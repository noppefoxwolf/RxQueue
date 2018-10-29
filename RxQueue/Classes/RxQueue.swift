//
//  RxQueue.swift
//  Pods
//
//  Created by Tomoya Hirano on 2016/11/16.
//
//

import RxSwift

public protocol Queueable {
  var duration: TimeInterval { get }
  var proprietary: Int { get } //サービスの専有数
}

public final class RxQueue {
  public private(set) var pool = [Queueable]()
  private var services = [Service]()
  private let disposeBag = DisposeBag()
  
  private let _output = PublishSubject<(Int, Queueable)>()
  public var output: Observable<(Int, Queueable)> {
    return _output.asObservable()
  }
  public let interrupt = PublishSubject<Queueable>()
  public let append = PublishSubject<Queueable>()
  
  public init(service count: Int) {
    services = (0..<count).map { _ in Service() }
    setupSubscriber()
  }
  
  private func setupSubscriber() {
    services.enumerated().forEach { (index, service) in
      service.state.asObservable()
        .filter({ $0 == .working })
        .subscribe(onNext: { [weak self] (_) in
        guard let element = service.element else { return }
        self?._output.onNext((index, element))
      }).disposed(by: disposeBag)
      
      service.state.asObservable()
        .filter({ $0 == .idle })
        .subscribe(onNext: { [weak self] (_) in
        self?.executeNextIfNeeded()
      }).disposed(by: disposeBag)
    }

    interrupt.subscribe(onNext: { [weak self] (element) in
      self?.interrupt(element)
    }).disposed(by: disposeBag)
    
    append.subscribe(onNext: { [weak self] (element) in
      self?.append(element)
    }).disposed(by: disposeBag)
  }
  
  public func interrupt(_ element: Queueable) {
    pool.insert(element, at: 0)
    executeNextIfNeeded()
  }
  
  public func append(_ element: Queueable) {
    pool.append(element)
    executeNextIfNeeded()
  }
  
  public func reset() {
    pool = [Queueable]()
  }
  
  private func executeNextIfNeeded() {
    guard let nextItem = pool.first else { return }
    let unusedServices = services.filter({ !$0.isWorking })
    if nextItem.proprietary <= unusedServices.count {
      unusedServices[0..<nextItem.proprietary].forEach({ $0.start(nextItem) })
      pool.removeFirst()
    }
  }
}


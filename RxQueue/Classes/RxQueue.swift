//
//  RxQueue.swift
//  Pods
//
//  Created by Tomoya Hirano on 2016/11/16.
//
//

import UIKit
import RxSwift

extension Reactive where Base: RxQueue {
  public var out: Observable<(Int, Queueable)> {
    return base.publisher
  }
  public var interrupt: PublishSubject<Queueable> {
    return base.interrupt
  }
  public var append: PublishSubject<Queueable> {
    return base.append
  }
}

public protocol Queueable {
  var duration: TimeInterval { get }
  var proprietary: Int { get } //サービスの専有数
}

public final class RxQueue: NSObject {
  public fileprivate(set) var pool = [Queueable]()
  fileprivate let publisher = PublishSubject<(Int, Queueable)>()
  fileprivate let disposeBag = DisposeBag()
  fileprivate var services = [Service]()
  fileprivate let interrupt = PublishSubject<Queueable>()
  fileprivate let append = PublishSubject<Queueable>()
  
  public init(serviceCount: Int) {
    super.init()
    services = (0..<serviceCount).map { _ in Service() }
    setupSubscriber()
  }
  
  fileprivate func setupSubscriber() {
    services.enumerated().forEach { (index, service) in
      service.stateBehavior.filter({ $0 == .working }).subscribe(onNext: { [weak self] (_) in
        guard let element = service.element else { return }
        self?.publisher.onNext((index, element))
      }).disposed(by: disposeBag)
      
      service.stateBehavior.filter({ $0 == .idle }).subscribe(onNext: { [weak self] (_) in
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
  
  fileprivate func executeNextIfNeeded() {
    guard let nextItem = pool.first else { return }
    let unusedServices = services.filter({ !$0.isWorking })
    if nextItem.proprietary <= unusedServices.count {
      unusedServices[0..<nextItem.proprietary].forEach({ $0.start(nextItem) })
      pool.removeFirst()
    }
  }
}

enum ServiceState {
  case working
  case idle
}

final class Service {
  let stateBehavior = BehaviorSubject<ServiceState>(value: .idle)
  var isWorking: Bool {
    return (((try? stateBehavior.value()) ?? .idle)) == .working
  }
  fileprivate(set) var element: Queueable? = nil
  
  func start(_ element: Queueable) {
    self.element = element
    let duration: DispatchTime = .now() + .seconds(Int(element.duration))
    stateBehavior.onNext(.working)
    DispatchQueue.main.asyncAfter(deadline: duration, execute: { [weak self] in
      self?.stateBehavior.onNext(.idle)
      self?.element = nil
    })
  }
}

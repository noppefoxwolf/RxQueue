//
//  RxQueue.swift
//  Pods
//
//  Created by Tomoya Hirano on 2016/11/16.
//
//

import UIKit
import RxSwift

public protocol Queueable {
  var duration: TimeInterval { get }
  var proprietary: Int { get } //サービスの専有数
}

public final class RxQueue {
  public private(set) var pool = [Queueable]()
  public let publisher = PublishSubject<(Int, Queueable)>()
  private var disposeBag = DisposeBag()
  private var services = [Service]()
  
  public init(serviceCount: Int) {
    services = (0..<serviceCount).map { _ in Service() }
    setupSubscriber()
  }
  
  private func setupSubscriber() {
    services.enumerated().forEach { (index, service) in
      service.stateBehavior.filter({ $0 == .working }).subscribe(onNext: { [weak self] (_) in
        guard let element = service.element else { return }
        self?.publisher.onNext((index, element))
      }).addDisposableTo(disposeBag)
      
      service.stateBehavior.filter({ $0 == .idle }).subscribe(onNext: { [weak self] (_) in
        self?.executeNextIfNeeded()
      }).addDisposableTo(disposeBag)
    }
  }
  
  public func interrupt(_ element: Queueable) {
    pool.insert(element, at: 0)
    executeNextIfNeeded()
  }
  
  public func append(_ element: Queueable) {
    pool.append(element)
    executeNextIfNeeded()
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

enum ServiceState {
  case working
  case idle
}

final class Service {
  let stateBehavior = BehaviorSubject<ServiceState>(value: .idle)
  var isWorking: Bool {
    return (((try? stateBehavior.value()) ?? .idle)) == .working
  }
  private(set) var element: Queueable? = nil
  
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

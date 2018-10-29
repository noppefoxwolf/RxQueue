//
//  Service.swift
//  Pods
//
//  Created by Tomoya Hirano on 2017/06/14.
//
//

import RxSwift

enum ServiceState {
  case working
  case idle
}

final class Service {
  let state = Variable<ServiceState>(.idle)
  var isWorking: Bool {
    return state.value == .working
  }
  private(set) var element: Queueable? = nil
  
  func start(_ element: Queueable) {
    self.element = element
    let duration: DispatchTime = .now() + element.duration
    state.value = .working
    DispatchQueue.main.asyncAfter(deadline: duration, execute: { [weak self] in
      self?.state.value = .idle
      self?.element = nil
    })
  }
}

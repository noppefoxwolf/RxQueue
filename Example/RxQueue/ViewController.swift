//
//  ViewController.swift
//  RxQueue
//
//  Created by Tomoya Hirano on 11/16/2016.
//  Copyright (c) 2016 Tomoya Hirano. All rights reserved.
//

import UIKit
import RxSwift
import RxQueue

final class SampleQueueItem: Queueable {
  var duration: TimeInterval {
    return 2.0
  }
  var value = 0
}

final class ViewController: UIViewController {
  @IBOutlet private weak var poolLabel: UILabel!
  @IBOutlet private weak var service01: UILabel!
  @IBOutlet private weak var service02: UILabel!
  @IBOutlet private weak var service03: UILabel!
  
  private var queue = RxQueue<SampleQueueItem>(serviceCount: 3)
  private var disposeBag = DisposeBag()
  private var count = 0
  
  override func viewDidLoad() {
    super.viewDidLoad()
    queue.publisher.subscribe(onNext: { [weak self] (index, item) in
      DispatchQueue.main.async {
        self?.poolLabel.text = self?.queue.pool.map({"\($0.value)"}).joined(separator: ",")
        switch index {
        case 0: self?.service01.text = "\(item.value)"
        case 1: self?.service02.text = "\(item.value)"
        case 2: self?.service03.text = "\(item.value)"
        default: break
        }
        print(index, item.value)
      }
    }).addDisposableTo(disposeBag)
  }
  
  @IBAction func appendAction(_ sender: UIButton) {
    let item = SampleQueueItem()
    item.value = count
    queue.append(item)
    count += 1
  }
  @IBAction func insertAction(_ sender: UIButton) {
    let item = SampleQueueItem()
    item.value = count
    queue.interrupt(item)
    count += 1
  }
}

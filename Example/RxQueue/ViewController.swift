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

struct QueueItem: Queueable {
  var duration: TimeInterval
  var proprietary: Int
  var value: Int
}

final class ViewController: UIViewController {
  @IBOutlet private weak var poolLabel: UILabel!
  @IBOutlet private weak var service01: UILabel!
  @IBOutlet private weak var service02: UILabel!
  @IBOutlet private weak var service03: UILabel!
  
  private var queue = RxQueue(serviceCount: 3)
  private var disposeBag = DisposeBag()
  private var count = 0
  
  override func viewDidLoad() {
    super.viewDidLoad()
    queue.publisher.subscribe(onNext: { [weak self] (index, item) in
      guard let item = item as? QueueItem else { return }
      DispatchQueue.main.async {
        self?.poolLabel.text = self?.queue.pool.flatMap({ $0 as? QueueItem }).map({"\($0.value)"}).joined(separator: ",")
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
    let item = QueueItem(duration: 1.0, proprietary: 1, value: count)
    queue.append(item)
    count += 1
  }
  @IBAction func insertAction(_ sender: UIButton) {
    let item = QueueItem(duration: 1.0, proprietary: 1, value: count)
    queue.interrupt(item)
    count += 1
  }
  
  
  @IBAction func appendAction2(_ sender: Any) {
    let item = QueueItem(duration: 1.0, proprietary: 2, value: count)
    queue.append(item)
    count += 1
  }
  
  @IBAction func insertAction2(_ sender: Any) {
    let item = QueueItem(duration: 1.0, proprietary: 2, value: count)
    queue.interrupt(item)
    count += 1
  }
}

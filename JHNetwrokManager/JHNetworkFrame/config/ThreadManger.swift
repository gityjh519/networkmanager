
//
//  ThreadManger.swift
//  CathAssist
//
//  Created by yaojinhai on 2019/11/5.
//  Copyright © 2019 CathAssist. All rights reserved.
//

import Foundation
import CoreFoundation

extension DispatchQueue {
    static func queue(afterTime: Double = 0, async: (@escaping () -> Void)) -> Void {
        DispatchQueue(label: "com.queue.async").asyncAfter(deadline: .now() + afterTime) {
            async()
        }
    }
    static func mainQueue(afterTime: Double = 0, async: (@escaping () -> Void)) -> Void {
        DispatchQueue.main.asyncAfter(deadline: .now() + afterTime) {
            async();
        }
    }
}

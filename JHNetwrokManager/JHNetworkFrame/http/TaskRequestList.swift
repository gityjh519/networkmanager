//
//  TaskRequestList.swift
//  CathAssist
//
//  Created by yaojinhai on 2019/9/18.
//  Copyright © 2019 CathAssist. All rights reserved.
//

import UIKit

struct TaskRequestList {
    
    private static var memryCacheList = [TaskRequestOperation]();
    private static let lock = DispatchQueue(label: "io.read.write.block")
    private static let maxOperation = 4
    
    static func addOperation(task: TaskRequestOperation) -> Void {
        func addItem(){
            for item in memryCacheList {
                if item == task {
                    item.configTask(task: task);
                    return;
                }
            }
            memryCacheList.insert(task, at: 0);
            runOperation();
        }
        lock.async {
            addItem()
        }
        
    }
    static func cancelOperaion(task: TaskRequestOperation) -> Void {
        func cancelItem(){
            if let firstIndex = memryCacheList.firstIndex(where: { $0 == task }) {
                let mTest = memryCacheList.remove(at: firstIndex);
                mTest.cancelRequest();
                task.cancelRequest();
            }
            
            runOperation();
        }
        lock.async {
            cancelItem()
        }
    }
    
    static func finishedOperaion(task: TaskRequestOperation) -> Void {
        
        func finishedItem(){
            if let firstIndex = memryCacheList.firstIndex(where: { $0 == task }) {
                let mTest = memryCacheList.remove(at: firstIndex);
                mTest.finishedTask();
                task.finishedTask();
            }
            runOperation();
        }
        
        lock.async {
            finishedItem()
        }
    }
    
    private static func runOperation() -> Void {
        
        DispatchQueue.main.async {
            UIApplication.shared.isNetworkActivityIndicatorVisible = memryCacheList.count != 0;
        }
        
        if memryCacheList.count == 0 {
            return;
        }
        
        let runCount = memryCacheList.reduce(0) { (idx, item) -> Int in
            idx + (item.state == .ready ? 0 : 1)
        }
        
        var otherCount = maxOperation - runCount;
        
        for item in memryCacheList {
            
            if otherCount <= 0 {
                return;
            }
            if item.state == .ready {
                item.starRun();
                otherCount -= 1;
            }
            
        }
        
    }
    
}

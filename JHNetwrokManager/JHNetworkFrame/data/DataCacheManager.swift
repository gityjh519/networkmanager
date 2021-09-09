//
//  DataBaseManager.swift
//  CathAssist
//
//  Created by yaojinhai on 2018/7/3.
//  Copyright © 2018年 CathAssist. All rights reserved.
//

import UIKit


protocol DataCacheManagerStringKey {
    var valueString: String { get }
}
extension String: DataCacheManagerStringKey {
    var valueString: String {
        return self;
    }
}


class DataCacheManager {
    
    private static var paramter = DataMemeryCache()
    private init() {}
    static subscript(key: DataCacheManagerStringKey) -> Any? {
        set {
            paramter[key.valueString] = newValue as AnyObject?;
        }
        get {
            return paramter[key.valueString]
        }
    }
    
    static func removeKey(key: DataCacheManagerStringKey) -> Void {
        paramter.removeObject(forKey: key.valueString as NSString)
    }
}



class DataMemeryCache: NSCache<NSString, AnyObject> {
    
    private lazy var weakCahe = NSMapTable<NSString, AnyObject>(keyOptions: .copyIn, valueOptions: .weakMemory)
    private lazy var ioDispatch = DispatchQueue(label: "io.readwrite.cahe",attributes: .concurrent)
    private lazy var index = 0
    
    override init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(noticationAction(_:)), name: UIApplication.didReceiveMemoryWarningNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(noticationAction(_:)), name: UIApplication.didEnterBackgroundNotification, object: nil)

    }
    
    @objc func noticationAction(_ notification: NSNotification) {
        
        if notification.name == UIApplication.didReceiveMemoryWarningNotification{
            super.removeAllObjects()
        }else if notification.name == UIApplication.didEnterBackgroundNotification {
            if index > 2 {
                index = 0
                super.removeAllObjects()
            }else {
                index += 1
            }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func object(forKey key: NSString) -> AnyObject? {
        var value = super.object(forKey: key);
        if value == nil {
            ioDispatch.sync {
                value = weakCahe.object(forKey: key)
            }
            if let newValue = value {
                var cost = 0
                if let img = newValue as? UIImage {
                    cost = img.memoryCost
                }else if let data = newValue as? Data,
                    let img = UIImage(data: data) {
                     cost = img.memoryCost
                }
                super.setObject(newValue, forKey: key, cost: cost)
            }
        }
        return value
    }

    override func setObject(_ obj: AnyObject, forKey key: NSString, cost g: Int) {
        super.setObject(obj, forKey: key, cost: g)
        ioDispatch.async(flags: .barrier) { 
            self.weakCahe.setObject(obj, forKey: key)
        }
    }
    override func removeAllObjects() {
        super.removeAllObjects()
        ioDispatch.async(flags: .barrier) {
            self.weakCahe.removeAllObjects()
        }
    }
    override func removeObject(forKey key: NSString) {
        super.removeObject(forKey: key)
        ioDispatch.async(flags: .barrier) {
            self.weakCahe.removeObject(forKey: key)
        }
    }
}


extension DataMemeryCache {
    subscript(key: String) -> AnyObject? {
        set{
            if let value = newValue {
                setObject(value, forKey: key as NSString)
            }
        }
        get {
            object(forKey: key as NSString)
        }
    }
}

extension UIImage {
   
    fileprivate var memoryCost: Int {
        guard let bytesPerFrame = cgImage?.bytesPerRow,
              let height = cgImage?.height else{
            return 0
        }
        let frameCount = images?.count ?? 1
        return bytesPerFrame * height * frameCount
    }
}

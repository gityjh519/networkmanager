//
//  BaseModel.swift
//  CathAssist
//
//  Created by yaojinhai on 2017/7/22.
//  Copyright © 2017年 CathAssist. All rights reserved.
//

import UIKit

enum CodeType: Int {
    case fail_code = 0
    case success_code = 200
    
}

/** 如过要使用BaseModel,请先确认后台返回来的数据格式，content 对应的是后台返回来的 Map 形式
 contentList 对应的是后台返回来的 数组模式 请务必把 content的"content" 对应后台的键
 如下：
 {
     "success": "1",
     "message": "获取成功",
     "result": {
         "days": "2021-09-09",
         "week": "星期四",
         "cityno": "beijing",
         "citynm": "北京",
         "cityid": "101010100",
         "windid": "8",
         "winpid": "1",
         "weather_iconid": "1"
     }
 }
 以这中json举例子，则下面的 setValue(_ value: Any?, forKey key: String) 函数如下：
 
 override func setValue(_ value: Any?, forKey key: String) {
     
     guard let value = value else {
         return;
     }
  这个key 对应 content 会自动判断是否是 数组或者 字典
     if key == "result"  {
         if let list = value as? NSArray {
             
             contentList = [BaseModel]();
             for item in list {
                 guard let cls = anyCls as? BaseModel.Type,let nDict = item as? [String: Any] else{
                     return;
                 }
                 let model = cls.init();
                 model.configModel(dict: nDict);
                 model.setData();
                 contentList.append(model);
             }
             content = contentList as AnyObject;
             
         }else if let dict = value as? NSDictionary {
             
             if let cls = anyCls as? BaseModel.Type{
                 let model = cls.init();
                 model.configModel(dict: dict as! [String : Any]);
                 model.setData();
                 content = model as AnyObject;
             }
             
         }else if let strl = value as? String {
             
             content = strl as AnyObject;
         }
     }else if key == "success"{
         if let value = value as? Int{
             code = value;
         }else let value = value as? String {
             code = Int(value) ?? 0
         }
         
     }else {
         super.setValue(value, forKey: key);
     }
 }
 自类别见： TestURLViewController.swift
*/

class BaseModel: NSObject {
    
    var errorCode: CodeType {
        guard let sCode = CodeType.init(rawValue: code) else {
            return .fail_code
        }
        return sCode;
    }
    var isSuccess: Bool {
        return errorCode == .success_code;
    }
    @objc var code = 0;
    @objc var message = "";
    
    var content: AnyObject!
    var contentList: [BaseModel]!
    
    private var anyCls: AnyClass!

    required override init() {
        super.init();
    }
    convenience init(dict: [String:Any]){
        self.init();
        configModel(dict: dict);
        setData();
    }
    convenience init(dictM: NSDictionary){
        self.init(dict: dictM as! [String : Any]);
        
    }
    
    convenience init(model: AnyClass,dict: Any){
        self.init();
        anyCls = model;
        configModel(dict: dict as! [String : Any]);
        setData();
    }
    
    
    convenience init(item: Any) {
        
        self.init(dict: item as! [String:Any]);
    }
    
    func setData() -> Void {
        
    }

    
    var modelDict: NSDictionary {
        
        var counts: UInt32 = 0;
        let propertis = class_copyPropertyList(classForCoder, &counts);
    
        let keyValueDict = NSMutableDictionary();
        for idx in 0..<Int(counts) {
            guard let property = propertis?[idx] else{
                continue;
            }
            
            if let pty = property_getAttributes(property) {
                let attribute = String(cString: pty);
                if attribute.contains("R") || attribute.contains("NSAttributedString") {
                    continue;
                }
            }
            let cName = property_getName(property);
            
            let name = String(cString: cName);
            
            var value = self.value(forKey: name);

            if value == nil {
                value = self.value(forKeyPath: name);
            }
            
            guard let keyValue = value else{
                continue;
            }
            
            if let model = keyValue as? BaseModel{
                let dict = model.modelDict;
                if dict.count > 0 {
                    keyValueDict[name] = model.modelDict;
                }
                
            }else if (keyValue is NSNumber){
                
                keyValueDict[name] = keyValue;
                
            }else if let list = keyValue as? NSArray{
                if let tempList = forArray(array: list) {
                    keyValueDict[name] = tempList;
                }
            }else if let valueString = (keyValue as? String) {
                keyValueDict[name] = valueString;
            }
        }
        
        return keyValueDict;
    }
    
    private func forArray(array: NSArray) -> NSArray? {
        if array.count == 0 {
            return nil;
        }
        let tempArray = NSMutableArray();
        for item in array {
            if let model = item as? BaseModel {
                let dict = model.modelDict;
                if dict.count > 0 {
                    tempArray.add(model.modelDict);
                }
            }else if let listArray = item as? NSArray {
                if let tempList = forArray(array: listArray) {
                    tempArray.addObjects(from: tempList as! [Any]);
                }
            }else if (item is NSNumber){
                tempArray.add(item);
            }else if let valueString = (item as? String) {
                tempArray.add(valueString);
            }
        }
        if tempArray.count > 0 {
            return tempArray;
        }
        return nil;
    }
    
    func configModel(dict: [String:Any]) -> Void {
        self.setValuesForKeys(dict);
    }
    

    
    override func setValue(_ value: Any?, forKey key: String) {
        
        guard let value = value else {
            return;
        }
        
        
        if key == "result"  {
            if let list = value as? NSArray {
                
                contentList = [BaseModel]();
                for item in list {
                    guard let cls = anyCls as? BaseModel.Type,let nDict = item as? [String: Any] else{
                        return;
                    }
                    let model = cls.init();
                    model.configModel(dict: nDict);
                    model.setData();
                    contentList.append(model);
                }
                content = contentList as AnyObject;
                
            }else if let dict = value as? NSDictionary {
                
                if let cls = anyCls as? BaseModel.Type{
                    let model = cls.init();
                    model.configModel(dict: dict as! [String : Any]);
                    model.setData();
                    content = model as AnyObject;
                }
                
            }else if let strl = value as? String {
                
                content = strl as AnyObject;
            }
        }else if key == "code"{
            if let value = value as? Int{
                code = value;
            }
            
        }else {
            super.setValue(value, forKey: key);
        }
    }
    
    override func setValue(_ value: Any?, forUndefinedKey key: String) {
        
    }
}



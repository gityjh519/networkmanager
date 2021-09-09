//
//  JsonConfig.swift
//
//  Created by yaojinhai on 2020/3/6.
//  Copyright © 2020  All rights reserved.
//

import Foundation

extension JSONDecoder {
    static func jsonDecoder<T: Codable>(_ type: T.Type,from data: Data?) -> T? {
        guard let data = data else {
            return nil;
        }
        let json = JSONDecoder();
        var jsonItem: T? = nil;
        do {
            jsonItem = try json.decode(type, from: data)
        } catch {
            #if DEBUG
            fatalError("data convert json error: \(error)")
            #endif
        }
        
        return jsonItem;
    }
    static func jsonDecoder<T: Codable>(_ type: T.Type,fromAny data: Any?) -> T? {
        if let data = data as? Data {
            return jsonDecoder(type, from: data);
        }
        if let stringValue = data as? String {
            return jsonDecoder(type, from: stringValue.data(using: .utf8));
        }
        guard let data = data else {
            return nil;
        }
      
        let jsonData = JSONSerialization.data(any: data);
        return jsonDecoder(type, from: jsonData);
    }
}

extension JSONSerialization {
    static func jsonDictionary(data: Data?) -> [String: Any]? {
        jsonObject(data: data) as? [String: Any]
    }
    static func jsonArray(data: Data?) -> [Any]? {
        jsonObject(data: data) as? [Any]
    }
    static func jsonObject(data: Data?) -> Any? {
        guard let data = data else{
            return nil;
        }
        return try? jsonObject(with: data, options: .mutableContainers)
    }
    
    static func data(any: Any?) -> Data? {
        guard let any = any else {
            return nil
        }
        if !isValidJSONObject(any) {
            return nil;
        }
        return try? data(withJSONObject: any, options: .prettyPrinted)
    }
}



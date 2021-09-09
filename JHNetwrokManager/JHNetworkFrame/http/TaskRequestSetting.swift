//
//  TaskRequestSetting.swift
//  CathAssist
//
//  Created by yaojinhai on 2019/9/20.
//  Copyright © 2019 CathAssist. All rights reserved.
//

import Foundation
import CommonCrypto


typealias proBlock = (_ perceces: Float) -> Void
typealias finishedTask = (_ data: AnyObject?,_ error: Error?) -> Void
typealias startLoaing = () -> Void


enum HttpState : Int{
    case ready
    case execing
    case cancel
    case finished
}

enum HttpMethodType : String{
    case GET = "GET"
    case POST = "POST"
}


enum CacheDataProtocal: Int {
    case ignoreCahes = 9 // 忽略缓存 直接从网络获取 这个策略不会保存数据
    case memory // 这个策略 会先从内存中获取 如果失败 就会在从网络中获取 成功后 会保存到内存中，但是不会保存到磁盘上
    case disk  // 这个策略 会先从内存中获取 如果失败 继续从磁盘上获取，如果失败 就会在从网络中获取，成功后 会保存到内存中，保存到磁盘上 适合离线模式
    case loadDataOrMemory // 这个策略 会先从网络中获取(成功后保存到内存中，不会保存到磁盘上) 如果失败 从内存上获取，适合离线模式
    case loadDataOrDisk // 这个策略 会先从网络中获取 如果失败 继续从内存磁盘上获取，适合离线模式

    
    var isFromNetLoadData: Bool {
        isIgnoreCaches || self == .loadDataOrDisk
    }
    
    var isIgnoreCaches: Bool {
         self == .ignoreCahes;
    }
    var isFromDiskData: Bool {
        self == .disk || self == .loadDataOrDisk
    }
}

enum HTTPContentType: String {
    case form = "application/x-www-form-urlencoded; charset=utf-8"
    case json = "application/json"
    case multipartForm = "multipart/form-data;boundary=wfWiEWrgEFA9A78512weF7106A";
    
}


extension String {
    
    var documentPath: String {
        String.documentPath + "/" + self + "/"
    }
    var libraryPath: String {
        String.libraryPath + "/" + self + "/"
    }

    static let documentPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0];
    static let libraryPath = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true)[0];
    
    var SHA256: String {
        let cStr = cString(using: .utf8);
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: Int(CC_SHA256_DIGEST_LENGTH))
        CC_SHA256(cStr!, (CC_LONG)(strlen(cStr!)), buffer)
        var sha256 = "";
        for i in 0 ..< Int(CC_SHA256_DIGEST_LENGTH){
            sha256 += String(format: "%02x", buffer[i]);
        }
        free(buffer)
        return sha256
    }
}


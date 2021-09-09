//
//  NetworkRequest.swift
//  CathAssist
//
//  Created by lzt on 16/7/5.
//  Copyright © 2016年 CathAssist. All rights reserved.
//

import UIKit
import Foundation
import CoreLocation

let baseURLAPI = "http://api.k780.com/"; // 这里需要设置域名


enum ResponseType : Int {
    case typeData = 0
    case typeJson
    case typeImage
    case typeString
    case model // 如果使用这个需要继承BaseModel 
}


class NetworkRequest : BaseRequestTask {
    
    override init() {
        super.init();
        
    }
    convenience init(methedType: HttpMethodType,rsType: ResponseType) {
        self.init()
        httpMethod = methedType
        respType = rsType
    }
}



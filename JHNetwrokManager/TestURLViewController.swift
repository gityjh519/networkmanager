//
//  TestURLViewController.swift
//  JHNetwrokManager
//
//  Created by yjh on 2021/9/9.
//

import UIKit

class TestURLViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

//        http://wthrcdn.etouch.cn/weather_mini?city=%E6%B7%B1%E5%9C%B3
        
        
    }
}


class WeatherObjectModel: BaseModel {
    @objc var days: String!
    @objc var week: String!
    @objc var cityno: String!
    @objc var citynm: String!
    @objc var cityid: String!
    @objc var windid: String!
    @objc var winpid: String!
    @objc var weather_iconid: String!
}

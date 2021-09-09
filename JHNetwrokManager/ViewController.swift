//
//  ViewController.swift
//  JHNetwrokManager
//
//  Created by yjh on 2021/9/9.
//

import UIKit

class ViewController: UIViewController {
    
    var model: WeatherModel!
    var ocModel: WeatherObjectModel!

    var mainTable: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
//            ?app=weather.today&weaId=1&appkey=10003&sign=&format=
        
        mainTable = UITableView(frame: self.view.bounds, style: .plain)
        view.addSubview(mainTable)
        mainTable.delegate = self
        mainTable.dataSource = self
        mainTable.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        
//        loadDataWeather()
        loadDataObjectModel()
    }

    // 强烈建议使用struct代替类model
    func loadDataWeather() {
        
        let request = NetworkRequest(methedType: .GET, rsType: .typeData);
        request.add(value: "weather.today", key: "app")
        request.add(value: "1", key: "weaId")
        request.add(value: "10003", key: "appkey")
        request.add(value: "b59bc3ef6191eb9f747dd4e83c99f2a4", key: "sign")
        request.add(value: "json", key: "format")

        request.loadJsonStringFinished { result, error in
            self.model = JSONDecoder.jsonDecoder(WeatherModel.self, fromAny: result)
            self.mainTable.reloadData()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
    }
    
    // 继承BaseModel的具体使用方式
    func loadDataObjectModel()  {
        
        let request = NetworkRequest(methedType: .GET, rsType: .model);
        request.clsModel = WeatherObjectModel.classForCoder()
        request.add(value: "weather.today", key: "app")
        request.add(value: "1", key: "weaId")
        request.add(value: "10003", key: "appkey")
        request.add(value: "b59bc3ef6191eb9f747dd4e83c99f2a4", key: "sign")
        request.add(value: "json", key: "format")

        request.loadJsonStringFinished { result, error in
            let model = result as? BaseModel
            let childModel = model?.content as? WeatherObjectModel;
            print(childModel?.modelDict)
        }
    }

}

//#MARK: - tableview delegate
extension ViewController: UITableViewDelegate,UITableViewDataSource {
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        model?.keyValue.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let item = model.keyValue[indexPath.row]
        cell.textLabel?.text = item.keys.first! + "：" + item.values.first!
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
    }
}

struct WeatherModel: Codable {
    let result: WeatherDetialModel
    let success: String
    
    var keyValue: [[String:String]] {
        var list = [[String: String]]()
        list.append(["日期":result.days])
        list.append(["星期":result.week])
        list.append(["地区":result.citynm])
        list.append(["温度":result.temperature_curr])
        list.append(["天气":result.weather])
        list.append(["风向":result.wind])
        list.append(["风级":result.winp])
        return list

    }
}


struct WeatherDetialModel: Codable {
    let aqi: String
    let cityid: String
    let citynm: String
    let cityno: String
    let days: String
    let humi_high: String
    let humi_low: String
    let humidity: String
    let temp_curr: String
    let temp_high: String
    let temp_low: String
    let temperature: String
    let temperature_curr: String
    let weather: String
    let weather_curr: String
    let weather_icon: String
    let weather_icon1: String
    let weather_iconid: String
   
    let week: String
    let wind: String
    let winp: String
}

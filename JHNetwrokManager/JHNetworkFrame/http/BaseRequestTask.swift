//
//  BaseRequestTask.swift
//  CathAssist
//
//  Created by yaojinhai on 2019/9/18.
//  Copyright © 2019 CathAssist. All rights reserved.
//

import UIKit

class BaseRequestTask {
    
    var respType = ResponseType.typeJson;
    
    var state = HttpState.ready;
    
    var filePath = "";
    
    var clsModel: AnyClass!
    
    
    var memeryProgress: Float = 0;
    var currentProgress: proBlock!
    
    
    var httpMethod = HttpMethodType.GET;
    var contentType = HTTPContentType.form;
    
    
    private lazy var paramterList = [HttpParamterModel]();
    
    private lazy var headerParamter = [String: String]();
    
    private lazy var queryItems = [URLQueryItem]();
    
    private var requestItem: TaskRequestOperation!
    
    private var stringURL = "";
    
    var httpURL: URL?
    
    private let ioDispatch = DispatchQueue(label: "read_caches_data",qos: .default)
    
    init() {}
    
    convenience init(baseUrl: String) {
        self.init();
        stringURL = baseUrl;
    }
    
    convenience init(url: URL) {
        self.init();
        httpURL = url;
    }
    
    func configParater() -> Void {
        
    }
    
    
}


extension BaseRequestTask {
    
    func add(value: String?,key: String) {
        func add(){
            if let value = value {
                queryItems.removeAll { (item) -> Bool in
                    return item.name == key;
                }
                let item = URLQueryItem(name: key, value: value);
                queryItems.append(item);
            } 
        }
        ioDispatch.async {
            add();
        }
    }
    func addBody(value:String?,key: String) -> Void {
        ioDispatch.async {
            if let value = value {
                let model = HttpParamterModel(key: key, value: value,isBody: true);
                self.paramterList.append(model);
            }
        }
        
    }
    func addBodyData(value: Data?,key: String) -> Void {
        ioDispatch.async {
            if let value = value {
                let model = HttpParamterModel(key: key, valueData: value);
                self.paramterList.append(model);
            }
        }
        
    }
    func addHeader(key: String,value: String) -> Void {
        ioDispatch.async {
            self.headerParamter[key] = value;
        }
    }
    
    func addBodyVideo(url: URLSchemeProtocol?,key: String)  {
        ioDispatch.async {
            let model = HttpParamterModel(key: key, videoURL: url);
            self.paramterList.append(model);
        }
    }
    
   
    private func connectURLRequest(request: URLRequest?,showLoading: Bool = false,progress: Bool = false,finished: @escaping finishedTask){
        
        guard let requestURL = request else {
            return
        }
        
        if showLoading {
            DispatchQueue.main.async {
                JHSActivityView.showActityView()
            }
        }
      
        let operation = TaskRequestOperation(request: requestURL);
        operation.finiTask = {
            (data,error) -> Void in
            if error == nil {
                let result = self.getResponsTypeData(data as? Data);
                finished(result, error);
            }else{
                finished(nil,error);
            }
        }
        
        if progress {
            operation.progress = {
                (pros) -> Void in
                self.currentProgress?(pros);
            }
        }
        
        TaskRequestList.addOperation(task: operation);
        self.memeryProgress = operation.memeryProgress;
        self.state = operation.state;
        
        
    }
    
}

extension BaseRequestTask {
    
    
    
    func loadJsonStringFinished(showLoading: Bool = false,cacheType: CacheDataProtocal = .memory, finished:@escaping finishedTask){
        
        var requestURL: URLRequest?
        
        ioDispatch.async {
            guard let tempURL = self.createRequest() else{
                DispatchQueue.main.async { 
                    finished(nil,NSError(domain: "请求的URL为空[\(self)]", code: -1, userInfo: nil));
                }
                self.ioDispatch.suspend()
                return
            }
            
            requestURL = tempURL
            requestURL?.setValue("\(cacheType.rawValue)", forHTTPHeaderField: "CacheDataProtocal");
        }
        
        func readCachesData(fileName: String) {
            
            if let data = DataFileManger.dataForKey(key: requestURL?.url?.absoluteString ?? "", cacheType: cacheType) {
                finished(getResponsTypeData(data),nil)
            }else{
                connectURLRequest(request: requestURL,showLoading: showLoading, finished: finished)
            }

        }
        
        ioDispatch.async {
            guard let fileName = requestURL?.url?.absoluteString else{
                return
            }
            if cacheType.isFromNetLoadData {
                self.connectURLRequest(request: requestURL,showLoading: showLoading, finished: finished)
            }else {
                readCachesData(fileName: fileName);
            }
        }
    }
    
    
    static func cancel(_ urlString: String) {
        
        guard let url = urlString.url else{
            return;
        }
        var request = URLRequest(url: url);
        request.httpMethod = HttpMethodType.GET.rawValue;
        let operation = TaskRequestOperation(request: request);
        TaskRequestList.cancelOperaion(task: operation);
    }
    
    func cancelRequest() -> Void {
        guard let url = getRequestURL() else{
            return;
        }
        let request = URLRequest(url: url);
        let operation = TaskRequestOperation(request: request);
        TaskRequestList.cancelOperaion(task: operation)
    }
    
    
}


extension BaseRequestTask {
    
    
    func getRequestURL() -> URL? {
        
        if let url = httpURL {
            return url;
        }
        
        var componse: URLComponents!
        
        if stringURL.lowercased().hasPrefix("http") {
            componse = URLComponents(string: stringURL.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed) ?? stringURL);
        }else {
            componse = URLComponents(string: baseURLAPI + "?");
        }
        if componse == nil {
            return nil
        }
        componse.path += filePath;
        if queryItems.count > 0 {
            componse.queryItems = queryItems;
        }
        
        return componse.url;
        
        
        
    }
    
    
    
    private func createRequest() -> URLRequest? {
        
        guard let tempURL = getRequestURL() else {
            return nil;
        }
        var request = URLRequest(url: tempURL);
        request.httpMethod = httpMethod.rawValue;
        request.allHTTPHeaderFields = headerParamter
        request.setValue("UTF-8", forHTTPHeaderField: "Accept-Charset");
   
        
        if contentType == .json {
            if let bodyData = HttpParamterModel.getHttpBodyJsonData(paramterList: paramterList) {
                request.httpBody = bodyData;
            }
        }else if let bodyData = HttpParamterModel.getHttpBodyData(paramterList: paramterList) {
            request.httpBody = bodyData
        }
        
        request.setValue(contentType.rawValue, forHTTPHeaderField: "Content-Type");
        
        if let bodayDataLength = request.httpBody?.count {
            request.setValue("\(bodayDataLength)", forHTTPHeaderField: "Content-Length")
            
        }
        
        
        return request;
        
    }
    
    
    private func getResponsTypeData(_ data: Data?) -> AnyObject? {
        
        guard let data = data else {
            return nil;
        }
        
        var result : AnyObject?;
        switch self.respType {
            case ResponseType.typeData:
                result = data as AnyObject?;
                break;
           case ResponseType.typeJson,ResponseType.model:
                guard let dict = JSONSerialization.jsonDictionary(data: data) else{
                    return nil;
                }
        
                if let cls = clsModel,respType == .model {
                    let model = BaseModel(model: cls, dict: dict);
                    result = model;
                }else{
                    result = dict as AnyObject?;
                }
            
            case ResponseType.typeImage:
                if let img = data.gifImage() {
                    result = img;
                }else {
                    result = UIImage(data: data);
                }
                
            
            case ResponseType.typeString:
                result = NSString(data: data, encoding: String.Encoding.utf8.rawValue);

        }
        
        return result;
    }
   
}


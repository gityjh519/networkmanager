//
//  TaskRequestOperation.swift
//  CathAssist
//
//  Created by yaojinhai on 2019/9/17.
//  Copyright © 2019 CathAssist. All rights reserved.
//

import UIKit


class TaskRequestOperation: NSObject {
        
    var state = HttpState.ready;
    var progress: proBlock?
    var finiTask: finishedTask!;
    var memeryProgress: Float = 0;
    
    
    private var requestItem: URLRequest!

    private var requestTask: URLSessionDataTask!
    
    private var reciveData: Data!;
    
    private var session: URLSession!
    
    private var totalBytesExpectedToReceive: Int64 = 0;
    
    
    override init() {
        super.init();
    }
    convenience init(request: URLRequest) {
        self.init();
        requestItem = request;
    }
    
    func starRun() -> Void {
        
        if state != .ready {
            return;
        }
        state = .execing;
        mainRun()
    }
    
    
    private func mainRun() -> Void {
        
        let extenName = requestItem?.url?.pathExtension ?? "";
        let header = requestItem?.allHTTPHeaderFields?["fileType"];
        let mp3File = [extenName.lowercased(),header ?? ""];
        let config: URLSessionConfiguration
        if mp3File.contains("mp3") || requestItem.url?.urlString.contains("web/images/") == true {
            config = URLSessionConfiguration.default
        }else {
            config = URLSessionConfiguration.ephemeral
            config.timeoutIntervalForRequest = 20
        }
        config.httpShouldUsePipelining = false
        session = URLSession(configuration: config, delegate: self, delegateQueue: OperationQueue());
        requestTask = session.dataTask(with: requestItem);
        requestTask.resume();
        memeryProgress = 0.01;
        
    
    }
    
    func cancelRequest() -> Void {
        if state == .cancel {
            return;
        }
        state = .cancel;
        progress = nil;
        requestTask?.cancel();
        session?.invalidateAndCancel();
        session = nil
        requestTask = nil
        
        memeryProgress = 0;
        
    }
    
    func finishedTask() -> Void {
        if state == .finished {
            return;
        }
        state = .finished;
        session?.finishTasksAndInvalidate();
        session = nil
        requestTask = nil
    }
    
    deinit {
    }
    
}

extension TaskRequestOperation {
    
    static func == (left: TaskRequestOperation,right: TaskRequestOperation) -> Bool{
        guard let leftURL = left.requestItem.url?.absoluteString,
            let leftMeth = left.requestItem.httpMethod,
            let rightURL = right.requestItem.url?.absoluteString,
            let rightMeth = right.requestItem.httpMethod else {
                return false;
        }
        return leftURL == rightURL && leftMeth == rightMeth;
    }
    
    func configTask(task: TaskRequestOperation) -> Void {
        finiTask = {
            (result, sccess) in
            task.finiTask?(result,sccess);
        }
        task.memeryProgress = memeryProgress;
        task.state = state
        progress = {
            (pf) in
            task.progress?(pf);
        }
        
    }
}


extension TaskRequestOperation: URLSessionDataDelegate {
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        
        if reciveData == nil || state == .cancel {
            return;
        }
                
        reciveData.append(data);
        
        guard let pro = progress else {
            return;
        }
        let currentLength = reciveData.count;
        let press = Double(currentLength) / Double(totalBytesExpectedToReceive);
        memeryProgress = Float(press);
        DispatchQueue.main.async {
            pro(Float(press));
        }
    }
    
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
            let serverTrust = challenge.protectionSpace.serverTrust {
            let card = URLCredential(trust: serverTrust);
            completionHandler(.useCredential,card);
        }else{
            completionHandler(.performDefaultHandling,nil)
        }
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        
        if state == .cancel {
            completionHandler(.cancel);
            TaskRequestList.cancelOperaion(task: self);
            return;
        }
        reciveData = Data();
        totalBytesExpectedToReceive = response.expectedContentLength;
        completionHandler(.allow);
    }
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        
        #if DEBUG
        if let request = task.originalRequest {
            printRequestParater(urlRequest: request, error: error);
        }
        #endif
        
        let data = handleRequestFinished(request: task.originalRequest, error: error);
        DispatchQueue.main.async {
            
            self.finiTask?(data as AnyObject?,error);

            TaskRequestList.finishedOperaion(task: self);
            
            JHSActivityView.hiddenActivityView();
            
            self.finiTask = nil;

        }
        
    }
    
    private func handleRequestFinished(request: URLRequest?,error: Error?) -> Data? {
        if state == .cancel {
            return nil;
        }
        
        if error == nil,let data = reciveData{
            saveDataToFile(request: request, data: data);
        }else {
            reciveData = readCachesData(request: request);
        }
        return reciveData;
    }
    
    
    
    private func saveDataToFile(request: URLRequest?,data: Data) {
        
        guard let method = request?.httpMethod,let url = request?.url else {
            return;
        }
        
        if method != HttpMethodType.GET.rawValue{
            return;
        }
        if let cacheType = request?.allHTTPHeaderFields?["CacheDataProtocal"] {
            if Int(cacheType) == CacheDataProtocal.ignoreCahes.rawValue {
                return;
            }
        }
        

        guard let data = reciveData else {
            return;
        }

    }
    
    private func readCachesData(request: URLRequest?) -> Data? {
        guard let method = request?.httpMethod,let url = request?.url else {
            return nil;
        }
        if method != HttpMethodType.GET.rawValue{
            return nil;
        }
       
        return nil
    }
    
    #if DEBUG
    private func printRequestParater(urlRequest: URLRequest,error: Error?) -> Void {
        
        
        var resultString = "\n=============请求开始=============\n\n";
        resultString += "地址：\(urlRequest.url?.absoluteString ?? "")\n";
        resultString += "方法：\(urlRequest.httpMethod ?? "")\n";
        if let body = urlRequest.httpBody {
            if let dict = JSONSerialization.jsonDictionary(data: body) {
                resultString += "body: \(dict)\n";
            }else if let img = UIImage(data: body) {
                resultString += "图片大小：[size =\(img.size)]";
            }
        }
        if let header = urlRequest.allHTTPHeaderFields {
            resultString += "header参数：\(header)\n";
        }
        resultString += "\n返回参数：\n";

        if let dict = JSONSerialization.jsonDictionary(data: reciveData) {
            resultString += "\(dict)\n";
        }else if let data = reciveData{
            if let img = UIImage(data: data) {
                resultString += "图片大小：[size =\(img.size)]";
            }else {
                let rs = String(data: data, encoding: .utf8);
                resultString += (rs ?? "");
            }
        }else if let er = error as NSError? {
            resultString += er.debugDescription
        }
        resultString += "\n\n=============请求结束=============\n";
        print(resultString);
  
        
        
    }
    #endif
}



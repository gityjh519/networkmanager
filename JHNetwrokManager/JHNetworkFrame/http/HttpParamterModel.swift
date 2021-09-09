//
//  HttpParamterModel.swift
//  StudyApp
//
//  Created by yaojinhai on 2018/4/12.
//  Copyright © 2018年 yaojinhai. All rights reserved.
//

import UIKit

enum HttpViaType: String {
    case other
    case image = "Content-Type:image/jpg"
    case video = "Content-Type:video/mp4"
}


class HttpParamterModel {

    private var isBodyPrammter = false;
    private var key = "";
    private var fileName = "";
    private var value = "";
    private var dataValue: Data!
    private var isData = false;
    private var fileType = HttpViaType.image;
    
    static let bodyBoundary = "wfWiEWrgEFA9A78512weF7106A";
    static let ctrlLine = "\r\n"
    
    convenience init(key: String,value: String,isBody: Bool = false) {
        self.init();
        self.key = key;
        self.value = value;
        self.isBodyPrammter = isBody;
    }
    convenience init(key: String,valueData: Data) {
        self.init();
        self.key = key;
        self.dataValue = valueData;
        self.isData = true;
        self.isBodyPrammter = true;
        self.fileName = key + ".jpg";
    }
    convenience init(key: String,videoURL: URLSchemeProtocol?) {
        self.init();
        self.key = key;
        
        if let url = videoURL as? URL {
            let data = try? Data(contentsOf: url);
            self.dataValue = data;
        }else if let urlString = videoURL as? String {
            let data = try? Data(contentsOf: URL(fileURLWithPath: urlString));
            self.dataValue = data;
        }

        fileType = .video;
        
        self.fileName = "\(Date().timeIntervalSince1970).mp4";
        self.isData = true;
        self.isBodyPrammter = true;
    }
    
    
    static func getHttpBodyJsonData(paramterList: [HttpParamterModel]) -> Data? {
        if paramterList.count == 0 {
            return nil;
        }
        var bodyParamter = [String:String]();
        for item in paramterList {
            if !item.isData {
                bodyParamter[item.key] = item.value;
            }
        }
        if bodyParamter.count == 0 {
            return nil;
        }
        guard let jsonData = JSONSerialization.data(any: bodyParamter) else{
            return nil;
        }
        return jsonData;
    }
    
    
    static func getHttpBodyData(paramterList: [HttpParamterModel]) -> Data? {
        
        
        let listModel = getBodyParamter(list: paramterList, isBody: true);
        
        if listModel.count == 0 {
            return nil;
        }
        var bodyData = Data();
        let debugDataString = NSMutableString();
        
        
        
        let boundLine = "--" + bodyBoundary + ctrlLine;

        for item in listModel {
            
            bodyData.append(boundLine.data);
            debugDataString.append(boundLine);
            
            
            if item.isData {
                
                
                let inputKey = """
                Content-Disposition: form-data;name="\(item.key)";filename="\(item.fileName)"\(ctrlLine)\(item.fileType.rawValue)\(ctrlLine)
                """;
                
                bodyData.append(inputKey.data);
                debugDataString.append(inputKey);
                
                
                bodyData.append(ctrlLine.data);
                debugDataString.append(ctrlLine);
                
                bodyData.append(item.dataValue);
                
                if let image = UIImage(data: item.dataValue) {
                    debugDataString.append("imageSize =\(image.size)");
                }else {
                    debugDataString.append("Data 数据：\(item.dataValue.count)");
                }
                
            }else {
                
                let inputKey = "Content-Disposition: form-data; name=\"\(item.key)\"" + ctrlLine + ctrlLine;
                bodyData.append(inputKey.data);
                debugDataString.append(inputKey);
                
                bodyData.append(item.value.data);
                debugDataString.append(item.value);
                
            }
            
            bodyData.append(ctrlLine.data);
            debugDataString.append(ctrlLine);
        }
        
        
        
        let endBound = "--" + bodyBoundary + "--" + ctrlLine;
        bodyData.append(endBound.data);
        
        debugDataString.append(endBound);
        
        #if DEBUG
        print("数据参数：\n\(debugDataString)");
        #endif
        
        return bodyData;
    }
    
    
    static func getBodyParamter(list: [HttpParamterModel],isBody: Bool) -> [HttpParamterModel] {
        
        var tempList = [HttpParamterModel]();
        for item in list {
            if item.isBodyPrammter && isBody {
                tempList.append(item);
            }else if !isBody && !item.isBodyPrammter{
                tempList.append(item);
            }
        }
        return tempList;
    }
    
    private init() {
    }
}

extension String {
    var data: Data {
        return self.data(using: String.Encoding.utf8)!;
    }
}

struct HttpDataCount {
    static let maxCount = 20
}


protocol URLSchemeProtocol {
    var url: URL? {get}
    var urlString: String {get}
}

extension String: URLSchemeProtocol {
    
    var urlString: String {self}
    var url: URL? {URL(string: self)}
    var fileURL: URL {
        URL(fileURLWithPath: self)
    }
}
extension URL: URLSchemeProtocol {
    var urlString: String {absoluteString}
    
    var url: URL? {
        if isFileURL {
            return self;
        }
        if host == nil {
            return nil;
        }
        return self;
    }
}

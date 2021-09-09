//
//  DataFileManger.swift
//  CathAssist
//
//  Created by yaojinhai on 2019/9/18.
//  Copyright © 2019 CathAssist. All rights reserved.
//

import UIKit

struct DataQueue {
    static private let backQueue = DispatchQueue(label: "save.data.queue")
    static private var queue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 4
        queue.underlyingQueue = backQueue
        return queue
    }()
    static func block(_ block: @escaping ()-> Void) {
        queue.addOperation(block)
    }
}

class DataFileManger {
    
    //    创建的路径：libraryPath documentPath 两种
    private var path : String!
    
    static var shareInstance: DataFileManger {
        DataFileManger(libraryPath: "defult.image.caches")
    }
    
    var rootPath: String {
        return path;
    }
    
    private init() {
        
    }
    // 这是libraryPath路径
    convenience init(libraryPath pathType: FileNameDelegate) {
        self.init();
        path = pathType.fileName
        configPath();
    }
   

    private func configPath(){
        let file = FileManager.default;
        if path.last?.description != "/" {
            path += "/"
        }
        path += FilePathType.imagePath.rawValue
        if !file.fileExists(atPath: path) {
            try? file.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil);
        }
    }
    
    
    func saveDataJson(anyData: Any?,fileName: FileNameDelegate,extenName: FileExtenNameDelegate = "",toType: CacheDataProtocal = .disk) {
        
        guard let dataItem = anyData else {
            return;
        }

        let data = JSONSerialization.data(any: dataItem);
        saveData(data: data, fileName: fileName, extenName: extenName);
    }
    
    func saveJson<T: Codable>(anyData: T,fileName: FileNameDelegate,extenName: FileExtenNameDelegate = "",toType: CacheDataProtocal = .disk) {
        
        let jsonData = JSONEncoder()
        let data = try? jsonData.encode(anyData);
        saveData(data: data, fileName: fileName, extenName: extenName);
        
    }
    
    // fileName: 文件的名字
    func saveData(data: Data?,fileName: FileNameDelegate,extenName: FileExtenNameDelegate = "",toType: CacheDataProtocal = .disk) -> Void {
        guard let data = data else {
            return;
        }
        let name = fileName.fileName.SHA256;
        let rootPath = path + name;
        
        if toType.isIgnoreCaches {
            return
        }
        if let image = data.gifImage() {
            DataCacheManager[rootPath] = image
        }else if let image = UIImage(data: data)?.decodedImage() {
            DataCacheManager[rootPath] = image
        }else {
            DataCacheManager[rootPath] = data
        }
     
        if toType.isFromDiskData {
            DataQueue.block {
                try? data.write(to: URL(fileURLWithPath: rootPath + extenName.value), options: .atomic);
            }
        }

    }
    
    
    func readToCachesJson(fileName: FileNameDelegate,extenName: FileExtenNameDelegate = "",fromData: CacheDataProtocal = .disk) -> Any? {
    
        if let data = readToCaches(fileName: fileName, extenName: extenName, fromData: fromData) {
            return JSONSerialization.jsonObject(data: data)
        }
        return nil;
    }
    
    func readToCachesImage(fileName: FileNameDelegate,extenName: FileExtenNameDelegate = "",fromData: CacheDataProtocal = .disk) -> UIImage?{
        if fromData.isIgnoreCaches {
            return nil;
        }
        let name = fileName.fileName.SHA256;
        let rootPath = path + name
        var image = DataCacheManager[rootPath] as? UIImage
        if fromData.isFromDiskData  && image == nil {
            image = UIImage(contentsOfFile: rootPath + extenName.value)
            if let cacheData = image {
                DataCacheManager[rootPath] = cacheData
            }
        }
        return image;
    }
    
    
    func readToCaches(fileName: FileNameDelegate,extenName: FileExtenNameDelegate = "",fromData: CacheDataProtocal = .disk) -> Data?{
        if fromData.isIgnoreCaches {
            return nil;
        }
        let name = fileName.fileName.SHA256;
        let rootPath = path + name
        var data = DataCacheManager[rootPath] as? Data
        if fromData.isFromDiskData  && data == nil {
            data = try? Data(contentsOf: URL(fileURLWithPath: rootPath + extenName.value));
            if let cacheData = data {
                DataCacheManager[rootPath] = cacheData
            }
        }
        return data;
    }
    
    
    
    func clearFile(fileName: FileNameDelegate,extenName: FileExtenNameDelegate = "") -> Void {
        let name = fileName.fileName.SHA256;
        let rootPath = path + name;
        DataCacheManager.removeKey(key: rootPath);
        let file = FileManager.default;
        DataQueue.block {
            try? file.removeItem(atPath: rootPath + extenName.value)
        }
    }
    
   
   
}

extension DataFileManger {
    static func saveData(key: String,data: Data?,extenName: FileExtenNameDelegate = "",fromData: CacheDataProtocal = .disk) {
        Self.shareInstance.saveDataJson(anyData: data, fileName: key, extenName: extenName, toType: fromData)
    }
    static func dataForKey(key: String,extenName: FileExtenNameDelegate = "",cacheType: CacheDataProtocal = .disk) -> Data?{
        Self.shareInstance.readToCaches(fileName: key, extenName: extenName, fromData: cacheType)
    }
    static func imageForKey(key: String,extenName: FileExtenNameDelegate = "",cacheType: CacheDataProtocal = .disk) -> UIImage?{
        Self.shareInstance.readToCachesImage(fileName: key, extenName: extenName, fromData: cacheType)
    }
    
}


extension DataFileManger {
    
    static func clearCahesData(finishedBlock:((_ strl: String) -> Void)? = nil) -> (() -> ()) {
        
        
        let libraryPath = DataFileManger.init(libraryPath: "").path ?? "";
        
        var listPath = [libraryPath];
        
        var maxSize: Double = 0
        let removePaths = listPath.reduce([URL]()) { 
            $0 + getPathsBy(rootPath: $1, size: &maxSize)
        }
    
        
        finishedBlock?(caculateSize(cachesSize: maxSize));
        
        func removeFile() {
            let file = FileManager.default;
            for item in removePaths {
                try? file.removeItem(at: item);
            }
        }
        return removeFile;
        
    }
    
    
    private static func getPathsBy(rootPath: FileNameDelegate,size: inout Double) -> [URL] {
        
        let keySet: Set<URLResourceKey> = [.fileSizeKey,.isDirectoryKey];

        
        let file = FileManager.default;
        let paths = file.enumerator(at: URL(fileURLWithPath: rootPath.fileName), includingPropertiesForKeys: keySet.reversed(), options: .skipsHiddenFiles);
        
        let allPath = (paths?.allObjects as? [URL]) ?? [URL]();
        
        let removePaths = allPath.compactMap { (item) -> URL? in
            if let result = try? item.resourceValues(forKeys: keySet) {
                if result.isDirectory ?? true {
                    return nil;
                }
                size += Double(result.fileSize ?? 0);
            }
            return item;
        }
        return removePaths;
    }
    
    
    private static func caculateSize(cachesSize: Double) -> String {
        let KB: Double = 1024;
        let MB = KB * KB;
        
        var valueMB = cachesSize / MB;
        var valueStrl = "MB"
        
        if valueMB > KB {
            valueStrl = "G"
            valueMB = valueMB / KB;
        }
        
        let formater = NumberFormatter.localizedString(from: NSNumber.init(value: valueMB), number: NumberFormatter.Style.decimal);
        
        return "\(formater)" + valueStrl;
    }
}




protocol FileNameDelegate {
    var fileName: String{get}
}
protocol FileExtenNameDelegate {
    var value: String {get}
}
extension String: FileNameDelegate , FileExtenNameDelegate{
    var fileName: String { self }
    var value: String { self }
}

enum FilePathType: String {
   case imagePath = "jh.cache.image.filepath/"
}

//
//  TaskRequest.swift
//  CathAssist
//
//  Created by yaojinhai on 2019/9/18.
//  Copyright © 2019 CathAssist. All rights reserved.
//

import UIKit
import Foundation

class ImageURLRequest: BaseRequestTask {
    
    static func loadImage(url: URLSchemeProtocol?,completed: (@escaping(_ image: UIImage?) -> Void)) -> Void {
        
        let request = ImageURLRequest(imageURL: url);
        request?.loadImageFinished(finished: { (image) in
            completed(image);
        })
    }
    
    convenience init?(imageURL: URLSchemeProtocol?) {
        if let url = imageURL?.url {
            self.init(url: url);
            respType = .typeImage;
        }else{
            return nil;
        }
    }
    
    private func loadImageFinished(finished: ((_ image: UIImage?) -> Void)?) -> Void {
        
        loadJsonStringFinished(cacheType: .disk) { (result, success) in
            finished?(result as? UIImage)
        }
    }
    
    
}


extension Data{
    
 
    func gifImage() -> UIImage? {
        
        var source = CGImageSourceCreateWithData(self as CFData, nil)
        if source == nil {
            return nil
        }
        defer {
            source = nil
        }
        
        let count = CGImageSourceGetCount(source!);
        if count <= 1 {
            return nil;
        }
        var images = [UIImage]();
        var duration: TimeInterval = 0;
        for idx in 0..<count {
            
            
            var imageRef = CGImageSourceCreateImageAtIndex(source!, idx, nil)
            if imageRef == nil {
                continue
            }
            
            var property = CGImageSourceCopyPropertiesAtIndex(source!, idx, nil) as NSDictionary?
            
            if property == nil {
                imageRef = nil
                continue
            }
            
            
            guard let gifProperty = property![kCGImagePropertyGIFDictionary as String] as? NSDictionary else{
                imageRef = nil
                property = nil
                continue;
            }
            
            var delayTime = gifProperty[kCGImagePropertyGIFUnclampedDelayTime as String] as? NSNumber;
            if delayTime == nil {
                delayTime = gifProperty[kCGImagePropertyGIFDelayTime as String] as? NSNumber;
            }
            let frameDuration = delayTime?.doubleValue ?? 0;
            duration += frameDuration;
            
            let image = autoreleasepool { () -> UIImage in
                UIImage(cgImage: imageRef!, scale: UIScreen.main.scale, orientation: .up);
            }
            images.append(image);
            imageRef = nil
            property = nil
            delayTime = nil
            
            
        }
        
        if duration == 0 {
            duration = Double(count) * 1.0 / 10.0;
        }
        let animatedImage = UIImage.animatedImage(with: images, duration: TimeInterval(duration));
        images.removeAll()
        return animatedImage;
    }
    
}

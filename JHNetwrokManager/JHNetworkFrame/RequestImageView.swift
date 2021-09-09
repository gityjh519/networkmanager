//
//  RequestImageView.swift
//  CathAssist
//
//  Created by yaojinhai on 2019/10/8.
//  Copyright © 2019 CathAssist. All rights reserved.
//

import Foundation
import UIKit
import CoreGraphics


struct AssociateKeys {
    static var urlKey: Void?
}


extension UIImageView {
    
    private var associateValue: String? {
        get {
            objc_getAssociatedObject(self, &AssociateKeys.urlKey) as? String
        }
        set {
            objc_setAssociatedObject(self, &AssociateKeys.urlKey, newValue, .OBJC_ASSOCIATION_COPY_NONATOMIC)
        }
    }
    
    func setImageURL(url: URLSchemeProtocol?,placeholder: UIImage? = nil,completed: ((_ image: UIImage?) -> Void)? = nil) -> Void {
        
        if associateValue == url?.urlString && associateValue != nil && image != nil{
            return;
        }
        image = placeholder;
        
        associateValue = url?.urlString
        
        ImageURLRequest.loadImage(url: url) {
            [weak self](img) in
            if let did = completed {
                did(img);
            }else if url?.urlString == self?.associateValue {
                self?.image = img;
            }
        }
    }
    
}


extension UIImage {
    func decodedImage() -> UIImage {
        
        if let imgs = images, imgs.count > 0 {
            return self;
        }
        
        if let img = downsample() {
            return img
        }
        
        guard let imageRef = cgImage else{
            return self;
        }
        
        let newImage =  autoreleasepool { () -> UIImage in
            
            let alpha = imageRef.alphaInfo;
            var listInfo = [CGImageAlphaInfo]();
            listInfo.append(.first);
            listInfo.append(.premultipliedFirst);
            listInfo.append(.last);
            listInfo.append(.premultipliedLast);
            
            let isHaveAlpha = listInfo.contains(alpha);
            
            let colorSpace = CGColorSpaceCreateDeviceRGB();
            
            
            var bitmapInfo = CGImageByteOrderInfo.orderDefault.rawValue;
            bitmapInfo = bitmapInfo | (isHaveAlpha ? CGImageAlphaInfo.premultipliedFirst.rawValue : CGImageAlphaInfo.noneSkipFirst.rawValue);
            
            
            let context = CGContext.init(data: nil, width: imageRef.width, height: imageRef.height, bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace, bitmapInfo: bitmapInfo);
            context?.draw(imageRef, in: .init(x: 0, y: 0, width: imageRef.width, height: imageRef.height));
            if let newImageRef = context?.makeImage() {
                let newImage = UIImage(cgImage: newImageRef);
                return newImage;
            }
            return self;
        }
        return newImage;
        
        
    }
    /**
     压缩图片 暂时不用
     */
    func downsample() -> UIImage? {
        
        guard let data = jpegData(compressionQuality: 1) else{return nil}
        
        
        let downsampleOpt = [kCGImageSourceCreateThumbnailFromImageIfAbsent : true,
                             
                             kCGImageSourceShouldCacheImmediately : true ,
                             
                             kCGImageSourceThumbnailMaxPixelSize : max(size.width, size.height)] as CFDictionary        
        guard let source = CGImageSourceCreateWithData(data as CFData, downsampleOpt) else{return nil}
        
        guard let downsampleImage = CGImageSourceCreateThumbnailAtIndex(source, 0, downsampleOpt) else {return nil}
        
        return UIImage(cgImage: downsampleImage, scale: UIScreen.main.scale, orientation: .up)
    }
}

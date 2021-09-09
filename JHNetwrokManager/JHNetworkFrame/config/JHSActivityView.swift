//
//  JHSActivityView.swift
//  CathAssist
//
//  Created by yaojinhai on 2019/9/27.
//  Copyright © 2019 CathAssist. All rights reserved.
//

import UIKit

class JHSActivityView: UIView {
    
    
    private static let indicatorWidth: CGFloat =   64;
    private var activity: UIActivityIndicatorView!
    private static let shareActity = JHSActivityView(frame: .init(x: (UIScreen.main.bounds.width - indicatorWidth)/2, y: (UIScreen.main.bounds.height - indicatorWidth)/2, width: indicatorWidth, height: indicatorWidth));
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func initView() {
        let style: UIActivityIndicatorView.Style;
        if #available(iOS 13.0, *) {
            style = .large
        }else {
            style = UIActivityIndicatorView.Style.gray;
        }
        activity = UIActivityIndicatorView(style: style);
        addSubview(activity);
        activity?.center = CGPoint(x: bounds.width/2, y: bounds.height/2);
        layer.cornerRadius = 4;
        layer.shadowColor = UIColor.secondaryLabel.cgColor
        layer.shadowOffset = .init(width: 0, height: 0);
        layer.shadowOpacity = 0.5;
        layer.shadowRadius = 3;
        backgroundColor = UIColor.systemBackground
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            NotificationCenter.default.addObserver(self, selector: #selector(noticationAction(_:)), name: UIApplication.didChangeStatusBarOrientationNotification, object: nil)
        }

    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
       
        if #available(iOS 13.0, *) {
            layer.shadowColor = UIColor.secondaryLabel.cgColor
        }
    }

    @objc func noticationAction(_ notification: NSNotification) {

        JHSActivityView.shareActity.center = CGPoint(x: UIScreen.main.bounds.height/2, y: UIScreen.main.bounds.height/2);

    }
    
}

extension JHSActivityView {
    static func showActityView() -> Void {

        guard let mainWindow = UIApplication.shared.windows.last else{
            return;
        }

        if shareActity.superview == nil {
            mainWindow.addSubview(shareActity);
        }
        mainWindow.bringSubviewToFront(shareActity);
        shareActity.activity.startAnimating();
    }
    static func hiddenActivityView(){
        shareActity.activity.stopAnimating();
        shareActity.removeFromSuperview();
    }
}

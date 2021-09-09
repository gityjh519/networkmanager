//
//  NetworkStateManger.swift
//  CathAssist
//
//  Created by yaojinhai on 2021/8/31.
//  Copyright © 2021 CathAssist. All rights reserved.
//

import Foundation
import SystemConfiguration

enum NetworkState {
    static var currentState = NetworkState.cellular
    case notReachable
    case ethernetOrWiFi
    case cellular
    init(_ flag: SCNetworkReachabilityFlags) {
        guard flag.isActuallyReachable else {
            self = .notReachable
            return
        }
        if flag.isCellular {
            self = .cellular
        }else {
            self = .ethernetOrWiFi
        }
    }
}

class NetworkStateManger {
    
    
    private var changeStateBlock: ((NetworkState) -> Void)?
    private let reachabilityQueue = DispatchQueue(label: "jh.netwrok.reachability")
    private var reachability: SCNetworkReachability!
    
    init() {
        reachabilityQueue.async {
            var zero = sockaddr()
            zero.sa_len = UInt8(MemoryLayout<sockaddr>.size)
            zero.sa_family = sa_family_t(AF_INET)
            guard let reachability = SCNetworkReachabilityCreateWithAddress(nil, &zero) else {
                return
            }
            self.reachability = reachability
        }
    }
    

    func startListening(listener: @escaping (NetworkState) -> Void) {
        changeStateBlock = listener
        func beginStart(){
            if reachability == nil {
                notifyListener(.reachable)
                return
            }

            var context = SCNetworkReachabilityContext(version: 0, info: Unmanaged.passRetained(self).toOpaque(), retain: nil, release: nil, copyDescription: nil)
            let callBack: SCNetworkReachabilityCallBack = {
                _,flags,info in
                guard let info = info else {
                    return
                }
                let instance = Unmanaged<NetworkStateManger>.fromOpaque(info).takeUnretainedValue()
                instance.notifyListener(flags)
            }
            _ = SCNetworkReachabilitySetDispatchQueue(reachability, reachabilityQueue)
            _ = SCNetworkReachabilitySetCallback(reachability, callBack, &context)
            var flags = SCNetworkReachabilityFlags()
            SCNetworkReachabilityGetFlags(reachability, &flags)
            
            reachabilityQueue.async {
                self.notifyListener(flags)
            }
        }
        reachabilityQueue.async {
            beginStart()
        }
        
    }
    
    
    private func notifyListener(_ flags: SCNetworkReachabilityFlags) {
        let newStatus = NetworkState(flags)
        NetworkState.currentState = newStatus
        DispatchQueue.main.async { 
            self.changeStateBlock?(newStatus)
        }
    }
}


extension SCNetworkReachabilityFlags {
    var isReachable: Bool { contains(.reachable) }
    var isConnectionRequired: Bool { contains(.connectionRequired) }
    var canConnectAutomatically: Bool { contains(.connectionOnDemand) || contains(.connectionOnTraffic) }
    var canConnectWithoutUserInteraction: Bool { canConnectAutomatically && !contains(.interventionRequired) }
    var isActuallyReachable: Bool { isReachable && (!isConnectionRequired || canConnectWithoutUserInteraction) }
    var isCellular: Bool {
        contains(.isWWAN)
    }
}










//
//  GSKDataManager.swift
//  GSKHub
//
//  Created by Simon Cook on 16/06/2017.
//  Copyright © 2017 Salesforce. All rights reserved.
//

import Foundation
import SalesforceSDKCore

class GSKDataManager {
    
    var gskNotifications = [GSKNotification]()
    
    // Can't init is singleton
    private init() {
        print("GSKDataManager:init()")
    }
    
    // MARK: Shared Instance
    
    static let shared = GSKDataManager()
    
}

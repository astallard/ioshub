//
//  GSKNotifcation.swift
//  GSKHub
//
//  Created by Simon Cook on 16/06/2017.
//  Copyright © 2017 Salesforce. All rights reserved.
//

import Foundation

class GSKNotification : CustomStringConvertible
{
    var title : String
    var type : String
    var sfid : String
    
    init() {
        title = ""
        type = ""
        sfid = ""
    }
    
    init(title: String, type: String, sfid: String) {
        self.title = title
        self.type = type
        self.sfid = sfid
    }
    
    var description: String {
        return "GSKNotification - title: \(title) type: \(type) sfid: \(sfid)"
    }
    
}

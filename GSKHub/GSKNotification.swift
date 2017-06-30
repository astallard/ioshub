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
    var actionLink : String
    var link : String
    
    init() {
        title = ""
        type = ""
        actionLink = ""
        link = ""
    }
    
    init(title: String, type: String, actionLink: String, link: String) {
        self.title = title
        self.type = type
        self.actionLink = actionLink
        self.link = link
    }
    
    var description: String {
        return "GSKNotification - title: \(title) type: \(type) actionLink: \(actionLink) link: \(link)"
    }
    
}

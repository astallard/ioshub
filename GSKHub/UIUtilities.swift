//
//  UIUtilities.swift
//  GSKHub
//
//  Created by Simon Cook on 13/06/2017.
//  Copyright © 2017 Salesforce. All rights reserved.
//

import Foundation
import UIKit

class UIUtilities {
    
    static func addBorderToView(view: UIView, color: CGColor, width: CGFloat) {
        view.layer.borderColor = color
        view.layer.borderWidth = width;
    }
}

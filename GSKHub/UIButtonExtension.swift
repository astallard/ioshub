//
//  UIButtonExtension.swift
//  GSKHub
//
//  Created by Simon Cook on 29/06/2017.
//  Copyright © 2017 Salesforce. All rights reserved.
//

import Foundation
import UIKit

extension UIButton {
    
    func shake() {
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
        animation.duration = 0.7
        animation.values = [-10.0, 10.0, -8.0, 8.0, -6.0, 6.0, -5.0, 5.0, 0.0 ]
        layer.add(animation, forKey: "shake")
    }
    
}

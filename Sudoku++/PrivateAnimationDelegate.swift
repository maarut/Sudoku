//
//  PrivateAnimationDelegate.swift
//  Sudoku++
//
//  Created by Maarut Chandegra on 02/03/2017.
//  Copyright © 2017 Maarut Chandegra. All rights reserved.
//

import UIKit

class PrivateAnimationDelegate: NSObject, CAAnimationDelegate
{
    var start: (() -> Void)?
    var end: (() -> Void)?
    
    init(startHandler: (() -> Void)? = nil, completionHandler: (() -> Void)? = nil)
    {
        start = startHandler
        end = completionHandler
    }
    
    func animationDidStart(_ anim: CAAnimation) {
        start?()
    }
    
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool)
    {
        end?()
    }
}

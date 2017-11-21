//
//  UIViewController+Extensions.swift
//  Sudoku++
//
//  Created by Maarut Chandegra on 27/07/2017.
//  Copyright © 2017 Maarut Chandegra. All rights reserved.
//

import UIKit

extension UIViewController
{
    enum ViewOrientation
    {
        case portrait
        case landscape
    }
    
    func isViewFullScreen(_ size: CGSize) -> Bool
    {
        if let screen = view.window?.screen {
            let screenWidth = min(screen.bounds.width, screen.bounds.height)
            let screenHeight = max(screen.bounds.width, screen.bounds.height)
            let viewWidth = min(size.width, size.height)
            let viewHeight = max(size.width, size.height)
            return screenWidth == viewWidth && screenHeight == viewHeight
        }
        return true
    }
    
    func orientation(ofSize size: CGSize) -> ViewOrientation
    {
        if isViewFullScreen(size) && size.width > size.height { return .landscape }
        return .portrait
    }
    
    var safetyArea: UIEdgeInsets {
        let safetyArea: UIEdgeInsets
        if #available(iOS 11, *) {
            safetyArea = view.safeAreaInsets
        }
        else {
            safetyArea = UIEdgeInsets.zero
        }
        return safetyArea
    }
}

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
    
    func orientation(ofSize size: CGSize) -> ViewOrientation
    {
        if size.width > size.height { return .landscape }
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

//
//  Utils.swift
//  Sudoku++
//
//  Created by Maarut Chandegra on 19/05/2017.
//  Copyright © 2017 Maarut Chandegra. All rights reserved.
//

import Foundation
import UIKit

public func statusBarHeight() -> CGFloat
{
    let statusBarHeight = UIApplication.shared.statusBarFrame.height
    if statusBarHeight > 0 { return statusBarHeight }
    if UIApplication.shared.statusBarOrientation.isLandscape &&
        UIDevice.current.userInterfaceIdiom != .pad {
        return statusBarHeight
    }
    return 20
}

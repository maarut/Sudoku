//
//  MainWindowConfigurer.swift
//  Sudoku++
//
//  Created by Maarut Chandegra on 18/02/2017.
//  Copyright © 2017 Maarut Chandegra. All rights reserved.
//

import UIKit

extension UIWindow
{
    static func buildWindow(for screen: UIScreen = UIScreen.main,
        with level: UIWindowLevel = UIWindowLevelNormal) -> UIWindow
    {
        let window = UIWindow(frame: screen.bounds)
        window.screen = screen
        window.windowLevel = level
        return window
    }
}

//
//  UIColor+Convenience.swift
//  Sudoku++
//
//  Created by Maarut Chandegra on 27/02/2017.
//  Copyright © 2017 Maarut Chandegra. All rights reserved.
//

import UIKit

extension UIColor
{
    convenience init(hexValue: Int, alpha: CGFloat = 1.0)
    {
        let red = CGFloat((hexValue >> 16) % 256) / 256.0
        let green = CGFloat((hexValue >> 8) % 256) / 256.0
        let blue = CGFloat(hexValue % 256) / 256.0
        
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
}

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

extension Array where Element: Equatable
{
    @discardableResult
    mutating func removeFirst(element: Element) -> Element?
    {
        return removeFirst(where: { $0 == element })
    }
}

extension Array
{
    @discardableResult
    mutating func removeFirst(where test: (Element) -> Bool) -> Element?
    {
        for i in self.indices {
            if test(self[i]) {
                let e = remove(at: i)
                return e
            }
        }
        return nil
    }
}

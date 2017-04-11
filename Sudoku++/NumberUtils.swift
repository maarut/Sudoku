//
//  Dispatch+Utils.swift
//  Sudoku++
//
//  Created by Maarut Chandegra on 11/04/2017.
//  Copyright © 2017 Maarut Chandegra. All rights reserved.
//

import Dispatch

extension Int
{
    var seconds: DispatchTime {
        let currentTime = DispatchTime.now()
        let offset = currentTime.uptimeNanoseconds + UInt64(self) * NSEC_PER_SEC
        return DispatchTime(uptimeNanoseconds: offset)
    }
}

extension Double
{
    var seconds: DispatchTime {
        let currentTime = DispatchTime.now()
        let offset = currentTime.uptimeNanoseconds + UInt64(self * Double(NSEC_PER_SEC))
        return DispatchTime(uptimeNanoseconds: offset)
    }
}

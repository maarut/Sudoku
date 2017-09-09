//
//  RoundedRectView.swift
//  Sudoku++
//
//  Created by Maarut Chandegra on 23/06/2017.
//  Copyright © 2017 Maarut Chandegra. All rights reserved.
//

import UIKit

extension UIRectCorner
{
    public static var none: UIRectCorner { return UIRectCorner(rawValue: 0) }
}

class RoundedRectView: UIView
{

    var roundedCorners: UIRectCorner = .none {
        didSet {
            self.layoutIfNeeded()
        }
    }
    var cornerRadius: CGFloat = 8.0
    
    override func layoutSubviews()
    {
        let mask = CAShapeLayer()
        mask.frame = CGRect(origin: CGPoint.zero, size: frame.size)
        let path = CGMutablePath()
        
        if roundedCorners.contains(.topLeft) {
            path.move(to: CGPoint(x: cornerRadius, y: 0))
        }
        else {
            path.move(to: CGPoint(x: 0, y: 0))
        }
        
        if roundedCorners.contains(.topRight) {
            path.addLine(to: CGPoint(x: frame.size.width - cornerRadius, y: 0))
            path.addArc(center: CGPoint(x: frame.size.width - cornerRadius, y: cornerRadius),
                radius: cornerRadius, startAngle: 1.5 * .pi, endAngle: 2 * .pi, clockwise: false)
        }
        else {
            path.addLine(to: CGPoint(x: frame.size.width, y: 0))
        }
        
        if roundedCorners.contains(.bottomRight) {
            path.addLine(to: CGPoint(x: frame.size.width, y: frame.size.height - cornerRadius))
            path.addArc(center: CGPoint(x: frame.size.width - cornerRadius, y: frame.size.height - cornerRadius),
                radius: cornerRadius, startAngle: 0, endAngle: 0.5 * .pi, clockwise: false)
        }
        else {
            path.addLine(to: CGPoint(x: frame.size.width, y: frame.size.height))
        }
        
        if roundedCorners.contains(.bottomLeft) {
            path.addLine(to: CGPoint(x: cornerRadius, y: frame.size.height))
            path.addArc(center: CGPoint(x: cornerRadius, y: frame.size.height - cornerRadius),
                radius: cornerRadius, startAngle: 0.5 * .pi, endAngle: .pi, clockwise: false)
        }
        else {
            path.addLine(to: CGPoint(x: 0, y: frame.size.height))
        }
         
        if roundedCorners.contains(.topLeft) {
            path.addLine(to: CGPoint(x: 0, y: cornerRadius))
            path.addArc(center: CGPoint(x: cornerRadius, y: cornerRadius),
                radius: cornerRadius, startAngle: .pi, endAngle: 1.5 * .pi, clockwise: false)
        }
        path.closeSubpath()
        mask.path = path
        layer.mask = mask
        super.layoutSubviews()
    }

}

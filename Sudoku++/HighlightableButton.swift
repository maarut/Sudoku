//
//  HighlightableButton.swift
//  Sudoku++
//
//  Created by Maarut Chandegra on 21/03/2017.
//  Copyright © 2017 Maarut Chandegra. All rights reserved.
//

import UIKit

class HighlightableButton: UIButton
{
    fileprivate weak var borderShape: CAShapeLayer!
    var buttonColour:                   UIColor = UIColor(hexValue: 0xF0F0DC)
    var buttonHighlightedColour:        UIColor = UIColor(hexValue: 0xFF0000)
    var buttonSelectedColour:           UIColor = UIColor(hexValue: 0xFFFFFF)
    var buttonBorderColour:             UIColor = UIColor(hexValue: 0xA0AAA0)
    var buttonHighlightedBorderColour:  UIColor = UIColor(hexValue: 0xFF0000)
    var buttonSelectedBorderColour:     UIColor = UIColor(hexValue: 0xFF0000)
    var buttonTextColour:               UIColor = UIColor(hexValue: 0x000000)
    var buttonHighlightedTextColour:    UIColor = UIColor(hexValue: 0xFFFFFF)
    var buttonSelectedTextColour:       UIColor = UIColor(hexValue: 0xFF0000)
    
    override init(frame: CGRect)
    {
        super.init(frame: frame)
        let borderShape = CAShapeLayer()
        self.borderShape = borderShape
        borderShape.fillColor = UIColor.clear.cgColor
        borderShape.strokeColor = buttonBorderColour.cgColor
        layer.addSublayer(borderShape)
        layer.mask = CAShapeLayer()
        layer.backgroundColor = buttonColour.cgColor
        setTitleColor(buttonTextColour, for: .normal)
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        buttonColour = aDecoder.decodeObject(forKey: "buttonColour") as! UIColor
        buttonHighlightedColour = aDecoder.decodeObject(forKey: "buttonHighlightedColour") as! UIColor
        buttonSelectedColour = aDecoder.decodeObject(forKey: "buttonSelectedColour") as! UIColor
        buttonBorderColour = aDecoder.decodeObject(forKey: "buttonBorderColour") as! UIColor
        buttonHighlightedBorderColour = aDecoder.decodeObject(forKey: "buttonHighlightedBorderColour") as! UIColor
        buttonSelectedBorderColour = aDecoder.decodeObject(forKey: "buttonSelectedBorderColour") as! UIColor
        buttonTextColour = aDecoder.decodeObject(forKey: "buttonTextColour") as! UIColor
        buttonHighlightedTextColour = aDecoder.decodeObject(forKey: "buttonHighlightedTextColour") as! UIColor
        buttonSelectedTextColour = aDecoder.decodeObject(forKey: "buttonSelectedTextColour") as! UIColor
        super.init(coder: aDecoder)
    }
    
    override func encode(with aCoder: NSCoder)
    {
        super.encode(with: aCoder)
        aCoder.encode(buttonColour, forKey: "buttonColour")
        aCoder.encode(buttonHighlightedColour, forKey: "buttonHighlightedColour")
        aCoder.encode(buttonSelectedColour, forKey: "buttonSelectedColour")
        aCoder.encode(buttonBorderColour, forKey: "buttonBorderColour")
        aCoder.encode(buttonHighlightedBorderColour, forKey: "buttonHighlightedBorderColour")
        aCoder.encode(buttonSelectedBorderColour, forKey: "buttonSelectedBorderColour")
        aCoder.encode(buttonTextColour, forKey: "buttonTextColour")
        aCoder.encode(buttonHighlightedTextColour, forKey: "buttonHighlightedTextColour")
        aCoder.encode(buttonSelectedTextColour, forKey: "buttonSelectedTextColour")
    }
    
    override func layoutSubviews()
    {
        super.layoutSubviews()
        let mask = layer.mask! as! CAShapeLayer
        mask.path = UIBezierPath(roundedRect: bounds, cornerRadius: frame.width / 2).cgPath
        let circleStrokeWidth = frame.width * 0.02
        var pathBounds = bounds
        pathBounds.origin.x += circleStrokeWidth
        pathBounds.origin.y += circleStrokeWidth
        pathBounds.size.width -= circleStrokeWidth * 2
        pathBounds.size.height -= circleStrokeWidth * 2
        let path = UIBezierPath(roundedRect: pathBounds, cornerRadius: frame.width / 2)
        path.lineWidth = circleStrokeWidth
        borderShape.path = path.cgPath
        
    }
    
    func highlight()
    {
        animate(circle: buttonHighlightedBorderColour.cgColor, background: buttonHighlightedColour.cgColor,
            text: buttonHighlightedTextColour)
    }
    
    func unhighlight()
    {
        animate(circle: buttonBorderColour.cgColor, background: buttonColour.cgColor,
            text: buttonTextColour)
    }
    
    func select()
    {
        animate(circle: buttonSelectedBorderColour.cgColor, background: buttonSelectedColour.cgColor,
            text: buttonSelectedTextColour)
    }
}

fileprivate extension HighlightableButton
{
    func animate(circle: CGColor, background: CGColor, text: UIColor)
    {
        let animation = CABasicAnimation(keyPath: "backgroundColor")
        animation.fromValue = layer.backgroundColor
        animation.toValue = background
        animation.duration = 0.3
        layer.add(animation, forKey: nil)
        layer.backgroundColor = background
        
        let circleAnimation = CABasicAnimation(keyPath: "strokeColor")
        circleAnimation.fromValue = borderShape.strokeColor
        circleAnimation.toValue = circle
        circleAnimation.duration = 0.3
        borderShape.add(circleAnimation, forKey: nil)
        borderShape.strokeColor = circle
        setTitleColor(text, for: .normal)
        
    }
    
}

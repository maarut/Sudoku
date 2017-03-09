//
//  NumberSelectionView.swift
//  Sudoku++
//
//  Created by Maarut Chandegra on 03/03/2017.
//  Copyright © 2017 Maarut Chandegra. All rights reserved.
//

import UIKit

protocol NumberSelectionViewDelegate: NSObjectProtocol
{
    func didSelect(number: Int)
    func didDeselect(number: Int)
}

class NumberSelectionView: UIView
{
    fileprivate let order: Int
    fileprivate let buttons: [UIButton]
    fileprivate var selectedNumber: Int?
    fileprivate let displayLargeNumbers: Bool
    
    var buttonColour:                   UIColor = UIColor(hexValue: 0xF0F0DC)
    var buttonHighlightedColour:        UIColor = UIColor(hexValue: 0xFF0000)
    var buttonSelectedColour:           UIColor = UIColor(hexValue: 0xFFFFFF)
    var buttonBorderColour:             UIColor = UIColor(hexValue: 0xA0AAA0)
    var buttonHighlightedBorderColour:  UIColor = UIColor(hexValue: 0xFF0000)
    var buttonSelectedBorderColour:     UIColor = UIColor(hexValue: 0xFF0000)
    var buttonTextColour:               UIColor = UIColor(hexValue: 0x000000)
    var buttonHighlightedTextColour:    UIColor = UIColor(hexValue: 0xFFFFFF)
    var buttonSelectedTextColour:       UIColor = UIColor(hexValue: 0xFF0000)
    
    weak var delegate: NumberSelectionViewDelegate?
    
    init(frame: CGRect, order: Int, buttonTitles: [String], displayLargeNumbers: Bool)
    {
        self.order = order
        buttons = buttonTitles.map {
            let button = UIButton(type: .custom)
            button.setTitle($0, for: .normal)
            let circleShape = CAShapeLayer()
            button.layer.addSublayer(circleShape)
            let mask = CAShapeLayer()
            button.layer.mask = mask
            return button
        }
        self.displayLargeNumbers = displayLargeNumbers
        super.init(frame: frame)
        for b in buttons {
            addSubview(b)
            b.addTarget(self, action: #selector(buttonTouchDown(_:)), for: [.touchDown, .touchDragEnter])
            b.addTarget(self, action: #selector(buttonTouchUpInside(_:)), for: .touchUpInside)
            b.addTarget(self, action: #selector(buttonDragExit(_:)), for: [.touchDragExit, .touchCancel])
        }
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        buttons = aDecoder.decodeObject(forKey: "buttons") as! [UIButton]
        order = aDecoder.decodeInteger(forKey: "order")
        selectedNumber = aDecoder.decodeObject(forKey: "selectedNumber") as! Int?
        displayLargeNumbers = aDecoder.decodeBool(forKey: "displayLargeNumbers")
        super.init(coder: aDecoder)
    }
    
    override func encode(with aCoder: NSCoder)
    {
        super.encode(with: aCoder)
        aCoder.encode(buttons, forKey: "buttons")
        aCoder.encode(order, forKey: "order")
        aCoder.encode(selectedNumber, forKey: "selectedNumber")
        aCoder.encode(displayLargeNumbers, forKey: "displayLargeNumbers")
    }
    
    override func layoutSubviews()
    {
        super.layoutSubviews()
        let totalSpacing = frame.width * 0.1
        let spacing = totalSpacing / CGFloat(order - 1)
        let buttonSize = CGSize(width: (frame.width - totalSpacing) / CGFloat(order),
            height: (frame.width - totalSpacing) / CGFloat(order))
        let fontSize = displayLargeNumbers ? buttonSize.width * 0.45 : buttonSize.width * 0.3
        for (i, button) in buttons.enumerated() {
            let xOffset = CGFloat(i % order) * (buttonSize.width + spacing)
            let yOffset = CGFloat(i / order) * (buttonSize.width + spacing)
            button.frame = CGRect(origin: CGPoint(x: xOffset, y: yOffset), size: buttonSize)
            button.setTitleColor(buttonTextColour, for: .normal)
            
            button.titleLabel!.font = button.titleLabel!.font.withSize(fontSize)
            button.layer.backgroundColor = buttonColour.cgColor
            let mask = button.layer.mask! as! CAShapeLayer
            mask.path = UIBezierPath(roundedRect: button.bounds, cornerRadius: buttonSize.width / 2).cgPath
            let circleStrokeWidth = buttonSize.width * 0.01
            var pathBounds = button.bounds
            pathBounds.origin.x += circleStrokeWidth
            pathBounds.origin.y += circleStrokeWidth
            pathBounds.size.width -= circleStrokeWidth * 2
            pathBounds.size.height -= circleStrokeWidth * 2
            let path = UIBezierPath(roundedRect: pathBounds, cornerRadius: buttonSize.width / 2)
            path.lineWidth = circleStrokeWidth
            let circleShape = button.layer.sublayers!.first! as! CAShapeLayer
            circleShape.path = path.cgPath
            circleShape.fillColor = UIColor.clear.cgColor
            circleShape.strokeColor = buttonBorderColour.cgColor
        }
    }
    
    
    func clearSelection()
    {
        guard let selectedNumber = selectedNumber else { return }
        animate(button: buttons[selectedNumber - 1], circle: buttonBorderColour.cgColor,
            background: buttonColour.cgColor, text: buttonTextColour)
        
        delegate?.didDeselect(number: selectedNumber)
        self.selectedNumber = nil
    }
}

fileprivate extension NumberSelectionView
{
    @objc func buttonTouchUpInside(_ sender: UIButton)
    {
        let newNumber = buttons.index(of: sender)! + 1
        let currentNumber = selectedNumber
        clearSelection()
        
        if newNumber != currentNumber {
            animate(button: sender, circle: buttonSelectedBorderColour.cgColor,
                background: buttonSelectedColour.cgColor, text: buttonSelectedTextColour)
            selectedNumber = newNumber
            delegate?.didSelect(number: newNumber)
        }
    }
    
    @objc func buttonTouchDown(_ sender: UIButton)
    {
        sender.layer.backgroundColor = buttonHighlightedColour.cgColor
        let circleShape = sender.layer.sublayers!.first! as! CAShapeLayer
        circleShape.strokeColor = buttonHighlightedBorderColour.cgColor
        circleShape.setNeedsDisplay()
        sender.setTitleColor(buttonHighlightedTextColour, for: .normal)
    }
    
    @objc func buttonDragExit(_ sender: UIButton)
    {
        if selectedNumber != nil && sender === buttons[selectedNumber! - 1] {
            animate(button: sender, circle: buttonSelectedBorderColour.cgColor,
                background: buttonSelectedColour.cgColor, text: buttonSelectedTextColour)
        }
        else {
            animate(button: sender, circle: buttonBorderColour.cgColor, background: buttonColour.cgColor,
                text: buttonTextColour)
        }
        
    }
    
    func animate(button: UIButton, circle: CGColor, background: CGColor, text: UIColor)
    {
        button.layer.removeAllAnimations()
        let animation = CABasicAnimation(keyPath: "backgroundColor")
        animation.fromValue = button.layer.backgroundColor
        animation.toValue = background
        animation.duration = 0.3
        button.layer.add(animation, forKey: "backgroundColour")
        button.layer.backgroundColor = background
        
        let circleShape = button.layer.sublayers!.first! as! CAShapeLayer
        let circleAnimation = CABasicAnimation(keyPath: "strokeColor")
        circleAnimation.fromValue = circleShape.strokeColor
        circleAnimation.toValue = circle
        circleAnimation.duration = 0.3
        circleShape.add(circleAnimation, forKey: "strokeColour")
        circleShape.strokeColor = circle
        
        button.setTitleColor(text, for: .normal)
    }
}

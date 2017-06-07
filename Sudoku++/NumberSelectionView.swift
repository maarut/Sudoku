//
//  NumberSelectionView.swift
//  Sudoku++
//
//  Created by Maarut Chandegra on 03/03/2017.
//  Copyright © 2017 Maarut Chandegra. All rights reserved.
//

import UIKit

protocol NumberSelectionViewDelegate: class
{
    func numberSelectionView(_ view: NumberSelectionView, didSelect number: Int)
}

class NumberSelectionView: UIView
{
    fileprivate let order: Int
    fileprivate let buttons: [HighlightableButton]
    fileprivate var selectedNumber: Int?
    fileprivate let displayLargeNumbers: Bool
    
    
    weak var delegate: NumberSelectionViewDelegate?
    
    init(frame: CGRect, order: Int, buttonTitles: [String], displayLargeNumbers: Bool)
    {
        self.order = order
        buttons = buttonTitles.map {
            let button = HighlightableButton()
            button.titleLabel?.font = UIFont(name: "Futura-Medium", size: button.titleLabel?.font.pointSize ?? 0)
            button.setTitle($0, for: .normal)
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
        buttons = aDecoder.decodeObject(forKey: "buttons") as! [HighlightableButton]
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
        frame.size.height = frame.width
        let totalSpacing = frame.width * 0.1
        let spacing = totalSpacing / CGFloat(order - 1)
        let buttonHeight = (frame.width - totalSpacing) / CGFloat(order)
        let buttonSize = CGSize(width: buttonHeight, height: buttonHeight)
        let fontSize = displayLargeNumbers ? buttonSize.width * 0.4 : buttonSize.width * 0.25
        for (i, button) in buttons.enumerated() {
            let xOffset = CGFloat(i % order) * (buttonSize.width + spacing)
            let yOffset = CGFloat(i / order) * (buttonSize.width + spacing)
            button.frame = CGRect(origin: CGPoint(x: xOffset, y: yOffset), size: buttonSize)
            
            button.titleLabel!.font = button.titleLabel!.font.withSize(fontSize)
        }
    }
    
    func select(number: Int)
    {
        guard number <= buttons.count else { return }
        if let selectedNumber = selectedNumber { buttons[selectedNumber - 1].reset() }
        buttons[number - 1].select()
        selectedNumber = number
    }
    
    func clearSelection()
    {
        for button in buttons { button.reset() }
        self.selectedNumber = nil
    }
}

fileprivate extension NumberSelectionView
{
    dynamic func buttonTouchUpInside(_ sender: HighlightableButton)
    {
        let newNumber = buttons.index(of: sender)! + 1
        delegate?.numberSelectionView(self, didSelect: newNumber)
    }

    dynamic func buttonTouchDown(_ sender: HighlightableButton)
    {
        sender.highlight()
    }
    
    dynamic func buttonDragExit(_ sender: HighlightableButton)
    {
        if selectedNumber != nil && sender === buttons[selectedNumber! - 1] {
            sender.select()
        }
        else {
            sender.reset()
        }
    }
}


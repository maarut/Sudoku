//
//  Cell.swift
//  Sudoku++
//
//  Created by Maarut Chandegra on 24/02/2017.
//  Copyright © 2017 Maarut Chandegra. All rights reserved.
//

import UIKit
import QuartzCore

private let FONT_SCALE_FACTOR: CGFloat = 0.65

// MARK: - CellView Implementation
class CellView: UIView
{
    var cellColour = UIColor(hexValue: 0xF0F0DC) { didSet { resetColours() } }
    var textColour = UIColor.black  { didSet { resetColours() } }
    
    var pencilMarkCount: Int { return pencilMarks.count }
    
    var highlightedCellBackgroundColour = UIColor.white { didSet { resetColours() } }
    var highlightedCellBorderColour = UIColor.red { didSet { resetColours() } }
    var highlightedCellTextColour = UIColor.red { didSet { resetColours() } }
    
    private (set) var isHighlighted = false
    private let order: Int
    private let pencilMarks: [UILabel]
    private weak var number: UILabel!

    // MARK: - Lifecycle
    init(frame: CGRect, order: Int, pencilMarkTitles: [String])
    {
        self.order = order
        pencilMarks = pencilMarkTitles.map {
            let pencilMarkFrame = CGRect.zero
            let l = UILabel(frame: pencilMarkFrame)
            l.text = $0
            l.textAlignment = .center
            l.isHidden = true
            return l
        }
        let v = UIView(frame: CGRect(origin: CGPoint.zero, size: frame.size))
        let number = UILabel()
        number.font = UIFont.systemFont(ofSize: frame.width * FONT_SCALE_FACTOR)
        number.textAlignment = .center
        number.adjustsFontSizeToFitWidth = true
        number.minimumScaleFactor = 0.5
        number.text = ""
        number.isHidden = true
        self.number = number
        v.addSubview(number)
        super.init(frame: frame)
        addSubview(v)
        for pm in pencilMarks {
            let view = UIView()
            view.addSubview(pm)
            addSubview(view)
        }
        backgroundColor = cellColour
        layer.borderColor = highlightedCellBorderColour.cgColor
    }
    
    convenience override init(frame: CGRect)
    {
        self.init(frame: frame, order: 0, pencilMarkTitles: [])
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        order = aDecoder.decodeInteger(forKey: "order")
        pencilMarks = aDecoder.decodeObject(forKey: "pencilMarks") as! [UILabel]
        cellColour = aDecoder.decodeObject(forKey: "cellColour") as! UIColor
        super.init(coder: aDecoder)
    }
    
    // MARK: - Overrides
    override func encode(with aCoder: NSCoder)
    {
        super.encode(with: aCoder)
        aCoder.encode(pencilMarks, forKey: "pencilMarks")
        aCoder.encode(order, forKey: "order")
        aCoder.encode(cellColour, forKey: "cellColour")
    }
    
    override func layoutSubviews()
    {
        super.layoutSubviews()
        let frame = CGRect(origin: CGPoint.zero, size: self.frame.size)
        number.superview?.frame = frame
        number.frame = frame
        number.font = number.font.withSize(self.frame.width * FONT_SCALE_FACTOR)
        let pencilMarkDims = frame.width / CGFloat(order)
        for (i, v) in pencilMarks.enumerated() {
            let xOffset = CGFloat(i % order) * pencilMarkDims
            let yOffset = CGFloat(i / order) * pencilMarkDims
            v.superview?.frame = CGRect(x: xOffset, y: yOffset, width: pencilMarkDims, height: pencilMarkDims)
            v.frame.size = CGSize(width: pencilMarkDims, height: pencilMarkDims)
            v.font = v.font.withSize(pencilMarkDims * FONT_SCALE_FACTOR)
        }
        
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView?
    {
        return self.point(inside: point, with: event) ? self : nil
    }
    
    // MARK: - Internal Functions
    func deselect()
    {
        guard isHighlighted else { return }
        isHighlighted = false
        let newBackgroundColour = cellColour.cgColor
        let width: CGFloat = 0.0
        let animationDelegate = PrivateAnimationDelegate(startHandler: nil) { _ in
            for pm in self.pencilMarks { pm.textColor = self.textColour }
        }
        let backgroundColour = CABasicAnimation(keyPath: "backgroundColor")
        backgroundColour.fromValue = layer.backgroundColor
        backgroundColour.toValue = newBackgroundColour
        backgroundColour.delegate = animationDelegate
        let borderWidth = CABasicAnimation(keyPath: "borderWidth")
        borderWidth.fromValue = layer.borderWidth
        borderWidth.toValue = width
        layer.add(borderWidth, forKey:  "borderWidth")
        layer.add(backgroundColour, forKey: "backgroundColour")
        layer.borderWidth = width
        layer.backgroundColor = newBackgroundColour
        number.textColor =  UIColor.black
    }
    
    func select()
    {
        guard !isHighlighted else { return }
        isHighlighted = true
        let newBackgroundColour = highlightedCellBackgroundColour.cgColor
        let width: CGFloat = frame.width * 0.05
        let backgroundColour = CABasicAnimation(keyPath: "backgroundColor")
        backgroundColour.fromValue = layer.backgroundColor
        backgroundColour.toValue = newBackgroundColour
        let borderWidth = CABasicAnimation(keyPath: "borderWidth")
        borderWidth.fromValue = layer.borderWidth
        borderWidth.toValue = width
        layer.add(borderWidth, forKey:  "borderWidth")
        layer.add(backgroundColour, forKey: "backgroundColour")
        layer.borderColor = highlightedCellBorderColour.cgColor
        layer.borderWidth = width
        layer.backgroundColor = newBackgroundColour
        number.textColor = highlightedCellTextColour
        for pm in pencilMarks { pm.textColor = highlightedCellTextColour }
    }
    
    func showPencilMark(inPosition position: Int)
    {
        guard position < pencilMarks.count else { return }
        let mark = pencilMarks[position]
        if mark.isHidden { show(view: mark) }
    }
    
    func hidePencilMark(inPosition position: Int)
    {
        guard position < pencilMarks.count else { return }
        let mark = pencilMarks[position]
        if !mark.isHidden { hide(view: mark, completionHandler: { _ in mark.isHidden = true } ) }
    }
    
    func setNumber(number: String)
    {
        if number.isEmpty {
            hide(view: self.number) { _ in self.number.text = number }
        }
        else {
            for i in 0 ..< pencilMarks.count { hidePencilMark(inPosition: i) }
            self.number.text = number
            show(view: self.number)
        }
    }
    
    private func resetColours()
    {
        if isHighlighted {
            backgroundColor = highlightedCellBackgroundColour
            number.textColor = highlightedCellTextColour
            layer.borderColor = highlightedCellBorderColour.cgColor
            for pm in pencilMarks { pm.textColor = highlightedCellTextColour }
        }
        else {
            backgroundColor = cellColour
            number.textColor = textColour
            for pm in pencilMarks { pm.textColor = textColour }
        }
    }
}

// MARK: - Private Functions
fileprivate extension CellView
{
    
    func show(view: UIView)
    {
        view.isHidden = false
        view.layer.opacity = 0.0
        view.layer.transform = CATransform3DMakeScale(0.5, 0.5, 1.0)
        let animation = CASpringAnimation(keyPath: "transform.scale")
        animation.fromValue = 0.5
        animation.toValue = 1.0
        animation.stiffness = 100
        animation.damping = 10
        animation.initialVelocity = -20
        animation.duration = animation.settlingDuration + 0.1
        let opacityAnimation = CABasicAnimation(keyPath: "opacity")
        opacityAnimation.fromValue = 0.0
        opacityAnimation.toValue = 1.0
        opacityAnimation.duration = 0.3
        view.layer.add(animation, forKey: "bounce")
        view.layer.add(opacityAnimation, forKey: "opacity")
        view.layer.opacity = 1.0
        view.layer.transform = CATransform3DIdentity
    }
    
    func hide(view: UIView, completionHandler f: ((Bool) -> Void)? = nil)
    {
        view.layer.transform = CATransform3DIdentity
        view.layer.removeAllAnimations()
        let animation = CASpringAnimation(keyPath: "transform.scale")
        animation.fromValue = 1.0
        animation.toValue = 2.0
        animation.stiffness = 100
        animation.damping = 10
        animation.initialVelocity = -20
        animation.duration = 0.3
        let opacity = CABasicAnimation(keyPath: "opacity")
        opacity.fromValue = 1.0
        opacity.toValue = 0.0
        opacity.duration = 0.3
        opacity.delegate = PrivateAnimationDelegate(completionHandler: f)
        view.layer.add(opacity, forKey: "opacity")
        view.layer.add(animation, forKey: "bounce")
        view.layer.transform = CATransform3DMakeScale(2.0, 2.0, 1.0)
        view.layer.opacity = 0.0
    }
}

//
//  Cell.swift
//  Sudoku++
//
//  Created by Maarut Chandegra on 24/02/2017.
//  Copyright © 2017 Maarut Chandegra. All rights reserved.
//

import UIKit
import QuartzCore

// MARK: - CellView Implementation
class CellView: UIView
{
    var cellColour: UIColor
    
    private let order: Int
    private var pencilMarks: [UILabel]
    private weak var number: UILabel!
    private var isHighlighted = false
 
    
    // MARK: - Lifecycle
    init(frame: CGRect, order: Int, pencilMarkTitles: [String], cellColour: UIColor)
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
        number.font = UIFont.systemFont(ofSize: frame.width * 0.75)
        number.textAlignment = .center
        number.adjustsFontSizeToFitWidth = true
        number.minimumScaleFactor = 0.5
        number.text = ""
        number.isHidden = true
        self.number = number
        self.cellColour = cellColour
        v.addSubview(number)
        super.init(frame: frame)
        addSubview(v)
        for pm in pencilMarks {
            let view = UIView()
            view.addSubview(pm)
            addSubview(view)
        }
        backgroundColor = cellColour
    }
    
    convenience override init(frame: CGRect)
    {
        self.init(frame: frame, order: 0, pencilMarkTitles: [], cellColour: UIColor.white)
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        order = aDecoder.decodeInteger(forKey: "order")
        pencilMarks = aDecoder.decodeObject(forKey: "pencilMarks") as! [UILabel]
        cellColour = aDecoder.decodeObject(forKey: "cellColour") as! UIColor
        super.init(coder: aDecoder)
    }
    
    deinit
    {
        pencilMarks = []
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
        let frame = CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height)
        number.superview?.frame = frame
        number.frame = frame
        number.font = number.font.withSize(self.frame.width * 0.75)
        let pencilMarkDims = frame.width / CGFloat(order)
        for (i, v) in pencilMarks.enumerated() {
            let xOffset = CGFloat(i % order) * pencilMarkDims
            let yOffset = CGFloat(i / order) * pencilMarkDims
            v.superview?.frame = CGRect(x: xOffset, y: yOffset, width: pencilMarkDims, height: pencilMarkDims)
            v.frame.size = CGSize(width: pencilMarkDims, height: pencilMarkDims)
            v.font = v.font.withSize(pencilMarkDims * 0.75)
        }
        
    }
    
    // MARK: - Internal Functions
    func highlight(withColour colour: UIColor?)
    {
        isHighlighted = !isHighlighted
        let newBackgroundColour = isHighlighted ? UIColor.white.cgColor : cellColour.cgColor
        let width: CGFloat = colour == nil ? 0.0 : 3.0
        let newBorderColour = colour?.cgColor ?? UIColor.clear.cgColor
        let backgroundColour = CABasicAnimation(keyPath: "backgroundColor")
        backgroundColour.fromValue = layer.backgroundColor
        backgroundColour.toValue = newBackgroundColour
        let borderColour = CABasicAnimation(keyPath: "borderColor")
        borderColour.fromValue = layer.borderColor
        borderColour.toValue = newBorderColour
        let borderWidth = CABasicAnimation(keyPath: "borderWidth")
        borderWidth.fromValue = layer.borderWidth
        borderWidth.toValue = width
        layer.add(borderColour, forKey: "borderColour")
        layer.add(borderWidth, forKey:  "borderWidth")
        layer.add(backgroundColour, forKey: "backgroundColour")
        layer.borderColor = newBorderColour
        layer.borderWidth = width
        layer.backgroundColor = newBackgroundColour
    }
    
    func toggleVisibilityOfPencilMark(inPosition position: Int)
    {
        guard position < pencilMarks.count else { return }
        let mark = pencilMarks[position]
        mark.isHidden ? show(view: mark) : hide(view: mark, completionHandler: { mark.isHidden = true } )
    }
    
    func setNumber(number: String)
    {
        if number.isEmpty {
            hide(view: self.number) { self.number.text = number }
        }
        else {
            for (i, pm) in pencilMarks.enumerated() { if !pm.isHidden { toggleVisibilityOfPencilMark(inPosition: i) } }
            self.number.text = number
            show(view: self.number)
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
    
    func hide(view: UIView, completionHandler f: (() -> Void)? = nil)
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

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
    fileprivate let pencilMarks: [UILabel]
    fileprivate weak var number: UILabel!
    fileprivate var perspective: CATransform3D = {
        var p = CATransform3DIdentity
        p.m34 = -1.0 / 100.0
        return p
    }()

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
    
    func flipTo(number: String, backgroundColour: UIColor, showingPencilMarksAtPositions pencilMarks: [Int])
    {
        if number == self.number.text && backgroundColour == cellColour {
            let newMarks = Set(pencilMarks)
            let visibleMarks = Set(self.pencilMarks.enumerated().flatMap( { !$0.element.isHidden ? $0.offset : nil } ))
            if newMarks == visibleMarks { return }
        }
        
        guard let currentSnapshots = getSnapshotOf(view: self) else { return }
        
        self.number.text = number
        self.number.isHidden = number.isEmpty
        self.cellColour = backgroundColour
        displayPencilMarksInPositions(pencilMarks)

        guard let newSnapshots = getSnapshotOf(view: self) else { return }
        let oldLayers = createLayersFromCurrentSnapshot(currentSnapshots)
        let newLayers = createLayersFromDestinationSnapshot(newSnapshots)
        let superLayer = superview!.layer
        superLayer.insertSublayer(oldLayers.bottom, above: layer)
        superLayer.insertSublayer(oldLayers.top, above: oldLayers.bottom)
        superLayer.insertSublayer(newLayers.top, below: oldLayers.top)
        superLayer.insertSublayer(newLayers.bottom, above: newLayers.top)
        
        let animationBeginTime = CACurrentMediaTime() + CFTimeInterval(arc4random() % 256) / 1000.0
        let animationDuration = 0.4
        
        let animation = CABasicAnimation(keyPath: "transform.rotation.x")
        animation.beginTime = animationBeginTime
        animation.timingFunction = CAMediaTimingFunction(controlPoints: 0.5, 0, 0.75, 0.5)
        animation.fillMode = kCAFillModeBoth
        animation.fromValue = 0.0
        animation.toValue = -CGFloat.pi
        animation.duration = animationDuration
        
        oldLayers.top.add(animation, forKey: "transform")
        oldLayers.top.setValue(-CGFloat.pi, forKey: "transform.rotation.x")
        
        animation.fromValue = CGFloat.pi
        animation.toValue = 0
        animation.byValue = -CGFloat.pi
        animation.delegate = PrivateAnimationDelegate(completionHandler: { _ in
            oldLayers.bottom.removeFromSuperlayer()
            oldLayers.top.removeFromSuperlayer()            
            newLayers.bottom.removeFromSuperlayer()
            newLayers.top.removeFromSuperlayer()
        })
        newLayers.bottom.add(animation, forKey: "transform")
        newLayers.bottom.setValue(0.0, forKey: "transform.rotation.x")
        
        let opacityAnimation = CABasicAnimation(keyPath: "opacity")
        opacityAnimation.fromValue = 1.0
        opacityAnimation.toValue = 0.0
        opacityAnimation.beginTime = animationBeginTime
        opacityAnimation.duration = animationDuration
        opacityAnimation.timingFunction = CAMediaTimingFunction(controlPoints: 1.0, 0.0, 1.0, 0.0)
        opacityAnimation.fillMode = kCAFillModeBackwards
        oldLayers.bottom.add(opacityAnimation, forKey: "opacity")
        oldLayers.top.add(opacityAnimation, forKey: "opacity")
        oldLayers.bottom.opacity = 0.0
        oldLayers.top.opacity = 0.0
        
    }
}

// MARK: - Private Drawing Functions
fileprivate extension CellView
{
    func createLayersFromDestinationSnapshot(
        _ snapshot: (top: CGImage, bottom: CGImage)) -> (top: CALayer, bottom: CALayer)
    {
        let topLayer = CALayer()
        topLayer.contents = snapshot.top
        topLayer.frame = self.frame
        topLayer.frame.size.height = topLayer.frame.height / 2
        topLayer.masksToBounds = false
        topLayer.isOpaque = true
        
        let bottomLayer = CALayer()
        bottomLayer.contents = snapshot.bottom
        bottomLayer.anchorPoint = CGPoint(x: 0.5, y: 0.0)
        bottomLayer.frame = topLayer.frame
        bottomLayer.frame.origin.y += topLayer.frame.height
        bottomLayer.setValue(perspective, forKey: "transform")
        bottomLayer.setValue(CGFloat.pi, forKey: "transform.rotation.x")
        bottomLayer.isDoubleSided = false
        bottomLayer.masksToBounds = false
        bottomLayer.isOpaque = true
        
        return (topLayer, bottomLayer)
    }
    
    func createLayersFromCurrentSnapshot(
        _ snapshot: (top: CGImage, bottom: CGImage)) -> (top: CALayer, bottom: CALayer)
    {
        
        let topLayer = CALayer()
        topLayer.contents = snapshot.top
        topLayer.frame = self.frame
        topLayer.frame.size.height = topLayer.frame.height / 2
        topLayer.frame.origin.y += topLayer.frame.height / 2
        topLayer.anchorPoint = CGPoint(x: 0.5, y: 1.0)
        topLayer.setValue(perspective, forKey: "transform")
        topLayer.isDoubleSided = false
        topLayer.masksToBounds = false
        topLayer.isOpaque = true
        
        let bottomLayer = CALayer()
        bottomLayer.contents = snapshot.bottom
        bottomLayer.frame = topLayer.frame
        bottomLayer.frame.origin.y += topLayer.frame.height
        bottomLayer.masksToBounds = false
        bottomLayer.isOpaque = true
        return (topLayer, bottomLayer)
    }
    
    func displayPencilMarksInPositions(_ positions: [Int])
    {
        var sortedPencilMarks = positions.sorted(by: <).makeIterator()
        var mark = sortedPencilMarks.next()
        for i in 0 ..< self.pencilMarks.count {
            if mark == i {
                self.pencilMarks[i].isHidden = false
                mark = sortedPencilMarks.next()
            }
            else {
                self.pencilMarks[i].isHidden = true
            }
        }
    }
    
    func getSnapshotOf(view: UIView) -> (top: CGImage, bottom: CGImage)?
    {
        UIGraphicsBeginImageContextWithOptions(view.frame.size, false, 0.0)
        defer { UIGraphicsEndImageContext() }
        view.drawHierarchy(in: view.bounds, afterScreenUpdates: true)
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        let rect = UIGraphicsGetCurrentContext()!.convertToDeviceSpace(view.bounds)
        let size = CGSize(width: rect.width, height: rect.height / 2.0)
        let bottomOrigin = CGPoint(x: 0, y: size.height)
        let topImage = image.cgImage?.cropping(to: CGRect(origin: CGPoint.zero, size: size))
        let bottomImage = image.cgImage?.cropping(to: CGRect(origin: bottomOrigin, size: size))
        if let topImage = topImage, let bottomImage = bottomImage { return (topImage, bottomImage) }
        return nil
    }
}

// MARK: - Private Functions
fileprivate extension CellView
{
    func resetColours()
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

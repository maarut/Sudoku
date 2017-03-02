//
//  SudokuView.swift
//  Sudoku++
//
//  Created by Maarut Chandegra on 01/03/2017.
//  Copyright © 2017 Maarut Chandegra. All rights reserved.
//

import UIKit

private let π: CGFloat = CGFloat(M_PI)
private let BOX_SPACING: CGFloat = 0.02
private let CELL_SPACING: CGFloat = 0.01

class SudokuView: UIView
{
    private var cells: [CellView]
    private let order: Int
    private let dimensionality: Int
    private var animator: UIDynamicAnimator!
    
    init(frame: CGRect, order: Int, pencilMarkTitles: [String])
    {
        let correctedFrame = CGRect(origin: frame.origin, size: CGSize(width: frame.width, height: frame.width))
        self.order = order
        dimensionality = order * order
        cells = (0 ..< dimensionality * dimensionality).map { _ in
            CellView(frame: CGRect.zero, order: order, pencilMarkTitles: pencilMarkTitles,
                cellColour: UIColor.lightGray)
        }
        super.init(frame: correctedFrame)
        for c in cells { addSubview(c) }
        animator = UIDynamicAnimator(referenceView: self)
    }
    
    override convenience init(frame: CGRect)
    {
        self.init(frame: frame, order: 0, pencilMarkTitles: [])
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        cells = aDecoder.decodeObject(forKey: "cells") as! [CellView]
        order = aDecoder.decodeInteger(forKey: "order")
        dimensionality = order * order
        super.init(coder: aDecoder)
        animator = UIDynamicAnimator(referenceView: self)
    }

    override func encode(with aCoder: NSCoder)
    {
        super.encode(with: aCoder)
        aCoder.encode(cells, forKey: "cells")
        aCoder.encode(order, forKey: "order")
    }
    
    override func layoutSubviews()
    {
        var correctedFrame = frame
        correctedFrame.size.height = correctedFrame.width
        frame = correctedFrame
        let dimensionality = order * order
        let boxSpacing = frame.width * BOX_SPACING
        let cellSpacing = frame.width * CELL_SPACING
        let cellSize = (frame.width - (boxSpacing * CGFloat((order - 1))) -
            cellSpacing * CGFloat(order * (order - 1))) / CGFloat(dimensionality)
        var yOffset: CGFloat = 0
        for row in 0 ..< dimensionality {
            var xOffset: CGFloat = 0
            for column in 0 ..< dimensionality {
                let origin = CGPoint(x: xOffset, y: yOffset)
                let cell = cells[row * dimensionality + column]
                cell.frame = CGRect(origin: origin, size: CGSize(width: cellSize, height: cellSize))
                xOffset += cellSize + (((column + 1) % order == 0) ? boxSpacing : cellSpacing)
            }
            yOffset += cellSize + (((row + 1) % order == 0) ? boxSpacing : cellSpacing)
        }
    }
    
    func cellAt(row: Int, column: Int) -> CellView
    {
        return cells[row * dimensionality + column]
    }
    
    func gameEnded()
    {
        animator.removeAllBehaviors()
        let gravity = UIGravityBehavior(items: [])
        for cell in cells {
            guard let snapshot = cell.snapshotView(afterScreenUpdates: false) else { continue }
            snapshot.frame = cell.frame
            cell.layer.opacity = 0.0
            addSubview(snapshot)
            let push = UIPushBehavior(items: [snapshot], mode: .instantaneous)
            let angle = (arc4random() % 90).radianValue + 5.0 / 4.0 * π
            push.setAngle(angle, magnitude: 0.5)
            push.setTargetOffsetFromCenter(generateOffset(for: snapshot), for: snapshot)
            animator.addBehavior(push)
            gravity.addItem(snapshot)
            let animation = CABasicAnimation(keyPath: "opacity")
            animation.fromValue = 1.0
            animation.toValue = 0.0
            animation.beginTime = CACurrentMediaTime() + 1.0
            animation.duration = 1.0
            animation.delegate = PrivateAnimationDelegate(
                startHandler: { snapshot.layer.opacity = 0.0 },
                completionHandler: {
                    self.animator.removeBehavior(push)
                    snapshot.removeFromSuperview()
                    let animation = CABasicAnimation(keyPath: "opacity")
                    animation.fromValue = 0.0
                    animation.toValue = 1.0
                    animation.beginTime = CACurrentMediaTime() + 0.5
                    animation.delegate = PrivateAnimationDelegate(startHandler: { cell.layer.opacity = 1.0 })
                    cell.layer.add(animation, forKey: "opacity")
            })
            snapshot.layer.add(animation, forKey: "opacity")
        }
        animator.addBehavior(gravity)
    }
}

fileprivate extension SudokuView
{
    func generateOffset(for view: UIView) -> UIOffset
    {
        let x = CGFloat(arc4random() % UInt32(view.frame.width / 2)) - view.frame.width
        let y = CGFloat(arc4random() % UInt32(view.frame.height / 2)) - view.frame.height
        return UIOffset(horizontal: x, vertical: y)
    }
}

fileprivate extension UInt32
{
    var radianValue: CGFloat { return π * CGFloat(self) / 180.0 }
}

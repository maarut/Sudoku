//
//  SudokuView.swift
//  Sudoku++
//
//  Created by Maarut Chandegra on 01/03/2017.
//  Copyright © 2017 Maarut Chandegra. All rights reserved.
//

import UIKit

private let π: CGFloat = CGFloat.pi
private let BOX_SPACING: CGFloat = 0.025
private let CELL_SPACING: CGFloat = 0.0075

private typealias Degree = UInt32

typealias SudokuBoardViewIndex = (row: Int, column: Int)

protocol SudokuViewDelegate: class
{
    func sudokuView(_ view: SudokuView, didSelectCellAt: (row: Int, column: Int))
}

// MARK: - SudokuView Implementation
class SudokuView: UIView
{
    fileprivate var cells: [CellView]
    fileprivate let order: Int
    fileprivate var animator: UIDynamicAnimator!
    private (set) var tapGestureRecogniser: UITapGestureRecognizer!
    
    let dimensionality: Int
    weak var delegate: SudokuViewDelegate?
    
    // MARK: - Lifecycle
    init(frame: CGRect, order: Int, pencilMarkTitles: [String])
    {
        self.order = order
        let dimensionality = order * order
        cells = (0 ..< dimensionality * dimensionality).map {
            let row = $0 / dimensionality
            let column = $0 % dimensionality
            return CellView(frame: CGRect.zero, order: order, pencilMarkTitles: pencilMarkTitles, index:
                SudokuBoardViewIndex(row: row, column: column))
        }
        self.dimensionality = dimensionality
        super.init(frame: frame)
        isUserInteractionEnabled = true
        let gestureRecogniser = UITapGestureRecognizer(target: self, action: #selector(tapRecognised(_:)))
        self.tapGestureRecogniser = gestureRecogniser
        addGestureRecognizer(gestureRecogniser)
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
    
    // MARK: - Overriden Functions
    override func layoutSubviews()
    {
        super.layoutSubviews()
        frame.size.height = frame.size.width
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
    
    // MARK: - Internal Functions
    func cellAt(_ index: SudokuBoardViewIndex) -> CellView?
    {
        guard index.row < dimensionality && index.column < dimensionality else { return nil }
        return cells[index.row * dimensionality + index.column]
    }
    
    func gameEnded()
    {
        guard !UIAccessibilityIsReduceMotionEnabled() else { return }
        animator.removeAllBehaviors()
        let gravity = UIGravityBehavior(items: [])
        for cell in cells {
            guard let snapshot = cell.snapshotView(afterScreenUpdates: false) else { continue }
            snapshot.frame = cell.frame
            cell.layer.opacity = 0.0
            addSubview(snapshot)
            let push = UIPushBehavior(items: [snapshot], mode: .instantaneous)
            let angle = Degree(arc4random() % 90).radianValue + 1.25 * π
            push.setAngle(angle, magnitude: pushMagnitude)
            push.setTargetOffsetFromCenter(generateOffset(for: snapshot), for: snapshot)
            animator.addBehavior(push)
            gravity.addItem(snapshot)
            let animation = CABasicAnimation(keyPath: "opacity")
            animation.fromValue = 1.0
            animation.toValue = 0.0
            animation.beginTime = snapshot.layer.convertTime(CACurrentMediaTime(), from: nil) + 0.5
            animation.duration = 1.25
            animation.delegate = PrivateAnimationDelegate(
                startHandler: { snapshot.layer.opacity = 0.0 },
                completionHandler: { _ in
                    self.animator.removeBehavior(push)
                    snapshot.removeFromSuperview()
                    let animation = CABasicAnimation(keyPath: "opacity")
                    animation.fromValue = 0.0
                    animation.toValue = 1.0
                    animation.beginTime = cell.layer.convertTime(CACurrentMediaTime(), from: nil) + 0.5
                    animation.delegate = PrivateAnimationDelegate(
                        startHandler: { [weak cell] in cell?.layer.opacity = 1.0 })
                    cell.layer.add(animation, forKey: "opacity")
            })
            snapshot.layer.add(animation, forKey: "opacity")
        }
        animator.addBehavior(gravity)
    }
}

// MARK: - Gesture Recognition
fileprivate extension SudokuView
{
    @objc func tapRecognised(_ recogniser: UITapGestureRecognizer)
    {
        let point = recogniser.location(in: self)
        if let tappedView = hitTest(point, with: nil) {
            let row: Int
            let column: Int
            if tappedView === self {
                row = nearestRow(yCoord: point.y)
                column = nearestColumn(xCoord: point.x)
            }
            else if let tappedView = tappedView as? CellView {
                let index = cells.index(of: tappedView)!
                row = index / (order * order)
                column = index % (order * order)
                
            }
            else { return }
            delegate?.sudokuView(self, didSelectCellAt: (row, column))
        }
    }
    
    func nearestRow(yCoord: CGFloat) -> Int
    {
        let heightOfCell = frame.height / CGFloat(order * order)
        let distance = yCoord / heightOfCell
        return Int(distance.rounded(.towardZero))
    }
    
    func nearestColumn(xCoord: CGFloat) -> Int
    {
        let widthOfCell = frame.width / CGFloat(order * order)
        let distance = xCoord / widthOfCell
        return Int(distance.rounded(.towardZero))
    }
}

// MARK: - Private Functions
fileprivate extension SudokuView
{
    func generateOffset(for view: UIView) -> UIOffset
    {
        let x = CGFloat(arc4random() % UInt32(view.frame.width / 2)) - view.frame.width
        let y = CGFloat(arc4random() % UInt32(view.frame.height / 2)) - view.frame.height
        return UIOffset(horizontal: x, vertical: y)
    }
}


fileprivate extension Degree
{
    var radianValue: CGFloat { return π * CGFloat(self) / 180.0 }
}

fileprivate extension SudokuView
{
    var pushMagnitude: CGFloat {
        if let width = self.superview?.frame.width, let height = self.superview?.frame.height {
            let divisor = CGFloat(768)
            let dim = min(width, height)
            return dim / divisor
        }
        return 0.5
        
    }
}

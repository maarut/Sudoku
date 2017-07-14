//
//  CardInteractionController.swift
//  Sudoku++
//
//  Created by Maarut Chandegra on 13/07/2017.
//  Copyright © 2017 Maarut Chandegra. All rights reserved.
//

import UIKit

class CardInteractionController: UIPercentDrivenInteractiveTransition
{
    var interactionInProgress = false
    private var shouldCompleteTransition = false
    private weak var viewController: UIViewController!
    
    func wireTo(viewController: UIViewController)
    {
        self.viewController = viewController
        prepareGestureRecognizers(forView: viewController.view)
    }

    private func prepareGestureRecognizers(forView view: UIView)
    {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(panGestureRecognised(_:)))
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapRecognised(_:)))
        view.addGestureRecognizer(pan)
        (UIApplication.shared.delegate as? AppDelegate)?.window?.addGestureRecognizer(tap)
        
    }
    
    dynamic private func tapRecognised(_ sender: UITapGestureRecognizer)
    {
        let tapLocation = sender.location(in: viewController.view)
        if !viewController.view.point(inside: tapLocation, with: nil) {
            viewController.dismiss(animated: true, completion: nil)
        }
    }
    
    dynamic private func panGestureRecognised(_ sender: UIPanGestureRecognizer)
    {
        let translation = sender.translation(in: sender.view!.superview!)
        if translation == .zero { return }
        let direction = determinePanDirection(translation)
        var progress = translation.y / sender.view!.window!.frame.height
        progress = min(max(progress, 0.0), 1.0)
        switch sender.state {
        case .changed:
            if !interactionInProgress {
                if direction == .down {
                    interactionInProgress = true
                    viewController.dismiss(animated: true, completion: nil)
                }
                else {
                    cancel()
                    sender.isEnabled = false
                    return
                }
            }
            shouldCompleteTransition = progress > 0.2
            update(progress)
        case .ended:
            interactionInProgress = false
            
            if !shouldCompleteTransition { cancel() }
            else { finish() }
            sender.isEnabled = true
        case .cancelled:
            interactionInProgress = false
            cancel()
            sender.isEnabled = true
        default: break
        }
    }
    
    private func determinePanDirection(_ point: CGPoint) -> UISwipeGestureRecognizerDirection?
    {
        switch (point.x, point.y) {
        case let (x, y) where abs(x) > abs(y) && x < 0:     return .left
        case let (x, y) where abs(x) >= abs(y) && x > 0:    return .right
        case let (x, y) where abs(y) > abs(x) && y < 0:     return .up
        case let (x, y) where abs(y) >= abs(x) && y > 0:    return .down
        default:                                            return nil
        }
    }
}

//
//  CardAnimationController.swift
//  Sudoku++
//
//  Created by Maarut Chandegra on 13/07/2017.
//  Copyright © 2017 Maarut Chandegra. All rights reserved.
//

import UIKit

class CardAnimationController: NSObject, UIViewControllerAnimatedTransitioning
{
    enum TransitionType
    {
        case presenting
        case dismissing
    }
    
    private let transitionType: TransitionType
    
    init(transitionType: TransitionType)
    {
        self.transitionType = transitionType
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval
    {
        return 0.25
    }
    
    private func dismissTranisition(using transitionContext: UIViewControllerContextTransitioning)
    {
        guard let fromVC = transitionContext.viewController(forKey: .from) else { return }
        
        UIView.animate(withDuration: transitionDuration(using: transitionContext), animations: {
            fromVC.view.frame.origin.y += fromVC.view.frame.height
        }, completion: { finished in
            if transitionContext.transitionWasCancelled {
                transitionContext.cancelInteractiveTransition()
                transitionContext.completeTransition(false)
            }
            else {
                transitionContext.finishInteractiveTransition()
                transitionContext.completeTransition(true)
            }
        })
    }
    
    private func presentTransition(using transitionContext: UIViewControllerContextTransitioning)
    {
        guard let fromVC = transitionContext.viewController(forKey: .from),
            let toVC = transitionContext.viewController(forKey: .to) else {
            return
        }
        let finalFrame = transitionContext.finalFrame(for: toVC)
        let initialFrame = CGRect(origin: CGPoint(x: finalFrame.origin.x, y: fromVC.view.frame.height),
            size: finalFrame.size)
        transitionContext.containerView.addSubview(toVC.view)
        toVC.view.frame = initialFrame
        
        UIView.animate(withDuration: transitionDuration(using: transitionContext), animations: {
            toVC.view.frame = finalFrame
        }, completion: { finished in
            if transitionContext.transitionWasCancelled {
                transitionContext.cancelInteractiveTransition()
                transitionContext.completeTransition(false)
            }
            else {
                transitionContext.finishInteractiveTransition()
                transitionContext.completeTransition(true)
            }
        })
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning)
    {
        switch transitionType {
        case .dismissing: dismissTranisition(using: transitionContext)
        case .presenting: presentTransition(using: transitionContext)
        }
    }
}

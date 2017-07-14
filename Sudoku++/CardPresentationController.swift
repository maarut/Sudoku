//
//  CardPresentationController.swift
//  Sudoku++
//
//  Created by Maarut Chandegra on 13/07/2017.
//  Copyright © 2017 Maarut Chandegra. All rights reserved.
//

import UIKit

class CardPresentationController: UIPresentationController
{
    private let cornerRadius: CGFloat = 10.0
    private let transformScale: CGFloat = 0.95
    
    private let dimmingView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(white: 0, alpha: 0.5)
        view.alpha = 0
        return view
    }()
    
    override var shouldPresentInFullscreen: Bool { return false }
    
    override var shouldRemovePresentersView: Bool { return false }
    
    override var frameOfPresentedViewInContainerView: CGRect {
        var presenterFrame = presentingViewController.view.frame
        presenterFrame.size.height *= 0.95
        presenterFrame.origin.y = presentingViewController.view.frame.height - presenterFrame.height
        return presenterFrame
    }
    
    override func presentationTransitionWillBegin()
    {
        guard let containerView = containerView, let presentedView = presentedView,
            let presentingView = presentingViewController.view,
            let transitionCoordinator = presentingViewController.transitionCoordinator else {
            return
        }
        
        let animation = CABasicAnimation(keyPath: "cornerRadius")
        animation.fromValue = 0.0
        animation.toValue = cornerRadius
        animation.duration = transitionCoordinator.transitionDuration
        
        dimmingView.frame.size = containerView.frame.size
        containerView.addSubview(dimmingView)
        containerView.addSubview(presentedView)
        
        
        transitionCoordinator.animate(alongsideTransition: { _ in
            presentingView.transform = CGAffineTransform(scaleX: self.transformScale, y: self.transformScale)
            presentingView.layer.add(animation, forKey: "cornerRadius")
            self.presentedViewController.setNeedsStatusBarAppearanceUpdate()
            self.dimmingView.alpha = 1.0
        })
    }
    
    override func presentationTransitionDidEnd(_ completed: Bool)
    {
        if !completed {
            dimmingView.removeFromSuperview()
        }
        else {
            presentingViewController.view.layer.cornerRadius = cornerRadius
        }
    }
    
    override func dismissalTransitionWillBegin()
    {
        guard let transitionCoordinator = presentingViewController.transitionCoordinator,
            let presentingView = presentingViewController.view else {
            return
        }
        let animation = CABasicAnimation(keyPath: "cornerRadius")
        animation.fromValue = cornerRadius
        animation.toValue = 0.0
        animation.duration = transitionCoordinator.transitionDuration
        
        transitionCoordinator.animateAlongsideTransition(in: presentingView, animation: { _ in
            self.dimmingView.alpha = 0.0
            presentingView.transform = .identity
            presentingView.layer.add(animation, forKey: "cornerRadius")
            self.presentingViewController.setNeedsStatusBarAppearanceUpdate()
        }, completion: nil)
    }
    
    override func dismissalTransitionDidEnd(_ completed: Bool) {
        guard let transitionCoordinator = presentingViewController.transitionCoordinator else { return }
        if !transitionCoordinator.isCancelled && completed {
            dimmingView.removeFromSuperview()
            presentingViewController.view.layer.cornerRadius = 0.0
        }
        
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator)
    {
        super.viewWillTransition(to: size, with: coordinator)
        
        guard let containerView = containerView else { return }
        coordinator.animate(alongsideTransition: { _ in self.dimmingView.frame = containerView.bounds })
    }
}

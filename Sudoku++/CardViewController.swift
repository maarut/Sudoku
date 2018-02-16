//
//  CardViewController.swift
//  Sudoku++
//
//  Created by Maarut Chandegra on 21/06/2017.
//  Copyright © 2017 Maarut Chandegra. All rights reserved.
//

import UIKit

protocol CardViewControllerDelegate: NSObjectProtocol
{
    func didSelectDismiss(_ cardViewController: CardViewController)
}

open class CardViewController: UIViewController
{
    override open var preferredStatusBarStyle: UIStatusBarStyle { return .lightContent }
    
    weak var delegate: CardViewControllerDelegate?
    var roundedCorners: UIRectCorner = [.topLeft, .topRight] {
        didSet {
            guard let view = view as? RoundedRectView else {
                fatalError("CardViewController constructed incorrectly")
            }
            view.roundedCorners = roundedCorners
        }
    }
    
    private weak var tapGesture: UITapGestureRecognizer!
    private weak var dismissButton: UIButton!
    fileprivate let interactionController = CardInteractionController()
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?)
    {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        let dismissButton = UIButton(type: .system)
        dismissButton.setTitle("﹀", for: .normal)
        dismissButton.setTitleColor(UIColor.black.withAlphaComponent(0.75), for: .normal)
        dismissButton.frame.size = dismissButton.intrinsicContentSize
        dismissButton.translatesAutoresizingMaskIntoConstraints = false
        dismissButton.addTarget(self, action: #selector(dismissTapped(_:)), for: .touchUpInside)
        self.dismissButton = dismissButton
        view.addSubview(dismissButton)
        NSLayoutConstraint.activate([
            dismissButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            dismissButton.topAnchor.constraint(equalTo: view.topAnchor)
            ])
        
        self.modalPresentationStyle = .custom
        self.transitioningDelegate = self
        interactionController.wireTo(viewController: self)
    }
    
    required public init?(coder aDecoder: NSCoder)
    {
        delegate = aDecoder.decodeObject(forKey: "delegate") as? CardViewControllerDelegate
        dismissButton = aDecoder.decodeObject(forKey: "dismissButton") as? UIButton
        super.init(coder: aDecoder)
    }
    
    override open func encode(with aCoder: NSCoder)
    {
        super.encode(with: aCoder)
        aCoder.encode(delegate, forKey: "delegate")
        aCoder.encode(dismissButton, forKey: "dismissButton")
    }
    
    /// Do not override this method! The visuals will be affected.
    override open func loadView()
    {
        let view = RoundedRectView()
        view.roundedCorners = roundedCorners
        self.view = view
    }
    
    override open func viewDidLoad()
    {
        super.viewDidLoad()
        modalPresentationCapturesStatusBarAppearance = true
    }
    
    override open func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(true)
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapRecognised(_:)))
        (UIApplication.shared.delegate as? AppDelegate)?.window?.addGestureRecognizer(tap)
        tapGesture = tap
    }
    
    @objc private func tapRecognised(_ sender: UITapGestureRecognizer)
    {
        let tapLocation = sender.location(in: view)
        if !view.point(inside: tapLocation, with: nil) {
            dismiss(animated: true, completion: nil)
        }
    }
    
    override open func viewDidDisappear(_ animated: Bool)
    {
        super.viewDidDisappear(animated)
        tapGesture.view?.removeGestureRecognizer(tapGesture)
        delegate?.didSelectDismiss(self)
        
    }
    
    @objc private func dismissTapped(_ sender: UIButton)
    {
        dismiss(animated: true, completion: nil)
    }
}

// MARK: - UIViewControllerTransitioningDelegate Implementation
extension CardViewController: UIViewControllerTransitioningDelegate
{
    public func presentationController(forPresented presented: UIViewController, presenting: UIViewController?,
                                source: UIViewController) -> UIPresentationController?
    {
        return CardPresentationController(presentedViewController: presented, presenting: presenting)
    }
    
    public func animationController(forPresented presented: UIViewController, presenting: UIViewController,
                             source: UIViewController) -> UIViewControllerAnimatedTransitioning?
    {
        return CardAnimationController(transitionType: .presenting)
    }
    
    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning?
    {
        return CardAnimationController(transitionType: .dismissing)
    }
    
    public func interactionControllerForDismissal(
        using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning?
    {
        return interactionController.interactionInProgress ? interactionController : nil
    }
}

// MARK: - CardPresentationController
private class CardPresentationController: UIPresentationController
{
    private var cornerRadius: CGFloat = 10.0
    private var transformScale: CGFloat = 0.95
    
    private let dimmingView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(white: 0, alpha: 0.5)
        view.alpha = 0
        return view
    }()
    
    private lazy var halfScreenPresentation: Bool =
    {
        if self.traitCollection.containsTraits(in: UITraitCollection(horizontalSizeClass: .compact)) ||
            self.traitCollection.containsTraits(in: UITraitCollection(verticalSizeClass: .compact)) {
            return false
        }
        self.transformScale = 1.0
        self.cornerRadius = 0.0
        return true
    }()
    
    override var shouldPresentInFullscreen: Bool { return false }
    
    override var shouldRemovePresentersView: Bool { return false }
    
    override var frameOfPresentedViewInContainerView: CGRect {
        var presenterFrame = presentingViewController.view.frame
        if halfScreenPresentation {
            presenterFrame.size.height *= 0.5
            presenterFrame.size.width *= 0.5
            presenterFrame.origin = presentingViewController.view.center
            presenterFrame.origin.y -= presenterFrame.size.height / 2
            presenterFrame.origin.x -= presenterFrame.size.width / 2
            (presentedViewController as? CardViewController)?.roundedCorners = .allCorners
        }
        else {
            presenterFrame.size.height *= 0.95
            presenterFrame.origin.y = presentingViewController.view.frame.height - presenterFrame.height
        }
        
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

// MARK: - CardAnimationController
private class CardAnimationController: NSObject, UIViewControllerAnimatedTransitioning
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
        
        UIView.animate(withDuration: transitionDuration(using: transitionContext), delay: 0, options: .curveLinear,
            animations: {
            fromVC.view.frame.origin.y = transitionContext.containerView.frame.height
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

// MARK: - CardInteractionController
private class CardInteractionController: UIPercentDrivenInteractiveTransition
{
    var interactionInProgress = false
    private var presentedViewOriginY: CGFloat = 0
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
        view.addGestureRecognizer(pan)
    }
    
    @objc private func panGestureRecognised(_ sender: UIPanGestureRecognizer)
    {
        let translation = sender.translation(in: sender.view!.superview!)
        var progress = translation.y / (sender.view!.superview!.frame.height - presentedViewOriginY)
        progress = min(max(progress, 0.0), 1.0)
        switch sender.state {
        case .began:
            interactionInProgress = true
            presentedViewOriginY = sender.view!.frame.origin.y
            viewController.dismiss(animated: true, completion: nil)
            update(progress)
        case .changed:
            shouldCompleteTransition = progress > 0.3
            update(progress)
        case .ended:
            interactionInProgress = false
            if !shouldCompleteTransition { cancel() }
            else { finish() }
            sender.isEnabled = true
        case .cancelled:
            interactionInProgress = false
            presentedViewOriginY = 0
            cancel()
            sender.isEnabled = true
        default: break
        }
    }
}


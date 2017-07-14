//
//  CardTransitioningDelegate
//  Sudoku++
//
//  Created by Maarut Chandegra on 13/07/2017.
//  Copyright © 2017 Maarut Chandegra. All rights reserved.
//

import UIKit

class CardTransitioningDelegate: NSObject, UIViewControllerTransitioningDelegate
{
    let interactionController = CardInteractionController()
    
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?,
        source: UIViewController) -> UIPresentationController?
    {
        return CardPresentationController(presentedViewController: presented, presenting: presenting)
    }
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController,
        source: UIViewController) -> UIViewControllerAnimatedTransitioning?
    {
        return CardAnimationController(transitionType: .presenting)
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning?
    {
        return CardAnimationController(transitionType: .dismissing)
    }
    
    func interactionControllerForDismissal(
        using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning?
    {
        return interactionController.interactionInProgress ? interactionController : nil
    }
}

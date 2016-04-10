//
//  PopAnimator.swift
//  App Store
//
//  Created by Jwlyan Macbook Pro on 4/9/16.
//  Copyright © 2016 Grability. All rights reserved.
//

import UIKit

class PopAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    let duration = 1.0
    
    func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval {
        return duration
    }
    
    func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
        let toView   = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey)?.view
        let fromView = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey)?.view
        
        UIView.transitionFromView(fromView!,
                                  toView: toView!,
                                  duration: transitionDuration(transitionContext),
                                  options: .TransitionFlipFromRight) { finished in
            transitionContext.completeTransition(true)
        }
        
        
    }
}

//
//  FirstAnimator.swift
//  App Store
//
//  Created by Jwlyan Macbook Pro on 4/9/16.
//  Copyright © 2016 Grability. All rights reserved.
//

import UIKit

class FirstAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    let duration = 1.0
    var presenting = true
    var originFrame = CGRect.zero
    
    func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval {
        return duration
    }
    
    func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView()!
        
        let toView = transitionContext.viewForKey(UITransitionContextToViewKey)!
        
        let appView = presenting ? toView : transitionContext.viewForKey(UITransitionContextFromViewKey)!
        
        let initialFrame = presenting ? originFrame : appView.frame
        let finalFrame = presenting ? appView.frame : originFrame
        
        let xScaleFactor = presenting ?
            initialFrame.width / finalFrame.width :
            finalFrame.width / initialFrame.width
        
        let yScaleFactor = presenting ?
            initialFrame.height / finalFrame.height :
            finalFrame.height / initialFrame.height
        
        let scaleTransform = CGAffineTransformMakeScale(xScaleFactor, yScaleFactor)
        
        if presenting {
            appView.transform = scaleTransform
            appView.center = CGPoint(
                x: CGRectGetMidX(initialFrame),
                y: CGRectGetMidY(initialFrame))
            appView.clipsToBounds = true
        }
        
        containerView.addSubview(toView)
        containerView.bringSubviewToFront(appView)
        
        UIView.animateWithDuration(duration, delay:0.0,
                                   usingSpringWithDamping: 0.4,
                                   initialSpringVelocity: 0.0,
                                   options: [],
                                   animations: {
                                    appView.transform = self.presenting ?
                                        CGAffineTransformIdentity : scaleTransform
                                    
                                    appView.center = CGPoint(x: CGRectGetMidX(finalFrame),
                                        y: CGRectGetMidY(finalFrame))
                                    
            }, completion:{_ in
                transitionContext.completeTransition(true)
        })
        
        let round = CABasicAnimation(keyPath: "cornerRadius")
        round.fromValue = presenting ? 20.0/xScaleFactor : 0.0
        round.toValue = presenting ? 0.0 : 20.0/xScaleFactor
        round.duration = duration / 2
        appView.layer.addAnimation(round, forKey: nil)
        appView.layer.cornerRadius = presenting ? 0.0 : 20.0/xScaleFactor
    }
}

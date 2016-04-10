//
//  NavigationControllerDelegate.swift
//  App Store
//
//  Created by Jwlyan Macbook Pro on 4/9/16.
//  Copyright © 2016 Grability. All rights reserved.
//

import UIKit

class NavigationControllerDelegate: NSObject, UINavigationControllerDelegate {
    func navigationController(
        navigationController: UINavigationController,
        animationControllerForOperation operation: UINavigationControllerOperation,
                                        fromViewController fromVC: UIViewController,
                                                           toViewController toVC: UIViewController
        ) -> UIViewControllerAnimatedTransitioning? {
        
        if fromVC is CategoriesViewController && toVC is AppsViewController {
            return FirstAnimator()
        }
        
        if let appsViewController = fromVC as? AppsViewController where toVC is AppViewController {
            let animator = FirstAnimator()
            guard let image = appsViewController.selectedCellImage else {
                return nil
            }
            animator.originFrame = image.superview!.convertRect(image.frame, toView: nil)
            animator.presenting = true
            return animator
        }
        
        return PopAnimator()
    }
}

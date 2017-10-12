//
//  AlertViewHelper.swift
//  On The Map
//
//  Created by Pete Barnes on 9/19/17.
//  Copyright © 2017 Pete Barnes. All rights reserved.
//

import UIKit

class AlertViewHelper {

    static func presentAlert(_ viewController: UIViewController, title: String, message: String?) {
        
        let controller = UIAlertController()
        controller.title = title
        controller.message = message
        
        let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default) { action in controller.dismiss(animated: true, completion: nil)
        }
        
        controller.addAction(okAction)
        viewController.present(controller, animated: true, completion: nil)
    }
}

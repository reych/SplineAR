//
//  RouterManager.swift
//  SplineAR
//
//  Created by Chen, Rena on 8/9/17.
//  Copyright © 2017 Chen, Rena. All rights reserved.
//

import UIKit

class RouterManager: NSObject {
    
    // Singleton
    static let shared = RouterManager()
    
    // MARK: - Properties
    var routers = [Router]()
    var selectedRouter: Router?
    
    func addRouter(_ router: Router) {
        routers.append(router)
        selectedRouter = router
    }
    
    func deleteRouter(_ router: Router) {
        
    }
    
    
    

}

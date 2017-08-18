//
//  StepNode.swift
//  SplineAR
//
//  Created by Chen, Rena on 8/10/17.
//  Copyright © 2017 Chen, Rena. All rights reserved.
//

import UIKit
import SceneKit

class StepNode: SCNNode {
    var informationNode: SCNNode = SCNNode()
    
    func displayInformation() {
        self.addChildNode(informationNode)
    }
    
    func hideInformation() {
        informationNode.removeFromParentNode()
    }

}

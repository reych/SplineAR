//
//  Tool.swift
//  SplineAR
//
//  Created by Chen, Rena on 8/9/17.
//  Copyright © 2017 Chen, Rena. All rights reserved.
//

import UIKit
import SceneKit

class Tool: SCNNode {
    
    var spline = CRSpline()
    var loaded = false
    
    func loadObject(_ path: String) {
        
        if !loaded {
            let geometry = SCNNode()
            if let scene = SCNScene(named: path) {
                let objNode = scene.rootNode
                for node in objNode.childNodes {
                    geometry.addChildNode(node)
                }
            }
            self.addChildNode(geometry)
            configureSpline()
            loaded = true
        }
    }
    
    // anchor spline to the object geometry
    private func configureSpline() {
        let tip = SCNNode()
        let second = SCNNode()
        let third = SCNNode()
        let end = SCNNode()
        spline.addControlPoint(tip)
        
    }
    
}

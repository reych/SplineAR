//
//  Plane.swift
//  SplineAR
//
//  Created by Chen, Rena on 8/10/17.
//  Copyright © 2017 Chen, Rena. All rights reserved.
//

import UIKit
import ARKit

class Plane: SCNNode {
    var anchor: ARAnchor!
    
    var planeGeometry: SCNBox!
    var planeNode: SCNNode!
    
    init(anchor: ARPlaneAnchor) {
        super.init()
        
        self.anchor = anchor
        let planeHeight: CGFloat = 0.005
        let width = CGFloat(anchor.extent.x)
        let length = CGFloat(anchor.extent.z)
        
        planeGeometry = SCNBox(width: width, height: planeHeight, length: length, chamferRadius: 0)
        planeGeometry.firstMaterial?.transparency = 0.1
        
        planeNode = SCNNode(geometry: planeGeometry)
        
        planeNode.physicsBody = SCNPhysicsBody(type: SCNPhysicsBodyType.static, shape: SCNPhysicsShape(geometry: planeGeometry, options: nil))
        
        self.addChildNode(planeNode)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func update(anchor: ARPlaneAnchor) {
        planeGeometry.width = CGFloat(anchor.extent.x);
        planeGeometry.length = CGFloat(anchor.extent.z);
        
        position = SCNVector3Make(anchor.center.x, 0, anchor.center.z)
        planeNode.physicsBody = SCNPhysicsBody(type: SCNPhysicsBodyType.static, shape: SCNPhysicsShape(geometry: planeGeometry, options: nil))
        
        
        
    }
    
}

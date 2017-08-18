//
//  Router.swift
//  SplineAR
//
//  Created by Chen, Rena on 8/9/17.
//  Copyright © 2017 Chen, Rena. All rights reserved.
//

import UIKit
import SceneKit

class Router: SCNNode {
    
    enum RouterState {
        case ethernet
        case power
        case dsl
        case homenetwork
        case usb
        case none
    }
    
    var ethernetPort: SCNNode?
    var dslPort: SCNNode?
    var powerPort: SCNNode?
    var homenetworkPort: SCNNode?
    
    var state: RouterState = .none
    var paths = [RouterState: [StepNode]]()
    
    override init() {
        super.init()
        
        // Load router model
        let geometry = SCNNode()
        if let routerScene = SCNScene(named: "art.scnassets/router.scn") {
            let routerNode = routerScene.rootNode
            for node in routerNode.childNodes {
                geometry.addChildNode(node)
                
                if node.name == "ethernet" {
                    ethernetPort = node
                } else if node.name == "dsl" {
                    dslPort = node
                } else if node.name == "homenetwork" {
                    homenetworkPort = node
                } else if node.name == "power" {
                    powerPort = node
                } else if node.name == "box" {
                    print(node.boundingBox)
                }
            }
        }
        
        // Bounds geometry
        let boundingBox = SCNBox(width: 0.213, height: 0.062, length: 0.171, chamferRadius: 0)
        let physicsShape = SCNPhysicsShape(geometry: boundingBox, options: nil)
        
        // Physics
        geometry.physicsBody = SCNPhysicsBody(type: SCNPhysicsBodyType.dynamic, shape: physicsShape)
        
        geometry.physicsBody?.mass = 10.0
        geometry.physicsBody?.categoryBitMask = Int(SCNPhysicsCollisionCategory.default.rawValue)
        
        self.addChildNode(geometry)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    
    // Display the relevant path for the tool.
    func displayPathFor(_ state: RouterState) -> SCNNode? {
        switch state {
        case .ethernet:
            print("ethernet")
            return configureEthernet()
        case .power:
            print("power")
            return configurePower()
        case .dsl:
            print("dsl")
            return configureDSL()
        case .homenetwork:
            print("homenetwork")
            return nil
        case .usb:
            print("usb")
            return nil
        case .none:
            print("none")
            return nil
        default:
            print("default")
            return nil
        }
    }
    
    private func configureEthernet() -> SCNNode {
        let parentNode = SCNNode()
        
        let geometry1 = SCNPlane()
        let step1 = StepNode()
        step1.informationNode = SCNNode(geometry: geometry1)
        step1.position = SCNVector3(0, 0.05, 0)
        
        let step2 = StepNode()
        
        parentNode.addChildNode(step1)
        parentNode.addChildNode(step2)
        
        
        self.addChildNode(parentNode)
        return parentNode
    }
    
    private func configureDSL() -> SCNNode {
        let parentNode = SCNNode()
        return parentNode
    }
    
    private func configurePower() -> SCNNode {
        let parentNode = SCNNode()
        return parentNode
    }
}

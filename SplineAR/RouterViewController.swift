//
//  RouterViewController.swift
//  SplineAR
//
//  Created by Chen, Rena on 8/9/17.
//  Copyright © 2017 Chen, Rena. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class RouterViewController: UIViewController, ARSCNViewDelegate {
    
    @IBOutlet var sceneView: ARSCNView!
    
    let session = ARSession()
    var sessionConfig: ARSessionConfiguration = ARWorldTrackingSessionConfiguration()
    
    var routers = [Router]()
    var selectedRouter: SCNNode? // Router currently interacting with.
    var currentTool: Tool?
    var currentToolIndex: Int = 0 // Index do we need this?
    let toolCount = 4;
    var touchLocation: CGPoint?
    
    var ethernet: Tool!
    var dsl: Tool!
    var power: Tool!
    
    var indicatorSphere: SCNNode!
    
    
    // Planes
    var planes = [ARPlaneAnchor: Plane]()
    var lastPlanePosition: SCNVector3?
    
     // list of possible tools
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // Create a new scene
        let scene = SCNScene(named: "art.scnassets/ship.scn")!
        sceneView.automaticallyUpdatesLighting = true
        enableEnvironmentMapWithIntensity(25)
        
        // Set the scene to the view
        sceneView.scene = scene
        
        setupScene()
        setupTools()
        setupGestures()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingSessionConfiguration()
        configuration.planeDetection = .horizontal
        
        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Create a session configuration
        let configuration = ARWorldTrackingSessionConfiguration()
        configuration.planeDetection = .horizontal
        
        // Run the view's session
        sceneView.session.run(configuration)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setupScene() {
        // set up sceneView
        sceneView.delegate = self
        sceneView.session = session
        sceneView.antialiasingMode = .multisampling4X
        sceneView.automaticallyUpdatesLighting = true
        
        sceneView.preferredFramesPerSecond = 60
        sceneView.contentScaleFactor = 1.3
        //sceneView.showsStatistics = true
        
        enableEnvironmentMapWithIntensity(25.0)
        
        
        if let camera = sceneView.pointOfView?.camera {
            camera.wantsHDR = true
            camera.wantsExposureAdaptation = true
            camera.exposureOffset = -1
            camera.minimumExposure = -1
        }
    }
    
    func setupGestures() {
        let singleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(singleTap(_:)))
        singleTapRecognizer.numberOfTapsRequired = 1
        let swipeUpRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(swipeUp(_:)))
        swipeUpRecognizer.direction = .up
        let swipeRightRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(swipeRight(_:)))
        swipeRightRecognizer.direction = .right
        let swipeLeftRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(swipeLeft(_:)))
        swipeLeftRecognizer.direction = .left
        
        self.view.addGestureRecognizer(singleTapRecognizer)
        self.view.addGestureRecognizer(swipeUpRecognizer)
        self.view.addGestureRecognizer(swipeRightRecognizer)
        self.view.addGestureRecognizer(swipeLeftRecognizer)
    }
    
    func setupTools() {
        ethernet = Tool()
        ethernet.loadObject("art.scnassets/ethernet.scn")
        dsl = Tool()
        dsl.loadObject("art.scnassets/dsl.scn")
        power = Tool()
        power.loadObject("art.scnassets/power.scn")
        
        // Animation
        let moveUp = SCNAction.move(by: SCNVector3Make(0, 0.2, 0), duration: 2.0)
        let moveDown = SCNAction.move(by: SCNVector3Make(0, -0.2, -0), duration: 2.0)
        moveUp.timingMode = .easeInEaseOut
        moveDown.timingMode = .easeInEaseOut
        let moveSequence = SCNAction.sequence([moveUp, moveDown])
        let moveLoop = SCNAction.repeatForever(moveSequence)
        indicatorSphere = SCNNode(geometry: SCNSphere(radius: 0.002))
        indicatorSphere.runAction(moveLoop)
    }
    
    func enableEnvironmentMapWithIntensity(_ intensity: CGFloat) {
        if sceneView.scene.lightingEnvironment.contents == nil {
            if let environmentMap = UIImage(named: "art.scnassets/environment_blur.exr") {
                sceneView.scene.lightingEnvironment.contents = environmentMap
            }
        }
        sceneView.scene.lightingEnvironment.intensity = intensity
    }
    
    // MARK: - Gesture responders
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        print("touches began")
        // Select node
        if let location = touches.first?.location(in: sceneView) {
            touchLocation = location
        }
    }
    
    // Single tap gesture
    @objc func singleTap(_ sender: UIGestureRecognizer) {
        
        switch currentToolIndex {
        case 0:
            print(0)
            if let hit = sceneView.hitTest(touchLocation!, types: ARHitTestResult.ResultType.existingPlaneUsingExtent).first {
                insertRouterAt(hit)
            }
        case 1:
            // Ethernet
            print(1)
            if let hit = sceneView.hitTest(touchLocation!, options: nil).first {
                for router in routers {
                    if hit.node == router.ethernetPort {
                        print("found port!")
                        router.ethernetPort?.addChildNode(currentTool!)
                        currentTool?.position = SCNVector3Make(-0.01, 0.02, 0.12)
                        //currentTool?.rotation = SCNVector4Make(1, 0, 0, .pi)
                    }
                }
            }
            
        case 2:
            // DSL
            print(2)
            if let hit = sceneView.hitTest(touchLocation!, options: nil).first {
                for router in routers {
                    if hit.node == router.dslPort {
                        print("found port!")
                        router.ethernetPort?.addChildNode(currentTool!)
                        currentTool?.position = SCNVector3Make(-0.065, 0.02, 0.085)
                    }
                }
            }
        case 3:
            // Power
            print(3)
            if let hit = sceneView.hitTest(touchLocation!, options: nil).first {
                for router in routers {
                    if hit.node == router.powerPort {
                        print("found port!")
                        router.ethernetPort?.addChildNode(currentTool!)
                        currentTool?.position = SCNVector3Make(-0.09, 0.02, 0.13)
                    }
                }
            }
        case 4:
            print(4)
        default:
            print("default")
        }
        
        
    }
    
    // Swipe up gesture
    @objc func swipeUp(_ sender: UIGestureRecognizer) {
        let actionSheetController = UIAlertController(title: "Options", message: "Choose an action", preferredStyle: .actionSheet)
        let cancelActionButton = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let switchActionButton = UIAlertAction(title: "Switch", style: .default, handler: {_ in
            self.dismiss(animated: true, completion: nil)
        })
        let nukeActionButton = UIAlertAction(title: "Nuke routers", style: .destructive, handler: {_ in
            for router in self.routers {
                router.removeFromParentNode()
            }
            self.routers = [Router]()
        })
        
        actionSheetController.addAction(cancelActionButton)
        actionSheetController.addAction(switchActionButton)
        actionSheetController.addAction(nukeActionButton)
        
        self.present(actionSheetController, animated: true, completion: nil)
    }
    
    @objc func swipeRight(_ sender: UIGestureRecognizer) {
        
        if currentToolIndex-1 >= 0 {
            currentToolIndex -= 1
        }
        print(currentToolIndex)
        setCurrentTool()
        
        
    }
    
    @objc func swipeLeft(_ sender: UIGestureRecognizer) {
        if currentToolIndex+1 < toolCount {
            currentToolIndex += 1
        }
        print(currentToolIndex)
        setCurrentTool()
    }
    
    func setCurrentTool() {
        currentTool?.removeFromParentNode()
        currentTool = nil
        
        var translateMatrix = matrix_identity_float4x4
        translateMatrix.columns.3.z = -0.15
        var transform = matrix_identity_float4x4
        if let camera = camera() {
            transform = simd_mul(camera.transform, translateMatrix)
        }
        switch currentToolIndex {
        case 0:
            print(0)
            
        case 1:
            // Ethernet
            print(1)
            currentTool = ethernet
            
            ethernet.position = SCNVector3(x: transform.columns.3.x, y: transform.columns.3.y, z: transform.columns.3.z)
            ethernet.rotation = SCNVector4Make(1, 0, 0, .pi * -0.5)
            sceneView.scene.rootNode.addChildNode(currentTool!)
            
            if let cameraNode = sceneView.pointOfView {
                currentTool!.position = SCNVector3Make(0, -0.05, -0.15)
                cameraNode.addChildNode(currentTool!)
            }
            
        case 2:
            // DSL
            print(2)
            currentTool = dsl
            dsl.position = SCNVector3(x: transform.columns.3.x, y: transform.columns.3.y, z: transform.columns.3.z)
            dsl.rotation = SCNVector4Make(1, 0, 0, .pi * -0.5)
            
            if let cameraNode = sceneView.pointOfView {
                currentTool!.position = SCNVector3Make(0, -0.05, -0.15)
                cameraNode.addChildNode(currentTool!)
            }
            
        case 3:
            // Power
            print(3)
            currentTool = power
            power.position = SCNVector3(x: transform.columns.3.x, y: transform.columns.3.y, z: transform.columns.3.z)
            power.rotation = SCNVector4Make(1, 0, 0, .pi * -0.5)
            
            if let cameraNode = sceneView.pointOfView {
                currentTool!.position = SCNVector3Make(0, -0.05, -0.15)
                cameraNode.addChildNode(currentTool!)
            }
        case 4:
            print(4)
        default:
            print("default")
        }
    }
    
    func camera() -> ARCamera? {
        if let currentFrame = sceneView.session.currentFrame {
            return currentFrame.camera
        }
        return nil
    }
    
    func insertRouterAt(_ hit: ARHitTestResult) {
        let node = Router()
        // Physics
        //node.physicsBody = SCNPhysicsBody(type: SCNPhysicsBodyType.dynamic, shape: nil)
        
        //node.physicsBody?.mass = 5.0
        //node.physicsBody?.categoryBitMask = Int(SCNPhysicsCollisionCategory.default.rawValue)
        
        
        
        // Drop the object
        let insertionYOffset: Float = 0.3
        
//        if let currentFrame = sceneView.session.currentFrame {
//            var translate = matrix_identity_float4x4
//            translate.columns.3.x = hit.worldTransform.columns.3.x
//            translate.columns.3.y = hit.worldTransform.columns.3.y + insertionYOffset
//            translate.columns.3.z = hit.worldTransform.columns.3.z
//            let transform = simd_mul(currentFrame.camera.transform, translate)
//
//            node.simdTransform = transform
//            node.rotation = SCNVector4Make(<#T##x: Float##Float#>, <#T##y: Float##Float#>, <#T##z: Float##Float#>, <#T##w: Float##Float#>)
//
//        }
        
        
        node.position = SCNVector3Make(
            hit.worldTransform.columns.3.x,
            hit.worldTransform.columns.3.y + insertionYOffset,
            hit.worldTransform.columns.3.z
        )
        // Add to scene
        sceneView.scene.rootNode.addChildNode(node)
        
        //node.physicsBody?.allowsResting = true
        // Add the cube to an internal list for book-keeping
        RouterManager.shared.addRouter(node)
        routers.append(node)
    }
    
    // MARK: - Plane detection
    
    // MARK: - Update tool positions
    func updateCurrentToolPosition() {
        if let tool = currentTool {
            if let cameraNode = sceneView.pointOfView {
                tool.position = SCNVector3Make(0, -0.15, -0.15)
                cameraNode.addChildNode(tool)
            }
            if let currentFrame = sceneView.session.currentFrame {
    
            var translateMatrix = matrix_identity_float4x4
            translateMatrix.columns.3.z = -0.15
    
            let transform = simd_mul(currentFrame.camera.transform, translateMatrix)
            tool.simdTransform = transform
    
            //print(tool.eulerAngles)
            let rotateZ = SCNVector4Make(0, 0, 1, .pi * -0.5)
    
            print(tool.rotation)
    
            }
        }
    }
    
    // Check if node should be highlighted
    func checkForPort() {
        if let currentFrame = sceneView.session.currentFrame {
            switch currentToolIndex {
            case 0:
                print(0)
            case 1:
                print(1)
                if let hit = sceneView.hitTest(sceneView.bounds.mid, options: nil).first {
                    
                    for router in routers {
                        if hit.node == router.ethernetPort {
                            print("found port!")
                        }
                    }
                }
            case 2:
                print(2)
                
                
            default:
                print("default")
            }
        }
    }
    
    // MARK: - ARSCNViewDelegate
    
    // Update stuff.
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        //updateCurrentToolPosition()
        if let lightEstimate = self.session.currentFrame?.lightEstimate {
            self.enableEnvironmentMapWithIntensity(lightEstimate.ambientIntensity / 40)
        } else {
            self.enableEnvironmentMapWithIntensity(25)
        }
        //checkForPort()
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        if let planeAnchor = anchor as? ARPlaneAnchor {
            if let plane = planes[planeAnchor] {
                plane.update(anchor: planeAnchor)
            }
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        // If is plane anchor
        if let planeAnchor = anchor as? ARPlaneAnchor {
            let planeNode = Plane(anchor: planeAnchor)
            planes[planeAnchor] = planeNode
            // ARKit owns the node corresponding to the anchor, so make the plane a child node.
            node.addChildNode(planeNode)
        }
    }
    
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
        
        return node
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

// MARK: - CGRect extensions

extension CGRect {
    
    var mid: CGPoint {
        return CGPoint(x: midX, y: midY)
    }
}

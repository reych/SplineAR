//
//  ViewController.swift
//  SplineAR
//
//  Created by Chen, Rena on 8/1/17.
//  Copyright © 2017 Chen, Rena. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {
    
    @IBOutlet var sceneView: ARSCNView!
    var spline = CRSpline()
    
    //var pointNodes = [SCNNode]()
    //var controlNodes: Set = Set<SCNNode>()
    //var controlAnchors = [ARAnchor]()
    
    var highlightNode: SCNNode! // For UI indication
    var selectedNode: SCNNode? // Selected node for interaction.
    
    var vectorToNode: vector_float3?
    
    var touchLocation: CGPoint?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // Create a new scene
        let scene = SCNScene(named: "art.scnassets/ship.scn")!
        
        // Set the scene to the view
        sceneView.scene = scene
        
        setupObjects()
        setupGestures()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingSessionConfiguration()
        
        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }
    
    // MARK: - Setup
    func setupObjects() {
        let g = SCNSphere(radius: 0.01)
        g.firstMaterial?.transparency = 0.5
        g.firstMaterial?.diffuse.contents = UIColor.orange.cgColor
        highlightNode = SCNNode(geometry: g)
        sceneView.scene.rootNode.addChildNode(highlightNode)
    }
    
    func setupGestures() {
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPressed(_:)))
        let singleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(singleTap(_:)))
        singleTapRecognizer.numberOfTapsRequired = 1
        let swipeUpRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(swipeUp(_:)))
        swipeUpRecognizer.direction = .up
        
        
        self.view.addGestureRecognizer(longPressRecognizer)
        self.view.addGestureRecognizer(singleTapRecognizer)
        self.view.addGestureRecognizer(swipeUpRecognizer)
    }
    
    // MARK: - Handle touch event.
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        print("touches began")
        // Select node
        if let location = touches.first?.location(in: sceneView) {
            touchLocation = location
        }
    }
    
    // Long press event.
    @objc func longPressed(_ sender: UIGestureRecognizer) {
        print("longpressed")
        switch sender.state {
        case .began:
            print("began")
            // Return if can't get touch location (this gets set in touches began, it shouldn't ever be nil)
            guard touchLocation != nil else {
                return
            }
            // Hit test to check intersection and select node.
            if let hit = sceneView.hitTest(touchLocation!, options: nil).first {
                //hit.node.removeFromParentNode()
                if selectedNode == hit.node {
                    deselectNode()
                } else {
                    selectNode(hit.node)
                }
                
                return
            }
            
        default:
            print("default")
        }
        
    }
    
    // Single tap.
    @objc func singleTap(_ sender: UIGestureRecognizer) {
        print("single tap")
        
        // Did not hit node, so deselect node.
        if selectedNode != nil {
            deselectNode()
            return
        }
        
        
        // Add control point node
        if let currentFrame = sceneView.session.currentFrame {
            var translateMatrix = matrix_identity_float4x4
            translateMatrix.columns.3.z = -0.15
            let transform = simd_mul(currentFrame.camera.transform, translateMatrix)
            
            // Create new control point and add it to spline.
            var translateVector = transform.columns.3
            //let point = Point(translateVector.x, translateVector.y, translateVector.z)
            let g = SCNSphere(radius: 0.01)
            g.firstMaterial?.diffuse.contents = UIColor.red.cgColor
            let controlPoint = SCNNode(geometry: g)
            controlPoint.position = SCNVector3(translateVector.x, translateVector.y, translateVector.z)
            spline.addControlPoint(controlPoint)
            sceneView.scene.rootNode.addChildNode(controlPoint)
            
            // Construct newest segment if have enough control points.
            let cvIndex = spline.constructNewestSegment()
            if cvIndex > -1 {
                let segment = spline.segments[spline.controlPoints[cvIndex]]
                for point in segment! {
                    sceneView.scene.rootNode.addChildNode(point)
                }
            }
            
        }
    }
    
    // Swipe up.
    @objc func swipeUp(_ sender: UIGestureRecognizer) {
        print ("swipe up")
        // Display options for selected node.
        if let node = selectedNode {
            let actionSheetController = UIAlertController(title: "Options", message: "Choose an action", preferredStyle: .actionSheet)
            let deleteActionButton = UIAlertAction(title: "Delete", style: .destructive, handler: {_ in
                print("delete")
                self.deselectNode()
                //Get affected segments and delete. Edit action is 'move' because node is not yet deleted.
                let affectedSegments = self.spline.getAffectedSegmentsOfControlPoint(node, editAction: .move)
                
                for segment in affectedSegments {
                    for point in segment {
                        point.removeFromParentNode()
                    }
                }
                print("affected segments num: \(affectedSegments.count)")
                
                node.removeFromParentNode()
                let cvIndices = self.spline.removeControlPoint(node)
                
                // Update the intermediate points.
                for index in cvIndices {
                    let controlPoint = self.spline.controlPoints[index]
                    if let segment = self.spline.segments[controlPoint] {
                        for point in segment {
                            self.sceneView.scene.rootNode.addChildNode(point)
                        }
                    }
                }
                
                
            })
            let cancelActionButton = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            actionSheetController.addAction(deleteActionButton)
            actionSheetController.addAction(cancelActionButton)
            self.present(actionSheetController, animated: true, completion: nil)
        }
    }
    
    // Update position of highlight node.
    func updateHighlightNode() {
        if let currentFrame = sceneView.session.currentFrame {
            var translateMatrix = matrix_identity_float4x4
            translateMatrix.columns.3.z = -0.15
            let transform = simd_mul(currentFrame.camera.transform, translateMatrix)
            highlightNode.simdTransform = transform
        }
    }
    
    func updateSelectedNode() {
        if let node = selectedNode {
            if let currentFrame = sceneView.session.currentFrame {
                
                var translateMatrix = matrix_identity_float4x4
                translateMatrix.columns.3.z = -0.15
                
                let transform = simd_mul(currentFrame.camera.transform, translateMatrix)
                
                // Delete old nodes.
                let affectedSegments = spline.getAffectedSegmentsOfControlPoint(node, editAction: .move)
                
                for segment in affectedSegments {
                    for point in segment {
                        point.removeFromParentNode()
                    }
                }
                
                // Move node.
                let cvIndices = spline.moveControlPoint(node, position: SCNVector3(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z))
                // Update the intermediate points.
                for index in cvIndices {
                    let controlPoint = spline.controlPoints[index]
                    if let segment = spline.segments[controlPoint] {
                        for point in segment {
                            sceneView.scene.rootNode.addChildNode(point)
                        }
                    }
                }
                //node.position = SCNVector3(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)
                
                //print(node.simdTransform.columns.3)
            }
        }
    }
    
    // MARK: - Node selection logic
    func selectNode(_ node: SCNNode) {
        if spline.isControlPoint(node) {
            deselectNode()
            selectedNode = node
            selectedNode?.geometry?.firstMaterial?.diffuse.contents = UIColor.cyan.cgColor
            
            if let currentFrame = sceneView.session.currentFrame {
                let nodePos = node.position
                let camPos = currentFrame.camera.transform.columns.3
                vectorToNode = vector3(nodePos.x - camPos.x, nodePos.y - camPos.y, nodePos.z - camPos.z)
                print(vectorToNode!)
            }
        }
    }
    
    func deselectNode() {
        if let node = selectedNode {
            node.geometry?.firstMaterial?.diffuse.contents = UIColor.red.cgColor
            selectedNode = nil
        }
    }
    
    // Return true if is a node for a control point.
    func isControlPointNode(_ node: SCNNode) {
        
    }

    // MARK: - ARSCNViewDelegate
    
    // Update stuff.
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        updateHighlightNode()
        updateSelectedNode()
    }
    
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let g = SCNSphere(radius: 0.01)
        g.firstMaterial?.diffuse.contents = UIColor.red.cgColor
        let node = SCNNode(geometry: g)
        
        node.position = SCNVector3Zero
     
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
}

//
//  CRSpline.swift
//  SplineAR
//
//  Created by Chen, Rena on 8/7/17.
//  Copyright © 2017 Chen, Rena. All rights reserved.
//

import UIKit
import SceneKit

typealias Point = vector_float3

class CRSpline: NSObject {
    enum EditAction {
        case move
        case delete
    }
    
    // List of control points
    var controlPoints = [SCNNode]()
    
    // Map of start CV (p1) to segment. Each segment is an array of positions. Segment 0 begins at CV 1.
    var segments = [SCNNode: [SCNNode]]()
    
    // Tension parameter
    var s: Float = 0.5
    
    // Basis matrix, determined from tension parameter s.
    var basis: matrix_float4x4 {
        return matrix_float4x4(float4(-s, 2*s, -s, 0), float4(2-s, s-3, 0, 1), float4(s-2, 3-2*s, s, 0), float4(s, -s, 0, 0))
    }
    
    // Parameter interval
    var t: Float = 0.1
    
    override init() {
        super.init()
    }
    
    // Loop through all control points and draw spline.
    func constructSpline() {
        //positions = [SCNNode]()
        for index in 1..<controlPoints.count-2 {
            print("\(index)")
            let p0 = controlPoints[index-1]
            let p1 = controlPoints[index]
            let p2 = controlPoints[index+1]
            let p3 = controlPoints[index+2]
            
            // Calculate the points between control points.
            constructSplineSegment(p0: p0, p1: p1, p2: p2, p3: p3, parameterInterval: t)
        }
    }
    
    // Optimization: draw only the newest segment.
    // Return index of start of new nodes.
    func constructNewestSegment() -> Int {
        guard controlPoints.count >= 4 else {
            return -1
        }
        let index = controlPoints.count - 3
        constructSplineSegment(p0: controlPoints[index-1], p1: controlPoints[index], p2: controlPoints[index+1], p3: controlPoints[index+2], parameterInterval: t)
        return index
    }
    
    // Draw the segment between two control points
    func constructSplineSegment(p0: SCNNode, p1: SCNNode, p2: SCNNode, p3: SCNNode, parameterInterval: Float) {
        segments[p1] = [SCNNode]() // Initialize segment array
        
        let controlMatrix = getControlMatrix(p0: p0, p1: p1, p2: p2, p3: p3)
        var u:Float = 0
        while u < 1 {
            let parameterVector = vector4(u*u*u, u*u, u, 1)
            let translate = parameterVector * basis * controlMatrix
            
            // create node.
            let g = SCNSphere(radius: 0.005)
            let splinePoint = SCNNode(geometry: g)
            splinePoint.position = SCNVector3(translate.x, translate.y, translate.z)
            
            // Add node to positions.
            //positions.append(splinePoint)
            segments[p1]?.append(splinePoint) // Add to segment.
            
            u += parameterInterval
        }
    }
    
    func getControlMatrix(p0: SCNNode, p1: SCNNode, p2: SCNNode, p3: SCNNode) -> matrix_float3x4{
        let p0_trans = p0.simdTransform.columns.3
        let p1_trans = p1.simdTransform.columns.3
        let p2_trans = p2.simdTransform.columns.3
        let p3_trans = p3.simdTransform.columns.3
        // COLUMN MAJOR IS THIS THE RIGHT ORDER??
        return matrix_float3x4(float4(p0_trans.x, p1_trans.x, p2_trans.x, p3_trans.x), float4(p0_trans.y, p1_trans.y, p2_trans.y, p3_trans.y), float4(p0_trans.z, p1_trans.z, p2_trans.z, p3_trans.z))
    }
    
    func addControlPoint(_ point: SCNNode) {
        controlPoints.append(point)
    }
    
    // Remove control point and update affected segments.
    func removeControlPoint(_ node: SCNNode) -> [Int]{
        let index = controlPoints.index(of: node) as! Int
        print("deleting index: \(index)")
        
        controlPoints.remove(at: index)
        segments[node] = nil
        
        return rebuildAffectedSegments(index: index, editAction: .delete)
        
    }
    
    // Move control point and update affected segments.
    func moveControlPoint(_ point: SCNNode, position: SCNVector3) -> [Int] {
        point.position = position
        let index = controlPoints.index(of: point) as! Int
        
        // Find all affected segments and recalculate.
        return rebuildAffectedSegments(index: index, editAction: .move)
    }
    
    // Return true if it's a control point in the spline.
    func isControlPoint(_ node: SCNNode) -> Bool{
        for point in controlPoints {
            if node == point {
                return true
            }
        }
        return false
    }
    
    // Return control points that begin the affected segments.
    func getAffectedSegmentsOfControlPoint(_ point: SCNNode, editAction: EditAction) -> [[SCNNode]]{
        let index = controlPoints.index(of: point) as! Int
        var nodes = [[SCNNode]]()
        // Check first segment.
        if index - 3 >= 0 && index < controlPoints.count {
            let points = segments[controlPoints[index-2]]
            nodes.append(points!)
        }
        // Second segment.
        if index - 2 >= 0 && index + 1 < controlPoints.count {
            let points = segments[controlPoints[index-1]]
            if let p = points {
                nodes.append(p)
            }
        }
        // Third segment.
        if index - 1 >= 0 && index + 2 < controlPoints.count{
            let points = segments[controlPoints[index]]
            if let p = points {
                nodes.append(p)
            }
        }
        // Fourth segment.
        if index >= 0 && index + 3 < controlPoints.count && editAction == EditAction.move{
            let points = segments[controlPoints[index+1]]
            if let p = points {
                nodes.append(p)
            }
        }
        print("affected segments: \(nodes.count)")
        return nodes
    }
    
    // Delete everything in the spline.
    func nuke() {
        controlPoints = [SCNNode]()
        segments = [SCNNode: [SCNNode]]()
    }
    
    private func rebuildAffectedSegments(index: Int, editAction: EditAction) -> [Int]{
        var indices = [Int]()
        // Check first segment.
        if index - 3 >= 0 && index < controlPoints.count {
            indices.append(index-2)
            constructSplineSegment(p0: controlPoints[index-3], p1: controlPoints[index-2], p2: controlPoints[index-1], p3: controlPoints[index], parameterInterval: t)
        }
        // Second segment.
        if index - 2 >= 0 && index + 1 < controlPoints.count {
            indices.append(index-1)
            constructSplineSegment(p0: controlPoints[index-2], p1: controlPoints[index-1], p2: controlPoints[index], p3: controlPoints[index+1], parameterInterval: t)
        }
        // Third segment.
        if index - 1 >= 0 && index + 2 < controlPoints.count{
            indices.append(index)
            constructSplineSegment(p0: controlPoints[index-1], p1: controlPoints[index], p2: controlPoints[index+1], p3: controlPoints[index+2], parameterInterval: t)
        }
        // Fourth segment.
        if index >= 0 && index + 3 < controlPoints.count && editAction == EditAction.move{
            indices.append(index+1)
            constructSplineSegment(p0: controlPoints[index], p1: controlPoints[index+1], p2: controlPoints[index+2], p3: controlPoints[index+3], parameterInterval: t)
        }
        return indices
    }
    
    
}


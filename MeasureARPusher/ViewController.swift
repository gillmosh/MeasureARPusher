//
//  ViewController.swift
//  MeasureARPusher
//
//  Created by Gillian Mosher on 11/3/19.
//  Copyright © 2019 Gillian Mosher. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

enum Mode {
// enumeration to indicate the possible states of the app
    case waitingForMeasuring
    case measuring
}

class ViewController : UIViewController, ARSCNViewDelegate {
    
    @IBOutlet weak var scnView: ARSCNView!
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var statusTextView: UITextView!
    
    var viewCenter: CGPoint {
      let viewBounds = view.bounds
      return CGPoint(x: viewBounds.width / 2.0, y: viewBounds.height / 2.0)
    }
    
    var nodes: [SCNNode] = []
    var nodeColor = UIColor.white
    var nodeRadius = 0.005
    var startNode: SCNNode!
    var distance = 0.0
    
    var textNode: TextNode!
    var lineNode: LineNode!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(sender:)))
        scnView.addGestureRecognizer(tap)
        setupScene()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupARSession()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        scnView.session.pause()
    }
    
    
    @objc func handleTap(sender: UITapGestureRecognizer) {
        let tapLocation = self.scnView.center// Get the center point, of the SceneView.
        let hitTestResults = scnView.hitTest(tapLocation, types:.existingPlaneUsingExtent)

         if let result = hitTestResults.first {
            if nodes.count == 2 {
                cleanAllNodes()
            }
            
            let position = SCNVector3.positionFrom(matrix: result.worldTransform)
            let sphere = SCNSphere(color: self.nodeColor, radius: CGFloat(self.nodeRadius))
            let node = SCNNode(geometry: sphere)
            
            node.position = position
            
            scnView.scene.rootNode.addChildNode(node)
            
            // Get the Last Node from the list
            let lastNode = nodes.last
            
            // Add the Sphere to the list.
            nodes.append(node)
            
            // Setting our starting point for drawing a line in real time
            self.startNode = nodes.last
            
            if lastNode != nil {
                // If there is 2 nodes or more
                if nodes.count >= 2 {
                    // Create a node line between the nodes
                    let measureLine = LineNode(from: (lastNode?.position)!, to: node.position, lineColor: self.nodeColor)
                    measureLine.name = "measureLine"
                    // Add the Node to the scene.
                    scnView.scene.rootNode.addChildNode(measureLine)
                }
                
                self.distance = Double(lastNode!.position.distance(to: node.position)) * 100
                print( String(format: "Distance between nodes:  %.2f cm", self.distance))
                presentShoeSizes(distance: self.distance)
            }
        }
    }
    
    // renderer callback method
//    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
//
//        if nodes.count == 2 {
//            self.startNode = nil
//            self.lineNode.removeFromParentNode()
//        }
//
//        DispatchQueue.main.async {
//            // get current hit position
//            // and check if start-node is available
//            guard let currentPosition = self.doHitTestOnExistingPlanes(),
//                let start = self.startNode else {
//                    return
//            }
//            // line-node
//            self.lineNode.removeFromParentNode()
//            self.lineNode = LineNode(from: start.position, to: currentPosition, lineColor: self.nodeColor)
//            self.lineNode.name = "lineInRealTime"
//            self.scnView.scene.rootNode.addChildNode(self.lineNode!)
//        }
//    }
    
    func doHitTestOnExistingPlanes() -> SCNVector3? {
        // hit-test of view's center with existing-planes
        let results = scnView.hitTest(view.center, types: .featurePoint)
        // check if result is available
        if let result = results.first {
            // get vector from transform
            let hitPos = SCNVector3.positionFrom(matrix: result.worldTransform)
            return hitPos
        }
        return nil
    }
    
    func presentShoeSizes(distance: Double) {
        if nodes.count == 2 {
            // Get the Last Node from the list
            let lastNode = nodes.last
            let firtsNode = nodes.first
            
            let formatter = NumberFormatter()
            formatter.minimumFractionDigits = 0
            formatter.maximumFractionDigits = 1
            
            let stringSize = formatter.string(for: distance)
            
            if let node1 = firtsNode, let node2 = lastNode  {
                // Calculate the middle point between the two SphereNodes.
                let minPosition = node1.position
                let maxPosition = node2.position
                let dx = ((maxPosition.x + minPosition.x)/2.0)
                let dy = (maxPosition.y + minPosition.y)/2.0 + 0.04
                let dz = (maxPosition.z + minPosition.z)/2.0
                let position =  SCNVector3(dx, dy, dz)
                // Create the textNode
                self.textNode = TextNode(stringSize!)
                self.textNode.color = nodeColor
                self.textNode.position = position
                self.textNode.font = UIFont(name: "AvenirNext-Bold", size: 0.1)
                self.scnView.scene.rootNode.addChildNode(self.textNode!)
            }
        }
    }
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
            print("Camera State: \(camera.trackingState)")
    }
    
    func cleanAllNodes() {
           if nodes.count > 0 {
               for node in nodes {
                   node.removeFromParentNode()
               }
               for node in scnView.scene.rootNode.childNodes {
                   if node.name == "measureLine" {
                       node.removeFromParentNode()
                   }
               }
               nodes = []
           }
    }
    
    func setupScene()  {
        let scene = SCNScene()

        self.scnView.delegate = self
        self.scnView.showsStatistics = true
        self.scnView.automaticallyUpdatesLighting = true
        self.scnView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
        self.scnView.scene = scene
    }
    
    func setupARSession() {
         let configuration = ARWorldTrackingConfiguration()
         configuration.planeDetection = .horizontal
         
         scnView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
     }
}

extension SCNVector3 {
    func distance(to destination: SCNVector3) -> CGFloat {
        let dx = destination.x - x
        let dy = destination.y - y
        let dz = destination.z - z
        return CGFloat(sqrt(dx*dx + dy*dy + dz*dz))
    }

    static func positionFrom(matrix: matrix_float4x4) -> SCNVector3 {
        let column = matrix.columns.3
        return SCNVector3(column.x, column.y, column.z)
    }
}

extension SCNNode {
    static func createLineNode(fromNode: SCNNode, toNode: SCNNode, andColor color: UIColor) -> SCNNode {
        let line = lineFrom(vector: fromNode.position, toVector: toNode.position)
        let lineNode = SCNNode(geometry: line)
        let planeMaterial = SCNMaterial()
        planeMaterial.diffuse.contents = color
        line.materials = [planeMaterial]
        return lineNode
    }
    
    static func lineFrom(vector vector1: SCNVector3, toVector vector2: SCNVector3) -> SCNGeometry {
        let indices: [Int32] = [0, 1]
        let source = SCNGeometrySource(vertices: [vector1, vector2])
        let element = SCNGeometryElement(indices: indices, primitiveType: .line)
        return SCNGeometry(sources: [source], elements: [element])
    }
}



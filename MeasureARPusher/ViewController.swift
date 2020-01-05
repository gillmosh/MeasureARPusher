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
    
    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var statusTextView: UITextView!
    
    var box: Box!
        // represents the 3D box that is going to get drawn when measuring
    var status: String!
        // text that tells us if the app is ready or not to take measurements (whether planes have been detected or not)
    var startPosition: SCNVector3!
        // represents measurement's start position
    var distance: Float!
        // calculated distance from the start to the current position (the measurement itself)
    var trackingState: ARCamera.TrackingState!
        // holds the current tracking state of the camera
    
    var mode: Mode = .waitingForMeasuring {
      didSet {
        switch mode {
          case .waitingForMeasuring:
            status = "NOT READY"
          case .measuring:
            box.update(minExtents: SCNVector3Zero, maxExtents: SCNVector3Zero)
            box.isHidden = false
            startPosition = nil
            distance = 0.0
            setStatusText()
        }
      }
    }

    
    override func viewDidLoad() {
      super.viewDidLoad()
      // set the view's delegate
      sceneView.delegate = self
      // set a padding in the text view
      statusTextView.textContainerInset = UIEdgeInsetsMake(20.0, 10.0, 10.0, 0.0)
      // instantiate the box and add it to the scene
      box = Box()
      box.isHidden = true;
      sceneView.scene.rootNode.addChildNode(box)
      // set the initial mode
      mode = .waitingForMeasuring
      // set the initial distance
      distance = 0.0
      // display the initial status
      setStatusText()
    }
    
    override func viewWillAppear(_ animated: Bool) {
      super.viewWillAppear(animated)
      // create a session configuration with plane detection
      let configuration = ARWorldTrackingConfiguration()
      configuration.planeDetection = .horizontal
      // run the view's session
      sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
      super.viewWillDisappear(animated)
      // pause the view's session
      sceneView.session.pause()
    }
    
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    @IBAction func switchChanged(_ sender: UISwitch) {
        if sender.isOn {
            mode = .measuring
        } else {
            mode = .waitingForMeasuring
        }
    }
}

extension ViewController {
    
    func setStatusText() {
      var text = "Status: \(status!)\n"
      text += "Tracking: \(getTrackigDescription())\n"
      text += "Distance: \(String(format:"%.2f cm", distance! * 100.0))"
      statusTextView.text = text
    }
    
    func getTrackigDescription() -> String {
      var description = ""
      if let t = trackingState {
        switch(t) {
          case .notAvailable:
            description = "TRACKING UNAVAILABLE"
          case .normal:
            description = "TRACKING NORMAL"
          case .limited(let reason):
            switch reason {
              case .excessiveMotion:
                description =               "TRACKING LIMITED - Too much camera movement"
              case .insufficientFeatures:
                description =               "TRACKING LIMITED - Not enough surface detail"
              default:
                description = "INITIALIZING"
            }
        }
      }
      return description
    }
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
      trackingState = camera.trackingState
    }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
      // Call the method asynchronously to perform
      //  this heavy task without slowing down the UI
      DispatchQueue.main.async {
        self.measure()
      }
    }
    
    func measure() {
      let screenCenter : CGPoint = CGPoint(x: self.sceneView.bounds.midX, y: self.sceneView.bounds.midY)
      let planeTestResults = sceneView.hitTest(screenCenter, types: [.existingPlaneUsingExtent])
      if let result = planeTestResults.first {
        status = "READY"
        if mode == .measuring {
        status = "MEASURING"
        let worldPosition = SCNVector3Make(result.worldTransform.columns.3.x, result.worldTransform.columns.3.y,   result.worldTransform.columns.3.z)
        if startPosition == nil {
          startPosition = worldPosition
          box.position = worldPosition
          distance = calculateDistance(from: startPosition!, to: worldPosition)
          box.resizeTo(extent: distance)
            let angleInRadians = calculateAngleInRadians(from: startPosition!, to: worldPosition)
            box.rotation = SCNVector4(x: 0, y: 1, z: 0, w: -(angleInRadians + Float.pi))
        }
        }
      }
      else {
        status = "NOT READY"
      }
        
        
        
    }
    
    func calculateDistance(from: SCNVector3, to: SCNVector3) -> Float {
      let x = from.x - to.x
      let y = from.y - to.y
      let z = from.z - to.z
      return sqrtf( (x * x) + (y * y) + (z * z))
    }
    
    func calculateAngleInRadians(from: SCNVector3, to: SCNVector3) -> Float {
      let x = from.x - to.x
      let z = from.z - to.z
      return atan2(z, x)
    }
    

}



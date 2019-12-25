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

class Box: SCNNode {
    lazy var box: SCNNode = makeBox()
    override init() {
      super.init()
    }
    required init?(coder aDecoder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
    }
    func makeBox() -> SCNNode {
      let box = SCNBox(        width: 0.01, height: 0.01, length: 0.01, chamferRadius: 0    )
      return convertToNode(geometry: box)
    }
    func convertToNode(geometry: SCNGeometry) -> SCNNode {
      for material in geometry.materials {
        material.lightingModel = .constant
        material.diffuse.contents = UIColor.white
        material.isDoubleSided = false
}

func + (left: SCNVector3, right: SCNVector3) -> SCNVector3 {
  return SCNVector3Make(      left.x + right.x, left.y + right.y, left.z + right.z  )
}
func - (left: SCNVector3, right: SCNVector3) -> SCNVector3 {
  return SCNVector3Make(      left.x - right.x, left.y - right.y, left.z - right.z  )
}

class ViewController: UIViewController, ARSCNViewDelegate {
    
    var box: Box! //3D box that is going to get drawn when measuring
    var status: String! //text that says if app is ready or not to make measurements
    var startPosition: SCNVector3! //measurement's start position
    var distance: Float! //calculated distance from start to current position
    var trackingState: ARCamera.TrackingState! //holds current tracking state of camera
    enum Mode {  //enumeration to indicate possible states of the app
      case waitingForMeasuring
      case measuring
    }
    
    var mode: Mode = .waitingForMeasuring {
      didSet {
        switch mode {
          case .waitingForMeasuring: //if set, assume app is not ready
            status = "NOT READY"
          case .measuring: //if set, size of box is reset
            box.update(minExtents: SCNVector3Zero, maxExtents: SCNVector3Zero)
            box.isHidden = false //if box is hidden, startPosition and distance reset
            startPosition = nil
            distance = 0.0
            setStatusText()
        }
      }
    }
    
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
            switch reason {  //FUCKKKKKK
              case .excessiveMotion:
                description = "TRACKING LIMITED - too much camera movement"
              case .insufficientFeatures:
                description = "TRACKING LIMITED - not enough surface detail"
              case .initializing:
                description = "INITIALIZING"
            }
        }
      }
      return description
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

    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var statusTextView: UITextView!
    
    override func viewWillDisappear(_ animated: Bool) {
      super.viewWillDisappear(animated)
      // Pause the view's session
      sceneView.session.pause()
    }
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
      trackingState = camera.trackingState
    }
    
    (void)renderer:(id <SCNSceneRenderer>)renderer updateAtTime:(NSTimeInterval)time
    // method is called once per frame (60x per second)
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
      // Call the method asynchronously to perform
      //  this heavy task without slowing down the UI
      DispatchQueue.main.async {
        self.measure()
      }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
      // call the method asynchronously to perform
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
        let worldPosition = SCNVector3Make(        result.worldTransform.columns.3.x,              result.worldTransform.columns.3.y,        result.worldTransform.columns.3.z)
let angleInRadians = calculateAngleInRadians(from: startPosition!, to: worldPosition)
            box.rotation = SCNVector4(x: 0, y: 1, z: 0, w: -(angleInRadians + Float.pi))
        if startPosition == nil {
          startPosition = worldPosition
          box.position = worldPosition
        }
      } else {
        status = "NOT READY"
      }
    }
        
     func calculateAngleInRadians(from: SCNVector3, to: SCNVector3) -> Float {
          let x = from.x - to.x
          let z = from.z - to.z
          return atan2(z, x)
        }
    
    
    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        // Do any additional setup after loading the view, typically from a nib.
//    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func switchChanged(sender: UISwitch) {
        if sender.isOn {
            mode = .measuring
        } else {
            mode = .waitingForMeasuring
        }
    }
    
}



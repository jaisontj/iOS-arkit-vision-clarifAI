//
//  ViewController.swift
//  ArSample
//
//  Created by Jaison on 01/12/17.
//  Copyright © 2017 Hasura. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import Vision

class ViewController: UIViewController {

    @IBOutlet var sceneView: ARSCNView!
    var faces: [Face] = []
    var bounds: CGRect = CGRect(x: 0, y: 0, width: 0, height: 0)
    
    var currentFrameTimer: Timer!
    var updateNodeTimer: Timer!
    
    var sceneViewConfig: ARWorldTrackingConfiguration = {
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        return configuration
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        bounds = sceneView.bounds
    
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Run the view's session
        sceneView.session.run(sceneViewConfig)

        updateNodeTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.updateNodes), userInfo: nil, repeats: true)

        let tapRecog = UITapGestureRecognizer(target: self, action: #selector(self.detectFace))
        sceneView.addGestureRecognizer(tapRecog)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
        currentFrameTimer.invalidate()
        updateNodeTimer.invalidate()
    }
}

extension ViewController {
    
    @objc func updateNodes() {
        self.faces.filter{ $0.updated.isAfter(seconds: 30) && !$0.hidden }.forEach{ face in
            print("Hide node: \(String(describing: face.name))")
            DispatchQueue.main.async {
                face.node.hide()
            }
        }
    }
    
    @objc func detectFace() {
        // Create and rotate image
        guard let frame = self.sceneView.session.currentFrame else {
            return
        }
        let image = CIImage.init(cvPixelBuffer: frame.capturedImage).rotate
        let facesRequest = VNDetectFaceRectanglesRequest { request, error in
            guard error == nil else {
                print("Face request error: \(error!.localizedDescription)")
                return
            }
            
            guard let observations = request.results as? [VNFaceObservation] else {
                print("No face observations")
                return
            }
            
            // Map response
            let allResponses = observations.map({ (face) -> (observation: VNFaceObservation, image: CIImage, frame: ARFrame) in
                return (observation: face, image: image, frame: frame)
            })
            
            for response in allResponses {
                print("Detected faces: \(allResponses.count)")
                self.classifyFace(face: response.observation, image: response.image, frame: response.frame)
            }
        }
        try? VNImageRequestHandler(ciImage: image).perform([facesRequest])
    }
    
    func classifyFace(face: VNFaceObservation, image: CIImage, frame: ARFrame) {
        // Determine position of the face
        let boundingBox = self.transformBoundingBox(face.boundingBox)
        print("Detected face bounding box: \(boundingBox)")
        guard let worldCoord = self.normalizeWorldCoord(boundingBox) else {
            print("No feature point found")
            return
        }
        
        let pixel = image.cropImage(toFace: face)
        
        //Create a facenode at position
        let node = FaceNode.init(withText: "Please wait..", image: pixel.uiimage, position: worldCoord)        
        let face = Face.init(node: node, timestamp: frame.timestamp)
        self.faces.append(face)
        DispatchQueue.main.async {
            self.sceneView.scene.rootNode.addChildNode(node)
            node.show()
        }
    }
    
    
    private func updateNode(celebName: String, image: UIImage, position: SCNVector3, frame: ARFrame) {
        
        // Filter for existent face
        let results = self.faces.filter {
                $0.name == celebName && $0.timestamp != frame.timestamp
            }.sorted {
                $0.node.position.distance(toVector: position) < $1.node.position.distance(toVector: position)
        }
        
        // Create new face
        guard let existentFace = results.first else {
            let node = FaceNode.init(withText: celebName, image: image, position: position)
            
            DispatchQueue.main.async {
                self.sceneView.scene.rootNode.addChildNode(node)
                node.show()
            }
            let face = Face.init(name: celebName, node: node, timestamp: frame.timestamp)
            self.faces.append(face)
            return
        }
        
        DispatchQueue.main.async {
            // Filter for face that's already displayed and update it
            if let displayFace = results.filter({ !$0.hidden }).first  {
                let distance = displayFace.node.position.distance(toVector: position)
                if(distance >= 0.03 ) {
                    displayFace.node.move(position)
                }
                displayFace.timestamp = frame.timestamp
            } else {
                existentFace.node.position = position
                existentFace.node.show()
                existentFace.timestamp = frame.timestamp
            }
        }
    }
    
    /// Transform bounding box according to device orientation
    ///
    /// - Parameter boundingBox: of the face
    /// - Returns: transformed bounding box
    private func transformBoundingBox(_ boundingBox: CGRect) -> CGRect {
        var size: CGSize
        var origin: CGPoint
        switch UIDevice.current.orientation {
        case .landscapeLeft, .landscapeRight:
            size = CGSize(width: boundingBox.width * bounds.height,
                          height: boundingBox.height * bounds.width)
        default:
            size = CGSize(width: boundingBox.width * bounds.width,
                          height: boundingBox.height * bounds.height)
        }
        
        switch UIDevice.current.orientation {
        case .landscapeLeft:
            origin = CGPoint(x: boundingBox.minY * bounds.width,
                             y: boundingBox.minX * bounds.height)
        case .landscapeRight:
            origin = CGPoint(x: (1 - boundingBox.maxY) * bounds.width,
                             y: (1 - boundingBox.maxX) * bounds.height)
        case .portraitUpsideDown:
            origin = CGPoint(x: (1 - boundingBox.maxX) * bounds.width,
                             y: boundingBox.minY * bounds.height)
        default:
            origin = CGPoint(x: boundingBox.minX * bounds.width,
                             y: (1 - boundingBox.maxY) * bounds.height)
        }
        
        return CGRect(origin: origin, size: size)
    }
    
    /// In order to get stable vectors, we determine multiple coordinates within an interval.
    ///
    /// - Parameters:
    ///   - boundingBox: Rect of the face on the screen
    /// - Returns: the normalized vector
    private func normalizeWorldCoord(_ boundingBox: CGRect) -> SCNVector3? {
        
        var array: [SCNVector3] = []
        Array(0...2).forEach{_ in
            if let position = determineWorldCoord(boundingBox) {
                array.append(position)
            }
            usleep(12000) // .012 seconds
        }
        
        if array.isEmpty {
            return nil
        }
        
        return SCNVector3.center(array)
    }
    
    /// Determine the vector from the position on the screen.
    ///
    /// - Parameter boundingBox: Rect of the face on the screen
    /// - Returns: the vector in the sceneView
    private func determineWorldCoord(_ boundingBox: CGRect) -> SCNVector3? {
        let arHitTestResults = sceneView.hitTest(CGPoint(x: boundingBox.midX, y: boundingBox.midY), types: [.featurePoint])
        print(arHitTestResults.count)
        // Filter results that are to close
        if let closestResult = arHitTestResults.filter({ $0.distance > 0.10 }).first {
            //            print("vector distance: \(closestResult.distance)")
            return SCNVector3.positionFromTransform(closestResult.worldTransform)
        }
        return nil
    }
}

extension ViewController: ARSCNViewDelegate {
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        
        switch camera.trackingState {
        case .limited(.initializing):
            print("Camera starting up")
        case .notAvailable:
            print("Not available")
        case .normal:
            print("Camera in normal state")
        default:
            break
        }
    }
}

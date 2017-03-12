//
//  GameViewController.swift
//  SceneKitMetalMaptiles
//
//  Created by Lachlan Hurst on 11/3/17.
//  Copyright © 2017 Lachlan Hurst. All rights reserved.
//

import UIKit
import QuartzCore
import SceneKit

class GameViewController: UIViewController, MapTileManagerDelegate, SCNSceneRendererDelegate {

    var mtm:MaptileManager!

    var planeRootNode:SCNNode!

    var updateLocationTo:GlobalMtLocation? = nil

    override func viewDidLoad() {
        super.viewDidLoad()

        mtm = MaptileManager(mapTileGridSize: 15, tileMaker:MapTileMakerImage())
        mtm.delegate = self
        //mtm.shiftMapTiles(dX: 1, dY: 0)

        // create a new scene
        let scene = SCNScene()
        
        // create and add a camera to the scene
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        scene.rootNode.addChildNode(cameraNode)
        
        // place the camera
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 10)
        
        // create and add a light to the scene
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light!.type = .omni
        lightNode.position = SCNVector3(x: 0, y: 10, z: 10)
        scene.rootNode.addChildNode(lightNode)
        
        // create and add an ambient light to the scene
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light!.type = .ambient
        ambientLightNode.light!.color = UIColor.darkGray
        scene.rootNode.addChildNode(ambientLightNode)
        
        // retrieve the ship node
        //let box = SCNNode(geometry:SCNBox(width: 1, height: 1, length: 1, chamferRadius: 0))
        //scene.rootNode.addChildNode(box)
        // animate the 3d object
        //box.runAction(SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: 2, z: 0, duration: 1)))

        let planes = planesFromMtm(mtm: mtm)
        planes.position = SCNVector3Make(Float(mtm.globalLocation.x), Float(mtm.globalLocation.y), 0)
        beginTranslation3d = planes.position
        planeRootNode = planes
        scene.rootNode.addChildNode(planes)

        // retrieve the SCNView
        let scnView = self.view as! SCNView
        scnView.isPlaying = true
        scnView.delegate = self
        
        // set the scene to the view
        scnView.scene = scene
        
        // allows the user to manipulate the camera
        //scnView.allowsCameraControl = true
        
        // show statistics such as fps and timing information
        scnView.showsStatistics = true
        
        // configure the view
        scnView.backgroundColor = UIColor.lightGray
        
        // add a tap gesture recognizer
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        scnView.addGestureRecognizer(tapGesture)

        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        scnView.addGestureRecognizer(panGesture)
    }

    //func updateMtm

    var beginTranslation3d = SCNVector3Zero
    func handlePan(_ recognizer: UIPanGestureRecognizer) {

        let scnView = self.view as! SCNView
        let transInView = recognizer.translation(in: scnView)
        let transPtIn3d = scnView.unprojectPoint(SCNVector3Make(Float(transInView.x), Float(transInView.y), 0))
        let originIn3d = scnView.unprojectPoint(SCNVector3Zero)

        let transIn3d = (transPtIn3d - originIn3d) * 10 // camera z pos ???

        let totalTrans3d = beginTranslation3d + transIn3d

        if (recognizer.state == .began )
        {

        } else if (recognizer.state == .ended ||
            recognizer.state == .cancelled ||
            recognizer.state == .failed)
        {
            beginTranslation3d = totalTrans3d
        } else {

            //updateForNewLocation(x: Double(-1 * totalTrans3d.x), y: Double(-1 * totalTrans3d.y))
            updateLocationTo = GlobalMtLocation(x: Double(-1 * totalTrans3d.x), y: Double(-1 * totalTrans3d.y))
        }
    }

    func updateForNewLocation(x:Double, y:Double) {

        mtm.globalLocation = GlobalMtLocation(x: x, y: y)
        let dXf = Float(mtm.mapTileCentre.xIndex) * mtm.mapTileGlobalSize
        let dYf = Float(mtm.mapTileCentre.yIndex) * mtm.mapTileGlobalSize

        planeRootNode.position = SCNVector3Make(Float(x) - dXf, Float(y) - dYf, 0) * -1.0
    }

    func mapTilesShifted(dX: Int, dY: Int) {
        //print("shifting by \(dX), \(dY)")
        updatePlanesFromMtm(mtm: mtm)
    }

    func updatePlanesFromMtm(mtm:MaptileManager) {
        var count:Int = 0
        for i in 0..<mtm.gridSize {
            for j in 0..<mtm.gridSize {
                let mt = mtm.mapTiles[j][i]! as! MapTileImage
                let image = mt.image

                let planeNode = planeRootNode.childNodes[count]

                planeNode.geometry?.firstMaterial?.diffuse.contents = image

                count+=1
            }
        }
    }

    func planesFromMtm(mtm:MaptileManager) -> SCNNode {
        let node = SCNNode()

        var count:Int = 0

        for i in 0..<mtm.gridSize {
            for j in 0..<mtm.gridSize {
                let mt = mtm.mapTiles[j][i]! as! MapTileImage
                let image = mt.image

                let plane = SCNPlane(width: 1, height: 1)
                plane.firstMaterial?.locksAmbientWithDiffuse = false
                plane.firstMaterial?.diffuse.contents = image
                plane.firstMaterial?.ambient.contents = Utils.colourForIndex(index: count)
                let planeNode = SCNNode(geometry: plane)
                planeNode.position = SCNVector3Make(Float(j) - Float(mtm.gridSize) / 2, Float(i) - Float(mtm.gridSize) / 2, 0)
                node.addChildNode(planeNode)

                count+=1
            }
        }
        return node
    }

    func handleTap(_ gestureRecognize: UIGestureRecognizer) {
        // retrieve the SCNView
        let scnView = self.view as! SCNView
        
        // check what nodes are tapped
        let p = gestureRecognize.location(in: scnView)
        let hitResults = scnView.hitTest(p, options: [:])
        // check that we clicked on at least one object
        if hitResults.count > 0 {
            // retrieved the first clicked object
            let result: AnyObject = hitResults[0]
            
            // get its material
            let material = result.node!.geometry!.firstMaterial!
            
            // highlight it
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.5
            
            // on completion - unhighlight
            SCNTransaction.completionBlock = {
                SCNTransaction.begin()
                SCNTransaction.animationDuration = 0.5
                
                material.emission.contents = UIColor.black
                
                SCNTransaction.commit()
            }
            
            material.emission.contents = UIColor.red
            
            SCNTransaction.commit()
        }
    }

    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        if let updateLoc = updateLocationTo {
            updateForNewLocation(x:updateLoc.x, y:updateLoc.y)
            updateLocationTo = nil
        }
    }

    override var shouldAutorotate: Bool {
        return true
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

}

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

class GameViewController: UIViewController, MapTileManagerDelegate, SCNSceneRendererDelegate, UIGestureRecognizerDelegate {

    var mtm:MaptileManager!
    var mtis:MaptileImageSource!

    var planeRootNode:SCNNode!
    var camera:SCNCamera!
    var cameraNode:SCNNode!

    var updateLocationTo:GlobalMtLocation? = nil
    var zoom:Float = 1.0

    override func viewDidLoad() {
        super.viewDidLoad()

        // MapTileMakerImage works, but is slower than texture
        //mtm = MaptileManager(mapTileGridSize: 15, tileMaker:MapTileMakerImage())

        mtm = MaptileManager(mapTileGridSize: 5, tileMaker:MapTileMakerTexture())
        mtm.delegate = self
        //mtm.shiftMapTiles(dX: 1, dY: 0)

        mtis = StamenMapsImageSource()

        // create a new scene
        let scene = SCNScene()
        
        // create and add a camera to the scene
        camera = SCNCamera()
        camera.usesOrthographicProjection = true
        cameraNode = SCNNode()
        cameraNode.camera = camera
        scene.rootNode.addChildNode(cameraNode)
        
        // place the camera
        cameraNode.position = SCNVector3(x: 0, y: 0, z: zoom)
        
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
        panGesture.minimumNumberOfTouches = 1
        panGesture.maximumNumberOfTouches = 2
        panGesture.delaysTouchesBegan = false
        panGesture.delaysTouchesEnded = false
        panGesture.delegate = self
        scnView.addGestureRecognizer(panGesture)

        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        pinchGesture.delaysTouchesBegan = false
        pinchGesture.delaysTouchesEnded = false
        pinchGesture.delegate = self
        scnView.addGestureRecognizer(pinchGesture)

        updateLocationTo = GlobalMtLocation(x: 0.5, y: 0.5)
        updateForNewLocation(x: updateLocationTo!.x, y: updateLocationTo!.y)
    }

    var beginTranslation3d = SCNVector3Make(0.5, 0.5, 0)
    func handlePan(_ recognizer: UIPanGestureRecognizer) {
        let scnView = self.view as! SCNView
        let transInView = recognizer.translation(in: scnView)
        let transPtIn3d = scnView.unprojectPoint(SCNVector3Make(Float(transInView.x), Float(transInView.y), 0))
        let originIn3d = scnView.unprojectPoint(SCNVector3Zero)

        let transIn3d = (originIn3d - transPtIn3d)

        let totalTrans3d = beginTranslation3d + transIn3d

        if (recognizer.state == .began )
        {
            beginTranslation3d = totalTrans3d
        } else if (recognizer.state == .ended ||
            recognizer.state == .cancelled ||
            recognizer.state == .failed)
        {
            beginTranslation3d = totalTrans3d
        } else {

            updateLocationTo = GlobalMtLocation(x: Double(totalTrans3d.x), y: Double(totalTrans3d.y))
        }
    }

    var startZoom:Float!
    var startZoomFactor:Float!
    func handlePinch(_ recognizer: UIPinchGestureRecognizer) {
        if (recognizer.state == .began )
        {
            startZoom = zoom
        } else if (recognizer.state == .ended ||
            recognizer.state == .cancelled ||
            recognizer.state == .failed)
        {

        } else {
            let currentZoom = startZoom / Float(recognizer.scale)
            zoom = currentZoom
        }
    }


    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }

    func updateForNewLocation(x:Double, y:Double) {
        mtm.globalLocation = GlobalMtLocation(x: x, y: y)
        // zooming in drops to top left tile (eg; TMS)
        let dXf = Float(mtm.mapTileCentre.xIndex+1) * mtm.mapTileGlobalSize
        let dYf = Float(mtm.mapTileCentre.yIndex) * mtm.mapTileGlobalSize

        // zooming in drops to bottom left tile
        //let dXf = Float(mtm.mapTileCentre.xIndex+1) * mtm.mapTileGlobalSize
        //let dYf = Float(mtm.mapTileCentre.yIndex+1) * mtm.mapTileGlobalSize

        let position = SCNVector3Make(Float(x) - dXf, Float(y) - dYf, 0) * -1.0

        planeRootNode.position = position
    }

    func mapTilesZoomed(dZoomLevel: Int) {
        let scale = mtm.mapTileGlobalSize
        planeRootNode.scale = SCNVector3Make(scale, scale, scale)
        updatePlanesFromMtm(mtm: mtm)
        updateForNewLocation(x: self.mtm.globalLocation.x, y: self.mtm.globalLocation.y)
    }

    func mapTilesShifted(dX: Int, dY: Int) {
        print("shifting by \(dX), \(dY)")
        updatePlanesFromMtm(mtm: mtm)
    }

    func setPlaneWith(mapTile:MapTile, plane:SCNGeometry) {
        if let mtImage = mapTile as? MapTileImage {
            let image = mtImage.image
            plane.firstMaterial?.diffuse.contents = image
        } else if let mtTexture = mapTile as? MapTileTexture {

            if !mtTexture.initialised && mtis.isWithinBounds(mapTile: mtTexture) {
                mtis.requestMaptile(maptile: mtTexture, imageType: .diffuse, progress: nil, complete: self.maptileImageRecieved)
            }

            let tex = mtTexture.texture
            plane.firstMaterial?.diffuse.contents = tex
        }
    }

    func updatePlanesFromMtm(mtm:MaptileManager) {
        var count:Int = 0
        for i in 0..<mtm.gridSize {
            for j in 0..<mtm.gridSize {

                let planeNode = planeRootNode.childNodes[count]
                let plane = planeNode.geometry!

                let mt = mtm.mapTiles[j][i]!

                setPlaneWith(mapTile: mt, plane: plane)

                count+=1
            }
        }
    }

    func maptileImageRecieved(maptile:MapTile,
                              imageType:MaptileImageType,
                              image:UIImage) {
        var count:Int = 0
        for i in 0..<mtm.gridSize {
            for j in 0..<mtm.gridSize {
                let mt = mtm.mapTiles[j][i]!

                if mt == maptile {
                    let mtx = mt as! MapTileTexture
                    let texture = Utils.imageToTexture(image: image)
                    mtx.texture = texture

                    let planeNode = planeRootNode.childNodes[count]
                    let plane = planeNode.geometry!


                    setPlaneWith(mapTile: mt, plane: plane)

                }

                count+=1
            }
        }
    }

    func planesFromMtm(mtm:MaptileManager) -> SCNNode {
        let node = SCNNode()

        var count:Int = 0

        for i in 0..<mtm.gridSize {
            for j in 0..<mtm.gridSize {

                let plane = SCNPlane(width: 1, height: 1)
                plane.firstMaterial?.locksAmbientWithDiffuse = false

                let mt = mtm.mapTiles[j][i]!
                setPlaneWith(mapTile: mt, plane: plane)

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

        let zoomLevel = Int(-1 * log(zoom) / log(2))
        mtm.zoomLevel = zoomLevel

        if let updateLoc = updateLocationTo {
            updateForNewLocation(x:updateLoc.x, y:updateLoc.y)
            updateLocationTo = nil
        }

        //cameraNode.position = SCNVector3Make(cameraNode.position.x, cameraNode.position.y, zoom)
        camera.orthographicScale = Double(zoom)
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

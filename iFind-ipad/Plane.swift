//
//  Plane.swift
//  LastPlayAR
//
//  Created by 赵一达 on 2018/4/1.
//  Copyright © 2018年 赵一达. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class Plane: SCNNode {
    
    var anchor: ARPlaneAnchor!
    var planeGeometry: SCNPlane!
    
    init(withAnchor anchor: ARPlaneAnchor) {
        super.init()
        
        self.anchor = anchor
        planeGeometry = SCNPlane(width: CGFloat(anchor.extent.x), height: CGFloat(anchor.extent.z))
        
        
        let material = SCNMaterial()
        let img = UIImage(named: "art.scnassets/fabric")
        material.diffuse.contents = img
        material.lightingModel = .physicallyBased
        planeGeometry.materials = [material]
        
        let planeNode = SCNNode(geometry: planeGeometry)
        planeNode.position = SCNVector3Make(anchor.center.x, 0, anchor.center.z)
        
        
        planeNode.transform = SCNMatrix4MakeRotation(Float(-.pi / 2.0), 1.0, 0.0, 0.0)
        
        setTextureScale()
        addChildNode(planeNode)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func update(anchor: ARPlaneAnchor) {
        
        
        planeGeometry.width = CGFloat(anchor.extent.x);
        planeGeometry.height = CGFloat(anchor.extent.z);
        
        
        
        position = SCNVector3Make(anchor.center.x, 0, anchor.center.z)
        setTextureScale()
    }
    
    func setTextureScale() {
        let width = planeGeometry.width
        let height = planeGeometry.height
        
        
        
        let material = planeGeometry.materials.first
        material?.diffuse.contentsTransform = SCNMatrix4MakeScale(Float(width), Float(height), 1)
        material?.diffuse.wrapS = .repeat
        material?.diffuse.wrapT = .repeat
    }
}

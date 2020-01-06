//
//  SCNSphere+Init.swift
//  MeasureARPusher
//
//  Created by Ali Alobaidi on 1/5/20.
//  Copyright © 2020 Gillian Mosher. All rights reserved.
//

import UIKit
import SceneKit

extension SCNSphere {
    convenience init(color: UIColor, radius: CGFloat) {
        self.init(radius: radius)
        
        let material = SCNMaterial()
        material.diffuse.contents = color
        materials = [material]
    }
}

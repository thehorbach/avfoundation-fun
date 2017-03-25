//
//  CameraPreviewView.swift
//  AVFoundationFun
//
//  Created by Vyacheslav Horbach on 25/03/17.
//  Copyright © 2017 Vjaceslav Horbac. All rights reserved.
//

import UIKit
import AVFoundation
//import Photos

class CameraPreviewView: UIView {
    
    override static var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }
    
    var cameraPreviewLayer: AVCaptureVideoPreviewLayer {
        return layer as! AVCaptureVideoPreviewLayer
    }
    
    var session: AVCaptureSession? {
        get {
            return cameraPreviewLayer.session
        }
        set {
            cameraPreviewLayer.session = newValue
        }
    }
}

//
//  ViewController.swift
//  AVFoundationFun
//
//  Created by Vyacheslav Horbach on 25/03/17.
//  Copyright © 2017 Vjaceslav Horbac. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {

    @IBOutlet weak var cameraPreviewView: CameraPreviewView!
    @IBOutlet weak var shutterButtonDidTouch: UIButton!
    @IBOutlet weak var previewImageView: UIImageView!
    @IBOutlet weak var thumbnailSwitch: UISwitch!
    
    fileprivate let session = AVCaptureSession()
    fileprivate let sessionQueue = DispatchQueue(label: "com.razeware.PhotoMe.session-queue")
    var videoDeviceInput: AVCaptureDeviceInput!
    
    fileprivate let photoOutput = AVCapturePhotoOutput()
    
    fileprivate var photoCaptureDelegates = [Int64 : PhotoCaptureDelegate]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        cameraPreviewView.session = session
        sessionQueue.suspend()
        
        AVCaptureDevice.requestAccess(forMediaType: AVMediaTypeVideo) { success in
            if !success {
                print("Come on, it's a camera app!")
                return
            }
            
            self.sessionQueue.resume()
        }
        
        sessionQueue.async {
            [unowned self] in
            self.prepareCaptureSession()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        sessionQueue.async {
            self.session.startRunning()
        }
    }
    
    private func prepareCaptureSession() {
        
        session.beginConfiguration()
        session.sessionPreset = AVCaptureSessionPresetPhoto
        
        do {
            let videoDevice = AVCaptureDevice.defaultDevice(withDeviceType: .builtInWideAngleCamera, mediaType: AVMediaTypeVideo, position: .front)
            let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
            
            if session.canAddInput(videoDeviceInput) {
                session.addInput(videoDeviceInput)
                self.videoDeviceInput = videoDeviceInput
                
                DispatchQueue.main.async {
                    self.cameraPreviewView.cameraPreviewLayer.connection.videoOrientation = .portrait
                }
                
            } else {
                print("Couldn't add device to the session")
                return
            }
            
        } catch {
            print("Couldn't create video device input: \(error)")
            return
        }
        
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
            photoOutput.isHighResolutionCaptureEnabled = true
        } else {
            print("Unable to add photo output")
            return
        }
        
        session.commitConfiguration()
    }
    
    @IBAction func shutterButtonDidTouch(_ sender: Any) {
        capturePhoto()
    }
}

extension ViewController {
    fileprivate func capturePhoto() {
        let cameraPreviewLayerOrientation = cameraPreviewView.cameraPreviewLayer.connection.videoOrientation
        
        sessionQueue.async {
            if let connection = self.photoOutput.connection(withMediaType: AVMediaTypeVideo) {
                connection.videoOrientation = cameraPreviewLayerOrientation
            }
            
            let photoSettings = AVCapturePhotoSettings()
            photoSettings.flashMode = .off
            photoSettings.isHighResolutionPhotoEnabled = true
            
            ///
            
            if self.thumbnailSwitch.isOn && photoSettings.availablePreviewPhotoPixelFormatTypes.count > 0 {
                photoSettings.previewPhotoFormat = [
                    kCVPixelBufferPixelFormatTypeKey as String : photoSettings.availablePreviewPhotoPixelFormatTypes.first!,
                    kCVPixelBufferWidthKey as String : 160,
                    kCVPixelBufferHeightKey as String : 160
                ]
            }
            
            ///
            
            let uniqueID = photoSettings.uniqueID
            let photoCaptureDelegate = PhotoCaptureDelegate() { [unowned self] (photoCaptureDelegate, asset) in
                self.sessionQueue.async { [unowned self] in
                    self.photoCaptureDelegates[uniqueID] = .none
                }
            }
            
            self.photoCaptureDelegates[uniqueID] = photoCaptureDelegate
            self.photoOutput.capturePhoto(with: photoSettings, delegate: photoCaptureDelegate)
            
            photoCaptureDelegate.photoCaptureBegins = { [unowned self] in
                DispatchQueue.main.async {
                    self.shutterButtonDidTouch.isEnabled = false
                    self.cameraPreviewView.cameraPreviewLayer.opacity = 0
                    UIView.animate(withDuration: 0.2) {
                        self.cameraPreviewView.cameraPreviewLayer.opacity = 1
                    }
                }
            }
            
            photoCaptureDelegate.photoCaptured = { [unowned self] in
                DispatchQueue.main.async {
                    self.shutterButtonDidTouch.isEnabled = true
                }
            }
            
            photoCaptureDelegate.thumbnailCaptured = { [unowned self] image in
                DispatchQueue.main.async {
                    self.previewImageView.image = image
                }
            }
        }
    }
}

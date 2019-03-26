//
//  FirstViewController.swift
//  BlindVision
//
//  Created by Hoàng Sơn Tùng on 3/21/19.
//  Copyright © 2019 Hoàng Sơn Tùng. All rights reserved.
//

import UIKit
import AVFoundation

class FirstViewController: UIViewController, AVCapturePhotoCaptureDelegate {
    
    @IBOutlet weak var previewView: UIView!
    @IBOutlet weak var objectLabel: UILabel!
    
    var captureSession: AVCaptureSession!
    var stillImageOutput: AVCapturePhotoOutput!
    var videoPreviewLayer: AVCaptureVideoPreviewLayer!
    
    //When user tap on camera
    @IBAction func didTakePhoto(_ sender: Any) {
        let settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
        stillImageOutput.capturePhoto(with: settings, delegate: self)
    }
    
    //Handle the captured photo
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        
        guard let imageData = photo.fileDataRepresentation()
            else { return }

        // @image: AVCapture --> UI Image
        var image = UIImage(data: imageData)
    
        image = resizeImage(image: image!, targetSize: CGSize.init(width: 720, height: 1280))
        //Convert UIImage -> jpeg -> base64
        
        guard let imgData = image?.jpegData(compressionQuality: 0.0) else {
            return()
        }
        let imgDataBase64 = imgData.base64EncodedString()
        let imgName = randomString(length: 5) + ".jpg"
        
        let result = self.callAPIObjectDetect(imgDataBase64: imgDataBase64, imgName: imgName)
        
        showLoadingHUD()
        print(result)
        
    }
    
    func setupLivePreview() {
        
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        
        videoPreviewLayer.videoGravity = .resizeAspectFill
        videoPreviewLayer.connection?.videoOrientation = .portrait
        previewView.layer.addSublayer(videoPreviewLayer)
        
        //Add FloatingView on top
        addFloatingView(previewView: previewView)
        
        DispatchQueue.global(qos: .userInitiated).async { //[weak self] in
            self.captureSession.startRunning()
            DispatchQueue.main.async {
                self.videoPreviewLayer.frame = self.previewView.bounds
            }
        }
    }
    
    func pushCameraToController() {
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = .hd1920x1080
        
        guard let backCamera = AVCaptureDevice.default(for: AVMediaType.video)
            else {
                print("Unable to access back camera!")
                return
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: backCamera)
            stillImageOutput = AVCapturePhotoOutput()
            if captureSession.canAddInput(input) && captureSession.canAddOutput(stillImageOutput) {
                captureSession.addInput(input)
                captureSession.addOutput(stillImageOutput)
                setupLivePreview()
            }
        }
        catch let error  {
            print("Error Unable to initialize back camera:  \(error.localizedDescription)")
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        pushCameraToController()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.captureSession.stopRunning()
    }
}


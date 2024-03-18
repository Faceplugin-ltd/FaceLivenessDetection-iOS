import UIKit
import AVFoundation
import CoreData

class CameraViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate{
    
    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var faceView: FaceView!
    @IBOutlet weak var cameraSwitchBtn: UIButton!
    
    var session = AVCaptureSession()
    
    var cameraLens_val = 0
    var livenessThreshold = Float(0)
    var cameraPosition: AVCaptureDevice.Position!
    
    var cameraLens_val_settings: Int!
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: ViewController.CORE_DATA_NAME)
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    override func viewWillAppear(_ animated: Bool) {
        let defaults = UserDefaults.standard
        cameraLens_val_settings = defaults.integer(forKey: "camera_lens")
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        let defaults = UserDefaults.standard
        defaults.set(cameraLens_val_settings, forKey: "camera_lens")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        cameraView.translatesAutoresizingMaskIntoConstraints = true
        cameraView.frame = view.bounds
        
        faceView.translatesAutoresizingMaskIntoConstraints = true
        faceView.frame = view.bounds
        
        let defaults = UserDefaults.standard
        cameraLens_val = defaults.integer(forKey: "camera_lens")
        livenessThreshold = defaults.float(forKey: "liveness_threshold")
        
        session = AVCaptureSession()
        startCamera()
    }
    
    func startCamera() {
        self.cameraSwitchBtn.isHidden = false
        var cameraLens = AVCaptureDevice.Position.front
        if(cameraLens_val == 0) {
            cameraLens = AVCaptureDevice.Position.back
        }
        
        //cameraPosition = cameraLens
        
        // Create an AVCaptureSession
        session.sessionPreset = .high
        
        // Create an AVCaptureDevice for the camera
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: cameraLens) else { return }
        guard let input = try? AVCaptureDeviceInput(device: videoDevice) else { return }
        if session.canAddInput(input) {
            session.addInput(input)
        }
        
        // Create an AVCaptureVideoDataOutput
        let videoOutput = AVCaptureVideoDataOutput()
        
        // Set the video output's delegate and queue for processing video frames
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue.global(qos: .default))
        
        // Add the video output to the session
        session.addOutput(videoOutput)
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds
        cameraView.layer.addSublayer(previewLayer)
        
        // Start the session
        session.startRunning()
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags.readOnly)
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        
        let context = CIContext()
        let cgImage = context.createCGImage(ciImage, from: ciImage.extent)
        let image = UIImage(cgImage: cgImage!)
        CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags.readOnly)
        
        // Rotate and flip the image
        let capturedImage = image.rotate(radians: .pi/2).flipHorizontally()
        
        let param = FaceDetectionParam()
        param.check_liveness = true
        
        let faceBoxes = FaceSDK.faceDetection(capturedImage, param: param)
        for faceBox in (faceBoxes as NSArray as! [FaceBox]) {
            if(cameraLens_val == 0) {
                let tmp = faceBox.x1
                faceBox.x1 = Int32(capturedImage.size.width) - faceBox.x2 - 1;
                faceBox.x2 = Int32(capturedImage.size.width) - tmp - 1;
            }
        }
        
        DispatchQueue.main.sync {
            self.faceView.setFrameSize(frameSize: capturedImage.size)
            self.faceView.setFaceBoxes(faceBoxes: faceBoxes)
        }
    }
    
    @IBAction func done_clicked(_ sender: Any) {
        self.cameraSwitchBtn.isHidden = false
        session.startRunning()
    }
    
    @IBAction func cameraSwitchClicked(_ sender: Any) {
        let defaults = UserDefaults.standard
        cameraLens_val = defaults.integer(forKey: "camera_lens")
        
        switch cameraLens_val {
        case 0:
            defaults.set(1, forKey: "camera_lens")
        case 1:
            defaults.set(0, forKey: "camera_lens")
        default:
            print("cameraSwitchClicked")
            
        }
        self.viewDidLoad()
    }
    
}


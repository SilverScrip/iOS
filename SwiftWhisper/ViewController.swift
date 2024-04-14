import Oxy
import AVFoundation
import UIKit
import Photos

enum Constants {
    static let updateInterval = 0.03
    static let barAmount = 40
    static let magnitudeLimit: Float = 32
}


class ViewController: UIViewController, oxyDelegate  {
    
    var pOxy_str = ""
    
    let myLabel = UILabel()
    
    private func setupLabel() {
            myLabel.text = "Waiting to sync!"
            myLabel.textAlignment = .center
            myLabel.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(myLabel)

            NSLayoutConstraint.activate([
                myLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                myLabel.bottomAnchor.constraint(equalTo: recordButton.topAnchor, constant: -20), // Adjust the constant as needed
                myLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),  // Added leading constraint
                myLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20) // Added trailing constraint
            ])
        }
    
    private func startFlashingLabel() {
            UIView.animate(withDuration: 0.5, delay: 0, options: [.repeat, .autoreverse, .allowUserInteraction], animations: {
                self.myLabel.alpha = 0
            }, completion: nil)
        }
    
    private lazy var recordButton: UIButton = {
        let button = UIButton(type: .custom)
        
        // Set the image for normal state
        let image = UIImage(named: "Record")
        
        button.setImage(image, for: .normal)
        
        // Add target and action
        button.addTarget(self, action: #selector(recordButtonTapped), for: .touchUpInside)
        
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    // Add AVCaptureMovieFileOutput to handle video recording
    private let movieOutput = AVCaptureMovieFileOutput()
    
    @IBOutlet weak var onoff: UISwitch!

    //Instance
    let oxyManager = Oxy.instance()
    
    //MARK: Flow control of payload
    var tog:Bool = false
    var payload:String = ""
    
    let audioProcessing = AudioProcessing.shared
    
    let captureSession = AVCaptureSession()
        var previewLayer: AVCaptureVideoPreviewLayer!
    
    let logoImageView = UIImageView(image: UIImage(named: "Image"))
        var pulseLayers = [CAShapeLayer]()
        
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        oxyManager?.delegate=self
        //load()
        //loadCamera()
                addLogo()
                applyFadeEffect()
        // Start pulse animation
                startPulseAnimation()
        
        oxyManager!.listen()
        
        _ = addButtonToBottom(view: self.view, title: "Instructions") {
            let popupVC = PopupViewController()
            popupVC.modalPresentationStyle = .overFullScreen
            self.present(popupVC, animated: true, completion: nil)
        }
        
        // Add the recordButton to the view
                view.addSubview(recordButton)

                // Add constraints for the recordButton
                NSLayoutConstraint.activate([
                    recordButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                    recordButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
                    recordButton.widthAnchor.constraint(equalToConstant: 50),
                    recordButton.heightAnchor.constraint(equalToConstant: 50)
                ])
        
        // Check if the app has permission to access the photo library
                let status = PHPhotoLibrary.authorizationStatus()
                
                switch status {
                case .authorized:
                    // User has already granted permission
                    print("User has already granted access to the photo library.")
                case .denied, .restricted:
                    // User has denied or restricted access to the photo library
                    print("User has denied or restricted access to the photo library.")
                case .notDetermined:
                    // Request access to the photo library
                    PHPhotoLibrary.requestAuthorization { status in
                        switch status {
                        case .authorized:
                            // User has granted permission
                            print("User has granted access to the photo library.")
                        case .denied:
                            // User has denied access
                            print("User has denied access to the photo library.")
                        case .restricted:
                            // Parental controls restrict access to the photo library
                            print("Access to photo library is restricted.")
                        case .notDetermined:
                            // User has not yet made a choice
                            print("User has not yet made a choice regarding access to the photo library.")
                        @unknown default:
                            fatalError("Unexpected case when requesting photo library access authorization.")
                        }
                    }
                @unknown default:
                    fatalError("Unexpected case when checking photo library authorization status.")
                }
        // Configure capture session
                configureCaptureSession()
        
        setupLabel()
        startFlashingLabel()
    }
    
    @IBAction func offon(_ sender: Any) {

        let state = onoff.isOn
        
        if state {
            oxyManager!.listen()
        }else{
            oxyManager!.stop()
        }
    }
    
    func loadCamera() {
        // Get the default back camera for video capture
        guard let backCamera = AVCaptureDevice.default(for: .video) else {
            print("Unable to access back camera.")
            return
        }
        
        do {
            // Create input for the capture session using the back camera
            let input = try AVCaptureDeviceInput(device: backCamera)
            
            // Add input to the capture session
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
            } else {
                print("Unable to add input to capture session.")
                return
            }
        } catch {
            print("Error creating AVCaptureDeviceInput: \(error)")
            return
        }
        
        // Create AVCaptureVideoPreviewLayer to display the camera feed
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds
        // Set the opacity of the preview layer to 50%
        
        previewLayer.backgroundColor = UIColor.systemBlue.cgColor
        previewLayer.opacity = 1.7
        
       
        // Add previewLayer to your view's layer
        view.layer.addSublayer(previewLayer)
        /*
        // Add grid overlay on top of the preview layer
           let gridLayer = CAShapeLayer()
           gridLayer.frame = previewLayer.bounds
           
           // Define the grid line spacing and thickness
           let numberOfLines = 64
           let lineWidth: CGFloat = 2.0
           
           // Create a path for vertical grid lines
           let verticalPath = UIBezierPath()
           let verticalSpacing = previewLayer.bounds.width / CGFloat(numberOfLines + 1)
           for i in 1...numberOfLines {
               let x = CGFloat(i) * verticalSpacing
               verticalPath.move(to: CGPoint(x: x, y: 0))
               verticalPath.addLine(to: CGPoint(x: x, y: previewLayer.bounds.height))
           }
           
           // Create a path for horizontal grid lines
           let horizontalPath = UIBezierPath()
           let horizontalSpacing = previewLayer.bounds.height / CGFloat(numberOfLines + 1)
           for i in 1...numberOfLines {
               let y = CGFloat(i) * horizontalSpacing
               horizontalPath.move(to: CGPoint(x: 0, y: y))
               horizontalPath.addLine(to: CGPoint(x: previewLayer.bounds.width, y: y))
           }
           
           // Combine vertical and horizontal paths
           let gridPath = UIBezierPath()
           gridPath.append(verticalPath)
           gridPath.append(horizontalPath)
           
           // Set path properties
           gridLayer.path = gridPath.cgPath
           gridLayer.strokeColor = UIColor.black.cgColor
           gridLayer.lineWidth = lineWidth
           gridLayer.lineCap = .round
           gridLayer.lineJoin = .round
           
           // Add grid layer to preview layer
           previewLayer.addSublayer(gridLayer)
       
        */
        // Start the capture session
        captureSession.startRunning()
    }
    
    func addLogo() {
            // Set the size of the logo
            let logoSize = CGSize(width: 150, height: 150)
            
            // Calculate the position to center the logo horizontally and vertically
            let centerX = view.bounds.midX - (logoSize.width / 2)
            let centerY = view.bounds.midY - (logoSize.height / 2)
            
            // Set the frame of the logoImageView
            logoImageView.frame = CGRect(x: centerX, y: centerY, width: logoSize.width, height: logoSize.height)
            logoImageView.contentMode = .scaleAspectFit
            
            // Add logoImageView to the view
            view.addSubview(logoImageView)
        }
    
    func applyFadeEffect() {
        // Create a UIView to overlay on top of the camera view
        let overlayView = UIView(frame: view.bounds)
        overlayView.backgroundColor = UIColor.black.withAlphaComponent(0.5) // Adjust alpha as needed
        
        // Add overlayView to the view
        view.addSubview(overlayView)
    }
    
    func startPulseAnimation() {
        let pulseCount = 3
        let animationDuration: CFTimeInterval = 3.0
        _ = UIColor(red: CGFloat(3) / 255.0, green: CGFloat(141) / 255.0, blue: CGFloat(177) / 255.0, alpha: 0.4)
        
        let pulseColor = UIColor.blue.cgColor
        
        for i in 0..<pulseCount {
            let radius = CGFloat(50 + i * 25) // Varying radii for each ring
            let delay = Double(i) * (animationDuration / Double(pulseCount)) // Adjusted delay for each ring
            
            let pulseLayer = createPulseLayer(withColor: pulseColor, andRadius: radius, andAnimationDuration: animationDuration, andDelay: delay)
            pulseLayers.append(pulseLayer)
            view.layer.insertSublayer(pulseLayer, below: logoImageView.layer)
        }
    }
    
    func createPulseLayer(withColor color: CGColor, andRadius radius: CGFloat, andAnimationDuration duration: CFTimeInterval, andDelay delay: CFTimeInterval) -> CAShapeLayer {
        let pulseLayer = CAShapeLayer()
        let ioColor = UIColor(red: CGFloat(3) / 255.0, green: CGFloat(141) / 255.0, blue: CGFloat(177) / 255.0, alpha: 0.4)
        pulseLayer.fillColor = ioColor.cgColor // Convert UIColor to CGColor
        pulseLayer.strokeColor = ioColor.cgColor

        pulseLayer.lineWidth = 8.0
        
        let path = UIBezierPath(arcCenter: logoImageView.center, radius: radius, startAngle: 0, endAngle: CGFloat(2 * Double.pi), clockwise: true)
        pulseLayer.path = path.cgPath
        
        let pulseAnimation = CABasicAnimation(keyPath: "opacity")
        pulseAnimation.duration = duration
        pulseAnimation.fromValue = 1.0
        pulseAnimation.toValue = 0.0
        pulseAnimation.autoreverses = true
        pulseAnimation.repeatCount = .infinity
        pulseAnimation.timingFunction = CAMediaTimingFunction(name: .easeOut)
        pulseAnimation.beginTime = CACurrentMediaTime() + delay
        
        pulseLayer.add(pulseAnimation, forKey: "pulse")
        
        return pulseLayer
    }
    //MARK: Still processing audio push to new thread
    
    func oxyId(with oxy_id: String?) {
        DispatchQueue.main.async {
            // Check if oxy_id is not nil
            
                    
            if let oxyId = oxy_id, oxyId != "BAD", oxyId != self.pOxy_str
            {
                
                self.pOxy_str = oxy_id!
                //continue listening for other id_ but not BAD or nil
                
                self.applyColorChangingEffect()
                
                // Play audio
                self.audioProcessing.player.play()
                
                
                // Start recording
                let popupVC = ColourViewController()
                popupVC.modalPresentationStyle = .overFullScreen
                self.present(popupVC, animated: true, completion: nil)
            }
            
        }
    }

 
    func random() -> UIColor {
        return UIColor(red: .random(in: 0...1),
                       green: .random(in: 0...1),
                       blue: .random(in: 0...1),
                       alpha: 1.0)
    }


    func UIColorFromHex(rgbValue:UInt32, alpha:Double=1.0)->UIColor {
        let red = CGFloat((rgbValue & 0xFF0000) >> 16)/256.0
        let green = CGFloat((rgbValue & 0xFF00) >> 8)/256.0
        let blue = CGFloat(rgbValue & 0xFF)/256.0

        return UIColor(red:red, green:green, blue:blue, alpha:CGFloat(alpha))
    }
   
    func addButtonToBottom(view: UIView, title: String, presentPopup: @escaping () -> Void) -> UIButton {
        // Create a button
        let button = UIButton(type: .roundedRect)
        
        // Set button title
        button.setTitle(title, for: .normal)
        
        // Set button action to present pop-up
        button.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
        
        // Set button background color to white
        button.backgroundColor = .clear
        
        // Add button to the view
        view.addSubview(button)
        
        // Add constraints to the button
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            button.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            button.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            button.heightAnchor.constraint(equalToConstant: 60) // Set button height
        ])
        
        // Return the button
        return button
    }
    
    @objc func showPopup() {
            let popupVC = PopupViewController()
            popupVC.modalPresentationStyle = .overFullScreen
            present(popupVC, animated: true, completion: nil)
        }

    @objc func buttonTapped(_ sender: UIButton) {
        print("Button tapped!")
        showPopup()
    }
    
    // Method to configure AVCaptureSession
        private func configureCaptureSession() {
            guard let camera = AVCaptureDevice.default(for: .video) else {
                print("Unable to access camera.")
                return
            }

            do {
                let input = try AVCaptureDeviceInput(device: camera)
                let session = AVCaptureSession()
                session.addInput(input)

                // Add movie output
                if session.canAddOutput(movieOutput) {
                    session.addOutput(movieOutput)
                }

                let previewLayer = AVCaptureVideoPreviewLayer(session: session)
                previewLayer.videoGravity = .resizeAspectFill
                previewLayer.frame = view.bounds
                view.layer.insertSublayer(previewLayer, at: 0)

                session.startRunning()
            } catch {
                print("Error setting up capture session: \(error.localizedDescription)")
            }
        }
    
    func applyColorChangingEffect() {
        // Animate the background color change of the view
        UIView.animate(withDuration: 5.0, delay: 0, options: [.autoreverse, .repeat], animations: {
            self.view.backgroundColor = self.random() // Change to a random color
        }, completion: nil)
    }
        
    @objc private func recordButtonTapped() {
        if movieOutput.isRecording {
            // Stop recording
            movieOutput.stopRecording()
            recordButton.setTitle("Record", for: .normal)
        } else {
            // Start recording
            let popupVC = RecordViewController()
            popupVC.modalPresentationStyle = .overFullScreen
            self.present(popupVC, animated: true, completion: nil)
            
            let outputPath = NSTemporaryDirectory() + "output.mov"
            let outputURL = URL(fileURLWithPath: outputPath)
            
            // Check if file at outputURL already exists, if so, remove it
            if FileManager.default.fileExists(atPath: outputPath) {
                do {
                    try FileManager.default.removeItem(at: outputURL)
                } catch {
                    print("Error removing existing file: \(error.localizedDescription)")
                }
            }
            
            // Start recording to the outputURL
            movieOutput.startRecording(to: outputURL, recordingDelegate: self)
            recordButton.setTitle("Stop", for: .normal)
        }
    }

    
    
    
    }
class PopupViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Configure the view
        view.backgroundColor = .white
        
        // Create a scroll view
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        
        // Add content to the scroll view
        let contentView = UIView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        
        // Add content to the content view
        let stepViews: [UIView] = [
            createStepView(imageName: "3.png", stepText: "Step 1", smallText: "Enable the microphone in app"),
            createStepView(imageName: "s2.jpg", stepText: "Step 2", smallText: "Lookout for the prompt to open the app"),
            createStepView(imageName: "s4.jpg", stepText: "Step 3", smallText: "Let the app do the magic!"),
        ]
        
        var previousView: UIView?
        for stepView in stepViews {
            contentView.addSubview(stepView)
            stepView.translatesAutoresizingMaskIntoConstraints = false
            
            NSLayoutConstraint.activate([
                stepView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                stepView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                stepView.widthAnchor.constraint(equalTo: contentView.widthAnchor),
            ])
            
            if let previousView = previousView {
                stepView.topAnchor.constraint(equalTo: previousView.bottomAnchor).isActive = true
            } else {
                stepView.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
            }
            
            previousView = stepView
        }
        
        // Add dismiss button
        let dismissButton = UIButton(type: .system)
        dismissButton.setTitle("Dismiss", for: .normal)
        dismissButton.addTarget(self, action: #selector(dismissButtonTapped), for: .touchUpInside)
        dismissButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(dismissButton)
        
        NSLayoutConstraint.activate([
            dismissButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            dismissButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
        
        // Add constraints to the scroll view
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: dismissButton.bottomAnchor, constant: 20),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        // Add constraints to the content view
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
        ])
        
        // Set the content size of the scroll view
        let totalHeight = stepViews.reduce(0) { $0 + $1.bounds.height }
        contentView.heightAnchor.constraint(equalToConstant: CGFloat(totalHeight)).isActive = true
    }
    
    @objc private func dismissButtonTapped() {
        dismiss(animated: true, completion: nil)
    }
    
    private func createStepView(imageName: String, stepText: String, smallText: String) -> UIView {
        // Create a view for each step
        let stepContainer = UIView()
        
        // Add image view
        let imageView = UIImageView(image: UIImage(named: imageName))
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        stepContainer.addSubview(imageView)
        
        // Add step text label
        let stepLabel = UILabel()
        stepLabel.text = stepText
        stepLabel.textColor = .black
        stepLabel.font = UIFont.boldSystemFont(ofSize: 18)
        stepLabel.textAlignment = .center
        stepLabel.translatesAutoresizingMaskIntoConstraints = false
        stepContainer.addSubview(stepLabel)
        
        // Add small text label
        let smallLabel = UILabel()
        smallLabel.text = smallText
        smallLabel.textColor = .black
        smallLabel.font = UIFont.systemFont(ofSize: 14)
        smallLabel.textAlignment = .center
        smallLabel.numberOfLines = 0
        smallLabel.translatesAutoresizingMaskIntoConstraints = false
        stepContainer.addSubview(smallLabel)
        
        // Constraints
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: stepContainer.topAnchor, constant: 20),
            imageView.centerXAnchor.constraint(equalTo: stepContainer.centerXAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 100), // Adjust width as needed
            imageView.heightAnchor.constraint(equalToConstant: 100), // Adjust height as needed
            
            stepLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 10),
            stepLabel.leadingAnchor.constraint(equalTo: stepContainer.leadingAnchor),
            stepLabel.trailingAnchor.constraint(equalTo: stepContainer.trailingAnchor),
            
            smallLabel.topAnchor.constraint(equalTo: stepLabel.bottomAnchor, constant: 5),
            smallLabel.leadingAnchor.constraint(equalTo: stepContainer.leadingAnchor),
            smallLabel.trailingAnchor.constraint(equalTo: stepContainer.trailingAnchor),
            smallLabel.bottomAnchor.constraint(equalTo: stepContainer.bottomAnchor, constant: -20)
        ])
        
        return stepContainer
    }
}


class RecordViewController: UIViewController {
    var countdownLabel: UILabel!
    var countdownTimer: Timer?
    var countdownValue = 4
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Configure the view
        view.backgroundColor = .white
        
        // Create countdown label
        countdownLabel = UILabel()
        countdownLabel.textColor = .black
        countdownLabel.font = UIFont.systemFont(ofSize: 40, weight: .bold)
        countdownLabel.textAlignment = .center
        countdownLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(countdownLabel)
        
        // Add constraints to the countdown label
        NSLayoutConstraint.activate([
            countdownLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            countdownLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        // Start countdown timer
        startCountdown()
    }
    
    func startCountdown() {
        countdownTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateCountdown), userInfo: nil, repeats: true)
    }
    
    @objc func updateCountdown() {
        countdownValue -= 1
        if countdownValue > 0 {
            countdownLabel.text = "\(countdownValue)"
        } else {
            countdownTimer?.invalidate()
            dismiss(animated: true, completion: nil)
        }
    }
}


//MARK

class ColourViewController: UIViewController {
    var countdownLabel: UILabel!
    var countdownTimer: Timer?
    var colorChangeTimer: Timer?
    var countdownValue = 4
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initial random background color
        view.backgroundColor = getRandomColor()
        
        // Create countdown label
        countdownLabel = UILabel()
        countdownLabel.textColor = .black
        countdownLabel.font = UIFont.systemFont(ofSize: 40, weight: .bold)
        countdownLabel.textAlignment = .center
        countdownLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(countdownLabel)
        
        // Add constraints to the countdown label
        NSLayoutConstraint.activate([
            countdownLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            countdownLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        // Setup timer to change background color every few seconds
        colorChangeTimer = Timer.scheduledTimer(timeInterval: 3, target: self, selector: #selector(changeBackgroundColor), userInfo: nil, repeats: true)
        
        let logoImageView = UIImageView(image: UIImage(named: "Image"))
        
        // Set the size of the logo
        let logoSize = CGSize(width: 150, height: 150)
        
        // Calculate the position to center the logo horizontally and vertically
        let centerX = view.bounds.midX - (logoSize.width / 2)
        let centerY = view.bounds.midY - (logoSize.height / 2)
        
        // Set the frame of the logoImageView
        logoImageView.frame = CGRect(x: centerX, y: centerY, width: logoSize.width, height: logoSize.height)
        logoImageView.contentMode = .scaleAspectFit
        
        // Add logoImageView to the view
        view.addSubview(logoImageView)
        
        // Create dismiss button
                let dismissButton = UIButton(type: .system)
                dismissButton.setTitle("Dismiss", for: .normal)
                dismissButton.addTarget(self, action: #selector(dismissButtonTapped), for: .touchUpInside)
                dismissButton.translatesAutoresizingMaskIntoConstraints = false  // Use Auto Layout
                view.addSubview(dismissButton)

                // Constraints for the dismiss button
                NSLayoutConstraint.activate([
                    dismissButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                    dismissButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -40)  // 20 points from the bottom safe area
                ])
        
    }
    
    @objc private func dismissButtonTapped() {
        dismiss(animated: true, completion: nil)
        
        // Play audio
        
        let audioProcessing = AudioProcessing.shared
        audioProcessing.player.stop()
    }
    
    // Function to generate a random color
    func getRandomColor() -> UIColor {
        let red = CGFloat.random(in: 0...1)
        let green = CGFloat.random(in: 0...1)
        let blue = CGFloat.random(in: 0...1)
        return UIColor(red: red, green: green, blue: blue, alpha: 1.0)
    }
    
    // Selector function to change background color
    @objc func changeBackgroundColor() {
        UIView.animate(withDuration: 1) {
            self.view.backgroundColor = self.getRandomColor()
        }
    }
    
    deinit {
        colorChangeTimer?.invalidate()
    }
}


// Extension to conform to AVCaptureFileOutputRecordingDelegate
extension ViewController: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if let error = error {
            print("Error recording video: \(error.localizedDescription)")
        } else {
            print("Recording finished. Video saved at: \(outputFileURL)")
            showToast(message: "Video saved to library.")

            
            // Request to save the video to the photo library
            PHPhotoLibrary.shared().performChanges({
                let options = PHAssetResourceCreationOptions()
                options.shouldMoveFile = true // Move the file instead of copying
                let creationRequest = PHAssetCreationRequest.forAsset()
                creationRequest.addResource(with: .video, fileURL: outputFileURL, options: options)
            }) { saved, error in
                if let error = error {
                    print("Error saving video to photo library: \(error.localizedDescription)")
                } else {
                    print("Video saved to photo library.")
                }
            }
        }
    }
}


extension UIViewController {
    func showToast(message: String) {
        let toastLabel = UILabel(frame: CGRect(x: self.view.frame.size.width/2 - 75, y: self.view.frame.size.height-100, width: 150, height: 35))
        toastLabel.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        toastLabel.textColor = UIColor.white
        toastLabel.textAlignment = .center;
        toastLabel.font = UIFont.systemFont(ofSize: 12)
        toastLabel.text = message
        toastLabel.alpha = 1.0
        toastLabel.layer.cornerRadius = 10;
        toastLabel.clipsToBounds  =  true
        self.view.addSubview(toastLabel)
        UIView.animate(withDuration: 4.0, delay: 0.1, options: .curveEaseOut, animations: {
            toastLabel.alpha = 0.0
        }, completion: {(isCompleted) in
            toastLabel.removeFromSuperview()
        })
    }
}

import Oxy
import AVFoundation
import UIKit

enum Constants {
    static let updateInterval = 0.03
    static let barAmount = 40
    static let magnitudeLimit: Float = 32
}
 
class ViewController: UIViewController, oxyDelegate  {
    
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
        loadCamera()
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
        
        // Add previewLayer to your view's layer
        view.layer.addSublayer(previewLayer)
        
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
    
    
    func oxyId(with oxy_id: String!) {
       
   DispatchQueue.main.async {
       
       if(self.payload != oxy_id){
            self.payload = oxy_id
            self.tog = true
           //self.oxyManager?.stop()
           
           self.audioProcessing.player.play()
           print(self.payload)
           self.showToast("Oxysound has stopped passing to audio beat function")
        }
       else if (oxy_id == "BAD")
       {
           print("bad")
       }
       else{
           print(Constants.barAmount)
           
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

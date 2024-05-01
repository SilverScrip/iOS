import AVFoundation
import Accelerate
import UIKit

class AudioProcessing {
    
    
    static var shared: AudioProcessing = .init()
    
    private let engine = AVAudioEngine()
    private let bufferSize = 1024
    
    let player = AVAudioPlayerNode()
    var fftMagnitudes: [Float] = []
    
    // Flashlight
    private let flashlight = FlashlightManager()
    private let flashlightBeatThreshold: Float = 50.0 // Adjust as needed
    
    init() {
        
        // Set the audio session category
        do {
            try AVAudioSession.sharedInstance().setCategory(.multiRoute)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Error setting audio session category: \(error)")
        }
        
        _ = engine.mainMixerNode
        
        engine.prepare()
        try! engine.start()
        
        let audioFile = try! AVAudioFile(
            forReading: Bundle.main.url(forResource: "steel", withExtension: "mp3")!
        )
        let format = audioFile.processingFormat
            
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)
            
        player.scheduleFile(audioFile, at: nil)
            
        let fftSetup = vDSP_DFT_zop_CreateSetup(
            nil,
            UInt(bufferSize),
            vDSP_DFT_Direction.FORWARD
        )
            
        engine.mainMixerNode.installTap(
            onBus: 0,
            bufferSize: UInt32(bufferSize),
            format: nil
        ) { [self] buffer, _ in
            let channelData = buffer.floatChannelData?[0]
            fftMagnitudes = fft(data: channelData!, setup: fftSetup!)
            
            // Check if FFT magnitude exceeds the threshold
            let maxMagnitude = fftMagnitudes.max() ?? 0
            if maxMagnitude > flashlightBeatThreshold {
                flashlight.flash() // Trigger flashlight
            }
        }
    }
    
    func fft(data: UnsafeMutablePointer<Float>, setup: OpaquePointer) -> [Float] {
        var realIn = [Float](repeating: 0, count: bufferSize)
        var imagIn = [Float](repeating: 0, count: bufferSize)
        var realOut = [Float](repeating: 0, count: bufferSize)
        var imagOut = [Float](repeating: 0, count: bufferSize)
            
        for i in 0 ..< bufferSize {
            realIn[i] = data[i]
        }
        
        vDSP_DFT_Execute(setup, &realIn, &imagIn, &realOut, &imagOut)
        
        var magnitudes = [Float](repeating: 0, count: Constants.barAmount)
        
        realOut.withUnsafeMutableBufferPointer { realBP in
            imagOut.withUnsafeMutableBufferPointer { imagBP in
                var complex = DSPSplitComplex(realp: realBP.baseAddress!, imagp: imagBP.baseAddress!)
                vDSP_zvabs(&complex, 1, &magnitudes, 1, UInt(Constants.barAmount))
            }
        }
        
        var normalizedMagnitudes = [Float](repeating: 0.0, count: Constants.barAmount)
        var scalingFactor = Float(1)
        vDSP_vsmul(&magnitudes, 1, &scalingFactor, &normalizedMagnitudes, 1, UInt(Constants.barAmount))
            
        return normalizedMagnitudes
    }
}

class FlashlightManager {
    private let device = AVCaptureDevice.default(for: AVMediaType.video)
    
    func flash() {
        guard let device = device else { return }
        if device.hasTorch {
            do {
                try device.lockForConfiguration()
                device.torchMode = .on
                device.unlockForConfiguration()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                    self?.turnOffFlashlight()
                }
            } catch {
                print("Unable to access flashlight")
            }
        }
    }
    
    private func turnOffFlashlight() {
        guard let device = device else { return }
        if device.hasTorch {
            do {
                try device.lockForConfiguration()
                device.torchMode = .off
                device.unlockForConfiguration()
            } catch {
                print("Unable to access flashlight")
            }
        }
    }
}

import UIKit
import CoreML
import Vision

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var labelText: UILabel!

    let imagePicker = UIImagePickerController()

    override func viewDidLoad() {
        super.viewDidLoad()
        imagePicker.delegate = self
    }

    func detect(pixelBuffer: CVPixelBuffer) {
        // Create input for the model
      
        let input = petRecogniserInput(image: pixelBuffer)
        
        // Initialize the model
        let modelConfiguration = MLModelConfiguration()
        
        guard let model = try? petRecogniser(configuration: modelConfiguration) else {
            fatalError("Can't load petImageClassifier model")
        }

        do {
            // Make a prediction
            let output = try model.prediction(input: input)

            // Process the prediction results
            DispatchQueue.main.async 
            {
                self.navigationItem.title = output.target
                
                let confidence = String(format: "%.2f", (output.targetProbability[output.target] ?? 0) * 100)
                
                switch output.target {
                case "Dog":
                    self.labelText.text = "Predicted: \(output.target)\nConfidence: \(confidence)% \n\nDogs are loyal and intelligent animals, often known as man's best friend. They come in various breeds, each with unique traits, and are highly social, making them excellent companions. Dogs are also used in roles like therapy, service, and protection."
                case "Cat":
                    self.labelText.text = "Predicted: \(output.target)\nConfidence: \(confidence)% \n\nCats are independent and curious creatures, often adored for their playful yet aloof nature. They are known for their agility and ability to hunt small prey. Cats can be both affectionate and solitary, making them ideal pets for those who appreciate their quiet companionship."
                default:
                    self.labelText.text = "Predicted: \(output.target)\nConfidence: \(confidence)% \n\nCows are gentle and social animals commonly raised for milk, meat, and leather. They are essential to agriculture and are known for their calm demeanor. Cows have a strong herd instinct and form close bonds with their fellow cattle."
                }
            }
        } catch {
            print("Error making prediction: \(error.localizedDescription)")
        }
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        if let image = info[.editedImage] as? UIImage {
            imageView.image = image
            
            imagePicker.dismiss(animated: true, completion: nil)
            guard let pixelBuffer = image.pixelBuffer() else {
                fatalError("Couldn't convert UIImage to CVPixelBuffer")
            }
            detect(pixelBuffer: pixelBuffer)
        }
    }

    @IBAction func cameraTapped(_ sender: Any) {
        imagePicker.sourceType = .camera
        imagePicker.allowsEditing = true
        present(imagePicker, animated: true, completion: nil)
    }
}

// Extension to convert UIImage to CVPixelBuffer
extension UIImage {
    func pixelBuffer() -> CVPixelBuffer? {
        let attrs: [CFString: Any] = [
            kCVPixelBufferCGImageCompatibilityKey: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey: true
        ]

        var pixelBuffer: CVPixelBuffer?
        let width = 299
        let height = 299

        let status = CVPixelBufferCreate(kCFAllocatorDefault,
                                         width,
                                         height,
                                         kCVPixelFormatType_32BGRA,
                                         attrs as CFDictionary,
                                         &pixelBuffer)

        guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
            return nil
        }

        CVPixelBufferLockBaseAddress(buffer, [])
        
        // Create a graphics context
        let context = CGContext(data: CVPixelBufferGetBaseAddress(buffer),
                                width: width,
                                height: height,
                                bitsPerComponent: 8,
                                bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
                                space: CGColorSpaceCreateDeviceRGB(),
                                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)

      
        context?.draw(self.cgImage!, in: CGRect(x: 0, y: 0, width: width, height: height))

        CVPixelBufferUnlockBaseAddress(buffer, [])
        
     
        return buffer
    }
    
}


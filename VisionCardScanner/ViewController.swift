//
//  ViewController.swift
//  VisionCardScanner
//
//  Created by USER on 2022/04/28.
//

import UIKit
import Vision
import AVFoundation

struct CreditCardInfo {
    let number: String
    let name: String
    let cvv: String?
    let date: String

    init?(number: String?, name: String?, cvv: String?, date: String?) {
        guard let date = date,
              let number = number,
              let name = name
        else {
            return nil
        }
        self.name = name
        self.number = number
        self.date = date
        self.cvv = cvv
    }
}

class ViewController: UIViewController {
    @IBOutlet weak var cameraView: UIView!

    private let videoOutput = AVCaptureVideoDataOutput()
    private let captureSession = AVCaptureSession()
    private var previewLayer = AVCaptureVideoPreviewLayer()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
        setupPreviewLayer()
        addVideoOutput()
    }

    private func setupCamera() {
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device)
        else {
            return
        }

        captureSession.addInput(input)
    }

    private func setupPreviewLayer() {
        view.layer.addSublayer(previewLayer)
        previewLayer.session = captureSession
        previewLayer.frame = view.bounds
        previewLayer.videoGravity = .resizeAspect
    }

    private func addVideoOutput() {
        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as NSString: NSNumber(value: kCVPixelFormatType_32BGRA)] as [String: Any]
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "imageProcessQueue"))
        captureSession.addOutput(videoOutput)
        guard let connection = videoOutput.connection(with: AVMediaType.video),
              connection.isVideoOrientationSupported else {
            return
        }
        connection.videoOrientation = .portrait
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        captureSession.startRunning()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        captureSession.stopRunning()
    }

}

extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let frame = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }

        let request = makeTextVisionRequest()
        let imageRequestHandler = VNImageRequestHandler(
            ciImage: CIImage(cvImageBuffer: frame),
            options: [:]
        )

        try? imageRequestHandler.perform([request])

        guard let texts = request.results,
              texts.count > 0,
              let cardInfo = processCardInfo(from: texts)
        else {
            return
        }

        captureSession.stopRunning()

        DispatchQueue.main.async { [weak self] in
            guard let viewController = self?.storyboard?.instantiateViewController(withIdentifier: "resultViewController") as? ResultViewController
            else {
                return
            }

            viewController.configureDataSource(creditCardInfo: cardInfo)
            self?.navigationController?.pushViewController(viewController, animated: true)
        }
    }

    private func processCardInfo(from textObservations: [VNRecognizedTextObservation]) -> CreditCardInfo? {
        var number: String?
        var name: String?
        var date: String?
        var cvv: String?

        let results = textObservations.flatMap({
            $0.topCandidates(10)
//                .filter{$0.confidence > 0.75}
                .map({ $0.string })
                .filter{$0.allSatisfy({ $0.isNumber })}
        })

        print(results)
        for result in results {
            if validateCreditCardNumber(from: result) {
                print(result)
                number = result
            }

            if validateCvv(from: result) {
                cvv = result
            }

            if validateDate(from: result) {
                date = result
            }

            if validateName(from: result) {
                name = result
            }
        }

        return CreditCardInfo(number: number, name: name, cvv: cvv, date: date)
    }

    private func validateCreditCardNumber(from text: String) -> Bool {
        text.count >= 19 && text.filter({ $0 != " " }).allSatisfy({ $0.isNumber })
        && text.filter({ $0 == " "}).count >= 3
    }

    private func validateCvv(from text: String) -> Bool {
        text.count == 3 && text.allSatisfy({ $0.isNumber })
    }

    private func validateName(from text: String) -> Bool {
        text.contains(" ")
        && text.replacingOccurrences(of: " ", with: "")
            .allSatisfy({ $0.isLetter && $0.isUppercase && $0.isASCII })
        && text.count > 3
    }

    private func validateDate(from text: String) -> Bool {
        text.count == 5 && text.contains("/")
    }

    private func makeTextVisionRequest() -> VNRecognizeTextRequest {
        let textVisionRequest = VNRecognizeTextRequest()
        textVisionRequest.recognitionLevel = .accurate
        textVisionRequest.usesLanguageCorrection = false

        return textVisionRequest
    }
}


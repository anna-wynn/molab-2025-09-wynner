//
//  Model.swift
//  VideoManipulator
//
//  Created by Ya Wen Tang on 10/30/25.
//

import SwiftUI
import Combine
import AVFoundation
import Photos
import CoreImage.CIFilterBuiltins

enum PaintMode: String, CaseIterable {
    case pixellate = "Pixellate"
    case crystallize = "Crystallize"
    case mosaic = "Mosaic Mix"
}

final class Model: NSObject, ObservableObject {
    // Public UI bindings
    @Published var previewImage: CGImage?
    @Published var showingSavedAlert = false
    @Published var videoSaved = false

    @Published var paintMode: PaintMode = .pixellate
    @Published var motionSensitivity: Double = 1.0
    @Published var brushMin: Double = 8
    @Published var brushMax: Double = 80

    // Capture
    private let session = AVCaptureSession()
    private var videoDevice: AVCaptureDevice?
    private var videoDataOutput: AVCaptureVideoDataOutput?
    private var videoInput: AVCaptureDeviceInput?

    // Writing (filtered)
    private var assetWriter: AVAssetWriter?
    private var videoWriterInput: AVAssetWriterInput?
    private var pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor?
    private var isRecordingSession = false
    private var videoURL: URL?
    private var startTime: CMTime?

    // Image processing
    private let context = CIContext(options: nil)
    private var lastCIImage: CIImage?

    // MARK: Permissions
    func checkPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: break
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { _ in }
        default:
            print("Camera access denied")
        }

        switch PHPhotoLibrary.authorizationStatus(for: .addOnly) {
        case .authorized, .limited: break
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { _ in }
        default:
            print("Photo add access denied")
        }
    }

    // MARK: Session setup
    func setupSession() {
        session.beginConfiguration()
        session.sessionPreset = .high

        guard let cam = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)
        else { session.commitConfiguration(); return }
        videoDevice = cam

        do {
            videoInput = try AVCaptureDeviceInput(device: cam)
            if session.canAddInput(videoInput!) { session.addInput(videoInput!) }
        } catch {
            print("Video input error:", error)
        }

        let out = AVCaptureVideoDataOutput()
        out.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        out.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        if session.canAddOutput(out) { session.addOutput(out) }
        videoDataOutput = out
        videoDataOutput?.connection(with: .video)?.videoOrientation = .portrait

        session.commitConfiguration()

        DispatchQueue.global(qos: .userInitiated).async {
            self.session.startRunning()
        }
    }

    // MARK: Record
    func startRecording() {
        let tmp = (NSTemporaryDirectory() as NSString).appendingPathComponent("paintcam.mp4")
        if FileManager.default.fileExists(atPath: tmp) { try? FileManager.default.removeItem(atPath: tmp) }
        let url = URL(fileURLWithPath: tmp)
        videoURL = url

        guard let device = videoDevice else { return }
        let dims = CMVideoFormatDescriptionGetDimensions(device.activeFormat.formatDescription)
        let width = Int(dims.height) // swap for portrait
        let height = Int(dims.width)

        do {
            let writer = try AVAssetWriter(outputURL: url, fileType: .mp4)
            let videoSettings: [String: Any] = [
                AVVideoCodecKey: AVVideoCodecType.h264,
                AVVideoWidthKey: width,
                AVVideoHeightKey: height,
                AVVideoScalingModeKey: AVVideoScalingModeResizeAspectFill
            ]
            let input = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
            input.expectsMediaDataInRealTime = true

            let adaptor = AVAssetWriterInputPixelBufferAdaptor(
                assetWriterInput: input,
                sourcePixelBufferAttributes: [
                    kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA),
                    kCVPixelBufferWidthKey as String: width,
                    kCVPixelBufferHeightKey as String: height
                ])

            if writer.canAdd(input) { writer.add(input) }

            assetWriter = writer
            videoWriterInput = input
            pixelBufferAdaptor = adaptor

            writer.startWriting()
            writer.startSession(atSourceTime: .zero)
            isRecordingSession = true
            startTime = nil
        } catch {
            print("Writer error:", error)
            assetWriter = nil
            videoWriterInput = nil
            pixelBufferAdaptor = nil
        }
    }

    func stopRecording() {
        guard isRecordingSession else { return }
        isRecordingSession = false
        videoWriterInput?.markAsFinished()
        assetWriter?.finishWriting { [weak self] in
            DispatchQueue.main.async {
                self?.saveRecordingToPhotos()
                self?.assetWriter = nil
                self?.videoWriterInput = nil
                self?.pixelBufferAdaptor = nil
                self?.startTime = nil
            }
        }
    }

    private func saveRecordingToPhotos() {
        guard let url = videoURL else { return }
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
        }) { [weak self] saved, err in
            if saved {
                DispatchQueue.main.async { self?.videoSaved = true }
            } else if let err = err {
                print("Save error:", err)
            }
        }
    }

    // MARK: Core Image pipeline
    /// Returns (filteredImage, motionValue[0...1], changed)
    private func filtered(_ cvBuffer: CVPixelBuffer) -> (CIImage, CGFloat, Bool) {
        let ci = CIImage(cvPixelBuffer: cvBuffer)
        let motion = motionMagnitude(current: ci, previous: lastCIImage) // 0...1
        lastCIImage = ci

        // Map motion -> brush size
        let m = max(0, min(1, CGFloat(motion) * CGFloat(motionSensitivity)))
        let brush = CGFloat(brushMin) + m * CGFloat(max(brushMax - brushMin, 0))

        var output = ci
        var changed = false

        switch paintMode {
        case .pixellate:
            if let f = CIFilter(name: "CIPixellate") {
                f.setValue(ci, forKey: kCIInputImageKey)
                f.setValue(brush, forKey: kCIInputScaleKey)
                if let o = f.outputImage { output = o; changed = true }
            }
        case .crystallize:
            if let f = CIFilter(name: "CICrystallize") {
                f.setValue(ci, forKey: kCIInputImageKey)
                f.setValue(brush, forKey: kCIInputRadiusKey)
                if let o = f.outputImage { output = o; changed = true }
            }
        case .mosaic:
            // blend of both based on motion: low motion = gentle pixel, high = strong crystallize
            let pixelScale = max(4, brush * 0.6)
            let crystalRadius = max(6, brush)

            var pix = ci
            if let p = CIFilter(name: "CIPixellate") {
                p.setValue(ci, forKey: kCIInputImageKey)
                p.setValue(pixelScale, forKey: kCIInputScaleKey)
                if let o = p.outputImage { pix = o }
            }
            var cry = ci
            if let c = CIFilter(name: "CICrystallize") {
                c.setValue(ci, forKey: kCIInputImageKey)
                c.setValue(crystalRadius, forKey: kCIInputRadiusKey)
                if let o = c.outputImage { cry = o }
            }
            // Crossfade by motion m (0..1)
            if let blend = CIFilter(name: "CISourceOverCompositing") {
                // alpha mix: make a linear interpolation
                let alpha = m
                if let a = CIFilter(name: "CIConstantColorGenerator") {
                    a.setValue(CIColor(red: 0, green: 0, blue: 0, alpha: alpha), forKey: kCIInputColorKey)
                    if let mask = a.outputImage?
                        .cropped(to: ci.extent) {
                        // (cry * alpha) over pix
                        if let composited = blendImage(cry, over: pix, with: blend),
                           let final = blendImage(composited, over: mask, with: blend) {
                            output = final
                            changed = true
                        } else {
                            output = cry
                            changed = true
                        }
                    } else {
                        output = cry
                        changed = true
                    }
                } else {
                    output = cry
                    changed = true
                }
            } else {
                output = cry
                changed = true
            }
        }

        // Push preview
        if let cg = context.createCGImage(output, from: output.extent) {
            DispatchQueue.main.async { self.previewImage = cg }
        }
        return (output, m, changed)
    }

    /// Average frame difference to estimate motion ∈ [0,1]
    private func motionMagnitude(current: CIImage, previous: CIImage?) -> CGFloat {
        guard let previous else { return 0 }
        // downscale for cheap compute
        let scale: CGFloat = 0.1
        let w = max(16, Int(current.extent.width * scale))
        let h = max(16, Int(current.extent.height * scale))

        let curSmall = current
            .transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        let prevSmall = previous
            .transformed(by: CGAffineTransform(scaleX: scale, y: scale))

        guard
            let diff = CIFilter(name: "CIDifferenceBlendMode",
                                parameters: [kCIInputImageKey: curSmall,
                                             kCIInputBackgroundImageKey: prevSmall])?.outputImage,
            let gray = CIFilter(name: "CIColorControls",
                                parameters: [kCIInputImageKey: diff,
                                             kCIInputSaturationKey: 0])?.outputImage
        else { return 0 }

        // average intensity
        let extent = CGRect(x: 0, y: 0, width: w, height: h)
        guard let avg = CIFilter(name: "CIAreaAverage",
                                 parameters: [kCIInputImageKey: gray,
                                              kCIInputExtentKey: CIVector(cgRect: extent)])?.outputImage
        else { return 0 }

        var bitmap = [UInt8](repeating: 0, count: 4)
        let rect = CGRect(x: 0, y: 0, width: 1, height: 1)
        context.render(avg, toBitmap: &bitmap, rowBytes: 4, bounds: rect, format: .RGBA8, colorSpace: CGColorSpaceCreateDeviceRGB())
        // Use green channel as luma-ish proxy
        let intensity = CGFloat(bitmap[1]) / 255.0
        // clamp (it’s tiny), boost a touch
        return min(1, max(0, intensity * 3.0))
    }

    private func blendImage(_ image: CIImage, over bg: CIImage, with filter: CIFilter) -> CIImage? {
        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(bg, forKey: kCIInputBackgroundImageKey)
        return filter.outputImage
    }
}

// MARK: - Sample buffer delegate
extension Model: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {

        guard let px = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        if isRecordingSession {
            // Filtered frame for writing
            let (filtered, _, changed) = filtered(px)

            // Render to new PixelBuffer for writer if filtered changed
            var outBuffer: CVPixelBuffer? = nil
            CVPixelBufferCreate(kCFAllocatorDefault,
                                Int(CVPixelBufferGetWidth(px)),
                                Int(CVPixelBufferGetHeight(px)),
                                kCVPixelFormatType_32BGRA,
                                nil,
                                &outBuffer)
            if let out = outBuffer {
                if let ctx = context as CIContext? {
                    ctx.render(filtered, to: out)
                }
            }

            guard let writerInput = videoWriterInput,
                  writerInput.isReadyForMoreMediaData,
                  let adaptor = pixelBufferAdaptor,
                  let out = outBuffer else { return }

            let t = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
            if startTime == nil { startTime = t }
            let adj = CMTimeSubtract(t, startTime ?? .zero)
            adaptor.append(out, withPresentationTime: adj)
        } else {
            // Preview only
            _ = filtered(px)
        }
    }
}

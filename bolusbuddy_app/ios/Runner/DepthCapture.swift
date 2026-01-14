import Foundation
import ARKit
import UIKit
import ImageIO

struct DepthCaptureResult {
  let rgbJpeg: Data
  let depthPng16: Data?
  let confidencePng: Data?
  let intrinsicsJson: String
  let width: Int
  let height: Int
}

final class DepthCaptureManager: NSObject, ARSessionDelegate {
  private let session = ARSession()
  private var latestFrame: ARFrame?
  private let context = CIContext()

  override init() {
    super.init()
    session.delegate = self
  }

  func session(_ session: ARSession, didUpdate frame: ARFrame) {
    latestFrame = frame
  }

  func startSessionIfNeeded() {
    let config = ARWorldTrackingConfiguration()
    if ARWorldTrackingConfiguration.supportsFrameSemantics(.sceneDepth) {
      config.frameSemantics.insert(.sceneDepth)
    }
    if ARWorldTrackingConfiguration.supportsFrameSemantics(.smoothedSceneDepth) {
      config.frameSemantics.insert(.smoothedSceneDepth)
    }
    session.run(config, options: [.resetTracking, .removeExistingAnchors])
  }

  func captureDepthFrame() async throws -> DepthCaptureResult {
    startSessionIfNeeded()
    try await Task.sleep(nanoseconds: 150_000_000)
    guard let frame = latestFrame else {
      throw NSError(domain: "DepthCapture", code: 1, userInfo: [NSLocalizedDescriptionKey: "No AR frame"])
    }

    let rgbData = try jpegData(from: frame.capturedImage)
    let depthData = frame.sceneDepth?.depthMap ?? frame.smoothedSceneDepth?.depthMap
    let confidenceData = frame.sceneDepth?.confidenceMap ?? frame.smoothedSceneDepth?.confidenceMap
    let depthPng = depthData.flatMap { png16Data(from: $0) }
    let confidencePng = confidenceData.flatMap { png8Data(from: $0) }

    let intrinsics = frame.camera.intrinsics
    let intrinsicsJson = """
    {"fx":\(intrinsics.columns.0.x),"fy":\(intrinsics.columns.1.y),"cx":\(intrinsics.columns.2.x),"cy":\(intrinsics.columns.2.y)}
    """
    return DepthCaptureResult(
      rgbJpeg: rgbData,
      depthPng16: depthPng,
      confidencePng: confidencePng,
      intrinsicsJson: intrinsicsJson,
      width: Int(frame.camera.imageResolution.width),
      height: Int(frame.camera.imageResolution.height)
    )
  }

  private func jpegData(from pixelBuffer: CVPixelBuffer) throws -> Data {
    let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
    guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
      throw NSError(domain: "DepthCapture", code: 2, userInfo: [NSLocalizedDescriptionKey: "CGImage failure"])
    }
    let uiImage = UIImage(cgImage: cgImage)
    guard let data = uiImage.jpegData(compressionQuality: 0.85) else {
      throw NSError(domain: "DepthCapture", code: 3, userInfo: [NSLocalizedDescriptionKey: "JPEG encode failure"])
    }
    return data
  }

  private func png16Data(from pixelBuffer: CVPixelBuffer) -> Data? {
    CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
    defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }
    let width = CVPixelBufferGetWidth(pixelBuffer)
    let height = CVPixelBufferGetHeight(pixelBuffer)
    let rowBytes = CVPixelBufferGetBytesPerRow(pixelBuffer)
    guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) else {
      return nil
    }
    let floatBuffer = baseAddress.assumingMemoryBound(to: Float32.self)
    var output = [UInt16](repeating: 0, count: width * height)
    for y in 0..<height {
      let row = floatBuffer.advanced(by: (rowBytes / 4) * y)
      for x in 0..<width {
        let meters = row[x]
        let millimeters = max(0, min(65535, Int(meters * 1000.0)))
        output[y * width + x] = UInt16(millimeters)
      }
    }
    return output.withUnsafeBytes { raw in
      guard let provider = CGDataProvider(data: raw as CFData) else { return nil }
      let colorSpace = CGColorSpaceCreateDeviceGray()
      let cgImage = CGImage(
        width: width,
        height: height,
        bitsPerComponent: 16,
        bitsPerPixel: 16,
        bytesPerRow: width * 2,
        space: colorSpace,
        bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue),
        provider: provider,
        decode: nil,
        shouldInterpolate: false,
        intent: .defaultIntent
      )
      return cgImage?.pngData(bitsPerComponent: 16)
    }
  }

  private func png8Data(from pixelBuffer: CVPixelBuffer) -> Data? {
    CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
    defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }
    let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
    guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
      return nil
    }
    return cgImage.pngData(bitsPerComponent: 8)
  }
}

private extension CGImage {
  func pngData(bitsPerComponent: Int) -> Data? {
    let data = NSMutableData()
    guard let destination = CGImageDestinationCreateWithData(
      data as CFMutableData,
      "public.png" as CFString,
      1,
      nil
    ) else {
      return nil
    }
    let properties: [CFString: Any] = [
      kCGImagePropertyDepth: bitsPerComponent
    ]
    CGImageDestinationAddImage(destination, self, properties as CFDictionary)
    guard CGImageDestinationFinalize(destination) else {
      return nil
    }
    return data as Data
  }
}

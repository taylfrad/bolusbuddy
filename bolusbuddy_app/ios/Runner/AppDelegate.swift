import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let depthManager = DepthCaptureManager()

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: "bolusbuddy/depth",
        binaryMessenger: controller.binaryMessenger
      )
      channel.setMethodCallHandler { [weak self] call, result in
        guard let self = self else { return }
        switch call.method {
        case "getDepthCapabilities":
          let supportsDepth = ARWorldTrackingConfiguration.supportsFrameSemantics(.sceneDepth)
            || ARWorldTrackingConfiguration.supportsFrameSemantics(.smoothedSceneDepth)
          let depthType = supportsDepth ? "lidar" : "none"
          result([
            "hasDepth": supportsDepth,
            "depthType": depthType,
            "supportsConfidence": supportsDepth
          ])
        case "captureDepthFrame":
          Task {
            do {
              let capture = try await self.depthManager.captureDepthFrame()
              result([
                "rgbJpeg": FlutterStandardTypedData(bytes: capture.rgbJpeg),
                "depthPng16": capture.depthPng16 != nil
                  ? FlutterStandardTypedData(bytes: capture.depthPng16!)
                  : NSNull(),
                "confidencePng": capture.confidencePng != nil
                  ? FlutterStandardTypedData(bytes: capture.confidencePng!)
                  : NSNull(),
                "intrinsicsJson": capture.intrinsicsJson,
                "width": capture.width,
                "height": capture.height
              ])
            } catch {
              result(FlutterError(code: "DEPTH_CAPTURE_FAILED", message: error.localizedDescription, details: nil))
            }
          }
        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

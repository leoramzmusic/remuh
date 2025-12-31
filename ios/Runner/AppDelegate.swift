import Flutter
import UIKit
import AVFoundation

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var eq = AVAudioUnitEQ(numberOfBands: 10)

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let channel = FlutterMethodChannel(name: "remuh/eq_ios",
                                              binaryMessenger: controller.binaryMessenger)
    
    channel.setMethodCallHandler({
        (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
        switch call.method {
        case "initEq":
            result(true)
        case "configureBand":
            if let args = call.arguments as? [String: Any],
               let index = args["index"] as? Int,
               let freq = args["freq"] as? Double,
               let gainDb = args["gainDb"] as? Double,
               let bw = args["bw"] as? Double {
                self.configureBand(index: index, freq: Float(freq), gainDb: Float(gainDb), bandwidth: Float(bw))
                result(nil)
            } else {
                result(FlutterError(code: "INVALID_ARGS", message: nil, details: nil))
            }
        case "setGain":
            if let args = call.arguments as? [String: Any],
               let index = args["index"] as? Int,
               let gainDb = args["gainDb"] as? Double {
                self.setGain(index: index, gainDb: Float(gainDb))
                result(nil)
            } else {
                result(FlutterError(code: "INVALID_ARGS", message: nil, details: nil))
            }
        default:
            result(FlutterMethodNotImplemented)
        }
    })

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func configureBand(index: Int, freq: Float, gainDb: Float, bandwidth: Float) {
      guard index < eq.bands.count else { return }
      let band = eq.bands[index]
      band.filterType = .parametric
      band.frequency = freq
      band.gain = gainDb
      band.bandwidth = bandwidth
      band.bypass = false
  }

  func setGain(index: Int, gainDb: Float) {
      guard index < eq.bands.count else { return }
      eq.bands[index].gain = gainDb
  }
}

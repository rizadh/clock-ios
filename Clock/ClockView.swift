import UIKit
import AudioToolbox

class ClockView: UIView {
    // MARK: Static properties
    static let defaultHue: CGFloat = 0.53

    // MARK: Public properties
    var lastOrientation: UIDeviceOrientation = UIDevice.current.orientation
    var frameLayer: ClockFrameLayer = ClockFrameLayer(radius: 0.8, width: 1 / 20, tickLength: 0.05, tickWidth: 1 / 40)
    var secondHandLayer: ClockHandLayer = ClockHandLayer(width: 1 / 45, length: 0.65, pinRadius: 0.04)
    var minuteHandLayer: ClockHandLayer = ClockHandLayer(width: 1 / 20, length: 0.65)
    var hourHandLayer: ClockHandLayer = ClockHandLayer(width: 1 / 20, length: 0.45)

    // MARK: Initializers
    override init(frame: CGRect) {
        super.init(frame: frame)

        // Resize with parent view
        autoresizingMask = [.flexibleWidth, .flexibleHeight]

        isOpaque = true

        frameLayer.frame = frame
        minuteHandLayer.frame = frame
        hourHandLayer.frame = frame
        secondHandLayer.frame = frame

        // Add sublayers
        layer.addSublayer(frameLayer)
        layer.addSublayer(minuteHandLayer)
        layer.addSublayer(hourHandLayer)
        layer.addSublayer(secondHandLayer)
    }

    required init?(coder aDecoder: NSCoder) {
        return nil
    }

    // Mark: UIView methods
    override func layoutSubviews() {
        if UIDevice.current.orientation == lastOrientation {
            return
        }

        lastOrientation = UIDevice.current.orientation

        super.layoutSubviews()

        frameLayer.bounds = layer.bounds
        minuteHandLayer.bounds = layer.bounds
        secondHandLayer.bounds = layer.bounds
        hourHandLayer.bounds = layer.bounds

        frameLayer.position = layer.position
        minuteHandLayer.position = layer.position
        secondHandLayer.position = layer.position
        hourHandLayer.position = layer.position

        frameLayer.setNeedsDisplay()
        minuteHandLayer.setNeedsDisplay()
        hourHandLayer.setNeedsDisplay()
        secondHandLayer.setNeedsDisplay()
    }
}

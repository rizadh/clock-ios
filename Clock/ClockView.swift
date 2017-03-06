import UIKit
import AudioToolbox

class ClockView: UIView {
    // MARK: Static properties
    static let defaultHue: CGFloat = 0.53
    
    // MARK: Private properties
    private var displayLink: CADisplayLink!
    private var lastTouchAngle: CGFloat = 0
    private var lastOrientation: UIDeviceOrientation = UIDevice.current.orientation
    
    private var skewAngle: CGFloat = 0 {
        willSet {
            if newValue < 0 || newValue > .pi / 6 {
                AudioServicesPlaySystemSound(1104)
            }
        }
        didSet {
            skewAngle = skewAngle.truncatingRemainder(dividingBy: .pi / 6)
            
            while skewAngle < 0 {
                skewAngle += .pi / 6
            }
            
            CATransaction.begin()
            CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
            frameLayer.transform = CATransform3DMakeAffineTransform(CGAffineTransform(rotationAngle: skewAngle))
            CATransaction.commit()
        }
    }
    
    private var frameLayer: ClockFrameLayer
    private var secondHandLayer: ClockHandLayer
    private var minuteHandLayer: ClockHandLayer
    private var hourHandLayer: ClockHandLayer
    
    // MARK: Public properties
    var discoMode = false
    var themeHue: CGFloat = ClockView.defaultHue {
        didSet {
            themeHue = themeHue.truncatingRemainder(dividingBy: 1)
            
            while themeHue < 0 { self.themeHue += 1 }
            
            if themeHue.isNaN { themeHue = 0 }
            
            let primary = UIColor(hue: themeHue, saturation: 0.8889, brightness: 0.72, alpha: 1)
            let primaryDark = UIColor(hue: themeHue, saturation: 0.889, brightness: 0.54, alpha: 1)
            let primaryLight = UIColor(hue: themeHue, saturation: 0.4211, brightness: 0.76, alpha: 1)
            let secondary = UIColor(hue: themeHue, saturation: 0.1818, brightness: 0.88, alpha: 1)
            let accent = UIColor(hue: secondaryHue, saturation: 0.6957, brightness: 0.92, alpha: 1)
            
            
            CATransaction.begin()
            CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
            backgroundColor = primary
            frameLayer.innerColor = primaryDark.cgColor
            frameLayer.frameColor = secondary.cgColor
            frameLayer.tickColor = primaryLight.cgColor
            minuteHandLayer.handColor = primaryLight.cgColor
            hourHandLayer.handColor = secondary.cgColor
            secondHandLayer.handColor = accent.cgColor
            secondHandLayer.pinFillColor = primaryDark.cgColor
            CATransaction.commit()
        }
    }
    
    private var secondaryHue: CGFloat {
        get {
            return (themeHue + 0.5).truncatingRemainder(dividingBy: 1)
        }
    }
    
    
    // MARK: Public methods
    func setHandAngles(_ hands: (hour: CGFloat, minute: CGFloat, second: CGFloat)) {
        CATransaction.begin()
        CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
        minuteHandLayer.transform = CATransform3DMakeRotation(hands.minute, 0, 0, 1)
        hourHandLayer.transform = CATransform3DMakeRotation(hands.hour, 0, 0, 1)
        secondHandLayer.transform = CATransform3DMakeRotation(hands.second, 0, 0, 1)
        CATransaction.commit()
    }
    
    // MARK: Private methods
    private func resetSkewAngle() {
        let animation = CABasicAnimation(keyPath: "transform.rotation.z")
        animation.fromValue = skewAngle
        if (skewAngle < .pi / 12) {
            animation.toValue = CGFloat(0.0)
        } else {
            animation.toValue = CGFloat(0.5)
        }
        
        CATransaction.begin()
        CATransaction.setValue(CGFloat(0.2), forKey: kCATransactionAnimationDuration)
        CATransaction.setValue(CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut), forKey: kCATransactionAnimationTimingFunction)
        frameLayer.add(animation, forKey: "skew")
        CATransaction.commit()
        
        skewAngle = 0
    }
    
    private func getTouchAngle(to touchPosition: CGPoint) -> CGFloat {
        let x = touchPosition.x - center.x
        let y = touchPosition.y - center.y
        
        return (x < 0 ? 1 : 2) * .pi + atan(y / x)
    }
    
    
    
    // MARK: Initializers
    override init(frame: CGRect) {
        // Create sublayers
        frameLayer = ClockFrameLayer(radius: 0.8, width: 1 / 20, tickLength: 0.05, tickWidth: 1 / 40)
        minuteHandLayer = ClockHandLayer(width: 1 / 20, length: 0.65)
        hourHandLayer = ClockHandLayer(width: 1 / 20, length: 0.45)
        secondHandLayer = ClockHandLayer(width: 1 / 45, length: 0.65, pinRadius: 0.04)
        
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
    
    // Mark: Public methods
    func useDefaultHue() {
        themeHue = ClockView.defaultHue
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
    
    // MARK: Touch handlers (UIResponder methods)
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        discoMode = false
        
        lastTouchAngle = getTouchAngle(to: touches.first!.preciseLocation(in: self))
        frameLayer.removeAnimation(forKey: "skew")
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        let currentAngle = getTouchAngle(to: touches.first!.preciseLocation(in: self))
        
        if currentAngle != CGFloat.infinity && !currentAngle.isNaN {
            skewAngle += currentAngle - lastTouchAngle
            themeHue += (currentAngle - lastTouchAngle) / .pi / 2
            lastTouchAngle = currentAngle
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        resetSkewAngle()
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        resetSkewAngle()
    }
    
}

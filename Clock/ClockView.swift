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
        didSet {
            if skewAngle < 0 || skewAngle > .pi / 6 {
                AudioServicesPlaySystemSound(1104)
            }
            
            while skewAngle < 0 {
                skewAngle += .pi / 6
            }
            
            skewAngle = skewAngle.truncatingRemainder(dividingBy: .pi / 6)
            
            CATransaction.begin()
            CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
            frameLayer.transform = CATransform3DMakeRotation(skewAngle, 0, 0, 1)
            CATransaction.commit()
        }
    }

    // MARK: CALayers
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
    
    
    // MARK: Private functions
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
    
    private func getClockHandAngles() -> (hour: CGFloat, minute: CGFloat, second: CGFloat) {
        let date = NSDate()
        let calendar = NSCalendar.current
        
        let nanoseconds = CGFloat(calendar.component(.nanosecond, from: date as Date))
        let seconds = CGFloat(calendar.component(.second, from: date as Date)) + nanoseconds / 1e9
        let minutes = CGFloat(calendar.component(.minute, from: date as Date)) + seconds / 60
        let hours = (CGFloat(calendar.component(.hour, from: date as Date)) + minutes / 60).truncatingRemainder(dividingBy: 12)
        
        return (hour: hours * .pi / 6, minute: minutes * .pi / 30, second: seconds * .pi / 30)
    }
    
    private func getTouchAngle(to touchPosition: CGPoint) -> CGFloat {
        let x = touchPosition.x - center.x
        let y = touchPosition.y - center.y
        
        return (x < 0 ? 1 : 2) * .pi + atan(y / x)
    }
    
    @objc private func updateHands() {
        if discoMode {
            themeHue += CGFloat(displayLink.duration)
            skewAngle += 8 * CGFloat(displayLink.duration) / .pi
        }
        
        let hands = getClockHandAngles()
        
        CATransaction.begin()
        CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
        minuteHandLayer.transform = CATransform3DMakeRotation(hands.minute, 0, 0, 1)
        hourHandLayer.transform = CATransform3DMakeRotation(hands.hour, 0, 0, 1)
        secondHandLayer.transform = CATransform3DMakeRotation(hands.second, 0, 0, 1)
        CATransaction.commit()
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

        // Update hands on every screen refresh
        displayLink = CADisplayLink(target: self, selector: #selector(updateHands as (Void) -> Void))
        displayLink.add(to: .current, forMode: .commonModes)
        
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(useDefaultHue as (Void) -> Void))
        doubleTap.numberOfTapsRequired = 2
        self.addGestureRecognizer(doubleTap)
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
        
        let oldSkewAngle = skewAngle
        skewAngle = 0
        
        let minuteTransform = minuteHandLayer.transform
        let hourTransform = hourHandLayer.transform
        let secondTransform = secondHandLayer.transform
        
        CATransaction.begin()
        CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
        minuteHandLayer.transform = CATransform3DIdentity
        hourHandLayer.transform = CATransform3DIdentity
        secondHandLayer.transform = CATransform3DIdentity
        frameLayer.frame = layer.bounds
        minuteHandLayer.frame = layer.bounds
        hourHandLayer.frame = layer.bounds
        secondHandLayer.frame = layer.bounds
        minuteHandLayer.transform = minuteTransform
        hourHandLayer.transform = hourTransform
        secondHandLayer.transform = secondTransform
        CATransaction.commit()
        
        skewAngle = oldSkewAngle
        frameLayer.setNeedsDisplay()
        minuteHandLayer.setNeedsDisplay()
        hourHandLayer.setNeedsDisplay()
        secondHandLayer.setNeedsDisplay()
    }
    
    // MARK: Touch handlers (UIResponder methods)
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        discoMode = false
        
        let touch = touches.first!
        
        lastTouchAngle = getTouchAngle(to: touch.preciseLocation(in: self))
        frameLayer.removeAnimation(forKey: "skew")
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touchLocation = touches.first?.preciseLocation(in: self) else {
            fatalError("Could not get first touch")
        }
        
        let currentAngle = getTouchAngle(to: touchLocation)

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

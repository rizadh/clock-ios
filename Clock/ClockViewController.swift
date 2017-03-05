import UIKit

class ClockViewController: UIViewController {
    static let ArchiveURL = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("themeHue")
    
    var clockView: ClockView {
        get {
            return view as! ClockView
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let clockView = ClockView(frame: view.frame)
        clockView.topAnchor.constraint(equalTo: view.topAnchor)
        clockView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        clockView.leadingAnchor.constraint(equalTo: view.leadingAnchor)
        clockView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        
        let doubleTap = UITapGestureRecognizer(target: clockView, action: #selector(clockView.useDefaultHue as (Void) -> Void))
        doubleTap.numberOfTapsRequired = 2
        doubleTap.delaysTouchesEnded = false
        clockView.addGestureRecognizer(doubleTap)
        
        if let storedHue = NSKeyedUnarchiver.unarchiveObject(withFile: ClockViewController.ArchiveURL.path) as! CGFloat? {
            clockView.themeHue = storedHue
        }
        
        view = clockView
    }
    
    func saveClockHue() {
        NSKeyedArchiver.archiveRootObject(clockView.themeHue, toFile: ClockViewController.ArchiveURL.path)
    }
    
    override var prefersStatusBarHidden: Bool {
        get {
            return true
        }
    }
    
    func handleShortcutItem(withName shortcutName: String) {
        switch (shortcutName) {
        case "useDefaultTheme":
            clockView.useDefaultHue()
        case "useRandomTheme":
            clockView.themeHue = CGFloat(arc4random()) / CGFloat(UINT32_MAX)
        case "activateDiscoMode":
            clockView.discoMode = true
        default:
            fatalError("Invalid shortcut type")
        }
    }
}


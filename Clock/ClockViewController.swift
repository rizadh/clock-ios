import UIKit

class ClockViewController: UIViewController {
    var clockView: ClockView?
    
    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let ArchiveURL = DocumentsDirectory.appendingPathComponent("themeHue")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let newClockView = ClockView(frame: view.frame)
        newClockView.topAnchor.constraint(equalTo: view.topAnchor)
        newClockView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        newClockView.leadingAnchor.constraint(equalTo: view.leadingAnchor)
        newClockView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        
        newClockView.themeHue = NSKeyedUnarchiver.unarchiveObject(withFile: ClockViewController.ArchiveURL.path) as! CGFloat? ?? ClockView.defaultHue
        
        clockView = newClockView
        view.addSubview(clockView!)
    }
    
    func saveClockHue() {
        if let hue = clockView?.themeHue {
            NSKeyedArchiver.archiveRootObject(hue, toFile: ClockViewController.ArchiveURL.path)
        }
    }
    
    override var prefersStatusBarHidden: Bool {
        get {
            return true
        }
    }
    
    func handleShortcutItem(withName shortcutName: String) {
        
        switch (shortcutName) {
        case "useDefaultTheme":
            clockView?.useDefaultHue()
        case "useRandomTheme":
            clockView?.themeHue = CGFloat(arc4random()) / CGFloat(UINT32_MAX)
        case "activateDiscoMode":
            clockView?.discoMode = true
        default:
            fatalError("Invalid shortcut type")
        }
    }
}


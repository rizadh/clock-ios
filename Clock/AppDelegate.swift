import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    var clockViewController = ClockViewController()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = clockViewController
        window?.makeKeyAndVisible()
        
        if let shortcutItem = launchOptions?[UIApplicationLaunchOptionsKey.shortcutItem] as! UIApplicationShortcutItem? {
            clockViewController.handleShortcutItem(withName: shortcutItem.type)
            return false
        }
        
        return true
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        clockViewController.saveClockHue()
    }
    
    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        clockViewController.handleShortcutItem(withName: shortcutItem.type)
    }
}


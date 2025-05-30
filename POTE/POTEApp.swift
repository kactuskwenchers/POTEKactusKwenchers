import SwiftUI
import UIKit
import FirebaseCore
import SquareMobilePaymentsSDK

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        print("Initializing Firebase at \(Date())")
        FirebaseApp.configure()
        print("Firebase initialized successfully")
        MobilePaymentsSDK.initialize(
            applicationLaunchOptions: launchOptions,
            squareApplicationID: Bundle.main.object(forInfoDictionaryKey: "SQUARE_APPLICATION_ID") as? String ?? ""
        )
        return true
    }
}

@main
struct POTEApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            LoginView()
        }
    }
}

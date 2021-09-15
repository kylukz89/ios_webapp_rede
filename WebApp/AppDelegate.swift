//
//  AppDelegate.swift
//  WebApp
//
//  Created by Programador on 14/05/19.
//  Copyright © 2019 Programador. All rights reserved.
import UIKit
import CoreData
import UserNotifications
import Firebase


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

        var window: UIWindow?
        let gcmMessageIDKey = "gcm.message_id"


        func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
            
           FirebaseApp.configure()
             
            UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
            
           let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
            
           UNUserNotificationCenter.current().requestAuthorization(options: authOptions) { (_, error) in
               guard error == nil else{
                   print(error!.localizedDescription)
                   return
               }
           }
            
          
            //Solicit permission from the user to receive notifications
            UNUserNotificationCenter.current().requestAuthorization(options: authOptions) { (_, error) in
                guard error == nil else{
                    print(error!.localizedDescription)
                    return
                }
            }
             
            //get application instance ID
            InstanceID.instanceID().instanceID { (result, error) in
                if let error = error {
                    print("Error fetching remote instance ID: \(error)")
                } else if let result = result {
                    print("Remote instance ID token: \(result.token)")
                }
            }
             
            application.registerForRemoteNotifications()
           return true
        }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
           if let messageID = userInfo[gcmMessageIDKey] {
               print("Message ID: \(messageID)")
           }
            
           // Print full message.
           print(userInfo)
       }
    
       func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
           print("Unable to register for remote notifications: \(error.localizedDescription)")
       }

        func applicationWillResignActive(_ application: UIApplication) {
            // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
            // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
        }

        func applicationDidEnterBackground(_ application: UIApplication) {
            // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
            // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        }

        func applicationWillEnterForeground(_ application: UIApplication) {
            // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        }

        func applicationDidBecomeActive(_ application: UIApplication) {
            // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        }

        func applicationWillTerminate(_ application: UIApplication) {
            // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        }
 
    func registerForPushNotifications() {
      UNUserNotificationCenter.current() // 1
        .requestAuthorization(options: [.alert, .sound, .badge]) { // 2
          granted, error in
          print("Permission granted: \(granted)") // 3
      }
    }
    
    
     

    // This function is added here only for debugging purposes, and can be removed if swizzling is enabled.
    // If swizzling is disabled then this function must be implemented so that the APNs token can be paired to
    // the FCM registration token.
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
       print("APNs token retrieved: \(deviceToken)")
       Messaging.messaging().apnsToken = deviceToken
    }

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
      if let messageID = userInfo[gcmMessageIDKey] {
        print("Message ID: \(messageID)")
      }
        
        
        
     
        // converte retorno do firebase push
        let retorno = self.distrinchaObjectRetornadoFirebasePush(userInfo: userInfo)
      
        // Gera push na tela do usuario
        self.disparaPushTelaUsuario(titulo: retorno.title, msg: retorno.title)
       
        
        // Print full message.
        print("retorno ===========================>>> \(retorno.body)")
        NSLog("info %@", userInfo)
      completionHandler(UIBackgroundFetchResult.newData)
    }

 
        // Converte retorno do firebase fcm push para array de string
        func distrinchaObjectRetornadoFirebasePush(userInfo: [AnyHashable : Any]) -> (title: String, body: String) {
            var info = (title: "", body: "")
            guard let aps = userInfo["aps"] as? [String: Any] else { return info }
            guard let alert = aps["alert"] as? [String: Any] else { return info }
            let title = alert["title"] as? String ?? ""
            let body = alert["body"] as? String ?? ""
            info = (title: title, body: body)
            return info
        }
    
    // Gera notificacao recebida na tela do usuario
    private func disparaPushTelaUsuario(titulo: String, msg: String) {
       

    }
    
        ////////// ////////// ////////// ////////// ////////// ////////// ////////// ////////// ////////// ////////// ////////// ////////// ////////// ////////// ////////// //////////
        // MARK: - Core Data stack
        lazy var persistentContainer: NSPersistentContainer = {
            let container = NSPersistentContainer(name: "Gerenciamento")
            container.loadPersistentStores(completionHandler: { (storeDescription, error) in
                if let error = error as NSError? {
                    fatalError("Unresolved error \(error), \(error.userInfo)")
                }
            })
            return container
        }()
        func saveContext () {
            let context = persistentContainer.viewContext
            if context.hasChanges {
                do {
                    try context.save()
                } catch {
                    let nserror = error as NSError
                    fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
                }
            }
        }
        ////////// ////////// ////////// ////////// ////////// ////////// ////////// ////////// ////////// ////////// ////////// ////////// ////////// ////////// ////////// /////////
    }


func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
    print("Firebase registration token: \(fcmToken)")
     
    let dataDict:[String: String] = ["token": fcmToken]
    NotificationCenter.default.post(name: Notification.Name("FCMToken"), object: nil, userInfo: dataDict)
    // TODO: If necessary send token to application server.
    // Note: This callback is fired at each app startup and whenever a new token is generated.
}
 
func messaging(_ messaging: Messaging, didReceive remoteMessage: MessagingRemoteMessage) {
    print("Received data message: \(remoteMessage.appData)")
}





// [START ios_10_message_handling]
@available(iOS 10, *)
extension AppDelegate : UNUserNotificationCenterDelegate {

    // Receive displayed notifications for iOS 10 devices.
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {

        let userInfo = notification.request.content.userInfo
        if let messageID = userInfo[gcmMessageIDKey] {
            debugPrint("Message ID: \(messageID)")
        }
        debugPrint(userInfo)
        //Handle the notification ON APP
        Messaging.messaging().appDidReceiveMessage(userInfo)
        completionHandler([.sound,.alert,.badge])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {

        let userInfo = response.notification.request.content.userInfo
        if let messageID = userInfo[gcmMessageIDKey] {
            debugPrint("Message ID: \(messageID)")
        }
        //Handle the notification ON BACKGROUND
        Messaging.messaging().appDidReceiveMessage(userInfo)
        completionHandler()
    }
}
// [END ios_10_message_handling]

extension AppDelegate : MessagingDelegate {
  // [START refresh_token]
  func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
    print("Firebase registration token: \(fcmToken)")

    let dataDict:[String: String] = ["token": fcmToken]
    NotificationCenter.default.post(name: Notification.Name("FCMToken"), object: nil, userInfo: dataDict)
    // TODO: If necessary send token to application server.
    // Note: This callback is fired at each app startup and whenever a new token is generated.
  }
  // [END refresh_token]
  // [START ios_10_data_message]
  // Receive data messages on iOS 10+ directly from FCM (bypassing APNs) when the app is in the foreground.
  // To enable direct data messages, you can set Messaging.messaging().shouldEstablishDirectChannel to true.
  func messaging(_ messaging: Messaging, didReceive remoteMessage: MessagingRemoteMessage) {
    print("Received data message: \(remoteMessage.appData)")
  }
  // [END ios_10_data_message]
}
extension UIViewController: UNUserNotificationCenterDelegate {
    public func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Swift.Void) {
        completionHandler( [.alert, .badge, .sound])
        
        completionHandler(UNNotificationPresentationOptions(rawValue: UNNotificationPresentationOptions.alert.rawValue | UNNotificationPresentationOptions.sound.rawValue));
    }
}

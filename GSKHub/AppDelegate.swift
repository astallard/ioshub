/*
 Copyright (c) 2015-present, salesforce.com, inc. All rights reserved.
 
 Redistribution and use of this software in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:
 * Redistributions of source code must retain the above copyright notice, this list of conditions
 and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright notice, this list of
 conditions and the following disclaimer in the documentation and/or other materials provided
 with the distribution.
 * Neither the name of salesforce.com, inc. nor the names of its contributors may be used to
 endorse or promote products derived from this software without specific prior written
 permission of salesforce.com, inc.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR
 IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
 FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
 CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY
 WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

import Foundation
import UIKit
import SalesforceSDKCore

// Fill these in when creating a new Connected Application on Force.com 

//DEVELOPMENT
let RemoteAccessConsumerKey = "3MVG9HxRZv05HarS4brxVfRfUP2hEu95iNOEkHVbPXIZM1nV9_gfPe5k6CB8pA_4rpBi4T9J7NZKXlNauqBvp";
let OAuthRedirectURI        = "mymobileapp://callback";

//DISTRIBUTION
//let RemoteAccessConsumerKey = "3MVG9HxRZv05HarS4brxVfRfUP5AUnrk1106B94dr4lU4attwSUOvckCEIayZbBagftvA5gKOEg==";
//let OAuthRedirectURI        = "mymobileapp://callback";

class AppDelegate : UIResponder, UIApplicationDelegate
{
    var window: UIWindow?
    
    override
    init()
    {
        super.init()
        
        // register the settings bundle
        var appDefaults = [String:AnyObject]()
        
        // set the defaults
        appDefaults["baseurl"] = "https://isvsi-14ddd2ecd93-15167bf933-15bd851b0ad.force.com/ec" as AnyObject
        appDefaults["externalurls"] = false as AnyObject
        
        // register and synchronize
        UserDefaults.standard.register(defaults: appDefaults)
        UserDefaults.standard.synchronize()
        
        // Salesforce Mobile SDK Stuff
        SFLogger.shared().logLevel = .debug
        
        SalesforceSDKManager.shared().connectedAppId = RemoteAccessConsumerKey
        SalesforceSDKManager.shared().connectedAppCallbackUri = OAuthRedirectURI
        SalesforceSDKManager.shared().authScopes = ["web", "api"];
        
        //Uncomment the following line inorder to enable/force the use of advanced authentication flow.
        // SFAuthenticationManager.shared().advancedAuthConfiguration = SFOAuthAdvancedAuthConfiguration.require;
        // OR
        // To  retrieve advanced auth configuration from the org, to determine whether to initiate advanced authentication.
        // SFAuthenticationManager.shared().advancedAuthConfiguration = SFOAuthAdvancedAuthConfiguration.allow;
        
        // NOTE: If advanced authentication is configured or forced,  it will launch Safari to handle authentication
        // instead of a webview. You must implement application:openURL:options  to handle the callback.
        
        SalesforceSDKManager.shared().postLaunchAction = {
            [unowned self] (launchActionList: SFSDKLaunchAction) in
            let launchActionString = SalesforceSDKManager.launchActionsStringRepresentation(launchActionList)
            self.log(.info, msg:"Post-launch: launch actions taken: \(launchActionString)");
            self.setupRootViewController();
        }
        SalesforceSDKManager.shared().launchErrorAction = {
            [unowned self] (error: Error, launchActionList: SFSDKLaunchAction) in
            self.log(.error, msg:"Error during SDK launch: \(error.localizedDescription)")
            self.initializeAppViewState()
            SalesforceSDKManager.shared().launch()
        }
        SalesforceSDKManager.shared().postLogoutAction = {
            [unowned self] in
            self.handleSdkManagerLogout()
        }
        SalesforceSDKManager.shared().switchUserAction = {
            [unowned self] (fromUser: SFUserAccount?, toUser: SFUserAccount?) -> () in
            self.handleUserSwitch(fromUser, toUser: toUser)
        }
    }
    
    // MARK: - App delegate lifecycle
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool
    {
        self.window = UIWindow(frame: UIScreen.main.bounds)
        self.initializeAppViewState();
        
        //
        // If you wish to register for push notifications, uncomment the line below.  Note that,
        // if you want to receive push notifications from Salesforce, you will also need to
        // implement the application:didRegisterForRemoteNotificationsWithDeviceToken: method (below).
        //
        //
        
        //SFPushNotificationManager.sharedInstance().registerForRemoteNotifications()

        //
        //Uncomment the code below to see how you can customize the color, textcolor, font and fontsize of the navigation bar
        //
        let loginViewController = SFLoginViewController.sharedInstance();
        //Set showNavBar to NO if you want to hide the top bar
        // loginViewController.showNavbar = true;
        //Set showSettingsIcon to NO if you want to hide the settings icon on the nav bar
        loginViewController.showSettingsIcon = true;
        // Set primary color to different color to style the navigation header
        loginViewController.navBarColor = UIColor(red: 1.0, green: 0.45, blue: 0.2, alpha: 1.0);
        loginViewController.navBarTextColor = UIColor.white;
        //
        SalesforceSDKManager.shared().launch()

        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data)
    {
        //
        // Uncomment the code below to register your device token with the push notification manager
        //
        //
        SFPushNotificationManager.sharedInstance().didRegisterForRemoteNotifications(withDeviceToken: deviceToken)
        if (SFUserAccountManager.sharedInstance().currentUser?.credentials.accessToken != nil) {
            SFPushNotificationManager.sharedInstance().registerForSalesforceNotifications()
            print("AppDelegate: we've registered for push notifications")
        }
    }
    
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error )
    {
        // Respond to any push notification registration errors here.
        print("AppDelegate: Push Notifications failed, error is \(error.localizedDescription)")

    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        
        // Uncomment the following line, if Authentication was attempted using handle advanced OAuth flow.
        // For Advanced Auth functionality to work, edit your apps plist files and add the URL scheme that you have
        // chosen for your app. The scheme should be the same as used in  the oauthRedirectURI settings of your Connected App.
        // You should also set the  delegate(SFAuthenticationManagerDelegate) for SFAuthenticationManager to be notified
        // of success & failures. Inorder to be notfied of user's selected action on displayed alerts implement
        // authManagerDidProceedWithBrowserFlow: & authManagerDidCancelBrowserFlow:
        
        // return  SFAuthenticationManager.shared().handleAdvancedAuthenticationResponse(url)
        return false;
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any]) {
        print("AppDelegate:application didReceiveRemoteNotification userInfo is \(userInfo)")
    }
    
    // MARK: - Private methods
    func initializeAppViewState()
    {
        if (!Thread.isMainThread) {
            DispatchQueue.main.async {
                self.initializeAppViewState()
            }
            return
        }
        
        self.window!.rootViewController = InitialViewController(nibName: nil, bundle: nil)
        self.window!.makeKeyAndVisible()
    }
    
    func setupRootViewController()
    {
        //let rootVC = RootViewController(nibName: nil, bundle: nil)
        //let navVC = UINavigationController(rootViewController: rootVC)
        //self.window!.rootViewController = navVC
        
        let bundle : Bundle = Bundle.main
        let storyBoard : UIStoryboard = UIStoryboard.init(name: "GSKHub", bundle: bundle)
        let rootVC : RootViewController = storyBoard.instantiateViewController(withIdentifier: "rootView") as! RootViewController
        self.window?.rootViewController = rootVC;
        
    }
    
    func resetViewState(_ postResetBlock: @escaping () -> ())
    {
        if let rootViewController = self.window!.rootViewController {
            if let _ = rootViewController.presentedViewController {
                rootViewController.dismiss(animated: false, completion: postResetBlock)
                return
            }
        }
        postResetBlock()
    }
    
    func handleSdkManagerLogout()
    {
        self.log(.debug, msg: "SFAuthenticationManager logged out.  Resetting app.")
        self.resetViewState { () -> () in
            self.initializeAppViewState()
            
            // Multi-user pattern:
            // - If there are two or more existing accounts after logout, let the user choose the account
            //   to switch to.
            // - If there is one existing account, automatically switch to that account.
            // - If there are no further authenticated accounts, present the login screen.
            //
            // Alternatively, you could just go straight to re-initializing your app state, if you know
            // your app does not support multiple accounts.  The logic below will work either way.
            
            var numberOfAccounts : Int;
            let allAccounts = SFUserAccountManager.sharedInstance().allUserAccounts()
            numberOfAccounts = (allAccounts!.count);
            
            if numberOfAccounts > 1 {
                let userSwitchVc = SFDefaultUserManagementViewController(completionBlock: {
                    action in
                    self.window!.rootViewController!.dismiss(animated:true, completion: nil)
                })
                if let actualRootViewController = self.window!.rootViewController {
                    actualRootViewController.present(userSwitchVc!, animated: true, completion: nil)
                }
            } else {
                if (numberOfAccounts == 1) {
                    SFUserAccountManager.sharedInstance().currentUser = allAccounts?[0]
                }
                SalesforceSDKManager.shared().launch()
            }
        }
    }
    
    func handleUserSwitch(_ fromUser: SFUserAccount?, toUser: SFUserAccount?)
    {
        let fromUserName = (fromUser != nil) ? fromUser?.userName : "<none>"
        let toUserName = (toUser != nil) ? toUser?.userName : "<none>"
        self.log(.debug, msg:"SFUserAccountManager changed from user \(fromUserName ?? "From user name not set") to \(toUserName ?? "To username not set").  Resetting app.")
        self.resetViewState { () -> () in
            self.initializeAppViewState()
            SalesforceSDKManager.shared().launch()
        }
    }
    
}

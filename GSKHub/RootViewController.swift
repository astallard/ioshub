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
import AVFoundation
import WebKit
import QuickLook

class RootViewController : UIViewController, WKNavigationDelegate, WKUIDelegate, SFRestDelegate
{
    // MARK: - UI fields
    
    //@IBOutlet weak var webView: UIWebView!

    
    @IBOutlet weak var webPlaceholderView: UIView!
    @IBOutlet weak var controlView: UIView!
    @IBOutlet weak var prevButton: UIButton!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var homeButton: UIButton!
    @IBOutlet weak var appsButton: UIButton!
    @IBOutlet weak var settingsButton: UIButton!
    @IBOutlet weak var translateButton: UIButton!
    @IBOutlet weak var travelButton: UIButton!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    @IBOutlet weak var statusBarlabel: UILabel!
    @IBOutlet weak var reloadButton: UIButton!
    @IBOutlet weak var notificationButton: UIButton!
    @IBOutlet weak var warningButton: UIButton!
    
    var webView : WKWebView!
    var refreshControl : UIRefreshControl!
    var appsMenu : UIAlertController!
    
    var baseUrl : String = ""
    var allowExternalURLs : Bool = false
    var accessToken : String = ""
    
    var player: AVAudioPlayer?
    
    var urlWhitelist = ["https://isvsi-14ddd2ecd93-15167bf933-15bd851b0ad.force.com", "about:blank"]
    
    // MARK: - Lifecycle Functions
    
    override func loadView() {
        super.loadView()
        webView = WKWebView();
        webView?.uiDelegate = self
        webView?.navigationDelegate = self
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //To Do 
        reloadButton.isHidden = true
        
        // create the apps menu
        self.createAppsMenu();
        
        // Register for remote notifications
        // TODO: This should be moved
        SFPushNotificationManager.sharedInstance().registerForRemoteNotifications()
        
        // Register for internal app notifications
        NotificationCenter.default.addObserver(self, selector: #selector(remoteNotification), name: NSNotification.Name(rawValue: "remoteNotification"), object: nil)

        // Configure the web view
        webView.frame = self.webPlaceholderView.bounds
        webView.translatesAutoresizingMaskIntoConstraints = false
        self.webPlaceholderView.addSubview(webView)

        let topConstraint = NSLayoutConstraint(item: webView, attribute: NSLayoutAttribute.top, relatedBy: NSLayoutRelation.equal, toItem: webPlaceholderView, attribute: NSLayoutAttribute.top, multiplier: 1.0, constant: 0);
        let widthConstraint = NSLayoutConstraint(item: webView, attribute: NSLayoutAttribute.width, relatedBy: NSLayoutRelation.equal, toItem: webPlaceholderView, attribute: NSLayoutAttribute.width, multiplier: 1.0, constant: 0);
        let heightConstraint = NSLayoutConstraint(item: webView, attribute: NSLayoutAttribute.height, relatedBy: NSLayoutRelation.equal, toItem: webPlaceholderView, attribute: NSLayoutAttribute.height, multiplier: 1.0, constant: 0);
        webPlaceholderView.addConstraint(topConstraint);
        webPlaceholderView.addConstraint(widthConstraint);
        webPlaceholderView.addConstraint(heightConstraint);

        //configure the refresh for the web view
        refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(self.refreshWebViewFromController), for: UIControlEvents.valueChanged)
        webView.scrollView.insertSubview(refreshControl, at: 0)
        
        //set the loading indicator to hidden
        loadingIndicator.stopAnimating()
        
        let defaults = UserDefaults.standard
        let defaultsBaseUrl = defaults.string(forKey: "baseurl")
        
        if let defaultsBaseUrl = defaultsBaseUrl {
            self.baseUrl = defaultsBaseUrl
        } else {
            self.baseUrl = "https://isvsi-14ddd2ecd93-15167bf933-15bd851b0ad.force.com/ec"
        }
        
        let authManager = SFAuthenticationManager.shared()
        if(authManager.haveValidSession) {
            print("RootViewController:BANANAS we have a valid session")
        }
        
        
        //get the access token and set the home page to the current community
        if let sfAccessToken = SFAuthenticationManager.shared().coordinator.credentials.accessToken {
            self.accessToken = sfAccessToken
            
            print("RootViewController:viewDidLoad() - Access token is \(accessToken) and user is \((SFUserAccountManager.sharedInstance().currentUser?.fullName))");

            
            //let urlString = "https://isvsi-14ddd2ecd93-15167bf933-15bd851b0ad.force.com/ec/secur/frontdoor.jsp?sid=" + self.accessToken + "&retURL=https://isvsi-14ddd2ecd93-15167bf933-15bd851b0ad.force.com/ec/s/";
            let urlString = "\(self.baseUrl)/secur/frontdoor.jsp?sid=\(self.accessToken)&retURL=\(self.baseUrl)/s/"
            
            //update the welcome label
            statusBarlabel.text = "Welcome " + (SFUserAccountManager.sharedInstance().currentUser?.fullName)! + " to GSK Hub"
            
            //point the web view at the default URL
            if let url = NSURL(string: urlString) {
                let req = NSURLRequest(url: url as URL)
                webView?.load(req as URLRequest)
            }
        } else {
            print("Count not get a valid access token, the user needs to sign in");
        }
        
    }

    // MARK: - Internal Notification Functions
    
    func remoteNotification(notification: NSNotification) {
        
        let gskNotification = notification.object as! GSKNotification
        
        // update the status label text
        if(statusBarlabel != nil) {
            statusBarlabel.text = "You have a new \(gskNotification.type) Notifcation"
            self.playSound()
            
        }
        
        if(notificationButton != nil) {
            
            DispatchQueue.main.async() {
                self.notificationButton.shake()
            }
            
            //get the notification count and update the label
            let userId = SFUserAccountManager.sharedInstance().currentUser?.idData.userId;
            let request = SFRestAPI.sharedInstance().request(forQuery: "SELECT count() FROM Notification__c WHERE To__c = '" + userId! + "' AND Status__c != 'Done'")
            SFRestAPI.sharedInstance().send(request, fail: {(error:Error?) in
                print("RootViewController:remoteNotification - failed \(error?.localizedDescription ?? "No error supplied")");
            }, complete: { response in
                print("RootViewController:remoteNotification - BANANAS success");
                let responseDictionary = response as! NSDictionary
                let number = responseDictionary["totalSize"]
                DispatchQueue.main.async() {
                    UIApplication.shared.applicationIconBadgeNumber = number as! Int
                    self.notificationButton.isHidden = false
                }
            })
        }
    }
    
    // MARK: - UI Callback Functions

    @IBAction func prevButtonTouchUpInside(_ sender: Any) {
        print("prevButtonTouchUpInside called");
        if(self.webView.canGoBack) {
            self.webView.goBack()
        }
    }
    
    @IBAction func nextButtonTouchUpInside(_ sender: Any) {
        print("nextButtonTouchUpInside called");
        if(self.webView.canGoForward) {
            self.webView.goForward()
        }
    }
    
    @IBAction func homeButtonTouchUpInside(_ sender: Any) {
        //send the user back to the community home page
        print("RootViewController:homeButtonTouchUpInside called")
        showHowPage()
    }
    
    @IBAction func appsButtonTouchUpInside(_ sender: Any) {
        print("RootViewController:appsButtonTouchUpInside called")
        showAppsMenu()
    }
    
    @IBAction func settingsButtonTouchUpInside(_ sender: Any) {
        print("RootViewController:settingsButtonTouchUpInside called")
        showSettingsPage()
    }
    
    @IBAction func translateButtonTouchUpInside(_ sender: Any) {
        print("RootViewController:translateButtonTouchUpInside called")
        translatePage()

    }
    
    @IBAction func travelButtonTouchUpInside(_ sender: Any) {
        print("RootViewController:travelButtonTouchUpInside called")
        showTravelPage()
    }
    
    @IBAction func notificationButtonTouchUpInside(_ sender: Any) {
        print("RootViewController:notificationButtonTouchUpInside called")
        showNotificationsPage()
    }

    @IBAction func reloadButtonTouchUpInside(_ sender: Any) {
        print("RootViewController:reloadButtonTouchUpInside called")
        refreshWebView()
    }
    
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    // MARK: - Application Functions

    func refreshWebViewFromController(sender: UIRefreshControl) {
        print("RootViewController:refreshWebViewFromController called")
        sender.endRefreshing()
        refreshWebView()
    }
    
    
    func refreshWebView() {
        guard let webView = self.webView else {
            return
        }
        webView.reloadFromOrigin()
    }
    
    
    func showHowPage() {
        let urlString = "\(self.baseUrl)/s/"
        
        if let url = NSURL(string: urlString) {
            let req = NSURLRequest(url: url as URL)
            webView?.load(req as URLRequest)
        }
    }
    
    func createAppsMenu() {
        // show the apps action sheet
        print("RootViewController::showAppsMenu() Called.")
        
        appsMenu = UIAlertController(title: nil, message: "GSK Hub Apps Menu", preferredStyle: .actionSheet)
        appsMenu.view.tintColor = UIColor.orange

        
        let myProfileAction = UIAlertAction(title: "My Profile", style: .default, handler: {
            (alert: UIAlertAction!) -> Void in
            print("RootViewController:showAppsMenu() - myProfileAction")
            self.showProfilePage()
        })

        let mySettingsAction = UIAlertAction(title: "My Settings", style: .default, handler: {
            (alert: UIAlertAction!) -> Void in
            print("RootViewController:showAppsMenu() - mySettingsAction")
            self.showSettingsPage()
        })
        
        let logoutAction = UIAlertAction(title: "Log Out", style: .default, handler: {
            (alert: UIAlertAction!) -> Void in
            print("RootViewController:showAppsMenu() - logout")
            
            let logoutAlert = UIAlertController(title: "Confirm Log Out", message: "This action will log you out of the hub.  Are you sure?", preferredStyle: UIAlertControllerStyle.alert)
            logoutAlert.view.tintColor = UIColor.orange
            
            logoutAlert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: { action in
                print("RootViewController:showAppsMenu() - i was hasty don't log me out.")
            }))

            logoutAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { action in
                print("RootViewController:showAppsMenu() - confirm logout")
                SFAuthenticationManager.shared().logout()
                self.showHowPage();
            }))
            
            self.present(logoutAlert, animated: true, completion: nil)
        })
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: {
            (alert: UIAlertAction!) -> Void in
            print("RootViewController:showAppsMenu() - cancelAction")
        })
        
        appsMenu.addAction(myProfileAction)
        appsMenu.addAction(mySettingsAction)
        appsMenu.addAction(logoutAction)
        appsMenu.addAction(cancelAction)
    }
    
    func showAppsMenu() {
        self.present(appsMenu, animated: true, completion: nil)
    }
    
    func showSettingsPage() {
        if let userId = SFUserAccountManager.sharedInstance().currentUser?.idData.userId {
            let urlString = "\(baseUrl)/s/settings/\(userId)"
            
            if let url = NSURL(string: urlString) {
                let req = NSURLRequest(url: url as URL)
                webView?.load(req as URLRequest)
            }
        } else {
            print("RootViewController:showSettingsPage - could not get user Id")
        }
    }
    
    func showProfilePage() {
        if let userId = SFUserAccountManager.sharedInstance().currentUser?.idData.userId {
            let urlString = "\(baseUrl)/s/profile/\(userId)"
            
            if let url = NSURL(string: urlString) {
                let req = NSURLRequest(url: url as URL)
                webView?.load(req as URLRequest)
            }
        } else {
            print("RootViewController:showProfilePage - could not get user Id")
        }
    }
    
    func showTravelPage() {
        let urlString = "\(baseUrl)/s/travel-and-expenses"
        
        if let url = NSURL(string: urlString) {
            let req = NSURLRequest(url: url as URL)
            webView?.load(req as URLRequest)
        }
    }
        
    func showNotificationsPage() {
        let urlString = "\(baseUrl)/s/my-notifications"
        
        if let url = NSURL(string: urlString) {
            let req = NSURLRequest(url: url as URL)
            webView?.load(req as URLRequest)
        }
    }
    
    func translatePage() {
        // get the current URL
        let currentUrlString = webView.url?.absoluteString
        
        // call google translate
        if let currentUrlString = currentUrlString {
            var urlString = ""
            
            // are we in the community?
            if(currentUrlString.hasPrefix(baseUrl)) {
                urlString = "https://translate.google.com/translate?hl=en&sl=en&tl=fr&u=\(self.baseUrl)/secur/frontdoor.jsp?sid=\(self.accessToken)&retURL=\(currentUrlString)"
            } else {
                urlString = "https://translate.google.com/translate?hl=en&sl=en&tl=fr&u=\(currentUrlString)"
            }
            
            print("RootViewController:translatePage - Translating \(urlString)")
            
            if let url = NSURL(string: urlString) {
                let req = NSURLRequest(url: url as URL)
                webView?.load(req as URLRequest)
            }
        }
    }
    
    func playSound() {
        guard let url = Bundle.main.url(forResource: "sms-received", withExtension: "wav") else {
            print("error")
            return
        }
        
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            try AVAudioSession.sharedInstance().setActive(true)
            
            player = try AVAudioPlayer(contentsOf: url)
            guard let player = player else { return }
            
            player.play()
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        print("RootViewController:Web view createWebViewWith  configuration \(navigationAction.request.url?.absoluteString ?? "No URL") with navigationType \(navigationAction.navigationType)")
        
        
        if navigationAction.targetFrame == nil {
            let url = navigationAction.request.url
            
            if (url?.absoluteString.hasPrefix("mailto:"))! || (url?.absoluteString.hasPrefix("tel:"))! {
                if(UIApplication.shared.canOpenURL(url!)) {
                    UIApplication.shared.open(url!, options: [UIApplicationOpenURLOptionUniversalLinksOnly:true], completionHandler: nil)
                }
            } else {
                webView.load(navigationAction.request)
            }
        }
        return nil
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        print("RootViewController:Web view decidePolicyFor  navigationAction request \(navigationAction.request.url?.absoluteString ?? "No URL") with navigationType \(navigationAction.navigationType)")
        var showWarning = false
        
        
        // make sure we have a url
        if let url = navigationAction.request.url {
            // check to see if it for the telephone or email
            if url.scheme == "tel" || url.scheme == "mailto" {
                if UIApplication.shared.canOpenURL(url) {
                    // yes, so let the OS open it
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
            } else {
                // it's a url so check against the whitelist
                for wlUrl in urlWhitelist {
                    if url.absoluteString.hasPrefix(wlUrl) {
                        // it's not on the whitelist so show the warning icon
                        showWarning = true
                    }
                }
            }
            
        }
        // show the warning and allow the url
        self.warningButton.isHidden = showWarning
        decisionHandler(WKNavigationActionPolicy.allow);
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        self.loadingIndicator.startAnimating()
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        let docUrl = webView.url?.absoluteString;
        var showWarning = false
        //check against the whitelist
        
        for url in urlWhitelist {
            if(docUrl?.hasPrefix(url))! {
                showWarning = true
            }
        }
        
        self.warningButton.isHidden = showWarning
        self.loadingIndicator.stopAnimating()
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("RootViewController: Webview failed to load anything, error is \(error.localizedDescription)")
    }
    
    
    // MARK: - Memory Functions
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning();
        print("RootViewController:didRecieveMemoryWarning()")
    }
    
}

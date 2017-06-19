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

class RootViewController : UIViewController, WKNavigationDelegate, WKUIDelegate
{
    // MARK: - UI fields
    
    //@IBOutlet weak var webView: UIWebView!

    
    @IBOutlet weak var webPlaceholderView: UIView!
    @IBOutlet weak var controlView: UIView!
    @IBOutlet weak var prevButton: UIButton!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var homeButton: UIButton!
    @IBOutlet weak var profileButton: UIButton!
    @IBOutlet weak var settingsButton: UIButton!
    @IBOutlet weak var translateButton: UIButton!
    @IBOutlet weak var travelButton: UIButton!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    @IBOutlet weak var statusBarlabel: UILabel!
    @IBOutlet weak var notificationButton: UIButton!
    @IBOutlet weak var notifcationLabel: UILabel!
    @IBOutlet weak var warningButton: UIButton!
    
    var webView : WKWebView!
    
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

        
        //set the loading indicator to hidden
        loadingIndicator.stopAnimating()
        
        let defaults = UserDefaults.standard
        let defaultsBaseUrl = defaults.string(forKey: "baseurl")
        
        if let defaultsBaseUrl = defaultsBaseUrl {
            self.baseUrl = defaultsBaseUrl
        } else {
            self.baseUrl = "https://isvsi-14ddd2ecd93-15167bf933-15bd851b0ad.force.com/ec"
        }

        //get the access token and set the home page to the current community
        if let sfAccessToken = SFAuthenticationManager.shared().coordinator.credentials.accessToken {
            self.accessToken = sfAccessToken
                        
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
        
        if(statusBarlabel != nil) {
            statusBarlabel.text = "You have a new \(gskNotification.type) Notifcation"
        }
        
        if(notificationButton != nil) {
            //get the notification count and update the label
            let count = GSKDataManager.shared.gskNotifications.count;
            notifcationLabel.text = "\(count)"
            notificationButton.isHidden = false
            notifcationLabel.isHidden = false
            self.playSound()
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
    
    @IBAction func profileButtonTouchUpInside(_ sender: Any) {
        print("RootViewController:profileButtonTouchUpInside called")
        showProfilePage()
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
    
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    // MARK: - Application Functions

    func showHowPage() {
        let urlString = "\(self.baseUrl)/s/"
        
        if let url = NSURL(string: urlString) {
            let req = NSURLRequest(url: url as URL)
            webView?.load(req as URLRequest)
        }
    }
    
    func showProfilePage() {
        if let userId = SFUserAccountManager.sharedInstance().currentUser?.idData.userId {
            let urlString = "\(self.baseUrl)/s/profile/\(userId)"
            
            if let url = NSURL(string: urlString) {
                let req = NSURLRequest(url: url as URL)
                webView?.load(req as URLRequest)
            }
        } else {
            print("RootViewController:showProfilePage - could not get user Id")
        }
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
    
    func showTravelPage() {
        let urlString = "\(baseUrl)/s/travel-and-expenses"
        
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
    
    // MARK: - UIWebViewDelegate Functions
    
    /*func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        print("RootViewController:Web view shouldStartLoadwith request \(request.url?.absoluteString ?? "No URL") with navigationType \(navigationType)")
        let docUrl = request.url?.absoluteString
        var showWarning = false
        
        //check against the whitelist
        for url in urlWhitelist {
            if(docUrl?.hasPrefix(url))! {
                showWarning = true
            }
        }
        
        self.warningButton.isHidden = showWarning
        return true
    }*/
    
    /*func webViewDidStartLoad(_ webView: UIWebView) {
        self.loadingIndicator.startAnimating()
    }*/
    
    /*func webViewDidFinishLoad(_ webView: UIWebView) {
        let docUrl = webView.request?.mainDocumentURL?.absoluteString;
        var showWarning = false
        //check against the whitelist
        
        for url in urlWhitelist {
            if(docUrl?.hasPrefix(url))! {
                showWarning = true
            }
        }
        
        self.warningButton.isHidden = showWarning
        self.loadingIndicator.stopAnimating()
    }*/
    
    /*func webView(_ webView: UIWebView, didFailLoadWithError error: Error) {
        print("RootViewController: Webview failed to load anything, error is \(error.localizedDescription)")
    }*/
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        print("RootViewController:Web view decidePolicyFor  navigationAction request \(navigationAction.request.url?.absoluteString ?? "No URL") with navigationType \(navigationAction.navigationType)")
        let docUrl = navigationAction.request.url?.absoluteString
        var showWarning = false
        
        //check against the whitelist
        for url in urlWhitelist {
            if(docUrl?.hasPrefix(url))! {
                showWarning = true
            }
        }
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

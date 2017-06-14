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

class RootViewController : UIViewController, UIWebViewDelegate
{
    // MARK: - UI fields
    
    @IBOutlet weak var webView: UIWebView!
    @IBOutlet weak var controlView: UIView!
    @IBOutlet weak var prevButton: UIButton!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var homeButton: UIButton!
    @IBOutlet weak var profileButton: UIButton!
    @IBOutlet weak var settingsButton: UIButton!
    @IBOutlet weak var travelButton: UIButton!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    @IBOutlet weak var statusBarlabel: UILabel!
    
    
    var baseUrl : String = ""
    var allowExternalURLs : Bool = false
    var accessToken : String = ""
    
    // MARK: - Lifecycle Functions

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //set the web view delegate
        webView?.delegate = self
        
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
                        
            let urlString = "https://isvsi-14ddd2ecd93-15167bf933-15bd851b0ad.force.com/ec/secur/frontdoor.jsp?sid=" + self.accessToken + "&retURL=https://isvsi-14ddd2ecd93-15167bf933-15bd851b0ad.force.com/ec/s/";
            //let urlString = "\(self.baseUrl)/secur/frontdoor.jsp?sid=\(self.accessToken)&retURL=\(self.baseUrl)/s/"
            
            //update the welcome label
            statusBarlabel.text = "Welcome " + (SFUserAccountManager.sharedInstance().currentUser?.fullName)! + " to GSK Hub"
            
            //point the web view at the default URL
            if let url = NSURL(string: urlString) {
                let req = NSURLRequest(url: url as URL)
                webView?.loadRequest(req as URLRequest)
            }
        } else {
            print("Count not get a valid access token, the user needs to sign in");
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
    
    @IBAction func travelButtonTouchUpInside(_ sender: Any) {
        print("RootViewController:settingsButtonTouchUpInside called")
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
            webView?.loadRequest(req as URLRequest)
        }
    }
    
    func showProfilePage() {
        if let userId = SFUserAccountManager.sharedInstance().currentUser?.idData.userId {
            let urlString = "\(self.baseUrl)/s/profile/\(userId)"
            
            if let url = NSURL(string: urlString) {
                let req = NSURLRequest(url: url as URL)
                webView?.loadRequest(req as URLRequest)
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
                webView?.loadRequest(req as URLRequest)
            }
        } else {
            print("RootViewController:showSettingsPage - could not get user Id")
        }
    }
    
    func showTravelPage() {
        let urlString = "\(baseUrl)/s/travel-and-expenses"
        
        if let url = NSURL(string: urlString) {
            let req = NSURLRequest(url: url as URL)
            webView?.loadRequest(req as URLRequest)
        }
    }
    
    
    // MARK: - UIWebViewDelegate Functions
    
    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        print("RootViewController:Web view shouldStartLoadwith request \(request.url?.absoluteString ?? "No URL") with navigationType \(navigationType)")
        
        return true
    }
    
    func webViewDidStartLoad(_ webView: UIWebView) {
        self.loadingIndicator.startAnimating()
    }
    
    func webViewDidFinishLoad(_ webView: UIWebView) {
        self.loadingIndicator.stopAnimating()
    }
    
    func webView(_ webView: UIWebView, didFailLoadWithError error: Error) {
        print("RootViewController: Webview failed to load anything, error is \(error.localizedDescription)")
    }
    
    // MARK: - Memory Functions
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning();
        print("RootViewController:didRecieveMemoryWarning()")
    }
    
}

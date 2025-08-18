//
//  HTMLView.swift
//  macInstaller
//
//  Created by Paulo Raffaelli on 7/1/24.
//

import SwiftUI
import WebKit

struct LicenseHTMLView: NSViewRepresentable {
    typealias NSViewType = WKWebView
 
    var fileURL: URL {
        guard let url = Bundle.main.url(forResource: "License", withExtension: "html") else {
            fatalError("path does not exist")
        }
        return url
    }
 
    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.defaultWebpagePreferences.allowsContentJavaScript = false
        
        let webView = WKWebView(frame: .zero, configuration: config)

        webView.allowsBackForwardNavigationGestures = false
        return webView
    }
 
    func updateNSView(_ uiView: WKWebView, context: Context) {
        uiView.loadFileURL(fileURL, allowingReadAccessTo: fileURL)
    }
}

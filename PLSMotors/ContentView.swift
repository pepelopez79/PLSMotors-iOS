//
//  ContentView.swift
//  PLSMotors
//
//  Created by Pepe López Salado on 28/11/24.
//

import SwiftUI
import WebKit

class WebViewCoordinator: NSObject, WKUIDelegate {
    var parent: WebView
    
    init(parent: WebView) {
        self.parent = parent
    }
    
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
            completionHandler()
        }))
        
        if let rootVC = UIApplication.shared.windows.first?.rootViewController {
            rootVC.present(alert, animated: true, completion: nil)
        }
    }
}

extension WebViewCoordinator: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "validationError", let errorMessage = message.body as? String {
            DispatchQueue.main.async {
                let alert = UIAlertController(title: "Error de Validación", message: errorMessage, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                
                if let rootVC = UIApplication.shared.windows.first?.rootViewController {
                    rootVC.present(alert, animated: true, completion: nil)
                }
            }
        }
    }
}

struct WebView: UIViewRepresentable {
    var url: String
    
    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = true

        let script = """
        document.addEventListener('invalid', function(event) {
            event.preventDefault();
            var input = event.target;
            var errorMessage = input.getAttribute('title') || 'Los datos introducidos en el campo ' + input.name + ' no son válidos o están vacíos.';
            
            if (window.webkit && window.webkit.messageHandlers.validationError) {
                window.webkit.messageHandlers.validationError.postMessage(errorMessage);
            }
        }, true);
        """
        let userScript = WKUserScript(source: script, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        let contentController = WKUserContentController()
        contentController.addUserScript(userScript)
        contentController.add(context.coordinator as! WKScriptMessageHandler, name: "validationError")
        configuration.userContentController = contentController

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.uiDelegate = context.coordinator

        if let url = URL(string: url) {
            let request = URLRequest(url: url)
            webView.load(request)
        }
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        //
    }
    
    func makeCoordinator() -> WebViewCoordinator {
        return WebViewCoordinator(parent: self)
    }
}

struct ContentView: View {
    var body: some View {
        WebView(url: "https://pepelopez79.github.io/PLSMotors/")
            .edgesIgnoringSafeArea(.bottom)
    }
}


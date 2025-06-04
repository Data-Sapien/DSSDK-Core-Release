//
//  IntelligenceWebViewModuleProvider.swift
//  DSSDKCore
//
//  Created by Metecan Duyal on 4.06.2025.
//

import DSSDK
import Foundation
import WebKit

@available(iOS 17.0, *)
@objc(IntelligenceWebViewModuleProvider)
public class IntelligenceWebViewModuleProvider: NSObject, @preconcurrency WebViewModuleProvider {

    public override init() {}

    @MainActor public static func provideUserScripts() -> [WKUserScript] {
        let js = """
        window.IntelligenceService = {
            loadModel: function(modelName, onStatus, onComplete, onError) {
                const id = Date.now();
                const statusCallback = `onStatus_${id}`;
                const completeCallback = `onComplete_${id}`;
                const errorCallback = `onError_${id}`;

                window[statusCallback] = onStatus;
                window[completeCallback] = onComplete;
                window[errorCallback] = onError;

                window.webkit.messageHandlers.intelligenceHandler.postMessage({
                    method: "loadModel",
                    modelName: modelName,
                    onStatus: statusCallback,
                    onComplete: completeCallback,
                    onError: errorCallback
                });
            },

            invokeModel: function(modelName, prompt, onComplete, onStream, onError) {
                const id = Date.now();
                const completeCallback = `onComplete_${id}`;
                const streamCallback = `onStream_${id}`;
                const errorCallback = `onError_${id}`;

                window[completeCallback] = onComplete;
                window[streamCallback] = onStream;
                window[errorCallback] = onError;

                window.webkit.messageHandlers.intelligenceHandler.postMessage({
                    method: "invokeModel",
                    modelName: modelName,
                    prompt: prompt,
                    onComplete: completeCallback,
                    onStream: streamCallback,
                    onError: errorCallback
                });
            },

            isModelDownloaded: function(modelName, onResult) {
                const id = Date.now();
                const resultCallback = `onResult_${id}`;
                window[resultCallback] = onResult;

                window.webkit.messageHandlers.intelligenceHandler.postMessage({
                    method: "isModelDownloaded",
                    modelName: modelName,
                    onResult: resultCallback
                });
            }
        };
        """
        return [
            WKUserScript(source: js, injectionTime: .atDocumentStart, forMainFrameOnly: true)
        ]
    }
    

    @MainActor public static func provideHandlers(webView: WKWebView) -> [String : WKScriptMessageHandler] {
        return [
            "intelligenceHandler": WebViewIntelligenceServiceHandler(webView: webView)
        ]
    }
}

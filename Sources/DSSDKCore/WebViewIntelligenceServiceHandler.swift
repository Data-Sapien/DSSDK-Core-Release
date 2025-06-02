//
//  WebViewIntelligenceServiceHandler.swift
//  DSSDK
//
//  Created by Metecan Duyal on 19.04.2025.
//

import WebKit

@preconcurrency
class WebViewIntelligenceServiceHandler: NSObject, WKScriptMessageHandler {
    weak var webView: WKWebView?

    init(webView: WKWebView) {
        self.webView = webView
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let body = message.body as? [String: Any],
            let method = body["method"] as? String
        else {
            return
        }

        switch method {
        case "loadModel":
            print("METEMODEL userContentController loadModel")
            handleLoadModel(
                modelName: body["modelName"] as? String,
                onStatus: body["onStatus"] as? String,
                onComplete: body["onComplete"] as? String,
                onError: body["onError"] as? String)

        case "invokeModel":
            handleInvokeModel(
                modelName: body["modelName"] as? String,
                prompt: body["prompt"] as? String,
                onComplete: body["onComplete"] as? String,
                onStream: body["onStream"] as? String,
                onError: body["onError"] as? String)

        case "isModelDownloaded":
            handleIsModelDownloaded(
                modelName: body["modelName"] as? String,
                onResult: body["onResult"] as? String)

        default:
            break
        }
    }

    private func handleLoadModel(modelName: String?, onStatus: String?, onComplete: String?, onError: String?) {
        guard let modelName, let onStatus, let onComplete, let onError else { return }
        print("METEMODEL handleLoadModel loadModel")
        Task { @MainActor in
            IntelligenceService.shared.load(modelName: modelName) { status in
                self.callJSFunction(name: onStatus, with: status)
            } completion: { _ in
                self.callJSFunction(name: onComplete, with: true)
            } error: { error in
                self.callJSFunction(name: onError, with: error.localizedDescription)
            }
        }
    }

    private func handleInvokeModel(modelName: String?, prompt: String?, onComplete: String?, onStream: String?, onError: String?) {
        guard let modelName, let prompt, let onComplete, let onStream, let onError else { return }

        Task { @MainActor in
            IntelligenceService.shared.invoke(
                modelName: modelName,
                systemPrompt: prompt,
                streaming: { output in
                    self.callJSFunction(name: onStream, with: output)
                },
                completion: { result in
                    self.callJSFunction(name: onComplete, with: result)
                },
                error: { error in
                    self.callJSFunction(name: onError, with: error.localizedDescription)
                }
            )
        }
    }

    private func handleIsModelDownloaded(modelName: String?, onResult: String?) {
        guard let modelName, let onResult else { return }

        let downloaded = IntelligenceService.shared.isModelDownloaded(modelName: modelName)
        self.callJSFunction(name: onResult, with: downloaded)
    }

    nonisolated func callJSFunction(name: String, with value: Any) {
        let escaped: String
        
        print("METEMODEL callJSFunction \(name) --- \(value)")


        if let string = value as? String {
            escaped = "\"\(string.jsEscapedString())\""
        } else {
            escaped = "\(value)"
        }
        
        print("METEMODEL callJSFunction \(escaped)")


        DispatchQueue.main.async {
            self.webView?.evaluateJavaScript("\(name)(\(escaped));") { result, error in
                if let error = error {
                    print("METEMODEL callJSFunction err \(error)")

                    print("⚠️ JS Callback Error: \(error)")
                }
            }
        }
    }
    internal func getUserScripts() -> WKUserScript {
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
        return WKUserScript(source: js, injectionTime: .atDocumentStart, forMainFrameOnly: true)
    }
}

//
//  IntelligenceService+JS.swift
//  DSSDKModel
//
//  Created by Metecan Duyal on 17.04.2025.
//

@preconcurrency import JavaScriptCore

extension IntelligenceService: JavaScriptExportable {

    nonisolated public func registerMethods(to context: JSContext) {
        let modelService = JSValue(newObjectIn: context)

        let invokeModelFunction:
            @convention(block) (
                String, String, JSValue, JSValue, JSValue
            ) -> Void = { modelName, prompt, completeCallback, streamCallback, errorCallback in

                let complete = completeCallback
                let stream = streamCallback
                let error = errorCallback
                Task { @MainActor in
                    self.invoke(
                        modelName: modelName,
                        systemPrompt: prompt,
                        streaming: { output in
                            stream.call(withArguments: [output])
                        },
                        completion: { result in
                            complete.call(withArguments: [result])
                        },
                        error: { err in
                            complete.call(withArguments: [err.localizedDescription])
                        }
                    )
                }
            }

        modelService?.setObject(
            invokeModelFunction,
            forKeyedSubscript: "invokeModel" as NSString
        )

        let loadModelFunction: @convention(block) (String, JSValue, JSValue, JSValue) -> Void = { modelName, statusCallback, completeCallback, errorCallback in

            Task { @MainActor in
                let status = statusCallback
                let complete = completeCallback
                let error = errorCallback

                IntelligenceService.shared.load(modelName: modelName) { result in
                    status.call(withArguments: [result])
                } completion: { model in
                    complete.call(withArguments: [true])
                } error: { err in
                    error.call(withArguments: [err.localizedDescription])
                }
            }
        }

        modelService?.setObject(
            loadModelFunction,
            forKeyedSubscript: "loadModel" as NSString
        )

        let isModelDownloadedFunction: @convention(block) (String, JSValue) -> Void = { modelName, result in
            Task {
                let res = await IntelligenceService.shared.isModelDownloaded(modelName: modelName)
                result.call(withArguments: [res])
            }
        }

        modelService?.setObject(
            isModelDownloadedFunction,
            forKeyedSubscript: "isModelDownloaded" as NSString
        )
        
        context.setObject(modelService, forKeyedSubscript: "IntelligenceService" as NSString)

    }

}

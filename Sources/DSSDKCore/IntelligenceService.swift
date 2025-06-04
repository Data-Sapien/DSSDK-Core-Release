//
//  IntelligenceService.swift
//  DSSDKModel
//
//  Created by Arda Doğantemur on 7.04.2025.
//

import MLX
import MLXLLM
import MLXLMCommon
import MLXRandom
import Foundation

enum LLMEvaluatorError: Error {
    case modelNotFound(String)
    case modelIsAlreadyRunning
}

@available(iOS 17.0, *)
@Observable
@MainActor
public class IntelligenceService {
    
    public static let shared = IntelligenceService()

    enum LoadState {
        case idle
        case loaded(ModelContainer)
    }
    
    public static let llama_3_2_1b_4bit = ModelConfiguration(id: "mlx-community/Llama-3.2-1B-Instruct-4bit")
    public static let llama_3_2_3b_4bit = ModelConfiguration(id: "mlx-community/Llama-3.2-3B-Instruct-4bit")
    public static let deepseek_r1_distill_qwen_1_5b_4bit = ModelConfiguration(id: "mlx-community/DeepSeek-R1-Distill-Qwen-1.5B-4bit")
    public static let deepseek_r1_distill_qwen_1_5b_8bit = ModelConfiguration(id: "mlx-community/DeepSeek-R1-Distill-Qwen-1.5B-8bit")
    
    var appManager = AppManager()
    var running = false
    var cancelled = false
    var output = ""
    var modelInfo = ""
    var stat = ""
    var progress = 0.0
    var thinkingTime: TimeInterval?
    var collapsed: Bool = false
    var isThinking: Bool = false
    private var startTime: Date?
    var modelConfiguration = ModelConfiguration.defaultModel
    
    /// parameters controlling the output
    let generateParameters = GenerateParameters(temperature: 0.5)
    let maxTokens = 4096 // Max tokens that llm produce

    /// update the display every N tokens -- 4 looks like it updates continuously
    /// and is low overhead.  observed ~15% reduction in tokens/s when updating
    /// on every token
    let displayEveryNTokens = 4
    var loadState = LoadState.idle
    var elapsedTime: TimeInterval? {
        if let startTime {
            return Date().timeIntervalSince(startTime)
        }

        return nil
    }

    
    // MARK: - Switch Model
    // ===============================================================================
    public func switchModel(_ model: ModelConfiguration) async {
        progress = 0.0 // reset progress
        loadState = .idle
        modelConfiguration = model
        _ = try? await load(modelName: model.name)
    }
    
    // MARK: - LOAD
    // ===============================================================================
    private func load(modelName: String) async throws -> ModelContainer {
        guard let model = ModelConfiguration.getModelByName(modelName) else {
            throw LLMEvaluatorError.modelNotFound(modelName)
        }
        
        switch loadState {
        case .idle:
            // limit the buffer cache
            MLX.GPU.set(cacheLimit: 20 * 1024 * 1024)

            let modelContainer = try await LLMModelFactory.shared.loadContainer(configuration: model) {
                [modelConfiguration] progress in
                Task { @MainActor in
                    self.modelInfo =
                        "Downloading \(modelConfiguration.name): \(Int(progress.fractionCompleted * 100))%"
                    self.progress = progress.fractionCompleted
                }
            }
            modelInfo =
                "Loaded \(modelConfiguration.id).  Weights: \(MLX.GPU.activeMemory / 1024 / 1024)M"
            loadState = .loaded(modelContainer)
            return modelContainer

        case let .loaded(modelContainer):
            return modelContainer
        }
    }
    
    public func isModelDownloaded(modelName: String) -> Bool
    {
        let installedModels = appManager.installedModels
        return installedModels.contains(modelName)
    }
    
    public func getDownloadedModelsList() -> [String]
    {
        return appManager.installedModels
    }
    
    public func load(modelName: String, status: @escaping @Sendable(Double) -> (), completion: @escaping @Sendable(ModelContainer) -> () , error: @escaping @Sendable(Error)->()) {
        guard let model = ModelConfiguration.getModelByName(modelName) else {
            error(LLMEvaluatorError.modelNotFound(modelName))
            return
        }

        switch loadState {
        case .idle:
            // limit the buffer cache
            Task
            {
                MLX.GPU.set(cacheLimit: 20 * 1024 * 1024)

                let modelContainer = try await LLMModelFactory.shared.loadContainer(configuration: model) {
                    [modelConfiguration] progress in
                    Task { @MainActor in
                        
                        self.modelInfo =
                            "Downloading \(modelConfiguration.name): \(Int(progress.fractionCompleted * 100))%"
                        self.progress = progress.fractionCompleted
                        print("METEMODEL status \(progress.fractionCompleted)")
                        status(progress.fractionCompleted)
                    }
                }
                modelInfo =
                    "Loaded \(modelConfiguration.id).  Weights: \(MLX.GPU.activeMemory / 1024 / 1024)M"
                loadState = .loaded(modelContainer)
                appManager.currentModelName = modelName
                appManager.addInstalledModel(modelName)
                
                completion(modelContainer)
            }


        case let .loaded(modelContainer):
            completion(modelContainer)
        }
    }
    
    // MARK: - Generate
    // ===============================================================================
    public func stop() {
        isThinking = false
        cancelled = true
    }
    
    public func invoke(modelName: String, systemPrompt: String , streaming:@escaping @Sendable(String) -> () , completion:@escaping @Sendable(String) -> () , error:@escaping @Sendable(Error) -> ())
    {
        guard !running else
        {
            error(LLMEvaluatorError.modelIsAlreadyRunning)
            return
        }

        running = true
        cancelled = false
        output = ""
        startTime = Date()
        
        Task
        {
            do {
                let modelContainer = try await load(modelName: modelName)

                
                // augment the prompt as needed
                let promptHistory = await modelContainer.configuration.getPromptHistory(systemPrompt: systemPrompt)
                
                if await modelContainer.configuration.modelType == .reasoning {
                    isThinking = true
                }

                // each time you generate you will get something new
                MLXRandom.seed(UInt64(Date.timeIntervalSinceReferenceDate * 1000))

                let result = try await modelContainer.perform { context in
                    let input = try await context.processor.prepare(input: .init(messages: promptHistory))
                    return try MLXLMCommon.generate(
                        input: input, parameters: generateParameters, context: context
                    ) { tokens in

                        var cancelled = false
                        Task { @MainActor in
                            cancelled = self.cancelled
                        }

                        // update the output -- this will make the view show the text as it generates
                        if tokens.count % displayEveryNTokens == 0 {
                            let text = context.tokenizer.decode(tokens: tokens)
                            Task { @MainActor in
                                self.output = text
                                streaming(self.output)
                                print("STREAMING \(self.output)")
                            }
                        }

                        if tokens.count >= maxTokens || cancelled {
                            return .stop
                        } else {
                            return .more
                        }
                    }
                }

                // update the text if needed, e.g. we haven't displayed because of displayEveryNTokens
                if result.output != output {
                    output = result.output
                }
                stat = " Tokens/second: \(String(format: "%.3f", result.tokensPerSecond))"

            } catch {
                output = "Failed: \(error)"
            }

            running = false
            completion(output)
            print("COMPLETEEEE \(self.output)")
        }
    }

    func invoke(modelName: String, systemPrompt: String) async -> String {
        guard !running else { return "" }

        running = true
        cancelled = false
        output = ""
        startTime = Date()

        do {
            let modelContainer = try await load(modelName: modelName)

            
            // augment the prompt as needed
            let promptHistory = await modelContainer.configuration.getPromptHistory(systemPrompt: systemPrompt)

            if await modelContainer.configuration.modelType == .reasoning {
                isThinking = true
            }

            // each time you generate you will get something new
            MLXRandom.seed(UInt64(Date.timeIntervalSinceReferenceDate * 1000))

            let result = try await modelContainer.perform { context in
                let input = try await context.processor.prepare(input: .init(messages: promptHistory))
                return try MLXLMCommon.generate(
                    input: input, parameters: generateParameters, context: context
                ) { tokens in

                    var cancelled = false
                    Task { @MainActor in
                        cancelled = self.cancelled
                    }

                    // update the output -- this will make the view show the text as it generates
                    if tokens.count % displayEveryNTokens == 0 {
                        let text = context.tokenizer.decode(tokens: tokens)
                        Task { @MainActor in
                            self.output = text
                        }
                    }

                    if tokens.count >= maxTokens || cancelled {
                        return .stop
                    } else {
                        return .more
                    }
                }
            }

            // update the text if needed, e.g. we haven't displayed because of displayEveryNTokens
            if result.output != output {
                output = result.output
            }
            stat = " Tokens/second: \(String(format: "%.3f", result.tokensPerSecond))"

        } catch {
            output = "Failed: \(error)"
        }

        running = false
        return output
    }
    
    
}

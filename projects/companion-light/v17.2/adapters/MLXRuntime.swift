// CC0-1.0
// Written against ml-explore/mlx-swift-lm @ e3d4a20 (2026-09-03). Apple platforms only.
// Two roles, one set of weights: every generate() opens a fresh ChatSession. That is deliberate —
// null-state reset is an immune property (Memory Alpha inv. 1); the KV cache never carries Judge into Voice.
#if canImport(MLXLLM)
import Foundation
import CompanionCore
import MLXLLM
import MLXLMCommon
import MLXHuggingFace
import MLXEmbedders
import HuggingFace
import Tokenizers

public final class MLXRuntime: ModelRuntime {
    private let modelDir: URL
    private var container: ModelContainer?

    /// Local weights, e.g. `mlx-community/gemma-4-e4b-it-4bit` snapshot copied into Application Support.
    public init(modelDir: URL) { self.modelDir = modelDir }

    public func load() async throws {
        container = try await LLMModelFactory.shared.loadContainer(from: modelDir, using: #huggingFaceTokenizerLoader())
    }

    public func generate(system: String, user: String, sampling: Sampling) async throws -> String {
        guard let container else { throw RuntimeError.notLoaded }
        let params = GenerateParameters(maxTokens: sampling.maxTokens,
                                        temperature: Float(sampling.temperature),
                                        topP: Float(sampling.topP))
        let session = ChatSession(container, instructions: system, generateParameters: params)
        return try await session.respond(to: user)
    }
}

/// EmbeddingGemma (model_type gemma3_text → EmbeddingGemma in the MLXEmbedders registry). Local directory.
public final class GemmaEmbedder: Embedder {
    private let modelDir: URL
    private var container: EmbedderModelContainer?
    public init(modelDir: URL) { self.modelDir = modelDir }

    public func load() async throws {
        container = try await EmbedderModelFactory.shared.loadContainer(from: modelDir, using: #huggingFaceTokenizerLoader())
    }

    public func embed(_ text: String) async throws -> [Float] {
        guard let container else { throw RuntimeError.notLoaded }
        return await container.perform { (model: EmbeddingModel, tokenizer: Tokenizer, pooling: Pooling) -> [Float] in
            let ids = tokenizer.encode(text: text, addSpecialTokens: true)
            let input = MLXArray(ids).expandedDimensions(axis: 0)
            let mask = MLXArray.ones(like: input)
            let tokenTypes = MLXArray.zeros(like: input)
            let out = pooling(model(input, positionIds: nil, tokenTypeIds: tokenTypes, attentionMask: mask),
                              normalize: true, applyLayerNorm: true)
            out.eval()
            return out[0].asArray(Float.self)
        }
    }
}
#endif

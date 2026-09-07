// CC0-1.0
// VERIFY before shipping: the MLX-Swift LLM API moves. Shape is right; names may not be.
// Model: Gemma 4 E4B, 4-bit MLX weights (~3–4 GB on disk, ~8 GB RAM at runtime).
// Alternative: llama.cpp via a Swift bridge with a GGUF file — same protocol, different body.
import Foundation
// import MLX
// import MLXLLM
// import MLXLMCommon

public final class MLXRuntime: ModelRuntime {
    private let modelDir: URL
    // private var container: ModelContainer?
    public init(modelDir: URL) { self.modelDir = modelDir }

    public func load() async throws {
        // container = try await LLMModelFactory.shared.loadContainer(configuration: .init(directory: modelDir))
    }

    public func generate(system: String, user: String, sampling: Sampling) async throws -> String {
        // guard let container else { throw RuntimeError.notLoaded }
        // let messages: [[String: String]] = [["role": "system", "content": system], ["role": "user", "content": user]]
        // let params = GenerateParameters(maxTokens: sampling.maxTokens, temperature: Float(sampling.temperature), topP: Float(sampling.topP))
        // return try await container.perform { ctx in
        //     let input = try await ctx.processor.prepare(input: .init(messages: messages))
        //     var out = ""
        //     for await g in try MLXLMCommon.generate(input: input, parameters: params, context: ctx) {
        //         if case .chunk(let s) = g { out += s }
        //     }
        //     return out
        // }
        throw RuntimeError.notLoaded
    }
}

/// EmbeddingGemma via MLX. VERIFY: model id and pooling.
public final class GemmaEmbedder: Embedder {
    public init(modelDir: URL) {}
    public func embed(_ text: String) async throws -> [Float] { throw RuntimeError.notLoaded }
}

public enum RuntimeError: Error { case notLoaded, http(Int, String) }

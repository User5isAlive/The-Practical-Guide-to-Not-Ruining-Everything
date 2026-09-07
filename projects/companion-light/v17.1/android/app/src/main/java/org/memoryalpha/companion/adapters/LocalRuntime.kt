// CC0-1.0
// VERIFY before shipping: two candidate bodies for the same interface. Pick one.
//  A) LiteRT-LM  — Google's stack, best NPU/GPU acceleration, .litertlm format (Gemma 4 E4B ≈ 3.7 GB file).
//  B) llama.cpp  — GGUF via JNI, model-agnostic, slower. Sovereignty pick.
package org.memoryalpha.companion.adapters

import org.memoryalpha.companion.core.Embedder
import org.memoryalpha.companion.core.ModelRuntime
import org.memoryalpha.companion.core.Sampling

class LiteRtRuntime(private val modelPath: String) : ModelRuntime {
    // private var engine: Engine? = null   // com.google.ai.edge.litertlm.Engine — VERIFY class/package names
    fun load() {
        // engine = Engine(EngineConfig(modelPath = modelPath, backend = Backend.GPU)).also { it.initialize() }
    }
    override suspend fun generate(system: String, user: String, sampling: Sampling): String {
        // val conv = engine!!.createConversation(ConversationConfig(systemInstruction = system,
        //     samplerConfig = SamplerConfig(temperature = sampling.temperature.toFloat(), topP = sampling.topP.toFloat())))
        // return conv.sendMessage(user).text
        throw IllegalStateException("runtime not loaded — see VERIFY notes")
    }
}

/** EmbeddingGemma via LiteRT. VERIFY model id and mean-pooling. */
class GemmaEmbedder(private val modelPath: String) : Embedder {
    override suspend fun embed(text: String): FloatArray = throw IllegalStateException("embedder not loaded")
}

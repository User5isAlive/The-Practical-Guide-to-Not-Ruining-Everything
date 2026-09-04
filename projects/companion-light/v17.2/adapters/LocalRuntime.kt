// CC0-1.0
// Written against google-ai-edge/LiteRT-LM @ b41b3c3 (2026-09-03), artifact com.google.ai.edge.litertlm:litertlm-android.
// One .litertlm file (gemma-4-E4B-it-litert-lm) is the same file the iOS LiteRTRuntime loads.
// Every generate() opens a fresh Conversation and closes it: null-state reset between roles (Memory Alpha inv. 1).
package org.memoryalpha.companion.adapters

import com.google.ai.edge.litertlm.Backend
import com.google.ai.edge.litertlm.Contents
import com.google.ai.edge.litertlm.ConversationConfig
import com.google.ai.edge.litertlm.EmbeddingEngine
import com.google.ai.edge.litertlm.EmbeddingEngineConfig
import com.google.ai.edge.litertlm.EmbeddingOptions
import com.google.ai.edge.litertlm.Engine
import com.google.ai.edge.litertlm.EngineConfig
import com.google.ai.edge.litertlm.InputData
import com.google.ai.edge.litertlm.Message
import com.google.ai.edge.litertlm.SamplerConfig
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.memoryalpha.companion.core.Embedder
import org.memoryalpha.companion.core.ModelRuntime
import org.memoryalpha.companion.core.Sampling

class LiteRtRuntime(modelPath: String, backend: Backend = Backend.GPU(), maxNumTokens: Int = 4096) : ModelRuntime, AutoCloseable {
    private val engine = Engine(EngineConfig(modelPath = modelPath, backend = backend, maxNumTokens = maxNumTokens))

    suspend fun load() = withContext(Dispatchers.IO) { engine.initialize() }

    override suspend fun generate(system: String, user: String, sampling: Sampling): String = withContext(Dispatchers.IO) {
        val config = ConversationConfig(
            systemInstruction = Contents.of(system),
            samplerConfig = SamplerConfig(topK = 40, topP = sampling.topP, temperature = maxOf(sampling.temperature, 0.0)),
            maxOutputToken = sampling.maxTokens,
        )
        engine.createConversation(config).use { conv -> conv.sendMessage(Message.user(user)).toString() }
    }
    override fun close() = engine.close()
}

/** EmbeddingGemma as a .litertlm embedding model. */
class LiteRtEmbedder(modelPath: String, backend: Backend = Backend.CPU()) : Embedder, AutoCloseable {
    private val engine = EmbeddingEngine(EmbeddingEngineConfig(modelPath = modelPath, backend = backend))
    suspend fun load() = withContext(Dispatchers.IO) { engine.initialize() }
    override suspend fun embed(text: String): FloatArray = withContext(Dispatchers.IO) {
        engine.computeEmbedding(listOf(InputData.Text(text)), EmbeddingOptions(normalize = true)).embedding
    }
    override fun close() = engine.close()
}

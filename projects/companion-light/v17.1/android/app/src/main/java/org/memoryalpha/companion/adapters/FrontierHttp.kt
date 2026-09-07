// CC0-1.0
// BYOK frontier clients. Keys come from EncryptedSharedPreferences; the core never persists them.
package org.memoryalpha.companion.adapters

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.json.JSONArray
import org.json.JSONObject
import org.memoryalpha.companion.core.FrontierClient
import java.net.HttpURLConnection
import java.net.URL

private fun post(url: String, headers: Map<String, String>, body: JSONObject): JSONObject {
    val c = URL(url).openConnection() as HttpURLConnection
    c.requestMethod = "POST"; c.doOutput = true; c.setRequestProperty("Content-Type", "application/json")
    headers.forEach { (k, v) -> c.setRequestProperty(k, v) }
    c.outputStream.use { it.write(body.toString().toByteArray()) }
    val text = (if (c.responseCode < 300) c.inputStream else c.errorStream).bufferedReader().readText()
    if (c.responseCode >= 300) throw RuntimeException("HTTP ${c.responseCode}: $text")
    return JSONObject(text)
}

class AnthropicClient(private val key: String, private val model: String = "claude-sonnet-4-6") : FrontierClient {
    override val name = "claude"
    override suspend fun complete(system: String, user: String): String = withContext(Dispatchers.IO) {
        val j = post("https://api.anthropic.com/v1/messages", mapOf("x-api-key" to key, "anthropic-version" to "2023-06-01"),
            JSONObject().put("model", model).put("max_tokens", 1024).put("system", system)
                .put("messages", JSONArray().put(JSONObject().put("role", "user").put("content", user))))
        val parts = j.getJSONArray("content"); (0 until parts.length()).joinToString("") { parts.getJSONObject(it).optString("text") }
    }
}

class OpenAIClient(private val key: String, private val model: String = "gpt-5") : FrontierClient {
    override val name = "gpt"
    override suspend fun complete(system: String, user: String): String = withContext(Dispatchers.IO) {
        val j = post("https://api.openai.com/v1/chat/completions", mapOf("Authorization" to "Bearer $key"),
            JSONObject().put("model", model).put("messages", JSONArray()
                .put(JSONObject().put("role", "system").put("content", system)).put(JSONObject().put("role", "user").put("content", user))))
        j.getJSONArray("choices").getJSONObject(0).getJSONObject("message").getString("content")
    }
}

class GeminiClient(private val key: String, private val model: String = "gemini-2.5-pro") : FrontierClient {
    override val name = "gemini"
    override suspend fun complete(system: String, user: String): String = withContext(Dispatchers.IO) {
        val j = post("https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$key", emptyMap(),
            JSONObject().put("system_instruction", JSONObject().put("parts", JSONArray().put(JSONObject().put("text", system))))
                .put("contents", JSONArray().put(JSONObject().put("role", "user").put("parts", JSONArray().put(JSONObject().put("text", user))))))
        val parts = j.getJSONArray("candidates").getJSONObject(0).getJSONObject("content").getJSONArray("parts")
        (0 until parts.length()).joinToString("") { parts.getJSONObject(it).optString("text") }
    }
}

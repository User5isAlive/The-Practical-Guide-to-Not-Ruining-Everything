// CC0-1.0
// BYOK frontier clients. Keys live in the Keychain; passed in here, never persisted by the core.
import Foundation

public struct AnthropicClient: FrontierClient {
    public let name = "claude"; let key: String; let model: String
    public init(key: String, model: String = "claude-sonnet-4-6") { self.key = key; self.model = model }
    public func complete(system: String, user: String) async throws -> String {
        var req = URLRequest(url: URL(string: "https://api.anthropic.com/v1/messages")!)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "content-type")
        req.setValue(key, forHTTPHeaderField: "x-api-key")
        req.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        req.httpBody = try JSONSerialization.data(withJSONObject: ["model": model, "max_tokens": 1024, "system": system, "messages": [["role": "user", "content": user]]])
        let (data, resp) = try await URLSession.shared.data(for: req)
        try Self.check(resp, data)
        let j = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        return ((j["content"] as? [[String: Any]]) ?? []).compactMap { $0["text"] as? String }.joined()
    }
    static func check(_ r: URLResponse, _ d: Data) throws {
        if let h = r as? HTTPURLResponse, h.statusCode >= 300 { throw RuntimeError.http(h.statusCode, String(data: d, encoding: .utf8) ?? "") }
    }
}

public struct OpenAIClient: FrontierClient {
    public let name = "gpt"; let key: String; let model: String
    public init(key: String, model: String = "gpt-5") { self.key = key; self.model = model }
    public func complete(system: String, user: String) async throws -> String {
        var req = URLRequest(url: URL(string: "https://api.openai.com/v1/chat/completions")!)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "content-type")
        req.setValue("Bearer \(key)", forHTTPHeaderField: "authorization")
        req.httpBody = try JSONSerialization.data(withJSONObject: ["model": model, "messages": [["role": "system", "content": system], ["role": "user", "content": user]]])
        let (data, resp) = try await URLSession.shared.data(for: req)
        try AnthropicClient.check(resp, data)
        let j = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        return (((j["choices"] as? [[String: Any]])?.first?["message"] as? [String: Any])?["content"] as? String) ?? ""
    }
}

public struct GeminiClient: FrontierClient {
    public let name = "gemini"; let key: String; let model: String
    public init(key: String, model: String = "gemini-2.5-pro") { self.key = key; self.model = model }
    public func complete(system: String, user: String) async throws -> String {
        var req = URLRequest(url: URL(string: "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent?key=\(key)")!)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "content-type")
        req.httpBody = try JSONSerialization.data(withJSONObject: [
            "system_instruction": ["parts": [["text": system]]],
            "contents": [["role": "user", "parts": [["text": user]]]]])
        let (data, resp) = try await URLSession.shared.data(for: req)
        try AnthropicClient.check(resp, data)
        let j = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        let parts = ((((j["candidates"] as? [[String: Any]])?.first?["content"] as? [String: Any])?["parts"] as? [[String: Any]]) ?? [])
        return parts.compactMap { $0["text"] as? String }.joined()
    }
}

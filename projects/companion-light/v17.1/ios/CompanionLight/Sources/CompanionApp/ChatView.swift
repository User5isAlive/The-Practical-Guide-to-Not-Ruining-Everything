// CC0-1.0
// Minimal SwiftUI shell: one chat, six sliders, promote button on committee drafts.
import SwiftUI
import CompanionCore
import CryptoKit

@MainActor
final class ChatModel: ObservableObject {
    @Published var messages: [(role: String, text: String)] = []
    @Published var sliders = Sliders()
    @Published var lastTurn: Turn?
    @Published var input = ""
    let persona: Persona

    init() {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let key = Curve25519.Signing.PrivateKey()          // PROD: load from Keychain; create once
        let vault = try! Vault(path: dir.appendingPathComponent("vault.sqlite").path, signer: key, presence: BiometricPresence())   // PROD: KeychainKeyStore
        let librarian = try! Librarian(vault: vault, embedder: HashEmbedder())   // swap for GemmaEmbedder
        let runtime = MLXRuntime(modelDir: dir.appendingPathComponent("models/gemma-4-e4b-4bit"))
        persona = Persona(vault: vault, librarian: librarian, local: runtime, frontier: [] /* BYOK clients from Keychain */)
        sliders = Sliders((try? vault.sliders()) ?? [:])
    }

    func send() {
        let q = input; input = ""
        messages.append(("you", q))
        Task {
            do {
                let t = try await persona.answer(q, sliders: sliders)
                lastTurn = t
                messages.append((persona.personaName, t.reply))
                if let s = t.spread { messages.append(("spread", Self.renderSpread(s))) }   // CAT-002: UI renders, verbatim
            } catch { messages.append(("system", "\(error)")) }
        }
    }

    static func renderSpread(_ s: Spread) -> String {
        var out = "COMMITTEE \(s.returned)/\(s.expected)"
        if !s.missing.isEmpty { out += "  missing: " + s.missing.map { "\($0.key) (\($0.value.prefix(40)))" }.joined(separator: ", ") }
        if !s.agree.isEmpty { out += "\nAGREE: " + s.agree.joined(separator: "; ") }
        for d in s.disagree { out += "\nDISAGREE — \(d.topic):" ; for (m, p) in d.positions.sorted(by: { $0.key < $1.key }) { out += "\n   \(m): \(p)" } }
        return out
    }

    func set(_ name: String, _ v: Int) {
        sliders.values[name] = v
        Task { try? await persona.vault.setSlider(name, v) }   // T1-A: presence-gated, signed
    }
}

struct ChatView: View {
    @StateObject var m = ChatModel()
    @State var showSliders = false

    var body: some View {
        VStack {
            ScrollView { ForEach(Array(m.messages.enumerated()), id: \.offset) { _, msg in
                HStack { if msg.role != "you" { Spacer() }
                    Text(msg.text).padding(10).background(msg.role == "you" ? .gray.opacity(0.2) : .blue.opacity(0.15)).cornerRadius(10)
                    if msg.role == "you" { Spacer() } }.padding(.horizontal) } }
            if let t = m.lastTurn, !t.drafts.isEmpty {
                ForEach(t.drafts, id: \.id) { d in
                    Button("Keep \(d.model)'s draft (signs a T1 note about it)") { Task { try? await m.persona.promote(draftId: d.id, ownerStatement: "Owner reviewed and kept this draft.") } }.font(.caption)
                }
            }
            HStack {
                TextField("Ask", text: $m.input).textFieldStyle(.roundedBorder)
                Button("Send", action: m.send)
                Button("TARS") { showSliders.toggle() }
            }.padding()
        }
        .sheet(isPresented: $showSliders) {
            VStack(alignment: .leading) {
                ForEach(Sliders.names, id: \.self) { n in
                    Text("\(n.capitalized): \(m.sliders.anchor(n))").font(.caption)
                    Slider(value: Binding(get: { Double(m.sliders.values[n] ?? 50) }, set: { m.set(n, Int($0)) }), in: 0...100, step: 1)
                }
            }.padding()
        }
    }
}

// CC0-1.0
// Minimal Compose shell: one chat, six sliders, promote button on committee drafts.
package org.memoryalpha.companion.ui

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.launch
import org.memoryalpha.companion.core.*

class ChatViewModel(val persona: Persona) : ViewModel() {
    val messages = mutableStateListOf<Pair<String, String>>()
    val sliders = Sliders(persona.vault.sliders())
    var lastTurn by mutableStateOf<Turn?>(null)
    var sliderTick by mutableStateOf(0)

    fun send(q: String) {
        messages.add("you" to q)
        viewModelScope.launch {
            runCatching { persona.answer(q, sliders) }
                .onSuccess { lastTurn = it; messages.add(persona.personaName to it.reply) }
                .onFailure { messages.add("system" to it.toString()) }
        }
    }
    fun set(name: String, v: Int) { sliders.values[name] = v; persona.vault.setSlider(name, v); sliderTick++ }   // signed T1 event
    fun promote(id: String) = viewModelScope.launch { runCatching { persona.promote(id, "Owner reviewed and kept this draft.") } }
}

@Composable
fun ChatScreen(vm: ChatViewModel) {
    var input by remember { mutableStateOf("") }
    var showSliders by remember { mutableStateOf(false) }
    Column(Modifier.fillMaxSize().padding(12.dp)) {
        LazyColumn(Modifier.weight(1f)) { items(vm.messages) { (who, text) -> Text("$who: $text", Modifier.padding(6.dp)) } }
        vm.lastTurn?.drafts?.forEach { d -> TextButton(onClick = { vm.promote(d.id) }) { Text("Keep ${d.model}'s draft (signs a T1 note about it)") } }
        Row {
            OutlinedTextField(input, { input = it }, Modifier.weight(1f), placeholder = { Text("Ask") })
            Button(onClick = { vm.send(input); input = "" }) { Text("Send") }
            TextButton(onClick = { showSliders = !showSliders }) { Text("TARS") }
        }
        if (showSliders) { vm.sliderTick; Sliders.NAMES.forEach { n ->
            Text("${n.replaceFirstChar { it.uppercase() }}: ${vm.sliders.anchor(n)}", style = MaterialTheme.typography.labelSmall)
            Slider(value = (vm.sliders.values[n] ?: 50).toFloat(), onValueChange = { vm.set(n, it.toInt()) }, valueRange = 0f..100f)
        } }
    }
}

package me.gabber235.typewriter.entries.event

import lol.pyr.znpcsplus.api.event.NpcInteractEvent
import me.gabber235.typewriter.adapters.Colors
import me.gabber235.typewriter.adapters.Entry
import me.gabber235.typewriter.adapters.modifiers.EntryIdentifier
import me.gabber235.typewriter.adapters.modifiers.Help
import me.gabber235.typewriter.entries.entity.ZNPC
import me.gabber235.typewriter.entry.EntryListener
import me.gabber235.typewriter.entry.Query
import me.gabber235.typewriter.entry.entries.EventEntry
import me.gabber235.typewriter.entry.startDialogueWithOrNextDialogue
import me.gabber235.typewriter.utils.Icons

@Entry("znpc_on_npc_interact", "当玩家点击NPC时", Colors.YELLOW, Icons.PEOPLE_ROBBERY)
/**
 * The `NPC Interact Event` is fired when a player interacts with an NPC.
 *
 * ## How could this be used?
 *
 * This can be used to create a variety of interactions that can occur between an NPC and a player. For example, you could create an NPC that gives the player an item when they interact with it.
 */
class NpcInteractEventEntry(
    override val id: String = "",
    override val name: String = "",
    override val triggers: List<String> = emptyList(),
    @EntryIdentifier(ZNPC::class)
    @Help("NPC 的标识符（id）。")
    // The NPC that needs to be interacted with.
    val identifier: String = "",
) : EventEntry


@EntryListener(NpcInteractEventEntry::class)
fun onNpcInteract(event: NpcInteractEvent, query: Query<NpcInteractEventEntry>) {
    val entries: List<ZNPC> = Query findWhere { it.id == event.entry.id }
    val identifiers = entries.map { it.id }

    query findWhere {
        it.identifier in identifiers
    } startDialogueWithOrNextDialogue event.player
}
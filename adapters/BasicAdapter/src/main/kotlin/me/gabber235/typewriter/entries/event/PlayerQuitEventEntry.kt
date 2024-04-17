package me.gabber235.typewriter.entries.event

import me.gabber235.typewriter.adapters.Colors
import me.gabber235.typewriter.adapters.Entry
import me.gabber235.typewriter.entry.EntryListener
import me.gabber235.typewriter.entry.Query
import me.gabber235.typewriter.entry.entries.EventEntry
import me.gabber235.typewriter.entry.triggerAllFor
import me.gabber235.typewriter.utils.Icons
import org.bukkit.event.player.PlayerQuitEvent

@Entry("on_player_quit", "当玩家退出服务器时", Colors.YELLOW, Icons.PERSON_CIRCLE_MINUS)
/**
 * The `Player Quit Event` event is called when a player quits the server.
 *
 * ## How could this be used?
 *
 * This could be used to reset a boss when they leave or to teleport them outside a dungeon.
 */
class PlayerQuitEventEntry(
    override val id: String = "",
    override val name: String = "",
    override val triggers: List<String> = emptyList(),
) : EventEntry

@EntryListener(PlayerQuitEventEntry::class)
fun onQuit(event: PlayerQuitEvent, query: Query<PlayerQuitEventEntry>) {
    query.find() triggerAllFor event.player
}
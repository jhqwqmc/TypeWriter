package me.gabber235.typewriter.entries.action

import com.github.shynixn.mccoroutine.bukkit.launch
import me.gabber235.typewriter.adapters.Colors
import me.gabber235.typewriter.adapters.Entry
import me.gabber235.typewriter.adapters.modifiers.Help
import me.gabber235.typewriter.adapters.modifiers.WithRotation
import me.gabber235.typewriter.entry.Criteria
import me.gabber235.typewriter.entry.Modifier
import me.gabber235.typewriter.entry.entries.ActionEntry
import me.gabber235.typewriter.plugin
import me.gabber235.typewriter.utils.Icons
import org.bukkit.Location
import org.bukkit.entity.Player

@Entry("teleport", "传送玩家", Colors.RED, Icons.STREET_VIEW)
/**
 * The `Teleport Action` entry is used to teleport a player to a location.
 *
 * ## How could this be used?
 * This could be used to teleport a player to a location when they click a button.
 * Or it could be used for a fast travel system where players talk to an NPC and are teleported to a location.
 */
class TeleportActionEntry(
    override val id: String = "",
    override val name: String = "",
    override val criteria: List<Criteria> = emptyList(),
    override val modifiers: List<Modifier> = emptyList(),
    override val triggers: List<String> = emptyList(),
    @WithRotation
    @Help("将玩家传送到的位置。")
    val location: Location = Location(null, 0.0, 0.0, 0.0),
) : ActionEntry {
    override fun execute(player: Player) {
        super.execute(player)

        plugin.launch {
            player.teleport(location)
        }
    }
}
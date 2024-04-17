package com.caleb.typewriter.superiorskyblock.entries.action

import com.bgsoftware.superiorskyblock.api.SuperiorSkyblockAPI
import me.gabber235.typewriter.adapters.Colors
import me.gabber235.typewriter.adapters.Entry
import me.gabber235.typewriter.adapters.modifiers.Help
import me.gabber235.typewriter.entry.Criteria
import me.gabber235.typewriter.entry.Modifier
import me.gabber235.typewriter.entry.entries.ActionEntry
import me.gabber235.typewriter.utils.Icons
import org.bukkit.entity.Player

@Entry("island_set_member_limit", "设置玩家岛屿的成员限制", Colors.RED, Icons.PEOPLE_GROUP)
/**
 * The `Island Set Member Limit Action` is an action that sets the member limit of an island.
 *
 * ## How could this be used?
 *
 * This could be used as a reward for a quest or as if they reach a certain level.
 *
 */
class IslandSetMemberLimitActionEntry(
    override val id: String = "",
    override val name: String = "",
    override val criteria: List<Criteria> = emptyList(),
    override val modifiers: List<Modifier> = emptyList(),
    override val triggers: List<String> = emptyList(),
    @Help("新的限制将岛屿的成员限制设置为")
    val size: Int = 0
) : ActionEntry {

    override fun execute(player: Player) {
        super.execute(player)

        val sPlayer = SuperiorSkyblockAPI.getPlayer(player)
        val island = sPlayer.island
        island?.teamLimit = size
    }
}
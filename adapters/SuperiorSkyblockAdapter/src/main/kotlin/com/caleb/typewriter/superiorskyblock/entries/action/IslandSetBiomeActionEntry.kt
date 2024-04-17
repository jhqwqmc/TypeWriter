package com.caleb.typewriter.superiorskyblock.entries.action

import com.bgsoftware.superiorskyblock.api.SuperiorSkyblockAPI
import me.gabber235.typewriter.adapters.Colors
import me.gabber235.typewriter.adapters.Entry
import me.gabber235.typewriter.adapters.modifiers.Help
import me.gabber235.typewriter.entry.Criteria
import me.gabber235.typewriter.entry.Modifier
import me.gabber235.typewriter.entry.entries.ActionEntry
import me.gabber235.typewriter.utils.Icons
import org.bukkit.block.Biome
import org.bukkit.entity.Player

@Entry("island_set_biome", "设置玩家岛屿的生物群系", Colors.RED, Icons.EARTH_AMERICAS)
/**
 * The `Island Set Biome` action is used to set a player's island's biome.
 *
 * ## How could this be used?
 *
 * This could be used to simulate the seasons of the year, or to change the biome of the island to match the theme of the island.
 */
class IslandSetBiomeActionEntry(
    override val id: String = "",
    override val name: String = "",
    override val criteria: List<Criteria> = emptyList(),
    override val modifiers: List<Modifier> = emptyList(),
    override val triggers: List<String> = emptyList(),
    @Help("设置岛屿的生物群系")
    val biome: Biome = Biome.PLAINS
) : ActionEntry {

    override fun execute(player: Player) {
        super.execute(player)

        val sPlayer = SuperiorSkyblockAPI.getPlayer(player)
        val island = sPlayer.island
        island?.biome = biome
    }
}
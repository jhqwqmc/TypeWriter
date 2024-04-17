package com.caleb.typewriter.vault.entries.fact

import com.caleb.typewriter.vault.VaultAdapter
import lirand.api.extensions.server.server
import me.gabber235.typewriter.adapters.Colors
import me.gabber235.typewriter.adapters.Entry
import me.gabber235.typewriter.adapters.modifiers.Help
import me.gabber235.typewriter.entry.entries.ReadableFactEntry
import me.gabber235.typewriter.facts.Fact
import me.gabber235.typewriter.utils.Icons
import net.milkbowl.vault.permission.Permission
import java.util.*

@Entry("permission_fact", "如果玩家有权限", Colors.PURPLE, Icons.USER_SHIELD)
/**
 * A [fact](/docs/facts) that checks if the player has a certain permission.
 *

 *
 * ## How could this be used?
 *
 * This fact could be used to check if the player has a certain permission, for example to check if the player is an admin.
 */
class PermissionFactEntry(
    override val id: String = "",
    override val name: String = "",
    override val comment: String = "",
    @Help("要检查的权限")
    val permission: String = ""
) : ReadableFactEntry {
    override fun read(playerId: UUID): Fact {
        val permissionHandler: Permission = VaultAdapter.permissions ?: return Fact(id, 0)
        val player = server.getPlayer(playerId) ?: return Fact(id, 0)
        val value = if (permissionHandler.playerHas(player, permission)) 1 else 0
        return Fact(id, value)
    }
}
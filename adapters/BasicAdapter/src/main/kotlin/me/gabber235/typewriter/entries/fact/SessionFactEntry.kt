package me.gabber235.typewriter.entries.fact

import me.gabber235.typewriter.adapters.Colors
import me.gabber235.typewriter.adapters.Entry
import me.gabber235.typewriter.entry.entries.CachableFactEntry
import me.gabber235.typewriter.utils.Icons

@Entry("session_fact", "保存到玩家退出服务器为止", Colors.PURPLE, Icons.USER_CLOCK)
/**
 * This [fact](/docs/facts) is stored until the player logs out.
 *
 * ## How could this be used?
 *
 * This could be used to slowly add up a player's total time played, and reward them with a badge or other reward when they reach a certain amount of time.
 */
class SessionFactEntry(
    override val id: String = "",
    override val name: String = "",
    override val comment: String = "",
) : CachableFactEntry
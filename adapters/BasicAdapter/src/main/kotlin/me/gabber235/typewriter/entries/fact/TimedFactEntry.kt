package me.gabber235.typewriter.entries.fact

import me.gabber235.typewriter.adapters.Colors
import me.gabber235.typewriter.adapters.Entry
import me.gabber235.typewriter.adapters.modifiers.Help
import me.gabber235.typewriter.entry.entries.ExpirableFactEntry
import me.gabber235.typewriter.entry.entries.PersistableFactEntry
import me.gabber235.typewriter.facts.Fact
import me.gabber235.typewriter.utils.Icons
import java.time.Duration
import java.time.LocalDateTime

@Entry("timed_fact", "保存指定的持续时间，例如 20 分钟", Colors.PURPLE, Icons.STOPWATCH)
/**
 * This fact is stored for a certain amount of time.
 * After that time, it is reset.
 *
 * ## How could this be used?
 *
 * This fact could serve as a timer, and when the fact runs out, it could be used to trigger an action.
 */
class TimedFactEntry(
    override val id: String = "",
    override val name: String = "",
    override val comment: String = "",
    @Help("变量到期后的持续时间。")
    val duration: Duration = Duration.ZERO,
) : ExpirableFactEntry, PersistableFactEntry {
    override fun hasExpired(fact: Fact): Boolean {
        return LocalDateTime.now().isAfter(fact.lastUpdate.plus(duration))
    }
}

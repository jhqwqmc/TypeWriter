package me.gabber235.typewriter.entries.fact

import me.gabber235.typewriter.adapters.Colors
import me.gabber235.typewriter.adapters.Entry
import me.gabber235.typewriter.adapters.modifiers.Help
import me.gabber235.typewriter.entry.entries.ExpirableFactEntry
import me.gabber235.typewriter.entry.entries.PersistableFactEntry
import me.gabber235.typewriter.facts.Fact
import me.gabber235.typewriter.utils.CronExpression
import me.gabber235.typewriter.utils.Icons
import java.time.LocalDateTime

@Entry("cron_fact", "保存到指定日期，例如 (0 0 * * 1)", Colors.PURPLE, Icons.CALENDAR_DAYS)
/**
 * A [fact](/docs/facts) that is saved until a specified date, like (0 0 \* \* 1).
 *
 * ## How could this be used?
 *
 * This fact could be used to create weekly rewards, which are reset every week. Or to simulate the opening hours of a shop.
 */
class CronFactEntry(
    override val id: String = "",
    override val name: String = "",
    override val comment: String = "",
    @Help("变量到期时的计划任务表达式。")
    // The <Link to="https://www.netiq.com/documentation/cloud-manager-2-5/ncm-reference/data/bexyssf.html">Cron Expression</Link> when the fact expires.
    val cron: CronExpression = CronExpression.default()
) : ExpirableFactEntry, PersistableFactEntry {
    override fun hasExpired(fact: Fact): Boolean {
        return cron.nextLocalDateTimeAfter(fact.lastUpdate).isBefore(LocalDateTime.now())
    }
}
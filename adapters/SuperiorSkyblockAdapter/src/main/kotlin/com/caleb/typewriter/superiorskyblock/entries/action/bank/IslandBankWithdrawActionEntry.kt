package com.caleb.typewriter.superiorskyblock.entries.action.bank

import com.bgsoftware.superiorskyblock.api.SuperiorSkyblockAPI
import me.gabber235.typewriter.adapters.Colors
import me.gabber235.typewriter.adapters.Entry
import me.gabber235.typewriter.adapters.modifiers.Help
import me.gabber235.typewriter.entry.Criteria
import me.gabber235.typewriter.entry.Modifier
import me.gabber235.typewriter.entry.entries.ActionEntry
import me.gabber235.typewriter.utils.Icons
import org.bukkit.Bukkit
import org.bukkit.entity.Player
import java.math.BigDecimal

@Entry("island_bank_withdraw", "从玩家的岛屿银行取款", Colors.RED, Icons.PIGGY_BANK)
/**
 * The `Island Bank Withdraw` action allows you to withdraw money from the player's Island bank.
 *
 * ## How could this be used?
 *
 * This could be used to allow players to buy items from a shop.
 */
class IslandBankWithdrawActionEntry(
    override val id: String = "",
    override val name: String = "",
    override val criteria: List<Criteria> = emptyList(),
    override val modifiers: List<Modifier> = emptyList(),
    override val triggers: List<String> = emptyList(),
    @Help("从玩家岛屿银行取款的金额")
    val amount: Double = 0.0
) : ActionEntry {

    override fun execute(player: Player) {
        super.execute(player)

        val amountConverted: BigDecimal = BigDecimal.valueOf(amount)

        val sPlayer = SuperiorSkyblockAPI.getPlayer(player)
        val island = sPlayer.island
        island?.islandBank?.withdrawAdminMoney(Bukkit.getServer().consoleSender, amountConverted)
    }
}
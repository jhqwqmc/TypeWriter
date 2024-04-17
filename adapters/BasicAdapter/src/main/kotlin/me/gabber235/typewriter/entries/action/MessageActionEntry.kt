package me.gabber235.typewriter.entries.action

import me.gabber235.typewriter.adapters.Colors
import me.gabber235.typewriter.adapters.Entry
import me.gabber235.typewriter.adapters.modifiers.EntryIdentifier
import me.gabber235.typewriter.adapters.modifiers.Help
import me.gabber235.typewriter.adapters.modifiers.MultiLine
import me.gabber235.typewriter.entry.Criteria
import me.gabber235.typewriter.entry.Modifier
import me.gabber235.typewriter.entry.Query
import me.gabber235.typewriter.entry.dialogue.playSpeakerSound
import me.gabber235.typewriter.entry.entries.ActionEntry
import me.gabber235.typewriter.entry.entries.SpeakerEntry
import me.gabber235.typewriter.extensions.placeholderapi.parsePlaceholders
import me.gabber235.typewriter.snippets.snippet
import me.gabber235.typewriter.utils.Icons
import me.gabber235.typewriter.utils.sendMiniWithResolvers
import net.kyori.adventure.text.minimessage.tag.resolver.Placeholder
import org.bukkit.entity.Player

val messageFormat: String by snippet(
    "action.message.format",
    "\n<gray> [ <bold><speaker></bold><reset><gray> ]\n<reset><white> <message>\n"
)

@Entry("send_message", "向玩家发送消息", Colors.RED, Icons.MESSAGE)
/**
 * The `Send Message Action` is an action that sends a message to a player.
 * You can specify the speaker, and the message to send.
 *
 * This should not be confused with the (Message Dialogue)[../dialogue/message].
 * (Message Dialogue)[../dialogue/message] will replace the current dialogue with the message, while this action will not.
 *
 * ## How could this be used?
 *
 * This action can be useful in a variety of situations.
 * You can use it to create text effects in response to specific events, such as completing actions or anything else.
 * The possibilities are endless!
 */
class MessageActionEntry(
    override val id: String = "",
    override val name: String = "",
    override val criteria: List<Criteria> = emptyList(),
    override val modifiers: List<Modifier> = emptyList(),
    override val triggers: List<String> = emptyList(),
    @Help("消息的发言者")
    @EntryIdentifier(SpeakerEntry::class)
    val speaker: String = "",
    @Help("要发送的消息")
    @MultiLine
    val message: String = "",
) : ActionEntry {
    override fun execute(player: Player) {
        super.execute(player)

        val speakerEntry = speakerEntry
        player.playSpeakerSound(speakerEntry)
        player.sendMiniWithResolvers(
            messageFormat,
            Placeholder.parsed("speaker", speakerEntry?.displayName ?: ""),
            Placeholder.parsed("message", message.parsePlaceholders(player).replace("\n", "\n "))
        )
    }

    private val speakerEntry: SpeakerEntry?
        get() = Query.findById(speaker)
}
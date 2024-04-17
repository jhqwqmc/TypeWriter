package me.gabber235.typewriter.citizens.entries.artifact

import me.gabber235.typewriter.adapters.Colors
import me.gabber235.typewriter.adapters.Entry
import me.gabber235.typewriter.entry.entries.NpcMovementArtifact
import me.gabber235.typewriter.utils.Icons

@Entry("npc_movement_artifact", "NPC 的移动数据", Colors.PINK, Icons.PERSON_WALKING)
/**
 * The `Npc Movement Artifact` is an artifact that stores the movement data of an NPC.
 * There is no reason to create this on its own.
 * It should always be connected to another entry
 */
class CitizensNpcMovementArtifact(
    override val id: String = "",
    override val name: String = "",
    override val artifactId: String = "",
) : NpcMovementArtifact

package me.gabber235.typewriter.entry.entries

import me.gabber235.typewriter.adapters.Tags
import me.gabber235.typewriter.adapters.modifiers.Help
import me.gabber235.typewriter.adapters.modifiers.MultiLine
import me.gabber235.typewriter.entry.StaticEntry
import me.gabber235.typewriter.facts.Fact
import me.gabber235.typewriter.facts.FactDatabase
import org.koin.java.KoinJavaComponent.get
import java.util.*

@Tags("fact")
interface FactEntry : StaticEntry {
    @MultiLine
    @Help("用于跟踪该变量用途的注释。")
    val comment: String
}

@Tags("readable-fact")
interface ReadableFactEntry : FactEntry {
    fun read(playerId: UUID): Fact
}

@Tags("writable-fact")
interface WritableFactEntry : FactEntry {
    fun write(playerId: UUID, value: Int)
}

@Tags("cachable-fact")
interface CachableFactEntry : ReadableFactEntry, WritableFactEntry {

    override fun read(playerId: UUID): Fact {
        val factDatabase: FactDatabase = get(FactDatabase::class.java)
        return factDatabase.getCachedFact(playerId, id) ?: Fact(id, 0)
    }

    override fun write(playerId: UUID, value: Int) {
        if (!canCache(read(playerId))) return

        val factDatabase: FactDatabase = get(FactDatabase::class.java)
        factDatabase.setCachedFact(playerId, Fact(id, value))
    }

    fun canCache(fact: Fact): Boolean = true
}

@Tags("persistable-fact")
interface PersistableFactEntry : CachableFactEntry {
    fun canPersist(fact: Fact): Boolean = true
}

@Tags("expirable-fact")
interface ExpirableFactEntry : CachableFactEntry {
    fun hasExpired(fact: Fact): Boolean = false
}
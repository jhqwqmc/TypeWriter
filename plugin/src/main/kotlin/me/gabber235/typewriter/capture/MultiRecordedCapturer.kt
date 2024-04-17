package me.gabber235.typewriter.capture

import me.gabber235.typewriter.capture.capturers.Tape
import me.gabber235.typewriter.logger
import org.bukkit.entity.Player
import kotlin.properties.ReadOnlyProperty
import kotlin.reflect.KProperty

open abstract class MultiRecordedCapturer<T>(override val title: String) : RecordedCapturer<T> {
    internal val capturers = mutableListOf<MultiRecorderCapturerDelegate<*>>()

    override fun startRecording(player: Player) {
        capturers.forEach { it.startRecording(player) }
    }

    override fun captureFrame(player: Player, frame: Int) {
        capturers.forEach { it.captureFrame(player, frame) }
    }

    override fun stopRecording(player: Player): T {
        capturers.forEach { it.stopRecording(player) }
        return combineCapturers()
    }

    abstract fun combineCapturers(): T

    open fun <V> capturer(capturer: RecordedCapturer<V>): MultiRecorderCapturerDelegate<V> {
        return MultiRecorderCapturerDelegate(capturer).also { capturers.add(it) }
    }


    open fun <V> capturer(capturer: (String) -> RecordedCapturer<V>): MultiRecorderCapturerDelegate<V> {
        return capturer(capturer(title))
    }
}

abstract class MultiTapeRecordedCapturer<T>(title: String) : MultiRecordedCapturer<Tape<T>>(title) {
    override fun combineCapturers(): Tape<T> {
        val tapes = capturers.map { it.value }.filterIsInstance<Tape<*>>()
        val frames = tapes.flatMap { it.keys }.toSet()
        return frames.associateWith { frame -> combineFrame(frame) }
    }

    abstract fun combineFrame(frame: Int): T

    @Deprecated(
        "无法将此方法与 MultiTapeRecordedCapturer 一起使用",
        level = DeprecationLevel.ERROR,
        replaceWith = ReplaceWith("tapeCapturer(capturer)")
    )
    override fun <V> capturer(capturer: (String) -> RecordedCapturer<V>): MultiRecorderCapturerDelegate<V> =
        throw UnsupportedOperationException("无法将此方法与 MultiTapeRecordedCapturer 一起使用")

    @Deprecated(
        "无法将此方法与 MultiTapeRecordedCapturer 一起使用",
        level = DeprecationLevel.ERROR,
        replaceWith = ReplaceWith("tapeCapturer(capturer)")
    )
    override fun <V> capturer(capturer: RecordedCapturer<V>): MultiRecorderCapturerDelegate<V> =
        throw UnsupportedOperationException("无法将此方法与 MultiTapeRecordedCapturer 一起使用")

    fun <V> tapeCapturer(capturer: RecordedCapturer<Tape<V>>): MultiRecorderCapturerDelegate<Tape<V>> {
        return MultiRecorderCapturerDelegate(capturer).also { capturers.add(it) }
    }

    fun <V> tapeCapturer(capturer: (String) -> RecordedCapturer<Tape<V>>): MultiRecorderCapturerDelegate<Tape<V>> {
        return tapeCapturer(capturer(title))
    }
}

class MultiRecorderCapturerDelegate<T>(private val capturer: RecordedCapturer<T>) :
    ReadOnlyProperty<MultiRecordedCapturer<*>, T> {
    var value: T? = null
        private set

    fun startRecording(player: Player) {
        capturer.startRecording(player)
    }

    fun captureFrame(player: Player, frame: Int) {
        capturer.captureFrame(player, frame)
    }

    fun stopRecording(player: Player) {
        value = capturer.stopRecording(player)
    }

    override operator fun getValue(thisRef: MultiRecordedCapturer<*>, property: KProperty<*>): T {
        if (value == null) {
            logger.severe("捕获者 ${capturer.title} 尚未被记录！")
        }
        return value!!
    }
}
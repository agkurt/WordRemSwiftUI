package app.wordrem.android.voice

import android.annotation.SuppressLint
import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioRecord
import android.media.AudioTrack
import android.media.MediaRecorder
import java.io.ByteArrayOutputStream
import kotlin.concurrent.thread

/** Sunucunun beklediği biçim: 24 kHz, 16 bit, mono PCM (iOS ile aynı) */
const val SAMPLE_RATE = 24_000

/** Bas-konuş kaydı: start() ile başlar, stop() kaydı PCM olarak döndürür */
class PcmRecorder {
    private var record: AudioRecord? = null
    private var worker: Thread? = null
    private val buffer = ByteArrayOutputStream()
    @Volatile private var running = false
    @Volatile var level = 0f
        private set

    @SuppressLint("MissingPermission")   // izin ekranda önceden istenir
    fun start() {
        if (running) return
        val min = AudioRecord.getMinBufferSize(SAMPLE_RATE, AudioFormat.CHANNEL_IN_MONO, AudioFormat.ENCODING_PCM_16BIT)
        fun make(source: Int) = AudioRecord(source, SAMPLE_RATE, AudioFormat.CHANNEL_IN_MONO,
            AudioFormat.ENCODING_PCM_16BIT, maxOf(min, 4800) * 2)
        // Yankı engelleme kaynağı 24 kHz'i desteklemeyen cihazlarda düz mikrofona düş
        var r = make(MediaRecorder.AudioSource.VOICE_COMMUNICATION)
        if (r.state != AudioRecord.STATE_INITIALIZED) { r.release(); r = make(MediaRecorder.AudioSource.MIC) }
        if (r.state != AudioRecord.STATE_INITIALIZED) { r.release(); return }
        record = r
        synchronized(buffer) { buffer.reset() }
        running = true
        r.startRecording()
        worker = thread(name = "pcm-recorder") {
            val chunk = ByteArray(4800)
            while (running) {
                val n = r.read(chunk, 0, chunk.size)
                if (n > 0) {
                    synchronized(buffer) { buffer.write(chunk, 0, n) }
                    var peak = 0
                    for (i in 0 until n - 1 step 2) {
                        val s = (chunk[i].toInt() and 0xFF) or (chunk[i + 1].toInt() shl 8)
                        peak = maxOf(peak, kotlin.math.abs(s.toShort().toInt()))
                    }
                    level = peak / 32768f
                }
            }
        }
    }

    fun stop(): ByteArray {
        running = false
        worker?.join(500)
        record?.run { runCatching { stop() }; release() }
        record = null
        level = 0f
        return synchronized(buffer) { buffer.toByteArray().also { buffer.reset() } }
    }
}

/** Öğretmenin sesi: gelen PCM parçaları sırayla çalınır */
class PcmPlayer {
    private val track: AudioTrack = AudioTrack.Builder()
        .setAudioAttributes(AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_MEDIA)
            .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH).build())
        .setAudioFormat(AudioFormat.Builder()
            .setSampleRate(SAMPLE_RATE)
            .setChannelMask(AudioFormat.CHANNEL_OUT_MONO)
            .setEncoding(AudioFormat.ENCODING_PCM_16BIT).build())
        .setBufferSizeInBytes(SAMPLE_RATE * 2)
        .setTransferMode(AudioTrack.MODE_STREAM)
        .build()
    private val queue = java.util.concurrent.LinkedBlockingQueue<ByteArray>()
    @Volatile private var alive = true
    private val worker = thread(name = "pcm-player") {
        while (alive) {
            val data = runCatching { queue.take() }.getOrNull() ?: continue
            if (data.isEmpty()) continue
            if (track.playState != AudioTrack.PLAYSTATE_PLAYING) track.play()
            track.write(data, 0, data.size)
        }
    }

    fun enqueue(pcm: ByteArray) { queue.offer(pcm) }

    /** Söz kesilince (öğrenci konuşmaya başladı) kuyruk boşaltılır */
    fun flush() {
        queue.clear()
        runCatching { track.pause(); track.flush() }
    }

    val isSpeaking: Boolean get() = queue.isNotEmpty()

    fun release() {
        alive = false
        queue.offer(ByteArray(0))
        worker.interrupt()
        runCatching { track.stop() }
        track.release()
    }
}

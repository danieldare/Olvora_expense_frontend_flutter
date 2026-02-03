package com.example.frontend_flutter_main

import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.media.AudioRecord
import android.media.MediaRecorder
import android.media.audiofx.AcousticEchoCanceler
import android.media.audiofx.AutomaticGainControl
import android.media.audiofx.NoiseSuppressor
import android.os.Build
import android.os.StatFs
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.*
import java.io.File
import java.io.FileOutputStream
import java.io.IOException
import kotlin.math.sqrt

/**
 * World-Class Audio Recording Manager for Voice Input
 * 
 * Features:
 * - Raw PCM audio recording using AudioRecord (NOT SpeechRecognizer)
 * - High-quality audio: 48kHz preferred, 16kHz minimum
 * - PCM 16-bit, Mono channel
 * - Manual start/stop (NO auto-stop on silence)
 * - Real-time audio level streaming for waveform visualization
 * - WAV file output
 * - Audio processing disabled (no noise suppression, echo cancel, AGC)
 * - Audio focus handling
 */
class AudioRecordManager(
    private val activity: FlutterActivity,
    private val methodChannel: MethodChannel,
    private val eventChannel: EventChannel
) {
    companion object {
        private const val TAG = "AudioRecordManager"
        
        // Audio Configuration - World-Class Quality
        private const val PREFERRED_SAMPLE_RATE = 48000 // 48kHz preferred
        private const val MIN_SAMPLE_RATE = 16000 // 16kHz minimum
        private const val CHANNEL_CONFIG = AudioFormat.CHANNEL_IN_MONO
        private const val AUDIO_FORMAT = AudioFormat.ENCODING_PCM_16BIT
        
        // Recording Limits (Cost Protection)
        private const val MIN_RECORDING_DURATION_MS = 500 // Minimum duration to avoid partial speech
        private const val MAX_RECORDING_DURATION_MS = 60000 // 60 seconds max (configurable)
        private const val MIN_SPEECH_ENERGY_THRESHOLD = 0.01 // Minimum RMS threshold (1% of max)
        private const val SILENCE_THRESHOLD = 0.005 // RMS threshold for silence detection (0.5% of max)
        private const val SILENCE_DURATION_MS = 2000 // 2 seconds of silence to consider as silence-only
    }

    private var audioRecord: AudioRecord? = null
    private var audioManager: AudioManager? = null
    private var audioFocusRequest: AudioFocusRequest? = null
    private var recordingJob: Job? = null
    private var eventSink: EventChannel.EventSink? = null
    private var isRecording = false
    private var currentSampleRate = PREFERRED_SAMPLE_RATE
    private var currentOutputFile: File? = null
    private val recordingScope = CoroutineScope(Dispatchers.IO + SupervisorJob())
    private var silenceStartTime: Long = 0
    private var hasDetectedSpeech = false
    private val audioLevels = mutableListOf<Double>() // Track levels for speech energy analysis

    init {
        audioManager = activity.getSystemService(android.content.Context.AUDIO_SERVICE) as AudioManager
    }

    /**
     * Set the event sink for streaming audio levels
     * Called from MainActivity when EventChannel listener is attached
     */
    fun setEventSink(sink: EventChannel.EventSink?) {
        eventSink = sink
        if (sink != null) {
            Log.d(TAG, "Event channel listener attached")
        } else {
            Log.d(TAG, "Event channel listener detached")
        }
    }

    /**
     * Initialize AudioRecord with optimal configuration
     * Tries 48kHz first, falls back to 16kHz if not supported
     */
    private fun initializeAudioRecord(): Boolean {
        // Try preferred sample rate first (48kHz)
        var bufferSize = AudioRecord.getMinBufferSize(
            PREFERRED_SAMPLE_RATE,
            CHANNEL_CONFIG,
            AUDIO_FORMAT
        )

        if (bufferSize == AudioRecord.ERROR_BAD_VALUE || bufferSize == AudioRecord.ERROR) {
            // Fallback to minimum sample rate (16kHz)
            bufferSize = AudioRecord.getMinBufferSize(
                MIN_SAMPLE_RATE,
                CHANNEL_CONFIG,
                AUDIO_FORMAT
            )
            
            if (bufferSize == AudioRecord.ERROR_BAD_VALUE || bufferSize == AudioRecord.ERROR) {
                Log.e(TAG, "Failed to get valid buffer size")
                return false
            }
            
            currentSampleRate = MIN_SAMPLE_RATE
            Log.d(TAG, "Using fallback sample rate: $MIN_SAMPLE_RATE Hz")
        } else {
            currentSampleRate = PREFERRED_SAMPLE_RATE
            Log.d(TAG, "Using preferred sample rate: $PREFERRED_SAMPLE_RATE Hz")
        }

        // Double buffer size for smooth recording
        bufferSize *= 2

        try {
            audioRecord = AudioRecord(
                MediaRecorder.AudioSource.MIC,
                currentSampleRate,
                CHANNEL_CONFIG,
                AUDIO_FORMAT,
                bufferSize
            )

            if (audioRecord?.state != AudioRecord.STATE_INITIALIZED) {
                Log.e(TAG, "AudioRecord initialization failed")
                audioRecord?.release()
                audioRecord = null
                return false
            }

            // CRITICAL: Disable audio processing for clean raw audio
            // This ensures consistent recording quality across all devices
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN) {
                try {
                    // Disable Acoustic Echo Cancellation
                    val aec = AcousticEchoCanceler.create(audioRecord!!.audioSessionId)
                    if (aec != null) {
                        aec.enabled = false
                        Log.d(TAG, "Acoustic Echo Cancellation disabled")
                    }

                    // Disable Automatic Gain Control
                    val agc = AutomaticGainControl.create(audioRecord!!.audioSessionId)
                    if (agc != null) {
                        agc.enabled = false
                        Log.d(TAG, "Automatic Gain Control disabled")
                    }

                    // Disable Noise Suppression
                    val ns = NoiseSuppressor.create(audioRecord!!.audioSessionId)
                    if (ns != null) {
                        ns.enabled = false
                        Log.d(TAG, "Noise Suppression disabled")
                    }
                } catch (e: Exception) {
                    Log.w(TAG, "Could not disable audio processing: ${e.message}")
                    // Continue anyway - not critical
                }
            }

            Log.d(TAG, "AudioRecord initialized successfully: $currentSampleRate Hz, buffer: $bufferSize")
            return true
        } catch (e: Exception) {
            Log.e(TAG, "Error initializing AudioRecord: ${e.message}", e)
            audioRecord?.release()
            audioRecord = null
            return false
        }
    }

    /**
     * Request audio focus for recording
     */
    private fun requestAudioFocus(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val audioAttributes = AudioAttributes.Builder()
                .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
                .setUsage(AudioAttributes.USAGE_VOICE_COMMUNICATION)
                .build()

            val focusChangeListener = AudioManager.OnAudioFocusChangeListener { focusChange: Int ->
                when (focusChange) {
                    AudioManager.AUDIOFOCUS_LOSS_TRANSIENT,
                    AudioManager.AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK -> {
                        Log.d(TAG, "Audio focus lost temporarily")
                        // Continue recording but at lower volume
                    }
                    AudioManager.AUDIOFOCUS_GAIN -> {
                        Log.d(TAG, "Audio focus gained")
                    }
                    AudioManager.AUDIOFOCUS_LOSS -> {
                        Log.d(TAG, "Audio focus lost permanently - stopping recording")
                        // Note: stopRecording() requires a result parameter, but we can't provide it here
                        // Just mark as not recording and stop the audio record
                        isRecording = false
                        try {
                            audioRecord?.stop()
                        } catch (e: Exception) {
                            Log.e(TAG, "Error stopping audio record on focus loss: ${e.message}")
                        }
                    }
                }
            }

            audioFocusRequest = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN_TRANSIENT)
                .setAudioAttributes(audioAttributes)
                .setOnAudioFocusChangeListener(focusChangeListener)
                .build()

            val result = audioManager?.requestAudioFocus(audioFocusRequest!!)
            return result == AudioManager.AUDIOFOCUS_REQUEST_GRANTED
        } else {
            @Suppress("DEPRECATION")
            val result = audioManager?.requestAudioFocus(
                null,
                AudioManager.STREAM_VOICE_CALL,
                AudioManager.AUDIOFOCUS_GAIN_TRANSIENT
            )
            return result == AudioManager.AUDIOFOCUS_REQUEST_GRANTED
        }
    }

    /**
     * Release audio focus
     */
    private fun releaseAudioFocus() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            audioFocusRequest?.let {
                audioManager?.abandonAudioFocusRequest(it)
                audioFocusRequest = null
            }
        } else {
            @Suppress("DEPRECATION")
            audioManager?.abandonAudioFocus(null)
        }
    }

    /**
     * Start recording audio
     * Manual start - NO auto-stop on silence
     */
    fun startRecording(outputFilePath: String, result: MethodChannel.Result) {
        if (isRecording) {
            result.error("ALREADY_RECORDING", "Recording is already in progress", null)
            return
        }

        // CRITICAL: Check available storage space before recording
        val outputFile = File(outputFilePath)
        outputFile.parentFile?.let { parentDir ->
            try {
                val stat = StatFs(parentDir.absolutePath)
                val availableBytes = stat.availableBytes

                // Estimate: 48kHz * 16-bit * 1 channel = 96,000 bytes/sec
                // For 60 seconds max: ~5.76 MB
                // We check for 2x buffer (12 MB) to be safe
                val requiredBytes = 12L * 1024 * 1024 // 12 MB

                if (availableBytes < requiredBytes) {
                    result.error(
                        "LOW_STORAGE",
                        "Not enough storage space. Please free up at least 12 MB.",
                        null
                    )
                    Log.e(TAG, "Insufficient storage: ${availableBytes / (1024 * 1024)} MB available")
                    return
                }

                Log.d(TAG, "Storage check passed: ${availableBytes / (1024 * 1024)} MB available")
            } catch (e: Exception) {
                Log.w(TAG, "Could not check storage space: ${e.message}")
                // Continue anyway - better to try than fail immediately
            }
        }

        if (!initializeAudioRecord()) {
            result.error("INIT_FAILED", "Failed to initialize AudioRecord", null)
            return
        }

        if (!requestAudioFocus()) {
            result.error("AUDIO_FOCUS_FAILED", "Failed to request audio focus", null)
            audioRecord?.release()
            audioRecord = null
            return
        }

        // outputFile already created during storage check above
        outputFile.parentFile?.mkdirs()

        currentOutputFile = outputFile
        isRecording = true

        // Start recording in coroutine
        recordingJob = recordingScope.launch {
            try {
                audioRecord?.startRecording()
                Log.d(TAG, "Recording started: $outputFilePath")

                // Notify Flutter
                withContext(Dispatchers.Main) {
                    result.success(mapOf(
                        "success" to true,
                        "sampleRate" to currentSampleRate,
                        "filePath" to outputFilePath
                    ))
                }

                // Record audio and stream levels
                recordAudio(outputFile)

            } catch (e: Exception) {
                Log.e(TAG, "Error during recording: ${e.message}", e)
                isRecording = false
                withContext(Dispatchers.Main) {
                    result.error("RECORDING_ERROR", "Error during recording: ${e.message}", null)
                }
            }
        }
    }

    /**
     * Record audio data and stream audio levels
     */
    private suspend fun recordAudio(outputFile: File) {
        val audioRecord = this.audioRecord ?: return
        val bufferSize = AudioRecord.getMinBufferSize(
            currentSampleRate,
            CHANNEL_CONFIG,
            AUDIO_FORMAT
        )
        val buffer = ShortArray(bufferSize)
        val pcmData = mutableListOf<ByteArray>()
        val startTime = System.currentTimeMillis()
        var lastSpeechTime = startTime
        silenceStartTime = 0
        hasDetectedSpeech = false
        audioLevels.clear()

        try {
            val fileOutputStream = FileOutputStream(outputFile)
            
            // Write WAV header placeholder (will be updated later)
            val headerSize = 44
            fileOutputStream.write(ByteArray(headerSize))

            while (isRecording) {
                val currentTime = System.currentTimeMillis()
                val elapsed = currentTime - startTime

                // Enforce max duration (30 seconds)
                if (elapsed >= MAX_RECORDING_DURATION_MS) {
                    Log.d(TAG, "Max recording duration reached: ${elapsed}ms")
                    isRecording = false
                    break
                }

                val samplesRead = audioRecord.read(buffer, 0, buffer.size)

                if (samplesRead > 0) {
                    // Calculate and stream audio level (RMS)
                    val rms = calculateRMS(buffer, samplesRead)
                    val normalizedLevel = rms / 32768.0 // Normalize to 0.0-1.0
                    audioLevels.add(normalizedLevel)

                    // Detect speech (above minimum energy threshold)
                    if (normalizedLevel >= MIN_SPEECH_ENERGY_THRESHOLD) {
                        hasDetectedSpeech = true
                        lastSpeechTime = currentTime
                        silenceStartTime = 0
                    } else if (normalizedLevel < SILENCE_THRESHOLD) {
                        // Detect silence
                        if (silenceStartTime == 0L) {
                            silenceStartTime = currentTime
                        } else {
                            val silenceDuration = currentTime - silenceStartTime
                            // If we've had speech before and now have long silence, continue recording
                            // (user might be pausing, not finished)
                        }
                    } else {
                        // Between thresholds - reset silence counter
                        silenceStartTime = 0
                    }

                    // Convert shorts to bytes (little-endian)
                    val byteArray = ByteArray(samplesRead * 2)
                    for (i in 0 until samplesRead) {
                        val sample = buffer[i]
                        byteArray[i * 2] = (sample.toInt() and 0xFF).toByte()
                        byteArray[i * 2 + 1] = ((sample.toInt() shr 8) and 0xFF).toByte()
                    }

                    // Write to file
                    fileOutputStream.write(byteArray)
                    pcmData.add(byteArray)

                    // Stream audio level to Flutter
                    withContext(Dispatchers.Main) {
                        eventSink?.success(mapOf(
                            "type" to "audioLevel",
                            "level" to normalizedLevel,
                            "raw" to rms
                        ))
                    }
                } else if (samplesRead == AudioRecord.ERROR_INVALID_OPERATION) {
                    Log.e(TAG, "Invalid operation during recording")
                    break
                } else if (samplesRead == AudioRecord.ERROR_BAD_VALUE) {
                    Log.e(TAG, "Bad value during recording")
                    break
                }
            }

            fileOutputStream.close()

            // Update WAV header with actual data size
            val dataSize = pcmData.sumOf { it.size.toLong() }.toInt()
            val duration = System.currentTimeMillis() - startTime

            // Validate recording quality
            if (duration < MIN_RECORDING_DURATION_MS) {
                Log.w(TAG, "Recording too short: ${duration}ms")
                outputFile.delete()
                withContext(Dispatchers.Main) {
                    eventSink?.success(mapOf(
                        "type" to "recordingComplete",
                        "success" to false,
                        "error" to "Recording too short"
                    ))
                }
                return
            }

            // Reject silence-only recordings
            if (!hasDetectedSpeech) {
                Log.w(TAG, "Recording rejected: No speech detected (silence-only)")
                outputFile.delete()
                withContext(Dispatchers.Main) {
                    eventSink?.success(mapOf(
                        "type" to "recordingComplete",
                        "success" to false,
                        "error" to "No speech detected"
                    ))
                }
                return
            }

            // Calculate average speech energy
            val avgEnergy = if (audioLevels.isNotEmpty()) {
                audioLevels.average()
            } else {
                0.0
            }

            // Check if average energy is too low (likely silence-only)
            if (avgEnergy < MIN_SPEECH_ENERGY_THRESHOLD) {
                Log.w(TAG, "Recording rejected: Average energy too low: $avgEnergy")
                outputFile.delete()
                withContext(Dispatchers.Main) {
                    eventSink?.success(mapOf(
                        "type" to "recordingComplete",
                        "success" to false,
                        "error" to "No speech detected"
                    ))
                }
                return
            }

            // Note: Silence trimming is handled on backend during STT processing
            // We validate here to reject silence-only recordings

            // Write proper WAV header
            writeWavHeader(outputFile, dataSize, currentSampleRate)

            Log.d(TAG, "Recording completed: ${outputFile.absolutePath}, duration: ${duration}ms, size: $dataSize bytes")

            // Notify Flutter
            withContext(Dispatchers.Main) {
                eventSink?.success(mapOf(
                    "type" to "recordingComplete",
                    "success" to true,
                    "filePath" to outputFile.absolutePath,
                    "duration" to duration,
                    "sampleRate" to currentSampleRate,
                    "dataSize" to dataSize
                ))
            }

        } catch (e: IOException) {
            Log.e(TAG, "IO error during recording: ${e.message}", e)
            outputFile.delete()
            withContext(Dispatchers.Main) {
                eventSink?.success(mapOf(
                    "type" to "recordingComplete",
                    "success" to false,
                    "error" to "IO error: ${e.message}"
                ))
            }
        } finally {
            isRecording = false
            audioRecord.stop()
            releaseAudioFocus()
        }
    }

    /**
     * Stop recording manually
     */
    fun stopRecording(result: MethodChannel.Result) {
        if (!isRecording) {
            result.error("NOT_RECORDING", "No recording in progress", null)
            return
        }

        isRecording = false
        result.success(true)
        Log.d(TAG, "Stop recording requested")
    }

    /**
     * Calculate RMS (Root Mean Square) for audio level
     */
    private fun calculateRMS(buffer: ShortArray, length: Int): Double {
        var sum = 0.0
        for (i in 0 until length) {
            val sample = buffer[i].toDouble()
            sum += sample * sample
        }
        return sqrt(sum / length)
    }

    /**
     * Write WAV file header
     */
    private fun writeWavHeader(file: File, dataSize: Int, sampleRate: Int) {
        val header = ByteArray(44)
        var offset = 0

        // RIFF header
        "RIFF".toByteArray().copyInto(header, offset)
        offset += 4
        (36 + dataSize).toInt().toLittleEndianBytes().copyInto(header, offset, 0, 4)
        offset += 4
        "WAVE".toByteArray().copyInto(header, offset)
        offset += 4

        // fmt chunk
        "fmt ".toByteArray().copyInto(header, offset)
        offset += 4
        16.toLittleEndianBytes().copyInto(header, offset, 0, 4) // fmt chunk size
        offset += 4
        1.toShort().toLittleEndianBytes().copyInto(header, offset, 0, 2) // audio format (PCM)
        offset += 2
        1.toShort().toLittleEndianBytes().copyInto(header, offset, 0, 2) // channels (mono)
        offset += 2
        sampleRate.toLittleEndianBytes().copyInto(header, offset, 0, 4)
        offset += 4
        (sampleRate * 2).toLittleEndianBytes().copyInto(header, offset, 0, 4) // byte rate
        offset += 4
        2.toShort().toLittleEndianBytes().copyInto(header, offset, 0, 2) // block align
        offset += 2
        16.toShort().toLittleEndianBytes().copyInto(header, offset, 0, 2) // bits per sample
        offset += 2

        // data chunk
        "data".toByteArray().copyInto(header, offset)
        offset += 4
        dataSize.toLittleEndianBytes().copyInto(header, offset, 0, 4)

        // Write header to file
        val fileOutputStream = FileOutputStream(file)
        fileOutputStream.write(header)
        fileOutputStream.close()
    }

    /**
     * Cleanup resources
     */
    fun dispose() {
        isRecording = false
        recordingJob?.cancel()
        audioRecord?.stop()
        audioRecord?.release()
        audioRecord = null
        releaseAudioFocus()
        recordingScope.cancel()
    }
}

// Extension functions for byte conversion
private fun Int.toLittleEndianBytes(): ByteArray {
    return byteArrayOf(
        (this and 0xFF).toByte(),
        ((this shr 8) and 0xFF).toByte(),
        ((this shr 16) and 0xFF).toByte(),
        ((this shr 24) and 0xFF).toByte()
    )
}

private fun Short.toLittleEndianBytes(): ByteArray {
    return byteArrayOf(
        (this.toInt() and 0xFF).toByte(),
        ((this.toInt() shr 8) and 0xFF).toByte()
    )
}

package com.careerlabs.voice;

/*
 * Integration contract for the production Godot Android plugin.
 * Implement with Android SpeechRecognizer and expose start/stop callbacks
 * to Godot. This source is intentionally dependency-free.
 */
public final class VoiceBridge {
    public interface Listener {
        void onPartialText(String text);
        void onFinalText(String text);
        void onError(String message);
    }

    private final Listener listener;

    public VoiceBridge(Listener listener) {
        this.listener = listener;
    }

    public void start() {
        // Production implementation:
        // SpeechRecognizer + RecognitionListener + RECORD_AUDIO permission.
    }

    public void stop() {
        // Stop/cancel recognition.
    }
}

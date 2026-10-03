# Android Voice-to-Text bridge

The Godot UI already exposes a voice-answer action. For a production APK, connect it to Android's SpeechRecognizer through a Godot Android plugin.

Required Android permission:
- android.permission.RECORD_AUDIO

Recommended flow:
1. User taps "ANSWER BY VOICE".
2. Android SpeechRecognizer requests microphone permission.
3. Speech recognition runs asynchronously.
4. Recognized text is returned to the Godot script.
5. The text is inserted into the current TextEdit.
6. User can edit the transcription before submission.
7. Only the final answer is sent to the backend.

Privacy:
- Show a clear microphone permission explanation.
- Do not record/store raw audio unless the user explicitly chooses it.
- Prefer transient speech-to-text.
- Provide a visible recording/listening state.
- Provide a stop/cancel action.

The included Java folder is an integration placeholder; use a Godot-compatible Android plugin project during the final Android export rather than embedding provider secrets in the APK.

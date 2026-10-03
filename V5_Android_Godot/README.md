# ServiceNow Career Lab V2

A mobile-first ServiceNow learning game.

## Core loop
Learn -> Play -> Explain -> Interview -> Improve -> Level Up

## Important fixes in V2
- Responsive width recalculated on every viewport resize.
- Scroll content uses the real available viewport width.
- No fixed 1000px content inside a narrow phone container.
- Bottom navigation is fixed.
- Cards expand horizontally.
- Voice-answer controls are included in question/interview flows.
- Lightweight 2D visual treatment.
- Correct color constants; no undefined ORANGE parser error.

## Import
Godot 4 -> Import -> select this ZIP -> open the project -> Run.

## Voice
The UI is ready for an Android SpeechRecognizer bridge. See:
android_plugin/README/VOICE_BRIDGE.md

The Java file is an integration contract, not a claim that native speech recognition is already wired into the exported APK.

## Copyright
Starter content is independently authored. Do not copy proprietary ServiceNow documentation, screenshots, training content or third-party question banks.

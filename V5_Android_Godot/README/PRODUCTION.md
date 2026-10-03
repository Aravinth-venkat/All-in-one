# Production roadmap

## 1. Client
Godot 4 Android, responsive Control UI, lightweight 2D decoration.

## 2. Voice
Android SpeechRecognizer -> text -> Godot TextEdit.
The user can edit the transcription before submitting.

## 3. Backend
HTTPS API -> authentication -> content API -> progress database -> AI evaluation service.

## 4. Resume
Pick PDF/DOCX -> secure upload -> parse -> section extraction -> deterministic checks -> AI suggestions -> user approval -> interview question generation.

## 5. Learning engine
Each topic has:
Concept -> example -> interactive question -> free-text answer -> feedback -> interview question -> XP.

## 6. Engagement without dark patterns
Use optional streaks, quests, XP, unlockable lessons, progress maps and meaningful feedback. Do not use deceptive purchases, infinite notification spam, or manipulative pressure.

## 7. Security
- No API keys in APK.
- HTTPS only.
- Auth tokens stored securely.
- Server-side authorization.
- File type/size validation.
- Malware scanning before parsing.
- Encryption in transit and at rest.
- Resume/interview deletion controls.
- Rate limits.
- Crash reporting.
- Automated tests.

## 8. Play Store quality
Before production:
- Android permission review.
- Accessibility testing.
- Multiple aspect ratios and font scales.
- Low-memory device testing.
- Offline/error states.
- Signed AAB.
- Internal -> closed -> production testing tracks.
- Privacy policy and data safety disclosures.

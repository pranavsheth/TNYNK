# Chapter 3.2 Teacher Guide: One-Minute Story

Mini-project file: `book2_ch3_mini_one_minute_story.sb3`

## Lesson goal (30-40 min)
Students structure a short story with scene flow, dialogue timing, sprite movement, and sound.

## What to demo first (10 min)
1. Run full story once without interruption.
2. Replay and pause after each scene transition.
3. Show sequence blocks in order:
   - say for seconds
   - broadcast next scene
   - wait
4. Show responder sprite script for scene receive.
5. Modify one timing value live (say duration or wait) and test clarity.

## Common student errors and quick fixes
- Error: Dialogue overlaps.
  - Quick fix: Use say for seconds and add short waits between speakers.
- Error: Scene 2 never starts.
  - Quick fix: Check broadcast message spelling matches receiver exactly.
- Error: Sound plays at wrong moment.
  - Quick fix: Use play sound until done for controlled timing.
- Error: Story feels confusing.
  - Quick fix: Keep one clear event per scene and one transition message.

## Fast teacher troubleshooting checklist
1. Does every scene end with one clear trigger?
2. Do all receiver scripts use exact message names?
3. Are waits placed between major actions?
4. Are opening and ending lines clearly visible/audible?

## Extension challenge (for fast finishers)
- Add a third sprite reaction in scene 2.
- Add one alternate ending triggered by key press.

## Exit ticket (2 min)
Ask each student:
- Which block controlled story clarity the most: wait, say duration, or broadcast?

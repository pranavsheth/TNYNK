# Chapter 4.2 Teacher Guide: Final Showreel

Mini-project file: `book2_ch4_mini_final_showreel.sb3`

## Lesson goal (40 min)
Students combine all Level 2 concepts in one polished project: animation, custom blocks, sound/story flow, and broadcasts.

## What to demo first (12 min)
1. Run the full showreel and ask students to identify all four concepts.
2. Open controller script and show message chain:
   - intro_done -> demo_start -> show_end
3. Open performer script and show where each message is received.
4. Show custom jump block call and definition.
5. Change one part live:
   - jump height
   - animation repeat count
   - one broadcast message name (then fix receiver too)

## Common student errors and quick fixes
- Error: Project breaks after renaming a message.
  - Quick fix: Update both broadcast and all receivers to the same exact name.
- Error: Custom block works in one place but not another.
  - Quick fix: Verify procedure call input and definition reporter match.
- Error: Too many actions happen together.
  - Quick fix: Insert waits between broadcasts and major actions.
- Error: Final ending never appears.
  - Quick fix: Confirm show_end is broadcast and receiver script exists.

## Fast teacher troubleshooting checklist
1. Are there at least 3 broadcast messages used correctly?
2. Is at least one custom block with input defined and called?
3. Is animation visibly using costumes and timing blocks?
4. Is there at least one sound integrated with scene flow?

## Extension challenge (for fast finishers)
- Add a score or applause meter shown at the end.
- Add a student voice-over line before final ending.

## Exit ticket (3 min)
Ask each student to name:
- One bug they fixed today.
- Which of the four concepts they used best.

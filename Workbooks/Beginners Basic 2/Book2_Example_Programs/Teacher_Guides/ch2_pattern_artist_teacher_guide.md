# Chapter 2.2 Teacher Guide: Pattern Artist

Mini-project file: `book2_ch2_mini_pattern_artist.sb3`

## Lesson goal (30-40 min)
Students use custom blocks with inputs to create reusable drawing logic and generate geometric patterns.

## What to demo first (10 min)
1. Run once and ask students to identify repeated behavior.
2. Show custom block definitions:
   - drawLine(len)
   - turnAngle(deg)
3. Show where each block is called in repeat.
4. Change one input live:
   - turnAngle 60 to 45 (pattern changes immediately)
5. Run again and compare shapes.

## Common student errors and quick fixes
- Error: Nothing is drawn.
  - Quick fix: Check pen down is present before the drawing loop.
- Error: Random lines appear across stage.
  - Quick fix: Use clear at start and reset sprite position before pen down.
- Error: Custom block input has no effect.
  - Quick fix: Confirm argument reporter is used inside the definition, not hardcoded values.
- Error: Script is too long and hard to debug.
  - Quick fix: Move repeated logic into custom blocks and test each block separately.

## Fast teacher troubleshooting checklist
1. Is pen extension enabled?
2. Is pen clear at start?
3. Is pen down before repeat?
4. Do custom blocks include and use their input parameters?

## Extension challenge (for fast finishers)
- Create 3 pattern presets with different angle and length values.
- Add key controls to switch pattern style.

## Exit ticket (2 min)
Ask each student to explain:
- Why custom blocks are better than copying 20 blocks multiple times.

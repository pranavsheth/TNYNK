# Chapter 1.2 Teacher Guide: Dance Loop

Mini-project file: `book2_ch1_mini_dance_loop.sb3`

## Lesson goal (30-40 min)
Students build a dance animation using sequence, loop, costume switch, and timing control.

## What to demo first (10 min)
1. Run the project once and ask: What repeated pattern do you see?
2. Open the main script and point to the block order: repeat -> turn -> move -> next costume -> wait.
3. Change one value live:
   - wait 0.2 to 0.1 (faster)
   - move 15 to 30 (bigger jumps)
4. Re-run and compare smoothness vs speed.

## Common student errors and quick fixes
- Error: Sprite moves too fast and looks jerky.
  - Quick fix: Reduce move steps and reduce wait together in small increments.
- Error: Animation runs only once and stops too early.
  - Quick fix: Increase repeat count or use forever for continuous dance.
- Error: Costume does not change.
  - Quick fix: Confirm at least 2 costumes exist and next costume is inside the loop.
- Error: Sprite drifts out of stage.
  - Quick fix: Add if on edge, bounce or reduce movement values.

## Fast teacher troubleshooting checklist
1. Is when green flag clicked the top block?
2. Is repeat wrapping all action blocks?
3. Is wait inside the loop?
4. Are there at least two costumes?

## Extension challenge (for fast finishers)
- Add a second dance style triggered by key press.
- Add music and synchronize one dance move to each beat.

## Exit ticket (2 min)
Ask each student to answer:
- Which single block change made the biggest visual difference?
- Why?

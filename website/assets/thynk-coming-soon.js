const scene = document.querySelector(".scene");
const stage = document.querySelector(".stage");

if (scene && stage && !window.matchMedia("(prefers-reduced-motion: reduce)").matches) {
  const isSmallScreen = window.matchMedia("(max-width: 768px)").matches;
  const defaultRx = isSmallScreen ? 6 : 9;
  const defaultRy = isSmallScreen ? -6 : -10;
  const maxTilt = isSmallScreen ? 3 : 8;

  let targetRx = defaultRx;
  let targetRy = defaultRy;
  let currentRx = defaultRx;
  let currentRy = defaultRy;

  function animateTilt() {
    currentRx += (targetRx - currentRx) * 0.12;
    currentRy += (targetRy - currentRy) * 0.12;

    stage.style.setProperty("--rx", `${currentRx.toFixed(2)}deg`);
    stage.style.setProperty("--ry", `${currentRy.toFixed(2)}deg`);

    requestAnimationFrame(animateTilt);
  }

  requestAnimationFrame(animateTilt);

  scene.addEventListener("pointermove", (event) => {
    const rect = scene.getBoundingClientRect();
    const x = (event.clientX - rect.left) / rect.width;
    const y = (event.clientY - rect.top) / rect.height;

    targetRx = defaultRx + (0.5 - y) * maxTilt;
    targetRy = defaultRy + (x - 0.5) * maxTilt;
  });

  scene.addEventListener("pointerleave", () => {
    targetRx = defaultRx;
    targetRy = defaultRy;
  });
}

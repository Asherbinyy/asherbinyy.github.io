/**
 * Mounts the threshold over the page, and takes it down again.
 *
 * Everything here is about not being in the way. Flutter starts loading at the
 * same moment the scene does, so the intro costs no waiting; the overlay is
 * removed on any failure rather than trapping a visitor in front of a broken
 * canvas; and the whole thing is skippable from the first frame by keyboard,
 * pointer or touch.
 */
const HOST_ID = 'threshold';

function tearDown(host, scene) {
  if (scene) scene.dispose();
  host.classList.add('threshold--gone');
  // Removed after the fade rather than during it, so the app is never
  // composited under a half-transparent canvas.
  window.setTimeout(() => host.remove(), 700);
  document.documentElement.classList.remove('threshold-locked');
}

export async function mountThreshold() {
  const host = document.getElementById(HOST_ID);
  if (!host) return;

  let Threshold;
  try {
    ({ Threshold } = await import('./intro.js'));
  } catch (_) {
    // No module support, a blocked request, anything: the site is the point.
    tearDown(host, null);
    return;
  }

  if (!Threshold.shouldPlay()) {
    tearDown(host, null);
    return;
  }

  let scene;
  try {
    scene = new Threshold(host);
    scene.build();
  } catch (_) {
    // A machine with no working WebGL context gets the site directly.
    tearDown(host, scene);
    return;
  }

  Threshold.markPlayed();
  document.documentElement.classList.add('threshold-locked');
  host.classList.add('threshold--ready');

  let finished = false;
  const finish = () => {
    if (finished) return;
    finished = true;
    tearDown(host, scene);
  };
  scene.onFinished = finish;

  const enter = () => scene.open();
  const skip = () => finish();

  host.querySelector('.threshold__enter')?.addEventListener('click', enter);
  host.querySelector('.threshold__skip')?.addEventListener('click', skip);
  // Any key that is not an obvious skip opens the door, so a visitor who
  // presses something reasonable gets the sequence rather than nothing.
  window.addEventListener('keydown', (event) => {
    if (finished) return;
    if (event.key === 'Escape') return skip();
    if (event.key === 'Enter' || event.key === ' ') {
      event.preventDefault();
      enter();
    }
  });

  const resize = () => scene.resize();
  window.addEventListener('resize', resize);

  let raf = 0;
  const loop = () => {
    if (finished) {
      window.removeEventListener('resize', resize);
      return;
    }
    scene.frame();
    raf = window.requestAnimationFrame(loop);
  };
  raf = window.requestAnimationFrame(loop);

  // A hard ceiling. If anything stalls, the visitor still reaches the site.
  window.setTimeout(() => {
    if (!finished) finish();
    window.cancelAnimationFrame(raf);
  }, 22000);
}

mountThreshold();

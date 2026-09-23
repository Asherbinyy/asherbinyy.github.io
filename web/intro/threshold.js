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
  if (new URLSearchParams(location.search).get('preview') === '1') {
    host.remove();
    return;
  }

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

  // The door opens when it is asked to. The owner wanted the button back:
  // a sealed door with no handle is a wait, and a visitor who has seen the
  // scene once wants past it.
  const openDoor = () => {
    if (finished) return;
    host.classList.add('threshold--opening');
    scene.open();
  };

  // The whole panel is the control. The owner asked for the button to go, and
  // a door that opens to a click anywhere on it needs no handle drawn on it.
  host.addEventListener('click', openDoor);
  host.addEventListener('keydown', (event) => {
    // Any key, not just the two a button would answer to: there is nothing
    // else on screen to type at, and a visitor pressing a key here means
    // "get on with it" whichever key it is.
    if (event.key !== 'Tab') openDoor();
  });
  // Focused as soon as the scene is up, so a keyboard opens the door without
  // hunting for anything.
  window.setTimeout(() => host.focus({preventScroll: true}), 600);

  // It still opens on its own, for somebody who does nothing. Long enough to
  // read the button, short enough not to be a wait.
  window.setTimeout(openDoor, 4200);

  // Escape still works, deliberately without being advertised. Trapping
  // someone in a non-dismissible overlay is an accessibility failure however
  // short it is, and anyone who wants out already tries this key.
  window.addEventListener('keydown', (event) => {
    if (!finished && event.key === 'Escape') finish();
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

/**
 * The threshold: a buried temple in the Sahara, and the way in.
 *
 * Runs before Flutter boots, in the page shell, because that is the one place
 * on this site where real 3D is possible. The app itself renders to a single
 * canvas and cannot host a WebGL scene; the shell can, and the moment before
 * the app mounts is exactly when a first impression is made.
 *
 * Three.js is vendored under web/vendor rather than pulled from a CDN. This
 * site's argument is that it makes no third-party request, and a 300KB script
 * fetched from someone else's server on first paint would be the largest
 * exception to that anywhere in the codebase.
 *
 * It runs once per tab, never for a viewer who asked for reduced motion, never
 * on a device too small or too weak to carry it, and never at the cost of the
 * app: Flutter loads in parallel and the intro hands over the moment both are
 * ready. Anything that goes wrong here removes the whole overlay rather than
 * stranding a visitor in front of a broken scene.
 */
import * as THREE from '../vendor/three.module.min.js';

const PALETTE = {
  night: 0x0b1018,
  sand: 0x3d3524,
  sandLit: 0x8a7248,
  stone: 0x333c4e,
  gold: 0xe3a93f,
  glow: 0xffd98a,
};

/** Reads the run once, so a reload replays it but a route change does not. */
const PLAYED_KEY = 'kemet.threshold.played';

export class Threshold {
  constructor(host) {
    this.host = host;
    this.clock = new THREE.Clock();
    this.state = 'waiting';
    this.openedAt = 0;
    this.shake = 0;
    this.disposed = false;
    this.onFinished = () => {};
  }

  /** Whether the scene should run at all. */
  static shouldPlay() {
    try {
      if (window.matchMedia('(prefers-reduced-motion: reduce)').matches) {
        return false;
      }
      if (sessionStorage.getItem(PLAYED_KEY) === '1') return false;
    } catch (_) {
      // A browser refusing storage is not a reason to refuse the site.
    }
    // A phone can run this, but a very small viewport cannot compose it: the
    // doorway, both guards and the horizon do not fit, and a cramped version
    // reads worse than none.
    if (Math.min(window.innerWidth, window.innerHeight) < 380) return false;
    return true;
  }

  static markPlayed() {
    try {
      sessionStorage.setItem(PLAYED_KEY, '1');
    } catch (_) {
      /* storage refused; the intro simply replays next time */
    }
  }

  build() {
    const width = this.host.clientWidth;
    const height = this.host.clientHeight;

    this.renderer = new THREE.WebGLRenderer({
      antialias: window.devicePixelRatio < 2,
      powerPreference: 'high-performance',
    });
    // Capped rather than matched: a 3x display would otherwise render nine
    // times the pixels for a scene that is mostly silhouette and dust.
    this.renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
    this.renderer.setSize(width, height);
    this.renderer.setClearColor(PALETTE.night, 1);
    this.host.appendChild(this.renderer.domElement);

    this.scene = new THREE.Scene();
    this.scene.fog = new THREE.FogExp2(PALETTE.night, 0.018);

    this.camera = new THREE.PerspectiveCamera(52, width / height, 0.1, 200);
    this.camera.position.set(0, 3.4, 16);
    this.camera.lookAt(0, 4, 0);

    this.rig = new THREE.Group();
    this.scene.add(this.rig);

    this.#lights();
    this.#ground();
    this.#facade();
    this.#guards();
    this.#dust();
    this.#stars();
  }

  #lights() {
    // Bright enough to read the architecture, dark enough to still be night.
    // The first pass was lit for a scene nobody could see.
    this.scene.add(new THREE.AmbientLight(0x46566e, 2.6));

    const moon = new THREE.DirectionalLight(0xc8dcf0, 2.2);
    moon.position.set(-9, 12, 7);
    this.scene.add(moon);

    // A low warm bounce off the sand, which is what stops the stone reading
    // as flat grey cardboard.
    const bounce = new THREE.DirectionalLight(0xa07d46, 0.8);
    bounce.position.set(4, -2, 8);
    this.scene.add(bounce);

    // The light behind the door. Off until the seal breaks, and the whole
    // sequence is about it arriving.
    this.inner = new THREE.PointLight(PALETTE.glow, 0, 30, 2);
    this.inner.position.set(0, 2.6, -3.4);
    this.scene.add(this.inner);
  }

  #ground() {
    const geometry = new THREE.PlaneGeometry(120, 120, 90, 90);
    const position = geometry.attributes.position;
    // Dunes, from two offset sine ridges rather than noise: cheaper, and a
    // desert at night reads by its silhouette, not its detail.
    for (let i = 0; i < position.count; i += 1) {
      const x = position.getX(i);
      const y = position.getY(i);
      const dune =
        Math.sin(x * 0.12) * 0.9 +
        Math.sin(y * 0.09 + 1.3) * 0.7 +
        Math.sin((x + y) * 0.05) * 0.5;
      // Flattened near the doorway so the approach is walkable ground.
      const flatten = Math.min(1, Math.hypot(x, y + 4) / 12);
      position.setZ(i, dune * flatten);
    }
    geometry.computeVertexNormals();

    const sand = new THREE.Mesh(
      geometry,
      new THREE.MeshStandardMaterial({
        color: PALETTE.sand,
        roughness: 1,
        metalness: 0,
      }),
    );
    sand.rotation.x = -Math.PI / 2;
    sand.position.y = -0.2;
    this.rig.add(sand);
  }

  #facade() {
    const stone = new THREE.MeshStandardMaterial({
      color: PALETTE.stone,
      roughness: 0.95,
      metalness: 0.02,
    });

    // Two battered towers with a gap between them, which is what a pylon is.
    // The first pass built one solid slab and put the doorway behind it, so
    // the entrance was hidden by the entrance.
    const gap = 3.8;
    const towerWidth = 4.4;
    for (const side of [-1, 1]) {
      // Tapered: Egyptian walls lean inward, and the batter is most of why a
      // box reads as a pylon rather than as a box.
      const tower = new THREE.Mesh(
        new THREE.CylinderGeometry(towerWidth * 0.42, towerWidth * 0.5, 9, 4, 1),
        stone,
      );
      tower.rotation.y = Math.PI / 4;
      tower.position.set(side * (gap / 2 + towerWidth / 2), 4.5, -3.2);
      tower.scale.set(1, 1, 0.5);
      this.rig.add(tower);

      // A cavetto cornice: the flared lip along the top of every pylon.
      const cornice = new THREE.Mesh(
        new THREE.BoxGeometry(towerWidth + 0.5, 0.5, 2.6),
        stone,
      );
      cornice.position.set(side * (gap / 2 + towerWidth / 2), 9.1, -3.2);
      this.rig.add(cornice);

      // The jamb facing the gap, so the opening has thickness.
      const jamb = new THREE.Mesh(new THREE.BoxGeometry(0.5, 6.4, 2.2), stone);
      jamb.position.set(side * (gap / 2 - 0.1), 3.2, -2.6);
      this.rig.add(jamb);
    }

    const lintel = new THREE.Mesh(new THREE.BoxGeometry(gap + 1.4, 1.2, 2.4), stone);
    lintel.position.set(0, 7, -2.9);
    this.rig.add(lintel);

    // The glyph band across the lintel. Bars rather than signs: at this
    // distance a sign is two pixels, and inventing writing is forbidden.
    this.band = new THREE.Group();
    const barGeometry = new THREE.BoxGeometry(0.19, 0.56, 0.1);
    const bars = 13;
    for (let i = 0; i < bars; i += 1) {
      const bar = new THREE.Mesh(
        barGeometry,
        new THREE.MeshStandardMaterial({
          color: PALETTE.gold,
          emissive: PALETTE.gold,
          emissiveIntensity: 0,
          roughness: 0.6,
        }),
      );
      bar.position.set(-2.4 + i * 0.4, 7, -1.68);
      bar.scale.y = 0.6 + ((i * 37) % 11) / 14;
      this.band.add(bar);
    }
    this.rig.add(this.band);

    // The chamber behind, lit from within once the doors part.
    const chamber = new THREE.Mesh(
      new THREE.PlaneGeometry(gap, 6.4),
      new THREE.MeshBasicMaterial({ color: PALETTE.glow, transparent: true }),
    );
    chamber.position.set(0, 3.2, -3.6);
    chamber.material.opacity = 0;
    this.chamber = chamber;
    this.rig.add(chamber);

    // The two slabs that part, in front of the chamber.
    this.doors = [];
    for (const side of [-1, 1]) {
      const door = new THREE.Mesh(
        new THREE.BoxGeometry(gap / 2, 6.4, 0.4),
        new THREE.MeshStandardMaterial({
          color: 0x232c3b,
          roughness: 0.88,
          metalness: 0.06,
        }),
      );
      door.position.set(side * gap / 4, 3.2, -3.1);
      door.userData.side = side;
      door.userData.home = side * gap / 4;
      this.rig.add(door);
      this.doors.push(door);
    }
  }

  #guards() {
    // Anubis, seated, as the funerary statues actually are: forelegs
    // straight, hindquarters down, head up and forward, tail along the
    // plinth. The first pass was a standing figure built from a cylinder and
    // a box, and it read as a chess piece.
    //
    // Still stylised rather than detailed. A low-polygon Anubis that almost
    // works is uncanny; one that is clearly a carved statue is not, and at
    // this distance the silhouette is the whole read: long snout, tall ears,
    // straight forelegs.
    const statue = new THREE.MeshStandardMaterial({
      color: 0x2b3444,
      roughness: 0.92,
      metalness: 0.06,
    });
    const gilt = new THREE.MeshStandardMaterial({
      color: PALETTE.gold,
      emissive: PALETTE.gold,
      emissiveIntensity: 0.12,
      roughness: 0.4,
      metalness: 0.6,
    });
    this.staves = [];

    for (const side of [-1, 1]) {
      const guard = new THREE.Group();

      // Plinth, stepped.
      const base = new THREE.Mesh(new THREE.BoxGeometry(3.2, 0.42, 1.9), statue);
      base.position.y = 0.21;
      guard.add(base);
      const plinth = new THREE.Mesh(new THREE.BoxGeometry(2.9, 0.5, 1.65), statue);
      plinth.position.y = 0.67;
      guard.add(plinth);

      // Hindquarters: the mass a seated jackal sits back on.
      const haunch = new THREE.Mesh(new THREE.BoxGeometry(1.0, 1.15, 1.3), statue);
      haunch.position.set(-0.72, 1.5, 0);
      guard.add(haunch);

      // The back, rising from haunch to shoulder.
      const back = new THREE.Mesh(new THREE.BoxGeometry(1.5, 0.85, 1.05), statue);
      back.position.set(0.02, 2.0, 0);
      back.rotation.z = -0.32;
      guard.add(back);

      // Chest, upright and forward of the haunch.
      const chest = new THREE.Mesh(new THREE.BoxGeometry(0.92, 1.65, 1.0), statue);
      chest.position.set(0.62, 2.05, 0);
      guard.add(chest);

      // Forelegs: straight down to the plinth, which is the pose's signature.
      for (const leg of [-1, 1]) {
        const foreleg = new THREE.Mesh(
          new THREE.BoxGeometry(0.26, 1.35, 0.26),
          statue,
        );
        foreleg.position.set(0.86, 1.6, leg * 0.32);
        guard.add(foreleg);
        const paw = new THREE.Mesh(new THREE.BoxGeometry(0.34, 0.2, 0.58), statue);
        paw.position.set(0.92, 1.02, leg * 0.32);
        guard.add(paw);
      }

      // Neck and head, carried high and forward.
      const neck = new THREE.Mesh(new THREE.BoxGeometry(0.55, 0.8, 0.62), statue);
      neck.position.set(0.66, 3.0, 0);
      guard.add(neck);

      const head = new THREE.Mesh(new THREE.BoxGeometry(0.62, 0.62, 0.72), statue);
      head.position.set(0.66, 3.55, 0);
      guard.add(head);

      // The snout. Long, level, and the single thing that makes this a jackal.
      const snout = new THREE.Mesh(new THREE.BoxGeometry(0.85, 0.3, 0.34), statue);
      snout.position.set(1.16, 3.44, 0);
      guard.add(snout);

      // Ears: tall, upright, slightly splayed.
      for (const ear of [-1, 1]) {
        const shape = new THREE.Mesh(new THREE.BoxGeometry(0.16, 0.95, 0.34), statue);
        shape.position.set(0.5, 4.2, ear * 0.24);
        shape.rotation.z = 0.12;
        shape.rotation.x = ear * 0.1;
        guard.add(shape);
      }

      // The nemes headcloth flaring behind the ears, and a gilt collar. Two
      // marks of rank, and the only gold on the figure.
      const nemes = new THREE.Mesh(new THREE.BoxGeometry(0.36, 1.05, 1.15), statue);
      nemes.position.set(0.3, 3.35, 0);
      guard.add(nemes);
      const collar = new THREE.Mesh(new THREE.BoxGeometry(0.7, 0.2, 1.06), gilt);
      collar.position.set(0.62, 2.72, 0);
      guard.add(collar);

      // Tail along the plinth.
      const tail = new THREE.Mesh(new THREE.BoxGeometry(1.5, 0.2, 0.22), statue);
      tail.position.set(-1.25, 1.02, 0);
      tail.rotation.z = 0.18;
      guard.add(tail);

      // The staff it holds upright, which is what strikes the ground.
      const staff = new THREE.Mesh(
        new THREE.CylinderGeometry(0.08, 0.08, 4.6, 6),
        gilt,
      );
      staff.position.set(1.12, 2.3, side * 0.62);
      guard.add(staff);
      this.staves.push(staff);

      // Facing the doorway, so both sentries look at what the viewer is about
      // to walk through.
      guard.position.set(side * 4.9, 0, 4.2);
      guard.rotation.y = side > 0 ? Math.PI : 0;
      guard.scale.setScalar(0.95);
      this.rig.add(guard);
    }
  }

  #dust() {
    const count = 900;
    const positions = new Float32Array(count * 3);
    this.dustSeed = new Float32Array(count);
    for (let i = 0; i < count; i += 1) {
      positions[i * 3] = (Math.random() - 0.5) * 26;
      positions[i * 3 + 1] = Math.random() * 9;
      positions[i * 3 + 2] = (Math.random() - 0.5) * 18 - 1;
      this.dustSeed[i] = Math.random();
    }
    const geometry = new THREE.BufferGeometry();
    geometry.setAttribute('position', new THREE.BufferAttribute(positions, 3));

    this.dust = new THREE.Points(
      geometry,
      new THREE.PointsMaterial({
        color: PALETTE.sandLit,
        size: 0.06,
        transparent: true,
        opacity: 0.32,
        depthWrite: false,
      }),
    );
    this.scene.add(this.dust);
  }

  #stars() {
    const count = 420;
    const positions = new Float32Array(count * 3);
    for (let i = 0; i < count; i += 1) {
      const theta = Math.random() * Math.PI * 2;
      const phi = Math.random() * 0.42 + 0.05;
      const radius = 70;
      positions[i * 3] = Math.cos(theta) * Math.sin(phi + 0.6) * radius;
      positions[i * 3 + 1] = Math.cos(phi) * radius * 0.7 + 12;
      positions[i * 3 + 2] = Math.sin(theta) * Math.sin(phi + 0.6) * radius;
    }
    const geometry = new THREE.BufferGeometry();
    geometry.setAttribute('position', new THREE.BufferAttribute(positions, 3));
    this.scene.add(
      new THREE.Points(
        geometry,
        new THREE.PointsMaterial({ color: 0x8ea6c4, size: 0.34, transparent: true, opacity: 0.7 }),
      ),
    );
  }

  /** The viewer has asked to go in. */
  open() {
    if (this.state !== 'waiting') return;
    this.state = 'opening';
    this.openedAt = this.clock.getElapsedTime();
    this.shake = 1;
    this.host.dispatchEvent(new CustomEvent('threshold:opening'));
  }

  resize() {
    if (this.disposed || !this.renderer) return;
    const width = this.host.clientWidth;
    const height = this.host.clientHeight;
    this.camera.aspect = width / height;
    this.camera.updateProjectionMatrix();
    this.renderer.setSize(width, height);
  }

  frame() {
    if (this.disposed) return;
    const time = this.clock.getElapsedTime();
    const since = this.state === 'waiting' ? 0 : time - this.openedAt;

    // Dust drifts always, and lifts hard on the impact.
    const positions = this.dust.geometry.attributes.position;
    const lift = this.state === 'waiting' ? 0.12 : 0.12 + Math.max(0, 2.4 - since) * 1.5;
    for (let i = 0; i < this.dustSeed.length; i += 1) {
      let y = positions.getY(i) + this.dustSeed[i] * 0.004 * lift * 60;
      if (y > 9) y = 0;
      positions.setY(i, y);
      positions.setX(i, positions.getX(i) + Math.sin(time * 0.3 + this.dustSeed[i] * 9) * 0.004);
    }
    positions.needsUpdate = true;

    if (this.state === 'waiting') {
      // The band breathes, which is the only invitation the scene gives.
      const pulse = 0.16 + Math.sin(time * 1.6) * 0.1;
      for (const bar of this.band.children) bar.material.emissiveIntensity = pulse;
      this.camera.position.x = Math.sin(time * 0.18) * 0.4;
      this.camera.position.y = 3.4 + Math.sin(time * 0.24) * 0.12;
      this.camera.lookAt(0, 4, -1);
    } else {
      this.#opening(since);
    }

    this.renderer.render(this.scene, this.camera);
  }

  #opening(since) {
    const ease = (t) => 1 - Math.pow(1 - Math.min(1, Math.max(0, t)), 3);

    // Beat one: the staves come down. The strike is what starts everything,
    // so it lands before anything else moves.
    const strike = Math.min(1, since / 0.42);
    for (const staff of this.staves) {
      staff.rotation.z = (1 - ease(strike)) * 0.5;
      staff.material.emissiveIntensity = 0.1 + ease(strike) * 0.9;
    }

    // Beat two: the ground takes it. Shake decays fast; a long shake reads as
    // a bug rather than as an impact.
    this.shake = Math.max(0, 1 - (since - 0.42) / 0.9);
    const jolt = since > 0.42 ? this.shake * this.shake * 0.16 : 0;
    this.rig.position.y = Math.sin(since * 60) * jolt;
    this.rig.position.x = Math.cos(since * 47) * jolt * 0.6;

    // Beat three: the inscription takes light, one bar at a time from the
    // centre out, so the lintel reads as being read.
    const litFrom = Math.max(0, since - 0.6) * 9;
    this.band.children.forEach((bar, index) => {
      const distance = Math.abs(index - 6);
      bar.material.emissiveIntensity = litFrom > distance ? 1.6 : 0.16;
    });

    // Beat four: the slabs part, and the chamber behind them is already lit.
    const part = ease(Math.max(0, since - 1.15) / 1.5);
    this.doors.forEach((door) => {
      door.position.x = door.userData.home + door.userData.side * part * 3.7;
    });
    this.chamber.material.opacity = part;
    this.inner.intensity = part * 40;

    // Beat five: the camera goes in. Everything above happens to the scene;
    // this is the only part that happens to the viewer.
    const approach = ease(Math.max(0, since - 1.8) / 2.1);
    this.camera.position.z = 16 - approach * 19.2;
    this.camera.position.y = 3.4 - approach * 0.5;
    this.camera.position.x *= 1 - approach;
    this.camera.lookAt(0, 3.4, -4);

    if (since > 3.7) {
      this.state = 'done';
      this.onFinished();
    }
  }

  dispose() {
    this.disposed = true;
    if (!this.renderer) return;
    this.scene.traverse((object) => {
      if (object.geometry) object.geometry.dispose();
      if (object.material) {
        const materials = Array.isArray(object.material) ? object.material : [object.material];
        for (const material of materials) material.dispose();
      }
    });
    this.renderer.dispose();
    this.renderer.domElement.remove();
  }
}

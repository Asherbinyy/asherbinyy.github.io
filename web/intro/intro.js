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
import { loadMesh } from './kmsh.js';

const PALETTE = {
  night: 0x0b1018,
  sand: 0x6d6144,
  sandLit: 0x8a7248,
  stone: 0xa8b3c4,
  gold: 0xe3a93f,
  glow: 0xffd98a,
};

// The pedestal, in scene units, and the statue that stands on it. Named
// because two different methods have to agree about where its top is.
const BASE_HEIGHT = 0.42;
const PLINTH_HEIGHT = 0.5;
const PEDESTAL_TOP = BASE_HEIGHT + PLINTH_HEIGHT;
const PEDESTAL_WIDTH = 2.1;
// Tall enough to be a colossus rather than an ornament: with the pedestal
// under it this stands above the doorway it flanks.
const STATUE_HEIGHT = 4.3;
/** Bastet sits lower than a standing god, and turns to face the viewer. */
const BASTET_HEIGHT = 3.4;
/** Half the width that must be in frame (both pedestals and braziers), how
 *  far forward the statues stand, and where the camera ends up, past the
 *  door. */
const FRAME_HALF_WIDTH = 7.0;
const GUARD_DEPTH = 4.8;
const APPROACH_END = 3.2;
/** How tall the braziers' stands are, and how bright the light they throw. */
const BRAZIER_HEIGHT = 1.05;
const LAMP_LIGHT = 26;
const BASTET_TURN = 0.5;
/** Anubis lies along the pedestal, facing the doorway at a three-quarter. */
const ANUBIS_LENGTH = 3.5;
const ANUBIS_TURN = Math.PI - 0.55;

/** Reads the run once, so a reload replays it but a route change does not. */
const PLAYED_KEY = 'kemet.threshold.played';

export class Threshold {
  constructor(host) {
    this.host = host;
    this.clock = new THREE.Clock();
    this.state = 'waiting';
    this.openedAt = 0;
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
    // The scene carries no information; the credit beside it does. Hiding the
    // canvas specifically, rather than the overlay that contains both, is what
    // lets a screen reader still reach the attribution.
    this.renderer.domElement.setAttribute('aria-hidden', 'true');
    this.renderer.setSize(width, height);
    this.renderer.setClearColor(PALETTE.night, 1);
    this.host.appendChild(this.renderer.domElement);

    this.scene = new THREE.Scene();
    this.scene.fog = new THREE.FogExp2(PALETTE.night, 0.026);

    this.camera = new THREE.PerspectiveCamera(52, width / height, 0.1, 200);
    this.#fit(width / height);
    this.camera.position.set(0, 3.4, this.baseZ);
    this.camera.lookAt(0, 4, 0);

    this.rig = new THREE.Group();
    this.scene.add(this.rig);

    this.#textures();
    this.#lights();
    this.#ground();
    this.#facade();
    this.#guards();
    this.#dust();
    this.#stars();
  }

  /**
   * Real photographed stone and sand, instead of flat colour.
   *
   * The owner's repeated objection was that the scene read as cheap and flat,
   * and the honest reason was that every surface was a single sRGB value with
   * no grain, no normal detail and no variation in roughness. Lighting cannot
   * rescue that: a flat albedo lit perfectly still looks like painted card.
   *
   * These are Poly Haven scans, CC0, at 512px and quality 72, which is 356KB
   * for the whole set. Resolution is deliberately low: these are surfaces seen
   * at distance in near-darkness, and the grain is doing the work rather than
   * the detail.
   *
   * Loading is fire-and-forget. A texture that fails to arrive leaves the
   * material at its base colour, which is exactly the scene as it was, so a
   * blocked or slow request costs quality rather than the whole intro.
   */
  #textures() {
    const loader = new THREE.TextureLoader();
    const load = (file, repeat) => {
      const texture = loader.load(`intro/textures/${file}`);
      texture.wrapS = THREE.RepeatWrapping;
      texture.wrapT = THREE.RepeatWrapping;
      texture.repeat.set(repeat[0], repeat[1]);
      texture.anisotropy = Math.min(
        4,
        this.renderer.capabilities.getMaxAnisotropy(),
      );
      return texture;
    };

    // Colour maps carry sRGB; normal and packed maps are raw data and must
    // not be colour-managed, or the lighting goes subtly wrong everywhere.
    const stoneColour = load('sand_diff.jpg', [3, 2]);
    stoneColour.colorSpace = THREE.SRGBColorSpace;
    const groundColour = load('ground_diff.jpg', [26, 26]);
    groundColour.colorSpace = THREE.SRGBColorSpace;

    this.stoneMaps = {
      map: stoneColour,
      normalMap: load('sand_nor_gl.jpg', [3, 2]),
      // Poly Haven packs ambient occlusion, roughness and metalness into one
      // texture's three channels, and Three reads roughness from the green
      // one, so the packed map serves directly as the roughness map.
      //
      // The ambient-occlusion channel is deliberately unused: `aoMap` needs a
      // second UV set that box and cylinder geometry does not carry, so wiring
      // it would silently do nothing while looking like it worked.
      roughnessMap: load('sand_arm.jpg', [3, 2]),
    };
    this.groundMaps = {
      map: groundColour,
      normalMap: load('ground_nor.jpg', [26, 26]),
    };

    // The statues take the sand grain, not the wall's stone. The wall texture
    // is photographed sandstone *blocks*, and it has mortar courses running
    // through it: correct on masonry, and on a figure carved from one piece it
    // draws brick lines across the chest. The ground scan is bare grain with
    // no structure in it, which is what weathered granite looks like close up.
    //
    // Cloned rather than reused because repeat lives on the texture, not on
    // the material. The image is shared, so this costs a sampler, not a
    // download.
    this.statueMaps = {
      map: this.#retile(groundColour, [3, 4]),
      normalMap: this.#retile(this.groundMaps.normalMap, [3, 4]),
    };
  }

  /** One texture at a different tiling, sharing the image it came from. */
  #retile(texture, repeat) {
    const copy = texture.clone();
    copy.repeat.set(repeat[0], repeat[1]);
    copy.needsUpdate = true;
    return copy;
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
        // Tinted rather than replaced: the scan is daylight sand and the
        // scene is night, so the map supplies grain and the colour supplies
        // the hour.
        ...this.groundMaps,
        normalScale: new THREE.Vector2(0.7, 0.7),
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
      ...this.stoneMaps,
      normalScale: new THREE.Vector2(1.1, 1.1),
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
          color: 0x7f8ba0,
          roughness: 0.88,
          metalness: 0.06,
          ...this.stoneMaps,
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
    // Two colossi flanking the gate, which is how a pylon was actually
    // fronted: standing figures at the door rather than ornament beside it.
    //
    // Everything here except the statue itself is architecture, and boxes are
    // the honest way to build architecture. The statue is not, and the first
    // pass proved it: a seated Anubis assembled from nine boxes read as nine
    // boxes at every distance, because that is what it was. Lighting cannot
    // rescue geometry with no carving in it, and the owner said so.
    //
    // So the figure is a photogrammetry scan of a real statue, loaded from
    // `models/guardian.kmsh`. It is Ra-Horakhty, the sun at the horizon, and
    // that is a better fit than the Anubis it replaces: this sequence is a
    // sealed door opening onto light.
    const statue = new THREE.MeshStandardMaterial({
      // A cool albedo on a warm map, which together render as stone about half
      // again brighter than the wall: two objects standing in front of it
      // rather than a hole in it.
      //
      // The value is measured against the pylon rather than picked, and it
      // took four passes to get there. Untextured, it rendered at twice the
      // wall's brightness and read as plaster. Corrected to a blue-grey, it
      // read as steel under a cool moon. Given the wall's own photograph, the
      // same colour multiplied down darker than the wall and the figures
      // vanished into it. Given the sand photograph instead, the warmth in the
      // map compounded with the warmth in the colour and they came out bright
      // tan. Hence a colour that looks wrong written down: it is the one that
      // cancels the map rather than the one the stone should be.
      color: 0xa7aebf,
      roughness: 1,
      metalness: 0,
      ...this.statueMaps,
      normalScale: new THREE.Vector2(0.55, 0.55),
    });
    // Held on the instance because the opening sequence brightens it, and it
    // is shared by both braziers, so the flare is one assignment rather than
    // one per piece.
    this.gilt = new THREE.MeshStandardMaterial({
      color: PALETTE.gold,
      emissive: PALETTE.gold,
      // Low at rest. The gold is the one saturated thing in a night scene, and
      // at the first value it pulled the eye off the statues entirely; it has
      // nine tenths of its range still to travel when the door is opened.
      emissiveIntensity: 0.05,
      roughness: 0.52,
      metalness: 0.7,
    });
    const gilt = this.gilt;
    const plinthStone = new THREE.MeshStandardMaterial({
      color: 0x8b98ae,
      roughness: 0.92,
      metalness: 0.06,
      ...this.stoneMaps,
      normalScale: new THREE.Vector2(0.7, 0.7),
    });
    this.lamps = [];
    this.guards = [];

    for (const side of [-1, 1]) {
      const guard = new THREE.Group();

      // A stepped pedestal, roughly square: a standing figure does not need
      // the long plinth a seated animal did.
      const base = new THREE.Mesh(
        new THREE.BoxGeometry(PEDESTAL_WIDTH, BASE_HEIGHT, PEDESTAL_WIDTH),
        plinthStone,
      );
      base.position.y = BASE_HEIGHT / 2;
      guard.add(base);
      const plinth = new THREE.Mesh(
        new THREE.BoxGeometry(1.8, PLINTH_HEIGHT, 1.8),
        plinthStone,
      );
      plinth.position.y = BASE_HEIGHT + PLINTH_HEIGHT / 2;
      guard.add(plinth);


      // Facing the doorway, so both sentries look at what the viewer is about
      // to walk through. The group's local +X is that direction, on both
      // sides, which is also the direction the scan faces.
      guard.position.set(side * 4.9, 0, 4.2);
      guard.rotation.y = side > 0 ? Math.PI : 0;
      guard.scale.setScalar(0.95);
      guard.userData.side = side;
      this.rig.add(guard);
      this.guards.push(guard);
    }

    // A brazier at the front of each pedestal, on the doorway's side. The
    // black stone figures read as holes in the night under the moon alone;
    // the owner asked for gold light on them. Placed in the rig rather than
    // in each guard, because the right guard is turned half round and its
    // local "front" is behind it.
    for (const side of [-1, 1]) {
      this.#brazier(gilt, side * 3.35, 5.45);
    }

    this.#carve(statue);
  }

  /**
   * A bronze bowl on three legs, a flame and a soft halo, and the warm light
   * it throws on the statue beside it. The flame flickers while the door
   * waits and flares when it opens: the opening's first beat now that the
   * staves are gone.
   */
  #brazier(gilt, x, z) {
    const lamp = new THREE.Group();
    const bronze = new THREE.MeshStandardMaterial({
      color: 0x4a3a22,
      roughness: 0.55,
      metalness: 0.8,
    });
    for (let i = 0; i < 3; i += 1) {
      const leg = new THREE.Mesh(
        new THREE.CylinderGeometry(0.035, 0.05, BRAZIER_HEIGHT, 6),
        bronze,
      );
      const angle = (i / 3) * Math.PI * 2;
      leg.position.set(
        Math.cos(angle) * 0.16,
        BRAZIER_HEIGHT / 2,
        Math.sin(angle) * 0.16,
      );
      leg.rotation.set(Math.sin(angle) * 0.14, 0, -Math.cos(angle) * 0.14);
      lamp.add(leg);
    }
    const bowl = new THREE.Mesh(
      new THREE.CylinderGeometry(0.36, 0.16, 0.24, 16, 1, true),
      gilt,
    );
    bowl.material.side = THREE.DoubleSide;
    bowl.position.y = BRAZIER_HEIGHT + 0.12;
    lamp.add(bowl);
    const rim = new THREE.Mesh(new THREE.TorusGeometry(0.36, 0.03, 6, 20), gilt);
    rim.rotation.x = Math.PI / 2;
    rim.position.y = BRAZIER_HEIGHT + 0.24;
    lamp.add(rim);

    const flameMaterial = new THREE.MeshBasicMaterial({
      color: PALETTE.glow,
      transparent: true,
      opacity: 0.45,
      blending: THREE.AdditiveBlending,
      depthWrite: false,
    });
    const flame = new THREE.Mesh(new THREE.ConeGeometry(0.18, 0.55, 12), flameMaterial);
    flame.position.y = BRAZIER_HEIGHT + 0.5;
    lamp.add(flame);
    const core = new THREE.Mesh(
      new THREE.ConeGeometry(0.1, 0.36, 10),
      new THREE.MeshBasicMaterial({
        color: 0xfff3d6,
        transparent: true,
        opacity: 0.7,
        blending: THREE.AdditiveBlending,
        depthWrite: false,
      }),
    );
    core.position.y = BRAZIER_HEIGHT + 0.4;
    lamp.add(core);

    const halo = new THREE.Sprite(
      new THREE.SpriteMaterial({
        map: this.#haloTexture(),
        color: PALETTE.gold,
        transparent: true,
        opacity: 0.85,
        blending: THREE.AdditiveBlending,
        depthWrite: false,
      }),
    );
    halo.position.y = BRAZIER_HEIGHT + 0.5;
    halo.scale.setScalar(1.6);
    lamp.add(halo);

    // The light itself, above the flame so it reaches the figure's head.
    const light = new THREE.PointLight(PALETTE.glow, LAMP_LIGHT, 11, 1.4);
    light.position.y = BRAZIER_HEIGHT + 1.1;
    lamp.add(light);

    lamp.position.set(x, 0, z);
    lamp.userData = { flame, core, halo, light, seed: x };
    this.rig.add(lamp);
    this.lamps.push(lamp);
  }

  /** A soft round glow, drawn once and shared by both halos. */
  #haloTexture() {
    if (this.halo) return this.halo;
    const size = 128;
    const canvas = document.createElement('canvas');
    canvas.width = size;
    canvas.height = size;
    const context = canvas.getContext('2d');
    const gradient = context.createRadialGradient(
      size / 2, size / 2, 0, size / 2, size / 2, size / 2,
    );
    gradient.addColorStop(0, 'rgba(255,255,255,1)');
    gradient.addColorStop(0.25, 'rgba(255,255,255,0.45)');
    gradient.addColorStop(1, 'rgba(255,255,255,0)');
    context.fillStyle = gradient;
    context.fillRect(0, 0, size, size);
    this.halo = new THREE.CanvasTexture(canvas);
    return this.halo;
  }

  /** Flickers each flame; [flare] 0 to 1 is the opening's surge. */
  #flicker(time, flare) {
    for (const lamp of this.lamps) {
      const { flame, core, halo, light, seed } = lamp.userData;
      const flick =
        Math.sin(time * 11 + seed) * 0.5 +
        Math.sin(time * 17.3 + seed * 2) * 0.3 +
        Math.sin(time * 5.1 + seed * 3) * 0.2;
      const grow = 1 + flare * 0.7;
      flame.scale.set(grow, grow * (1 + flick * 0.12), grow);
      core.scale.set(grow, grow * (1 + flick * 0.18), grow);
      halo.scale.setScalar(1.6 * grow * (1 + flick * 0.05));
      light.intensity = LAMP_LIGHT * (1 + flick * 0.08) * (1 + flare * 0.8);
    }
  }

  /**
   * Stands the scanned statue on both plinths, once it has arrived.
   *
   * Fire-and-forget, like the textures, and for the same reason: the scene has
   * to paint on the first frame. The doors do not move for 1500ms, so a
   * same-origin fetch of 190KB is in place long before anything happens.
   *
   * A failure leaves two lit pedestals with braziers beside them, which
   * reads as a composition rather than as a fault. The boxes are deliberately
   * not kept as a fallback: they were the thing being fixed, and showing them
   * on a slow connection would say the fix had not landed.
   */
  #carve(material) {
    // Bastet, the cat, in black stone on the left, the way the owner asked
    // for her: a seated cat in the pose of the Gayer-Anderson bronze.
    // Polished, so the braziers' light runs along the carving as a sheen:
    // matte black took no light at all and the figures were silhouettes.
    const basalt = new THREE.MeshStandardMaterial({
      color: 0x2a2e38,
      roughness: 0.4,
      metalness: 0.15,
    });
    loadMesh('intro/models/bastet.kmsh')
      .then((geometry) => {
        if (this.disposed) {
          geometry.dispose();
          return;
        }
        const bounds = geometry.boundingBox;
        const scale = BASTET_HEIGHT / (bounds.max.y - bounds.min.y);
        const guard = this.guards.find((g) => g.userData.side < 0);
        const figure = new THREE.Mesh(geometry, basalt);
        figure.scale.setScalar(scale);
        figure.position.y = PEDESTAL_TOP - bounds.min.y * scale;
        figure.rotation.y = BASTET_TURN;
        guard.add(figure);
      })
      .catch(() => {});

    // Anubis on the right: the recumbent jackal of Tutankhamun's shrine,
    // lying on his chest the way he guarded the treasury. Sized by his
    // length, since he lies rather than stands.
    loadMesh('intro/models/anubis.kmsh')
      .then((geometry) => {
        if (this.disposed) {
          geometry.dispose();
          return;
        }
        const bounds = geometry.boundingBox;
        const length = Math.max(
          bounds.max.x - bounds.min.x,
          bounds.max.z - bounds.min.z,
        );
        const scale = ANUBIS_LENGTH / length;
        const guard = this.guards.find((g) => g.userData.side > 0);
        const figure = new THREE.Mesh(geometry, basalt);
        figure.scale.setScalar(scale);
        figure.position.y = PEDESTAL_TOP - bounds.min.y * scale;
        figure.rotation.y = ANUBIS_TURN;
        guard.add(figure);
      })
      .catch(() => {});
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
    this.host.dispatchEvent(new CustomEvent('threshold:opening'));
  }

  /**
   * Frames the gate for the screen's shape.
   *
   * Composed for a wide screen: on a phone held upright the same camera saw
   * the doorway and nothing either side of it, and the owner said the scene
   * looked cut. A narrow screen gets a slightly wider lens and stands further
   * back, far enough that both statues and their braziers are in the frame,
   * with the fog thinned to match so the gate is not lost in it.
   */
  #fit(aspect) {
    const fov = aspect >= 1 ? 52 : 52 + (1 - aspect) * 22;
    const halfFov = (fov / 2) * (Math.PI / 180);
    const needed = FRAME_HALF_WIDTH / (Math.tan(halfFov) * aspect);
    this.baseZ = Math.max(16, GUARD_DEPTH + needed);
    this.camera.fov = fov;
    if (this.scene?.fog) this.scene.fog.density = 0.026 * (16 / this.baseZ);
    if (this.state === 'waiting' || this.state === undefined) {
      this.camera.position.z = this.baseZ;
    }
  }

  resize() {
    if (this.disposed || !this.renderer) return;
    const width = this.host.clientWidth;
    const height = this.host.clientHeight;
    this.camera.aspect = width / height;
    this.#fit(width / height);
    this.camera.updateProjectionMatrix();
    this.renderer.setSize(width, height);
  }

  frame() {
    if (this.disposed) return;
    const time = this.clock.getElapsedTime();
    const since = this.state === 'waiting' ? 0 : time - this.openedAt;

    // Dust drifts always, and lifts hard as the door opens.
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
      this.#flicker(time, 0);
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
    const clamp01 = (t) => Math.min(1, Math.max(0, t));

    // Beat one: the braziers flare and the gold takes light. The owner cut
    // the staves striking the floor; the fire answering the knock is the
    // opening's first beat now.
    const flare = clamp01(since / 0.3) * (1 - clamp01((since - 0.9) / 1.2) * 0.5);
    this.#flicker(this.clock.getElapsedTime(), flare);
    this.gilt.emissiveIntensity = 0.05 + ease(since / 0.3) * 0.95;

    // Beat three: the inscription takes light from the centre out.
    const litFrom = Math.max(0, since - 0.32) * 16;
    this.band.children.forEach((bar, index) => {
      const distance = Math.abs(index - 6);
      bar.material.emissiveIntensity = litFrom > distance ? 1.6 : 0.16;
    });

    // Beat four: the slabs part. Faster than it was -- the owner found three
    // seconds and more of opening a wait -- and the chamber behind is lit.
    const part = ease(Math.max(0, since - 0.5) / 0.95);
    this.doors.forEach((door) => {
      door.position.x = door.userData.home + door.userData.side * part * 3.7;
    });
    this.chamber.material.opacity = part;
    this.inner.intensity = part * 40;

    // Beat five: the camera goes in.
    const approach = ease(Math.max(0, since - 0.78) / 1.25);
    this.camera.position.z =
      this.baseZ - approach * (this.baseZ + APPROACH_END);
    this.camera.position.y = 3.4 - approach * 0.5;
    this.camera.position.x *= 1 - approach;
    this.camera.lookAt(0, 3.4, -4);

    if (since > 2.1) {
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

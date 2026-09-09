/**
 * Reads the compact mesh container the statues are stored in.
 *
 * The scene needs one sculpted model. glTF is the obvious way to carry it and
 * the wrong one here: `GLTFLoader` is over 100KB of vendored JavaScript, and
 * it exists to describe scenes, materials, animation and skinning, none of
 * which this file has. What is actually needed is a list of positions and a
 * list of triangles.
 *
 * So the model is converted ahead of time by `tool/mesh/decimate_stl.py`, and
 * this reads what it writes. Positions and texture coordinates are 16-bit
 * across their own ranges, which on a life-size statue is finer than a
 * millimetre, and there are no normals in the file because an indexed mesh
 * yields exactly the same smooth normals from `computeVertexNormals`.
 */
import * as THREE from '../vendor/three.module.min.js';

/** "KMSH", read big-endian so it matches the bytes in that order. */
const MAGIC = 0x4b4d5348;
const VERSION = 3;
const HEADER = 60;

/**
 * Fetches and decodes one mesh.
 *
 * Rejects rather than returning something empty: the caller's fallback is to
 * leave the statue out of the scene, and an empty geometry would instead put
 * an invisible object in it and report success.
 */
export async function loadMesh(url) {
  const response = await fetch(url);
  if (!response.ok) throw new Error(`${url}: HTTP ${response.status}`);
  const buffer = await response.arrayBuffer();
  if (buffer.byteLength < HEADER) throw new Error(`${url}: truncated`);

  const head = new DataView(buffer);
  if (head.getUint32(0, false) !== MAGIC) throw new Error(`${url}: not a mesh`);
  if (head.getUint32(4, true) !== VERSION) throw new Error(`${url}: version`);

  const vertexCount = head.getUint32(8, true);
  const indexCount = head.getUint32(12, true);
  const wideIndices = (head.getUint32(16, true) & 1) === 1;

  // Bounds are the range the 16-bit positions were normalised across, so
  // decoding is one multiply-add per axis.
  const min = [20, 24, 28].map((at) => head.getFloat32(at, true));
  const max = [32, 36, 40].map((at) => head.getFloat32(at, true));
  const scale = min.map((low, axis) => (max[axis] - low) / 0xffff);
  const uvMin = [44, 48].map((at) => head.getFloat32(at, true));
  const uvMax = [52, 56].map((at) => head.getFloat32(at, true));
  const uvScale = uvMin.map((low, axis) => (uvMax[axis] - low) / 0xffff);

  const quantised = new Uint16Array(buffer, HEADER, vertexCount * 3);
  const positions = new Float32Array(vertexCount * 3);
  for (let i = 0; i < positions.length; i += 3) {
    positions[i] = min[0] + quantised[i] * scale[0];
    positions[i + 1] = min[1] + quantised[i + 1] * scale[1];
    positions[i + 2] = min[2] + quantised[i + 2] * scale[2];
  }

  const packedUv = new Uint16Array(buffer, HEADER + vertexCount * 6, vertexCount * 2);
  const uv = new Float32Array(vertexCount * 2);
  for (let i = 0; i < uv.length; i += 2) {
    uv[i] = uvMin[0] + packedUv[i] * uvScale[0];
    uv[i + 1] = uvMin[1] + packedUv[i + 1] * uvScale[1];
  }

  // Ten bytes a vertex: three 16-bit positions and two 16-bit texture
  // coordinates. The writer then pads to a 4-byte boundary so a 32-bit index
  // block can be viewed in place rather than copied.
  const indexAt = Math.ceil((HEADER + vertexCount * 10) / 4) * 4;
  const indices = wideIndices
    ? new Uint32Array(buffer, indexAt, indexCount)
    : new Uint16Array(buffer, indexAt, indexCount);

  const geometry = new THREE.BufferGeometry();
  geometry.setAttribute('position', new THREE.BufferAttribute(positions, 3));
  geometry.setAttribute('uv', new THREE.BufferAttribute(uv, 2));
  geometry.setIndex(new THREE.BufferAttribute(indices, 1));
  geometry.computeVertexNormals();
  geometry.computeBoundingBox();
  return geometry;
}

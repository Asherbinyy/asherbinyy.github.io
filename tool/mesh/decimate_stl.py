"""Turns a photogrammetry STL into a compact mesh the intro can load.

A museum scan is 100k triangles and 5MB, which is right for a scan archive and
wrong for the first paint of a web page. This reduces it by vertex clustering:
snap every vertex to a grid, drop triangles that collapse to a line, and weld
what remains. It is the cheapest decimation there is and it suits this case
exactly, because the statue is seen at a distance in near darkness and what
survives is the silhouette, which clustering preserves.

Output is a tiny purpose-made container rather than glTF. A glTF loader is
150KB of vendored JavaScript to read a file this simple, and the intro's whole
budget is smaller than that.

    magic   "KMSH"            4 bytes
    version u32               3
    counts  u32 u32 u32       vertices, indices, flags (bit 0: 32-bit indices)
    bounds  f32 x 6           min xyz, max xyz, origin-centred and unit-scaled
    uvrange f32 x 4           min uv, max uv
    verts   u16 x 3 x count   positions, normalised across the bounds
    uvs     u16 x 2 x count   texture coordinates, normalised across uvrange
    pad     0-3 bytes         so the index block starts 4-byte aligned
    idx     u16/u32 x count   triangles

There are no normals in the file. The mesh is indexed and welded, so the
consumer derives exactly the same smooth normals this tool would have written,
from a call it already has. Storing them would add a third to the download to
save nothing.

Positions are 16-bit because the mesh lives in a unit box, where 16 bits is
finer than a millimetre on a life-size statue and far finer than the clustering
that produced it. Indices are 16-bit while the vertex count allows it. Together
those halve the file against the obvious float32/uint32 encoding, which matters
because this loads during the first paint.
"""

import math
import struct
import sys

# Horizontal slices used to find the model's own vertical axis. Enough to
# average out the head and the base, few enough that each still holds a
# meaningful sample.
SLABS = 25


def read_stl(path, up):
    """Reads triangles, rotating a Z-up export onto Y-up as it goes.

    Scanning and CAD tools write Z-up; a scene graph wants Y-up. Doing it here
    rather than with a rotation on the node means the emitted bounds describe
    the statue as the scene will see it, so the scene can place it by its feet
    without knowing which tool produced the scan.
    """
    data = open(path, 'rb').read()
    count = struct.unpack('<I', data[80:84])[0]
    tris = []
    at = 84
    for _ in range(count):
        # Normal is recomputed from the welded mesh, so the file's own is
        # skipped: after clustering it would describe the original surface.
        vals = struct.unpack('<12f', data[at:at + 48])
        tri = (vals[3:6], vals[6:9], vals[9:12])
        if up == 'z':
            tri = tuple((v[0], v[2], -v[1]) for v in tri)
        tris.append(tri)
        at += 50
    return tris


def upright(tris):
    """Stands a scan up, using its own mass as the plumb line.

    A photogrammetry capture is aligned to wherever the camera rig happened to
    be, not to gravity. This one arrives leaning seven degrees, which on a
    statue standing at a doorway reads as damage rather than as a scan
    artefact.

    The correction takes the centroid of each horizontal slice, fits the line
    those centroids trace as the model rises, and rotates that line onto the
    vertical. It works because a standing figure is roughly symmetric about its
    own axis, so the run of slice centroids *is* that axis.
    """
    lo_y = min(v[1] for t in tris for v in t)
    hi_y = max(v[1] for t in tris for v in t)
    span = (hi_y - lo_y) or 1.0

    slabs = {}
    for tri in tris:
        for v in tri:
            key = min(SLABS - 1, int((v[1] - lo_y) / span * SLABS))
            slab = slabs.setdefault(key, [0.0, 0.0, 0.0, 0])
            for i in range(3):
                slab[i] += v[i]
            slab[3] += 1
    centres = [[slab[i] / slab[3] for i in range(3)] for slab in slabs.values()]
    if len(centres) < 3:
        return tris

    def slope(axis):
        mean_y = sum(c[1] for c in centres) / len(centres)
        mean_a = sum(c[axis] for c in centres) / len(centres)
        num = sum((c[1] - mean_y) * (c[axis] - mean_a) for c in centres)
        den = sum((c[1] - mean_y) ** 2 for c in centres)
        return num / den if den else 0.0

    axis = [slope(0), 1.0, slope(2)]
    length = math.sqrt(sum(c * c for c in axis))
    axis = [c / length for c in axis]

    # Rodrigues, rotating the model's own axis onto +Y. The cross product is
    # axis x up, in that order: the other order turns the model the wrong way
    # and doubles the lean instead of removing it.
    cross = [-axis[2], 0.0, axis[0]]
    sin = math.sqrt(sum(c * c for c in cross))
    if sin < 1e-9:
        return tris
    unit = [c / sin for c in cross]
    cos = axis[1]

    def turn(v):
        dot = sum(unit[i] * v[i] for i in range(3))
        perp = [
            unit[1] * v[2] - unit[2] * v[1],
            unit[2] * v[0] - unit[0] * v[2],
            unit[0] * v[1] - unit[1] * v[0],
        ]
        return tuple(v[i] * cos + perp[i] * sin + unit[i] * dot * (1 - cos)
                     for i in range(3))

    return [tuple(turn(v) for v in tri) for tri in tris]


def decimate(tris, grid):
    lo = [min(v[i] for t in tris for v in t) for i in range(3)]
    hi = [max(v[i] for t in tris for v in t) for i in range(3)]
    span = max(hi[i] - lo[i] for i in range(3)) or 1.0
    cell = span / grid

    keys = {}
    verts = []
    out = []
    for tri in tris:
        ids = []
        for v in tri:
            key = tuple(int((v[i] - lo[i]) / cell) for i in range(3))
            index = keys.get(key)
            if index is None:
                index = len(verts)
                keys[key] = index
                # The cell centre, not the first vertex that landed in it, so
                # the surface does not drift toward whichever triangle came
                # first in the file.
                verts.append([lo[i] + (key[i] + 0.5) * cell for i in range(3)])
            ids.append(index)
        # A triangle whose corners share a cell has no area left.
        if len(set(ids)) == 3:
            out.append(ids)
    return verts, out, span


def wrap(verts, faces):
    """Gives the mesh texture coordinates, wrapped around its own axis.

    Photogrammetry produces bare triangles, so a scan lit beside a photographed
    wall renders perfectly smooth next to visible grain, and reads as plaster.
    A cylindrical projection is the right shape for a standing figure: it
    stretches on horizontal surfaces, which on a statue is the top of the head
    and the shoulders, and nowhere a viewer looks.

    The seam is the part worth explaining. Angle wraps from 1 back to 0, so a
    triangle straddling the join spans nearly the whole texture and smears it
    across the figure. Those triangles get their own copies of the vertices
    with the angle continued past 1 instead, which is why this returns a vertex
    list that may be longer than the one it was given.
    """
    lo_y = min(v[1] for v in verts)
    height = (max(v[1] for v in verts) - lo_y) or 1.0

    verts = list(verts)
    uvs = []
    for x, y, z in verts:
        uvs.append([0.5 + math.atan2(z, x) / (2 * math.pi), (y - lo_y) / height])

    seam = {}
    out = []
    for face in faces:
        low = min(uvs[i][0] for i in face)
        if max(uvs[i][0] for i in face) - low <= 0.5:
            out.append(face)
            continue
        # Straddles the join: carry the near-zero corners round past one.
        fixed = []
        for index in face:
            if uvs[index][0] >= 0.5:
                fixed.append(index)
                continue
            copy = seam.get(index)
            if copy is None:
                copy = len(verts)
                seam[index] = copy
                verts.append(verts[index])
                uvs.append([uvs[index][0] + 1.0, uvs[index][1]])
            fixed.append(copy)
        out.append(fixed)
    return verts, out, uvs


def write(path, verts, faces, uvs, span):
    # Centred on its own footprint and scaled to unit height, so the scene
    # places it in scene units and never has to know the scan's own scale.
    # From the welded vertices, not the source triangles: a cluster centre can
    # sit half a cell outside the original extent, and bounds that do not
    # contain every vertex would clip the quantisation.
    lo = [min(v[i] for v in verts) for i in range(3)]
    hi = [max(v[i] for v in verts) for i in range(3)]
    mid = [(lo[i] + hi[i]) / 2 for i in range(3)]
    unit_lo = [(lo[i] - mid[i]) / span for i in range(3)]
    unit_hi = [(hi[i] - mid[i]) / span for i in range(3)]
    extent = [unit_hi[i] - unit_lo[i] or 1.0 for i in range(3)]

    uv_lo = [min(uv[i] for uv in uvs) for i in range(2)]
    uv_hi = [max(uv[i] for uv in uvs) for i in range(2)]
    uv_extent = [uv_hi[i] - uv_lo[i] or 1.0 for i in range(2)]

    wide = len(verts) > 0xFFFF
    body = bytearray()
    body += b'KMSH' + struct.pack('<IIII', 3, len(verts), len(faces) * 3,
                                  1 if wide else 0)
    body += struct.pack('<6f', *unit_lo, *unit_hi)
    body += struct.pack('<4f', *uv_lo, *uv_hi)
    for v in verts:
        body += struct.pack('<3H', *[
            min(0xFFFF, max(0, round(
                ((v[i] - mid[i]) / span - unit_lo[i]) / extent[i] * 0xFFFF)))
            for i in range(3)])
    for uv in uvs:
        body += struct.pack('<2H', *[
            min(0xFFFF, max(0, round((uv[i] - uv_lo[i]) / uv_extent[i] * 0xFFFF)))
            for i in range(2)])
    # A typed-array view cannot straddle its own alignment, so a 32-bit index
    # block has to start on a 4-byte boundary or the reader has to copy the
    # whole thing to fix it.
    body += b'\x00' * (-len(body) % 4)
    fmt = '<3I' if wide else '<3H'
    for f in faces:
        body += struct.pack(fmt, *f)
    open(path, 'wb').write(body)


if __name__ == '__main__':
    source, target, grid = sys.argv[1], sys.argv[2], int(sys.argv[3])
    up = sys.argv[4] if len(sys.argv) > 4 else 'y'
    tris = upright(read_stl(source, up))
    verts, faces, span = decimate(tris, grid)
    verts, faces, uvs = wrap(verts, faces)
    write(target, verts, faces, uvs, span)
    print(f'{len(tris)} triangles -> {len(faces)} '
          f'({len(verts)} vertices), '
          f'{len(open(target, "rb").read()) / 1024:.0f}KB')

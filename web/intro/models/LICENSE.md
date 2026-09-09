# Guardian statue

`guardian.kmsh` is not covered by this repository's MIT licence. It is an
adaptation of a Creative Commons Attribution-ShareAlike work, and ShareAlike
means the adaptation carries the same terms.

| | |
|---|---|
| **Work** | *Statue of Ra-Horakhty, 3D photogrammetry scan (STL)* |
| **Creator** | [OmarElAtabany](https://commons.wikimedia.org/wiki/User:OmarElAtabany) |
| **Source** | [Wikimedia Commons](https://commons.wikimedia.org/wiki/File:Statue_of_Ra-Horakhty,_3D_photogrammetry_scan_(STL).stl) |
| **Licence** | [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/) |
| **This file** | CC BY-SA 4.0, as required by ShareAlike |

## What was changed

The original is a 5.1MB binary STL of 102,714 triangles. That is the right size
for a scan archive and the wrong size for the first paint of a web page, so it
was reduced by `tool/mesh/decimate_stl.py`:

- decimated to 21,712 triangles by vertex clustering on a 96-cell grid
- rotated from the Z-up of the source export onto the scene's Y-up
- recentred on its own bounds and scaled to unit height
- re-encoded from 50 bytes per triangle to 16-bit positions and 16-bit indices,
  with normals dropped because an indexed mesh regenerates them exactly

The result is 190KB, and 135KB over the wire. No geometry was added and nothing
was sculpted by hand: it is the same statue, coarser.

## Why this statue

Ra-Horakhty is the sun at the horizon. The sequence this appears in is a sealed
door opening onto light, so the god of the sun on the horizon is the one who
should be standing at it.

Attribution is also shown on screen, in `web/index.html`, for as long as the
statues are visible.

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

Attribution is available through the Artwork credits link on the About page.

# Bastet

`bastet.kmsh` is not covered by this repository's MIT licence either. It is an
adaptation of a Creative Commons Attribution work.

| | |
|---|---|
| **Work** | *Bastet* (STL) |
| **Creator** | Gargi ([Thingiverse](https://www.thingiverse.com/Gargi)) / Christian Kuhn |
| **Source** | [Wikimedia Commons](https://commons.wikimedia.org/wiki/File:Thingiverse_-_Bastet.stl) |
| **Licence** | [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/) |

## What was changed

Reduced by `tool/mesh/decimate_stl.py` (with its plumb-line straightening
turned off: the model is already true, and a seated cat is not symmetric about
an upright axis) from 16,524 triangles to 9,706 on a 110-cell grid, turned
from Z-up onto the scene's Y-up, recentred and scaled to
unit height, and re-encoded as KMSH (104KB). It is rendered in a black stone,
at the owner's request for a black cat.

## Why this statue

The owner asked for the guardians to be Anubis and Bastet. Bastet is the
seated cat in the pose of the Gayer-Anderson bronze. No Anubis scan under an
open licence was found on Wikimedia Commons; the Scan The World scan of
Tutankhamun's Anubis shrine needs a MyMiniFactory account to download, so until
one is supplied the right-hand guardian is still Ra-Horakhty.

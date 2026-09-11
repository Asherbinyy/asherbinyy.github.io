# Interest logos

Images that stand for a specific the owner named: a club crest, a game's mark.

**This directory ships empty on purpose.** A club crest is a registered
trademark. The owner asked for the real Manchester United crest rather than a
drawn approximation, and he is right that an approximation would be worse. But
no free-licensed version of it exists: it is non-free on Wikipedia and absent
from Wikimedia Commons, so there is no version this repository can redistribute
without a licence it does not have.

Using a crest to say which club you support is ordinary nominative use, and
that is his call to make about his own site. So the slot is built and the file
is his to add:

1. Save the crest as `manchester-united.png`, ideally 256px square with a
   transparent background.
2. Drop it in this directory.
3. That is all. `interests.json` already points at it, and the card shows it
   the moment it exists.

Until then the card draws its scene as normal. A declared logo that resolves to
nothing is not an error; the image falls back to the drawing rather than
leaving a gap.

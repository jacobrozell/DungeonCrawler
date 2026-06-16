# Audio assets

The game runs **silently without these files** — `SoundManager` no-ops when a
resource is missing. Drop the files here, add them to the `DungeonDivers` target
("Copy Bundle Resources"), and they light up automatically (matched by name).

## Sound effects (`.caf` preferred, `.wav`/`.m4a` also accepted)

Name each file after the `SFX` raw value in `Models/SoundManager.swift`:

`swing`, `crit`, `miss`, `magic`, `poison`, `playerHurt`, `heal`, `enemyDie`,
`bossAppear`, `gold`, `levelUp`, `purchase`, `denied`, `playerDie`, `victory`

e.g. `swing.caf`, `crit.caf`, …

## Music (looping, `.m4a` AAC preferred)

Name each after the `MusicTrack` raw value: `title`, `combat`, `victory`,
`gameover` (e.g. `title.m4a`).

## Sourcing & licensing

Use CC0 / royalty-free audio (e.g. kenney.nl, freesound.org CC0) or commissioned
work. **Record attribution/license for every file here** before shipping.

| File | Source | License |
|------|--------|---------|
| _(none yet)_ | | |

# trajectories
## spatial approach to rhythmic contours

This repository contains:

* electron app for path authoring
* max patch for applying the movement to a set of audio files

Electron app: visual indication of paths (trajectories) and dynamics of motion (rests, accelerations).

Trajectories exports a single multichannel `wav` file containing:

* `doppler` -- pitch-shift curve data according to doppler effect
* `distance` -- square law for distance-based attenuation
* `azimuth` -- angle from listener, normalized to be 0 to 1 for 360 degrees
* `panning` -- normalized L-R panning for exaggeration (0..1)

*TODO: finish this as things solidify*

### dependencies

#### javascript

* global (system) level:
    * node
    * npm
    * bower
    * coffee-script
    * electron

for global dependencies on OSX:

```
brew install node
npm install -g coffee-script electron bower
```

for everything else:

```
npm install
bower install
```

build on osx:

```
./make.sh
```

run:

```
electron .
```

#### max

* [odot](https://github.com/CNMAT/CNMAT-odot/releases)
* ~~[vbap](http://legacy.spa.aalto.fi/software/vbap/MAX_MSP/VBAP_v_1.03_OSXunivers_windows/)~~ -- replaced by own audio-rate implementation
* [HISSTools](http://www.thehiss.org) -- [paper and externals link](http://eprints.hud.ac.uk/14897/)
* [HRTF impulse responses](http://sound.media.mit.edu/resources/KEMAR.html)


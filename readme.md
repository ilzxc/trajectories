# trajectories
## spatial approach to rhythmic contours

This repository contains:

* electron app for path authoring
* max patch for applying the movement to a set of audio files

Electron app: visual indication of paths (trajectories) and dynamics of motion (rests, accelerations).
Trajectories exports:

* `doppler.wav` -- results of doppler data computation
* `distance.wav` -- results of distance levels computation
* `to be determined` -- results of x/y spatialization for HRTF rendering

*TODO: finish this as things solidify*

### dependencies

#### javascript

* global (system) level:
    * node
    * npm
    * bower
    * coffee-script
    * electron
* app level:
    * paper.js -- via bower
    * osc

for global dependencies on OSX:

```
brew install node
npm install -g node-gyp coffee-script electron bower
```

for everything else:

```
npm install
bower install
```

building:

```
./make.sh
```

#### max

* [odot](https://github.com/CNMAT/CNMAT-odot/releases)
* [vbap](http://legacy.spa.aalto.fi/software/vbap/MAX_MSP/VBAP_v_1.03_OSXunivers_windows/)
* [HISSTools]() -- [paper and externals link](http://eprints.hud.ac.uk/14897/)
* [HRTF impulse responses](http://sound.media.mit.edu/resources/KEMAR.html)


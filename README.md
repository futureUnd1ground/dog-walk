# Dog Walk

An AngelOS plugin for tracking dog walks. It provides a desktop widget and a
bar button with start, pause, resume, and finish controls. Elapsed time is
stored in the plugin settings, and distance is estimated from elapsed time at
4.5 km/h. No external program or network connection is required.

## Install for development

Copy this directory to `~/.config/angelos/plugins/dog-walk/`, then reload
AngelOS and enable **Dog Walk** in **Settings -> Plugins**. Add the desktop
widget or enable its bar widget from the plugin settings.

Distance is an estimate, not GPS tracking. Finished walk time and estimated
distance are kept as the last walk summary.

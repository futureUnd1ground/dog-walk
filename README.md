# Dog Walk

[Русская версия](README.ru.md) | English

A native AngelOS desktop pet inspired by Cat Walk. The pixel dog continuously
walks across its desktop widget, turns at the edges, occasionally naps, and
reacts to a double-click. Its pace and step animation speed up as CPU load rises. A
live `CPU xx%` reading is shown on the widget. Double-click the desktop widget
with the left mouse button to throw a ball; the dog fetches it and returns to its walk. A
small animated dog is also available in the panel.

## Use

Install the plugin through Community Store and reload AngelOS. The enabled plugin
adds one desktop pet automatically (without duplicating an existing instance).
Move it by dragging its host title bar. Enable or disable naps, labels, speed,
and base speed in **Settings -> Plugins -> Dog Walk**. CPU load scales that base
speed from a stroll to a run.

## Motion, play, and appearance

Movement follows animation frames and elapsed time, so its pace stays consistent
across monitor refresh rates. Motion and sprite animation pause when hidden or
when AngelOS locks the screen. Fetching takes priority over naps; the dog carries
the ball home, and resizing the widget keeps the dog and its targets inside.

Set **Fur color (#RRGGBB)** in the plugin settings and press Enter to apply it.
Invalid colors are rejected. Existing size, speed, and nap settings are kept.
The frame animation requires Qt 6.4 or newer.

Regression checks: with Python 3 and Qt 6 QtTest installed, run
`python3 -m unittest discover -s tests -v`. Set `QMLTESTRUNNER` if Qt 6's test
runner is installed outside `/usr/lib/qt6/bin`. These checks execute the real
pet components offscreen with AngelOS service doubles; they do not install or
restart the desktop plugin.

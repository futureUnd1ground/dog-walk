"""Exercise production pet QML offscreen with small AngelOS doubles."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
RUNNER = os.environ.get('QMLTESTRUNNER') or shutil.which('qmltestrunner6') or '/usr/lib/qt6/bin/qmltestrunner'


@unittest.skipUnless(Path(RUNNER).exists(), 'Qt 6 qmltestrunner is required')
class PetTests(unittest.TestCase):
    def test_pet_behaviour(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            def write(path, body):
                dest = root / path
                dest.parent.mkdir(parents=True, exist_ok=True)
                dest.write_text(body)
            for name in ['DesktopWidget.qml', 'DogSprite.qml', 'Settings.qml', 'DogFrames.js', 'PetLogic.js']:
                text = (ROOT / name).read_text()
                if name == 'DesktopWidget.qml':
                    text = text.replace('FrameAnimation {', 'FrameAnimation {\n        objectName: "motion"', 1)
                    text = text.replace('id: ballFlight', 'id: ballFlight\n        objectName: "flight"', 1)
                    text = text.replace('id: dog', 'id: dog\n        objectName: "dog"', 1)
                    text = text.replace('visible: root.faceLayer && root.ballVisible', 'objectName: "ball"\n        visible: root.faceLayer && root.ballVisible', 1)
                if name == 'Settings.qml':
                    text = text.replace('PxField {', 'PxField {\n                objectName: "furField"', 1)
                write(name, text)
            write('qmldir', 'singleton Cpu 1.0 Cpu.qml\n')
            write('Cpu.qml', 'pragma Singleton\nimport QtQuick\nQtObject { property real percent: 0 }')
            write('imports/qs/config/qmldir', 'module qs.config\nsingleton Theme 1.0 Theme.qml\nsingleton I18n 1.0 I18n.qml\n')
            write('imports/qs/config/Theme.qml', '''pragma Singleton
import QtQuick
QtObject {
    property int u: 2
    property color accent: "blue"
    property color accent2: "yellow"
    property color accent4: "green"
    property color text: "black"
    property color danger: "red"
    property color edge: "black"
}''')
            write('imports/qs/config/I18n.qml', 'pragma Singleton\nimport QtQuick\nQtObject { function t(ru, en) { return en } }')
            write('imports/qs/services/qmldir', 'module qs.services\nsingleton Shell 1.0 Shell.qml\n')
            write('imports/qs/services/Shell.qml', 'pragma Singleton\nimport QtQuick\nQtObject { property bool locked: false }')
            widgets = {
                'PxText': 'Text { property bool dim; property string kind }',
                'PxIcon': '''Item { property int pixel: 2; property var bitmap: []
                    property color body; property color fill; property color fill2; property color fill3
                    property color light; property var palette
                    width: 16 * pixel; height: bitmap.length * pixel }''',
                'PxGroup': 'Column { property string title; property string icon }',
                'SettingRow': 'Row { property string label }',
                'PxField': 'Item { property string text; signal accepted() }',
                'PxSegmented': 'Item { property var model; property var currentValue; signal activated(var value) }',
                'PxSlider': 'Item { property real from; property real to; property real stepSize; property real value; property string suffix; signal released(var value) }',
                'PxToggle': 'Item { property bool checked; signal toggled(bool value) }',
            }
            write('imports/qs/widgets/qmldir', 'module qs.widgets\n' + ''.join(f'{name} 1.0 {name}.qml\n' for name in widgets))
            for name, body in widgets.items():
                write(f'imports/qs/widgets/{name}.qml', 'import QtQuick\n' + body)
            write('tst_pet.qml', '''import QtQuick
import QtTest
import qs.services
import "." as Pet
TestCase {
    name: "DogWalk"
    when: windowShown
    visible: true
    width: 500; height: 300
    property var pet
    QtObject {
        id: context
        property var settings: ({})
        function get(key, fallback) { return settings[key] === undefined ? fallback : settings[key] }
        function set(key, value) { settings = Object.assign({}, settings, {[key]: value}) }
    }
    Component { id: desktop; Pet.DesktopWidget {} }
    Component { id: preferences; Pet.Settings {} }
    function init() {
        Shell.locked = false
        context.settings = {}
        pet = createTemporaryObject(desktop, this, {plugin: context, width: 360, height: 112})
        verify(pet !== null)
        findChild(pet, "motion").paused = true
    }
    function test_speed_independent_of_refresh_rate() {
        pet.dogX = 50
        for (let i = 0; i < 25; ++i) pet.advance(1/25)
        const slow = pet.dogX
        pet.dogX = 50
        for (let i = 0; i < 144; ++i) pet.advance(1/144)
        verify(Math.abs(pet.dogX - slow) < 0.00001)
    }
    function test_fetch_finishes_and_does_not_nap() {
        pet.dogX = 50
        pet.startFetch(180)
        compare(pet.playState, "throw")
        pet.beginNap()
        verify(!pet.sleepy)
        findChild(pet, "flight").complete()
        compare(pet.playState, "fetch")
        for (let i = 0; i < 400 && pet.playState !== "idle"; ++i) pet.advance(0.1)
        compare(pet.playState, "idle")
        compare(pet.dogX, 50)
        verify(!pet.ballVisible)
        verify(!pet.excited)
    }
    function test_arc_uses_finite_progress_and_ball_is_carried() {
        pet.startFetch(180)
        const flight = findChild(pet, "flight")
        flight.paused = true
        pet.flightProgress = 0.5
        const ball = findChild(pet, "ball")
        verify(Number.isFinite(ball.x))
        verify(Number.isFinite(ball.y))
        const middle = ball.y
        pet.flightProgress = 0
        verify(middle < ball.y)
        flight.complete()
        pet.playState = "return"
        pet.direction = 1
        verify(pet.ballVisible)
        compare(pet.ballX, pet.dogX + findChild(pet, "dog").width)
    }
    function test_resize_during_fetch_stays_inside_and_completes() {
        pet.dogX = 250
        pet.startFetch(300)
        findChild(pet, "flight").complete()
        pet.width = 100
        verify(pet.dogX <= pet.maxX)
        verify(pet.homeX <= pet.maxX)
        for (let i = 0; i < 400 && pet.playState !== "idle"; ++i) pet.advance(0.1)
        compare(pet.playState, "idle")
        pet.width = 10
        compare(pet.dogX, 0)
        verify(Number.isFinite(pet.ballX))
    }
    function test_lock_and_hidden_widget_pause_motion() {
        pet.dogX = 50
        Shell.locked = true
        verify(!findChild(pet, "motion").running)
        pet.advance(0.1)
        compare(pet.dogX, 50)
        Shell.locked = false
        pet.visible = false
        pet.advance(0.1)
        compare(pet.dogX, 50)
        pet.visible = true
        pet.startFetch(180)
        Shell.locked = true
        verify(findChild(pet, "flight").paused)
    }
    function test_command_timestamp_is_not_truncated_or_replayed() {
        context.set("playTargetX", 180)
        context.set("playCommandId", 1791200000000)
        compare(pet.seenPlayCommand, 1791200000000)
        compare(pet.playState, "throw")
        findChild(pet, "flight").complete()
        pet.playState = "idle"
        pet.consumePlayCommand()
        compare(pet.playState, "idle")
    }
    function test_corrupt_settings_and_invalid_color_are_safe() {
        context.set("size", "broken")
        context.set("speed", "broken")
        context.set("fur", "bad")
        compare(pet.dogSize, 2)
        compare(pet.baseSpeed, 1)
        compare(findChild(pet, "dog").fur, "#c9824a")
        const page = createTemporaryObject(preferences, this, {plugin: context})
        verify(page !== null)
        const field = findChild(page, "furField")
        field.text = "#345678"
        field.accepted()
        compare(context.get("fur", ""), "#345678")
        field.text = "wrong"
        field.accepted()
        verify(page.invalidColor)
        compare(context.get("fur", ""), "#345678")
    }
    function test_disable_naps_wakes_dog() {
        pet.beginNap()
        verify(pet.sleepy)
        context.set("nap", false)
        verify(!pet.sleepy)
    }
}''')
            result = subprocess.run([RUNNER, '-input', str(root), '-import', str(root / 'imports')],
                env={**os.environ, 'QT_QPA_PLATFORM': 'offscreen', 'QT_QPA_PLATFORMTHEME': '', 'QT_QUICK_BACKEND': 'software', 'QT_FORCE_STDERR_LOGGING': '1', 'QT_LOGGING_TO_CONSOLE': '1'},
                capture_output=True, text=True, timeout=30)
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)


if __name__ == '__main__':
    unittest.main()

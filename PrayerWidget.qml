import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.Plugins

PluginComponent {
    id: root

    property string prayerInfo: "..."
    property string fajr: ""
    property string dhuhr: ""
    property string asr: ""
    property string maghrib: ""
    property string isha: ""
    property string dateHijr: ""
    property string dateGreg: ""
    // property int refreshInterval: root.pluginData.refreshInterval * 1000 || 300000 // in seconds
    // property int refreshInterval: Number(root.pluginData.refreshInterval) * 60000 || 300000 // in minutes
    property int refreshInterval: (Number(root.pluginData.refreshInterval) || 5) * 60000 // in minutes
    property string lat: root.pluginData.lat || "-6.2088"
    property string lon: root.pluginData.lon || "106.8456"
    property string scriptPath: Qt.resolvedUrl("get-prayer-times").toString().replace("file://", "")

    Process {
        id: prayerProcess
        command: ["bash", root.scriptPath, root.lat, root.lon]
        running: false

        stdout: SplitParser {
            onRead: data => {
                root.prayerInfo = data.trim();
            }
        }
        
        onRunningChanged: {
            if (!running) {
                console.log("Prayer times updated: ", root.prayerInfo);
            }
        }
    }

    Timer {
        interval: root.refreshInterval
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            prayerProcess.running = true;
        }
    }

    FileView {
        id: jsonFile
        path: Qt.resolvedUrl("prayer_times.json").toString().replace("file://", "")
        // Forces the file to be loaded by the time we call JSON.parse().
        // see blockLoading's property documentation for details.
        blockLoading: true
        onDataChanged: {
            try {
                var data = JSON.parse(jsonFile.text())
                var t = data.data.timings
                root.fajr = t.Fajr
                root.dhuhr = t.Dhuhr
                root.asr = t.Asr
                root.maghrib = t.Maghrib
                root.isha = t.Isha

                var d = data.data.date
                root.dateGreg = d.readable
                root.dateHijr = `${d.hijri.day} ${d.hijri.month.en} ${d.hijri.year}`
            } catch (e) {
                root.fajr = "waduh"
                prayerProcess.running = true;
                console.log("JSON error:", e)
            }
        }
    }

    popoutContent: Component {
        Column {
            id: prayerPopup

            // width: 50
            spacing: Theme.spacingS
            padding: Theme.spacingM

            StyledText { text: "🗓️ Hijri: " + root.dateHijr }
            StyledText { text: "🗓️ Gregorian: " + root.dateGreg }
            StyledText { text: "🌅 Fajr: " + root.fajr }
            StyledText { text: "☀️ Dhuhr: " + root.dhuhr }
            StyledText { text: "🌤️ Asr: " + root.asr }
            StyledText { text: "🌇 Maghrib: " + root.maghrib }
            StyledText { text: "🌙 Isha: " + root.isha }
        }
    }

    horizontalBarPill: Component {
        Row {
            spacing: Theme.spacingXS
            rightPadding: Theme.spacingS

            StyledText {
                text: "🕌 "
                font.pixelSize: Theme.fontSizeMedium
                color: Theme.surfaceText
                anchors.verticalCenter: parent.verticalCenter
            }

            StyledText {
                text: root.prayerInfo
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceText
                anchors.verticalCenter: parent.verticalCenter
            }

            MouseArea {
                onClicked: {
                    // loadPrayerData(() => { prayerPopup.open(); });
                    // jsonFile.read();
                    // prayerPopup.open();
                }
            }
        }
    }

    verticalBarPill: Component {
        Rectangle {
            color: Theme.surface
            border.color: Theme.surfaceText
            border.width: 1
            radius: Theme.spacingXS

            Column {
                spacing: Theme.spacingXS
                anchors.fill: parent
                anchors.margins: Theme.spacingXS

                StyledText {
                    text: "🕌 "
                    font.pixelSize: Theme.fontSizeMedium
                    color: Theme.surfaceText
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                StyledText {
                    text: root.prayerInfo
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceText
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                MouseArea {
                    // anchors.fill: parent
                    // onClicked: {
                    //     loadPrayerData(() => { prayerPopup.open(); });
                    // }
                }
            }
        }
    }
}
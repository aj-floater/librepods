pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2

import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.extras as PlasmaExtras
import org.kde.plasma.plasmoid

PlasmaExtras.Representation {
    id: root

    required property PlasmoidItem plasmoidItem

    property int selectedNoiseControlMode: -1
    property int currentTab: 0

    function batteryDisplay(level, charging) {
        const numeric = Number(level)
        if (!Number.isFinite(numeric) || numeric < 0) {
            return "--"
        }
        const percent = Math.round(numeric) + "%"
        return charging ? percent + " (Charging)" : percent
    }

    function ensureSelectedNoiseControlMode() {
        if (selectedNoiseControlMode >= 0) {
            return
        }
        const mode = Number(plasmoidItem.status.noiseControlMode)
        selectedNoiseControlMode = Number.isFinite(mode) ? mode : 0
    }

    function openSettingsTab() {
        currentTab = 1
    }

    implicitWidth: Kirigami.Units.gridUnit * 24
    implicitHeight: Math.max(
        Kirigami.Units.gridUnit * 10,
        (headerBar ? headerBar.implicitHeight : 0) + (contentContainer ? contentContainer.implicitHeight : 0))
    Layout.minimumWidth: Kirigami.Units.gridUnit * 22
    Layout.maximumWidth: Kirigami.Units.gridUnit * 28
    Layout.minimumHeight: Kirigami.Units.gridUnit * 10
    Layout.maximumHeight: implicitHeight
    focus: true
    collapseMarginsHint: true

    Component.onCompleted: ensureSelectedNoiseControlMode()

    Connections {
        target: plasmoidItem
        function onStatusChanged() {
            root.ensureSelectedNoiseControlMode()
        }
    }

    header: PlasmaExtras.PlasmoidHeading {
        id: headerBar
        leftPadding: mirrored ? 0 : Kirigami.Units.smallSpacing
        rightPadding: mirrored ? Kirigami.Units.smallSpacing : 0

        contentItem: RowLayout {
            spacing: Kirigami.Units.smallSpacing

            PlasmaComponents3.Label {
                text: i18n("LibrePods")
                font.weight: Font.DemiBold
                Layout.fillWidth: true
                elide: Text.ElideRight
            }

            PlasmaComponents3.ToolButton {
                visible: !(Plasmoid.containmentDisplayHints & PlasmaCore.Types.ContainmentDrawsPlasmoidHeading)
                icon.name: "window-new-symbolic"
                display: PlasmaComponents3.AbstractButton.IconOnly
                onClicked: plasmoidItem.callBackend("OpenPage", ["app"], null, null)
                PlasmaComponents3.ToolTip {
                    text: i18n("Open Full App")
                }
            }
        }
    }

    Item {
        id: contentContainer
        anchors.fill: parent
        implicitHeight: contentColumn.implicitHeight + (Kirigami.Units.largeSpacing * 2)

        ColumnLayout {
            id: contentColumn
            anchors.fill: parent
            anchors.margins: Kirigami.Units.largeSpacing
            spacing: Kirigami.Units.largeSpacing

            PlasmaComponents3.TabBar {
                id: tabBar
                Layout.fillWidth: true
                currentIndex: root.currentTab
                onCurrentIndexChanged: root.currentTab = currentIndex

                PlasmaComponents3.TabButton {
                    text: i18n("Controls")
                }

                PlasmaComponents3.TabButton {
                    text: i18n("Settings")
                }
            }

            StackLayout {
                id: pageStack
                currentIndex: root.currentTab
                Layout.fillWidth: true
                Layout.fillHeight: true
                implicitHeight: currentItem ? currentItem.implicitHeight : 0

                Item {
                    id: controlsPage
                    implicitHeight: controlsColumn.implicitHeight

                    ColumnLayout {
                        id: controlsColumn
                        anchors.fill: parent
                        spacing: Kirigami.Units.largeSpacing

                        PlasmaComponents3.Label {
                            Layout.fillWidth: true
                            text: plasmoidItem.backendAvailable
                                ? (plasmoidItem.status.connected
                                   ? i18n("%1 connected", plasmoidItem.status.deviceName !== "" ? plasmoidItem.status.deviceName : "AirPods")
                                   : i18n("No AirPods connected"))
                                : i18n("Waiting for backend…")
                            horizontalAlignment: Text.AlignHCenter
                            color: plasmoidItem.status.connected ? Kirigami.Theme.positiveTextColor : Kirigami.Theme.textColor
                            wrapMode: Text.WordWrap
                        }

                        RowLayout {
                            id: primaryPodsRow
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            Layout.preferredHeight: Kirigami.Units.gridUnit * 5
                            Layout.minimumHeight: Kirigami.Units.gridUnit * 4
                            spacing: Kirigami.Units.smallSpacing

                            PlasmaComponents3.Frame {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                Layout.preferredWidth: 1
                                Layout.minimumWidth: 0
                                opacity: plasmoidItem.status.leftAvailable ? 1.0 : 0.6

                                contentItem: ColumnLayout {
                                    spacing: Kirigami.Units.smallSpacing

                                    Kirigami.Icon {
                                        source: "audio-headphones-symbolic"
                                        implicitWidth: Kirigami.Units.iconSizes.smallMedium
                                        implicitHeight: Kirigami.Units.iconSizes.smallMedium
                                        Layout.alignment: Qt.AlignHCenter
                                    }

                                    PlasmaComponents3.Label {
                                        text: i18n("Left")
                                        font.weight: Font.Medium
                                        Layout.fillWidth: true
                                        horizontalAlignment: Text.AlignHCenter
                                    }

                                    PlasmaComponents3.Label {
                                        text: plasmoidItem.status.leftAvailable
                                            ? root.batteryDisplay(plasmoidItem.status.leftBattery, plasmoidItem.status.leftCharging)
                                            : "--"
                                        Layout.fillWidth: true
                                        horizontalAlignment: Text.AlignHCenter
                                    }
                                }
                            }

                            PlasmaComponents3.Frame {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                Layout.preferredWidth: 1
                                Layout.minimumWidth: 0
                                opacity: plasmoidItem.status.rightAvailable ? 1.0 : 0.6

                                contentItem: ColumnLayout {
                                    spacing: Kirigami.Units.smallSpacing

                                    Kirigami.Icon {
                                        source: "audio-headphones-symbolic"
                                        implicitWidth: Kirigami.Units.iconSizes.smallMedium
                                        implicitHeight: Kirigami.Units.iconSizes.smallMedium
                                        Layout.alignment: Qt.AlignHCenter
                                    }

                                    PlasmaComponents3.Label {
                                        text: i18n("Right")
                                        font.weight: Font.Medium
                                        Layout.fillWidth: true
                                        horizontalAlignment: Text.AlignHCenter
                                    }

                                    PlasmaComponents3.Label {
                                        text: plasmoidItem.status.rightAvailable
                                            ? root.batteryDisplay(plasmoidItem.status.rightBattery, plasmoidItem.status.rightCharging)
                                            : "--"
                                        Layout.fillWidth: true
                                        horizontalAlignment: Text.AlignHCenter
                                    }
                                }
                            }
                        }

                        RowLayout {
                            id: secondaryPodsRow
                            visible: plasmoidItem.status.caseAvailable || plasmoidItem.status.headsetAvailable
                            Layout.fillWidth: true
                            spacing: Kirigami.Units.smallSpacing

                            PlasmaComponents3.Frame {
                                visible: plasmoidItem.status.caseAvailable
                                Layout.fillWidth: true
                                Layout.preferredWidth: 1
                                Layout.minimumWidth: 0

                                contentItem: ColumnLayout {
                                    spacing: Kirigami.Units.smallSpacing

                                    Kirigami.Icon {
                                        source: "battery-symbolic"
                                        implicitWidth: Kirigami.Units.iconSizes.smallMedium
                                        implicitHeight: Kirigami.Units.iconSizes.smallMedium
                                        Layout.alignment: Qt.AlignHCenter
                                    }

                                    PlasmaComponents3.Label {
                                        text: i18n("Case")
                                        font.weight: Font.Medium
                                        Layout.fillWidth: true
                                        horizontalAlignment: Text.AlignHCenter
                                    }

                                    PlasmaComponents3.Label {
                                        text: root.batteryDisplay(plasmoidItem.status.caseBattery, plasmoidItem.status.caseCharging)
                                        Layout.fillWidth: true
                                        horizontalAlignment: Text.AlignHCenter
                                    }
                                }
                            }

                            PlasmaComponents3.Frame {
                                visible: plasmoidItem.status.headsetAvailable
                                Layout.fillWidth: true
                                Layout.preferredWidth: 1
                                Layout.minimumWidth: 0

                                contentItem: ColumnLayout {
                                    spacing: Kirigami.Units.smallSpacing

                                    Kirigami.Icon {
                                        source: "audio-headset-symbolic"
                                        implicitWidth: Kirigami.Units.iconSizes.smallMedium
                                        implicitHeight: Kirigami.Units.iconSizes.smallMedium
                                        Layout.alignment: Qt.AlignHCenter
                                    }

                                    PlasmaComponents3.Label {
                                        text: i18n("Headset")
                                        font.weight: Font.Medium
                                        Layout.fillWidth: true
                                        horizontalAlignment: Text.AlignHCenter
                                    }

                                    PlasmaComponents3.Label {
                                        text: root.batteryDisplay(plasmoidItem.status.headsetBattery, plasmoidItem.status.headsetCharging)
                                        Layout.fillWidth: true
                                        horizontalAlignment: Text.AlignHCenter
                                    }
                                }
                            }
                        }

                        PlasmaComponents3.Label {
                            Layout.fillWidth: true
                            text: i18n("Noise Control")
                            font.weight: Font.DemiBold
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Kirigami.Units.smallSpacing
                            enabled: plasmoidItem.status.connected

                            Repeater {
                                model: [
                                    { text: i18n("Off"), value: 0 },
                                    { text: i18n("ANC"), value: 1 },
                                    { text: i18n("Transparency"), value: 2 },
                                    { text: i18n("Adaptive"), value: 3 }
                                ]

                                delegate: PlasmaComponents3.Button {
                                    required property var modelData
                                    Layout.fillWidth: true
                                    text: modelData.text
                                    checkable: true
                                    checked: (root.selectedNoiseControlMode >= 0
                                        ? root.selectedNoiseControlMode
                                        : Number(plasmoidItem.status.noiseControlMode)) === modelData.value
                                    highlighted: checked
                                    onClicked: {
                                        root.selectedNoiseControlMode = modelData.value
                                        plasmoidItem.callBackend("SetNoiseControlMode", [modelData.value], null, null)
                                    }
                                }
                            }
                        }

                        PlasmaComponents3.Switch {
                            Layout.fillWidth: true
                            text: i18n("Conversational Awareness")
                            checked: plasmoidItem.status.conversationalAwareness
                            enabled: plasmoidItem.status.connected
                            onClicked: plasmoidItem.callBackend("SetConversationalAwareness", [checked], null, null)
                        }

                        PlasmaComponents3.Switch {
                            Layout.fillWidth: true
                            text: i18n("Hearing Aid")
                            checked: plasmoidItem.status.hearingAidEnabled
                            enabled: plasmoidItem.status.connected
                            onClicked: plasmoidItem.callBackend("SetHearingAidEnabled", [checked], null, null)
                        }
                    }
                }

                Item {
                    id: settingsPage
                    implicitHeight: settingsColumn.implicitHeight

                    ColumnLayout {
                        id: settingsColumn
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        spacing: Kirigami.Units.largeSpacing

                        PlasmaComponents3.Switch {
                            Layout.fillWidth: true
                            text: i18n("Cross-Device Connectivity")
                            checked: plasmoidItem.status.crossDeviceEnabled
                            onClicked: plasmoidItem.callBackend("SetCrossDeviceEnabled", [checked], null, null)
                        }

                        PlasmaComponents3.Switch {
                            Layout.fillWidth: true
                            text: i18n("One Bud ANC Mode")
                            checked: plasmoidItem.status.oneBudANCMode
                            onClicked: plasmoidItem.callBackend("SetOneBudANCMode", [checked], null, null)
                        }

                        PlasmaComponents3.Switch {
                            Layout.fillWidth: true
                            text: i18n("Enable Notifications")
                            checked: plasmoidItem.status.notificationsEnabled
                            onClicked: plasmoidItem.callBackend("SetNotificationsEnabled", [checked], null, null)
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Kirigami.Units.smallSpacing

                            PlasmaComponents3.Label {
                                text: i18n("Retry Attempts")
                            }

                            PlasmaComponents3.SpinBox {
                                from: 1
                                to: 10
                                value: plasmoidItem.status.retryAttempts
                                onValueModified: plasmoidItem.callBackend("SetRetryAttempts", [value], null, null)
                            }
                        }
                    }
                }
            }
        }
    }
}

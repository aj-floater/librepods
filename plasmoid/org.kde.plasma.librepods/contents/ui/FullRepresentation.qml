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

    implicitWidth: Kirigami.Units.gridUnit * 24
    implicitHeight: Kirigami.Units.gridUnit * 24
    Layout.minimumWidth: Kirigami.Units.gridUnit * 22
    Layout.maximumWidth: Kirigami.Units.gridUnit * 28
    Layout.minimumHeight: Kirigami.Units.gridUnit * 18
    Layout.maximumHeight: Kirigami.Units.gridUnit * 34
    focus: true
    collapseMarginsHint: true

    header: PlasmaExtras.PlasmoidHeading {
        leftPadding: mirrored ? 0 : Kirigami.Units.smallSpacing
        rightPadding: mirrored ? Kirigami.Units.smallSpacing : 0

        contentItem: RowLayout {
            spacing: Kirigami.Units.smallSpacing

            PlasmaComponents3.ToolButton {
                visible: stackView.depth > 1
                icon.name: "go-previous-symbolic"
                display: PlasmaComponents3.AbstractButton.IconOnly
                onClicked: stackView.pop()
                PlasmaComponents3.ToolTip {
                    text: i18n("Back")
                }
            }

            PlasmaComponents3.Label {
                text: stackView.depth > 1 ? i18n("Settings") : i18n("LibrePods")
                font.weight: Font.DemiBold
                Layout.fillWidth: true
                elide: Text.ElideRight
            }

            PlasmaComponents3.ToolButton {
                visible: stackView.depth === 1 && !(Plasmoid.containmentDisplayHints & PlasmaCore.Types.ContainmentDrawsPlasmoidHeading)
                icon.name: "configure-symbolic"
                display: PlasmaComponents3.AbstractButton.IconOnly
                onClicked: stackView.push(settingsPage)
                PlasmaComponents3.ToolTip {
                    text: i18n("Settings")
                }
            }
        }
    }

    QQC2.StackView {
        id: stackView
        anchors.fill: parent
        initialItem: mainPage
    }

    Component {
        id: mainPage

        PlasmaComponents3.ScrollView {
            contentWidth: availableWidth

            ColumnLayout {
                width: parent.width
                spacing: Kirigami.Units.largeSpacing
                leftPadding: Kirigami.Units.largeSpacing
                rightPadding: Kirigami.Units.largeSpacing
                topPadding: Kirigami.Units.largeSpacing
                bottomPadding: Kirigami.Units.largeSpacing

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

                GridLayout {
                    Layout.fillWidth: true
                    columns: 2
                    columnSpacing: Kirigami.Units.smallSpacing
                    rowSpacing: Kirigami.Units.smallSpacing

                    Repeater {
                        model: [
                            {
                                label: i18n("Left"),
                                available: plasmoidItem.status.leftAvailable,
                                level: plasmoidItem.status.leftBattery,
                                charging: plasmoidItem.status.leftCharging
                            },
                            {
                                label: i18n("Right"),
                                available: plasmoidItem.status.rightAvailable,
                                level: plasmoidItem.status.rightBattery,
                                charging: plasmoidItem.status.rightCharging
                            },
                            {
                                label: i18n("Case"),
                                available: plasmoidItem.status.caseAvailable,
                                level: plasmoidItem.status.caseBattery,
                                charging: plasmoidItem.status.caseCharging
                            },
                            {
                                label: i18n("Headset"),
                                available: plasmoidItem.status.headsetAvailable,
                                level: plasmoidItem.status.headsetBattery,
                                charging: plasmoidItem.status.headsetCharging
                            }
                        ]

                        delegate: PlasmaComponents3.Frame {
                            required property var modelData
                            visible: modelData.available
                            Layout.fillWidth: true

                            contentItem: ColumnLayout {
                                spacing: Kirigami.Units.smallSpacing
                                PlasmaComponents3.Label {
                                    text: modelData.label
                                    font.weight: Font.Medium
                                }
                                PlasmaComponents3.Label {
                                    text: modelData.charging
                                        ? i18n("%1% (Charging)", modelData.level)
                                        : i18n("%1%", modelData.level)
                                }
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
                            checked: plasmoidItem.status.noiseControlMode === modelData.value
                            onClicked: plasmoidItem.callBackend("SetNoiseControlMode", [modelData.value], null, null)
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

                PlasmaComponents3.Button {
                    Layout.alignment: Qt.AlignHCenter
                    text: i18n("Open Full App")
                    icon.name: "window-symbolic"
                    onClicked: plasmoidItem.callBackend("OpenPage", ["app"], null, null)
                }
            }
        }
    }

    Component {
        id: settingsPage

        PlasmaComponents3.ScrollView {
            contentWidth: availableWidth

            ColumnLayout {
                width: parent.width
                spacing: Kirigami.Units.largeSpacing
                leftPadding: Kirigami.Units.largeSpacing
                rightPadding: Kirigami.Units.largeSpacing
                topPadding: Kirigami.Units.largeSpacing
                bottomPadding: Kirigami.Units.largeSpacing

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

                PlasmaComponents3.Button {
                    Layout.alignment: Qt.AlignHCenter
                    text: i18n("Open Advanced Settings")
                    icon.name: "settings-configure"
                    onClicked: plasmoidItem.callBackend("OpenPage", ["settings"], null, null)
                }
            }
        }
    }
}

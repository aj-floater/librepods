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

    function podImageSource() {
        const iconName = plasmoidItem.status.podIcon ? plasmoidItem.status.podIcon : "pod.png"
        return Qt.resolvedUrl("../images/" + iconName)
    }

    function resolvedCaseIconName() {
        const model = Number(plasmoidItem.status.model)
        if (Number.isFinite(model)) {
            switch (model) {
            case 1:
            case 2:
                return "pod_case.png"
            case 3:
                return "pod3_case.png"
            case 4:
            case 5:
            case 6:
                return "podpro_case.png"
            case 7:
            case 8:
                return "podmax.png"
            case 9:
            case 10:
                return "pod4_case.png"
            default:
                break
            }
        }

        const backendIcon = plasmoidItem.status.caseIcon
        if (backendIcon && backendIcon !== "max_case.png") {
            return backendIcon
        }

        const podIcon = plasmoidItem.status.podIcon ? plasmoidItem.status.podIcon : "pod.png"
        if (podIcon === "podpro.png") {
            return "podpro_case.png"
        }
        if (podIcon === "pod3.png") {
            return "pod3_case.png"
        }
        if (podIcon === "podmax.png") {
            return "podmax.png"
        }

        return "pod_case.png"
    }

    function caseImageSource() {
        return Qt.resolvedUrl("../images/" + resolvedCaseIconName())
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

                        PlasmaComponents3.Frame {
                            id: batteryPanel
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            Layout.preferredHeight: Kirigami.Units.gridUnit * 7
                            Layout.minimumHeight: Kirigami.Units.gridUnit * 5

                            contentItem: ColumnLayout {
                                spacing: Kirigami.Units.smallSpacing

                                RowLayout {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    spacing: Kirigami.Units.smallSpacing

                                    Item {
                                        Layout.fillWidth: true
                                        Layout.preferredWidth: 1
                                        Layout.minimumWidth: 0
                                        Layout.fillHeight: true
                                        Layout.minimumHeight: Kirigami.Units.gridUnit * 2.5
                                        opacity: plasmoidItem.status.leftAvailable ? 1.0 : 0.6

                                        Image {
                                            source: root.podImageSource()
                                            width: Kirigami.Units.gridUnit * 4.8
                                            height: Kirigami.Units.gridUnit * 2.88
                                            fillMode: Image.PreserveAspectFit
                                            mipmap: true
                                            anchors.centerIn: parent
                                        }
                                    }

                                    Item {
                                        Layout.fillWidth: true
                                        Layout.preferredWidth: 1
                                        Layout.minimumWidth: 0
                                        Layout.fillHeight: true
                                        Layout.minimumHeight: Kirigami.Units.gridUnit * 2.5
                                        opacity: plasmoidItem.status.rightAvailable ? 1.0 : 0.6

                                        Image {
                                            source: root.podImageSource()
                                            width: Kirigami.Units.gridUnit * 4.8
                                            height: Kirigami.Units.gridUnit * 2.88
                                            fillMode: Image.PreserveAspectFit
                                            mipmap: true
                                            mirror: true
                                            anchors.centerIn: parent
                                        }
                                    }

                                    Item {
                                        visible: plasmoidItem.status.caseAvailable || plasmoidItem.status.headsetAvailable
                                        Layout.fillWidth: true
                                        Layout.preferredWidth: 1
                                        Layout.minimumWidth: 0
                                        Layout.fillHeight: true
                                        Layout.minimumHeight: Kirigami.Units.gridUnit * 2.5

                                        Image {
                                            visible: plasmoidItem.status.caseAvailable
                                            source: root.caseImageSource()
                                            width: Kirigami.Units.gridUnit * 3.0
                                            height: Kirigami.Units.gridUnit * 1.9
                                            fillMode: Image.PreserveAspectFit
                                            mipmap: true
                                            anchors.centerIn: parent
                                        }

                                        Kirigami.Icon {
                                            visible: !plasmoidItem.status.caseAvailable
                                            source: "audio-headset-symbolic"
                                            implicitWidth: Kirigami.Units.iconSizes.smallMedium
                                            implicitHeight: Kirigami.Units.iconSizes.smallMedium
                                            anchors.centerIn: parent
                                        }
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: Kirigami.Units.gridUnit * 1.4
                                    Layout.minimumHeight: Kirigami.Units.gridUnit * 1.2
                                    spacing: Kirigami.Units.smallSpacing

                                    PlasmaComponents3.Label {
                                        Layout.fillWidth: true
                                        Layout.preferredWidth: 1
                                        Layout.minimumWidth: 0
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                        elide: Text.ElideRight
                                        font.weight: Font.Medium
                                        text: plasmoidItem.status.leftAvailable
                                            ? i18n("Left %1", root.batteryDisplay(plasmoidItem.status.leftBattery, plasmoidItem.status.leftCharging))
                                            : i18n("Left --")
                                    }

                                    PlasmaComponents3.Label {
                                        Layout.fillWidth: true
                                        Layout.preferredWidth: 1
                                        Layout.minimumWidth: 0
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                        elide: Text.ElideRight
                                        font.weight: Font.Medium
                                        text: plasmoidItem.status.rightAvailable
                                            ? i18n("Right %1", root.batteryDisplay(plasmoidItem.status.rightBattery, plasmoidItem.status.rightCharging))
                                            : i18n("Right --")
                                    }

                                    PlasmaComponents3.Label {
                                        visible: plasmoidItem.status.caseAvailable || plasmoidItem.status.headsetAvailable
                                        Layout.fillWidth: true
                                        Layout.preferredWidth: 1
                                        Layout.minimumWidth: 0
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                        elide: Text.ElideRight
                                        font.weight: Font.Medium
                                        text: plasmoidItem.status.caseAvailable
                                            ? i18n("Case %1", root.batteryDisplay(plasmoidItem.status.caseBattery, plasmoidItem.status.caseCharging))
                                            : i18n("Headset %1", root.batteryDisplay(plasmoidItem.status.headsetBattery, plasmoidItem.status.headsetCharging))
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

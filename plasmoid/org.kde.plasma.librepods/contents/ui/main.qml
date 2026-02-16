pragma ComponentBehavior: Bound

import QtQuick

import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import org.kde.plasma.workspace.dbus as DBus

PlasmoidItem {
    id: root

    readonly property string serviceName: "me.kavishdevar.librepods"
    readonly property string objectPath: "/me/kavishdevar/librepods"
    readonly property string interfaceName: "me.kavishdevar.librepods"

    property bool backendAvailable: false
    property string backendError: ""
    property var status: ({
        connected: false,
        deviceName: "",
        model: 0,
        podIcon: "pod.png",
        caseIcon: "pod_case.png",
        noiseControlMode: 0,
        adaptiveNoiseLevel: 50,
        conversationalAwareness: false,
        hearingAidEnabled: false,
        oneBudANCMode: false,
        crossDeviceEnabled: false,
        notificationsEnabled: true,
        retryAttempts: 3,
        leftBattery: 0,
        rightBattery: 0,
        caseBattery: 0,
        headsetBattery: 0,
        leftCharging: false,
        rightCharging: false,
        caseCharging: false,
        headsetCharging: false,
        leftAvailable: false,
        rightAvailable: false,
        caseAvailable: false,
        headsetAvailable: false
    })

    readonly property int lowestBatteryLevel: {
        const levels = []
        if (status.leftAvailable) {
            levels.push(status.leftBattery)
        }
        if (status.rightAvailable) {
            levels.push(status.rightBattery)
        }
        if (status.caseAvailable) {
            levels.push(status.caseBattery)
        }
        if (status.headsetAvailable) {
            levels.push(status.headsetBattery)
        }
        if (levels.length === 0) {
            return -1
        }
        return Math.min.apply(Math, levels)
    }

    switchWidth: Kirigami.Units.gridUnit * 15
    switchHeight: Kirigami.Units.gridUnit * 10

    fullRepresentation: FullRepresentation {
        plasmoidItem: root
    }

    Plasmoid.contextualActions: [
        PlasmaCore.Action {
            id: openWindowAction
            text: i18n("Open LibrePods")
            icon.name: "window-new-symbolic"
            onTriggered: root.callBackend("OpenPage", ["app"], null, null)
        }
    ]

    Plasmoid.status: status.connected ? PlasmaCore.Types.ActiveStatus : PlasmaCore.Types.PassiveStatus
    Plasmoid.icon: status.connected ? "audio-headset-symbolic" : "audio-headphones-symbolic"
    Plasmoid.title: i18n("LibrePods")
    toolTipMainText: i18n("LibrePods")
    toolTipSubText: {
        if (!backendAvailable) {
            return i18n("Backend unavailable")
        }
        if (status.connected) {
            const name = status.deviceName !== "" ? status.deviceName : "AirPods"
            if (lowestBatteryLevel >= 0) {
                return i18n("%1 connected \u00b7 %2% Battery", name, lowestBatteryLevel)
            }
            if (status.deviceName !== "") {
                return i18n("%1 connected", status.deviceName)
            }
            return i18n("AirPods connected")
        }
        return i18n("No AirPods connected")
    }

    DBus.DBusServiceWatcher {
        id: serviceWatcher
        busType: DBus.BusType.Session
        watchedService: root.serviceName
        onRegisteredChanged: {
            root.backendAvailable = registered
            if (registered) {
                root.backendError = ""
                root.refreshStatus()
            }
        }
    }

    DBus.SignalWatcher {
        enabled: serviceWatcher.registered
        busType: DBus.BusType.Session
        service: root.serviceName
        path: root.objectPath
        iface: root.interfaceName
        function onReceivedSignal(message) {
            if (message.member !== "StatusChanged" || message.arguments.length === 0) {
                return
            }
            root.status = Object.assign({}, root.status, message.arguments[0])
        }
    }

    Timer {
        interval: 2500
        running: true
        repeat: true
        onTriggered: root.refreshStatus()
    }

    function callBackend(member, args, onSuccess, onError) {
        var pending = DBus.SessionBus.asyncCall({
            service: serviceName,
            path: objectPath,
            iface: interfaceName,
            member: member,
            arguments: args ? args : []
        })

        pending.finished.connect(function() {
            if (pending.isError) {
                backendAvailable = false
                backendError = pending.error.message
                if (onError) {
                    onError(pending.error.message)
                }
                return
            }

            backendAvailable = true
            backendError = ""
            if (onSuccess) {
                onSuccess(pending.value)
            }
        })
    }

    function ensureBackendStarted() {
        DBus.SessionBus.asyncCall({
            service: "org.freedesktop.DBus",
            path: "/org/freedesktop/DBus",
            iface: "org.freedesktop.DBus",
            member: "StartServiceByName",
            arguments: [serviceName, 0]
        })
    }

    function refreshStatus() {
        callBackend("GetStatus", [], function(value) {
            if (value) {
                status = Object.assign({}, status, value)
            }
        }, function() {
            ensureBackendStarted()
        })
    }

    Component.onCompleted: {
        Plasmoid.setInternalAction("configure", openWindowAction)
        ensureBackendStarted()
        refreshStatus()
    }
}

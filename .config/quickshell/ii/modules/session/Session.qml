import qs.modules.common
import qs
import qs.services
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

Scope {
    id: root
    property var focusedScreen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name)
    property bool packageManagerRunning: false
    property bool downloadRunning: false

    component DescriptionLabel: Rectangle {
        id: descriptionLabel
        property string text
        property color textColor: Appearance.colors.colOnTooltip
        color: Appearance.colors.colTooltip
        clip: true
        radius: Appearance.rounding.normal
        implicitHeight: descriptionLabelText.implicitHeight + 10 * 2
        implicitWidth: descriptionLabelText.implicitWidth + 15 * 2

        Behavior on implicitWidth {
            animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
        }

        StyledText {
            id: descriptionLabelText
            anchors.centerIn: parent
            color: descriptionLabel.textColor
            text: descriptionLabel.text
        }
    }

    function closeAllWindows() {
        HyprlandData.windowList.map(w => w.pid).forEach((pid) => {
            Quickshell.execDetached(["kill", pid]);
        });
    }

    function detectRunningStuff() {
        packageManagerRunning = false;
        downloadRunning = false;
        detectPackageManagerProc.running = false;
        detectPackageManagerProc.running = true;
        detectDownloadProc.running = false;
        detectDownloadProc.running = true;
    }

    Process {
        id: detectPackageManagerProc
        command: ["pidof", "pacman", "yay", "paru", "dnf", "zypper", "apt", "apx", "xbps", "flatpak", "snap", "apk",
            "yum", "epsi", "pikman"]
        onExited: (exitCode, exitStatus) => {
            root.packageManagerRunning = (exitCode === 0);
        }
    }

    Process {
        id: detectDownloadProc
        command: ["bash", "-c", "pidof curl wget aria2c yt-dlp || ls ~/Downloads | grep -E '\.crdownload$|\.part$'"]
        onExited: (exitCode, exitStatus) => {
            root.downloadRunning = (exitCode === 0);
        }
    }

    PanelWindow { // Session menu
        id: sessionRoot
        visible: GlobalStates.sessionOpen
        property string subtitle

        function hide() {
            GlobalStates.sessionOpen = false
        }

        Connections {
            target: GlobalStates
            function onScreenLockedChanged() {
                if (GlobalStates.screenLocked) {
                    GlobalStates.sessionOpen = false;
                }
            }

        sourceComponent: PanelWindow { // Session menu
            id: sessionRoot
            visible: sessionLoader.active
            property string subtitle
            
            function hide() {
                GlobalStates.sessionOpen = false;
            }

            GridLayout {
                columns: 4
                columnSpacing: 15
                rowSpacing: 15

                SessionActionButton {
                    id: sessionLock
                    focus: sessionRoot.visible
                    buttonIcon: "lock"
                    buttonText: Translation.tr("Lock")
                    onClicked:  { Quickshell.execDetached(["loginctl", "lock-session"]); sessionRoot.hide() }
                    onFocusChanged: { if (focus) sessionRoot.subtitle = buttonText }
                    KeyNavigation.right: sessionSleep
                    KeyNavigation.down: sessionHibernate
                }
                SessionActionButton {
                    id: sessionSleep
                    buttonIcon: "dark_mode"
                    buttonText: Translation.tr("Sleep")
                    onClicked:  { Quickshell.execDetached(["bash", "-c", "systemctl suspend || loginctl suspend"]); sessionRoot.hide() }
                    onFocusChanged: { if (focus) sessionRoot.subtitle = buttonText }
                    KeyNavigation.left: sessionLock
                    KeyNavigation.right: sessionLogout
                    KeyNavigation.down: sessionShutdown
                }
                SessionActionButton {
                    id: sessionLogout
                    buttonIcon: "logout"
                    buttonText: Translation.tr("Logout")
                    onClicked: { root.closeAllWindows(); Quickshell.execDetached(["pkill", "Hyprland"]); sessionRoot.hide() }
                    onFocusChanged: { if (focus) sessionRoot.subtitle = buttonText }
                    KeyNavigation.left: sessionSleep
                    KeyNavigation.right: sessionTaskManager
                    KeyNavigation.down: sessionReboot
                }
                SessionActionButton {
                    id: sessionTaskManager
                    buttonIcon: "browse_activity"
                    buttonText: Translation.tr("Task Manager")
                    onClicked:  { Quickshell.execDetached(["bash", "-c", `${Config.options.apps.taskManager}`]); sessionRoot.hide() }
                    onFocusChanged: { if (focus) sessionRoot.subtitle = buttonText }
                    KeyNavigation.left: sessionLogout
                    KeyNavigation.down: sessionFirmwareReboot
                }

                SessionActionButton {
                    id: sessionHibernate
                    buttonIcon: "downloading"
                    buttonText: Translation.tr("Hibernate")
                    onClicked:  { Quickshell.execDetached(["bash", "-c", `systemctl hibernate || loginctl hibernate`]); sessionRoot.hide() }
                    onFocusChanged: { if (focus) sessionRoot.subtitle = buttonText }
                    KeyNavigation.up: sessionLock
                    KeyNavigation.right: sessionShutdown
                }
                SessionActionButton {
                    id: sessionShutdown
                    buttonIcon: "power_settings_new"
                    buttonText: Translation.tr("Shutdown")
                    onClicked:  { root.closeAllWindows(); Quickshell.execDetached(["bash", "-c", `systemctl poweroff --no-wall || loginctl poweroff`]); sessionRoot.hide() }
                    onFocusChanged: { if (focus) sessionRoot.subtitle = buttonText }
                    KeyNavigation.left: sessionHibernate
                    KeyNavigation.right: sessionReboot
                    KeyNavigation.up: sessionSleep
                }
                SessionActionButton {
                    id: sessionReboot
                    buttonIcon: "restart_alt"
                    buttonText: Translation.tr("Reboot")
                    onClicked:  { root.closeAllWindows(); Quickshell.execDetached(["bash", "-c", `reboot --no-wall || loginctl reboot`]); sessionRoot.hide() }
                    onFocusChanged: { if (focus) sessionRoot.subtitle = buttonText }
                    KeyNavigation.left: sessionShutdown
                    KeyNavigation.right: sessionFirmwareReboot
                    KeyNavigation.up: sessionLogout
                }
                SessionActionButton {
                    id: sessionFirmwareReboot
                    buttonIcon: "settings_applications"
                    buttonText: Translation.tr("Reboot to firmware settings")
                    onClicked:  { root.closeAllWindows(); Quickshell.execDetached(["bash", "-c", `systemctl reboot --firmware-setup || loginctl reboot --firmware-setup`]); sessionRoot.hide() }
                    onFocusChanged: { if (focus) sessionRoot.subtitle = buttonText }
                    KeyNavigation.up: sessionTaskManager
                    KeyNavigation.left: sessionReboot
                }
            }

            DescriptionLabel {
                Layout.alignment: Qt.AlignHCenter
                text: sessionRoot.subtitle
            }
        }

        RowLayout {
            anchors {
                top: contentColumn.bottom
                topMargin: 10
                horizontalCenter: contentColumn.horizontalCenter
            }
            spacing: 10

            Loader {
                active: root.packageManagerRunning
                visible: active
                sourceComponent: DescriptionLabel {
                    text: Translation.tr("Your package manager is running")
                    textColor: Appearance.m3colors.m3onErrorContainer
                    color: Appearance.m3colors.m3errorContainer
                }
            }
            Loader {
                active: root.downloadRunning
                visible: active
                sourceComponent: DescriptionLabel {
                    text: Translation.tr("There might be a download in progress")
                    textColor: Appearance.m3colors.m3onErrorContainer
                    color: Appearance.m3colors.m3errorContainer
                }
            }
        }
    }

    IpcHandler {
        target: "session"

        function toggle(): void {
            GlobalStates.sessionOpen = !GlobalStates.sessionOpen;
        }

        function close(): void {
            GlobalStates.sessionOpen = false
        }

        function open(): void {
            GlobalStates.sessionOpen = true
        }
    }

    GlobalShortcut {
        name: "sessionToggle"
        description: "Toggles session screen on press"

        onPressed: {
            GlobalStates.sessionOpen = !GlobalStates.sessionOpen;
        }
    }

    GlobalShortcut {
        name: "sessionOpen"
        description: "Opens session screen on press"

        onPressed: {
            GlobalStates.sessionOpen = true
        }
    }

    GlobalShortcut {
        name: "sessionClose"
        description: "Closes session screen on press"

        onPressed: {
            GlobalStates.sessionOpen = false
        }
    }
}

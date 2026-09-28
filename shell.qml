//@ pragma UseQApplication
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick

// shell.qml
ShellRoot {
    Theme { id: theme }
    Stats { id: stats }
    AudioMonitor { id: audioMon }
    IslandState { id: islandState }
    Pomodoro { id: pomodoro }
    NotificationMonitor { id: notificationMon }

    // Find the ShellScreen corresponding to DP-3
    readonly property var targetScreen: {
        var screens = Quickshell.screens
        for (var i = 0; i < screens.length; i++) {
            if (screens[i].name === "DP-3")
                return screens[i]
        }
        return screens[0]  // Fallback to first screen
    }

    TopBar {
        islandState: islandState
        screen: targetScreen  // Explicitly specify
    }

    DynamicIsland {
        theme: theme
        stats: stats
        audioMon: audioMon
        islandState: islandState
        pomodoro: pomodoro
        notificationMon: notificationMon
        screen: targetScreen  // Explicitly specify
    }
}
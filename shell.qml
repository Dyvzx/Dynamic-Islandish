//@ pragma UseQApplication
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick

ShellRoot {
    Theme               { id: theme             }
    Stats               { id: stats             }
    AudioMonitor        { id: audioMon          }
    IslandState         { id: islandState       }
    Pomodoro            { id: pomodoro          }
    NotificationMonitor { id: notificationMon   }

    TopBar {
        islandState: islandState
    }

    DynamicIsland {
        theme: theme
        stats: stats
        audioMon: audioMon
        islandState: islandState
        pomodoro: pomodoro
        notificationMon: notificationMon
    }
}

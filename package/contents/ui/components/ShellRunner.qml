import QtQuick
import org.kde.plasma.plasma5support as Plasma5Support

// Runs a shell command and reports its stdout. One instance per module that
// needs it; `finished` carries the command so callers can tell replies apart.
Item {
    id: sh

    signal finished(string cmd, string out)

    function run(cmd) {
        exec.disconnectSource(cmd);
        exec.connectSource(cmd);
    }

    Plasma5Support.DataSource {
        id: exec
        engine: "executable"
        connectedSources: []
        onNewData: (sourceName, data) => {
            disconnectSource(sourceName);
            sh.finished(sourceName, data["stdout"] || "");
        }
    }
}

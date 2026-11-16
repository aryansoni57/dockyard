import QtQuick
import org.kde.plasma.plasma5support as P5

// Runs a shell command and hands stdout, stderr and the exit code to a callback.
Item {
    id: r
    property var cbs: ({})
    function run(cmd, cb) {
        if (cb)
            cbs[cmd] = cb;
        src.connectSource(cmd);
    }
    P5.DataSource {
        id: src
        engine: "executable"
        onNewData: (s, d) => {
            disconnectSource(s);
            const cb = r.cbs[s];
            delete r.cbs[s];
            if (cb)
                cb(d["stdout"] || "", d["stderr"] || "", d["exit code"]);
        }
    }
}

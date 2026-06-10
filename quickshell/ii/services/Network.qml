pragma Singleton
pragma ComponentBehavior: Bound

// Took many bits from https://github.com/caelestia-dots/shell (GPLv3)

import Quickshell
import Quickshell.Io
import QtQuick
import qs.services.network

/**
 * Network service with nmcli.
 */
Singleton {
    id: root

    property bool wifi: true
    property bool ethernet: false

    property bool wifiEnabled: false
    property bool wifiScanning: false
    property bool wifiConnecting: connectProc.running
    property WifiAccessPoint wifiConnectTarget
    property var pendingPasswordRequests: ({}) // BSSID -> bool map
    property int lastScanTime: 0
    property string lastActiveBssid: "" // Cache to smooth over connection transitions
    readonly property list<WifiAccessPoint> wifiNetworks: []
    readonly property WifiAccessPoint active: wifiNetworks.find(n => n.active) ?? null
    
    function setPasswordRequest(bssid: string, value: bool): void {
        const updated = Object.assign({}, pendingPasswordRequests);
        if (value) {
            updated[bssid] = true;
        } else {
            delete updated[bssid];
        }
        pendingPasswordRequests = updated;
    }
    readonly property list<var> friendlyWifiNetworks: [...wifiNetworks].sort((a, b) => {
        if (a.active && !b.active)
            return -1;
        if (!a.active && b.active)
            return 1;
        return b.strength - a.strength;
    })
    property string wifiStatus: "disconnected"

    property string networkName: ""
    property int networkStrength
    property string materialSymbol: root.ethernet
        ? "lan"
        : root.wifiEnabled
            ? (
                Network.networkStrength > 83 ? "signal_wifi_4_bar" :
                Network.networkStrength > 67 ? "network_wifi" :
                Network.networkStrength > 50 ? "network_wifi_3_bar" :
                Network.networkStrength > 33 ? "network_wifi_2_bar" :
                Network.networkStrength > 17 ? "network_wifi_1_bar" :
                "signal_wifi_0_bar"
            )
            : (root.wifiStatus === "connecting")
                ? "signal_wifi_statusbar_not_connected"
                : (root.wifiStatus === "disconnected")
                    ? "wifi_find"
                    : (root.wifiStatus === "disabled")
                        ? "signal_wifi_off"
                        : "signal_wifi_bad"

    // Control
    function enableWifi(enabled = true): void {
        const cmd = enabled ? "on" : "off";
        enableWifiProc.exec(["nmcli", "radio", "wifi", cmd]);
    }

    function toggleWifi(): void {
        enableWifi(!wifiEnabled);
    }

    function rescanWifi(): void {
        const now = Date.now();
        if (now - lastScanTime < 5000) return; // Throttle: max once per 5 seconds
        wifiScanning = true;
        lastScanTime = now;
        rescanProcess.running = true;
    }

    function connectToWifiNetwork(accessPoint: WifiAccessPoint): void {
        pendingPasswordRequests = {}; // Clear all previous password requests
        root.wifiConnectTarget = accessPoint;
        connectProc.exec(["nmcli", "dev", "wifi", "connect", accessPoint.ssid])
    }

    function disconnectWifiNetwork(): void {
        if (active) disconnectProc.exec(["nmcli", "connection", "down", active.ssid]);
    }

    function openPublicWifiPortal() {
        Quickshell.execDetached(["xdg-open", "https://nmcheck.gnome.org/"]) // From some StackExchange thread, seems to work
    }

    function changePassword(network: WifiAccessPoint, password: string, username = ""): void {
        setPasswordRequest(network.bssid, false);
        changePasswordProc.exec({
            "environment": {
                "PASSWORD": password,
                "SSID": network.ssid
            },
            "command": ["bash", "-c", 'nmcli connection modify "$SSID" wifi-sec.psk "$PASSWORD"']
        })
    }

    Process {
        id: enableWifiProc
    }

    Process {
        id: connectProc
        environment: ({
            LANG: "C",
            LC_ALL: "C"
        })
        stdout: SplitParser {
            onRead: line => {
                // Don't refresh here - let nmcli monitor handle it
            }
        }
        stderr: SplitParser {
            onRead: line => {
                if (line.includes("Secrets were required") && root.wifiConnectTarget) {
                    root.setPasswordRequest(root.wifiConnectTarget.bssid, true);
                }
            }
        }
        onExited: (exitCode, exitStatus) => {
            if (root.wifiConnectTarget) {
                if (exitCode === 0) {
                    root.updateImmediate();
                    connectionSuccessRefresh.restart();
                } else {
                    root.setPasswordRequest(root.wifiConnectTarget.bssid, true);
                }
                root.wifiConnectTarget = null;
            }
        }
    }

    Timer {
        id: connectionTimeout
        interval: 30000
        repeat: false
        onTriggered: {
            if (connectProc.running) {
                connectProc.running = false;
                if (root.wifiConnectTarget) {
                    root.setPasswordRequest(root.wifiConnectTarget.bssid, true);
                    root.wifiConnectTarget = null;
                }
            }
        }
    }

    Timer {
        id: connectionSuccessRefresh
        interval: 200
        repeat: true
        property int attempts: 0
        onTriggered: {
            root.updateImmediate();
            getNetworks.running = true;
            attempts++;
            if (attempts >= 15) { // 15 × 200ms = 3 seconds
                stop();
                attempts = 0;
            }
        }
        onRunningChanged: {
            if (running) attempts = 0;
        }
    }

    Connections {
        target: connectProc
        function onRunningChanged() {
            if (connectProc.running) {
                connectionTimeout.restart();
            } else {
                connectionTimeout.stop();
            }
        }
    }

    Process {
        id: disconnectProc
        stdout: SplitParser {
            onRead: {} // nmcli monitor will handle updates
        }
    }

    Process {
        id: changePasswordProc
        onExited: { // Re-attempt connection after changing password
            connectProc.running = false
            connectProc.running = true
        }
    }

    Process {
        id: rescanProcess
        command: ["nmcli", "dev", "wifi", "list", "--rescan", "yes"]
        stdout: SplitParser {
            onRead: {
                wifiScanning = false;
                getNetworks.running = true;
            }
        }
    }

    // Status update
    property var _pendingState: ({})
    property int _pendingStateCount: 0

    Timer {
        id: updateDebouncer
        interval: 100 // Reduced from 200ms
        repeat: false
        onTriggered: {
            _pendingState = {};
            _pendingStateCount = 0;
            updateConnectionType.startCheck();
            wifiStatusProcess.running = true;
            updateNetworkName.running = true;
            updateNetworkStrength.running = true;
        }
    }

    function _commitStateIfReady() {
        if (_pendingStateCount === 4) {
            if (_pendingState.wifiStatus !== undefined) root.wifiStatus = _pendingState.wifiStatus;
            if (_pendingState.ethernet !== undefined) root.ethernet = _pendingState.ethernet;
            if (_pendingState.wifi !== undefined) root.wifi = _pendingState.wifi;
            if (_pendingState.networkName !== undefined) root.networkName = _pendingState.networkName;
            if (_pendingState.networkStrength !== undefined) root.networkStrength = _pendingState.networkStrength;
            if (_pendingState.wifiEnabled !== undefined) root.wifiEnabled = _pendingState.wifiEnabled;
            _pendingState = {};
            _pendingStateCount = 0;
        }
    }

    function update() {
        updateDebouncer.restart();
    }
    
    function updateImmediate() {
        updateDebouncer.stop();
        _pendingState = {};
        _pendingStateCount = 0;
        updateConnectionType.startCheck();
        wifiStatusProcess.running = true;
        updateNetworkName.running = true;
        updateNetworkStrength.running = true;
    }

    Process {
        id: subscriber
        running: true
        command: ["nmcli", "monitor"]
        stdout: SplitParser {
            onRead: root.update()
        }
    }

    Process {
        id: updateConnectionType
        property string buffer
        command: ["sh", "-c", "nmcli -t -f TYPE,STATE d status && nmcli -t -f CONNECTIVITY g"]
        running: true
        function startCheck() {
            buffer = "";
            updateConnectionType.running = true;
        }
        stdout: SplitParser {
            onRead: data => {
                updateConnectionType.buffer += data + "\n";
            }
        }
        onExited: (exitCode, exitStatus) => {
            const lines = updateConnectionType.buffer.trim().split('\n');
            const connectivity = lines.pop()
            let hasEthernet = false;
            let hasWifi = false;
            let wifiStatus = "disconnected";
            lines.forEach(line => {
                if (line.includes("ethernet") && line.includes("connected"))
                    hasEthernet = true;
                else if (line.includes("wifi:")) {
                    if (line.includes("disconnected")) {
                        wifiStatus = "disconnected"
                    }
                    else if (line.includes("connected")) {
                        hasWifi = true;
                        wifiStatus = "connected"

                        if (connectivity === "limited") {
                            hasWifi = false;
                            wifiStatus = "limited"
                        }
                    }
                    else if (line.includes("connecting")) {
                        wifiStatus = "connecting"
                    }
                    else if (line.includes("unavailable")) {
                        wifiStatus = "disabled"
                    }
                }
            });
            root._pendingState.wifiStatus = wifiStatus;
            root._pendingState.ethernet = hasEthernet;
            root._pendingState.wifi = hasWifi;
            root._pendingStateCount++;
            root._commitStateIfReady();
        }
    }

    Process {
        id: updateNetworkName
        command: ["sh", "-c", "nmcli -t -f NAME c show --active | head -1"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                root._pendingState.networkName = data;
                root._pendingStateCount++;
                root._commitStateIfReady();
            }
        }
    }

    Process {
        id: updateNetworkStrength
        running: true
        command: ["sh", "-c", "nmcli -f IN-USE,SIGNAL,SSID device wifi | awk '/^\*/{if (NR!=1) {print $2}}'"]
        stdout: SplitParser {
            onRead: data => {
                root._pendingState.networkStrength = parseInt(data);
                root._pendingStateCount++;
                root._commitStateIfReady();
            }
        }
    }

    Process {
        id: wifiStatusProcess
        command: ["nmcli", "radio", "wifi"]
        Component.onCompleted: running = true
        environment: ({
            LANG: "C",
            LC_ALL: "C"
        })
        stdout: StdioCollector {
            onStreamFinished: {
                root._pendingState.wifiEnabled = text.trim() === "enabled";
                root._pendingStateCount++;
                root._commitStateIfReady();
            }
        }
    }

    Process {
        id: getNetworks
        running: true
        command: ["nmcli", "-g", "ACTIVE,SIGNAL,FREQ,SSID,BSSID,SECURITY", "d", "w"]
        environment: ({
            LANG: "C",
            LC_ALL: "C"
        })
        stdout: StdioCollector {
            onStreamFinished: {
                const PLACEHOLDER = "STRINGWHICHHOPEFULLYWONTBEUSED";
                const rep = new RegExp("\\\\:", "g");
                const rep2 = new RegExp(PLACEHOLDER, "g");

                const allNetworks = text.trim().split("\n").map(n => {
                    const net = n.replace(rep, PLACEHOLDER).split(":");
                    return {
                        active: net[0] === "yes",
                        strength: parseInt(net[1]),
                        frequency: parseInt(net[2]),
                        ssid: net[3],
                        bssid: net[4]?.replace(rep2, ":") ?? "",
                        security: net[5] || ""
                    };
                }).filter(n => n.ssid && n.ssid.length > 0);

                // Group networks by SSID and prioritize connected ones
                const networkMap = new Map();
                for (const network of allNetworks) {
                    const existing = networkMap.get(network.ssid);
                    if (!existing) {
                        networkMap.set(network.ssid, network);
                    } else {
                        if (network.active && !existing.active) {
                            networkMap.set(network.ssid, network);
                        } else if (!network.active && !existing.active) {
                            if (network.strength > existing.strength) {
                                networkMap.set(network.ssid, network);
                            }
                        }
                    }
                }

                const wifiNetworks = Array.from(networkMap.values());
                const rNetworks = root.wifiNetworks;

                // Find currently active network
                const activeNetwork = wifiNetworks.find(n => n.active);
                if (activeNetwork) {
                    root.lastActiveBssid = activeNetwork.bssid;
                }

                // Use BSSID as stable identifier - only destroy truly disappeared networks
                const newBssids = new Set(wifiNetworks.map(n => n.bssid));
                const destroyed = rNetworks.filter(rn => !newBssids.has(rn.bssid));
                
                for (const network of destroyed) {
                    // Don't destroy network being connected to
                    if (root.wifiConnectTarget && network.bssid === root.wifiConnectTarget.bssid) {
                        continue;
                    }
                    rNetworks.splice(rNetworks.indexOf(network), 1).forEach(n => n.destroy());
                }

                // Update existing or create new
                for (const network of wifiNetworks) {
                    const match = rNetworks.find(n => n.bssid === network.bssid);
                    
                    // If no active network reported but this was last active, keep it active temporarily
                    if (!activeNetwork && network.bssid === root.lastActiveBssid) {
                        network.active = true;
                    }
                    
                    if (match) {
                        match.lastIpcObject = network;
                    } else {
                        rNetworks.push(apComp.createObject(root, {
                            lastIpcObject: network
                        }));
                    }
                }
            }
        }
    }

    Component {
        id: apComp

        WifiAccessPoint {}
    }
}

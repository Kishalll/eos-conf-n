import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Item {
    id: root
    
    Image {
        id: timeTableImage
        anchors.fill: parent
        
        // REPLACE THIS PATH with the actual path to your image
        // Make sure to keep the "file://" prefix
        source: "file:///home/gigabyte/.config/quickshell/ii/modules/ii/cheatsheet/TT.jpg" 
        
        // This ensures the image doesn't stretch weirdly
        fillMode: Image.PreserveAspectFit
    }
}

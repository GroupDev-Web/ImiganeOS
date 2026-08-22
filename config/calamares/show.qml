import QtQuick 2.0

Rectangle {
    width: 800
    height: 480
    color: "#101827"

    Column {
        anchors.centerIn: parent
        spacing: 18

        Image {
            anchors.horizontalCenter: parent.horizontalCenter
            source: "logo.png"
            width: 132
            height: 132
            fillMode: Image.PreserveAspectFit
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Welcome to ImiganeOS"
            color: "#f3f7ff"
            font.pixelSize: 34
            font.bold: true
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Brought to you by XProductions"
            color: "#a9bdd5"
            font.pixelSize: 18
        }
    }
}

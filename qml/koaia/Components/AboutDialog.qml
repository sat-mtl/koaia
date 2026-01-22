import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import koaia

Dialog {
    id: aboutDialog
    
    property string appName: "Koaia"
    property string appDescription: "A tool developed by the Société des Arts Technologiques"
    property string appDetails: "Explore generative AI and create custom visual effects by combining input layers, filters, with a live preview and NDI streaming output."
    property string appWebsite: "https://gitlab.com/sat-mtl"
    property string logoPath: "../resources/images/koaia_logo.png"
    property string satLogoPath: "../resources/images/sat_logo.png"
    property string satWebsite: "https://www.sat.qc.ca"
    property string ossiaLogoPath: "../resources/images/ossia_logo.png"
    property string ossiaWebsite: "https://ossia.io"
    
    property var parentWindow: null
    
    modal: true
    width: parentWindow ? parentWindow.width : 800
    height: parentWindow ? parentWindow.height : 600
    x: 0
    y: 0
    
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 40
        spacing: 30
        
        Image {
            Layout.alignment: Qt.AlignHCenter
            source: logoPath
            fillMode: Image.PreserveAspectFit
            Layout.preferredWidth: 100
            Layout.preferredHeight: 100
        }
        
        CustomLabel {
            Layout.alignment: Qt.AlignHCenter
            text: appName
            font.pixelSize: 32
            font.bold: true
        }
        
        CustomLabel {
            Layout.alignment: Qt.AlignHCenter
            text: appDescription
            font.pixelSize: appStyle.fontSizeSubtitle
        }
        
        Text {
            Layout.fillWidth: true
            Layout.maximumWidth: 600
            Layout.alignment: Qt.AlignHCenter
            text: appDetails + " <a href=\"" + appWebsite + "\">" + appWebsite + "</a>"
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
            font.family: appStyle.fontFamily
            font.pixelSize: appStyle.fontSizeBody
            color: appStyle.textColor
            linkColor: appStyle.primaryColor
            onLinkActivated: function(url) {
                Qt.openUrlExternally(url)
            }
        }
        
        Item {
            Layout.fillHeight: true
        }
        
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            Layout.bottomMargin: 20
            spacing: 40
            
            Image {
                source: satLogoPath
                fillMode: Image.PreserveAspectFit
                Layout.preferredWidth: 180
                Layout.preferredHeight: 90
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Qt.openUrlExternally(satWebsite)
                }
            }
            
            Image {
                source: ossiaLogoPath
                fillMode: Image.PreserveAspectFit
                Layout.preferredWidth: 180
                Layout.preferredHeight: 90
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Qt.openUrlExternally(ossiaWebsite)
                }
            }
        }
        
        Button {
            Layout.alignment: Qt.AlignHCenter
            text: "Close"
            font.family: appStyle.fontFamily
            onClicked: aboutDialog.close()
        }
    }
}


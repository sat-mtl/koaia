import QtQuick

QtObject {
    // Primary accent
    property color primaryColor: "#0A84FF"
    property color secondaryColor: "#5E5CE6"
    
    // Backgrounds
    property color backgroundColor: "#1C1C1E"
    property color backgroundColorSecondary: "#2C2C2E"
    property color backgroundColorTertiary: "#3A3A3C"
    
    // Text
    property color textColor: "#E5E5E7"
    property color textColorSecondary: "#A1A1A6"
    property color textColorOnAccent: "#FFFFFF"
    
    // Borders & Separators
    property color borderColor: "#48484A"
    property color separatorColor: "#38383A"
    
    // Interactive states
    property color buttonBgActive: "#30D158"
    property color buttonBgInactive: "#3A3A3C"
    property color buttonBgHover: "#48484A"
    property color errorColor: "#FF453A"
    
    // Sidebar
    property color sidebarBackgroundColor: "#2C2C2E"
    property color sidebarTextColor: "#E5E5E7"
    property color sidebarTextColorInactive: "#8E8E93"
    property color sidebarHoverColor: "#3A3A3C"
    
    property int windowWidth: 600 
    property int windowHeight: 820
    property int windowMinWidth: 600
    property int windowMinHeight: 780
    property int padding: 16
    property int spacing: 12
    property int inputHeight: 36
    property int buttonHeight: 36
    
    property int fontSizeTitle: 20
    property int fontSizeSubtitle: 16
    property int fontSizeBody: 14
    property int fontSizeSmall: 12
    property string fontFamily: "DM Sans"
    
    property int borderRadius: 8
    property int animationDuration: 200
    
    property int sidebarWidth: 100
    property int sidebarButtonWidth: 80
    property int sidebarButtonHeight: 50
} 



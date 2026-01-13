import QtQuick

QtObject {
    // Primary accent
    property color primaryColor: "#007AFF"
    property color secondaryColor: "#5856D6"
    
    // Backgrounds
    property color backgroundColor: "#F2F2F7"
    property color backgroundColorSecondary: "#FFFFFF"
    property color backgroundColorTertiary: "#E5E5EA"
    
    // Text
    property color textColor: "#1C1C1E"
    property color textColorSecondary: "#8E8E93"
    property color textColorOnAccent: "#FFFFFF"
    
    // Borders & Separators
    property color borderColor: "#C6C6C8"
    property color separatorColor: "#D1D1D6"
    
    // Interactive states
    property color buttonBgActive: "#34C759"
    property color buttonBgInactive: "#E5E5EA"
    property color buttonBgHover: "#D1D1D6"
    property color errorColor: "#FF3B30"
    
    // Sidebar
    property color sidebarBackgroundColor: "#E8E8ED"
    property color sidebarTextColor: "#1C1C1E"
    property color sidebarTextColorInactive: "#8E8E93"
    property color sidebarHoverColor: "#D1D1D6"
    
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



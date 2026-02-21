import QtQuick 2
 
Item {
	id: root

	property TmStyle mtheme: TmStyle {}

	Component.onCompleted: {
		if (connection)
			connection.color = mtheme.themeBackgroundColor
		if (ball?.border)
			ball.border.color = mtheme.themeBackgroundColor
	}
}

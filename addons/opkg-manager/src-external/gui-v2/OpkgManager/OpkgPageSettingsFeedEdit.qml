import QtQuick 2
import Victron.VenusOS
import QtQuick.Layouts
import "."

Page {
	id: root
	title: qsTr("Edit Feed")
	tryPop: opkgManager?.tryPop

	required property var model
	required property OpkgManager opkgManager
	required property var loadFeedsModelCallback
	property bool _isNew: false
	property bool _builtin: false
	property string _removeButtonText: "Remove"
	property string _saveButtonText: "Save"

	onModelChanged: refreshModel()

	function resetButtonText() {
		root._saveButtonText = "Save"
		root._removeButtonText = "Remove"
	}

	//also called from parent feeds page
	function refreshModel(newModel) {
		if (newModel !== undefined) {
			root.model = newModel
			return
		}

		resetButtonText()

		feedNameTextField.secondaryText = root.model.name
		feedUrlTextField.text = root.model.url
		root._builtin = root.model.builtin
		root._isNew = root.model.isNew === undefined ? false : root.model.isNew

	}

	GradientListView {
		id: settingsListView
		clip: true
		model: VisibleItemModel {

			ListTextField {
				id: feedNameTextField
				text: "Feed Name"
				validateInput: root.validateFeedName
				interactive: !root._builtin
			}
			ListSetting {
				id: listItem
				height: feedUrlTextField.implicitHeight + listItem.topPadding + listItem.bottomPadding
				interactive: !root._builtin

				contentItem: RowLayout {
					id:itm
					height: feedUrlTextField.implicitHeight
					spacing: Theme.geometry_listItem_content_spacing

					Label {
						id: label
						text: "Feed Url"
						font.family: listItem.font.family
						font.pixelSize: listItem.font.pixelSize
						Layout.alignment: Qt.AlignVCenter
					}
					TextValidationField {
						id: feedUrlTextField
						implicitHeight: feedUrlTextField.contentHeight + Theme.geometry_listItem_content_verticalMargin - 3
						enabled: !root._builtin
						implicitWidth: 0
						text: root.model.url
						color: root._builtin ? Theme.color_listItem_secondaryText : Theme.color_font_primary
						borderColor: root._builtin ? Qt.rgba(0,0,0,0) : Theme.color_ok
						wrapMode: TextInput.WrapAtWordBoundaryOrAnywhere
						inputMethodHints: Qt.ImhUrlCharactersOnly
						Layout.fillWidth: true

						horizontalAlignment: Text.AlignLeft
						validateInput: root._builtin ? undefined : root.validateFeedUrl
						validateOnFocusLost: feedUrlTextField.validateOnFocusLost
					}
				}
			}
		}
	}

	OpkgActionsRow {
		id: actionsRow
		buttonModel: [
			{
				text: root._saveButtonText,
				enabled: !root._builtin && !root.opkgManager.running,
				onClicked: root.save},
			{
				text: root._removeButtonText,
				enabled: !root._builtin && !root._isNew && !root.opkgManager.running,
				onClicked: root.remove
			}
		]
	}

	function validateFeedName() {
		var text = feedNameTextField.secondaryText
		console.log("validateFeedName:" + text)
		// only alphanumeric, no spaces or symbols
		// must contain at least one letter (prevents "12345")
		if (!/^[A-Za-z0-9-]+$/.test(text) || (!/[A-Za-z]/.test(text))) {
			// "'%1' is not a valid IP address."
			return Utils.validationResult(VenusOS.InputValidation_Result_Error,"Invalid Name")
		}
		return Utils.validationResult(VenusOS.InputValidation_Result_OK, "", text)
	}

	function validateFeedUrl() {
		console.log("validateFeedUrl: in")
		var text = feedUrlTextField.text
		const pattern = /^https?:\/\/([a-zA-Z0-9-]+(\.[a-zA-Z0-9-]+)*|\d{1,3}(\.\d{1,3}){3})(:\d+)?(\/.*)?$/;
		if (!pattern.test(text)) {
			// "'%1' is not a valid IP address."
			// qsTrId("ip_address_input_not_valid").arg(trimmed)
			return Utils.validationResult(VenusOS.InputValidation_Result_Error,"Invalid URL")
		}

		return Utils.validationResult(VenusOS.InputValidation_Result_OK, "", text)
	}

	function remove() {
		if (root._builtin || opkgManager.running)
			return

		var completedCallback = function(result) {
			if (!result.success) {
				resetButtonText()
				return
			}

			loadFeedsModelCallback?.(result.data)
			Global.pageManager.popPage()
		}

		root._removeButtonText = "Removing..."
		opkgManager.removeFeed(root.model.name, completedCallback)

	}

	function save() {
		if (root._builtin || opkgManager.running)
			return

		var status1 = feedNameTextField.runValidation(VenusOS.InputValidation_ValidateOnly)
		var status2 = feedUrlTextField.runValidation(VenusOS.InputValidation_ValidateOnly)
		if (status1 !== VenusOS.InputValidation_Result_OK || status2 !== VenusOS.InputValidation_Result_OK) {
			console.log("save: Not saving; Invalid model")
			return
		}

		var feedName = feedNameTextField.secondaryText
		var feedUrl = feedUrlTextField.text

		var completedCallback = function(result) {
			if (!result.success) {
				resetButtonText()
				return
			}
			root.title = "Edit Feed" // update breadcrumb
			root._isNew = false
			loadFeedsModelCallback?.(result.data, feedName, root.refreshModel)

		}

		root._saveButtonText = "Saving..."

		if (root._isNew) {
			opkgManager.addFeed(feedName, feedUrl, completedCallback)
		} else {
			opkgManager.updateFeed(feedName, feedUrl, model.name, completedCallback)
		}
	}

}
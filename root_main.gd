extends VBoxContainer

@onready var lbl_version := $HBoxContainer/LblVersion
@onready var lbl_sub_version := $HBoxContainer/LblSub

const DOWNLOAD_REPO := "https://downloads.tuxfamily.org/godotengine/"

func _on_control_version_selected(version : String) -> void:
	lbl_version.text = version

func _on_control_sub_version_selected(sub_version : String) -> void:
	lbl_sub_version.text = sub_version


func _on_actual_downloads_request_download(download_name) -> void:
	print("download requested")
	var path :String = DOWNLOAD_REPO + lbl_version.text + "/"
	if not lbl_sub_version.text == "::stable":
		path += lbl_sub_version.text
	path += download_name
	print("Opening path: ", path)
	OS.shell_open(path)

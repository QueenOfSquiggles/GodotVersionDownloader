extends Control

@export var loading_placeholder_scene : PackedScene

@onready var http := $HTTPRequest
@onready var version_list := $%VersionList
@onready var sub_versions := $SubVersionsPanel
@onready var downloads := $ActualDownloads

const DOWNLOAD_REPO := "https://downloads.tuxfamily.org/godotengine/"

var known_versions := []
var selected_version := ""

signal version_selected(version)
signal sub_version_selected(sub_version)

func _ready() -> void:
	var loading := loading_placeholder_scene.instantiate()
	version_list.add_child(loading)
	
	http.request_completed.connect(_handle_request)
	var err = http.request(DOWNLOAD_REPO)
	if err != OK:
		push_error("HTTP Request Failed: " + str(err))

func _handle_request(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	print("Request Complted with result: %s" % str(result))
	if result == OK:
		parse_body(body)

func parse_body(body : PackedByteArray) -> void:
	var xml := XMLParser.new()
	xml.open_buffer(body)
	var err = OK
	while err == OK:
		err = xml.read()
		if xml.get_node_type() != XMLParser.NODE_ELEMENT:
			continue
		var n := xml.get_node_name()
		if n == 'a' and xml.get_named_attribute_value_safe("href").contains('.'):
			var link := xml.get_named_attribute_value_safe("href")
			if link.begins_with(".."):
				continue
			known_versions.append(link)
	populate_version_list()

func populate_version_list() -> void:
	while version_list.get_child_count() > 0:
		var node := version_list.get_child(0)
		node.queue_free()
		version_list.remove_child(node)

	print(str(known_versions))
	var ver_cache := '_'
	for ver in known_versions:
		var lbl := Button.new()
		lbl.text = (ver as String).replace('/', '')
		var callback := Callable(_btn_callback)
		lbl.pressed.connect(callback.bind(lbl.text))
		if ver_cache[0] != lbl.text[0]:
			version_list.add_spacer(false)
		ver_cache = lbl.text
		version_list.add_child(lbl)
		lbl.grab_focus()

func _btn_callback(ver : String) -> void:
	selected_version = ver
	version_selected.emit(ver)
	sub_versions.load_sub_versions(ver)
	

func _on_sub_versions_panel_request_downloads(sub_version : String) -> void:
	sub_version_selected.emit(sub_version)
	if sub_version.begins_with("::"):
		sub_version = ""
	downloads.load_downloads(selected_version, sub_version)

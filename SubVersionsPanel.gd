extends PanelContainer

@export var loading_placeholder_scene : PackedScene

@onready var http := $HTTPRequest
@onready var ver_list := $%SubVersionList

const DOWNLOAD_REPO := "https://downloads.tuxfamily.org/godotengine/"

signal request_downloads(sub_version)

var known_subversions := []
var has_stable_version := false

func _ready() -> void:
	http.request_completed.connect(_handle_request)
	

func load_sub_versions(ver : String) -> void:
	print('loading sub-versions for: %s' % ver)
	while ver_list.get_child_count() > 0:
		var node := ver_list.get_child(0)
		node.queue_free()
		ver_list.remove_child(node)

	var loading := loading_placeholder_scene.instantiate()
	ver_list.add_child(loading)

	known_subversions.clear()
	var path := DOWNLOAD_REPO + ver + "/"
	var err = http.request(path)
	if err != OK:
		push_error("HTTP Request Failed: %s" % str(err))

func _handle_request(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	print("Request Complted with result: %s" % str(result))
	if result == OK:
		parse_body(body)

func parse_body(body : PackedByteArray) -> void:
	var xml := XMLParser.new()
	xml.open_buffer(body)
	var err = OK
	has_stable_version = false;
	while err == OK:
		err = xml.read()
		if xml.get_node_type() != XMLParser.NODE_ELEMENT:
			continue
		var n := xml.get_node_name()
		if n == 'a':
			var link := xml.get_named_attribute_value_safe("href")
			if link.begins_with(".."):
				continue
			if link.ends_with("zip"):
				has_stable_version = true

			if not link.ends_with('/') or link.begins_with('mono'):
				continue
			known_subversions.append(link)
	_populate_list()

const STABLE_CODE := "::stable"

func _populate_list() -> void:
	while ver_list.get_child_count() > 0:
		var node := ver_list.get_child(0)
		node.queue_free()
		ver_list.remove_child(node)

	if has_stable_version:
		var stable_btn := Button.new()
		stable_btn.text = "Stable"
		var callback := Callable(_handle_button)
		stable_btn.pressed.connect(callback.bind(STABLE_CODE))
		ver_list.add_child(stable_btn)
		stable_btn.grab_focus()

	for ver in known_subversions:
		var btn := Button.new()
		var callback := Callable(_handle_button)
		btn.pressed.connect(callback.bind(ver))
		btn.text = ver
		ver_list.add_child(btn)
		if not has_stable_version:
			btn.grab_focus()
	if has_stable_version:
		_handle_button(STABLE_CODE)

func _handle_button(ver : String) -> void:
	print("Sub-Version button pressed: %s" % ver)
	request_downloads.emit(ver)


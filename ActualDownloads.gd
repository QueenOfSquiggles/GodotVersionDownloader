extends PanelContainer

@export var loading_placeholder_scene : PackedScene

@onready var ver_list := $%DownloadList

const DOWNLOAD_REPO := "https://downloads.tuxfamily.org/godotengine/"

var standard_downloads := []
var mono_downloads := []
var requests_completed := 0

signal request_download(download_name)

func load_downloads(ver : String, sub_ver : String) -> void:
	while ver_list.get_child_count() > 0:
		var node := ver_list.get_child(0)
		node.queue_free()
		ver_list.remove_child(node)

	var loading := loading_placeholder_scene.instantiate()
	ver_list.add_child(loading)
	
	print('loading sub-versions for: %s' % ver)
	standard_downloads.clear()
	mono_downloads.clear()
	requests_completed = 0
	_get_standard(ver, sub_ver)
	_try_get_mono(ver, sub_ver)

func _get_standard(ver : String, sub_ver : String) -> void:
	var http := HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_handle_standard)
	http.request_completed.connect(Callable(http, "queue_free"), CONNECT_DEFERRED)

	var path := DOWNLOAD_REPO + ver + "/" + sub_ver
	var err = http.request(path)
	if err != OK:
		push_error("HTTP Request Failed: %s" % str(err))
	

func _try_get_mono(ver : String, sub_ver : String) -> void:
	var http := HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_handle_mono)
	http.request_completed.connect(Callable(http, "queue_free"), CONNECT_DEFERRED)

	var path := DOWNLOAD_REPO + ver + "/" + sub_ver + "/mono/"
	var err = http.request(path)
	if err != OK:
		push_warning("No mono versions found for %s::%s" % [ver, sub_ver])

func _handle_standard(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	var xml := XMLParser.new()
	xml.open_buffer(body)
	var err = OK
	while err == OK:
		err = xml.read()
		if xml.get_node_type() != XMLParser.NODE_ELEMENT:
			continue
		var n := xml.get_node_name()
		if n == 'a':
			var link := xml.get_named_attribute_value_safe("href")
			if not link.ends_with("zip"):
				continue
			standard_downloads.append(link)
	print("standard: %s" % str(standard_downloads))
	requests_completed += 1
	try_populate_list()

func _handle_mono(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	var xml := XMLParser.new()
	xml.open_buffer(body)
	var err = OK
	while err == OK:
		err = xml.read()
		if xml.get_node_type() != XMLParser.NODE_ELEMENT:
			continue
		var n := xml.get_node_name()
		if n == 'a':
			var link := xml.get_named_attribute_value_safe("href")
			if not link.ends_with("zip"):
				continue
			standard_downloads.append(link)
	print("mono: %s" % str(standard_downloads))
	requests_completed += 1
	try_populate_list()

func try_populate_list() -> void:
	if requests_completed < 2:
		return
	while ver_list.get_child_count() > 0:
		var node := ver_list.get_child(0)
		node.queue_free()
		ver_list.remove_child(node)
	var mask := _build_os_mask()
	populate_masked(standard_downloads, mask)
	populate_masked(mono_downloads, mask)
	print("Found %s available downloads" % str(ver_list.get_child_count()))

func populate_masked(download_list : Array, mask : String) -> void:
	for d in download_list:
		var d_name := d as String
		if mask == MASK_LINUX:
			if 'linux' in d_name or 'unix' in d_name or 'x11' in d_name:
				pass
			else:
				continue
		elif (not mask in d_name):
			continue
		var btn := Button.new()
		var callback := Callable(_process_download)
		btn.pressed.connect(callback.bind(d_name))
		btn.text = "[Download] " + d_name
		ver_list.add_child(btn)

const MASK_WINDOWS := "win"
const MASK_MAC := "osx"
const MASK_LINUX := "x11"
func _build_os_mask() -> String:
	match OS.get_name():
		"Windows", "UWP":
			return MASK_WINDOWS
		"macOS":
			return MASK_MAC
		"Linux", "FreeBSD", "NetBSD", "OpenBSD", "BSD":
			return MASK_LINUX
		"Android","iOS","Web":
			push_error("Unsupported platform! Must be on a desktop platform!! Current OS: %s" % OS.get_name())
	return ""
	
func _process_download(download_name : String) -> void:
	if download_name.contains('mono'):
		download_name = "mono/" + download_name
	request_download.emit(download_name)

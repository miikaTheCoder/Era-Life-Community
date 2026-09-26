extends RefCounted
class_name NetworkSceneSupport
## Network support for the main scene. State, when needed, is passed explicitly.


static func _read_browser_origin() -> String:
	if not OS.has_feature("web"):
		return ""

	if not ClassDB.class_exists("JavaScriptBridge"):
		return ""

	var origin_raw: Variant = JavaScriptBridge.eval("window.location.origin || ''", true)
	return str(origin_raw).strip_edges().trim_suffix("/")


static func _read_browser_base_path() -> String:
	if not OS.has_feature("web"):
		return ""

	if not ClassDB.class_exists("JavaScriptBridge"):
		return ""

	var path_raw: Variant = JavaScriptBridge.eval("window.location.pathname || ''", true)
	var path: String = str(path_raw).strip_edges()
	if path == "":
		return ""

	var play_index: int = path.find("/play/")
	if play_index >= 0:
		return path.substr(0, play_index).trim_suffix("/")

	var mobile_index: int = path.find("/m/play/")
	if mobile_index >= 0:
		return path.substr(0, mobile_index).trim_suffix("/")

	var tv_index: int = path.find("/tv/play/")
	if tv_index >= 0:
		return path.substr(0, tv_index).trim_suffix("/")

	if path.ends_with("/index.html"):
		return path.trim_suffix("/index.html").trim_suffix("/")

	return ""


static func _read_browser_url() -> String:
	if not OS.has_feature("web"):
		return ""

	if not ClassDB.class_exists("JavaScriptBridge"):
		return ""

	var href_raw: Variant = JavaScriptBridge.eval("window.location.href", true)
	return str(href_raw).strip_edges()


static func _query_value_from_url(url: String, key: String) -> String:
	var clean_url: String = str(url).strip_edges()
	if clean_url == "":
		return ""

	var sections: Array = []

	var query_start: int = clean_url.find("?")
	if query_start >= 0:
		var query: String = clean_url.substr(query_start + 1)
		var hash_start: int = query.find("#")
		if hash_start >= 0:
			query = query.substr(0, hash_start)
		sections.append(query)

	var hash_index: int = clean_url.find("#")
	if hash_index >= 0:
		var hash_query: String = clean_url.substr(hash_index + 1)
		if hash_query.begins_with("?"):
			hash_query = hash_query.substr(1)
		sections.append(hash_query)

	for section_raw in sections:
		var section: String = str(section_raw)
		for raw_part in section.split("&", false):
			var part: String = str(raw_part)
			var eq_index: int = part.find("=")
			var raw_key: String = part if eq_index < 0 else part.substr(0, eq_index)
			var raw_value: String = "" if eq_index < 0 else part.substr(eq_index + 1)

			if raw_key.uri_decode() == key:
				return raw_value.uri_decode()

	return ""


static func _eraccount_banner_style(connected: bool = true) -> StyleBoxFlat:
	var style:= StyleBoxFlat.new()
	style.bg_color = Color(0.025, 0.025, 0.028, 0.96)
	style.border_color = Color(0.88, 0.88, 0.88, 0.84) if connected else Color(1.0, 0.72, 0.72, 0.84)
	style.set_border_width_all(1)
	style.corner_radius_top_left = 0
	style.corner_radius_top_right = 0
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.55)
	style.shadow_size = 18
	return style

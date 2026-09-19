extends RefCounted
class_name ValueSceneSupport
## Person values, display names and safe container conversion for scene callers.


static func _person_contract_value(person: Person, keys: Array, fallback: String = "") -> String:
	if person == null:
		return fallback

	for raw_key in keys:
		var key: String = str(raw_key)
		var value: String = ""

		if person.has_method("get"):
			value = str(person.get(key)).strip_edges()

		if value != "" and value != "<null>":
			return value

	return fallback


static func _safe_array(value: Variant) -> Array:
	return EraUtils.safe_array(value)


static func _safe_dictionary(value: Variant) -> Dictionary:
	return EraUtils.safe_dictionary(value)


static func _get_month_name(m):
	var names = [
		"January", "February", "March", "April", "May", "June",
		"July", "August", "September", "October", "November", "December"
	]
	return names [m - 1]


static func _article_for_phrase(text: String) -> String:
	var clean_text: String = str(text).strip_edges()
	if clean_text == "":
		return "a"

	var first_char: String = clean_text.substr(0, 1).to_lower()
	if first_char in ["a", "e", "i", "o", "u"]:
		return "an"

	return "a"


static func _person_display_name_for_identity_switch(person: Person) -> String:
	if person == null:
		return "Unknown Life"

	var first: String = str(person.first_name).strip_edges()
	var last: String = str(person.last_name).strip_edges()
	var full_name: String = ("%s %s" % [first, last]).strip_edges()

	if full_name == "":
		full_name = str(person.name).strip_edges()
	if full_name == "":
		full_name = "Unknown Life"

	return full_name


static func _get_person_display_name(person: Person) -> String:
	if person == null:
		return "Unknown Life"

	var first_name: String = str(person.first_name).strip_edges()
	var last_name: String = str(person.last_name).strip_edges()
	var full_name: String = ("%s %s" % [first_name, last_name]).strip_edges()

	if full_name == "" and person.has_method("_display_name"):
		full_name = str(person.call("_display_name")).strip_edges()

	if full_name == "":
		full_name = str(person.name).strip_edges()

	if full_name == "":
		var person_id: int = int(person.id)
		if person_id > 0:
			full_name = "Life #%d" % person_id

	if full_name == "":
		full_name = "Unknown Life"

	var royal_title: String = str(person.royal_title).strip_edges()
	if royal_title != "" and not full_name.begins_with(royal_title):
		full_name = ("%s %s" % [royal_title, full_name]).strip_edges()

	return full_name


static func _ui_packet_row_to_display_line(raw_row: Variant) -> String:
	if typeof(raw_row) != TYPE_DICTIONARY:
		return str(raw_row).strip_edges()

	var row: Dictionary = raw_row as Dictionary
	var title: String = str(row.get("title", row.get("label", row.get("name", row.get("id", ""))))).strip_edges()
	var description: String = str(row.get("description", row.get("text", row.get("summary", "")))).strip_edges()

	if title == "":
		return description
	if description == "":
		return title

	return "%s — %s" % [title, description]


static func _person_contract_country(person: Person) -> String:
	return ValueSceneSupport._person_contract_value(person, [
		"current_country",
		"country",
		"home_country",
		"birth_country",
		"realm_country",
		"nation"
	], "")


static func _person_contract_city(person: Person) -> String:
	return ValueSceneSupport._person_contract_value(person, [
		"current_city",
		"city",
		"home_city",
		"birth_city",
		"settlement",
		"location"
	], "")

extends RefCounted
class_name CareersSceneSupport
## Careers support for the main scene. State, when needed, is passed explicitly.


static func _career_contract_route_result(
	report: Dictionary
) -> Dictionary:
	if report.is_empty():
		return {}

	var cursor: Dictionary = report.duplicate(true)

	for _index in range(10):
		if cursor.has(
			"career_panel_contract"
		):
			return cursor

		var advanced: bool = false

		for key in [
			"route_report",
			"result",
			"engine_report",
			"target_report",
			"commit_report",
			"command_report",
			"payload"
		]:
			var nested_raw: Variant = cursor.get(
				key,
				{}
			)

			if typeof(nested_raw) != TYPE_DICTIONARY:
				continue

			var nested: Dictionary = (
				nested_raw as Dictionary
			).duplicate(true)

			if nested.is_empty():
				continue

			cursor = nested
			advanced = true
			break

		if not advanced:
			break

	return {}


static func _format_job_for_grandparent(job: String) -> String:
	if job == "Retired":
		return "retired"
	return "a %s" % job.to_lower()


static func _normalize_career_job_apply_result(job_name: String, result: Dictionary) -> Dictionary:
	var normalized: Dictionary = result.duplicate(true) if typeof(result) == TYPE_DICTIONARY else {}
	var result_text: String = str(normalized.get("text", "")).strip_edges()
	if result_text == "":
		result_text = "The result of your application could not be resolved."

	var success: bool = bool(normalized.get("success", false))
	var lead_text: String = "You applied for %s." % job_name
	if success:
		lead_text = "You applied for %s.\n\nYou got accepted." % job_name
	else:
		lead_text = "You applied for %s.\n\nYou were not accepted." % job_name

	normalized ["text"] = "%s\n\n%s" % [lead_text, result_text]
	normalized ["popup_title"] = "Career Application"
	normalized ["popup_text"] = str(normalized.get("text", ""))
	if not normalized.has("popup_footer"):
		normalized ["popup_footer"] = "Tap anywhere to continue."
	return normalized


static func _career_job_browser_title(job_kind: String) -> String:
	match str(job_kind).strip_edges():
		"part_time":
			return "PART-TIME CAREERS"
		"famous":
			return "FAMOUS CAREER TRACKS"
		_:
			return "FULL-TIME CAREERS"


static func _career_job_browser_body_lines(job_kind: String, person: Person) -> Array:
	var lines: Array = []
	lines.append("===== CAREER BROWSER =====")

	match str(job_kind).strip_edges():
		"part_time":
			lines.append("Lane: Part-Time")
			lines.append("Eligibility: Ages 16-17")
		"famous":
			lines.append("Lane: Famous Career")
			lines.append("Eligibility: Depends on the track")
			lines.append("Boxing starts from the bottom and routes into the Boxing Hub.")
		_:
			lines.append("Lane: Full-Time")
			lines.append("Eligibility: Ages 18+")

	lines.append("Current Age: %d" % int(person.age))
	lines.append("Tap any career below to inspect it.")
	lines.append("==========================")
	return lines


static func _career_hub_workplace_snapshot_lines(person: Person) -> Array:
	var lines: Array = []
	var has_job: bool = str(person.job).strip_edges() != ""
	lines.append("Current Job: %s" % (person.job if has_job else "Unemployed"))
	lines.append("Workplace ID: %s" % (str(person.current_workplace_id) if str(person.current_workplace_id).strip_edges() != "" else "None"))
	lines.append("Performance: %d" % int(person.job_performance))
	lines.append("Stress: %d" % int(person.work_stress))
	if has_job:
		lines.append("Presence: You are actively attached to a workplace lane.")
	else:
		lines.append("Presence: You are not currently attached to any workplace.")
	return lines


static func _format_job_for_parent(job: String) -> String:
	var office_text: String = GovernmentSceneSupport._format_civic_office_article_title(job)
	if office_text != "":
		return office_text

	return "a %s" % job.to_lower()

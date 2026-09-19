extends RefCounted
class_name CrimeSceneSupport
## Crime support for the main scene. State, when needed, is passed explicitly.


static func _crime_hub_renderer_chassis_contract() -> Dictionary:
	return {
		"schema": "eralife.crime_hub_contract",
		"version": 1,
		"success": true,
		"actor_id": -1,
		"title": "CRIME & JUSTICE",
		"subtitle": (
			(
				"Crime reality is resident. "
				+ "Targets, criminal intent, cases, weapons, custody, "
				+ "and legal pressure bind continuously."
			)
		),
		"active_section": "overview",
		"section_tabs": [
			{
				"id": "overview",
				"label": "OVERVIEW"
			},
			{
				"id": "crime_actions",
				"label": "CRIME ACTIONS"
			},
			{
				"id": "targets",
				"label": "TARGETS"
			},
			{
				"id": "weapons",
				"label": "WEAPONS"
			},
			{
				"id": "cases",
				"label": "CASES"
			},
			{
				"id": "pending",
				"label": "PENDING"
			},
			{
				"id": "custody",
				"label": "CUSTODY"
			}
		],
		"section_rows": [
			{
				"kind": "resident_projection",
				"label": "CRIME REALITY RESIDENT",
				"subtitle": (
					(
						"This room already exists. "
						+ "Its current actor projection is reconnecting."
					)
				),
				"actions": []
			}
		],
		"identity": {},
		"access_contract": {
			"minimum_age": 0,
			"under_12_access": true,
		},
		"incarcerated": false,
		"prison_reality_contract": {},
		"interaction_contract": {},
		"action_report": {},
		"truth_state": "renderer_chassis",
		"projection_composed": true,
		"hydrated": false,
		"ui_is_renderer_only": true,
		"renderer_chassis_only": true,
		"generated_at_ms": int(
			Time.get_ticks_msec()
		)
	}


static func _incarceration_context_for_actor(actor: Person) -> Dictionary:
	if actor == null:
		return {}

	if str(actor.current_context).strip_edges().to_lower() != "incarcerated":
		return {}

	if typeof(actor.incarceration_context) != TYPE_DICTIONARY:
		return {}

	return actor.incarceration_context.duplicate(true)


static func _incarceration_facility_title(context: Dictionary, tab_label: String) -> String:
	var facility: String = str(context.get("facility_type", context.get("facility_label", "Facility"))).strip_edges()
	var _era_name: String = str(context.get("era", "Unknown Era")).strip_edges()
	var security: String = str(context.get("security_level", "Low")).strip_edges()
	return "%s — %s • %s" % [tab_label, facility.to_upper(), security]


static func _incarceration_base_lines(context: Dictionary) -> Array:
	var sentence_years: int = int(context.get("sentence_years", 0))
	var years_remaining: int = int(context.get("years_remaining", sentence_years))
	var years_served: int = int(context.get("years_served", 0))
	var months_served: int = int(context.get("months_served", years_served * 12))

	return [
		"Facility: %s" % str(context.get("facility_type", context.get("facility_label", "Facility"))),
		"Era: %s" % str(context.get("era", "Unknown Era")),
		"Security Level: %s" % str(context.get("security_level", "Low")),
		"Sentence: %d year%s" % [sentence_years, "" if sentence_years == 1 else "s"],
		"Time Served: %d month%s" % [months_served, "" if months_served == 1 else "s"],
		"Years Remaining: %d" % years_remaining
	]

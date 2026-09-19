extends RefCounted
class_name ActivitiesSceneSupport
## Activities support for the main scene. State, when needed, is passed explicitly.


static func _activities_hub_icon_for_group(group_name: String) -> String:
	match str(group_name).strip_edges():
		"Featured":
			return "✨"
		"Markets & Assets":
			return "🏦"
		"Public Life":
			return "🌆"
		"School & Youth":
			return "📚"
		"Supernatural":
			return "🌀"
		_:
			return "🎲"


static func _activities_hub_description_for_group(group_name: String) -> String:
	match str(group_name).strip_edges():
		"Featured":
			return "One-time unlocks and important life-entry decisions."
		"Markets & Assets":
			return "Browse, manage, or inspect owned things without mixing in careers."
		"Public Life":
			return "Go places, move around, and interact with the world."
		"School & Youth":
			return "School-adjacent actions that are not full training systems."
		"Supernatural":
			return "Reality-bending routes, occult choices, and high-weirdness actions."
		_:
			return "Contextual life actions that do not belong to a deeper hub yet."


static func _activities_hub_panel_style(kind: String = "card") -> StyleBoxFlat:
	var style:= StyleBoxFlat.new()
	var clean_kind: String = str(kind).strip_edges().to_lower()

	match clean_kind:
		"shell":
			style.bg_color = Color(0.018, 0.024, 0.048, 0.985)
			style.border_color = Color(0.96, 0.68, 0.28, 0.34)
			style.shadow_color = Color(0.96, 0.54, 0.16, 0.18)
			style.shadow_size = 18
		"hero":
			style.bg_color = Color(0.055, 0.072, 0.12, 0.94)
			style.border_color = Color(1.0, 0.82, 0.42, 0.42)
			style.shadow_color = Color(0.96, 0.64, 0.22, 0.16)
			style.shadow_size = 14
		_:
			style.bg_color = Color(0.038, 0.05, 0.086, 0.94)
			style.border_color = Color(0.62, 0.78, 1.0, 0.24)
			style.shadow_color = Color(0.1, 0.18, 0.38, 0.12)
			style.shadow_size = 10

	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 20
	style.corner_radius_top_right = 20
	style.corner_radius_bottom_left = 20
	style.corner_radius_bottom_right = 20
	style.shadow_offset = Vector2.ZERO
	return style


static func _pet_shop_listing_category_label(
	category_id: String
) -> String:
	match category_id:
		"mythical":
			return "MYTHICAL & ARCANE"
		"working":
			return "WORKING, GUARDIAN & MOUNT"
		"exotic":
			return "EXOTIC & WILD"
		_:
			return "HOUSEHOLD COMPANIONS"


static func _pet_shop_listing_icon(
	listing: Dictionary
) -> String:
	var species_id: String = str(
		listing.get(
			"species_id",
			listing.get(
				"listing_id",
				""
			)
		)
	).strip_edges().to_lower()

	if str(
		listing.get(
			"entity_kind",
			"animal"
		)
	).to_lower() == "mythical":
		return "✦"

	match species_id:
		"dog":
			return "🐕"
		"cat":
			return "🐈"
		"horse":
			return "🐎"
		"cow":
			return "🐄"
		"chicken":
			return "🐓"
		"sheep":
			return "🐑"
		"goat":
			return "🐐"
		"rabbit":
			return "🐇"
		"duck":
			return "🦆"
		"crow":
			return "🐦"
		_:
			return "🐾"


static func _activity_label_should_be_hidden_from_activities(action_label: String) -> bool:
	var clean_label: String = str(action_label).strip_edges()
	var lowered: String = clean_label.to_lower()

	if clean_label == "":
		return true

	if clean_label == "Begin Boxing":
		return false

	if clean_label in [
		"Apply for Part Time Job",
		"Browse Part Time Jobs",
		"Apply for Full Time Job",
		"Browse Full Time Jobs",
		"Browse Famous Careers",
		"View Job Details",
		"Work Normally",
		"Work Hard",
		"Slack Off",
		"Ask for Raise",
		"View Coworkers",
		"Quit Job"
	]:
		return true

	if clean_label in [
		"Train Bending",
		"Teach Bending",
		"Grant Bending",
		"Remove Bending",
		"Challenge To Bending Duel",
		"Train Boxing",
		"Boxing Sparring",
		"Boxing Hub",
		"Open Boxing Hub",
		"Book Boxing Match",
		"View Boxing Record",
		"View Boxing Rivalries",
		"Call Out Opponent",
		"Change Weight Class",
		"Review Last Fight Log",
		"Enter Amateur Tournament"
	]:
		return true

	if clean_label == "Start Boxing":
		return true

	if lowered.find("career") >= 0:
		return true
	if lowered.find("job") >= 0:
		return true
	if lowered.find("coworker") >= 0:
		return true
	if lowered.find("work ") >= 0 or lowered == "work":
		return true
	if lowered.find("train") >= 0:
		return true
	if lowered.find("sparring") >= 0:
		return true

	return false


static func _normalize_activity_action_to_player_action(action_label: String) -> String:
	match action_label:
		"Apply for Full Time Job":
			return "browse_jobs"
		"Browse Jobs":
			return "browse_jobs"
		"View Job Details":
			return "view_job_details"
		"Work Normally":
			return "work_normally"
		"Work Hard":
			return "work_hard"
		"Slack Off":
			return "slack_off"
		"Ask for Raise":
			return "ask_for_raise"
		"Quit Job":
			return "quit_job"
		"Start School":
			return "start_school"
		"Enroll In Era School":
			return "enroll_era_school"
		"Enroll In Bending School":
			return "enroll_bending_school"
		"Dual Enrollment":
			return "dual_enrollment"
		"Interact With Classmates":
			return "interact_with_classmates"
		_:
			return action_label.to_lower().replace(" ", "_")


static func _activity_group_for_label(gs: GameState,
	action_label: String) -> String:
	if ActivitiesSceneSupport._activity_label_is_pet_shop_label(gs, action_label):
		return "Companions"

	if AssetsSceneSupport._activity_label_is_meat_market_label(gs, action_label):
		return "Markets & Assets"

	if action_label in [
		"Trade On The Silk Road",
		"Look For Property",
		"Look For Vehicles",
		"Browse Property Market",
		"Browse Vehicle Market",
		"Review Estates",
		"Manage Holdings",
		"Open To Tenants",
		"Manage Fleet",
		"Assign Driver",
		"Assign Captain",
		"Artifact Shop",
		"View Assets"
	]:
		return "Markets & Assets"

	if action_label in [
		"Start School",
		"Enroll In Era School",
		"Enroll In Bending School",
		"Dual Enrollment",
		"Interact With Classmates"
	]:
		return "School & Youth"

	if action_label in [
		"Feed",
		"Use Blood Bag",
		"Glamour Target",
		"Join Coven",
		"Found Coven",
		"Seek Cure",
		"Turn Someone",
		"Blood Bond",
		"Investigate Vampire Rumors",
		"Ask To Be Turned",
		"Forge Gauntlet",
		"Become A Super Hero"
	]:
		return "Supernatural"

	if action_label in [
		"Migrate Somewhere",
		"Go to the movies",
		"Go To The Movies"
	]:
		return "Public Life"

	match action_label:
		"Begin Boxing":
			return "Featured"

		_:
			return "Miscellaneous"


static func _activities_current_controlled_actor(gs: GameState,

	fallback_actor: Person = null
) -> Person:
	if gs != null and gs.player != null:
		return gs.player

	return fallback_actor


static func _activity_label_is_pet_shop_label(gs: GameState,
	action_label: String) -> bool:
	var clean_label: String = str(action_label).strip_edges()
	if clean_label == "":
		return false
	if clean_label in ["Pet Shop", "Animal Market", "Stable & Menagerie", "Animal Dealer", "Bio-Companion Gallery", "Creature Market"]:
		return true
	if gs != null and gs.pet_shop_contract_engine != null and gs.pet_shop_contract_engine.has_method("shop_label_for_current_era"):
		return clean_label == str(gs.pet_shop_contract_engine.shop_label_for_current_era()).strip_edges()
	return false


static func _pet_shop_activity_label(gs: GameState) -> String:
	if gs != null and gs.pet_shop_contract_engine != null and gs.pet_shop_contract_engine.has_method("shop_label_for_current_era"):
		return str(gs.pet_shop_contract_engine.shop_label_for_current_era()).strip_edges()
	return "Pet Shop"


static func _pet_shop_actor_cache_key(gs: GameState,

	actor_id: int
) -> String:
	if gs == null:
		return str(
			actor_id
		)

	return "%d:%d:%s" % [
		int(
			actor_id
		),
		int(
			gs.year
		),
		(
			str(gs.era.name).strip_edges().to_lower()
			if gs.era != null
			else "unknown"
		)
	]

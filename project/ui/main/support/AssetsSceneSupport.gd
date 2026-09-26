extends RefCounted
class_name AssetsSceneSupport
## Assets support for the main scene. State, when needed, is passed explicitly.


static func _object_has_script_property(target: Object, property_name: String) -> bool:
	if target == null:
		return false

	for property_info in target.get_property_list():
		if typeof(property_info) != TYPE_DICTIONARY:
			continue
		if str(property_info.get("name", "")).strip_edges() == property_name:
			return true

	return false


static func _property_asset_enter_button_label(payload: Dictionary) -> String:
	var property_type: String = str(payload.get("subtype", "")).strip_edges()
	if property_type == "":
		property_type = str(payload.get("display_name", payload.get("type", "Property"))).strip_edges()
	property_type = property_type.replace("_", " ").capitalize()

	var address: String = str(payload.get("address", "")).strip_edges()
	if address == "" or address == "Unknown Address":
		return property_type

	return "%s at %s" % [property_type, address]


static func _asset_surface_contract_revision_key(
	contract: Dictionary
) -> String:
	if contract.is_empty():
		return ""

	for key in [
		"surface_signature",
		"surface_revision",
		"projection_revision",
		"revision"
	]:
		var value: String = str(
			contract.get(
				key,
				""
			)
		).strip_edges()

		if value != "":
			return value

	return str(
		hash(contract)
	)


static func _property_makeover_surface_panel_key(
	actor_id: int,
	property_id: int
) -> String:
	return "%d:%d" % [
		actor_id,
		property_id
	]


static func _property_viewer_surface_panel_key(
	actor_id: int,
	property_id: int
) -> String:
	return "%d:%d" % [
		actor_id,
		property_id
	]


static func _compact_property_spatial_intent_payload(
	source: Dictionary,
	action_id: String,
	actor_id: int,
	property_id: int,
	property_owner_id: int
) -> Dictionary:
	var out: Dictionary = {
		"actor_id": actor_id,
		"property_id": property_id,
		"property_owner_id": property_owner_id,
		"action_id": action_id,
		"intent_type": "spatial_traversal",
		"source": "mainscene.property_viewer",
		"ui_is_renderer_only": true,
	}

	for key in [
		"room_id",
		"from_room_id",
		"target_room_id",
		"fixture_id",
		"fixture_kind",
		"host_id",
		"host_kind",
		"provider_id",
		"multiplayer_mode",
		"direction",
		"edge_id",
		"security_mode"
	]:
		if source.has(
			key
		):
			out [key] = str(
				source.get(
					key,
					""
				)
			)

	for key in [
		"launch_direct",
		"open_provider_setup"
	]:
		if source.has(
			key
		):
			out [key] = bool(
				source.get(
					key,
					false
				)
			)

	if source.has(
		"cursor_revision"
	):
		out [
			"cursor_revision"
		] = int(
			source.get(
				"cursor_revision",
				0
			)
		)

	for key in [
		"active_floor",
		"from_floor",
		"target_floor"
	]:
		if source.has(
			key
		):
			out [key] = int(
				source.get(
					key,
					0
				)
			)

	return out


static func _property_portfolio_body_lines(payload: Dictionary, status_text: String = "") -> Array:
	var lines: Array = []
	var rollup: Dictionary = payload.get("rollup", {})
	var portfolio_tags: Dictionary = rollup.get("portfolio_tags", {})
	lines.append("Holdings: %d total" % int(rollup.get("asset_count", 0)))
	if int(portfolio_tags.get("dynastic_properties", 0)) > 0:
		lines.append("Dynastic Seats: %d" % int(portfolio_tags.get("dynastic_properties", 0)))
	if int(portfolio_tags.get("rentals", 0)) > 0:
		lines.append("Rentals: %d" % int(portfolio_tags.get("rentals", 0)))
	if int(portfolio_tags.get("safehouses", 0)) > 0:
		lines.append("Safehouses: %d" % int(portfolio_tags.get("safehouses", 0)))
	if status_text.strip_edges() != "":
		lines.append("")
		lines.append(status_text.strip_edges())
	return lines


static func _vehicle_portfolio_body_lines(payload: Dictionary, status_text: String = "") -> Array:
	var lines: Array = []
	var rollup: Dictionary = payload.get("rollup", {})
	var portfolio_tags: Dictionary = rollup.get("portfolio_tags", {})
	lines.append("Mobility Assets: %d total" % int(rollup.get("asset_count", 0)))
	if int(portfolio_tags.get("fleets", 0)) > 0:
		lines.append("Fleet Tags: %d" % int(portfolio_tags.get("fleets", 0)))
	if int(portfolio_tags.get("stables", 0)) > 0:
		lines.append("Stable Tags: %d" % int(portfolio_tags.get("stables", 0)))
	if int(portfolio_tags.get("hangars", 0)) > 0:
		lines.append("Hangar Tags: %d" % int(portfolio_tags.get("hangars", 0)))
	if int(portfolio_tags.get("trade_routes", 0)) > 0:
		lines.append("Trade Routes: %d" % int(portfolio_tags.get("trade_routes", 0)))
	if status_text.strip_edges() != "":
		lines.append("")
		lines.append(status_text.strip_edges())
	return lines


static func _vehicle_portfolio_asset_body_lines(payload: Dictionary, status_text: String = "") -> Array:
	var lines: Array = []
	lines.append("Asset: %s" % str(payload.get("display_name", "Mobility Asset")))
	lines.append("Identity: %s • %s • %s • %s" % [
		str(payload.get("archetype", "transport")).replace("_", " ").capitalize(),
		str(payload.get("subtype", "")).replace("_", " ").capitalize(),
		str(payload.get("social_tier", "common")).replace("_", " ").capitalize(),
		str(payload.get("value_band", "entry")).replace("_", " ").capitalize()
	])
	lines.append("Condition: %d%% • %s" % [
		int(payload.get("condition", 100)),
		str(payload.get("condition_label", "Excellent"))
	])
	lines.append("Operator: %s" % str(payload.get("operator_label", "Owner / Self")))
	lines.append("Route: %s" % str(payload.get("route_label", "Local Use")))
	lines.append("Trade Role: %s" % str(payload.get("trade_role_label", "Personal Travel")))

	if str(payload.get("active_assignment", "")) != "":
		lines.append("Assignment: %s" % str(payload.get("active_assignment", "")))

	var feature_tag_labels: Array = payload.get("feature_tag_labels", [])
	if not feature_tag_labels.is_empty():
		lines.append("Identity Tags: %s" % ", ".join(feature_tag_labels))

	var requirement_tag_labels: Array = payload.get("requirement_tag_labels", [])
	if not requirement_tag_labels.is_empty():
		lines.append("Requirements: %s" % ", ".join(requirement_tag_labels))

	var missing_requirement_labels: Array = payload.get("missing_requirement_labels", [])
	if not missing_requirement_labels.is_empty():
		lines.append("Missing Support: %s" % ", ".join(missing_requirement_labels))

	var satisfied_requirement_labels: Array = payload.get("satisfied_requirement_labels", [])
	if not satisfied_requirement_labels.is_empty():
		lines.append("Satisfied Support: %s" % ", ".join(satisfied_requirement_labels))

	var portfolio_tag_labels: Array = payload.get("portfolio_tag_labels", [])
	if not portfolio_tag_labels.is_empty():
		lines.append("Portfolio Tags: %s" % ", ".join(portfolio_tag_labels))

	var status_lines: Array = payload.get("status_lines", [])
	if not status_lines.is_empty():
		lines.append("")
		lines.append("Status Signals:")
		for line_text in status_lines:
			lines.append("• %s" % str(line_text))

	var operational_lines: Array = payload.get("operational_lines", [])
	if not operational_lines.is_empty():
		lines.append("")
		lines.append("Operational Profile:")
		for line_text in operational_lines:
			lines.append("• %s" % str(line_text))

	var pressure_lines: Array = payload.get("pressure_lines", [])
	if not pressure_lines.is_empty():
		lines.append("")
		lines.append("Story Pressure:")
		for line_text in pressure_lines:
			lines.append("• %s" % str(line_text))

	var provenance_lines: Array = payload.get("provenance_lines", [])
	if not provenance_lines.is_empty():
		lines.append("")
		lines.append("Provenance:")
		for line_text in provenance_lines:
			lines.append("• %s" % str(line_text))

	var candidate_labels: Array = payload.get("candidate_labels", [])
	if not candidate_labels.is_empty():
		lines.append("")
		lines.append("Operator Pool: %s" % ", ".join(candidate_labels))

	lines.append("")
	lines.append("Legal Status: %s" % str(payload.get("legal_status", "owned")))
	if str(payload.get("market_region", "")) != "":
		lines.append("Region: %s" % str(payload.get("market_region", "")))
	if str(payload.get("market_climate", "")) != "":
		lines.append("Market Climate: %s" % str(payload.get("market_climate", "")))
	if str(payload.get("custom_paint", "")) != "":
		lines.append("Custom Paint: %s" % str(payload.get("custom_paint", "")))

	if status_text.strip_edges() != "":
		lines.append("")
		lines.append(status_text.strip_edges())
	return lines


static func _baseline_property_social_tier_for_actor(actor: Person) -> String:
	if actor == null:
		return "common"

	var raw_class: String = str(actor.social_class).strip_edges().to_lower()
	if raw_class == "":
		raw_class = str(actor.get("class") if actor.has_method("get") else "").strip_edges().to_lower()

	match raw_class:
		"poor", "lower", "lower class", "working", "working class", "commoner":
			return "working"
		"middle", "middle class", "merchant":
			return "common"
		"upper", "upper class", "wealthy", "rich":
			return "wealthy"
		"royal", "king", "queen", "prince", "princess":
			return "royal"
		"noble", "elite", "aristocrat":
			return "noble"
		_:
			return "common"


static func _silk_road_contract_route_result(
	report: Dictionary
) -> Dictionary:
	if report.is_empty():
		return {}

	var cursor: Dictionary = report

	for _index in range(12):
		if str(
			cursor.get(
				"mode",
				""
			)
		).strip_edges() == "silk_road_intent_resolved":
			return cursor.duplicate(false)

		var advanced: bool = false

		for key in [
			"route_report",
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

			if typeof(
				nested_raw
			) != TYPE_DICTIONARY:
				continue

			var nested: Dictionary = (
				nested_raw as Dictionary
			)

			if nested.is_empty():
				continue

			cursor = nested
			advanced = true
			break

		if not advanced:
			break

	return cursor.duplicate(false)


static func _silk_road_listing_color(
	rarity: String
) -> Color:
	match rarity.strip_edges().to_lower():
		"staple":
			return Color(
				0.82,
				0.68,
				0.42,
				1.0
			)

		"fine":
			return Color(
				0.44,
				0.76,
				1.0,
				1.0
			)

		"luxury":
			return Color(
				1.0,
				0.76,
				0.24,
				1.0
			)

		"rare":
			return Color(
				0.76,
				0.46,
				1.0,
				1.0
			)

	return Color(
		0.92,
		0.86,
		0.68,
		1.0
	)


static func _net_worth_entry_value(entry: Dictionary) -> float:
	if entry.is_empty():
		return 0.0
	if entry.has("value"):
		return max(0.0, float(entry.get("value", 0.0)))
	if entry.has("price"):
		return max(0.0, float(entry.get("price", 0.0)))
	if entry.has("cost"):
		return max(0.0, float(entry.get("cost", 0.0)))
	if entry.has("worth"):
		return max(0.0, float(entry.get("worth", 0.0)))
	return 0.0


static func _clear_dictionary_property_if_present(target: Object, property_name: String) -> void:
	if target == null:
		return
	if not AssetsSceneSupport._object_has_script_property(target, property_name):
		return

	var value: Variant = target.get(property_name)
	if typeof(value) == TYPE_DICTIONARY:
		(value as Dictionary).clear()
		target.set(property_name, value)
	else:
		target.set(property_name, {})


static func _clear_array_property_if_present(target: Object, property_name: String) -> void:
	if target == null:
		return
	if not AssetsSceneSupport._object_has_script_property(target, property_name):
		return

	var value: Variant = target.get(property_name)
	if typeof(value) == TYPE_ARRAY:
		(value as Array).clear()
		target.set(property_name, value)
	else:
		target.set(property_name, [])


static func _market_surface_contract_is_renderable(
	surface_contract: Dictionary,
	market_kind: String
) -> bool:
	if surface_contract.is_empty():
		return false

	if not bool(
		surface_contract.get(
			"success",
			false
		)
	):
		return false

	var truth_state: String = str(
		surface_contract.get(
			"truth_state",
			""
		)
	).strip_edges().to_lower()

	if truth_state in [
		"",
		"observable_partial",
		"observable_shell",
		"resolving",
		"cold",
		"missing_surface_contract"
	]:
		return false

	if bool(
		surface_contract.get(
			"crr_fallback",
			false
		)
	):
		return false

	var listing_cards: Array = ValueSceneSupport._safe_array(
		surface_contract.get(
			"listing_card_contracts",
			[]
		)
	)
	var clean_market_kind: String = str(
		market_kind
	).strip_edges().to_lower()
	var surface_mode: String = str(
		surface_contract.get(
			"surface_mode",
			""
		)
	).strip_edges().to_lower()

	for raw_card in listing_cards:
		var card: Dictionary = ValueSceneSupport._safe_dictionary(
			raw_card
		)

		if card.is_empty():
			return false

		if bool(
			card.get(
				"crr_placeholder_card",
				false
			)
		):
			return false

		if str(
			card.get(
				"truth_state",
				""
			)
		).strip_edges().to_lower() in [
			"observable_partial",
			"resolving",
			"cold"
		]:
			return false

		if str(
			card.get(
				"availability",
				""
			)
		).strip_edges().to_lower() == "resolving":
			return false

	if clean_market_kind == "property":
		return not listing_cards.is_empty()

	if clean_market_kind == "vehicle":
		var dealerships: Array = ValueSceneSupport._safe_array(
			surface_contract.get(
				"dealership_contracts",
				[]
			)
		)

		if surface_mode == "dealership_selector":
			return not dealerships.is_empty()

		return not listing_cards.is_empty()

	return not listing_cards.is_empty()


static func _market_surface_contract_is_authoritatively_hot(
	surface_contract: Dictionary,
	market_kind: String
) -> bool:
	if not AssetsSceneSupport._market_surface_contract_is_renderable(
		surface_contract,
		market_kind
	):
		return false

	if not bool(
		surface_contract.get(
			"success",
			false
		)
	):
		return false

	var truth_state: String = str(
		surface_contract.get(
			"truth_state",
			""
		)
	).strip_edges().to_lower()

	return truth_state not in [
		"",
		"observable_partial",
		"missing_surface_contract",
		"resolving",
		"cold"
	]


static func _observable_asset_market_surface_contract(gs: GameState,

	target_actor: Person,
	market_kind: String,
	status_text: String = ""
) -> Dictionary:
	var clean_market_kind: String = str(
		market_kind
	).strip_edges().to_lower()
	var is_property_market: bool = (
		clean_market_kind == "property"
	)
	var actor_id: int = (
		int(target_actor.id)
		if target_actor != null
		else -1
	)
	var era_name: String = (
		str(gs.era.name)
		if gs != null and gs.era != null
		else "Unknown"
	)
	var year_value: int = (
		int(gs.year)
		if gs != null
		else 0
	)
	var market_label: String = (
		"PROPERTY MARKET"
		if is_property_market
		else "VEHICLE MARKET"
	)
	var clean_status: String = str(
		status_text
	).strip_edges()

	if clean_status == "":
		clean_status = (
			"%s contracts are publishing live for %s."
			% [
				(
					"Property"
					if is_property_market
					else "Vehicle and dealership"
				),
				era_name
			]
		)



	return {
		"success": false,
		"schema": (
			"eralife.market.property_market.surface_contract"
			if is_property_market
			else "eralife.market.vehicle_market.surface_contract"
		),
		"version": 1,
		"actor_id": actor_id,
		"surface_mode": (
			"inventory"
			if is_property_market
			else "dealership_selector"
		),
		"title": market_label,
		"subtitle": (
			"Authoritative %s market truth is publishing."
			% clean_market_kind
		),
		"era": era_name,
		"market_year": year_value,
		"status_text": clean_status,
		"listing_card_contracts": [],
		"listing_count": 0,
		"filter_contracts": [],
		"dealership_contracts": [],
		"truth_state": "observable_partial",
		"surface_signature": (
			"observable_market_shell|%s|%d|%d"
			% [
				clean_market_kind,
				actor_id,
				year_value
			]
		),
		"crr_fallback": true,
		"retired_fake_generic_market_surface": true,
		"catalog_authority": "",
		"authoritative_market_surface_required": true,
		"generic_resident_market_fallback_forbidden": true,
		"blank_surface_impossible": true,
		"visible_click_work_required": false,
		"visible_click_work_forbidden": true,
		"ready_gate_member": false,
		"ui_is_renderer_only": true,
		"created_at_ms": int(
			Time.get_ticks_msec()
		)
	}


static func _vehicle_market_contract_has_renderable_surface(
	contract: Dictionary
) -> bool:
	if contract.is_empty():
		return false

	var cards: Array = ValueSceneSupport._safe_array(
		contract.get(
			"listing_card_contracts",
			[]
		)
	)

	if not cards.is_empty():
		return true

	if str(
		contract.get(
			"surface_mode",
			""
		)
	) == "dealership_selector":
		return not ValueSceneSupport._safe_array(
			contract.get(
				"dealership_contracts",
				[]
			)
		).is_empty()

	return false


static func _baseline_property_context_for_actor(gs: GameState,
	actor: Person, reason: String = "") -> Dictionary:
	return {
		"source": "controlled_actor_baseline_property_projection",
		"reason": str(reason),
		"era_name": AssetsSceneSupport._baseline_property_era_name(gs),
		"social_tier": AssetsSceneSupport._baseline_property_social_tier_for_actor(actor),
		"desired_tags": AssetsSceneSupport._baseline_property_desired_tags_for_actor(actor),
		"price_override": 0,
	}


static func _baseline_property_desired_tags_for_actor(actor: Person) -> Array:
	var tier: String = AssetsSceneSupport._baseline_property_social_tier_for_actor(actor)
	match tier:
		"working":
			return ["small", "shelter", "modest", "residence"]
		"wealthy":
			return ["large", "luxury", "residence"]
		"royal":
			return ["royal", "palace", "estate", "residence"]
		"noble":
			return ["estate", "mansion", "residence"]
		_:
			return ["residence", "home"]


static func _baseline_property_legacy_size_for_actor(actor: Person) -> String:
	match AssetsSceneSupport._baseline_property_social_tier_for_actor(actor):
		"working":
			return "Small"
		"wealthy":
			return "Large"
		"royal":
			return "Royal"
		"noble":
			return "Mansion"
		_:
			return "Medium"


static func _baseline_property_era_name(gs: GameState) -> String:
	if gs == null:
		return "Modern Era"
	if gs.era != null:
		var era_name: String = str(gs.era.name).strip_edges()
		if era_name != "":
			return era_name
	return "Modern Era"


static func _meat_market_activity_label(gs: GameState) -> String:
	if gs == null or gs.player == null or gs.meat_market_contract_engine == null:
		return ""
	if not gs.meat_market_contract_engine.available_in_current_era():
		return ""
	return str(gs.meat_market_contract_engine.market_label_for_actor(gs.player)).strip_edges()


static func _activity_label_is_meat_market_label(gs: GameState,
	action_label: String) -> bool:
	var clean_label: String = str(action_label).strip_edges()
	if clean_label == "":
		return false
	return clean_label == AssetsSceneSupport._meat_market_activity_label(gs)


static func _count_npc_properties(gs: GameState,
	npc_id: int) -> int:
	if gs.property_engine == null:
		return 0
	if not gs.property_engine.properties.has(npc_id):
		return 0
	return gs.property_engine.properties [npc_id].size()


static func _count_npc_vehicles(gs: GameState,
	npc_id: int) -> int:
	if gs.vehicle_engine == null:
		return 0
	if not gs.vehicle_engine.vehicles.has(npc_id):
		return 0
	return gs.vehicle_engine.vehicles [npc_id].size()


static func _net_worth_entry_key(prefix: String, category: String, entry: Dictionary) -> String:
	var entry_id: int = int(entry.get("id", -1))
	if entry_id > 0:
		return "%s:%d" % [prefix, entry_id]
	var asset_name: String = str(entry.get("name", entry.get("type", entry.get("size", "asset"))))
	var address: String = str(entry.get("address", ""))
	var value: int = int(round(AssetsSceneSupport._net_worth_entry_value(entry)))
	return "%s:%s:%s:%s:%d" % [prefix, category, asset_name, address, value]


static func _sum_unique_flat_asset_bucket(bucket: Dictionary, owner_ids: Array, prefix: String, seen_asset_keys: Dictionary) -> float:
	var total: float = 0.0
	for owner_id_value in owner_ids:
		var owner_id: int = int(owner_id_value)
		if not bucket.has(owner_id):
			continue
		var raw_entries = bucket.get(owner_id, [])
		if raw_entries is Array:
			for raw_entry in raw_entries:
				if typeof(raw_entry) != TYPE_DICTIONARY:
					continue
				var entry: Dictionary = raw_entry
				var entry_key: String = AssetsSceneSupport._net_worth_entry_key(prefix, "", entry)
				if seen_asset_keys.has(entry_key):
					continue
				seen_asset_keys [entry_key] = true
				total += AssetsSceneSupport._net_worth_entry_value(entry)
	return total


static func _sum_unique_inventory_value(gs: GameState,
	owner_ids: Array, seen_asset_keys: Dictionary) -> float:
	var total: float = 0.0
	if gs == null or gs.belongings_engine == null:
		return total
	var excluded_categories: Dictionary = {
		"Real Estate": true,
		"Vehicles": true,
		"Vehicle": true
	}
	for owner_id_value in owner_ids:
		var owner_id: int = int(owner_id_value)
		if not gs.belongings_engine.belongings.has(owner_id):
			continue
		var inventory: Dictionary = gs.belongings_engine.belongings.get(owner_id, {})
		for category_key in inventory.keys():
			var category: String = str(category_key)
			if excluded_categories.has(category):
				continue
			var raw_items = inventory.get(category_key, [])
			if raw_items is Array:
				for raw_item in raw_items:
					if typeof(raw_item) != TYPE_DICTIONARY:
						continue
					var item: Dictionary = raw_item
					var item_key: String = AssetsSceneSupport._net_worth_entry_key("item", category, item)
					if seen_asset_keys.has(item_key):
						continue
					seen_asset_keys [item_key] = true
					total += AssetsSceneSupport._net_worth_entry_value(item)
	return total


static func _calculate_personal_net_worth(gs: GameState,
	person: Person) -> float:
	if person == null or gs == null:
		return 0.0
	var owner_ids: Array = [int(person.id)]
	var seen_asset_keys: Dictionary = {}
	var total: float = max(0.0, float(person.bank_balance))
	if gs.property_engine != null:
		total += AssetsSceneSupport._sum_unique_flat_asset_bucket(gs.property_engine.properties, owner_ids, "property", seen_asset_keys)
	if gs.vehicle_engine != null:
		total += AssetsSceneSupport._sum_unique_flat_asset_bucket(gs.vehicle_engine.vehicles, owner_ids, "vehicle", seen_asset_keys)
	total += AssetsSceneSupport._sum_unique_inventory_value(gs, owner_ids, seen_asset_keys)
	return total


static func _calculate_family_net_worth(gs: GameState,
	root: Person) -> float:
	if root == null or gs == null:
		return 0.0
	var member_ids: Array = RelationshipsSceneSupport._collect_death_panel_family_member_ids(gs, root)
	var effective_ids: Array = []
	var total: float = 0.0
	for member_id_value in member_ids:
		var member_id: int = int(member_id_value)
		var member: Person = gs.get_or_reactivate_npc_by_id(member_id)
		if member == null:
			continue
		if not member.alive and member_id != int(root.id):
			continue
		effective_ids.append(member_id)
		total += max(0.0, float(member.bank_balance))
	var seen_asset_keys: Dictionary = {}
	if gs.property_engine != null:
		total += AssetsSceneSupport._sum_unique_flat_asset_bucket(gs.property_engine.properties, effective_ids, "property", seen_asset_keys)
	if gs.vehicle_engine != null:
		total += AssetsSceneSupport._sum_unique_flat_asset_bucket(gs.vehicle_engine.vehicles, effective_ids, "vehicle", seen_asset_keys)
	total += AssetsSceneSupport._sum_unique_inventory_value(gs, effective_ids, seen_asset_keys)
	return total


static func _resolve_player_household_property_record(gs: GameState,
	person: Person) -> Dictionary:
	if person == null or gs == null or gs.property_engine == null:
		return {}

	var owners_to_check: Array = []
	var seen_owner_ids: Dictionary = {}

	var anchor: Person = RelationshipsSceneSupport._resolve_player_household_anchor(gs, person)
	if anchor != null and not seen_owner_ids.has(int(anchor.id)):
		owners_to_check.append(anchor)
		seen_owner_ids [int(anchor.id)] = true

	var custodial_parent: Person = RelationshipsSceneSupport._resolve_player_custodial_parent(gs, person)
	if custodial_parent != null and not seen_owner_ids.has(int(custodial_parent.id)):
		owners_to_check.append(custodial_parent)
		seen_owner_ids [int(custodial_parent.id)] = true

	if not seen_owner_ids.has(int(person.id)):
		owners_to_check.append(person)
		seen_owner_ids [int(person.id)] = true

	var best_property: Dictionary = {}
	var best_score: float = -999999.0

	for property_owner in owners_to_check:
		if property_owner == null:
			continue
		if not gs.property_engine.properties.has(property_owner.id):
			continue

		for raw_prop in gs.property_engine.properties.get(property_owner.id, []):
			if typeof(raw_prop) != TYPE_DICTIONARY:
				continue

			var prop: Dictionary = raw_prop
			var score: float = 0.0
			var feature_tags: Array = prop.get("feature_tags", [])

			if "dynasty_seat" in feature_tags:
				score += 6.0
			if "family_seat" in feature_tags:
				score += 4.0
			if "luxury" in feature_tags:
				score += 2.0
			if "fortified" in feature_tags:
				score += 1.5

			match str(prop.get("size", "")):
				"Royal":
					score += 6.0
				"Mansion":
					score += 5.0
				"Large":
					score += 4.0
				"Medium":
					score += 3.0
				"Small":
					score += 2.0

			score += float(prop.get("value", prop.get("price", prop.get("base_value", 0)))) / 1000000.0

			if score > best_score:
				best_score = score
				best_property = prop.duplicate(true)

	return best_property


static func _household_property_display_name(gs: GameState,
	prop: Dictionary) -> String:
	if prop.is_empty():
		return "Unknown Residence"

	var display_name: String = str(prop.get("nickname", "")).strip_edges()
	if display_name != "":
		return display_name

	display_name = str(prop.get("display_name", prop.get("type", "Property"))).strip_edges()
	if display_name != "":
		return display_name

	var size_name: String = str(prop.get("size", "")).strip_edges()
	if size_name != "" and gs != null and gs.property_engine != null and gs.property_engine.has_method("_property_type_for_size"):
		return str(gs.property_engine._property_type_for_size(size_name)).strip_edges()

	return "Residence"


static func _build_household_property_card_lines(gs: GameState,
	person: Person) -> Array:
	var lines: Array = []
	lines.append("===== HOUSEHOLD PROPERTY =====")

	if person == null or gs == null or gs.property_engine == null:
		lines.append("Residence: Unresolved")
		lines.append("No household property system is available right now.")
		lines.append("==============================")
		return lines

	var prop: Dictionary = AssetsSceneSupport._resolve_player_household_property_record(gs, person)
	if prop.is_empty():
		lines.append("Residence: Unresolved")
		lines.append("No owned property is currently linked to this household.")
		if str(person.home_city).strip_edges() != "" or str(person.home_country).strip_edges() != "":
			if str(person.home_city).strip_edges() != "" and str(person.home_country).strip_edges() != "":
				lines.append("Location: %s, %s" % [person.home_city, person.home_country])
			elif str(person.home_city).strip_edges() != "":
				lines.append("Location: %s" % person.home_city)
			else:
				lines.append("Location: %s" % person.home_country)
		lines.append("==============================")
		return lines

	var display_name: String = AssetsSceneSupport._household_property_display_name(gs, prop)
	var size_name: String = str(prop.get("size", "")).strip_edges()
	var era_form: String = display_name
	if size_name != "" and gs.property_engine.has_method("_property_type_for_size"):
		era_form = str(gs.property_engine._property_type_for_size(size_name)).strip_edges()

	var address_text: String = str(prop.get("address", "Unknown Address")).strip_edges()
	if address_text == "":
		address_text = "Unknown Address"

	var condition_score: int = int(round(float(prop.get("condition", 100.0))))
	var condition_label: String = str(prop.get("condition_label", "Excellent")).strip_edges()
	var social_tier: String = str(prop.get("social_tier", "common")).strip_edges()
	var value_band: String = str(prop.get("value_band", "entry")).strip_edges()
	var archetype: String = str(prop.get("archetype", "residence")).strip_edges()
	var feature_tags: Array = prop.get("feature_tags", [])

	var household_role: String = "Primary Household Residence"
	if "dynasty_seat" in feature_tags:
		household_role = "Dynasty Seat"
	elif "family_seat" in feature_tags:
		household_role = "Family Seat"
	elif "fortified" in feature_tags:
		household_role = "Fortified Residence"
	elif "luxury" in feature_tags:
		household_role = "Luxury Residence"

	lines.append("Residence: %s" % display_name)
	lines.append("Era Form: %s" % era_form)
	lines.append("Household Role: %s" % household_role)
	lines.append("Archetype: %s" % archetype.capitalize())
	if size_name != "":
		lines.append("Size Tier: %s" % size_name)
	lines.append("Address: %s" % address_text)
	lines.append("Condition: %d%% • %s" % [condition_score, condition_label])
	if social_tier != "":
		lines.append("Social Tier: %s" % social_tier.capitalize())
	if value_band != "":
		lines.append("Value Band: %s" % value_band.capitalize())

	var ambiance_bits: Array = []
	if "fortified" in feature_tags:
		ambiance_bits.append("fortified")
	if "luxury" in feature_tags:
		ambiance_bits.append("luxury")
	if "dense" in feature_tags:
		ambiance_bits.append("dense")
	if "family_seat" in feature_tags:
		ambiance_bits.append("family-seat")
	if "dynasty_seat" in feature_tags:
		ambiance_bits.append("dynasty-seat")

	if ambiance_bits.is_empty():
		lines.append("Property Feel: This household is anchored by a practical %s-era residence." % str(gs.era.name))
	else:
		lines.append("Property Feel: %s-era %s" % [str(gs.era.name), ", ".join(ambiance_bits)])

	lines.append("==============================")
	return lines

extends RefCounted
class_name GovernmentSceneSupport
## Government support for the main scene. State, when needed, is passed explicitly.


static func _era_country_ruler_surface_label(country_name: String, era_key: String, hash_value: int) -> String:
	var era_lower: String = str(era_key).strip_edges().to_lower()
	var clean_country: String = str(country_name).strip_edges()
	if clean_country == "":
		clean_country = "Unknown Country"

	if era_lower == "ancient":
		return ["High King", "Queen Regent", "Divine Steward", "Imperial Governor"] [hash_value % 4] + " of %s" % clean_country
	if era_lower == "medieval":
		return ["Crown Regent", "High Lord", "Sovereign", "Royal Steward"] [hash_value % 4] + " of %s" % clean_country
	if era_lower == "industrial":
		return ["Prime Minister", "Industrial Chancellor", "President", "Crown Minister"] [hash_value % 4] + " of %s" % clean_country
	if era_lower == "future":
		return ["Quantum Chancellor", "World Governor", "Civic AI Regent", "Planetary Steward"] [hash_value % 4] + " of %s" % clean_country

	return ["President", "Prime Minister", "Chancellor", "National Regent"] [hash_value % 4] + " of %s" % clean_country


static func _player_is_government_figure(p: Person) -> bool:
	if p == null:
		return false

	if bool(p.is_ruler):
		return true

	if bool(p.is_royal) or str(p.royal_title).strip_edges() != "":
		return true

	if int(p.succession_rank) >= 0 and int(p.succession_rank) <= 12:
		return true

	var office_fields: Array = [
		"government_role",
		"government_title",
		"political_office",
		"office_title",
		"elected_office",
		"public_office"
	]

	for field_name in office_fields:
		var raw_value: Variant = p.get(str(field_name))
		if raw_value != null and str(raw_value).strip_edges() != "":
			return true

	if typeof(p.traits) == TYPE_ARRAY:
		for raw_trait in p.traits:
			var trait_text: String = str(raw_trait).strip_edges().to_lower()
			if trait_text in [
				"president",
				"prime_minister",
				"governor",
				"mayor",
				"senator",
				"representative",
				"council_member",
				"minister",
				"chancellor",
				"government_official",
				"elected_official"
			]:
				return true

	return false


static func _crown_hub_mood_color(summary: Dictionary) -> Color:
	var happiness_value: int = clampi(int(summary.get("happiness", 50)), 0, 100)
	var approval_value: int = clampi(int(summary.get("approval", 50)), 0, 100)

	if happiness_value <= 24 or approval_value <= 24:
		return Color(0.34, 0.06, 0.07, 1.0)
	if happiness_value <= 44 or approval_value <= 44:
		return Color(0.32, 0.14, 0.06, 1.0)
	if happiness_value >= 78 and approval_value >= 70:
		return Color(0.1, 0.2, 0.14, 1.0)

	return Color(0.06, 0.08, 0.13, 1.0)


static func _crown_hub_ensure_named_label(parent: Control, node_name: String, font_size: int = 13) -> Label:
	if parent == null:
		return null

	var existing: Label = parent.get_node_or_null(node_name) as Label
	if existing != null:
		return existing

	var label:= Label.new()
	label.name = node_name
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	parent.add_child(label)
	return label


static func _crown_hub_projection_color(delta_value: int) -> Color:
	if delta_value > 0:
		return Color(0.45, 1.0, 0.58, 1.0)
	if delta_value < 0:
		return Color(1.0, 0.38, 0.3, 1.0)
	return Color(0.82, 0.82, 0.78, 0.92)


static func _crown_diplomacy_entry_key(
	entry: Dictionary
) -> String:
	var entry_key: String = str(
		entry.get(
			"realm_key",
			""
		)
	).strip_edges()

	if entry_key != "":
		return entry_key

	var realm_id: int = int(
		entry.get(
			"realm_id",
			-1
		)
	)

	if realm_id > 0:
		return "realm:%d" % realm_id

	return "country:%s" % str(
		entry.get(
			"country",
			"unknown"
		)
	).strip_edges().to_lower()


static func _crown_diplomacy_filter_specs() -> Array:
	return [
		{
			"key": "all",
			"label": "All"
		},
		{
			"key": "elemental",
			"label": "Elemental"
		},
		{
			"key": "empires",
			"label": "Empires"
		},
		{
			"key": "kingdoms",
			"label": "Kingdoms"
		},
		{
			"key": "republics",
			"label": "Republics"
		},
		{
			"key": "allies",
			"label": "Allies"
		},
		{
			"key": "neutral",
			"label": "Neutral"
		},
		{
			"key": "strained",
			"label": "Strained"
		},
		{
			"key": "war",
			"label": "At War"
		},
		{
			"key": "tradable",
			"label": "Tradable"
		},
		{
			"key": "era_kingdom",
			"label": "Era Kingdom"
		}
	]


static func _crown_diplomacy_entry_core_color(
	entry: Dictionary
) -> Color:
	if bool(
		entry.get(
			"is_era_kingdom",
			false
		)
	):
		return Color(
			0.72,
			0.34,
			1.0,
			1.0
		)

	if bool(
		entry.get(
			"is_player_country",
			false
		)
	):
		return Color(
			1.0,
			0.76,
			0.2,
			1.0
		)

	match str(
		entry.get(
			"element",
			""
		)
	).strip_edges().to_lower():
		"fire":
			return Color(
				1.0,
				0.28,
				0.12,
				1.0
			)

		"earth":
			return Color(
				0.4,
				0.72,
				0.26,
				1.0
			)

		"water":
			return Color(
				0.22,
				0.58,
				1.0,
				1.0
			)

		"air":
			return Color(
				0.82,
				0.9,
				1.0,
				1.0
			)

	var realm_kind: String = str(
		entry.get(
			"realm_kind",
			""
		)
	).strip_edges().to_lower()

	if realm_kind.find(
		"empire"
	) >= 0:
		return Color(
			0.82,
			0.34,
			0.3,
			1.0
		)

	if realm_kind.find(
		"kingdom"
	) >= 0:
		return Color(
			0.76,
			0.56,
			0.94,
			1.0
		)

	if realm_kind.find(
		"republic"
	) >= 0:
		return Color(
			0.34,
			0.66,
			1.0,
			1.0
		)

	return Color(
		0.42,
		0.72,
		0.96,
		1.0
	)


static func _crown_tiny_stat_bar(value: int) -> String:
	var filled: int = clamp(int(round(float(value) / 10.0)), 0, 10)
	var out: String = ""
	for i in range(10):
		out += "▰" if i < filled else "▱"
	return out


static func _grant_crown_wisdom_willpower(target: Person, amount: int) -> void:
	if target == null:
		return

	var gain: float = float(max(amount, 0))
	target.willpower = clamp(float(target.willpower) + gain, 0.0, 250.0)

	if typeof(target.willpower_profile) == TYPE_DICTIONARY:
		target.willpower_profile ["core_score"] = max(float(target.willpower_profile.get("core_score", 0.0)), float(target.willpower))
		target.willpower_profile ["last_crown_wisdom_gain"] = gain
		target.willpower_profile ["last_crown_wisdom_gain_at_ms"] = int(Time.get_ticks_msec())


static func _crown_is_era_kingdom_country(country_name: String) -> bool:
	var clean: String = str(country_name).strip_edges().to_lower()
	return clean == "era kingdom" or clean == "the era kingdom"


static func _crown_exact_number(value: int) -> String:
	var number: int = int(value)
	var sign_text: String = ""
	if number < 0:
		sign_text = "-"
		number = abs(number)

	var raw_text: String = str(number)
	var out: String = ""
	var counter: int = 0

	for i in range(raw_text.length() - 1, -1, -1):
		if counter > 0 and counter % 3 == 0:
			out = "," + out
		out = raw_text.substr(i, 1) + out
		counter += 1

	return sign_text + out


static func _calculate_crown_tax_revenue(population: int, tax_rate: float, realm: Dictionary = {}) -> int:
	if population <= 0 or tax_rate <= 0.0:
		return 0
	var quality: float = float(realm.get("quality", realm.get("country_quality", 50.0)))
	var prosperity: float = float(realm.get("prosperity", realm.get("realm_quality", 0.0)))
	var land: float = float(realm.get("land", realm.get("land_size", 0.0)))
	var taxable_income_per_citizen: float = max(24.0, 120.0 + (quality * 6.0) + (prosperity * 2.5) + min(80.0, land * 0.04))
	return max(0, int(round(float(population) * taxable_income_per_citizen * (tax_rate / 100.0))))


static func _crown_allocation_bucket_help_line(bucket_key: String) -> String:
	match str(bucket_key):
		"treasury_pct":
			return "Treasury protects the reserve and stabilizes future choices."
		"military_pct":
			return "Military production raises force projection but can make goods feel thinner."
		"goods_pct":
			return "Goods production supports the people and the economy, but reduces immediate military pressure."
		_:
			return "Remaining buckets auto-balance live."


static func _crown_diplomacy_card_leader_text(
	entry: Dictionary
) -> String:
	var label_text: String = str(
		entry.get(
			"ruler_label",
			entry.get(
				"leader_label",
				""
			)
		)
	).strip_edges()

	while label_text != "":
		var lower_text: String = (
			label_text.to_lower()
		)

		if lower_text.begins_with(
			"leader:"
		):
			label_text = label_text.substr(
				"leader:".length()
			).strip_edges()
			continue

		if lower_text.begins_with(
			"leader -"
		):
			label_text = label_text.substr(
				"leader -".length()
			).strip_edges()
			continue

		if lower_text.begins_with(
			"leader —"
		):
			label_text = label_text.substr(
				"leader —".length()
			).strip_edges()
			continue

		break

	if label_text == "":
		label_text = "Unassigned Office Holder"

	return "Leader: %s" % label_text


static func _format_crown_compact_scaled_value(
	scaled: float
) -> String:
	var label: String = ""

	if scaled < 10.0:
		label = "%0.2f" % scaled
	elif scaled < 100.0:
		label = "%0.1f" % scaled
	else:
		label = "%0.0f" % scaled



	if label.find(".") >= 0:
		while label.ends_with("0"):
			label = label.substr(
				0,
				maxi(
					0,
					label.length() - 1
				)
			)

		if label.ends_with("."):
			label = label.substr(
				0,
				maxi(
					0,
					label.length() - 1
				)
			)

	return label


static func _sanitize_crown_allocation_split(draft: Dictionary) -> Dictionary:
	var out: Dictionary = draft.duplicate(true)
	var tax_rate: float = clamp(float(out.get("tax_rate", 10.0)), 0.0, 40.0)
	var treasury_pct: int = clamp(int(out.get("treasury_pct", 34)), 0, 100)
	var military_pct: int = clamp(int(out.get("military_pct", 33)), 0, 100)
	var goods_pct: int = clamp(int(out.get("goods_pct", 33)), 0, 100)

	var total_pct: int = treasury_pct + military_pct + goods_pct
	if total_pct != 100:
		if total_pct <= 0:
			treasury_pct = 34
			military_pct = 33
			goods_pct = 33
		else:
			var pct_scale: float = 100.0 / float(total_pct)
			treasury_pct = clamp(int(round(float(treasury_pct) * pct_scale)), 0, 100)
			military_pct = clamp(int(round(float(military_pct) * pct_scale)), 0, 100)
			goods_pct = clamp(int(round(float(goods_pct) * pct_scale)), 0, 100)

			var fixed_total: int = treasury_pct + military_pct + goods_pct
			if fixed_total != 100:
				goods_pct += 100 - fixed_total

	if goods_pct < 0:
		goods_pct = 0

	out ["tax_rate"] = tax_rate
	out ["treasury_pct"] = treasury_pct
	out ["military_pct"] = military_pct
	out ["goods_pct"] = goods_pct
	return out


static func _crown_tax_pressure_delta(
		tax_rate: float,
		channel: String
) -> int:
		var clean_tax: float = clamp(
			float(tax_rate),
			0.0,
			40.0
		)
		var clean_channel: String = str(
			channel
		).strip_edges().to_lower()

		if clean_tax <= 13.0:
			var relief_ratio: float = clamp(
				(13.0 - clean_tax) / 13.0,
				0.0,
				1.0
			)

			match clean_channel:
				"happiness":
					return int(
						round(
							pow(
								relief_ratio,
								0.88
							) * 24.0
						)
					)
				"approval":
					return int(
						round(
							pow(
								relief_ratio,
								0.92
							) * 18.0
						)
					)
				"respect":
					return int(
						round(
							pow(
								relief_ratio,
								0.96
							) * 12.0
						)
					)
				_:
					return 0

		var over_tax: float = clean_tax - 13.0

		match clean_channel:
			"happiness":
				return clamp(
					-2
					- int(
						round(
							pow(over_tax, 1.35) * 1.35
						)
					),
					-60,
					0
				)
			"approval":
				return clamp(
					-2
					- int(
						round(
							pow(over_tax, 1.3) * 1.1
						)
					),
					-50,
					0
				)
			"respect":
				return clamp(
					-1
					- int(
						round(
							pow(over_tax, 1.25) * 0.95
						)
					),
					-40,
					0
				)
			_:
				return 0


static func _crown_popup_title_for_event(event_name: String) -> String:
	match str(event_name).strip_edges():
		"crown_execution":
			return "Execution Ordered"
		"crown_exile":
			return "Exile Ordered"
		"crown_pardon":
			return "Mercy Granted"
		"crown_country_trade", "crown_trade":
			return "Trade Route Opened"
		"crown_country_gift", "crown_gift":
			return "Diplomatic Gift Sent"
		"crown_country_bribe", "crown_bribe":
			return "Bribe Sent"
		"crown_country_war":
			return "WAR DECLARED"
		"crown_law_signed":
			return "Law Signed"
		"crown_law_rejected":
			return "Law Rejected"
		"crown_law_revised":
			return "Law Revised"
		"crown_law_delayed":
			return "Law Delayed"
		"crown_citizen_mediation":
			return "Citizens Mediated"
		_:
			return "Crown Decision"


static func _crown_title_case(text: String) -> String:
	var out: Array = []
	for raw_word in str(text).strip_edges().split(" "):
		var word: String = str(raw_word).strip_edges()
		if word == "":
			continue
		out.append(word.substr(0, 1).to_upper() + word.substr(1).to_lower())
	return " ".join(out)


static func _crown_relation_label(
	score: int
) -> String:
	if score >= 60:
		return "Allied"

	if score >= 25:
		return "Friendly"

	if score >= 0:
		return "Neutral"

	if score >= -24:
		return "Unfriendly"

	if score >= -49:
		return "Strained"

	if score >= -69:
		return "Hostile"

	if score >= -84:
		return "Enemies"

	if score >= -99:
		return "Sworn enemies"

	return "Pure enemies"


static func _format_civic_office_article_title(job: String) -> String:
	var clean_job: String = str(job).strip_edges()
	var lower_job: String = clean_job.to_lower()

	if lower_job == "president" or lower_job == "president of the united states":
		return "The President of the United States"

	if lower_job == "first lady":
		return "The First Lady"

	if lower_job == "first gentleman":
		return "The First Gentleman"

	return ""


static func _format_birth_relative_civic_role(npc: Person) -> String:
	if npc == null:
		return ""

	var civic_title: String = str(npc.get("civic_title")).strip_edges()
	var job_text: String = str(npc.job).strip_edges()

	for raw_text in [civic_title, job_text]:
		var clean_text: String = str(raw_text).strip_edges()
		var lower_text: String = clean_text.to_lower()

		if lower_text == "president" or lower_text == "president of the united states":
			return "The President of the United States"

		if lower_text == "first lady":
			return "The First Lady"

		if lower_text == "first gentleman":
			return "The First Gentleman"

	return ""


static func _government_style_supports_royalty(government_style: String) -> bool:
	var style_text:= str(government_style).strip_edges().to_lower()
	return style_text in ["monarchy", "empire"]


static func _god_mode_birth_royal_rank_seed(settings: Dictionary) -> String:
	var rank_seed: String = str(settings.get("royal_rank", "")).strip_edges()
	if rank_seed == "Lesser Royal":
		return "Ducal Line"
	return rank_seed


static func _extract_compact_politics_fragment(line: String, label: String) -> String:
	var source: String = str(line).strip_edges()
	var lower_source: String = source.to_lower()
	var lower_label: String = label.to_lower()
	var start: int = lower_source.find(lower_label)
	if start == -1:
		return ""
	var end: int = source.length()
	var delimiters: Array = [",", "•", "|", ";"]
	for raw_delimiter in delimiters:
		var delimiter: String = str(raw_delimiter)
		var candidate: int = source.find(delimiter, start)
		if candidate != -1 and candidate < end:
			end = candidate
	var fragment: String = source.substr(start, end - start).strip_edges()
	while fragment.begins_with(":") or fragment.begins_with("-") or fragment.begins_with("—"):
		if fragment.length() <= 1:
			break
		fragment = fragment.substr(1, fragment.length() - 1).strip_edges()
	return fragment


static func _compact_politics_payload_from_fragment(fragment: String, label: String) -> String:
	var out: String = str(fragment).strip_edges()
	var lower_out: String = out.to_lower()
	var lower_label: String = label.to_lower()
	if lower_out.begins_with(lower_label):
		out = out.substr(label.length(), out.length() - label.length()).strip_edges()
	while out.begins_with(":") or out.begins_with("-") or out.begins_with("—"):
		if out.length() <= 1:
			break
		out = out.substr(1, out.length() - 1).strip_edges()
	return out if out != "" else str(fragment).strip_edges()


static func _append_compact_politics_row(rows: Array, seen: Dictionary, label: String, payload: String) -> void:
	var clean_payload: String = str(payload).strip_edges()
	if clean_payload == "":
		return
	var row: String = "%s • %s" % [label, clean_payload]
	if seen.has(row):
		return
	seen [row] = true
	rows.append(row)


static func _royal_court_role_priority(role: String) -> int:
	match str(role).strip_edges():
		"ruler":
			return 0
		"heir":
			return 1
		"consort":
			return 2
		"regent":
			return 3
		"advisor":
			return 4
		"guard_captain":
			return 5
		"spymaster":
			return 6
		"envoy":
			return 7
		_:
			return 99


static func _royal_court_role_display(role: String) -> String:
	match str(role).strip_edges():
		"ruler":
			return "Ruler"
		"heir":
			return "Heir"
		"consort":
			return "Consort"
		"regent":
			return "Regent"
		"advisor":
			return "Advisor"
		"guard_captain":
			return "Guard Captain"
		"spymaster":
			return "Spymaster"
		"envoy":
			return "Envoy"
		"courtier":
			return "Courtier"
		_:
			return str(role).replace("_", " ").capitalize()


static func _resolve_player_crown_pressure(gs: GameState) -> Dictionary:
	if gs == null or gs.player == null:
		return {}
	if typeof(gs.transient_scenario_biases) != TYPE_DICTIONARY:
		return {}
	var raw_bias: Variant = gs.transient_scenario_biases.get(int(gs.player.id), {})
	var bias: Dictionary = {}
	if typeof(raw_bias) == TYPE_ARRAY:
		var bucket: Array = raw_bias
		if not bucket.is_empty() and typeof(bucket [0]) == TYPE_DICTIONARY:
			bias = bucket [0]
	elif typeof(raw_bias) == TYPE_DICTIONARY:
		bias = raw_bias
	var faction_pressure_raw: Variant = bias.get("faction_pressure", {})
	return faction_pressure_raw if typeof(faction_pressure_raw) == TYPE_DICTIONARY else {}


static func _person_has_government_command_surface_access(gs: GameState,
	person: Person) -> bool:
	if person == null:
		return false

	var office_raw: Variant = person.get("civic_office_contract")
	if typeof(office_raw) == TYPE_DICTIONARY:
		var office: Dictionary = (office_raw as Dictionary).duplicate(true)
		var government_model: String = str(office.get("government_model", "")).strip_edges().to_lower()
		var office_name: String = str(office.get("office", "")).strip_edges().to_lower()
		var office_title: String = str(office.get("office_full_title", "")).strip_edges().to_lower()
		var branch_name: String = str(office.get("branch", "")).strip_edges().to_lower()

		if bool(office.get("ruling_power_by_office", false)):
			return true

		if bool(office.get("crown_hub_access", false)):
			return true

		if bool(office.get("government_command_surface_access", false)):
			return true

		if branch_name == "executive" and office_name != "":
			return true

		if government_model in [
			"federal_presidential_republic",
			"federal_republic",
			"presidential_republic",
			"constitutional_republic",
			"democracy",
			"republic"
		] and office_name in [
			"president",
			"prime minister",
			"chancellor",
			"governor",
			"executive"
		]:
			return true

		if office_title in [
			"the president of the united states",
			"president of the united states",
			"prime minister",
			"chancellor",
			"governor"
		]:
			return true

	var civic_title: String = str(person.get("civic_title")).strip_edges().to_lower()
	var job_text: String = str(person.job).strip_edges().to_lower()

	if civic_title in [
		"president",
		"prime minister",
		"chancellor",
		"governor"
	]:
		return true

	if job_text in [
		"president",
		"president of the united states",
		"prime minister",
		"chancellor",
		"governor"
	]:
		return true

	if bool(person.is_ruler) and not bool(person.is_royal):
		var social_class: String = str(person.social_class).strip_edges()
		if social_class not in ["Royal", "Noble"]:
			return true

	if gs != null and gs.has_method("get_npc_facts_by_id"):
		var facts: Dictionary = gs.get_npc_facts_by_id(int(person.id))
		if bool(facts.get("government_command_surface_access", false)):
			return true

		var facts_office_raw: Variant = facts.get("civic_office_contract", {})
		if typeof(facts_office_raw) == TYPE_DICTIONARY:
			var facts_office: Dictionary = (facts_office_raw as Dictionary).duplicate(true)
			if bool(facts_office.get("ruling_power_by_office", false)):
				return true
			if bool(facts_office.get("crown_hub_access", false)):
				return true
			if bool(facts_office.get("government_command_surface_access", false)):
				return true

			var facts_government_model: String = str(facts_office.get("government_model", "")).strip_edges().to_lower()
			var facts_office_name: String = str(facts_office.get("office", "")).strip_edges().to_lower()
			var facts_branch_name: String = str(facts_office.get("branch", "")).strip_edges().to_lower()

			if facts_branch_name == "executive" and facts_office_name != "":
				return true

			if facts_government_model in [
				"federal_presidential_republic",
				"federal_republic",
				"presidential_republic",
				"constitutional_republic",
				"democracy",
				"republic"
			] and facts_office_name in [
				"president",
				"prime minister",
				"chancellor",
				"governor",
				"executive"
			]:
				return true

	return false


static func _resolve_player_government_style(gs: GameState) -> String:
	var realm: Dictionary = WorldSceneSupport._resolve_player_realm_dict(gs)
	var style: String = str(realm.get("government_style", "")).strip_edges()
	if style != "":
		return style

	if gs != null and gs.player != null:
		var office_raw: Variant = gs.player.get("civic_office_contract")
		if typeof(office_raw) == TYPE_DICTIONARY:
			var office: Dictionary = office_raw
			var government_model: String = str(office.get("government_model", "")).strip_edges().to_lower()
			match government_model:
				"federal_presidential_republic", "federal_republic":
					return "Federal Republic"
				"presidential_republic", "constitutional_republic", "republic":
					return "Republic"
				"democracy":
					return "Democracy"
				"dictatorship":
					return "Dictatorship"

		if GovernmentSceneSupport._person_has_government_command_surface_access(gs, gs.player):
			return "Federal Republic" if GovernmentSceneSupport._player_is_federal_republic_office_holder(gs) else "State"

		if bool(gs.player.is_ruler) or bool(gs.player.is_royal):
			return "Monarchy"

	return "State"


static func _crown_hub_depth_style(target: Control, meta_key: String, layer: String, accent: Color, selected: bool = false, danger: bool = false) -> StyleBoxFlat:
	var radius: int = 16
	var border_width: int = 1
	var bg: Color = Color(0.06, 0.07, 0.11, 0.92)
	var border: Color = Color(accent.r, accent.g, accent.b, 0.32)

	match layer:
		"tabs":
			radius = 15
			border_width = 2
			bg = Color(accent.r, accent.g, accent.b, 0.3 if selected else 0.12)
			border = Color(accent.r, accent.g, accent.b, 0.94 if selected else 0.38)
		"raised":
			radius = 20
			border_width = 2
			bg = Color(0.09, 0.08, 0.13, 0.96)
			border = Color(accent.r, accent.g, accent.b, 0.62)
		"recessed":
			radius = 18
			border_width = 1
			bg = Color(0.035, 0.043, 0.066, 0.96)
			border = Color(accent.r, accent.g, accent.b, 0.24)
		"lowest":
			radius = 12
			border_width = 1
			bg = Color(0.025, 0.03, 0.045, 0.94)
			border = Color(accent.r, accent.g, accent.b, 0.16)
		"danger":
			radius = 18
			border_width = 2
			bg = Color(0.17, 0.035, 0.045, 0.96)
			border = Color(1.0, 0.2, 0.16, 0.82)
		_:
			pass

	if danger:
		bg = Color(0.16, 0.035, 0.045, 0.96)
		border = Color(1.0, 0.24, 0.18, 0.86)

	var style: StyleBoxFlat = AppearanceSceneSupport._runtime_stylebox_flat_from_meta(target, meta_key, border_width, radius)
	if style == null:
		style = StyleBoxFlat.new()

	style.bg_color = bg
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.border_color = border
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius

	return style


static func _crown_hub_identity_line(gs: GameState,
	summary: Dictionary) -> String:
	var title_text: String = str(summary.get("title", gs.player.royal_title if gs != null and gs.player != null else "Ruler")).strip_edges()
	var realm_name: String = str(summary.get("realm_name", gs.player.home_country if gs != null and gs.player != null else "Realm")).strip_edges()

	if bool(summary.get("federal_republic", false)):
		if title_text == "":
			title_text = "Federal Officer"
		if realm_name == "":
			realm_name = "the United States"
		return "You are %s in %s" % [title_text, realm_name]

	if title_text == "":
		title_text = "Ruler"
	if realm_name == "":
		realm_name = "the Realm"

	return "You are %s of %s" % [title_text, realm_name]


static func _player_is_federal_republic_office_holder(gs: GameState) -> bool:
	if gs == null or gs.player == null:
		return false

	var office: Dictionary = gs.player.get("civic_office_contract")
	if typeof(office) == TYPE_DICTIONARY:
		if str(office.get("government_model", "")).strip_edges() == "federal_presidential_republic":
			return true

	var job_text: String = str(gs.player.job).strip_edges().to_lower()
	return job_text == "president of the united states" or job_text == "president"


static func _belonging_popup_action_routes_to_crown_hub(
	action_spec: Dictionary
) -> bool:
	var payload: Dictionary = ValueSceneSupport._safe_dictionary(
		action_spec.get(
			"payload",
			{}
		)
	)
	var action_id: String = str(
		payload.get(
			"action",
			action_spec.get(
				"action_id",
				action_spec.get(
					"id",
					""
				)
			)
		)
	).strip_edges().to_lower()

	return action_id == "access_federal_republic_crown_hub"


static func _append_crown_war_side_column(
	parent: HBoxContainer,
	side_contract: Dictionary,
	title: String,
	accent: Color
) -> void:
	if parent == null:
		return

	var column:= VBoxContainer.new()
	column.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)
	column.add_theme_constant_override(
		"separation",
		8
	)
	parent.add_child(
		column
	)

	var header:= Label.new()
	header.text = title
	header.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)
	header.add_theme_font_size_override(
		"font_size",
		18
	)
	header.add_theme_color_override(
		"font_color",
		accent
	)
	column.add_child(
		header
	)

	for raw_card in ValueSceneSupport._safe_array(
		side_contract.get(
			"realm_cards",
			[]
		)
	):
		var card_contract: Dictionary = ValueSceneSupport._safe_dictionary(
			raw_card
		)

		if card_contract.is_empty():
			continue

		var panel:= PanelContainer.new()
		panel.size_flags_horizontal = (
			Control.SIZE_EXPAND_FILL
		)

		var panel_style:= StyleBoxFlat.new()
		panel_style.bg_color = Color(
			accent.r * 0.11,
			accent.g * 0.11,
			accent.b * 0.11,
			0.98
		)
		panel_style.border_color = Color(
			accent.r,
			accent.g,
			accent.b,
			0.86
		)
		panel_style.set_border_width_all(
			2
		)
		panel_style.set_corner_radius_all(
			14
		)
		panel.add_theme_stylebox_override(
			"panel",
			panel_style
		)
		column.add_child(
			panel
		)

		var margin:= MarginContainer.new()
		margin.add_theme_constant_override(
			"margin_left",
			12
		)
		margin.add_theme_constant_override(
			"margin_top",
			10
		)
		margin.add_theme_constant_override(
			"margin_right",
			12
		)
		margin.add_theme_constant_override(
			"margin_bottom",
			10
		)
		panel.add_child(
			margin
		)

		var body:= VBoxContainer.new()
		body.add_theme_constant_override(
			"separation",
			5
		)
		margin.add_child(
			body
		)

		var banner:= Label.new()
		banner.text = "AT WAR"
		banner.horizontal_alignment = (
			HORIZONTAL_ALIGNMENT_CENTER
		)
		banner.add_theme_font_size_override(
			"font_size",
			17
		)
		banner.add_theme_color_override(
			"font_color",
			Color(
				1.0,
				0.24,
				0.18,
				1.0
			)
		)
		body.add_child(
			banner
		)

		var name_label:= Label.new()
		name_label.text = str(
			card_contract.get(
				"name",
				"Unknown Realm"
			)
		)
		name_label.horizontal_alignment = (
			HORIZONTAL_ALIGNMENT_CENTER
		)
		name_label.add_theme_font_size_override(
			"font_size",
			20
		)
		name_label.add_theme_color_override(
			"font_color",
			accent
		)
		body.add_child(
			name_label
		)

		var stats:= Label.new()
		stats.text = (
			"Military: %s\nPopulation: %s\nTreasury: %s\nGoods: %s"
			% [
				GovernmentSceneSupport._crown_exact_number(
					int(
						card_contract.get(
							"military",
							0
						)
					)
				),
				GovernmentSceneSupport._crown_exact_number(
					int(
						card_contract.get(
							"population",
							0
						)
					)
				),
				GovernmentSceneSupport._crown_exact_number(
					int(
						card_contract.get(
							"treasury",
							0
						)
					)
				),
				GovernmentSceneSupport._crown_exact_number(
					int(
						card_contract.get(
							"goods",
							0
						)
					)
				)
			]
		)
		stats.horizontal_alignment = (
			HORIZONTAL_ALIGNMENT_CENTER
		)
		body.add_child(
			stats
		)


static func _crown_current_era_key(gs: GameState) -> String:
	if gs == null:
		return "Modern"

	if gs.era != null and typeof(gs.era) == TYPE_DICTIONARY:
		var era_name: String = str(gs.era.get("name", gs.era.get("key", ""))).strip_edges()
		if era_name != "":
			return era_name

	if gs.era_engine != null and gs.era_engine.has_method("_era_from_year"):
		var era_dict: Dictionary = gs.era_engine._era_from_year(int(gs.year))
		return str(era_dict.get("name", era_dict.get("key", "Modern")))

	return "Modern"


static func _build_crown_law_review_proposal(gs: GameState) -> Dictionary:
	var era_key: String = GovernmentSceneSupport._crown_current_era_key(gs)
	var era_lower: String = era_key.strip_edges().to_lower()
	var pool: Array = []

	match era_lower:
		"ancient":
			pool = [
				{ "title": "Burial Ground Protection Edict", "description": "Make it illegal to hunt, loot, or hold games on burial grounds.", "risk_label": "Sacred law", "approval_on_sign": 7, "approval_on_reject": -8, "approval_on_revise": 2, "approval_on_delay": -2},
				{ "title": "Daily Parent Reverence Law", "description": "Require children to say 'I love you' to their parents every day before sunset.", "risk_label": "Goofy but popular", "approval_on_sign": 2, "approval_on_reject": 1, "approval_on_revise": 1, "approval_on_delay": 0},
				{ "title": "Anti-Government Speech Ban", "description": "Make it illegal to speak openly against the government.", "risk_label": "Authoritarian danger", "approval_on_sign": -15, "approval_on_reject": 8, "approval_on_revise": 3, "approval_on_delay": -3}
			]
		"medieval":
			pool = [
				{ "title": "Protected Orchard Law", "description": "Ban nobles from seizing common orchard harvests during winter.", "risk_label": "Pro-commoner reform", "approval_on_sign": 9, "approval_on_reject": -10, "approval_on_revise": 3, "approval_on_delay": -2},
				{ "title": "Mandatory Compliment to the Crown", "description": "Require citizens to compliment the ruler's outfit during public festivals.", "risk_label": "Deeply unserious", "approval_on_sign": -1, "approval_on_reject": 3, "approval_on_revise": 1, "approval_on_delay": 0},
				{ "title": "Forest Burial Peace Act", "description": "Make it illegal to hunt in burial woods and ancestral grave fields.", "risk_label": "Spiritual protection", "approval_on_sign": 6, "approval_on_reject": -7, "approval_on_revise": 2, "approval_on_delay": -1}
			]
		"industrial":
			pool = [
				{ "title": "Factory Child Safety Act", "description": "Limit dangerous factory work for children and require inspections.", "risk_label": "Moral reform", "approval_on_sign": 12, "approval_on_reject": -16, "approval_on_revise": 5, "approval_on_delay": -4},
				{ "title": "Anti-Whistle Law", "description": "Make factory whistles after midnight illegal unless the whistle sounds polite.", "risk_label": "Goofy nuisance law", "approval_on_sign": 1, "approval_on_reject": 2, "approval_on_revise": 1, "approval_on_delay": 0},
				{ "title": "Seditious Pamphlet Ban", "description": "Criminalize printed criticism of the government.", "risk_label": "Civil liberty crisis", "approval_on_sign": -14, "approval_on_reject": 9, "approval_on_revise": 2, "approval_on_delay": -3}
			]
		"future":
			pool = [
				{ "title": "Synthetic Memory Consent Act", "description": "Require consent before corporations can simulate a citizen's memories.", "risk_label": "Human rights protection", "approval_on_sign": 13, "approval_on_reject": -15, "approval_on_revise": 4, "approval_on_delay": -3},
				{ "title": "Mandatory Robot Thank-You Law", "description": "Require citizens to thank service robots at least once per transaction.", "risk_label": "Goofy civic etiquette", "approval_on_sign": 2, "approval_on_reject": 1, "approval_on_revise": 1, "approval_on_delay": 0},
				{ "title": "Predictive Dissent Lockdown", "description": "Allow the state to punish citizens for future anti-government speech predicted by AI.", "risk_label": "Extremely dangerous", "approval_on_sign": -22, "approval_on_reject": 14, "approval_on_revise": 2, "approval_on_delay": -5}
			]
		_:
			pool = [
				{ "title": "Burial Ground Protection Act", "description": "Make it illegal to hunt in burial grounds or profit from sacred sites.", "risk_label": "Respectful public law", "approval_on_sign": 7, "approval_on_reject": -8, "approval_on_revise": 2, "approval_on_delay": -1},
				{ "title": "Mandatory Daily Parent Affection Act", "description": "Require children to say 'I love you' to their parents every day.", "risk_label": "Goofy family law", "approval_on_sign": 1, "approval_on_reject": 2, "approval_on_revise": 1, "approval_on_delay": 0},
				{ "title": "Government Criticism Ban", "description": "Make it illegal to speak out against the government.", "risk_label": "Authoritarian danger", "approval_on_sign": -18, "approval_on_reject": 11, "approval_on_revise": 3, "approval_on_delay": -4}
			]

	var law_seed_bucket: int = int(floor(float(Time.get_ticks_msec()) / 9000.0))
	var seed_text: String = "%s.%s.%s.%s" % [
		era_key,
		str(gs.player.first_name) if gs != null and gs.player != null else "ruler",
		str(gs.player.last_name) if gs != null and gs.player != null else "realm",
		str(law_seed_bucket)
	]
	var seed_value: int = int(hash(seed_text))
	if seed_value < 0:
		seed_value = - seed_value
	if seed_value <= 0:
		seed_value = 1

	var rng:= RandomNumberGenerator.new()
	rng.seed = seed_value

	var proposal: Dictionary = pool [int(rng.randi_range(0, pool.size() - 1))].duplicate(true)
	proposal ["era"] = era_key
	proposal ["court_reading"] = "The royal court believes this law could shape public trust, fear, tradition, and legitimacy."
	proposal ["created_at_ms"] = int(Time.get_ticks_msec())
	return proposal


static func _find_crown_cached_realm_id_for_country(gs: GameState,
	country_name: String) -> int:
	if gs == null or gs.realm_engine == null:
		return -1

	var clean_country: String = str(country_name).strip_edges().to_lower()
	if clean_country == "":
		return -1

	var realms_raw: Variant = gs.realm_engine.realms
	var realms: Dictionary = realms_raw if typeof(realms_raw) == TYPE_DICTIONARY else {}

	for raw_realm_id in realms.keys():
		var realm_raw: Variant = realms.get(raw_realm_id, {})
		if typeof(realm_raw) != TYPE_DICTIONARY:
			continue

		var realm: Dictionary = realm_raw
		var candidates: Array = [
			str(realm.get("country", "")),
			str(realm.get("country_name", "")),
			str(realm.get("nation", "")),
			str(realm.get("home_country", "")),
			str(realm.get("name", ""))
		]

		for raw_candidate in candidates:
			var candidate: String = str(raw_candidate).strip_edges().to_lower()
			if candidate != "" and candidate == clean_country:
				return int(raw_realm_id)

	return -1


static func _crown_is_player_ruling_country(gs: GameState,
	country_name: String, realm_id: int = -1, realm: Dictionary = {}) -> bool:
	if gs == null or gs.player == null:
		return false

	var p:= gs.player
	if realm_id > 0 and int(p.realm_id) == realm_id:
		return true

	var realm_ruler_id: int = int(realm.get("ruler_id", realm.get("leader_id", -1)))
	if realm_ruler_id > 0 and realm_ruler_id == int(p.id):
		return true

	var clean_country: String = str(country_name).strip_edges().to_lower()
	var candidate_names: Array = [
		str(p.home_country).strip_edges().to_lower(),
		str(p.birth_country).strip_edges().to_lower(),
		str(p.bending_nation).strip_edges().to_lower(),
		str(realm.get("name", "")).strip_edges().to_lower()
	]

	for raw_name in candidate_names:
		var candidate: String = str(raw_name).strip_edges().to_lower()
		if candidate != "" and candidate == clean_country:
			return true

	return false


static func _crown_preferred_capital_for_country(gs: GameState,
	country_name: String, era_key: String) -> String:
	if gs == null:
		return ""

	var clean_country: String = str(country_name).strip_edges()
	if clean_country == "":
		return ""

	if gs.player != null and str(gs.player.home_country).strip_edges().to_lower() == clean_country.to_lower():
		var player_city: String = str(gs.player.home_city).strip_edges()
		if player_city != "":
			return player_city

	if gs.era_engine != null and gs.era_engine.has_method("get_cities_for_era_country"):
		var cities: Array = gs.era_engine.get_cities_for_era_country(era_key, clean_country)
		if not cities.is_empty():
			return str(cities [0]).strip_edges()

	return ""


static func _crown_country_ruler_label(gs: GameState,
	realm: Dictionary, country_name: String) -> String:
	if gs == null:
		return "Unknown Leader"

	var ruler_id: int = int(realm.get("ruler_id", realm.get("leader_id", -1)))
	var government_style: String = str(realm.get("government_style", "")).strip_edges()
	var fallback_name: String = str(realm.get("ruler_name", realm.get("leader_name", ""))).strip_edges()

	if ruler_id > 0:
		var ruler: Person = gs.get_or_reactivate_npc_by_id(ruler_id)
		if ruler != null:
			var full_name: String = ("%s %s" % [str(ruler.first_name), str(ruler.last_name)]).strip_edges()
			var royal_title: String = str(ruler.royal_title).strip_edges()
			if royal_title != "":
				return "%s %s" % [royal_title, full_name]

			var leader_title: String = GovernmentSceneSupport._crown_leader_title_for_government(government_style, ruler)
			return "%s %s" % [leader_title, full_name]

	if fallback_name != "":
		return fallback_name

	return "%s Leader" % str(country_name).strip_edges()


static func _crown_leader_title_for_government(government_style: String, ruler: Person = null) -> String:
	var style: String = str(government_style).strip_edges().to_lower()

	if ruler != null:
		var job_title: String = str(ruler.job).strip_edges()
		if job_title != "" and not job_title.to_lower() in ["unemployed", "student"]:
			return GovernmentSceneSupport._crown_title_case(job_title)

	match style:
		"monarchy":
			return "Ruler"
		"democracy":
			return "President"
		"republic":
			return "President"
		"dictatorship":
			return "Supreme Leader"
		"communism":
			return "General Secretary"
		"anarchy":
			return "Council Speaker"
		_:
			return "Leader"


static func _format_crown_exact_treasury_label(gs: GameState,
	amount: int, currency_name: String) -> String:
	var clean_currency: String = str(currency_name).strip_edges()
	if clean_currency == "":
		clean_currency = GovernmentSceneSupport._crown_default_currency_name_for_realm(gs, "")
	return "%s %s" % [GovernmentSceneSupport._crown_exact_number(amount), clean_currency]


static func _find_active_crown_person_by_id(gs: GameState,
	person_id: int) -> Person:
	if gs == null or person_id <= 0:
		return null

	if gs.player != null and int(gs.player.id) == person_id:
		return gs.player

	for raw_npc in gs.npcs:
		var npc: Person = raw_npc
		if npc != null and int(npc.id) == person_id:
			return npc

	return null


static func _get_crown_allocation_draft_key(gs: GameState) -> String:
	if gs == null or gs.player == null:
		return ""
	return "%d:%d" % [int(gs.player.realm_id), int(gs.year)]


static func _apply_crown_pending_tax_effects(gs: GameState,
	realm: Dictionary) -> Dictionary:
	if gs == null or gs.player == null:
		return realm
	if realm.is_empty():
		return realm
	var pending_year: int = int(realm.get("pending_tax_effect_year", -1))
	if pending_year <= 0 or int(gs.year) < pending_year:
		return realm
	if int(realm.get("tax_effect_applied_year", -1)) == int(gs.year):
		return realm
	var p:= gs.player
	var approval_delta: int = int(realm.get("pending_tax_approval_delta", 0))
	var happiness_delta: int = int(realm.get("pending_tax_happiness_delta", 0))
	var respect_delta: int = int(realm.get("pending_tax_respect_delta", 0))
	p.approval = clamp(int(p.approval) + approval_delta, 0, 100)
	realm ["happiness"] = clamp(int(realm.get("happiness", 50)) + happiness_delta, 0, 100)
	realm ["respect_bias"] = clamp(int(realm.get("respect_bias", 0)) + respect_delta, -40, 40)
	realm ["tax_effect_applied_year"] = int(gs.year)
	if gs.realm_engine != null and int(p.realm_id) > 0:
		gs.realm_engine.realms [int(p.realm_id)] = realm
	return realm


static func _rebalance_crown_allocation_draft(draft: Dictionary, changed_key: String, requested_value: int) -> Dictionary:
	var out: Dictionary = GovernmentSceneSupport._sanitize_crown_allocation_split(draft)
	var ordered_keys: Array = ["treasury_pct", "military_pct", "goods_pct"]
	if not ordered_keys.has(changed_key):
		return out

	var other_keys: Array = []
	for raw_key in ordered_keys:
		var key: String = str(raw_key)
		if key != changed_key:
			other_keys.append(key)

	var next_value: int = clamp(requested_value, 0, 100)
	out [changed_key] = next_value

	var remaining: int = 100 - next_value
	var first_key: String = str(other_keys [0])
	var second_key: String = str(other_keys [1])

	var current_first: int = int(out.get(first_key, 0))
	var current_second: int = int(out.get(second_key, 0))
	var current_total: int = current_first + current_second

	if current_total <= 0:
		var first_share: int = int(floor(float(remaining) * 0.5))
		out [first_key] = first_share
		out [second_key] = remaining - first_share
	else:
		var first_share: int = int(round(float(remaining) * (float(current_first) / float(current_total))))
		first_share = clamp(first_share, 0, remaining)
		out [first_key] = first_share
		out [second_key] = remaining - first_share

	return GovernmentSceneSupport._sanitize_crown_allocation_split(out)


static func _build_crown_allocation_projection(summary: Dictionary, realm: Dictionary, draft: Dictionary) -> Dictionary:
	var clean_draft: Dictionary = GovernmentSceneSupport._sanitize_crown_allocation_split(draft)
	var tax_rate: float = clamp(float(clean_draft.get("tax_rate", 10.0)), 0.0, 40.0)
	var treasury_pct: int = int(clean_draft.get("treasury_pct", 34))
	var military_pct: int = int(clean_draft.get("military_pct", 33))
	var goods_pct: int = int(clean_draft.get("goods_pct", 33))
	var population: int = int(summary.get("population", 0))
	var tax_revenue: int = GovernmentSceneSupport._calculate_crown_tax_revenue(population, tax_rate, realm)
	var saved_reserve: int = int(realm.get("allocation_reserve", summary.get("allocation_reserve", 0)))
	var available_pool: int = saved_reserve + tax_revenue

	var treasury_amount: int = int(round(float(available_pool) * (float(treasury_pct) / 100.0)))
	var military_budget: int = int(round(float(available_pool) * (float(military_pct) / 100.0)))
	var goods_budget: int = int(round(float(available_pool) * (float(goods_pct) / 100.0)))

	var military_unit_cost: int = int(summary.get("military_unit_cost", 4500))
	var goods_unit_cost: int = int(summary.get("goods_unit_cost", 200000))

	var military_units: int = int(floor(float(military_budget) / float(max(1, military_unit_cost))))
	var goods_units: int = int(floor(float(goods_budget) / float(max(1, goods_unit_cost))))

	var military_amount: int = military_units * max(1, military_unit_cost)
	var goods_amount: int = goods_units * max(1, goods_unit_cost)

	var spent_total: int = treasury_amount + military_amount + goods_amount
	var carryover_amount: int = max(0, available_pool - spent_total)

	return {
		"tax_rate": tax_rate,
		"treasury_pct": treasury_pct,
		"military_pct": military_pct,
		"goods_pct": goods_pct,
		"tax_revenue": tax_revenue,
		"saved_reserve": saved_reserve,
		"available_pool": available_pool,
		"treasury_amount": treasury_amount,
		"military_amount": military_amount,
		"goods_amount": goods_amount,
		"carryover_amount": carryover_amount,
		"military_units": military_units,
		"goods_units": goods_units,
		"happiness_delta": GovernmentSceneSupport._crown_tax_pressure_delta(tax_rate, "happiness"),
		"approval_delta": GovernmentSceneSupport._crown_tax_pressure_delta(tax_rate, "approval"),
		"respect_delta": GovernmentSceneSupport._crown_tax_pressure_delta(tax_rate, "respect")
	}


static func _crown_allocation_draft_has_changes(summary: Dictionary, realm: Dictionary, draft: Dictionary) -> bool:
	var baseline: Dictionary = {
		"tax_rate": clamp(float(realm.get("tax_rate", summary.get("tax_rate", 10.0))), 0.0, 40.0),
		"treasury_pct": clamp(int(realm.get("allocation_treasury_pct", 34)), 0, 100),
		"military_pct": clamp(int(realm.get("allocation_military_pct", 33)), 0, 100),
		"goods_pct": clamp(int(realm.get("allocation_goods_pct", 33)), 0, 100)
	}
	baseline = GovernmentSceneSupport._sanitize_crown_allocation_split(baseline)

	var probe: Dictionary = GovernmentSceneSupport._sanitize_crown_allocation_split(draft)

	if abs(float(probe.get("tax_rate", 0.0)) - float(baseline.get("tax_rate", 0.0))) >= 0.5:
		return true

	for key in ["treasury_pct", "military_pct", "goods_pct"]:
		if int(probe.get(key, 0)) != int(baseline.get(key, 0)):
			return true

	return false


static func _pick_best_crown_successor(gs: GameState,
	exclude_id: int = -1) -> Person:
	if gs == null or gs.player == null:
		return null
	var best: Person = null
	for raw_npc in gs.npcs:
		var npc: Person = raw_npc
		if npc == null or not npc.alive or int(npc.id) == exclude_id:
			continue
		if int(npc.realm_id) != int(gs.player.realm_id):
			continue
		if not bool(npc.is_royal):
			continue
		if bool(npc.exiled):
			continue
		if best == null:
			best = npc
			continue
		if int(npc.succession_rank) < int(best.succession_rank):
			best = npc
		elif int(npc.succession_rank) == int(best.succession_rank) and int(npc.age) > int(best.age):
			best = npc
	return best


static func _build_crown_execution_methods(gs: GameState) -> Array:
	var era_key: String = GovernmentSceneSupport._crown_current_era_key(gs).strip_edges().to_lower()

	var methods: Array = [
		{ "label": "Public Decree", "severity": 35, "approval_delta": -6, "scandal_delta": 6, "outcry_delta": 5, "cause": "Execution"},
		{ "label": "Quiet Poison", "severity": 45, "approval_delta": -5, "scandal_delta": 9, "outcry_delta": 4, "cause": "Execution"},
		{ "label": "Iron Maiden", "severity": 90, "approval_delta": -18, "scandal_delta": 20, "outcry_delta": 18, "cause": "Execution"},
		{ "label": "Impalement", "severity": 92, "approval_delta": -19, "scandal_delta": 21, "outcry_delta": 19, "cause": "Execution"},
		{ "label": "Puppy Chow", "severity": 100, "approval_delta": -25, "scandal_delta": 28, "outcry_delta": 26, "cause": "Execution"},
		{ "label": "Cement Shoes", "severity": 66, "approval_delta": -13, "scandal_delta": 17, "outcry_delta": 12, "cause": "Execution"},
		{ "label": "Brazen Bull", "severity": 96, "approval_delta": -22, "scandal_delta": 25, "outcry_delta": 24, "cause": "Execution"},
		{ "label": "Drawn & Quartered", "severity": 100, "approval_delta": -26, "scandal_delta": 28, "outcry_delta": 28, "cause": "Execution"},
		{ "label": "Tar & Feathered", "severity": 52, "approval_delta": -8, "scandal_delta": 10, "outcry_delta": 8, "cause": "Execution"},
		{ "label": "Boiling Oil", "severity": 94, "approval_delta": -21, "scandal_delta": 24, "outcry_delta": 23, "cause": "Execution"},
		{ "label": "Black Mamba Bite", "severity": 82, "approval_delta": -17, "scandal_delta": 20, "outcry_delta": 16, "cause": "Execution"},
		{ "label": "Rat Torture", "severity": 93, "approval_delta": -22, "scandal_delta": 25, "outcry_delta": 23, "cause": "Execution"}
	]

	match era_key:
		"ancient":
			methods.append_array([
				{ "label": "Stoning", "severity": 78, "approval_delta": -15, "scandal_delta": 15, "outcry_delta": 15, "cause": "Execution"},
				{ "label": "Crucifixion", "severity": 96, "approval_delta": -23, "scandal_delta": 24, "outcry_delta": 25, "cause": "Execution"}
			])
		"medieval":
			methods.append_array([
				{ "label": "Burning at the Stake", "severity": 91, "approval_delta": -20, "scandal_delta": 23, "outcry_delta": 22, "cause": "Execution"},
				{ "label": "Public Beheading", "severity": 70, "approval_delta": -12, "scandal_delta": 14, "outcry_delta": 12, "cause": "Execution"}
			])
		"industrial":
			methods.append_array([
				{ "label": "Guillotine", "severity": 68, "approval_delta": -11, "scandal_delta": 12, "outcry_delta": 11, "cause": "Execution"},
				{ "label": "Firing Squad", "severity": 62, "approval_delta": -10, "scandal_delta": 12, "outcry_delta": 10, "cause": "Execution"}
			])
		"modern":
			methods.append_array([
				{ "label": "Lethal Injection", "severity": 48, "approval_delta": -7, "scandal_delta": 9, "outcry_delta": 7, "cause": "Execution"},
				{ "label": "Military Tribunal Execution", "severity": 65, "approval_delta": -12, "scandal_delta": 14, "outcry_delta": 12, "cause": "Execution"}
			])
		"future":
			methods.append_array([
				{ "label": "Neural Deletion Sentence", "severity": 88, "approval_delta": -20, "scandal_delta": 24, "outcry_delta": 22, "cause": "Execution"},
				{ "label": "Orbital Airlock Sentence", "severity": 84, "approval_delta": -18, "scandal_delta": 22, "outcry_delta": 20, "cause": "Execution"}
			])

	return methods


static func _apply_crown_public_outcry_delta(gs: GameState,
	delta_value: int) -> void:
	if gs == null:
		return

	if typeof(gs.scenario_state) != TYPE_DICTIONARY:
		gs.scenario_state = {}

	var current_outcry: int = int(gs.scenario_state.get("crown_public_outcry", 0))
	gs.scenario_state ["crown_public_outcry"] = clamp(current_outcry + int(delta_value), 0, 100)


static func _build_crown_honorific_options(gs: GameState) -> Array:
	if gs == null or gs.player == null:
		return ["Sovereign", "Majesty", "High Ruler"]
	var p:= gs.player
	var out: Array = []
	if bool(p.is_ruler):
		out.append("Your Majesty")
		out.append("Sovereign")
		out.append("High Ruler")
		out.append("First Crown")
	else:
		out.append("Royal Highness")
		out.append("Heir Apparent")
		out.append("Claimant Regent")
	return out


static func _build_crown_heir_candidates(gs: GameState) -> Array:
	var out: Array = []
	if gs == null or gs.player == null:
		return out
	for raw_npc in gs.npcs:
		var npc: Person = raw_npc
		if npc == null or not npc.alive or int(npc.id) == int(gs.player.id):
			continue
		if int(npc.realm_id) != int(gs.player.realm_id):
			continue
		if not bool(npc.is_royal):
			continue
		if bool(npc.exiled):
			continue
		out.append(npc)
	return out.slice(0, min(8, out.size()))


static func _build_crown_marriage_candidates(gs: GameState) -> Array:
	var out: Array = []
	if gs == null or gs.player == null:
		return out
	for raw_npc in gs.npcs:
		var npc: Person = raw_npc
		if npc == null or not npc.alive:
			continue
		if int(npc.realm_id) == int(gs.player.realm_id):
			continue
		if not bool(npc.is_royal):
			continue
		if npc.partner != null:
			continue
		if int(npc.age) < 18:
			continue
		out.append(npc)
	return out.slice(0, min(8, out.size()))


static func _build_crown_succession_text(gs: GameState) -> String:
	var lines: Array = []
	lines.append("Current throne order:")
	var candidates: Array = GovernmentSceneSupport._build_crown_heir_candidates(gs)
	if candidates.is_empty():
		lines.append("No clear heir lines found.")
	else:
		for raw_candidate in candidates:
			var candidate: Person = raw_candidate
			lines.append("%s %s  •  rank %d  •  age %d" % [
				candidate.first_name,
				candidate.last_name,
				int(candidate.succession_rank),
				int(candidate.age)
			])
	return "\n".join(lines)


static func _build_crown_claimant_text(gs: GameState) -> String:
	var lines: Array = []
	lines.append("Claimant and branch pressure:")
	if gs == null or gs.player == null:
		return "\n".join(lines)
	for raw_npc in gs.npcs:
		var npc: Person = raw_npc
		if npc == null or not npc.alive:
			continue
		if int(npc.realm_id) != int(gs.player.realm_id):
			continue
		if not bool(npc.deposed) and not bool(npc.exiled) and int(npc.succession_rank) > 12:
			continue
		lines.append("%s %s  •  rank %d  •  exiled=%s  •  deposed=%s" % [
			npc.first_name,
			npc.last_name,
			int(npc.succession_rank),
			str(bool(npc.exiled)),
			str(bool(npc.deposed))
		])
	if lines.size() == 1:
		lines.append("No major claimant threats are visible.")
	return "\n".join(lines)


static func _crown_default_currency_name_for_realm(gs: GameState,
	realm_name: String) -> String:
	var clean_name: String = realm_name.strip_edges()
	match clean_name:
		"Fire Nation":
			return "Gold Pieces"
		"Earth Kingdom":
			return "Yuan"
		"Water Tribe":
			return "Silver Marks"
		"Air Nomads":
			return "Monastery Chits"
		"USA":
			return "Dollars"
		"UK":
			return "Pounds"
		"Japan":
			return "Yen"
		"Brazil":
			return "Reais"
		"Germany":
			return "Marks"
		"Federated Earth":
			return "Credits"
		"Sol Empire":
			return "Solar Credits"
		"Lunar Republic":
			return "Lunar Credits"
	match gs.era.name if gs != null and gs.era != null else "":
		"Ancient Era":
			return "Talents"
		"Medieval Era":
			return "Crowns"
		"Industrial Era":
			return "Pounds"
		"Modern Era":
			return "Dollars"
		"Future Era":
			return "Credits"
		_:
			return "Crowns"


static func _get_crown_realm_relation_score(gs: GameState,
	target_realm_id: int) -> int:
	if gs == null or gs.player == null:
		return 0
	if typeof(gs.scenario_state) != TYPE_DICTIONARY:
		gs.scenario_state = {}
	var raw_store: Variant = gs.scenario_state.get("crown_realm_relations", {})
	var store: Dictionary = raw_store if typeof(raw_store) == TYPE_DICTIONARY else {}
	var key: String = "%d:%d" % [int(gs.player.realm_id), int(target_realm_id)]
	return int(store.get(key, 0))


static func _crown_realm_name(gs: GameState,
	realm_id: int) -> String:
	if gs == null or gs.realm_engine == null or realm_id <= 0:
		return "Unknown Realm"
	if not gs.realm_engine.realms.has(realm_id):
		return "Unknown Realm"
	var realm_raw: Variant = gs.realm_engine.realms.get(realm_id, {})
	var realm: Dictionary = realm_raw if typeof(realm_raw) == TYPE_DICTIONARY else {}
	return str(realm.get("name", "Unknown Realm"))


static func _format_birth_relative_royal_role(npc: Person) -> String:
	if npc == null or not npc.is_royal:
		return ""
	var title:= str(npc.royal_title).strip_edges()
	var job_text:= str(npc.job).strip_edges()
	if title == "":
		if job_text == "" or job_text == "Retired":
			return ""
		return "The %s" % GovernmentSceneSupport._crown_title_case(job_text)
	if title.begins_with("Former "):
		var former_title:= title.substr(7, title.length() - 7).strip_edges()
		return "The Former %s" % GovernmentSceneSupport._crown_title_case(former_title)
	if job_text == "Retired":
		return "The Retired %s" % GovernmentSceneSupport._crown_title_case(title)
	return "The %s" % GovernmentSceneSupport._crown_title_case(title)


static func _apply_god_mode_royal_birth_truth_to_actor(gs: GameState,
	actor: Person, settings: Dictionary, reason: String = "god_mode_royal_birth_truth") -> void:
	if actor == null:
		return

	var social_class: String = CreationSceneSupport._god_mode_birth_normalized_social_class(settings)
	var rank_seed: String = GovernmentSceneSupport._god_mode_birth_royal_rank_seed(settings)
	var requested_royal: bool = social_class in ["Royal", "Noble"] or rank_seed != ""

	if social_class != "":
		actor.social_class = social_class

	if not requested_royal:
		return

	if rank_seed == "":
		rank_seed = "Royal Child" if social_class == "Royal" else "Ducal Line"

	if gs != null and gs.royalty_engine != null and gs.royalty_engine.has_method("_normalize_royal_rank_seed"):
		rank_seed = str(gs.royalty_engine.call("_normalize_royal_rank_seed", rank_seed)).strip_edges()
		if rank_seed == "Lesser Royal":
			rank_seed = "Ducal Line"

	actor.is_ruler = false
	actor.is_royal = true
	actor.deposed = false
	actor.exiled = false
	actor.palace_owned = social_class == "Royal"

	match rank_seed:
		"Heir Line":
			actor.social_class = "Royal"
			actor.succession_rank = 1
			actor.royal_title = GovernmentSceneSupport._god_mode_birth_resolve_royal_title(gs, actor, "heir")
		"Royal Child":
			actor.social_class = "Royal"
			actor.succession_rank = max(3, int(actor.succession_rank))
			actor.royal_title = GovernmentSceneSupport._god_mode_birth_resolve_royal_title(gs, actor, "royal_child")
		"Ducal Line":
			actor.social_class = "Noble"
			actor.succession_rank = max(8, int(actor.succession_rank))
			actor.royal_title = GovernmentSceneSupport._god_mode_birth_resolve_royal_title(gs, actor, "ducal_royal")
		"Marcher Line":
			actor.social_class = "Noble"
			actor.succession_rank = max(9, int(actor.succession_rank))
			actor.royal_title = GovernmentSceneSupport._god_mode_birth_resolve_royal_title(gs, actor, "marcher_royal")
		_:
			actor.social_class = "Noble"
			actor.succession_rank = max(10, int(actor.succession_rank))
			actor.royal_title = GovernmentSceneSupport._god_mode_birth_resolve_royal_title(gs, actor, "lesser_royal")

	if gs != null and gs.royalty_engine != null:
		if gs.royalty_engine.has_method("_set_royal_rank_seed_trait"):
			gs.royalty_engine.call("_set_royal_rank_seed_trait", actor, rank_seed)
		if gs.royalty_engine.has_method("_sync_royal_job_identity"):
			gs.royalty_engine.call("_sync_royal_job_identity", actor)
		if gs.royalty_engine.has_method("_apply_royal_fame_floor"):
			gs.royalty_engine.call("_apply_royal_fame_floor", actor)

	actor.approval = clamp(max(int(actor.approval), 50), 0, 100)

	if typeof(gs.scenario_state) == TYPE_DICTIONARY:
		gs.scenario_state ["god_mode_royal_birth_truth_applied"] = true
		gs.scenario_state ["god_mode_royal_birth_truth_actor_id"] = int(actor.id)
		gs.scenario_state ["god_mode_royal_birth_truth_rank_seed"] = rank_seed
		gs.scenario_state ["god_mode_royal_birth_truth_reason"] = reason
		gs.scenario_state ["god_mode_royal_birth_truth_at_ms"] = int(Time.get_ticks_msec())


static func _god_mode_birth_resolve_royal_title(gs: GameState,
	actor: Person, rank_key: String) -> String:
	if actor == null:
		return ""

	if gs != null and gs.royalty_engine != null and gs.royalty_engine.has_method("_resolve_rank_title"):
		return str(gs.royalty_engine.call("_resolve_rank_title", actor, rank_key)).strip_edges()

	var gender_text: String = str(actor.gender).strip_edges().to_lower()

	match rank_key:
		"heir":
			return "Crown Princess" if gender_text == "female" else "Crown Prince"
		"royal_child":
			return "Princess" if gender_text == "female" else "Prince"
		"ducal_royal":
			return "Duchess" if gender_text == "female" else "Duke"
		"marcher_royal":
			return "Marchioness" if gender_text == "female" else "Marquess"
		_:
			return "Noble"


static func _collapse_realm_politics_compact_lines(lines: Array) -> Array:
	var rows: Array = []
	if lines.size() <= 1:
		return rows
	var seen: Dictionary = {}
	var split_payloads: Array = []
	var next_year_payloads: Array = []
	for i in range(1, lines.size()):
		var line: String = str(lines [i]).strip_edges()
		if line == "":
			continue
		var lower_line: String = line.to_lower()
		var treasury_fragment: String = GovernmentSceneSupport._extract_compact_politics_fragment(line, "Treasury")
		var military_fragment: String = GovernmentSceneSupport._extract_compact_politics_fragment(line, "Military")
		var goods_fragment: String = GovernmentSceneSupport._extract_compact_politics_fragment(line, "Goods")
		var happiness_fragment: String = GovernmentSceneSupport._extract_compact_politics_fragment(line, "Happiness")
		var approval_fragment: String = GovernmentSceneSupport._extract_compact_politics_fragment(line, "Approval")
		var respect_fragment: String = GovernmentSceneSupport._extract_compact_politics_fragment(line, "Respect")

		var split_context: bool = (
			lower_line.find("split") != -1
			or lower_line.find("allocation") != -1
			or lower_line.find("revenue") != -1
			or lower_line.find("%") != -1
		)

		if split_context:
			if treasury_fragment != "":
				var treasury_split: String = "Treasury " + GovernmentSceneSupport._compact_politics_payload_from_fragment(treasury_fragment, "Treasury")
				if not split_payloads.has(treasury_split):
					split_payloads.append(treasury_split)
			if military_fragment != "":
				var military_split: String = "Military " + GovernmentSceneSupport._compact_politics_payload_from_fragment(military_fragment, "Military")
				if not split_payloads.has(military_split):
					split_payloads.append(military_split)
			if goods_fragment != "":
				var goods_split: String = "Goods " + GovernmentSceneSupport._compact_politics_payload_from_fragment(goods_fragment, "Goods")
				if not split_payloads.has(goods_split):
					split_payloads.append(goods_split)
		else:
			if treasury_fragment != "":
				GovernmentSceneSupport._append_compact_politics_row(rows, seen, "Treasury", GovernmentSceneSupport._compact_politics_payload_from_fragment(treasury_fragment, "Treasury"))
			if military_fragment != "":
				GovernmentSceneSupport._append_compact_politics_row(rows, seen, "Military", GovernmentSceneSupport._compact_politics_payload_from_fragment(military_fragment, "Military"))
			if goods_fragment != "":
				GovernmentSceneSupport._append_compact_politics_row(rows, seen, "Goods", GovernmentSceneSupport._compact_politics_payload_from_fragment(goods_fragment, "Goods"))

		if happiness_fragment != "":
			var happiness_payload: String = "Happiness " + GovernmentSceneSupport._compact_politics_payload_from_fragment(happiness_fragment, "Happiness")
			if not next_year_payloads.has(happiness_payload):
				next_year_payloads.append(happiness_payload)
		if approval_fragment != "":
			var approval_payload: String = "Approval " + GovernmentSceneSupport._compact_politics_payload_from_fragment(approval_fragment, "Approval")
			if not next_year_payloads.has(approval_payload):
				next_year_payloads.append(approval_payload)
		if respect_fragment != "":
			var respect_payload: String = "Respect " + GovernmentSceneSupport._compact_politics_payload_from_fragment(respect_fragment, "Respect")
			if not next_year_payloads.has(respect_payload):
				next_year_payloads.append(respect_payload)

	if not split_payloads.is_empty():
		GovernmentSceneSupport._append_compact_politics_row(rows, seen, "State Split", " • ".join(split_payloads))
	if not next_year_payloads.is_empty():
		GovernmentSceneSupport._append_compact_politics_row(rows, seen, "Next Year", " • ".join(next_year_payloads))
	return rows


static func _can_stage_coup_against_target(gs: GameState,
	target: Person) -> bool:
	if gs == null or gs.player == null or target == null:
		return false
	if not gs.player.is_royal or not target.is_royal:
		return false
	if int(gs.player.id) == int(target.id):
		return false
	if int(gs.player.age) < 16:
		return false
	var my_house:= str(gs.player.dynasty_origin).strip_edges()
	var target_house:= str(target.dynasty_origin).strip_edges()
	if my_house != "" and target_house != "" and my_house != target_house:
		return false
	if target.is_ruler:
		return true
	if int(target.succession_rank) > 0 and int(gs.player.succession_rank) > 0 and int(target.succession_rank) < int(gs.player.succession_rank):
		return true
	return false


static func _primary_royal_court_entry_for_npc(gs: GameState,
	npc: Person) -> Dictionary:
	if gs == null or npc == null:
		return {}
	var membership_index_raw: Variant = gs.scenario_state.get("royal_court_membership_index", {})
	var membership_index: Dictionary = membership_index_raw if typeof(membership_index_raw) == TYPE_DICTIONARY else {}
	var npc_entries_raw: Variant = membership_index.get(str(int(npc.id)), {})
	var npc_entries: Dictionary = npc_entries_raw if typeof(npc_entries_raw) == TYPE_DICTIONARY else {}

	var best_entry: Dictionary = {}
	var best_priority: int = 999

	for raw_faction_id in npc_entries.keys():
		var entry_raw: Variant = npc_entries.get(raw_faction_id, {})
		var entry: Dictionary = entry_raw if typeof(entry_raw) == TYPE_DICTIONARY else {}
		if not bool(entry.get("active", true)):
			continue
		var priority: int = GovernmentSceneSupport._royal_court_role_priority(str(entry.get("role", "courtier")))
		if best_entry.is_empty() or priority < best_priority:
			best_entry = entry.duplicate(true)
			best_entry ["faction_id"] = str(raw_faction_id)
			best_priority = priority

	return best_entry


static func _player_is_royal_bender(gs: GameState) -> bool:
	if gs == null or gs.player == null:
		return false
	var p:= gs.player
	if not p.is_royal:
		return false
	return str(p.bending_nation).strip_edges() != ""


static func _royal_bender_ui_tint_for_player(gs: GameState) -> Color:
	if not GovernmentSceneSupport._player_is_royal_bender(gs):
		return Color(1.0, 1.0, 1.0, 1.0)
	var nation:= str(gs.player.bending_nation).strip_edges()
	match nation:
		"Fire Nation":
			return Color(1.0, 0.58, 0.3, 1.0)
		"Water Tribe":
			return Color(0.5, 0.8, 1.0, 1.0)
		"Earth Kingdom":
			return Color(0.73, 0.92, 0.46, 1.0)
		"Air Nomads":
			return Color(0.92, 0.92, 0.96, 1.0)
		_:
			return Color(1.0, 1.0, 1.0, 1.0)

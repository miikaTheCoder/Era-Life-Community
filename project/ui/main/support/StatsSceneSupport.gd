extends RefCounted
class_name StatsSceneSupport
## Stats support for the main scene. State, when needed, is passed explicitly.


static func _player_stat_row_phase_offset(title: String) -> float:
	match title:
		"Health":
			return 0.15
		"Mental":
			return 0.85
		"Happiness":
			return 1.55
		"Smarts":
			return 2.2
		"Looks":
			return 2.95
		"Fame":
			return 3.6
		_:
			return 0.0


static func _health_base_display_max(value: int) -> int:
	return max(100, int(value))


static func _build_player_stat_row_visual_signature(
	theme_key: String,
	title: String,
	is_hovered: bool,
	danger_state: bool,
	pulse_strength: float,
	flavor_visible: bool
) -> String:
	var pulse_bucket: int = int(round(clamp(pulse_strength, 0.0, 1.0) * 6.0))
	return "%s|%s|%s|%s|%s|%d" % [
		theme_key,
		title,
		str(is_hovered),
		str(danger_state),
		str(flavor_visible),
		pulse_bucket
	]


static func _ensure_player_stat_bar_fill_lens(bar: ProgressBar) -> PanelContainer:
	if bar == null:
		return null
	if not is_instance_valid(bar):
		return null

	var existing:= bar.get_node_or_null("StatFillLens") as PanelContainer
	if existing != null and is_instance_valid(existing):
		return existing

	var fill_lens:= PanelContainer.new()
	fill_lens.name = "StatFillLens"
	fill_lens.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fill_lens.focus_mode = Control.FOCUS_NONE
	fill_lens.z_as_relative = true
	fill_lens.z_index = 1
	fill_lens.anchor_left = 0.0
	fill_lens.anchor_top = 0.0
	fill_lens.anchor_right = 0.0
	fill_lens.anchor_bottom = 1.0
	fill_lens.offset_left = 0.0
	fill_lens.offset_top = 0.0
	fill_lens.offset_right = 0.0
	fill_lens.offset_bottom = 0.0
	fill_lens.set_meta("stat_fill_lens_authority", "player_stat_overlay")
	fill_lens.set_meta("stat_fill_lens_width_source", "bar_value_over_bar_max_value")
	fill_lens.set_meta("stat_fill_lens_is_visual_only", true)

	bar.add_child(fill_lens)
	bar.move_child(fill_lens, 0)

	return fill_lens


static func _player_stat_fill_lens_style(fill_lens: PanelContainer) -> StyleBoxFlat:
	if fill_lens == null:
		return null
	if not is_instance_valid(fill_lens):
		return null

	if fill_lens.has_meta("stat_fill_lens_stylebox"):
		var cached: Variant = fill_lens.get_meta("stat_fill_lens_stylebox")
		if cached != null and cached is StyleBoxFlat:
			return cached as StyleBoxFlat

	var style:= StyleBoxFlat.new()
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 0
	style.content_margin_right = 0
	style.content_margin_top = 0
	style.content_margin_bottom = 0

	fill_lens.set_meta("stat_fill_lens_stylebox", style)
	fill_lens.add_theme_stylebox_override("panel", style)

	return style


static func _get_or_create_player_stat_row_stylebox(bar: ProgressBar, meta_key: String) -> StyleBoxFlat:
	var cached: Variant = null
	if bar != null and bar.has_meta(meta_key):
		cached = bar.get_meta(meta_key)
	if cached != null and cached is StyleBoxFlat:
		return cached as StyleBoxFlat
	var style:= StyleBoxFlat.new()
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_right = 8
	style.corner_radius_bottom_left = 8
	if bar != null:
		bar.set_meta(meta_key, style)
	return style


static func _format_commas_for_player_stats_bank(amount: int) -> String:
	var negative: bool = amount < 0
	var digits: String = str(abs(amount))
	var grouped: String = ""

	while digits.length() > 3:
		grouped = "," + digits.substr(digits.length() - 3, 3) + grouped
		digits = digits.substr(0, digits.length() - 3)

	grouped = digits + grouped

	if negative:
		grouped = "-" + grouped

	return grouped


static func _surface_stat_phrase(text: String, surface_context: Dictionary) -> String:
	var out: String = str(text).strip_edges()
	if out == "":
		return out

	var perspective: String = str(surface_context.get("narrative_perspective", "first_person")).strip_edges().to_lower()
	var replacements: Array = []

	if perspective == "third_person":
		replacements = [
			["Your ", "Their "],
			["your ", "their "],
			["your.", "their."],
			["your,", "their,"],
			["your!", "their!"],
			["your?", "their?"],
			["You are ", "They are "],
			["You feel ", "They feel "],
			["You can ", "They can "],
			["You look ", "They look "],
			["You process ", "They process "],
			["You think ", "They think "],
			["You carry ", "They carry "],
			["You ", "They "],
			[" you are ", " they are "],
			[" you feel ", " they feel "],
			[" you can ", " they can "],
			[" you look ", " they look "],
			[" you process ", " they process "],
			[" you think ", " they think "],
			[" you carry ", " they carry "],
			[" you do.", " they do."],
			[" you do,", " they do,"],
			[" whether you ", " whether they "],
			[" when you ", " when they "],
			[" if you ", " if they "],
			[" before you ", " before they "],
			[" while you ", " while they "],
			[" know you,", " know them,"],
			[" know you.", " know them."],
			[" toward you", " toward them"],
			[" away from you", " away from them"],
			[" around you", " around them"],
			[" under you", " under them"],
			[" above you", " above them"],
			[" beside you", " beside them"],
			[" with you", " with them"],
			[" for you", " for them"],
			[" from you", " from them"],
			[" to you", " to them"]
		]
	else:
		replacements = [
			["Your ", "My "],
			["your ", "my "],
			["your.", "my."],
			["your,", "my,"],
			["your!", "my!"],
			["your?", "my?"],
			["You are ", "I am "],
			["You feel ", "I feel "],
			["You can ", "I can "],
			["You look ", "I look "],
			["You process ", "I process "],
			["You think ", "I think "],
			["You carry ", "I carry "],
			["You ", "I "],
			[" you are ", " I am "],
			[" you feel ", " I feel "],
			[" you can ", " I can "],
			[" you look ", " I look "],
			[" you process ", " I process "],
			[" you think ", " I think "],
			[" you carry ", " I carry "],
			[" you do.", " I do."],
			[" you do,", " I do,"],
			[" whether you ", " whether I "],
			[" when you ", " when I "],
			[" if you ", " if I "],
			[" before you ", " before I "],
			[" while you ", " while I "],
			[" know you,", " know me,"],
			[" know you.", " know me."],
			[" toward you", " toward me"],
			[" away from you", " away from me"],
			[" around you", " around me"],
			[" under you", " under me"],
			[" above you", " above me"],
			[" beside you", " beside me"],
			[" with you", " with me"],
			[" for you", " for me"],
			[" from you", " from me"],
			[" to you", " to me"]
		]

	for pair in replacements:
		if pair.size() < 2:
			continue
		out = out.replace(str(pair [0]), str(pair [1]))

	return out


static func _resolve_player_stat_surface_title(title: String, descriptor: String, surface_context: Dictionary) -> String:
	var safe_title: String = str(title).strip_edges()
	var safe_descriptor: String = str(descriptor).strip_edges()
	if safe_title == "":
		return safe_descriptor

	var title_mode: String = str(surface_context.get("descriptor_title_mode", "default")).strip_edges().to_lower()
	var perspective: String = str(surface_context.get("narrative_perspective", "first_person")).strip_edges().to_lower()

	if title_mode == "bond_pov" and safe_title == "Bond":
		if perspective == "third_person":
			match safe_descriptor:
				"Devoted":
					return "Bond: Devoted to You"
				"Warm":
					return "Bond: Warm Toward You"
				"Open":
					return "Bond: Open to You"
				"Guarded":
					return "Bond: Guarded Around You"
				"Cold":
					return "Bond: Cold Toward You"
				"Hostile":
					return "Bond: Hostile Toward You"

	if title_mode == "approval_pov" and safe_title == "Approval":
		match safe_descriptor:
			"Beloved":
				return "Approval: Beloved by Them"
			"Backed":
				return "Approval: Backed by Them"
			"Rejected":
				return "Approval: Rejected by Them"

	return "%s: %s" % [safe_title, safe_descriptor]


static func _stat_meter(label: String, value: int, max_value: int) -> String:
	var clamped_value: int = clamp(value, 0, max_value)
	var width:= 18
	var filled:= int(round((float(clamped_value) / float(max_value)) * width))
	filled = clamp(filled, 0, width)

	var bar:= ""
	for i in range(width):
		bar += "█" if i < filled else "░"

	return "%s: [%s] %d/%d" % [label, bar, clamped_value, max_value]


static func _resolve_player_stat_surface(title: String, value: int, max_value: int, surface_context: Dictionary) -> Dictionary:
	var safe_max: int = max(1, max_value)
	var ratio: float = clamp(float(value) / float(safe_max), 0.0, 1.0)
	var descriptor: String = ""
	var flavor: String = ""
	var flavor_already_localized: bool = false
	var bar_text_override: String = ""
	match title:
		"Health":
			var health_value: int = max(0, int(round(float(value))))
			var subject_dead: bool = bool(surface_context.get("subject_dead", false)) or health_value <= 0

			if subject_dead:
				descriptor = "Dead"
				flavor = str(surface_context.get("death_health_flavor", "")).strip_edges()
				if flavor == "":
					flavor = RelationshipsSceneSupport._relationship_profile_dead_health_flavor(surface_context)
			elif health_value >= 180:
				descriptor = "Mythic Body"
				flavor = "Your body is operating beyond anything ordinary people are built to survive."
			elif health_value >= 150:
				descriptor = "Superhuman"
				flavor = "Your body is past peak condition and starting to feel unreal."
			elif health_value >= 125:
				descriptor = "Enhanced"
				flavor = "Your body is stronger than normal limits, but still recognizably human."
			elif health_value >= 100:
				descriptor = "Peak Condition"
				flavor = "Your body is at the kind of health most people dream about."
			elif health_value >= 85:
				descriptor = "Excellent"
				flavor = "Your body feels strong, responsive, and dependable."
			elif health_value >= 70:
				descriptor = "Strong"
				flavor = "You feel durable, steady, and ready for impact."
			elif health_value >= 50:
				descriptor = "Stable"
				flavor = "You are holding together without obvious strain."
			elif health_value >= 30:
				descriptor = "Injured"
				flavor = "Your body is asking for recovery whether you listen or not."
			elif health_value >= 15:
				descriptor = "Critical"
				flavor = "Your body is refusing to give up, but it is close."
			else:
				descriptor = "Near Death"
				flavor = "Every movement feels like it could be your last."
		"Hunger":
			var hunger_value: int = clamp(int(round(float(value))), 0, 100)
			if hunger_value <= 5:
				descriptor = "Critical Starvation"
				flavor = "Your body is running on almost nothing. This is dangerous."
			elif hunger_value <= 18:
				descriptor = "Starving"
				flavor = "Your body urgently needs food. Every moment without sustenance matters."
			elif hunger_value <= 35:
				descriptor = "Malnourished"
				flavor = "You have gone too long without enough food."
			elif hunger_value <= 55:
				descriptor = "Hungry"
				flavor = "Your body is asking for food."
			elif hunger_value <= 72:
				descriptor = "Peckish"
				flavor = "You could eat, but you are still holding steady."
			elif hunger_value <= 92:
				descriptor = "Satisfied"
				flavor = "You feel fed and steady."
			else:
				descriptor = "Full"
				flavor = "You are fully fed. Food is not pressing on your body right now."
		"Mental":
			if bool(surface_context.get("is_royal_pressure", false)):
				if ratio >= 0.75:
					descriptor = "Commanding"
					flavor = "Pressure is real, but your mind is still above it."
				elif ratio >= 0.45:
					descriptor = "Siege-Minded"
					flavor = "Responsibility is crowding your thoughts."
				else:
					descriptor = "Overrun"
					flavor = "The crown is louder than your control."
			elif bool(surface_context.get("is_public_pressure", false)):
				if ratio >= 0.75:
					descriptor = "Focused"
					flavor = "The world is loud, but your inner signal is still clean."
				elif ratio >= 0.45:
					descriptor = "Crowded"
					flavor = "Too much attention is living in your head rent-free."
				else:
					descriptor = "Overwhelmed"
					flavor = "The noise outside is starting to win."
			else:
				if ratio >= 0.9:
					descriptor = "Locked In"
					flavor = "Your thoughts feel sharp, quiet, and fully under you."
				elif ratio >= 0.72:
					descriptor = "Focused"
					flavor = "Your mind is steady and responsive."
				elif ratio >= 0.5:
					descriptor = "Steady"
					flavor = "You are carrying your thoughts without slipping."
				elif ratio >= 0.3:
					descriptor = "Overloaded"
					flavor = "Your thoughts are louder than your control."
				elif ratio >= 0.15:
					descriptor = "Fractured"
					flavor = "Your mind is splitting under pressure."
				else:
					descriptor = "Overwhelmed"
					flavor = "You are barely holding the inside together."
		"Happiness":
			if ratio >= 0.9:
				descriptor = "Thriving"
				flavor = "Life feels open, bright, and worth leaning into."
			elif ratio >= 0.72:
				descriptor = "Content"
				flavor = "There is real warmth in your day-to-day state."
			elif ratio >= 0.5:
				descriptor = "Grounded"
				flavor = "You are not flying, but you are not empty either."
			elif ratio >= 0.3:
				descriptor = "Drained"
				flavor = "Joy is present mostly as memory."
			elif ratio >= 0.15:
				descriptor = "Numb"
				flavor = "Feeling good takes more work than it should."
			else:
				descriptor = "Joyless"
				flavor = "The light is there somewhere, but not in reach right now."
		"Smarts":
			if ratio >= 0.95:
				descriptor = "Gifted"
				flavor = "Your mind is operating above the room."
			elif ratio >= 0.8:
				descriptor = "Brilliant"
				flavor = "You process patterns faster than most people can explain them."
			elif ratio >= 0.6:
				descriptor = "Sharp"
				flavor = "You are thinking clearly and catching things quickly."
			elif ratio >= 0.4:
				descriptor = "Clever"
				flavor = "You can work your way through things with effort."
			elif ratio >= 0.2:
				descriptor = "Foggy"
				flavor = "Your thinking works, but it feels heavy."
			else:
				descriptor = "Lost"
				flavor = "Nothing is clicking the way it should."
		"Looks":
			if ratio >= 0.9:
				descriptor = "Striking"
				flavor = "Your presence lands before you even say anything."
			elif ratio >= 0.72:
				descriptor = "Attractive"
				flavor = "You are carrying yourself well and it shows."
			elif ratio >= 0.5:
				descriptor = "Presentable"
				flavor = "You look fine, even if it is not commanding the room."
			elif ratio >= 0.3:
				descriptor = "Plain"
				flavor = "Nothing is wrong, but nothing is turning heads either."
			elif ratio >= 0.15:
				descriptor = "Rough"
				flavor = "You look like life has been leaving fingerprints."
			else:
				descriptor = "Haggard"
				flavor = "You look visibly worn down."
		"Imagination":
			if bool(surface_context.get("terabithia_entered", false)):
				if ratio >= 0.9:
					descriptor = "Reality Bender"
					flavor = "Reality feels thin around you."
				elif ratio >= 0.72:
					descriptor = "Veil-Thinning"
					flavor = "You can feel the edge where ordinary rules weaken."
				elif ratio >= 0.5:
					descriptor = "Awakening"
					flavor = "Something beyond ordinary perception keeps answering back."
				else:
					descriptor = "Creative"
					flavor = "The door is real, but you are not fully through it yet."
			elif bool(surface_context.get("terabithia_unlocked", false)) or bool(surface_context.get("terabithia_known", false)):
				if ratio >= 0.9:
					descriptor = "Threshold Open"
					flavor = "Imagination is no longer just internal."
				elif ratio >= 0.72:
					descriptor = "Veil-Thinning"
					flavor = "Reality keeps feeling less sealed than before."
				elif ratio >= 0.5:
					descriptor = "Awakening"
					flavor = "Your creativity is beginning to bend perception."
				elif ratio >= 0.3:
					descriptor = "Creative"
					flavor = "Your inner world is getting louder."
				else:
					descriptor = "Grounded"
					flavor = "The signal is there, but it is still faint."
			else:
				if ratio >= 0.9:
					descriptor = "World-Shaping"
					flavor = "Your imagination feels capable of pulling new layers into existence."
				elif ratio >= 0.72:
					descriptor = "Creative"
					flavor = "Ideas come alive fast and vividly."
				elif ratio >= 0.5:
					descriptor = "Awakening"
					flavor = "Your inner world is active and getting stronger."
				elif ratio >= 0.3:
					descriptor = "Curious"
					flavor = "Your imagination is present, but not yet breaking through."
				else:
					descriptor = "Grounded"
					flavor = "Your perception stays close to the material world."
		"Willpower":
			var will_value: int = max(0, int(round(float(value))))
			if will_value >= 900:
				descriptor = "Avatar Limitless"
				flavor = "Your will is being carried by the Avatar State. Pain, fear, pressure, and defeat are struggling to find an edge."
			elif will_value >= 180:
				descriptor = "Mythic"
				flavor = "Your will is operating beyond ordinary collapse thresholds."
			elif will_value >= 150:
				descriptor = "Legendary"
				flavor = "Your mind refuses defeat with almost supernatural force."
			elif will_value >= 120:
				descriptor = "Unbreakable"
				flavor = "Pressure bends around you more than it breaks you."
			elif will_value >= 95:
				descriptor = "Iron"
				flavor = "You can take punishment, fear, and failure without losing your center."
			elif will_value >= 75:
				descriptor = "Strong"
				flavor = "You keep moving even when your body and emotions argue back."
			elif will_value >= 55:
				descriptor = "Steady"
				flavor = "Your resolve is holding under normal pressure."
			elif will_value >= 35:
				descriptor = "Shaken"
				flavor = "You can still push forward, but the cracks are getting louder."
			elif will_value >= 15:
				descriptor = "Breaking"
				flavor = "Your will is close to collapse and needs recovery."
			else:
				descriptor = "Collapsed"
				flavor = "Your internal resistance is almost gone."
		"Fame":
			var fame_tier_text: String = str(surface_context.get("fame_tier_text", "")).strip_edges()
			if fame_tier_text != "":
				descriptor = fame_tier_text
			elif ratio >= 0.9:
				descriptor = "Legend"
			elif ratio >= 0.72:
				descriptor = "Icon"
			elif ratio >= 0.5:
				descriptor = "Recognized"
			elif ratio >= 0.3:
				descriptor = "Known"
			else:
				descriptor = "Obscure"
			if ratio >= 0.85:
				flavor = "Your name walks into rooms before you do."
			elif ratio >= 0.6:
				flavor = "People know you, and that changes what life feels like."
			elif ratio >= 0.3:
				flavor = "Recognition is growing, even if it is not fully world-bending yet."
			else:
				flavor = "Your name is still mostly local to your own orbit."

		"Approval":
			if ratio >= 0.85:
				descriptor = "Beloved"
				flavor = "The public is leaning toward you, not away from you."
			elif ratio >= 0.7:
				descriptor = "Backed"
				flavor = "Your rule has support and breathing room."
			elif ratio >= 0.5:
				descriptor = "Stable"
				flavor = "You still hold legitimacy, but it is not untouchable."
			elif ratio >= 0.3:
				descriptor = "Fragile"
				flavor = "Your position is standing, but the ground is shifting."
			elif ratio >= 0.15:
				descriptor = "Rejected"
				flavor = "Trust is leaving faster than it is returning."
			else:
				descriptor = "Coup Risk"
				flavor = "Power around you feels one bad moment from turning."
		"Bond":
			var living_bond_descriptor: String = RelationshipsSceneSupport._relationship_bond_descriptor_for_ratio(ratio)
			var subject_dead: bool = bool(surface_context.get("subject_dead", false))

			if subject_dead:
				descriptor = RelationshipsSceneSupport._relationship_bond_posthumous_descriptor(living_bond_descriptor)
				flavor = RelationshipsSceneSupport._relationship_bond_flavor_for_descriptor(living_bond_descriptor, surface_context, true)
				bar_text_override = "Dead"
			else:
				descriptor = living_bond_descriptor
				flavor = RelationshipsSceneSupport._relationship_bond_flavor_for_descriptor(living_bond_descriptor, surface_context, false)

			flavor_already_localized = true
		_:
			descriptor = "%d" % clamp(value, 0, safe_max)
			flavor = ""
	if not flavor_already_localized:
		flavor = StatsSceneSupport._surface_stat_phrase(flavor, surface_context)

	var resolved_bar_text: String = str(bar_text_override).strip_edges()
	if resolved_bar_text == "":
		resolved_bar_text = "%d" % clamp(value, 0, safe_max)

	return {
		"descriptor": descriptor,
		"flavor": flavor,
		"bar_text": resolved_bar_text
	}


static func _player_has_meaningful_approval(p: Person) -> bool:
	if p == null:
		return false

	if GovernmentSceneSupport._player_is_government_figure(p):
		return true

	if bool(p.is_ruler):
		return true

	if bool(p.is_royal):
		return true

	var royal_title: String = str(p.royal_title).strip_edges()
	if royal_title != "":
		return true

	var social_class: String = str(p.social_class).strip_edges()
	if social_class == "Royal":
		return true

	var succession_rank: int = int(p.succession_rank)
	if succession_rank > 0 and succession_rank <= 12:
		if bool(p.is_royal) or royal_title != "" or social_class == "Royal":
			return true

	return false

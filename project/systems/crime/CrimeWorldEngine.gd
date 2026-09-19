extends Resource
class_name CrimeWorldEngine

const CONTRACT_SCHEMA:= "eralife.crime_world"
const CONTRACT_VERSION:= 1
const STATE_KEY:= "crime_world_state"
const CONTENT_PATH:= "res://data/crime_world.json"
const EVENT_HISTORY_LIMIT:= 240

var gs
var content: Dictionary = {}
var last_report: Dictionary = {}


func _init(_gs = null) -> void:
	bind_game_state(_gs)


func bind_game_state(_gs) -> void:
	gs = _gs
	_load_content()
	_ensure_state()


func contract() -> Dictionary:
	return {
		"schema": CONTRACT_SCHEMA,
		"version": CONTRACT_VERSION,
		"state_key": STATE_KEY,
		"content_path": CONTENT_PATH,
		"faction_authority": "UniversalFactionEngine",
		"justice_authority": "CaseOrchestrator",
		"money_authority": "BankEngine",
		"ui_authority": "CrimeHubContractEngine",
		"data_only_extension_points": [
			"eras",
			"ranks",
			"jobs",
			"extortion"
		]
	}


func bootstrap_world(force: bool = false) -> Dictionary:
	var state: Dictionary = _ensure_state()
	if gs == null or gs.player == null:
		return _finish({
			"success": false,
			"waiting": true,
			"reason": "crime_world_waiting_for_player"
		})

	var era_name: String = _current_era_name()
	var era_index: Dictionary = _safe_dictionary(
		state.get("organization_ids_by_era", {})
	)
	var era_organization_ids: Array = _safe_array(
		era_index.get(era_name, [])
	)

	if force or era_organization_ids.is_empty():
		era_organization_ids = _create_organizations_for_era(
			state,
			era_name,
			force
		)
		era_index[era_name] = era_organization_ids.duplicate(false)
		state["organization_ids_by_era"] = era_index
	_reconcile_organization_rosters(state, era_organization_ids)

	_ensure_actor_profile_in_state(state, gs.player)
	state["active_era"] = era_name
	state["last_bootstrap_year"] = _current_year()
	_commit_state(state)
	_sync_faction_contracts(state)

	return _finish({
		"success": true,
		"mode": "crime_world_bootstrapped",
		"era": era_name,
		"organization_ids": era_organization_ids.duplicate(false),
		"organization_count": era_organization_ids.size()
	})


func resolve_intent(actor: Person, payload: Dictionary = {}) -> Dictionary:
	if actor == null:
		return _failure("missing_actor", "Crime World requires an actor.")

	bootstrap_world()
	var action_id: String = str(
		payload.get("action_id", "crime_world_refresh")
	).strip_edges().to_lower()

	match action_id:
		"crime_world_refresh", "crime_world_bootstrap":
			return _finish({
				"success": true,
				"mode": "crime_world_refreshed",
				"text": "The local underworld shifted into view."
			})

		"crime_world_job":
			return perform_job(
				actor,
				str(payload.get("organization_id", "")),
				str(payload.get("job_id", ""))
			)

		"crime_world_join":
			return join_organization(
				actor,
				str(payload.get("organization_id", ""))
			)

		"crime_world_request_promotion":
			return request_promotion(actor)

		"crime_world_generate_extortion":
			return generate_extortion_demand(actor, true)

		"crime_world_respond_extortion":
			return respond_to_extortion(
				actor,
				str(payload.get("case_id", "")),
				str(payload.get("choice_id", ""))
			)

		_:
			return _failure(
				"unsupported_crime_world_intent",
				"Crime World does not support '%s'." % action_id
			)


func build_section_rows(actor: Person, section_id: String) -> Array:
	if actor == null:
		return []

	bootstrap_world()
	match str(section_id).strip_edges().to_lower():
		"underworld":
			return _underworld_rows(actor)
		"organizations":
			return _organization_rows(actor)
		"rackets":
			return _racket_rows(actor)
		_:
			return []


func get_actor_profile(actor: Person) -> Dictionary:
	if actor == null:
		return {}
	var state: Dictionary = _ensure_state()
	var profile: Dictionary = _ensure_actor_profile_in_state(state, actor)
	_commit_state(state)
	return profile.duplicate(true)


func get_organizations_for_actor(_actor: Person = null) -> Array:
	var state: Dictionary = _ensure_state()
	var organizations: Dictionary = _safe_dictionary(
		state.get("organizations", {})
	)
	var active_ids: Array = _safe_array(
		_safe_dictionary(
			state.get("organization_ids_by_era", {})
		).get(_current_era_name(), [])
	)
	var out: Array = []
	for raw_id in active_ids:
		var organization: Dictionary = _safe_dictionary(
			organizations.get(str(raw_id), {})
		)
		if not organization.is_empty():
			out.append(organization.duplicate(true))
	return out


func perform_job(
	actor: Person,
	organization_id: String,
	job_id: String = ""
) -> Dictionary:
	var age_gate: Dictionary = _criminal_age_gate(actor)
	if not bool(age_gate.get("allowed", false)):
		return _failure(
			"criminal_age_gate",
			str(age_gate.get("reason", "You are too young for underworld work."))
		)

	var state: Dictionary = _ensure_state()
	var organizations: Dictionary = _safe_dictionary(state.get("organizations", {}))
	var organization: Dictionary = _safe_dictionary(
		organizations.get(organization_id, {})
	)
	if organization.is_empty():
		return _failure("unknown_organization", "That organization is no longer active.")

	var profile: Dictionary = _ensure_actor_profile_in_state(state, actor)
	var member_organization_id: String = str(profile.get("organization_id", ""))
	if member_organization_id != "" and member_organization_id != organization_id:
		return _failure(
			"rival_organization_job_blocked",
			"Your current family would treat that as betrayal."
		)

	var job: Dictionary = _job_by_id(job_id)
	if job.is_empty():
		job = _best_available_job(profile)
	if job.is_empty():
		return _failure("no_available_job", "No underworld job is available at your rank.")

	var current_rank: String = str(profile.get("rank_id", "outsider"))
	var minimum_rank: String = str(job.get("minimum_rank", "outsider"))
	if _rank_index(current_rank) < _rank_index(minimum_rank):
		return _failure(
			"rank_too_low",
			"That job requires the %s rank." % _rank_label(minimum_rank)
		)

	var total_jobs: int = int(profile.get("successful_jobs", 0)) + int(
		profile.get("failed_jobs", 0)
	)
	var competence_bonus: int = int(round(
		(float(actor.smarts) - 50.0) * 0.16
		+ (float(actor.health) - 50.0) * 0.08
		+ float(profile.get("underworld_reputation", 0)) * 0.05
	))
	var success_chance: int = clampi(
		int(job.get("base_success", 65)) + competence_bonus,
		12,
		94
	)
	var roll: int = _stable_roll(
		"job|%d|%s|%s|%d|%d" % [
			int(actor.id),
			organization_id,
			str(job.get("id", "job")),
			_current_year(),
			total_jobs
		]
	)
	var succeeded: bool = roll < success_chance
	var reputation_gain: int = int(job.get("reputation_gain", 5))
	var heat_gain: int = int(job.get("heat_gain", 2))
	var fear_gain: int = int(job.get("fear_gain", 0))
	var text: String
	var payout: int = 0

	if succeeded:
		payout = _stable_amount(
			int(job.get("payout_min", 100)),
			int(job.get("payout_max", 500)),
			"payout|%d|%s|%d" % [int(actor.id), str(job.get("id", "")), total_jobs]
		)
		_credit_actor(actor, payout, "crime_world_job")
		profile["successful_jobs"] = int(profile.get("successful_jobs", 0)) + 1
		profile["underworld_reputation"] = clampi(
			int(profile.get("underworld_reputation", 0)) + reputation_gain,
			0,
			200
		)
		profile["fear"] = clampi(int(profile.get("fear", 0)) + fear_gain, 0, 100)
		profile["heat"] = clampi(int(profile.get("heat", 0)) + heat_gain, 0, 100)
		profile["loyalty"] = clampi(int(profile.get("loyalty", 50)) + 3, 0, 100)
		if str(profile.get("rank_id", "outsider")) == "outsider":
			profile["rank_id"] = "connected"
			profile["connected_organization_id"] = organization_id
		text = "You completed %s for the %s and earned %d coins." % [
			str(job.get("label", "an underworld job")),
			str(organization.get("name", "organization")),
			payout
		]
		_add_organization_resource(organization, "wealth", float(payout) * 2.5)
		_add_organization_resource(organization, "power", 0.8)
	else:
		profile["failed_jobs"] = int(profile.get("failed_jobs", 0)) + 1
		profile["heat"] = clampi(int(profile.get("heat", 0)) + maxi(2, heat_gain), 0, 100)
		profile["loyalty"] = clampi(int(profile.get("loyalty", 50)) - 4, 0, 100)
		text = "The %s job went wrong. You escaped, but attention followed you home." % str(
			job.get("label", "underworld")
		)
		_add_organization_resource(organization, "heat", 3.0)

	profile["last_job_year"] = _current_year()
	profile["last_job_id"] = str(job.get("id", ""))
	organizations[organization_id] = organization
	var profiles: Dictionary = _safe_dictionary(state.get("actor_profiles", {}))
	profiles[str(int(actor.id))] = profile
	state["actor_profiles"] = profiles
	state["organizations"] = organizations
	_commit_state(state)
	_sync_faction_contracts(state)
	_record_narrative(actor, text, "crime_world.job_resolved", {
		"organization_id": organization_id,
		"job_id": str(job.get("id", "")),
		"success": succeeded,
		"payout": payout
	})

	return _finish({
		"success": succeeded,
		"mode": "crime_world_job_resolved",
		"text": text,
		"popup_title": "Underworld Job",
		"popup_text": text,
		"popup_footer": "Your reputation: %d • Heat: %d" % [
			int(profile.get("underworld_reputation", 0)),
			int(profile.get("heat", 0))
		],
		"job": job.duplicate(true),
		"payout": payout,
		"profile": profile.duplicate(true)
	})


func join_organization(actor: Person, organization_id: String) -> Dictionary:
	var age_gate: Dictionary = _criminal_age_gate(actor)
	if not bool(age_gate.get("allowed", false)):
		return _failure("criminal_age_gate", str(age_gate.get("reason", "Too young.")))

	var state: Dictionary = _ensure_state()
	var organizations: Dictionary = _safe_dictionary(state.get("organizations", {}))
	var organization: Dictionary = _safe_dictionary(organizations.get(organization_id, {}))
	if organization.is_empty():
		return _failure("unknown_organization", "That organization is unavailable.")

	var profile: Dictionary = _ensure_actor_profile_in_state(state, actor)
	if str(profile.get("organization_id", "")) != "":
		return _failure("already_joined", "You already belong to an organization.")
	if str(profile.get("connected_organization_id", "")) != organization_id:
		return _failure("not_connected", "You need to earn this family's trust first.")
	if int(profile.get("underworld_reputation", 0)) < 12 or int(profile.get("successful_jobs", 0)) < 2:
		return _failure(
			"reputation_too_low",
			"Become Connected and complete two successful jobs before asking to join."
		)

	profile["organization_id"] = organization_id
	profile["rank_id"] = "associate"
	profile["joined_year"] = _current_year()
	profile["loyalty"] = maxi(55, int(profile.get("loyalty", 50)))
	_upsert_organization_member(
		organization,
		int(actor.id),
		"associate",
		int(profile.get("loyalty", 55))
	)
	organizations[organization_id] = organization
	var profiles: Dictionary = _safe_dictionary(state.get("actor_profiles", {}))
	profiles[str(int(actor.id))] = profile
	state["actor_profiles"] = profiles
	state["organizations"] = organizations
	_commit_state(state)
	_sync_faction_contracts(state)

	var text: String = "The %s accepted you as an Associate." % str(
		organization.get("name", "organization")
	)
	_record_narrative(actor, text, "crime_world.organization_joined", {
		"organization_id": organization_id,
		"rank_id": "associate"
	})
	return _finish({
		"success": true,
		"mode": "crime_world_organization_joined",
		"text": text,
		"popup_title": "Made",
		"popup_text": text,
		"popup_footer": "Loyalty opens doors. Betrayal closes them permanently.",
		"profile": profile.duplicate(true)
	})


func request_promotion(actor: Person) -> Dictionary:
	var state: Dictionary = _ensure_state()
	var profile: Dictionary = _ensure_actor_profile_in_state(state, actor)
	var organization_id: String = str(profile.get("organization_id", ""))
	if organization_id == "":
		return _failure("not_a_member", "Join an organization before requesting promotion.")

	var current_rank: String = str(profile.get("rank_id", "associate"))
	var next_rank: Dictionary = _next_rank_contract(current_rank)
	if next_rank.is_empty():
		return _failure("already_boss", "There is nowhere higher to climb.")

	var required_reputation: int = int(next_rank.get("reputation", 0))
	var required_jobs: int = int(next_rank.get("successful_jobs", 0))
	if (
		int(profile.get("underworld_reputation", 0)) < required_reputation
		or int(profile.get("successful_jobs", 0)) < required_jobs
	):
		return _failure(
			"promotion_requirements_not_met",
			"%s requires %d reputation and %d successful jobs." % [
				str(next_rank.get("label", "Promotion")),
				required_reputation,
				required_jobs
			]
		)

	var organizations: Dictionary = _safe_dictionary(state.get("organizations", {}))
	var organization: Dictionary = _safe_dictionary(organizations.get(organization_id, {}))
	var next_rank_id: String = str(next_rank.get("id", current_rank))
	if next_rank_id == "boss":
		_demote_existing_boss(organization, int(actor.id))

	profile["rank_id"] = next_rank_id
	profile["last_promotion_year"] = _current_year()
	profile["loyalty"] = clampi(int(profile.get("loyalty", 50)) + 5, 0, 100)
	_upsert_organization_member(
		organization,
		int(actor.id),
		next_rank_id,
		int(profile.get("loyalty", 50))
	)
	if next_rank_id == "boss":
		organization["leader_id"] = int(actor.id)
	organizations[organization_id] = organization
	var profiles: Dictionary = _safe_dictionary(state.get("actor_profiles", {}))
	profiles[str(int(actor.id))] = profile
	state["actor_profiles"] = profiles
	state["organizations"] = organizations
	_commit_state(state)
	_sync_faction_contracts(state)

	var text: String = "You rose to %s in the %s." % [
		str(next_rank.get("label", next_rank_id.capitalize())),
		str(organization.get("name", "organization"))
	]
	_record_narrative(actor, text, "crime_world.rank_changed", {
		"organization_id": organization_id,
		"previous_rank_id": current_rank,
		"rank_id": next_rank_id
	})
	return _finish({
		"success": true,
		"mode": "crime_world_rank_changed",
		"text": text,
		"popup_title": "Promotion",
		"popup_text": text,
		"popup_footer": "Power creates obligations.",
		"profile": profile.duplicate(true)
	})


func generate_extortion_demand(actor: Person, manual: bool = false) -> Dictionary:
	if actor == null or int(actor.age) < 18:
		return _failure("extortion_target_ineligible", "No eligible adult target exists.")

	var state: Dictionary = _ensure_state()
	var existing: Dictionary = _active_extortion_for_actor(state, int(actor.id))
	if not existing.is_empty():
		return _failure("extortion_already_active", "An extortion arrangement is already active.")

	var target: Dictionary = _extortion_target_for_actor(actor)
	if target.is_empty():
		return _failure(
			"extortion_target_ineligible",
			"Own property or work as a business owner before protection rackets can find you."
		)

	var profile: Dictionary = _ensure_actor_profile_in_state(state, actor)
	var organization: Dictionary = _extorting_organization(
		state,
		str(profile.get("organization_id", ""))
	)
	if organization.is_empty():
		return _failure("no_extorting_organization", "No rival organization controls this area.")

	var extortion_policy: Dictionary = _safe_dictionary(content.get("extortion", {}))
	var target_value: float = float(target.get("value", 0.0))
	var demand: int = int(round(
		maxi(1, int(target_value))
		* float(extortion_policy.get("property_value_rate", 0.035))
	))
	if target_value <= 0.0:
		demand = 3600 + int(float(actor.bank_balance) * 0.025)
	demand = clampi(
		demand,
		int(extortion_policy.get("minimum_annual_payment", 1200)),
		int(extortion_policy.get("maximum_annual_payment", 48000))
	)

	var case_id: String = "extortion_%d_%d_%s" % [
		int(actor.id),
		_current_year(),
		str(organization.get("id", "organization"))
	]
	var extortion_case: Dictionary = {
		"schema": "eralife.crime_world_extortion",
		"version": CONTRACT_VERSION,
		"case_id": case_id,
		"actor_id": int(actor.id),
		"organization_id": str(organization.get("id", "")),
		"target": target.duplicate(true),
		"annual_payment": demand,
		"original_annual_payment": demand,
		"status": "demanded",
		"security_level": 0,
		"created_year": _current_year(),
		"next_payment_year": _current_year(),
		"consequence_due_year": -1,
		"response_history": [],
		"manual_offer": manual
	}
	var cases: Dictionary = _safe_dictionary(state.get("extortion_cases", {}))
	cases[case_id] = extortion_case
	state["extortion_cases"] = cases
	_commit_state(state)

	var text: String = (
		"Representatives of the %s visited %s after closing. "
		+ "They demanded %d coins per year for protection."
	) % [
		str(organization.get("name", "local organization")),
		str(target.get("label", "your property")),
		demand
	]
	_record_narrative(actor, text, "crime_world.extortion_demanded", {
		"case_id": case_id,
		"organization_id": str(organization.get("id", "")),
		"annual_payment": demand,
		"target": target.duplicate(true)
	})
	return _finish({
		"success": true,
		"mode": "crime_world_extortion_demanded",
		"text": text,
		"popup_title": "A Visit After Closing",
		"popup_text": text,
		"popup_footer": "The Crime Hub now contains your response options.",
		"extortion_case": extortion_case.duplicate(true)
	})


func respond_to_extortion(
	actor: Person,
	case_id: String,
	choice_id: String
) -> Dictionary:
	var state: Dictionary = _ensure_state()
	var cases: Dictionary = _safe_dictionary(state.get("extortion_cases", {}))
	var extortion_case: Dictionary = _safe_dictionary(cases.get(case_id, {}))
	if extortion_case.is_empty() or int(extortion_case.get("actor_id", -1)) != int(actor.id):
		return _failure("unknown_extortion_case", "That protection demand no longer exists.")

	var status: String = str(extortion_case.get("status", "demanded"))
	if status not in ["demanded", "negotiated"]:
		return _failure("extortion_response_closed", "That demand has already been answered.")

	var organizations: Dictionary = _safe_dictionary(state.get("organizations", {}))
	var organization_id: String = str(extortion_case.get("organization_id", ""))
	var organization: Dictionary = _safe_dictionary(organizations.get(organization_id, {}))
	var profile: Dictionary = _ensure_actor_profile_in_state(state, actor)
	var choice: String = str(choice_id).strip_edges().to_lower()
	var text: String = ""
	var payment: int = int(extortion_case.get("annual_payment", 0))
	var succeeded: bool = true

	match choice:
		"pay":
			var payment_report: Dictionary = _spend_actor(
				actor,
				payment,
				"crime_world_protection_payment"
			)
			if not bool(payment_report.get("success", false)):
				return _failure(
					"protection_payment_failed",
					str(payment_report.get("reason", "You cannot afford the protection payment."))
				)
			extortion_case["status"] = "active"
			extortion_case["next_payment_year"] = _current_year() + 1
			extortion_case["last_payment_year"] = _current_year()
			profile["protected_until_year"] = _current_year() + 1
			profile["underworld_reputation"] = clampi(
				int(profile.get("underworld_reputation", 0)) + 2,
				0,
				200
			)
			_add_organization_resource(organization, "wealth", payment)
			text = "You paid %d coins. The %s now considers %s protected." % [
				payment,
				str(organization.get("name", "organization")),
				str(_safe_dictionary(extortion_case.get("target", {})).get("label", "your property"))
			]

		"refuse":
			extortion_case["status"] = "refused"
			extortion_case["consequence_due_year"] = _current_year() + 1
			profile["fear"] = clampi(int(profile.get("fear", 0)) + 3, 0, 100)
			text = "You refused the %s. Nothing happened immediately." % str(
				organization.get("name", "organization")
			)

		"negotiate":
			var negotiation_roll: int = _stable_roll(
				"negotiate|%d|%s|%d" % [int(actor.id), case_id, _current_year()]
			)
			var negotiation_chance: int = clampi(
				35 + int(float(actor.smarts) * 0.35) + int(float(actor.willpower) * 0.2),
				35,
				88
			)
			if negotiation_roll < negotiation_chance:
				payment = maxi(600, int(round(float(payment) * 0.72)))
				extortion_case["annual_payment"] = payment
				extortion_case["status"] = "negotiated"
				profile["underworld_reputation"] = clampi(
					int(profile.get("underworld_reputation", 0)) + 2,
					0,
					200
				)
				text = "You negotiated the annual demand down to %d coins." % payment
			else:
				succeeded = false
				extortion_case["status"] = "refused"
				extortion_case["consequence_due_year"] = _current_year() + 1
				text = "The negotiation failed. They treated your counteroffer as a refusal."

		"call_police":
			extortion_case["status"] = "reported"
			extortion_case["consequence_due_year"] = _current_year() + 1
			_add_organization_resource(organization, "heat", 18.0)
			var case_report: Dictionary = _register_extortion_case(
				actor,
				organization,
				extortion_case
			)
			extortion_case["justice_case_id"] = str(case_report.get("case_id", ""))
			text = "You reported the demand. Investigators opened a case, but the family may learn who called."

		"hire_security":
			var policy: Dictionary = _safe_dictionary(content.get("extortion", {}))
			var security_cost: int = maxi(
				500,
				int(round(float(payment) * float(policy.get("security_cost_rate", 0.55))))
			)
			var security_report: Dictionary = _spend_actor(
				actor,
				security_cost,
				"crime_world_security_contract"
			)
			if not bool(security_report.get("success", false)):
				return _failure(
					"security_payment_failed",
					str(security_report.get("reason", "You cannot afford security."))
				)
			extortion_case["status"] = "secured"
			extortion_case["security_level"] = 60
			extortion_case["security_cost"] = security_cost
			extortion_case["consequence_due_year"] = _current_year() + 1
			text = "You hired security for %d coins and refused the protection demand." % security_cost

		"threaten":
			var threat_roll: int = _stable_roll(
				"threaten|%d|%s|%d" % [int(actor.id), case_id, _current_year()]
			)
			var threat_chance: int = clampi(
				15 + int(float(actor.health) * 0.25) + int(float(profile.get("fear", 0)) * 0.45),
				18,
				82
			)
			profile["fear"] = clampi(int(profile.get("fear", 0)) + 9, 0, 100)
			profile["heat"] = clampi(int(profile.get("heat", 0)) + 5, 0, 100)
			if threat_roll < threat_chance:
				extortion_case["status"] = "withdrawn"
				text = "Your threat landed. The collectors withdrew—for now."
			else:
				succeeded = false
				extortion_case["status"] = "refused"
				extortion_case["consequence_due_year"] = _current_year() + 1
				text = "Your threat failed. The collectors left smiling."

		_:
			return _failure("unknown_extortion_choice", "Choose a valid response.")

	var history: Array = _safe_array(extortion_case.get("response_history", []))
	history.append({
		"choice_id": choice,
		"year": _current_year(),
		"resulting_status": str(extortion_case.get("status", "")),
		"text": text
	})
	extortion_case["response_history"] = history
	extortion_case["updated_year"] = _current_year()
	cases[case_id] = extortion_case
	organizations[organization_id] = organization
	var profiles: Dictionary = _safe_dictionary(state.get("actor_profiles", {}))
	profiles[str(int(actor.id))] = profile
	state["actor_profiles"] = profiles
	state["extortion_cases"] = cases
	state["organizations"] = organizations
	_commit_state(state)
	_sync_faction_contracts(state)
	_record_narrative(actor, text, "crime_world.extortion_resolved", {
		"case_id": case_id,
		"choice_id": choice,
		"status": str(extortion_case.get("status", ""))
	})

	return _finish({
		"success": succeeded,
		"mode": "crime_world_extortion_response",
		"text": text,
		"popup_title": "Protection Demand",
		"popup_text": text,
		"popup_footer": "Consequences may arrive during a future year.",
		"extortion_case": extortion_case.duplicate(true),
		"profile": profile.duplicate(true)
	})


func yearly_tick(_plan: Dictionary = {}, _metrics: Dictionary = {}) -> Dictionary:
	var boot_report: Dictionary = bootstrap_world()
	if not bool(boot_report.get("success", false)):
		return boot_report

	var state: Dictionary = _ensure_state()
	var profiles: Dictionary = _safe_dictionary(state.get("actor_profiles", {}))
	for raw_profile_id in profiles.keys():
		var profile: Dictionary = _safe_dictionary(profiles.get(raw_profile_id, {}))
		profile["heat"] = maxi(0, int(profile.get("heat", 0)) - 8)
		profiles[raw_profile_id] = profile
	state["actor_profiles"] = profiles

	var organizations: Dictionary = _safe_dictionary(state.get("organizations", {}))
	for raw_organization_id in organizations.keys():
		var organization: Dictionary = _safe_dictionary(
			organizations.get(raw_organization_id, {})
		)
		var resources: Dictionary = _safe_dictionary(
			organization.get("resource_ledger", {})
		)
		resources["heat"] = maxf(0.0, float(resources.get("heat", 0.0)) - 4.0)
		resources["wealth"] = maxf(
			0.0,
			float(resources.get("wealth", 0.0))
			+ float(resources.get("racket_income", 0.0))
		)
		organization["resource_ledger"] = resources
		organization["last_year_active"] = _current_year()
		organizations[raw_organization_id] = organization
	state["organizations"] = organizations

	var processed_cases: int = _process_extortion_year(state)
	# Persist annual payments and delayed consequences before the optional
	# automatic-offer path loads state through the public intent boundary.
	_commit_state(state)
	if gs.player != null:
		_maybe_offer_extortion(state, gs.player)
		# Automatic offers use the public intent path and commit their own state.
		# Refresh so this yearly commit cannot overwrite a newly-created demand.
		state = _ensure_state()
	state["last_yearly_tick"] = {
		"year": _current_year(),
		"processed_extortion_cases": processed_cases,
		"organization_count": organizations.size()
	}
	_commit_state(state)
	_sync_faction_contracts(state)
	return _finish({
		"success": true,
		"mode": "crime_world_yearly_tick",
		"year": _current_year(),
		"processed_extortion_cases": processed_cases
	})


func export_state() -> Dictionary:
	return _ensure_state().duplicate(true)


func import_state(data: Dictionary) -> Dictionary:
	if data.is_empty():
		return _failure("empty_import", "Crime World import data is empty.")
	var imported: Dictionary = data.duplicate(true)
	imported["schema"] = CONTRACT_SCHEMA
	imported["version"] = CONTRACT_VERSION
	_commit_state(imported)
	_sync_faction_contracts(imported)
	return _finish({"success": true, "mode": "crime_world_state_imported"})


func _underworld_rows(actor: Person) -> Array:
	var profile: Dictionary = get_actor_profile(actor)
	var organization: Dictionary = _organization_by_id(
		str(profile.get("organization_id", ""))
	)
	var organization_label: String = (
		str(organization.get("name", "Independent"))
		if not organization.is_empty()
		else "Independent"
	)
	var rows: Array = [
		{
			"kind": "crime_world_identity",
			"label": "%s • %s" % [
				_rank_label(str(profile.get("rank_id", "outsider"))),
				organization_label
			],
			"subtitle": "Underworld reputation %d • Fear %d • Heat %d" % [
				int(profile.get("underworld_reputation", 0)),
				int(profile.get("fear", 0)),
				int(profile.get("heat", 0))
			]
		},
		{
			"kind": "crime_world_progress",
			"label": "Criminal Career",
			"subtitle": "%d successful jobs • %d failed jobs • Loyalty %d" % [
				int(profile.get("successful_jobs", 0)),
				int(profile.get("failed_jobs", 0)),
				int(profile.get("loyalty", 50))
			]
		}
	]

	if str(profile.get("organization_id", "")) != "":
		rows.append({
			"kind": "crime_world_promotion",
			"label": "Ask for Promotion",
			"subtitle": _promotion_requirement_text(profile),
			"actions": [
				{
					"id": "crime_world_request_promotion",
					"label": "REQUEST PROMOTION",
					"payload": {"action_id": "crime_world_request_promotion"}
				}
			]
		})
	return rows


func _organization_rows(actor: Person) -> Array:
	var profile: Dictionary = get_actor_profile(actor)
	var rows: Array = []
	for organization in get_organizations_for_actor(actor):
		var resources: Dictionary = _safe_dictionary(
			organization.get("resource_ledger", {})
		)
		var members: Dictionary = _safe_dictionary(organization.get("members", {}))
		var territories: Array = _safe_array(organization.get("territory_ids", []))
		var actions: Array = []
		var organization_id: String = str(organization.get("id", ""))
		var actor_organization_id: String = str(profile.get("organization_id", ""))
		var connected_id: String = str(profile.get("connected_organization_id", ""))

		if actor_organization_id == "" or actor_organization_id == organization_id:
			var job: Dictionary = _best_available_job(profile)
			if not job.is_empty():
				actions.append({
					"id": "crime_world_job",
					"label": (
						"DO FAMILY JOB"
						if actor_organization_id == organization_id
						else "DO A SMALL JOB"
					),
					"payload": {
						"action_id": "crime_world_job",
						"organization_id": organization_id,
						"job_id": str(job.get("id", ""))
					}
				})

		if (
			actor_organization_id == ""
			and connected_id == organization_id
			and int(profile.get("underworld_reputation", 0)) >= 12
			and int(profile.get("successful_jobs", 0)) >= 2
		):
			actions.append({
				"id": "crime_world_join",
				"label": "JOIN AS ASSOCIATE",
				"payload": {
					"action_id": "crime_world_join",
					"organization_id": organization_id
				}
			})

		rows.append({
			"kind": "crime_world_organization",
			"label": str(organization.get("name", "Criminal Organization")),
			"subtitle": "%s • %d members • %d territories • Power %d • Heat %d" % [
				str(organization.get("kind", "crime syndicate")).replace("_", " ").capitalize(),
				members.size(),
				territories.size(),
				int(round(float(resources.get("power", 0.0)))),
				int(round(float(resources.get("heat", 0.0))))
			],
			"organization_id": organization_id,
			"actions": actions
		})
	return rows


func _racket_rows(actor: Person) -> Array:
	var state: Dictionary = _ensure_state()
	var rows: Array = []
	var active: Dictionary = _active_extortion_for_actor(state, int(actor.id))
	if active.is_empty():
		var target: Dictionary = _extortion_target_for_actor(actor)
		if target.is_empty():
			rows.append({
				"kind": "empty_state",
				"label": "No protection racket has a hold on you",
				"subtitle": "Own property or become a business owner to expose this story path."
			})
		else:
			rows.append({
				"kind": "crime_world_racket_opportunity",
				"label": "No active protection arrangement",
				"subtitle": "%s is visible to the local underworld." % str(
					target.get("label", "Your property")
				),
				"actions": [
					{
						"id": "crime_world_generate_extortion",
						"label": "SURFACE PROTECTION STORY",
						"payload": {"action_id": "crime_world_generate_extortion"}
					}
				]
			})
		return rows

	var organization: Dictionary = _organization_by_id(
		str(active.get("organization_id", ""))
	)
	var target: Dictionary = _safe_dictionary(active.get("target", {}))
	var status: String = str(active.get("status", "demanded"))
	var actions: Array = []
	if status in ["demanded", "negotiated"]:
		for choice in [
			{"id": "pay", "label": "PAY"},
			{"id": "refuse", "label": "REFUSE"},
			{"id": "negotiate", "label": "NEGOTIATE"},
			{"id": "call_police", "label": "CALL POLICE"},
			{"id": "hire_security", "label": "HIRE SECURITY"},
			{"id": "threaten", "label": "THREATEN THEM"}
		]:
			actions.append({
				"id": "crime_world_respond_extortion",
				"label": str(choice.get("label", "RESPOND")),
				"payload": {
					"action_id": "crime_world_respond_extortion",
					"case_id": str(active.get("case_id", "")),
					"choice_id": str(choice.get("id", ""))
				}
			})

	rows.append({
		"kind": "crime_world_extortion",
		"label": "%s • %s" % [
			str(organization.get("name", "Unknown Organization")),
			status.capitalize()
		],
		"subtitle": "%s • %d coins/year • Security %d" % [
			str(target.get("label", "Target")),
			int(active.get("annual_payment", 0)),
			int(active.get("security_level", 0))
		],
		"actions": actions,
		"extortion_case": active.duplicate(true)
	})
	return rows


func _create_organizations_for_era(
	state: Dictionary,
	era_name: String,
	force: bool
) -> Array:
	var eras: Dictionary = _safe_dictionary(content.get("eras", {}))
	var definitions: Array = _safe_array(eras.get(era_name, eras.get("Modern Era", [])))
	var organizations: Dictionary = _safe_dictionary(state.get("organizations", {}))
	var created_ids: Array = []
	var used_member_ids: Dictionary = _used_organization_member_ids(organizations)

	for definition_index in range(definitions.size()):
		var definition: Dictionary = _safe_dictionary(definitions[definition_index])
		var organization_id: String = "%s:%s" % [
			_era_key(era_name),
			str(definition.get("id", "organization_%d" % definition_index))
		]
		if organizations.has(organization_id) and not force:
			created_ids.append(organization_id)
			continue

		var members: Dictionary = _select_organization_members(
			organization_id,
			used_member_ids,
			6
		)
		for raw_member_id in members.keys():
			used_member_ids[str(raw_member_id)] = true

		var leader_id: int = -1
		for raw_member_key in members.keys():
			var member: Dictionary = _safe_dictionary(members.get(raw_member_key, {}))
			if str(member.get("role", "")) == "boss":
				leader_id = int(member.get("npc_id", -1))
				break

		var wealth: float = float(definition.get("wealth", 100000.0))
		var organization: Dictionary = {
			"schema": "eralife.organized_crime_organization",
			"version": CONTRACT_VERSION,
			"id": organization_id,
			"archetype_id": str(definition.get("id", "")),
			"name": str(definition.get("name", "Criminal Organization")),
			"kind": str(definition.get("kind", "crime_syndicate")),
			"era": era_name,
			"tags": _safe_array(definition.get("tags", [])),
			"status": "active",
			"created_year": _current_year(),
			"last_year_active": _current_year(),
			"leader_id": leader_id,
			"members": members,
			"territory_ids": _territory_ids_for_player(definition_index),
			"resource_ledger": {
				"wealth": wealth,
				"power": float(definition.get("power", 50.0)),
				"fear": float(definition.get("fear", 50.0)),
				"heat": float(definition.get("heat", 25.0)),
				"corruption": float(definition.get("corruption", 30.0)),
				"racket_income": maxf(600.0, wealth * 0.012)
			},
			"rackets": [
				{
					"id": "%s:protection" % organization_id,
					"type": "protection",
					"status": "active",
					"annual_income": maxf(600.0, wealth * 0.012)
				}
			]
		}
		organizations[organization_id] = organization
		created_ids.append(organization_id)

	state["organizations"] = organizations
	return created_ids


func _select_organization_members(
	organization_id: String,
	used_member_ids: Dictionary,
	limit: int
) -> Dictionary:
	var candidates: Array = []
	if gs == null:
		return {}
	for raw_npc in gs.npcs:
		var npc: Person = raw_npc
		if npc == null or not npc.alive or npc == gs.player:
			continue
		if int(npc.age) < 18 or used_member_ids.has(str(int(npc.id))):
			continue
		candidates.append(npc)

	candidates.sort_custom(func(a: Person, b: Person) -> bool:
		return _member_candidate_score(a, organization_id) > _member_candidate_score(b, organization_id)
	)
	var roles: Array = ["boss", "underboss", "capo", "soldier", "soldier", "associate"]
	var members: Dictionary = {}
	for index in range(mini(limit, candidates.size())):
		var npc: Person = candidates[index]
		members[str(int(npc.id))] = {
			"npc_id": int(npc.id),
			"role": str(roles[index] if index < roles.size() else "associate"),
			"loyalty": clampi(
				40 + int(float(npc.ambition) * 0.25) + _stable_roll(
					"loyalty|%s|%d" % [organization_id, int(npc.id)]
				) / 5,
				25,
				88
			),
			"joined_year": _current_year(),
			"active": true
		}
	return members


func _reconcile_organization_rosters(
	state: Dictionary,
	organization_ids: Array
) -> void:
	var organizations: Dictionary = _safe_dictionary(state.get("organizations", {}))
	var used_member_ids: Dictionary = _used_organization_member_ids(organizations)
	var roles: Array = ["boss", "underboss", "capo", "soldier", "soldier", "associate"]
	for raw_organization_id in organization_ids:
		var organization_id: String = str(raw_organization_id)
		var organization: Dictionary = _safe_dictionary(organizations.get(organization_id, {}))
		if organization.is_empty():
			continue
		var members: Dictionary = _safe_dictionary(organization.get("members", {}))
		if members.size() >= roles.size():
			continue
		var candidates: Array = []
		for raw_npc in gs.npcs:
			var npc: Person = raw_npc
			if (
				npc == null
				or not npc.alive
				or npc == gs.player
				or int(npc.age) < 18
				or used_member_ids.has(str(int(npc.id)))
			):
				continue
			candidates.append(npc)
		candidates.sort_custom(func(a: Person, b: Person) -> bool:
			return _member_candidate_score(a, organization_id) > _member_candidate_score(b, organization_id)
		)
		for npc in candidates:
			if members.size() >= roles.size():
				break
			var role: String = str(roles[members.size()])
			members[str(int(npc.id))] = {
				"npc_id": int(npc.id),
				"role": role,
				"loyalty": clampi(
					40 + int(float(npc.ambition) * 0.25) + _stable_roll(
						"loyalty|%s|%d" % [organization_id, int(npc.id)]
					) / 5,
					25,
					88
				),
				"joined_year": _current_year(),
				"active": true
			}
			used_member_ids[str(int(npc.id))] = true
			if role == "boss":
				organization["leader_id"] = int(npc.id)
		organization["members"] = members
		organizations[organization_id] = organization
	state["organizations"] = organizations


func _member_candidate_score(npc: Person, organization_id: String) -> float:
	return (
		float(npc.ambition) * 0.55
		+ float(npc.smarts) * 0.25
		+ float(npc.health) * 0.1
		+ float(_stable_roll("member|%s|%d" % [organization_id, int(npc.id)])) * 0.1
	)


func _sync_faction_contracts(state: Dictionary) -> void:
	if (
		gs == null
		or gs.universal_faction_engine == null
		or not gs.universal_faction_engine.has_method("ingest_faction_contract_pack")
	):
		return

	var contracts: Array = []
	var organizations: Dictionary = _safe_dictionary(state.get("organizations", {}))
	for raw_organization_id in organizations.keys():
		var organization: Dictionary = _safe_dictionary(
			organizations.get(raw_organization_id, {})
		)
		var members: Array = []
		for raw_member_key in _safe_dictionary(organization.get("members", {})).keys():
			var member: Dictionary = _safe_dictionary(
				_safe_dictionary(organization.get("members", {})).get(raw_member_key, {})
			)
			members.append(member.duplicate(true))
		var territories: Array = []
		for raw_territory_id in _safe_array(organization.get("territory_ids", [])):
			territories.append({"id": str(raw_territory_id), "weight": 1.0})
		var resources: Dictionary = _safe_dictionary(
			organization.get("resource_ledger", {})
		)
		contracts.append({
			"id": str(organization.get("id", raw_organization_id)),
			"faction_id": str(organization.get("id", raw_organization_id)),
			"name": str(organization.get("name", "Criminal Organization")),
			"domain": "crime_world",
			"kind": str(organization.get("kind", "crime_syndicate")),
			"tags": _safe_array(organization.get("tags", [])),
			"members": members,
			"territories": territories,
			"resources": resources.duplicate(true),
			"metrics": {
				"visibility": clampf(25.0 + float(resources.get("heat", 0.0)) * 0.55, 0.0, 100.0),
				"cohesion": _organization_cohesion(organization),
				"hostility": clampf(float(resources.get("fear", 0.0)) * 0.62, 0.0, 100.0),
				"legitimacy": clampf(float(resources.get("corruption", 0.0)) * 0.45, 0.0, 100.0),
				"pressure": clampf(float(resources.get("power", 0.0)) * 0.48, 0.0, 100.0),
				"prestige": clampf(float(resources.get("power", 0.0)), 0.0, 100.0)
			},
			"projection": {
				"leader_id": int(organization.get("leader_id", -1)),
				"status": str(organization.get("status", "active"))
			},
			"metadata": {
				"crime_world_schema": CONTRACT_SCHEMA,
				"era": str(organization.get("era", "")),
				"rackets": _safe_array(organization.get("rackets", [])).duplicate(true)
			}
		})

	gs.universal_faction_engine.ingest_faction_contract_pack({
		"id": "eralife.crime_world.runtime",
		"faction_contracts": contracts
	})


func _process_extortion_year(state: Dictionary) -> int:
	var cases: Dictionary = _safe_dictionary(state.get("extortion_cases", {}))
	var processed: int = 0
	for raw_case_id in cases.keys():
		var extortion_case: Dictionary = _safe_dictionary(cases.get(raw_case_id, {}))
		var actor = _actor_by_id(int(extortion_case.get("actor_id", -1)))
		if actor == null:
			continue
		var status: String = str(extortion_case.get("status", ""))

		if status == "active" and _current_year() >= int(extortion_case.get("next_payment_year", 2147483647)):
			var amount: int = int(extortion_case.get("annual_payment", 0))
			var payment_report: Dictionary = _spend_actor(
				actor,
				amount,
				"crime_world_annual_protection_payment"
			)
			if bool(payment_report.get("success", false)):
				extortion_case["last_payment_year"] = _current_year()
				extortion_case["next_payment_year"] = _current_year() + 1
				_record_narrative(
					actor,
					"You paid the annual %d-coin protection demand." % amount,
					"crime_world.protection_payment",
					{"case_id": str(raw_case_id), "amount": amount}
				)
			else:
				extortion_case["status"] = "refused"
				extortion_case["consequence_due_year"] = _current_year() + 1
			processed += 1

		if (
			str(extortion_case.get("status", "")) in ["refused", "reported", "secured"]
			and _current_year() >= int(extortion_case.get("consequence_due_year", 2147483647))
		):
			_resolve_extortion_consequence(state, actor, extortion_case)
			processed += 1

		cases[raw_case_id] = extortion_case
	state["extortion_cases"] = cases
	return processed


func _resolve_extortion_consequence(
	state: Dictionary,
	actor: Person,
	extortion_case: Dictionary
) -> void:
	var policy: Dictionary = _safe_dictionary(content.get("extortion", {}))
	var chance: int = int(policy.get("retaliation_chance", 68))
	chance -= int(round(
		float(extortion_case.get("security_level", 0))
		* float(policy.get("security_retaliation_reduction", 46))
		/ 100.0
	))
	var organization: Dictionary = _organization_by_id_from_state(
		state,
		str(extortion_case.get("organization_id", ""))
	)
	var resources: Dictionary = _safe_dictionary(organization.get("resource_ledger", {}))
	if float(resources.get("heat", 0.0)) >= 78.0:
		chance -= 28
	chance = clampi(chance, 8, 90)

	var roll: int = _stable_roll(
		"retaliation|%s|%d" % [str(extortion_case.get("case_id", "")), _current_year()]
	)
	if roll < chance:
		extortion_case["status"] = "retaliated"
		extortion_case["retaliation_year"] = _current_year()
		actor.health = maxi(0, int(actor.health) - 3)
		var target: Dictionary = _safe_dictionary(extortion_case.get("target", {}))
		var text: String = "The %s retaliated against %s. Windows were smashed and a suspicious fire damaged the property." % [
			str(organization.get("name", "organization")),
			str(target.get("label", "your property"))
		]
		_record_narrative(actor, text, "crime_world.extortion_retaliation", {
			"case_id": str(extortion_case.get("case_id", "")),
			"organization_id": str(organization.get("id", "")),
			"target": target.duplicate(true)
		})
	else:
		extortion_case["status"] = "abandoned"
		var text: String = "The %s backed away from its demand as pressure and security mounted." % str(
			organization.get("name", "organization")
		)
		_record_narrative(actor, text, "crime_world.extortion_abandoned", {
			"case_id": str(extortion_case.get("case_id", ""))
		})


func _maybe_offer_extortion(state: Dictionary, actor: Person) -> void:
	if actor == null or int(actor.age) < 18:
		return
	if not _active_extortion_for_actor(state, int(actor.id)).is_empty():
		return
	if _extortion_target_for_actor(actor).is_empty():
		return
	var policy: Dictionary = _safe_dictionary(content.get("extortion", {}))
	var chance: int = int(policy.get("yearly_offer_chance", 24))
	if _stable_roll("offer|%d|%d" % [int(actor.id), _current_year()]) < chance:
		generate_extortion_demand(actor, false)


func _register_extortion_case(
	actor: Person,
	organization: Dictionary,
	extortion_case: Dictionary
) -> Dictionary:
	if (
		gs == null
		or gs.crime_contract_engine == null
		or gs.case_orchestrator == null
		or not gs.crime_contract_engine.has_method("normalize_crime_event")
		or not gs.case_orchestrator.has_method("register_crime_event")
	):
		return {"success": false, "reason": "justice_pipeline_unavailable"}

	var offender_id: int = int(organization.get("leader_id", -1))
	var crime_event: Dictionary = gs.crime_contract_engine.normalize_crime_event({
		"crime_event_id": "crime_world_%s" % str(extortion_case.get("case_id", "")),
		"actor_id": offender_id,
		"victim_id": int(actor.id),
		"crime_name": "Protection Extortion",
		"crime_type": "extortion",
		"severity": 58,
		"intent": "financial_coercion",
		"victim_reported": true,
		"discovered": true,
		"witness_ids": [int(actor.id)],
		"base_sentence_years": 5,
		"violent": false,
		"charges": ["extortion", "criminal conspiracy"]
	})
	return gs.case_orchestrator.register_crime_event(crime_event, {
		"discovered": true,
		"victim_reported": true,
		"witness_ids": [int(actor.id)],
		"source": "crime_world_engine"
	})


func _extortion_target_for_actor(actor: Person) -> Dictionary:
	if actor == null:
		return {}
	if gs != null and gs.property_engine != null:
		var properties: Dictionary = _safe_dictionary(gs.property_engine.properties)
		var owned: Array = _safe_array(properties.get(int(actor.id), []))
		if not owned.is_empty():
			var property: Dictionary = _safe_dictionary(owned[0])
			var label: String = str(
				property.get(
					"nickname",
					property.get("display_name", property.get("type", "your property"))
				)
			).strip_edges()
			if label == "":
				label = "your property"
			return {
				"kind": "property",
				"asset_id": int(property.get("id", -1)),
				"label": label,
				"value": float(property.get(
					"value",
					property.get("price", property.get("purchase_price", 0.0))
				))
			}

	var job_text: String = str(actor.job).strip_edges().to_lower()
	for raw_term in _safe_array(
		_safe_dictionary(content.get("extortion", {})).get("eligible_job_terms", [])
	):
		if job_text.find(str(raw_term).to_lower()) != -1:
			return {
				"kind": "business_role",
				"asset_id": -1,
				"label": "your %s operation" % str(actor.job),
				"value": maxf(50000.0, float(actor.bank_balance) * 1.5)
			}
	return {}


func _extorting_organization(state: Dictionary, excluded_id: String) -> Dictionary:
	var organizations: Dictionary = _safe_dictionary(state.get("organizations", {}))
	var active_ids: Array = _safe_array(
		_safe_dictionary(state.get("organization_ids_by_era", {})).get(
			_current_era_name(),
			[]
		)
	)
	for raw_id in active_ids:
		var organization_id: String = str(raw_id)
		if organization_id == excluded_id:
			continue
		var organization: Dictionary = _safe_dictionary(
			organizations.get(organization_id, {})
		)
		if not organization.is_empty():
			return organization
	return {}


func _active_extortion_for_actor(state: Dictionary, actor_id: int) -> Dictionary:
	var cases: Dictionary = _safe_dictionary(state.get("extortion_cases", {}))
	for raw_case_id in cases.keys():
		var extortion_case: Dictionary = _safe_dictionary(cases.get(raw_case_id, {}))
		if int(extortion_case.get("actor_id", -1)) != actor_id:
			continue
		if str(extortion_case.get("status", "")) in [
			"demanded",
			"negotiated",
			"active",
			"refused",
			"reported",
			"secured"
		]:
			return extortion_case.duplicate(true)
	return {}


func _ensure_state() -> Dictionary:
	if gs == null:
		return _default_state()
	if typeof(gs.scenario_state) != TYPE_DICTIONARY:
		gs.scenario_state = {}
	var raw_state: Variant = gs.scenario_state.get(STATE_KEY, {})
	var state: Dictionary = (
		(raw_state as Dictionary).duplicate(true)
		if typeof(raw_state) == TYPE_DICTIONARY
		else {}
	)
	if state.is_empty():
		state = _default_state()
	state["schema"] = CONTRACT_SCHEMA
	state["version"] = CONTRACT_VERSION
	state["organizations"] = _safe_dictionary(state.get("organizations", {}))
	state["organization_ids_by_era"] = _safe_dictionary(
		state.get("organization_ids_by_era", {})
	)
	state["actor_profiles"] = _safe_dictionary(state.get("actor_profiles", {}))
	state["extortion_cases"] = _safe_dictionary(state.get("extortion_cases", {}))
	state["event_history"] = _safe_array(state.get("event_history", []))
	gs.scenario_state[STATE_KEY] = state.duplicate(true)
	return state


func _default_state() -> Dictionary:
	return {
		"schema": CONTRACT_SCHEMA,
		"version": CONTRACT_VERSION,
		"organizations": {},
		"organization_ids_by_era": {},
		"actor_profiles": {},
		"extortion_cases": {},
		"event_history": [],
		"created_year": _current_year()
	}


func _commit_state(state: Dictionary) -> void:
	if gs == null:
		return
	if typeof(gs.scenario_state) != TYPE_DICTIONARY:
		gs.scenario_state = {}
	var existing: Dictionary = _safe_dictionary(gs.scenario_state.get(STATE_KEY, {}))
	var existing_history: Array = _safe_array(existing.get("event_history", []))
	var incoming_history: Array = _safe_array(state.get("event_history", []))
	if existing_history.size() > incoming_history.size():
		state["event_history"] = existing_history.duplicate(true)
	gs.scenario_state[STATE_KEY] = state.duplicate(true)


func _ensure_actor_profile_in_state(
	state: Dictionary,
	actor: Person
) -> Dictionary:
	var profiles: Dictionary = _safe_dictionary(state.get("actor_profiles", {}))
	var key: String = str(int(actor.id))
	var profile: Dictionary = _safe_dictionary(profiles.get(key, {}))
	if profile.is_empty():
		profile = {
			"schema": "eralife.crime_world_actor_profile",
			"version": CONTRACT_VERSION,
			"actor_id": int(actor.id),
			"organization_id": "",
			"connected_organization_id": "",
			"rank_id": "outsider",
			"underworld_reputation": 0,
			"fear": 0,
			"heat": 0,
			"loyalty": 50,
			"successful_jobs": 0,
			"failed_jobs": 0,
			"created_year": _current_year()
		}
	profiles[key] = profile
	state["actor_profiles"] = profiles
	return profile


func _upsert_organization_member(
	organization: Dictionary,
	npc_id: int,
	role: String,
	loyalty: int
) -> void:
	var members: Dictionary = _safe_dictionary(organization.get("members", {}))
	var member: Dictionary = _safe_dictionary(members.get(str(npc_id), {}))
	member["npc_id"] = npc_id
	member["role"] = role
	member["loyalty"] = clampi(loyalty, 0, 100)
	member["active"] = true
	member["joined_year"] = int(member.get("joined_year", _current_year()))
	members[str(npc_id)] = member
	organization["members"] = members


func _demote_existing_boss(organization: Dictionary, new_boss_id: int) -> void:
	var members: Dictionary = _safe_dictionary(organization.get("members", {}))
	for raw_member_key in members.keys():
		var member: Dictionary = _safe_dictionary(members.get(raw_member_key, {}))
		if int(member.get("npc_id", -1)) == new_boss_id:
			continue
		if str(member.get("role", "")) == "boss":
			member["role"] = "consigliere"
			members[raw_member_key] = member
	organization["members"] = members


func _organization_cohesion(organization: Dictionary) -> float:
	var members: Dictionary = _safe_dictionary(organization.get("members", {}))
	if members.is_empty():
		return 0.0
	var total: float = 0.0
	for raw_member_key in members.keys():
		total += float(_safe_dictionary(members.get(raw_member_key, {})).get("loyalty", 50))
	return clampf(total / float(members.size()), 0.0, 100.0)


func _add_organization_resource(
	organization: Dictionary,
	resource_id: String,
	amount: float
) -> void:
	var resources: Dictionary = _safe_dictionary(
		organization.get("resource_ledger", {})
	)
	resources[resource_id] = maxf(
		0.0,
		float(resources.get(resource_id, 0.0)) + amount
	)
	organization["resource_ledger"] = resources


func _promotion_requirement_text(profile: Dictionary) -> String:
	var next_rank: Dictionary = _next_rank_contract(str(profile.get("rank_id", "outsider")))
	if next_rank.is_empty():
		return "You control the organization."
	return "%s requires %d reputation and %d successful jobs." % [
		str(next_rank.get("label", "Next rank")),
		int(next_rank.get("reputation", 0)),
		int(next_rank.get("successful_jobs", 0))
	]


func _next_rank_contract(rank_id: String) -> Dictionary:
	var ranks: Array = _safe_array(content.get("ranks", []))
	var index: int = _rank_index(rank_id)
	if index < 0 or index + 1 >= ranks.size():
		return {}
	return _safe_dictionary(ranks[index + 1]).duplicate(true)


func _rank_index(rank_id: String) -> int:
	var ranks: Array = _safe_array(content.get("ranks", []))
	for index in range(ranks.size()):
		if str(_safe_dictionary(ranks[index]).get("id", "")) == rank_id:
			return index
	return 0


func _rank_label(rank_id: String) -> String:
	for raw_rank in _safe_array(content.get("ranks", [])):
		var rank: Dictionary = _safe_dictionary(raw_rank)
		if str(rank.get("id", "")) == rank_id:
			return str(rank.get("label", rank_id.capitalize()))
	return rank_id.capitalize()


func _job_by_id(job_id: String) -> Dictionary:
	for raw_job in _safe_array(content.get("jobs", [])):
		var job: Dictionary = _safe_dictionary(raw_job)
		if str(job.get("id", "")) == job_id:
			return job.duplicate(true)
	return {}


func _best_available_job(profile: Dictionary) -> Dictionary:
	var current_index: int = _rank_index(str(profile.get("rank_id", "outsider")))
	var best: Dictionary = {}
	for raw_job in _safe_array(content.get("jobs", [])):
		var job: Dictionary = _safe_dictionary(raw_job)
		if _rank_index(str(job.get("minimum_rank", "outsider"))) <= current_index:
			best = job.duplicate(true)
	return best


func _criminal_age_gate(actor: Person) -> Dictionary:
	var minimum_age: int = int(content.get("minimum_criminal_age", 16))
	return {
		"allowed": actor != null and int(actor.age) >= minimum_age,
		"reason": "Underworld work requires age %d or older." % minimum_age
	}


func _territory_ids_for_player(organization_index: int) -> Array:
	if gs == null or gs.player == null:
		return ["world:unknown"]
	var actor: Person = gs.player
	var out: Array = []
	var district: String = str(actor.district_id).strip_edges()
	var city: String = str(
		actor.home_city if str(actor.home_city).strip_edges() != "" else actor.birth_city
	).strip_edges()
	var country: String = str(
		actor.home_country if str(actor.home_country).strip_edges() != "" else actor.birth_country
	).strip_edges()
	if district != "":
		out.append("district:%s" % _key(district))
	if city != "":
		out.append("city:%s" % _key(city))
		out.append("city:%s:sector_%d" % [_key(city), organization_index + 1])
	if country != "":
		out.append("country:%s" % _key(country))
	if out.is_empty():
		out.append("world:unknown")
	return out


func _used_organization_member_ids(organizations: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	for raw_organization_id in organizations.keys():
		var organization: Dictionary = _safe_dictionary(
			organizations.get(raw_organization_id, {})
		)
		for raw_member_id in _safe_dictionary(organization.get("members", {})).keys():
			out[str(raw_member_id)] = true
	return out


func _organization_by_id(organization_id: String) -> Dictionary:
	return _organization_by_id_from_state(_ensure_state(), organization_id)


func _organization_by_id_from_state(
	state: Dictionary,
	organization_id: String
) -> Dictionary:
	return _safe_dictionary(
		_safe_dictionary(state.get("organizations", {})).get(organization_id, {})
	).duplicate(true)


func _actor_by_id(actor_id: int):
	if gs == null or actor_id <= 0:
		return null
	if gs.has_method("get_npc_by_id"):
		return gs.get_npc_by_id(actor_id)
	for npc in gs.npcs:
		if npc != null and int(npc.id) == actor_id:
			return npc
	return null


func _credit_actor(actor: Person, amount: int, source: String) -> Dictionary:
	if amount <= 0:
		return {"success": true, "amount": 0}
	if gs != null and gs.bank_engine != null and gs.bank_engine.has_method("request_actor_bank_action"):
		return gs.bank_engine.request_actor_bank_action(actor, {
			"action": "crime_payout_cash",
			"amount": amount,
			"currency": "USD",
			"source": source,
			"text": "Underworld earnings became physical cash."
		}, {"source": source})
	actor.bank_balance += amount
	return {"success": true, "amount": amount, "mode": "legacy_bank_balance"}


func _spend_actor(actor: Person, amount: int, source: String) -> Dictionary:
	if amount <= 0:
		return {"success": true, "amount": 0}
	if gs != null and gs.bank_engine != null and gs.bank_engine.has_method("request_actor_bank_action"):
		return gs.bank_engine.request_actor_bank_action(actor, {
			"action": "spend",
			"amount": amount,
			"currency": "USD",
			"reason": source,
			"text": "A Crime World payment was made."
		}, {"source": source})
	if float(actor.bank_balance) < float(amount):
		return {"success": false, "reason": "Not enough money.", "amount": amount}
	actor.bank_balance -= amount
	return {"success": true, "amount": amount, "mode": "legacy_bank_balance"}


func _record_narrative(
	actor: Person,
	text: String,
	event_name: String,
	payload: Dictionary = {}
) -> void:
	if actor != null and text != "":
		actor.memories.append(text)
	var state: Dictionary = _ensure_state()
	var history: Array = _safe_array(state.get("event_history", []))
	var event: Dictionary = payload.duplicate(true)
	event["event_name"] = event_name
	event["text"] = text
	event["actor_id"] = int(actor.id) if actor != null else -1
	event["year"] = _current_year()
	event["created_at_ms"] = int(Time.get_ticks_msec())
	history.append(event)
	if history.size() > EVENT_HISTORY_LIMIT:
		history = history.slice(history.size() - EVENT_HISTORY_LIMIT, history.size())
	state["event_history"] = history
	_commit_state(state)

	if gs != null and gs.event_bus != null and gs.event_bus.has_method("emit"):
		gs.event_bus.emit(event_name, event.duplicate(true))
	if gs != null and gs.has_method("push_world_feed") and text != "":
		gs.push_world_feed(text, {
			"category": "crime",
			"event_name": event_name,
			"source": "crime_world_engine",
			"actor_id": event.get("actor_id", -1)
		})


func _load_content() -> void:
	if not content.is_empty():
		return
	if not FileAccess.file_exists(CONTENT_PATH):
		content = _fallback_content()
		return
	var file:= FileAccess.open(CONTENT_PATH, FileAccess.READ)
	if file == null:
		content = _fallback_content()
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	content = (
		(parsed as Dictionary).duplicate(true)
		if typeof(parsed) == TYPE_DICTIONARY
		else _fallback_content()
	)


func _fallback_content() -> Dictionary:
	return {
		"minimum_criminal_age": 16,
		"ranks": [
			{"id": "outsider", "label": "Outsider", "reputation": 0, "successful_jobs": 0},
			{"id": "connected", "label": "Connected", "reputation": 6, "successful_jobs": 1},
			{"id": "associate", "label": "Associate", "reputation": 12, "successful_jobs": 2},
			{"id": "soldier", "label": "Soldier", "reputation": 28, "successful_jobs": 5},
			{"id": "capo", "label": "Capo", "reputation": 52, "successful_jobs": 10},
			{"id": "underboss", "label": "Underboss", "reputation": 82, "successful_jobs": 17},
			{"id": "boss", "label": "Boss", "reputation": 118, "successful_jobs": 26}
		],
		"jobs": [
			{
				"id": "deliver_message",
				"label": "Deliver a Sealed Message",
				"minimum_rank": "outsider",
				"base_success": 82,
				"payout_min": 120,
				"payout_max": 420,
				"reputation_gain": 6,
				"fear_gain": 0,
				"heat_gain": 1
			}
		],
		"extortion": {
			"minimum_annual_payment": 1200,
			"maximum_annual_payment": 48000,
			"property_value_rate": 0.035,
			"security_cost_rate": 0.55,
			"yearly_offer_chance": 24,
			"retaliation_chance": 68,
			"security_retaliation_reduction": 46,
			"eligible_job_terms": ["business owner"]
		},
		"eras": {
			"Modern Era": [
				{
					"id": "moretti_family",
					"name": "Moretti Family",
					"kind": "mafia_family",
					"tags": ["crime", "mafia"],
					"wealth": 2400000,
					"power": 71,
					"fear": 69,
					"heat": 52,
					"corruption": 48
				}
			]
		}
	}


func _current_year() -> int:
	return int(gs.year) if gs != null else 0


func _current_era_name() -> String:
	if gs != null and gs.era != null:
		return str(gs.era.name)
	return "Modern Era"


func _stable_roll(key: String) -> int:
	return posmod(int(hash(key)), 100)


func _stable_amount(minimum: int, maximum: int, key: String) -> int:
	if maximum <= minimum:
		return minimum
	return minimum + posmod(int(hash(key)), maximum - minimum + 1)


func _era_key(value: String) -> String:
	return _key(value.replace(" Era", ""))


func _key(value: String) -> String:
	var out: String = str(value).strip_edges().to_lower()
	for character in [" ", "/", "\\", ":", ".", ",", "-", "'", "\""]:
		out = out.replace(character, "_")
	while out.find("__") != -1:
		out = out.replace("__", "_")
	return out.trim_prefix("_").trim_suffix("_")


func _safe_dictionary(value: Variant) -> Dictionary:
	return (value as Dictionary).duplicate(true) if typeof(value) == TYPE_DICTIONARY else {}


func _safe_array(value: Variant) -> Array:
	return (value as Array).duplicate(true) if typeof(value) == TYPE_ARRAY else []


func _finish(report: Dictionary) -> Dictionary:
	last_report = report.duplicate(true)
	return report


func _failure(reason: String, text: String) -> Dictionary:
	return _finish({
		"success": false,
		"reason": reason,
		"text": text,
		"popup_title": "Crime World",
		"popup_text": text,
		"popup_footer": "No irreversible change was made."
	})

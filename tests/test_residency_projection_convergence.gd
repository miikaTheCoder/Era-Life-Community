extends SceneTree

class StalledProjectionEngine extends RealityProjectionContractEngine:
	var step_count: int = 0

	func promote_next_hot_interactive_stage(
		_signature: String
	) -> Dictionary:
		return {
			"success": true,
			"promoted": false
		}

	func projection_status(
		_signature: String
	) -> Dictionary:
		return {
			"success": true,
			"complete": false,
			"failed": false,
			"stage_id": "relationships",
			"progress": 0.2
		}

	func interactive_projection_stage_authority_status(
		_signature: String
	) -> Dictionary:
		return {
			"success": true,
			"stage_id": "relationships",
			"authority_hot": true,
			"ready_gate_member": false
		}

	func checkpoint_resume_life_observation_pending(
		_signature: String
	) -> bool:
		return false

	func step_resident_projection(
		_signature: String,
		_max_steps: int = 1,
		_frame_budget_ms: int = 2
	) -> Dictionary:
		step_count += 1
		return projection_status(_signature)

	func interactive_surface_packets_ready(
		_signature: String
	) -> bool:
		return false

class PumpProbeHub extends RelationshipsHubContractEngine:
	var flush_count: int = 0

	func flush_switch_shell_stage_queue(
		max_count: int = 1,
		_context: Dictionary = {}
	) -> Dictionary:
		flush_count += 1
		var processed: int = 0

		while (
			processed < maxi(1, max_count)
			and not switch_shell_stage_queue.is_empty()
		):
			var row: Dictionary = switch_shell_stage_queue.pop_front()
			switch_shell_stage_seen.erase(
				int(row.get("target_id", -1))
			)
			processed += 1

		return {
			"success": true,
			"processed": processed,
			"staged": processed,
			"requeued": 0,
			"remaining": switch_shell_stage_queue.size(),
			"staged_packets_by_actor": {},
			"failures": [],
			"ready_gate_member": false
		}

var failures: Array[String] = []

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)

func _initialize() -> void:
	call_deferred("_run")

func _completed_relationship_work(actor_id: int) -> Dictionary:
	return {
		"signature": "relationship-ready",
		"actor_id": actor_id,
		"active_section_id": "family",
		"tabs": [],
		"section_contracts": {
			"family": {
				"success": true,
				"actor_id": actor_id,
				"active_section_id": "family",
				"groups": [],
				"projection_complete": true,
				"section_projection_complete": true,
				"ready_gate_member": false
			}
		},
		"section_groups": {},
		"section_cursor": 0,
		"group_cursor": 0,
		"projection_context": {},
		"climate": {},
		"complete": false,
		"failed": false
	}

func _run() -> void:
	var runtime := GameState.new()
	var actor := Person.new()
	actor.id = 71
	runtime.player = actor
	runtime.player_id = actor.id
	runtime.npcs = [actor]
	runtime._rebuild_npc_index()

	# Relationship cards are the projection authority. Pointer-core and full
	# switch-deck enrichment remain visible in diagnostics but cannot hold it.
	var hub := RelationshipsHubContractEngine.new(runtime)
	hub.resident_projection_work_by_signature [
		"relationship-ready"
	] = _completed_relationship_work(actor.id)
	hub.switch_shell_stage_queue = [
		{
			"target_id": actor.id,
			"next_allowed_at_ms": int(Time.get_ticks_msec()) + 1000,
			"ready_gate_member": false
		}
	]
	hub.switch_destination_upgrade_queue = [
		{
			"target_id": actor.id,
			"next_allowed_at_ms": int(Time.get_ticks_msec()) + 1000,
			"ready_gate_member": false
		}
	]
	var relationship_projection: Dictionary = (
		hub._step_resident_hub_projection(
			actor,
			"family",
			"relationship-ready",
			{}
		)
	)
	_check(
		bool(relationship_projection.get("projection_complete", false)),
		"Non-gating switch queues kept a complete relationship surface pending"
	)
	_check(
		bool(
			relationship_projection.get(
				"relationship_authority_lane_complete",
				false
			)
		),
		"Relationship surface did not retain completion authority"
	)
	_check(
		not bool(
			relationship_projection.get(
				"switch_shell_background_complete",
				true
			)
		),
		"Projection diagnostics hid pending switch-shell enrichment"
	)
	_check(
		not bool(
			relationship_projection.get(
				"switch_destination_upgrade_complete",
				true
			)
		),
		"Projection diagnostics hid pending destination enrichment"
	)
	_check(
		not hub.resident_projection_work_by_signature.has(
			"relationship-ready"
		),
		"Completed relationship work remained resident because of background queues"
	)
	_check(
		hub.switch_shell_stage_pump_armed,
		"Pending switch-shell enrichment was not transferred to its own pump"
	)
	_check(
		hub.switch_destination_upgrade_pump_armed,
		"Pending destination enrichment was not transferred to its own pump"
	)

	# A permanently unchanged switch-shell row is discarded from the background
	# cache after a generous retry budget; it never changes surface readiness.
	var retry_row: Dictionary = {
		"target_id": actor.id,
		"ready_gate_member": false
	}
	var retry_report: Dictionary = {}
	hub.switch_shell_stage_seen [actor.id] = true
	for attempt_index in range(
		RelationshipsHubContractEngine.MAX_SWITCH_SHELL_STAGE_STAGNANT_ATTEMPTS + 1
	):
		retry_report = (
			hub._advance_switch_shell_background_retry_budget(
				retry_row,
				actor.id,
				"resident_interactive_projection_pending",
				{
					"projection_stage_id": "relationships",
					"projection_progress": 0.2
				}
			)
		)

		if (
			attempt_index
			< RelationshipsHubContractEngine.MAX_SWITCH_SHELL_STAGE_STAGNANT_ATTEMPTS
		):
			_check(
				not bool(retry_report.get("exhausted", false)),
				"Switch-shell retry budget exhausted before its documented cap"
			)
	_check(
		bool(retry_report.get("exhausted", false)),
		"A stagnant switch-shell background row can retry forever"
	)
	_check(
		not hub.switch_shell_stage_seen.has(actor.id),
		"An exhausted switch-shell row remained marked as queued"
	)
	_check(
		bool(
			runtime.scenario_state.get(
				"relationship_surface_authority_preserved",
				false
			)
		),
		"Switch-shell exhaustion did not preserve relationship surface authority"
	)

	var destination_retry_row: Dictionary = {
		"target_id": actor.id,
		"ready_gate_member": false
	}
	var destination_retry_report: Dictionary = {}
	hub.switch_destination_upgrade_seen [actor.id] = true
	for _attempt_index in range(
		RelationshipsHubContractEngine.MAX_SWITCH_DESTINATION_UPGRADE_STAGNANT_ATTEMPTS + 1
	):
		destination_retry_report = (
			hub._advance_switch_destination_upgrade_retry_budget(
				destination_retry_row,
				actor.id,
				"profile_switch_actor_destination_deck_pending",
				{
					"projection_stage_id": "relationships",
					"projection_progress": 0.2
				}
			)
		)
	_check(
		bool(destination_retry_report.get("exhausted", false)),
		"A stagnant destination-upgrade background row can retry forever"
	)
	_check(
		not hub.switch_destination_upgrade_seen.has(actor.id),
		"An exhausted destination-upgrade row remained marked as queued"
	)

	# Arming is idempotent and each callback owns exactly one queue quantum.
	var pump_probe := PumpProbeHub.new(runtime)
	pump_probe.switch_shell_stage_queue = [
		{"target_id": actor.id, "ready_gate_member": false},
		{"target_id": actor.id + 1, "ready_gate_member": false}
	]
	pump_probe._arm_switch_shell_stage_pump()
	var first_pump_generation: int = (
		pump_probe.switch_shell_stage_pump_generation
	)
	pump_probe._arm_switch_shell_stage_pump()
	_check(
		pump_probe.switch_shell_stage_pump_generation
		== first_pump_generation,
		"Repeated pump arming scheduled a duplicate callback"
	)
	pump_probe._switch_shell_stage_pump_frame(
		first_pump_generation
	)
	_check(
		pump_probe.flush_count == 1
		and pump_probe.switch_shell_stage_queue.size() == 1,
		"One switch-shell pump callback consumed more than one quantum"
	)
	_check(
		pump_probe.switch_shell_stage_pump_armed,
		"A remaining switch-shell row did not re-arm the background pump"
	)
	pump_probe._switch_shell_stage_pump_frame(
		pump_probe.switch_shell_stage_pump_generation
	)
	_check(
		pump_probe.flush_count == 2
		and pump_probe.switch_shell_stage_queue.is_empty(),
		"Independent switch-shell callbacks did not converge the queue"
	)
	_check(
		not pump_probe.switch_shell_stage_pump_armed,
		"An empty switch-shell queue left its pump armed"
	)

	# The attached/interactive helper used to return before the tail counter. A
	# stuck projection must now terminate through the same bounded authority and
	# must not claim that missing surface packets are complete.
	var stalled_projection := StalledProjectionEngine.new(runtime)
	var residency := RealityResidencyManager.new(
		runtime,
		null,
		stalled_projection
	)
	stalled_projection.projection_work_by_signature ["step-cap"] = {
		"active_surface_progress": 0.2,
		"active_surface_status": {
			"stream_section_id": "family",
			"projected_group_count": 1,
			"stream_group_cursor": 1
		}
	}
	var capped_record: Dictionary = {
		"runtime_ref": runtime,
		"projection_started": true,
		"projection_tail_pending": true,
		"projection_surface_packets_complete": false,
		"projection_tail_step_count": (
			RealityResidencyManager.MAX_PROJECTION_TAIL_STEPS - 1
		)
	}
	residency.resident_records ["step-cap"] = capped_record
	var capped_report: Dictionary = (
		residency._service_checkpoint_interactive_projection_lane(
			"step-cap",
			capped_record,
			runtime,
			true,
			1
		)
	)
	var capped_result: Dictionary = (
		residency.resident_records ["step-cap"]
	)
	_check(
		bool(capped_result.get("projection_tail_failed", false)),
		"Interactive projection bypassed the shared step cap"
	)
	_check(
		bool(capped_report.get("background_tail_degraded", false)),
		"Interactive cap did not report background-tail degradation"
	)
	_check(
		str(capped_result.get("projection_tail_failure_scope", ""))
		== "background_only",
		"Projection exhaustion escaped the background-tail scope"
	)
	_check(
		not bool(
			capped_result.get(
				"projection_surface_packets_complete",
				true
			)
		),
		"Projection exhaustion fabricated interactive surface readiness"
	)
	_check(
		bool(capped_result.get("ready_state_preserved", false)),
		"Projection exhaustion did not preserve the already-ready life"
	)

	# A stable outer stage with no inner surface progress has a lower stagnation
	# ceiling even when the broad total-step budget is not yet exhausted.
	stalled_projection.projection_work_by_signature ["stagnation-cap"] = (
		stalled_projection.projection_work_by_signature ["step-cap"].duplicate(true)
	)
	var stagnant_status: Dictionary = (
		stalled_projection.projection_status("stagnation-cap")
	)
	var stagnant_record: Dictionary = {
		"runtime_ref": runtime,
		"projection_started": true,
		"projection_tail_pending": true,
		"projection_surface_packets_complete": false,
		"projection_tail_step_count": 0,
		"projection_tail_stagnant_step_count": (
			RealityResidencyManager.MAX_PROJECTION_TAIL_STAGNANT_STEPS - 1
		),
		"projection_tail_progress_token": (
			residency._projection_tail_progress_token(
				"stagnation-cap",
				stagnant_status
			)
		)
	}
	residency.resident_records ["stagnation-cap"] = stagnant_record
	residency._service_checkpoint_interactive_projection_lane(
		"stagnation-cap",
		stagnant_record,
		runtime,
		true,
		1
	)
	var stagnant_result: Dictionary = (
		residency.resident_records ["stagnation-cap"]
	)
	_check(
		str(stagnant_result.get("projection_tail_failure_reason", ""))
		== "projection_tail_stagnation_budget_exhausted",
		"A stagnant interactive projection did not use the stagnation cap"
	)

	print(
		"RESIDENCY PROJECTION CONVERGENCE TESTS: ",
		"PASS" if failures.is_empty() else "FAIL"
	)
	quit(0 if failures.is_empty() else 1)

extends SceneTree

class DeferredSink:
	extends RefCounted

	var received_sequences: Array[int] = []

	func capture(payload: Dictionary) -> void:
		received_sequences.append(
			int(payload.get("sequence", -1))
		)


var failed: bool = false


func _check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		push_error(message)


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var state := GameState.new()
	state.year = 2001
	state.scenario_state = {
		"runtime_guard": {
			"defer_noncritical_systems": true,
			"current_phase": "core_state_resolution",
		}
	}

	var bus := EventBus.new(state)
	var sink := DeferredSink.new()

	# A delivery recorded during the engine's first millisecond has timestamp zero.
	# Presence in the duplicate window, rather than a positive timestamp, defines
	# whether that first delivery can suppress an immediate duplicate.
	var tick_zero_event := "test.deferred.tick-zero-duplicate"
	var tick_zero_payload := {
		"year": state.year,
		"text": "tick-zero-duplicate",
	}
	var tick_zero_contract := {
		"suppress_duplicates": true,
		"duplicate_ttl_ms": 1000000,
	}
	var first_duplicate_report: Dictionary = (
		bus.contract_layer._check_duplicate(
			tick_zero_event,
			tick_zero_payload,
			tick_zero_contract
		)
	)
	_check(
		not bool(first_duplicate_report.get("duplicate", true)),
		"The first duplicate-window entry was rejected"
	)
	var tick_zero_signature: String = (
		bus.contract_layer._build_duplicate_signature(
			tick_zero_event,
			tick_zero_payload,
			tick_zero_contract
		)
	)
	bus.contract_layer.duplicate_window[tick_zero_signature] = 0
	var tick_zero_duplicate_report: Dictionary = (
		bus.contract_layer._check_duplicate(
			tick_zero_event,
			tick_zero_payload,
			tick_zero_contract
		)
	)
	_check(
		bool(tick_zero_duplicate_report.get("duplicate", false)),
		"A duplicate recorded at engine tick zero was not suppressed"
	)

	bus.subscribe(
		"test.deferred.backlog",
		sink,
		"capture",
		{"allow_defer": true}
	)

	for sequence in range(7):
		bus.emit(
			"test.deferred.backlog",
			{
				"sequence": sequence,
				"text": "deferred-%d" % sequence,
				"event_batch_key": "deferred-test-%d" % sequence,
				"fanout_hints": {
					"event_batch_key": "deferred-test-%d" % sequence,
					"force_defer_bus": true,
				},
			}
		)

	_check(
		bus.get_pending_deferred_delivery_count() == 7,
		"Deferred setup did not retain every handler"
	)
	_check(
		bus._deferred_delivery_service_armed,
		"Deferred process-frame service was not armed"
	)

	# Age-up and UI tails explicitly request small drains while the automatic
	# process-frame service is armed. Those calls must still make bounded
	# progress instead of leaving the entire annual fanout to one callback.
	bus.flush_deferred(3, false)
	var bounded_delivery_count: int = sink.received_sequences.size()
	_check(
		bounded_delivery_count > 0 and bounded_delivery_count <= 3,
		"An explicit bounded drain made no progress or exceeded max_handlers"
	)
	var expected_bounded_prefix: Array[int] = []
	for sequence in range(bounded_delivery_count):
		expected_bounded_prefix.append(sequence)
	_check(
		sink.received_sequences == expected_bounded_prefix,
		"An explicit bounded drain did not preserve its FIFO prefix"
	)
	_check(
		bus.get_pending_deferred_delivery_count()
		== 7 - bounded_delivery_count,
		"The bounded drain consumed an unexpected number of handlers"
	)

	var bounded_completion_passes: int = 0
	while (
		bus.has_pending_deferred_deliveries()
		and bounded_completion_passes < 16
	):
		bus.flush_deferred(64, false)
		bounded_completion_passes += 1
	_check(
		sink.received_sequences == [0, 1, 2, 3, 4, 5, 6],
		"Deferred handler order or delivery completeness changed"
	)
	_check(
		bus.get_pending_deferred_delivery_count() == 0,
		"Deferred queue did not settle after the remaining bounded drain"
	)

	for sequence in range(7):
		var receipt: Dictionary = bus.get_deferred_batch_receipt(
			"deferred-test-%d" % sequence
		)
		_check(
			bool(receipt.get("is_complete", false)),
			"Deferred batch receipt did not complete for sequence %d" % sequence
		)
		_check(
			int(receipt.get("delivered_handlers", 0)) == 1,
			"Deferred batch delivery was lost for sequence %d" % sequence
		)

	var pressure_bus := EventBus.new(state)
	var pressure_sink := DeferredSink.new()
	pressure_bus.subscribe(
		"test.deferred.annual-pressure",
		pressure_sink,
		"capture",
		{"allow_defer": true}
	)

	for sequence in range(100):
		pressure_bus.emit(
			"test.deferred.annual-pressure",
			{
				"sequence": sequence,
				"text": "annual-deferred-%d" % sequence,
				"fanout_hints": {"force_defer_bus": true},
			}
		)

	pressure_bus._service_deferred_delivery_quantum()
	var pressure_quantum_count: int = (
		pressure_sink.received_sequences.size()
	)
	_check(
		pressure_quantum_count > 1,
		"The process-frame service still drains only one annual handler"
	)
	_check(
		pressure_quantum_count
		<= EventBus._DEFERRED_SERVICE_PRESSURE_HANDLERS_PER_FRAME,
		"The process-frame service exceeded its handler budget"
	)
	_check(
		pressure_bus.get_pending_deferred_delivery_count()
		== 100 - pressure_quantum_count,
		"The pressure quantum lost or duplicated queued handlers"
	)

	var drain_passes: int = 0
	while (
		pressure_bus.has_pending_deferred_deliveries()
		and drain_passes < 100
	):
		pressure_bus.flush_deferred(64, false)
		drain_passes += 1

	var expected_sequences: Array[int] = []
	for sequence in range(100):
		expected_sequences.append(sequence)

	_check(
		pressure_sink.received_sequences == expected_sequences,
		"Annual-pressure draining lost, duplicated, or reordered an event"
	)
	_check(
		not pressure_bus.has_pending_deferred_deliveries(),
		"Annual-pressure queue could not settle through bounded drains"
	)

	var forced_bus := EventBus.new(state)
	var forced_sink := DeferredSink.new()
	forced_bus.subscribe(
		"test.deferred.force-all",
		forced_sink,
		"capture",
		{"allow_defer": true}
	)
	for sequence in range(100):
		forced_bus.emit(
			"test.deferred.force-all",
			{
				"sequence": sequence,
				"event_batch_key": "force-all-test-%d" % sequence,
				"fanout_hints": {
					"event_batch_key": "force-all-test-%d" % sequence,
					"force_defer_bus": true,
				},
			}
		)
	var force_all_pending_before: int = (
		forced_bus.get_pending_deferred_delivery_count()
	)
	_check(
		force_all_pending_before == 100,
		"Force-all fixture did not enqueue 100 distinct entry-time deliveries"
	)
	forced_bus.flush_deferred(1, true)
	_check(
		forced_sink.received_sequences == [0]
		and forced_bus.get_pending_deferred_delivery_count() == 99,
		"An explicit force flush ignored its max_handlers cap"
	)
	forced_bus.flush_deferred(-1, true)
	_check(
		forced_sink.received_sequences == expected_sequences,
		(
			"Force-all draining did not preserve the complete entry queue order: "
			+ "received=%s expected=%s pending_before=%d pending_after=%d"
			% [
				str(forced_sink.received_sequences),
				str(expected_sequences),
				force_all_pending_before,
				forced_bus.get_pending_deferred_delivery_count(),
			]
		)
	)
	_check(
		not forced_bus.has_pending_deferred_deliveries(),
		"Force-all draining left entry-time deliveries pending"
	)

	print("EVENT BUS DEFERRED TESTS: ", "FAIL" if failed else "PASS")
	quit(1 if failed else 0)

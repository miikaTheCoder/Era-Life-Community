extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var updater := root.get_node_or_null("ReleaseUpdateRuntimeLayer")
	if updater == null:
		push_error("Release updater autoload is missing")
		quit(1)
		return
	# Cross the original 2.5-second startup grace period in the real scene tree.
	# The community desktop must never create upstream HTTP requests.
	await create_timer(3.1).timeout
	if updater.is_processing() or updater.get_child_count() != 0:
		push_error("Community desktop activated the upstream update channel")
		quit(1)
		return
	if updater.get("last_release_update_report").get("stage") != "disabled_for_community_desktop":
		push_error("Disabled update channel has no diagnostic report")
		quit(1)
		return
	print("RELEASE CHANNEL TEST: PASS")
	quit(0)

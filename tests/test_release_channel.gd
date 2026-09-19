extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var updater := root.get_node_or_null("ReleaseUpdateRuntimeLayer")
	if updater == null:
		push_error("Release updater autoload is missing")
		quit(1)
		return
	if bool(ProjectSettings.get_setting("community/updates/allow_upstream_runtime.android", true)):
		push_error("Portrait Android app must not join the upstream update channel")
		quit(1)
		return
	# Cross the original 2.5-second startup grace period in the real scene tree.
	# Neither community desktop nor the portrait app may make upstream requests.
	await create_timer(3.1).timeout
	if updater.is_processing() or updater.get_child_count() != 0:
		push_error("Community fork activated the upstream update channel")
		quit(1)
		return
	var expected_stage := "disabled_for_community_portrait" if OS.has_feature("android") else "disabled_for_community_desktop"
	if updater.get("last_release_update_report").get("stage") != expected_stage:
		push_error("Disabled update channel has no diagnostic report")
		quit(1)
		return
	print("RELEASE CHANNEL TEST: PASS")
	quit(0)

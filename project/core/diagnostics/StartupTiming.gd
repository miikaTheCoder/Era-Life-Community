extends RefCounted
class_name StartupTiming

## Process-relative milestones, not Android launcher-to-first-frame timing.
## No gameplay references: the early menu must not pull in domain scripts.
static var stages: Dictionary = {}
static var previous_ms := 0

static func mark(stage: String, details: Dictionary = {}) -> void:
	if stages.has(stage):
		return
	var now := Time.get_ticks_msec()
	var row := details.duplicate()
	row["stage"] = stage
	row["at_ms"] = now
	row["since_previous_ms"] = now - previous_ms
	row["static_memory_bytes"] = OS.get_static_memory_usage()
	stages[stage] = row
	previous_ms = now
	if OS.has_feature("android") or "--startup-profile" in OS.get_cmdline_user_args():
		print("ERALIFE_STARTUP|", JSON.stringify(row))

extends RefCounted
class_name FamilyChronicleContractEngine

## Read-only projections of the existing story authority. No second history store.
const MAX_ENTRIES := 200

static func signature(state) -> String:
	var parts: Array = [state.get_instance_id(), state.player.id, state.year]
	var profiles: Dictionary = state.scenario_state.get("life_stories", {}).get("actors", {})
	for id in [state.player.id] + state.player.parents.slice(0, 2):
		var records: Dictionary = profiles.get(str(int(id)), {}).get("stories", {})
		for story_id in records:
			var record: Dictionary = records[story_id]
			parts.append([id, story_id, record.get("history", []).size(), record.get("status", ""), record.get("legacy", "")])
	return str(parts.hash())

static func build(state, catalog: Array = []) -> Dictionary:
	var result := {"title": "Family chronicle", "person": "", "entries": [], "recap": "", "truncated": false}
	if state == null or state.player == null:
		return result
	var actor: Person = state.player
	result.person = (actor.first_name + " " + actor.last_name).strip_edges()
	var definitions := {}
	for story in catalog:
		definitions[str(story.id)] = story
	var profiles: Dictionary = state.scenario_state.get("life_stories", {}).get("actors", {})
	var records: Dictionary = profiles.get(str(actor.id), {}).get("stories", {})
	var entries: Array = []
	for id in records:
		var record: Dictionary = records[id]
		var title := _title(str(id), record, definitions)
		for index in range(record.get("history", []).size()):
			var event: Dictionary = record.history[index]
			entries.append({"year": int(event.get("year", 0)), "title": title,
				"text": str(event.get("text", "")), "person": result.person,
				"cast": str(record.get("cast_name", "")), "inherited": false,
				"key": str(actor.id) + ":" + str(id) + ":" + str(index)})
		if str(record.get("status", "")) == "finished":
			entries.append({"year": int(record.get("finished_year", record.get("started_year", 0))),
				"title": title, "text": "Outcome: " + str(record.get("outcome", "A chapter closed")),
				"person": result.person, "cast": str(record.get("cast_name", "")),
				"inherited": false, "key": str(actor.id) + ":" + str(id) + ":outcome"})
	# Only completed public outcomes cross generations, never a parent's private
	# reflections or unfinished choices. Resolve at most two known parents.
	var parents: Array = actor.parents.slice(0, 2)
	for parent_id in parents:
		var parent_records: Dictionary = profiles.get(str(int(parent_id)), {}).get("stories", {})
		var parent = state.get_npc_by_id(int(parent_id), false)
		for id in parent_records:
			var record: Dictionary = parent_records[id]
			if str(record.get("status", "")) != "finished" or str(record.get("legacy", "unfinished")) in ["private", "unfinished"]:
				continue
			var name := str(record.get("actor_name", "Your parent"))
			if parent != null:
				name = (parent.first_name + " " + parent.last_name).strip_edges()
			entries.append({"year": int(record.get("finished_year", record.get("started_year", 0))),
				"title": _title(str(id), record, definitions), "text": str(record.get("outcome", "A remembered choice")),
				"person": name, "cast": str(record.get("cast_name", "")), "inherited": true,
				"key": str(parent_id) + ":" + str(id) + ":inherited"})
	entries.sort_custom(func(a, b):
		if int(a.year) == int(b.year):
			return str(a.key) < str(b.key)
		return int(a.year) > int(b.year))
	result.truncated = entries.size() > MAX_ENTRIES
	result.entries = entries.slice(0, MAX_ENTRIES)
	var recent: Array = []
	for entry in result.entries:
		if recent.size() == 2:
			break
		recent.append("%d: %s%s" % [entry.year, (str(entry.person) + " left: ") if entry.inherited else "", entry.text])
	result.recap = "\n".join(recent) if not recent.is_empty() else "Your choices will appear here as your life unfolds."
	return result

static func _title(id: String, record: Dictionary, definitions: Dictionary) -> String:
	return str(record.get("story_title", definitions.get(id, {}).get("title", id.replace("_", " ").replace(".", " / ").capitalize())))

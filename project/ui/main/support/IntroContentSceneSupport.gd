extends RefCounted
class_name IntroContentSceneSupport
## IntroContent support for the main scene. State, when needed, is passed explicitly.


static func _startup_intro_sequence_signature(sequence: Array) -> String:
	var parts: Array = []
	var limit_count: int = min(sequence.size(), 64)

	for i in range(limit_count):
		var raw_beat: Variant = sequence [i]
		if typeof(raw_beat) != TYPE_DICTIONARY:
			continue

		var beat: Dictionary = raw_beat as Dictionary
		var year_text: String = str(beat.get("year", "")).strip_edges()
		var line_text: String = str(beat.get("line", "")).strip_edges()
		if year_text == "" and line_text == "":
			continue

		parts.append("%s::%s" % [year_text, line_text])

	var signature: String = ""
	for raw_part in parts:
		var part: String = str(raw_part)
		if signature != "":
			signature += "|"
		signature += part

	return signature


static func _startup_intro_procedural_content_contract() -> Dictionary:
	return {
		"schema": "eralife.procedural_cinematic_sequence_contract",
		"version": 1,
		"sequence_count": 14,
		"bridge_count": 34,
		"pool_rotation": [
			"royal_bloodlines",
			"artifact_discoveries",
			"wars_and_crowns",
			"ordinary_lives",
			"crime_and_celebrity",
			"realm_anomalies",
			"future_legends"
		],
		"pools": {
			"royal_bloodlines": [
				{ "year": -30, "era": "ancient", "line": "A prodigy was born as Crowned Prince."},
				{ "year": -12, "era": "ancient", "line": "A queen hid an heir beneath a palace chapel."},
				{ "year": 41, "era": "ancient", "line": "A royal infant survived a poisoned feast."},
				{ "year": 210, "era": "ancient", "line": "A prince inherited a throne nobody believed he could hold."},
				{ "year": 476, "era": "medieval", "line": "A fallen dynasty buried its last crown in silence."},
				{ "year": 611, "era": "medieval", "line": "A child of two kingdoms was promised to a war."},
				{ "year": 742, "era": "medieval", "line": "A royal bloodline awakened with a name no historian trusted."},
				{ "year": 1204, "era": "medieval", "line": "A royal house broke quietly behind golden doors."},
				{ "year": 1492, "era": "medieval", "line": "A voyage redrew inheritance, land, and destiny."},
				{ "year": 1847, "era": "industrial", "line": "A family built a name from hunger, debt, and stubborn breath."},
				{ "year": 1914, "era": "industrial", "line": "A noble son marched away and returned as a story."},
				{ "year": 2026, "era": "modern", "line": "A celebrity bloodline collapsed on live television."},
				{ "year": 2148, "era": "future", "line": "Two royal timelines folded into one heir."},
				{ "year": 3022, "era": "future", "line": "A crown was inherited by code."}
			],
			"artifact_discoveries": [
				{ "year": -300, "era": "ancient", "line": "A temple opened around a stone that hummed like time."},
				{ "year": -44, "era": "ancient", "line": "A blade carried a prophecy through a senate hall."},
				{ "year": 33, "era": "ancient", "line": "A relic vanished the moment history tried to name it."},
				{ "year": 210, "era": "ancient", "line": "A time-changing artifact was discovered."},
				{ "year": 620, "era": "medieval", "line": "A desert city heard a message that would outlive empires."},
				{ "year": 699, "era": "medieval", "line": "A monk copied a map to a realm that should not exist."},
				{ "year": 750, "era": "medieval", "line": "An artifact chose a farmer instead of a king."},
				{ "year": 1066, "era": "medieval", "line": "A crown changed hands while an old relic watched."},
				{ "year": 1666, "era": "industrial", "line": "A hidden realm woke under ash and watched the smoke rise."},
				{ "year": 1969, "era": "modern", "line": "A footprint touched the moon while Earth held its breath."},
				{ "year": 1999, "era": "modern", "line": "Time forgot which life came first."},
				{ "year": 2075, "era": "future", "line": "A man vanished from every record except a child's dream."},
				{ "year": 2410, "era": "future", "line": "A name became legend and refused to stay dead."},
				{ "year": 4001, "era": "future", "line": "A universe archived its last prayer."}
			],
			"wars_and_crowns": [
				{ "year": -333, "era": "ancient", "line": "A young conqueror stared at the world like it owed him land."},
				{ "year": -218, "era": "ancient", "line": "An army crossed the mountains and made fear practical."},
				{ "year": -60, "era": "ancient", "line": "Three powerful men agreed to share a future none of them trusted."},
				{ "year": 73, "era": "ancient", "line": "A revolt became a lesson written in blood."},
				{ "year": 410, "era": "medieval", "line": "A city thought eternal learned how endings sounded."},
				{ "year": 476, "era": "medieval", "line": "A capital fell, but the age refused to end cleanly."},
				{ "year": 622, "era": "medieval", "line": "A migration changed the calendar of millions."},
				{ "year": 732, "era": "medieval", "line": "A battlefield decided which prayers would echo west."},
				{ "year": 793, "era": "medieval", "line": "A coastline learned fear before the ships had names."},
				{ "year": 1099, "era": "medieval", "line": "A city prayed under siege while history took notes."},
				{ "year": 1453, "era": "medieval", "line": "Walls fell and an empire changed shape overnight."},
				{ "year": 1776, "era": "industrial", "line": "A rebellion became a country and taught flags to argue."},
				{ "year": 1914, "era": "industrial", "line": "The world went to war and boys became dates on stone."},
				{ "year": 1945, "era": "modern", "line": "Cities learned the shape of endings."}
			],
			"ordinary_lives": [
				{ "year": -120, "era": "ancient", "line": "A farmer named his child after rain that never came."},
				{ "year": -7, "era": "ancient", "line": "A child opened their eyes while kingdoms argued over tomorrow."},
				{ "year": 88, "era": "ancient", "line": "A mother sold bread while a future soldier learned to walk."},
				{ "year": 244, "era": "ancient", "line": "A healer saved one stranger and changed a family line."},
				{ "year": 512, "era": "medieval", "line": "A village survived winter because one child remembered a path."},
				{ "year": 640, "era": "medieval", "line": "A blacksmith taught his daughter how to hear metal breathe."},
				{ "year": 701, "era": "medieval", "line": "A fisherman disappeared and left behind a map no one could read."},
				{ "year": 750, "era": "medieval", "line": "A runaway apprentice found a city that did not ask his name."},
				{ "year": 1348, "era": "medieval", "line": "A plague emptied streets and made silence feel crowded."},
				{ "year": 1815, "era": "industrial", "line": "An emperor met his final weather."},
				{ "year": 1892, "era": "industrial", "line": "A legacy fractured and every heir blamed the mirror."},
				{ "year": 1998, "era": "modern", "line": "A child was born into nothing and still bent the odds."},
				{ "year": 2031, "era": "modern", "line": "A school rumor became a scandal before lunch ended."},
				{ "year": 2091, "era": "future", "line": "A machine asked for a childhood."}
			],
			"crime_and_celebrity": [
				{ "year": -55, "era": "ancient", "line": "A thief stole a crown jewel and accidentally started a dynasty."},
				{ "year": 69, "era": "ancient", "line": "Four rulers claimed one year and none of them slept well."},
				{ "year": 305, "era": "ancient", "line": "A palace guard sold a secret to the wrong prophet."},
				{ "year": 642, "era": "medieval", "line": "A masked outlaw became more trusted than the local lord."},
				{ "year": 718, "era": "medieval", "line": "A singer exposed a king with one forbidden verse."},
				{ "year": 1517, "era": "medieval", "line": "A page was nailed down and a world split open."},
				{ "year": 1888, "era": "industrial", "line": "A city learned that fear could become a headline."},
				{ "year": 1927, "era": "modern", "line": "A silent star smiled while a studio buried the truth."},
				{ "year": 1984, "era": "modern", "line": "A city watched itself blink through a thousand cameras."},
				{ "year": 2026, "era": "modern", "line": "A celebrity fought crime at night and signed autographs by noon."},
				{ "year": 2037, "era": "modern", "line": "A mayor sold the future for peace."},
				{ "year": 2043, "era": "future", "line": "A boxer unified the world and punched through fate."},
				{ "year": 2059, "era": "future", "line": "A singer disappeared during the encore."},
				{ "year": 2210, "era": "future", "line": "A colony elected a ghost."}
			],
			"realm_anomalies": [
				{ "year": -900, "era": "ancient", "line": "A cave painted tomorrow before anyone invented history."},
				{ "year": -222, "era": "ancient", "line": "A buried door opened into a sky with two moons."},
				{ "year": 1, "era": "ancient", "line": "A calendar blinked and pretended nothing happened."},
				{ "year": 177, "era": "ancient", "line": "A child spoke a language from a kingdom not yet born."},
				{ "year": 399, "era": "ancient", "line": "A philosopher dreamed of a trial he had already lost."},
				{ "year": 580, "era": "medieval", "line": "A monastery bell rang from underground."},
				{ "year": 666, "era": "medieval", "line": "A hidden realm looked back through a candle flame."},
				{ "year": 741, "era": "medieval", "line": "A doorway appeared for exactly one heartbeat."},
				{ "year": 1666, "era": "industrial", "line": "A hidden realm woke under ash and refused to go back to sleep."},
				{ "year": 1999, "era": "modern", "line": "A timeline split and both versions blamed the other."},
				{ "year": 2075, "era": "future", "line": "Records erased a man who still kept aging."},
				{ "year": 2148, "era": "future", "line": "Two destinies folded into one and both screamed quietly."},
				{ "year": 2655, "era": "future", "line": "A crown was inherited by code."},
				{ "year": 3022, "era": "future", "line": "A memory survived the death of worlds."}
			],
			"future_legends": [
				{ "year": 1969, "era": "modern", "line": "A footprint touched the moon while children watched from carpet floors."},
				{ "year": 1998, "era": "modern", "line": "A child was born into nothing and still inherited time."},
				{ "year": 2026, "era": "modern", "line": "A celebrity smiled through interviews while hiding a second life."},
				{ "year": 2031, "era": "modern", "line": "A school rumor became a scandal before lunch ended."},
				{ "year": 2043, "era": "future", "line": "A boxer became champion while three timelines bet against him."},
				{ "year": 2059, "era": "future", "line": "A singer vanished during the encore and became a myth."},
				{ "year": 2075, "era": "future", "line": "A man vanished from every record except one child's dream."},
				{ "year": 2091, "era": "future", "line": "A machine asked for a childhood."},
				{ "year": 2148, "era": "future", "line": "Two destinies folded into one and both remembered the pain."},
				{ "year": 2210, "era": "future", "line": "A colony elected a ghost."},
				{ "year": 2410, "era": "future", "line": "A name became legend and refused to stay dead."},
				{ "year": 2655, "era": "future", "line": "A crown was inherited by code."},
				{ "year": 3022, "era": "future", "line": "A memory survived the death of worlds."},
				{ "year": 4001, "era": "future", "line": "A universe archived its last prayer."}
			]
		}
	}


static func _startup_intro_merge_generated_recipe_pool_ids(pool_rotation: Array, generated_recipes: Dictionary) -> void:
	for raw_pool_id in generated_recipes.keys():
		var pool_id: String = str(raw_pool_id).strip_edges()
		if pool_id == "":
			continue
		if not pool_rotation.has(pool_id):
			pool_rotation.append(pool_id)


static func _startup_intro_count_recipe_pool_combinations(generated_recipes: Dictionary) -> int:
	var count: int = 0
	for raw_pool_id in generated_recipes.keys():
		var recipe_raw: Variant = generated_recipes.get(raw_pool_id, {})
		if typeof(recipe_raw) != TYPE_DICTIONARY:
			continue

		var recipe: Dictionary = recipe_raw
		var years: Array = recipe.get("years", []) if typeof(recipe.get("years", [])) == TYPE_ARRAY else []
		var subjects: Array = recipe.get("subjects", []) if typeof(recipe.get("subjects", [])) == TYPE_ARRAY else []
		var outcomes: Array = recipe.get("outcomes", []) if typeof(recipe.get("outcomes", [])) == TYPE_ARRAY else []

		count += max(0, years.size() * subjects.size() * outcomes.size())

	return count


static func _startup_intro_recipe_pool_moment_count(recipe: Dictionary) -> int:
	var years: Array = recipe.get("years", []) if typeof(recipe.get("years", [])) == TYPE_ARRAY else []
	var subjects: Array = recipe.get("subjects", []) if typeof(recipe.get("subjects", [])) == TYPE_ARRAY else []
	var outcomes: Array = recipe.get("outcomes", []) if typeof(recipe.get("outcomes", [])) == TYPE_ARRAY else []
	return max(0, years.size() * subjects.size() * outcomes.size())


static func _startup_intro_massive_generated_pool_recipes() -> Dictionary:
	return {
		"grounded_modern_headlines": {
			"era": "modern",
			"years": [1984, 1999, 2007, 2016, 2020, 2026, 2031, 2037],
			"subjects": [
				"A teacher",
				"A lawyer",
				"A mayor",
				"A surgeon",
				"A principal",
				"A detective",
				"A preacher",
				"A billionaire",
				"A streamer",
				"A judge"
			],
			"outcomes": [
				"was arrested for murder",
				"abandoned his family",
				"vanished before sentencing",
				"confessed on live television",
				"hid a second life",
				"became a scandal overnight",
				"lost everything after one phone call",
				"bought silence and called it peace"
			]
		},
		"ancient_empire_pressure": {
			"era": "ancient",
			"years": [-333, -218, -120, -60, -33, -12, 33, 41, 79, 177, 210, 305, 399],
			"subjects": [
				"Empires",
				"Two kings",
				"A general",
				"A prophet",
				"A prince",
				"A queen",
				"A temple",
				"A hidden army",
				"A royal child",
				"A forgotten city"
			],
			"outcomes": [
				"go to war",
				"broke an oath before sunrise",
				"followed a sign nobody else could see",
				"buried a weapon beneath the river",
				"turned a betrayal into law",
				"survived a prophecy meant to kill them",
				"opened a door beneath the palace",
				"vanished from every official record"
			]
		},
		"medieval_oaths_and_realms": {
			"era": "medieval",
			"years": [410, 476, 512, 580, 611, 620, 642, 666, 701, 718, 741, 750, 793, 1066, 1099, 1204, 1348, 1453, 1492],
			"subjects": [
				"A knight",
				"A monk",
				"A queen",
				"A blacksmith",
				"A hidden realm",
				"A village",
				"A thief",
				"A singer",
				"A prince",
				"A plague doctor"
			],
			"outcomes": [
				"broke a vow and saved a kingdom",
				"copied a map to a place that should not exist",
				"hid an heir beneath a chapel",
				"heard metal speak back",
				"looked through a candle flame",
				"survived winter by blaming the wrong stranger",
				"stole a crown and started a dynasty",
				"exposed a king with one forbidden verse",
				"inherited a war before learning mercy",
				"was accused of selling curses"
			]
		},
		"industrial_pressure_cooker": {
			"era": "industrial",
			"years": [1666, 1776, 1815, 1833, 1842, 1847, 1888, 1892, 1906, 1914, 1918],
			"subjects": [
				"A factory",
				"A union",
				"A boxer",
				"A nurse",
				"A railroad heir",
				"A coal town",
				"A machine",
				"A newspaper",
				"A soldier",
				"A furnace"
			],
			"outcomes": [
				"changed how families survived",
				"began in whispers under smoke",
				"won a fight nobody paid to see",
				"kept working while the city counted its dead",
				"lost everything to a signed contract",
				"buried its shame under ash",
				"made a man rich and a city sick",
				"turned fear into a headline",
				"returned home as a ghost of himself",
				"revealed a crown made of black glass"
			]
		},
		"future_mythic_systems": {
			"era": "future",
			"years": [2043, 2059, 2075, 2091, 2148, 2210, 2410, 2655, 2826, 3022, 4001],
			"subjects": [
				"A Bender",
				"A colony",
				"A ghost",
				"A machine",
				"A cloned heir",
				"A prison moon",
				"A synthetic judge",
				"A memory",
				"A cosmic relic",
				"The last Avatar"
			],
			"outcomes": [
				"rises from sheer will power",
				"elected a ghost and called it democracy",
				"kept aging after being erased",
				"asked for a childhood",
				"remembered two timelines at once",
				"opened one cell and lost a civilization",
				"delivered a verdict nobody programmed",
				"survived the death of worlds",
				"refused every owner except a child",
				"heard every past life speak at once"
			]
		}
	}


static func _startup_intro_count_pool_moments(pools: Dictionary) -> int:
	var count: int = 0
	for raw_pool_id in pools.keys():
		var pool_raw: Variant = pools.get(raw_pool_id, [])
		if typeof(pool_raw) == TYPE_ARRAY:
			count += (pool_raw as Array).size()
	return count


static func _startup_intro_moment_key(moment: Dictionary) -> String:
	return "%s|%s|%s" % [
		str(moment.get("year", "")),
		str(moment.get("era", "")),
		str(moment.get("line", ""))
	]


static func _startup_intro_massive_static_pool_expansion() -> Dictionary:
	return {
		"grounded_life_fractures": [
			{ "year": -44, "era": "ancient", "line": "A senator betrayed a friend and called it duty."},
			{ "year": -33, "era": "ancient", "line": "Empires go to war."},
			{ "year": 79, "era": "ancient", "line": "A city disappeared beneath fire and ash."},
			{ "year": 310, "era": "ancient", "line": "A healer saved a child who would bankrupt a kingdom."},
			{ "year": 612, "era": "medieval", "line": "A farmer buried coins under a floor nobody would find for centuries."},
			{ "year": 740, "era": "medieval", "line": "A village blamed a stranger for a winter that would not end."},
			{ "year": 1221, "era": "medieval", "line": "A merchant vanished after selling bread to the wrong army."},
			{ "year": 1665, "era": "industrial", "line": "A doctor refused to leave the sick behind."},
			{ "year": 1842, "era": "industrial", "line": "A factory girl lost three fingers and started a union in secret."},
			{ "year": 1918, "era": "industrial", "line": "A nurse kept working while the city counted its dead."},
			{ "year": 1999, "era": "modern", "line": "A lawyer abandons his family."},
			{ "year": 2007, "era": "modern", "line": "A father changed his name and started over in another city."},
			{ "year": 2026, "era": "modern", "line": "A teacher was arrested for murder."},
			{ "year": 2034, "era": "modern", "line": "A streamer confessed on camera and deleted the evidence too late."},
			{ "year": 2098, "era": "future", "line": "A child sued the algorithm that raised him."},
			{ "year": 2315, "era": "future", "line": "A family bought a memory they could not afford."}
		],
		"bending_and_willpower": [
			{ "year": -12, "era": "ancient", "line": "A firebender refused a throne and walked into exile."},
			{ "year": 79, "era": "ancient", "line": "The Avatar still walks amongst men."},
			{ "year": 210, "era": "ancient", "line": "A child bent water before learning their own name."},
			{ "year": 511, "era": "medieval", "line": "A monk taught breath control to a boy who feared his hands."},
			{ "year": 642, "era": "medieval", "line": "An earthbender held a bridge until sunrise."},
			{ "year": 750, "era": "medieval", "line": "The Avatar vanished into a storm and returned older."},
			{ "year": 1420, "era": "medieval", "line": "A master refused to teach the prince and chose the stable boy."},
			{ "year": 1833, "era": "industrial", "line": "A metalworker heard the earth inside the machine."},
			{ "year": 1906, "era": "industrial", "line": "A bending tournament ended when the arena floor split in half."},
			{ "year": 1998, "era": "modern", "line": "A quiet student bent fire after years of humiliation."},
			{ "year": 2029, "era": "modern", "line": "A street duel made a nobody famous by morning."},
			{ "year": 2043, "era": "future", "line": "An airbender learned to move without being seen."},
			{ "year": 2148, "era": "future", "line": "A bending bloodline reappeared inside a cloned dynasty."},
			{ "year": 2826, "era": "future", "line": "A Bender rises from sheer will power."},
			{ "year": 3022, "era": "future", "line": "A master bent gravity and denied it happened."},
			{ "year": 4001, "era": "future", "line": "The last Avatar heard every past life speak at once."}
		],
		"crime_justice_and_scandal": [
			{ "year": -60, "era": "ancient", "line": "A governor bought innocence with temple gold."},
			{ "year": 33, "era": "ancient", "line": "A prisoner became a symbol before the empire understood why."},
			{ "year": 305, "era": "ancient", "line": "A palace guard framed a beggar for a royal death."},
			{ "year": 699, "era": "medieval", "line": "A judge sentenced his own brother and lost the city."},
			{ "year": 1066, "era": "medieval", "line": "A thief crossed a battlefield carrying the wrong crown."},
			{ "year": 1348, "era": "medieval", "line": "A plague doctor was accused of selling curses."},
			{ "year": 1888, "era": "industrial", "line": "A city learned fear could become a headline."},
			{ "year": 1927, "era": "modern", "line": "A studio buried a death and sold the smile anyway."},
			{ "year": 1984, "era": "modern", "line": "A mayor won reelection while hiding three bodies."},
			{ "year": 1999, "era": "modern", "line": "A detective solved the case and disappeared before trial."},
			{ "year": 2026, "era": "modern", "line": "A teacher was arrested for murder."},
			{ "year": 2037, "era": "modern", "line": "A courtroom livestream turned a witness into a celebrity."},
			{ "year": 2075, "era": "future", "line": "A synthetic judge delivered a verdict nobody programmed."},
			{ "year": 2410, "era": "future", "line": "A prison moon opened one cell and lost a civilization."},
			{ "year": 2826, "era": "future", "line": "A criminal empire bought a timeline and still went bankrupt."},
			{ "year": 3022, "era": "future", "line": "A confession arrived from a person not yet born."}
		],
		"cosmic_artifacts_and_relics": [
			{ "year": -300, "era": "ancient", "line": "A temple stone hummed before the priests learned fear."},
			{ "year": -33, "era": "ancient", "line": "A relic chose war over silence."},
			{ "year": 79, "era": "ancient", "line": "A buried artifact survived the mountain's fire."},
			{ "year": 210, "era": "ancient", "line": "A time-changing artifact was discovered."},
			{ "year": 620, "era": "medieval", "line": "A desert relic whispered through a locked room."},
			{ "year": 750, "era": "medieval", "line": "A ring opened a realm beneath a sleeping city."},
			{ "year": 1204, "era": "medieval", "line": "A knight sold a holy blade to pay a debt."},
			{ "year": 1666, "era": "industrial", "line": "A hidden realm woke under ash and refused to sleep again."},
			{ "year": 1847, "era": "industrial", "line": "A factory furnace revealed a crown made of black glass."},
			{ "year": 1969, "era": "modern", "line": "The moon kept one footprint and one secret."},
			{ "year": 1999, "era": "modern", "line": "A child found a red bonnet inside a locked attic."},
			{ "year": 2026, "era": "modern", "line": "Seven signals lit up across the world."},
			{ "year": 2043, "era": "future", "line": "An artifact escaped containment by becoming a rumor."},
			{ "year": 2148, "era": "future", "line": "A stone rewound one minute and aged a king by fifty years."},
			{ "year": 2826, "era": "future", "line": "A cosmic relic refused every owner except a child."},
			{ "year": 4001, "era": "future", "line": "The final artifact remembered the first universe."}
		],
		"family_dynasty_and_betrayal": [
			{ "year": -120, "era": "ancient", "line": "A mother hid twins from a bloodline that wanted only one."},
			{ "year": -30, "era": "ancient", "line": "A prodigy was born as Crowned Prince."},
			{ "year": 41, "era": "ancient", "line": "A royal infant survived a poisoned feast."},
			{ "year": 476, "era": "medieval", "line": "A fallen dynasty buried its last crown in silence."},
			{ "year": 611, "era": "medieval", "line": "A child of two kingdoms was promised to a war."},
			{ "year": 742, "era": "medieval", "line": "A royal bloodline awakened with a name no historian trusted."},
			{ "year": 1492, "era": "medieval", "line": "A voyage redrew inheritance, land, and destiny."},
			{ "year": 1815, "era": "industrial", "line": "An emperor met his final weather."},
			{ "year": 1892, "era": "industrial", "line": "A legacy fractured and every heir blamed the mirror."},
			{ "year": 1914, "era": "industrial", "line": "A noble son marched away and returned as a story."},
			{ "year": 1999, "era": "modern", "line": "A lawyer abandons his family."},
			{ "year": 2026, "era": "modern", "line": "A celebrity bloodline collapsed on live television."},
			{ "year": 2031, "era": "modern", "line": "A daughter inherited debt and turned it into a dynasty."},
			{ "year": 2075, "era": "future", "line": "A family uploaded its inheritance and forgot the password."},
			{ "year": 2655, "era": "future", "line": "A crown was inherited by code."},
			{ "year": 3022, "era": "future", "line": "A bloodline ended physically and continued legally."}
		],
		"ordinary_to_legendary": [
			{ "year": -7, "era": "ancient", "line": "A child opened their eyes while kingdoms argued over tomorrow."},
			{ "year": 88, "era": "ancient", "line": "A mother sold bread while a future soldier learned to walk."},
			{ "year": 244, "era": "ancient", "line": "A healer saved one stranger and changed a family line."},
			{ "year": 512, "era": "medieval", "line": "A village survived winter because one child remembered a path."},
			{ "year": 640, "era": "medieval", "line": "A blacksmith taught his daughter how to hear metal breathe."},
			{ "year": 701, "era": "medieval", "line": "A fisherman disappeared and left behind a map no one could read."},
			{ "year": 750, "era": "medieval", "line": "A runaway apprentice found a city that did not ask his name."},
			{ "year": 1847, "era": "industrial", "line": "A family built a name from hunger, debt, and stubborn breath."},
			{ "year": 1914, "era": "industrial", "line": "A boy lied about his age and returned older than his father."},
			{ "year": 1969, "era": "modern", "line": "A child watched the moon landing and decided Earth was too small."},
			{ "year": 1998, "era": "modern", "line": "A child was born into nothing and still bent the odds."},
			{ "year": 2026, "era": "modern", "line": "A broke dreamer built a world nobody could explain."},
			{ "year": 2043, "era": "future", "line": "A boxer unified the world and punched through fate."},
			{ "year": 2091, "era": "future", "line": "A machine asked for a childhood."},
			{ "year": 2410, "era": "future", "line": "A name became legend and refused to stay dead."},
			{ "year": 4001, "era": "future", "line": "A universe archived its last prayer."}
		]
	}


static func _startup_intro_generated_pool_special_moments(pool_id: String, era_tag: String) -> Array:
	var clean_pool_id: String = str(pool_id).strip_edges().to_lower()
	var clean_era: String = str(era_tag).strip_edges().to_lower()

	match clean_pool_id:
		"grounded_modern_headlines":
			return [
				{ "year": 1999, "era": "modern", "line": "A lawyer abandoned his family.", "event_signature": "family_abandonment"},
				{ "year": 2026, "era": "modern", "line": "A teacher was arrested for murder.", "event_signature": "teacher_murder_arrest"},
				{ "year": 2031, "era": "modern", "line": "A prodigy was born into history.", "event_signature": "prodigy_born_history"},
				{ "year": 2037, "era": "modern", "line": "A courtroom became famous before the verdict.", "event_signature": "courtroom_fame_before_verdict"}
			]
		"ancient_empire_pressure":
			return [
				{ "year": -33, "era": "ancient", "line": "Empires go to war.", "event_signature": "empires_go_to_war"},
				{ "year": 79, "era": "ancient", "line": "The Avatar still walks amongst men.", "event_signature": "avatar_walks_amongst_men"},
				{ "year": 210, "era": "ancient", "line": "A prodigy was born into history.", "event_signature": "prodigy_born_history"},
				{ "year": 250, "era": "ancient", "line": "A firebender summoned the Dragon Balls.", "event_signature": "firebender_summoned_dragon_balls"}
			]
		"future_mythic_systems":
			return [
				{ "year": 2043, "era": "future", "line": "A firebender summoned the Dragon Balls.", "event_signature": "firebender_summoned_dragon_balls"},
				{ "year": 2148, "era": "future", "line": "A prodigy was born into history.", "event_signature": "prodigy_born_history"},
				{ "year": 2826, "era": "future", "line": "A Bender rose from sheer willpower.", "event_signature": "bender_sheer_willpower"},
				{ "year": 3022, "era": "future", "line": "A cosmic relic chose a child and bent the sky around them.", "event_signature": "cosmic_relic_chose_child"}
			]
		"industrial_pressure_cooker":
			return [
				{ "year": 1847, "era": "industrial", "line": "A factory swallowed a family and gave back a dynasty.", "event_signature": "factory_family_dynasty"},
				{ "year": 1888, "era": "industrial", "line": "A newspaper turned fear into a headline.", "event_signature": "newspaper_fear_headline"},
				{ "year": 1914, "era": "industrial", "line": "A soldier returned home as a rumor.", "event_signature": "soldier_returned_rumor"}
			]
		_:
			return [
				{ "year": 250, "era": clean_era, "line": "A prodigy was born into history.", "event_signature": "prodigy_born_history"}
			]


static func _startup_intro_generated_subject_allows_outcome(pool_id: String, subject_text: String, outcome_text: String) -> bool:
	var pool: String = str(pool_id).strip_edges().to_lower()
	var subject: String = str(subject_text).strip_edges().to_lower()
	var outcome: String = str(outcome_text).strip_edges().to_lower()

	if subject == "" or outcome == "":
		return false

	match pool:
		"future_mythic_systems":
			if subject in ["a bender", "the last avatar"]:
				return outcome in [
					"rises from sheer will power",
					"heard every past life speak at once",
					"remembered two timelines at once"
				]
			if subject in ["a colony"]:
				return outcome in [
					"elected a ghost and called it democracy",
					"opened one cell and lost a civilization"
				]
			if subject in ["a ghost"]:
				return outcome in [
					"kept aging after being erased",
					"survived the death of worlds"
				]
			if subject in ["a machine"]:
				return outcome in [
					"asked for a childhood",
					"delivered a verdict nobody programmed"
				]
			if subject in ["a synthetic judge"]:
				return outcome in [
					"delivered a verdict nobody programmed"
				]
			if subject in ["a memory"]:
				return outcome in [
					"survived the death of worlds",
					"remembered two timelines at once"
				]
			if subject in ["a cosmic relic"]:
				return outcome in [
					"refused every owner except a child",
					"remembered two timelines at once"
				]
			if subject in ["a prison moon"]:
				return outcome in [
					"opened one cell and lost a civilization"
				]
			if subject in ["a cloned heir"]:
				return outcome in [
					"remembered two timelines at once"
				]
			return false

		"industrial_pressure_cooker":
			if subject in ["a factory", "a coal town", "a machine", "a furnace"]:
				return outcome in [
					"changed how families survived",
					"buried its shame under ash",
					"made a man rich and a city sick",
					"revealed a crown made of black glass"
				]
			if subject in ["a union"]:
				return outcome in [
					"began in whispers under smoke",
					"changed how families survived"
				]
			if subject in ["a boxer"]:
				return outcome in [
					"won a fight nobody paid to see"
				]
			if subject in ["a nurse"]:
				return outcome in [
					"kept working while the city counted its dead"
				]
			if subject in ["a railroad heir"]:
				return outcome in [
					"lost everything to a signed contract"
				]
			if subject in ["a newspaper"]:
				return outcome in [
					"turned fear into a headline"
				]
			if subject in ["a soldier"]:
				return outcome in [
					"returned home as a ghost of himself"
				]
			return false

		"grounded_modern_headlines":
			if subject in ["a teacher", "a principal", "a preacher", "a mayor", "a judge", "a surgeon", "a detective"]:
				return outcome in [
					"was arrested for murder",
					"vanished before sentencing",
					"confessed on live television",
					"hid a second life",
					"became a scandal overnight",
					"lost everything after one phone call",
					"bought silence and called it peace"
				]
			if subject in ["a lawyer"]:
				return outcome in [
					"abandoned his family",
					"vanished before sentencing",
					"hid a second life",
					"lost everything after one phone call"
				]
			if subject in ["a billionaire", "a streamer"]:
				return outcome in [
					"confessed on live television",
					"hid a second life",
					"became a scandal overnight",
					"lost everything after one phone call",
					"bought silence and called it peace"
				]
			return false

		"ancient_empire_pressure":
			if subject in ["empires", "two kings", "a general", "a hidden army"]:
				return outcome in [
					"go to war",
					"broke an oath before sunrise",
					"buried a weapon beneath the river",
					"turned a betrayal into law",
					"vanished from every official record"
				]
			if subject in ["a prophet", "a temple", "a forgotten city"]:
				return outcome in [
					"followed a sign nobody else could see",
					"opened a door beneath the palace",
					"vanished from every official record"
				]
			if subject in ["a prince", "a queen", "a royal child"]:
				return outcome in [
					"broke an oath before sunrise",
					"turned a betrayal into law",
					"survived a prophecy meant to kill them"
				]
			return false

		"medieval_oaths_and_realms":
			if subject in ["a knight", "a prince"]:
				return outcome in [
					"broke a vow and saved a kingdom",
					"inherited a war before learning mercy"
				]
			if subject in ["a monk"]:
				return outcome in [
					"copied a map to a place that should not exist"
				]
			if subject in ["a queen"]:
				return outcome in [
					"hid an heir beneath a chapel"
				]
			if subject in ["a blacksmith"]:
				return outcome in [
					"heard metal speak back"
				]
			if subject in ["a hidden realm"]:
				return outcome in [
					"looked through a candle flame"
				]
			if subject in ["a village"]:
				return outcome in [
					"survived winter by blaming the wrong stranger"
				]
			if subject in ["a thief"]:
				return outcome in [
					"stole a crown and started a dynasty"
				]
			if subject in ["a singer"]:
				return outcome in [
					"exposed a king with one forbidden verse"
				]
			if subject in ["a plague doctor"]:
				return outcome in [
					"was accused of selling curses"
				]
			return false

	return true


static func _startup_intro_compact_identity_text(raw_text: String) -> String:
	var clean: String = str(raw_text).strip_edges().to_lower()
	clean = clean.replace(".", "")
	clean = clean.replace(",", "")
	clean = clean.replace(";", "")
	clean = clean.replace(":", "")
	clean = clean.replace("!", "")
	clean = clean.replace("?", "")
	clean = clean.replace("/", " ")
	clean = clean.replace("\\", " ")
	clean = clean.replace("'", "")
	clean = clean.replace("\"", "")
	clean = clean.replace("  ", " ")

	while clean.find("  ") >= 0:
		clean = clean.replace("  ", " ")

	return clean.strip_edges()


static func _startup_intro_moment_year_identity_key(moment: Dictionary) -> String:
	if typeof(moment) != TYPE_DICTIONARY:
		return ""

	if moment.has("raw_year"):
		return str(moment.get("raw_year", "")).strip_edges()

	return str(moment.get("year", "")).strip_edges()


static func _startup_intro_perceptual_integrity_context(phase: String, slot_index: int = -1, attempt: int = 0, pool_id: String = "") -> Dictionary:
	return {
		"stream_id": "startup_intro",
		"phase": str(phase).strip_edges(),
		"slot_index": int(slot_index),
		"attempt": int(attempt),
		"pool_label": str(pool_id).strip_edges(),
		"source": "mainscene_startup_intro",
		"profile": "cinematic_hot_path",
	}


static func _startup_intro_sequence_timing_slots() -> Array:
	return [
		{ "fade_in": 0.2, "hold": 0.22, "fade_out": 0.08, "pitch": 0.98},
		{ "fade_in": 0.16, "hold": 0.18, "fade_out": 0.07, "pitch": 1.04},
		{ "fade_in": 0.13, "hold": 0.15, "fade_out": 0.06, "pitch": 1.1},
		{ "fade_in": 0.11, "hold": 0.12, "fade_out": 0.05, "pitch": 1.16},
		{ "fade_in": 0.09, "hold": 0.1, "fade_out": 0.04, "pitch": 1.22},
		{ "fade_in": 0.08, "hold": 0.08, "fade_out": 0.035, "pitch": 1.28},
		{ "fade_in": 0.07, "hold": 0.07, "fade_out": 0.03, "pitch": 1.34},
		{ "fade_in": 0.06, "hold": 0.06, "fade_out": 0.03, "pitch": 1.4},
		{ "fade_in": 0.05, "hold": 0.05, "fade_out": 0.025, "pitch": 1.46},
		{ "fade_in": 0.045, "hold": 0.045, "fade_out": 0.022, "pitch": 1.52},
		{ "fade_in": 0.04, "hold": 0.04, "fade_out": 0.02, "pitch": 1.58},
		{ "fade_in": 0.036, "hold": 0.036, "fade_out": 0.018, "pitch": 1.64},
		{ "fade_in": 0.032, "hold": 0.032, "fade_out": 0.016, "pitch": 1.7},
		{ "fade_in": 0.028, "hold": 0.028, "fade_out": 0.014, "pitch": 1.76}
	]


static func _startup_intro_procedural_color_for_era_tag(era_tag: String) -> Dictionary:
	match str(era_tag).strip_edges().to_lower():
		"ancient":
			return {
				"year_color": Color(0.96, 0.82, 0.42, 1.0),
				"line_color": Color(1.0, 0.91, 0.63, 1.0)
			}
		"medieval":
			return {
				"year_color": Color(0.82, 0.66, 1.0, 1.0),
				"line_color": Color(0.94, 0.86, 1.0, 1.0)
			}
		"industrial":
			return {
				"year_color": Color(0.95, 0.56, 0.3, 1.0),
				"line_color": Color(1.0, 0.72, 0.46, 1.0)
			}
		"modern":
			return {
				"year_color": Color(0.48, 0.9, 1.0, 1.0),
				"line_color": Color(0.76, 0.97, 1.0, 1.0)
			}
		"future":
			return {
				"year_color": Color(1.0, 0.3, 0.78, 1.0),
				"line_color": Color(1.0, 0.58, 0.9, 1.0)
			}
		_:
			return {
				"year_color": Color(1.0, 0.94, 0.62, 1.0),
				"line_color": Color(0.82, 0.98, 1.0, 1.0)
			}


static func _startup_intro_sequence_bundle_signature(intro_sequence: Array, bridge_sequence: Array) -> String:
	return "%s||%s" % [
		IntroContentSceneSupport._startup_intro_sequence_signature(intro_sequence),
		IntroContentSceneSupport._startup_intro_sequence_signature(bridge_sequence)
	]


static func _startup_intro_format_procedural_year(raw_year: Variant) -> String:
	var year_value: int = int(raw_year)

	if year_value < 0:
		return "%d BCE" % abs(year_value)

	if year_value == 0:
		return "1 BCE"

	if year_value <= IntroSceneSupport._startup_intro_ad_suffix_cutoff_year():
		return "%d AD" % year_value

	return str(year_value)


static func _startup_intro_apply_massive_pool_expansion(base_contract: Dictionary) -> Dictionary:
	var contract: Dictionary = base_contract.duplicate(true)
	contract ["version"] = 3
	contract ["schema"] = "eralife.procedural_cinematic_sequence_contract"
	contract ["expansion"] = "massive_grounded_to_legendary_recipe_pool_pass"
	contract ["recent_memory_limit"] = 768
	contract ["runtime_content_strategy"] = "static_pools_plus_o1_recipe_generation"

	var pool_rotation: Array = contract.get("pool_rotation", []) if typeof(contract.get("pool_rotation", [])) == TYPE_ARRAY else []
	var pools: Dictionary = contract.get("pools", {}) if typeof(contract.get("pools", {})) == TYPE_DICTIONARY else {}

	var static_expansion: Dictionary = IntroContentSceneSupport._startup_intro_massive_static_pool_expansion()
	var generated_recipes: Dictionary = IntroContentSceneSupport._startup_intro_massive_generated_pool_recipes()

	IntroContentSceneSupport._startup_intro_merge_pool_expansion(pool_rotation, pools, static_expansion)
	IntroContentSceneSupport._startup_intro_merge_generated_recipe_pool_ids(pool_rotation, generated_recipes)

	contract ["pool_rotation"] = pool_rotation
	contract ["pools"] = pools
	contract ["generated_recipe_pools"] = generated_recipes
	contract ["expanded_pool_count"] = pool_rotation.size()
	contract ["expanded_moment_count"] = IntroContentSceneSupport._startup_intro_count_pool_moments(pools) + IntroContentSceneSupport._startup_intro_count_recipe_pool_combinations(generated_recipes)

	return contract


static func _startup_intro_generate_recipe_pool_moment(pool_id: String, recipe: Dictionary, rng: RandomNumberGenerator, phase: String, slot_index: int) -> Dictionary:
	var years: Array = recipe.get("years", []) if typeof(recipe.get("years", [])) == TYPE_ARRAY else []
	var subjects: Array = recipe.get("subjects", []) if typeof(recipe.get("subjects", [])) == TYPE_ARRAY else []
	var outcomes: Array = recipe.get("outcomes", []) if typeof(recipe.get("outcomes", [])) == TYPE_ARRAY else []
	var era_tag: String = str(recipe.get("era", "modern")).strip_edges().to_lower()
	var clean_pool_id: String = str(pool_id).strip_edges()

	if years.is_empty() or subjects.is_empty() or outcomes.is_empty():
		return {}

	for attempt in range(32):
		var year_value: int = int(years [int(rng.randi_range(0, years.size() - 1))])
		var subject_text: String = str(subjects [int(rng.randi_range(0, subjects.size() - 1))]).strip_edges()
		var outcome_text: String = str(outcomes [int(rng.randi_range(0, outcomes.size() - 1))]).strip_edges()

		if subject_text == "" or outcome_text == "":
			continue

		if not IntroContentSceneSupport._startup_intro_generated_subject_allows_outcome(clean_pool_id, subject_text, outcome_text):
			continue

		var line_text: String = "%s %s." % [subject_text, outcome_text]
		var event_signature: String = IntroSceneSupport._startup_intro_event_signature_from_line(line_text)
		var line_key: String = IntroContentSceneSupport._startup_intro_line_identity_key(line_text)
		var opening_key: String = IntroContentSceneSupport._startup_intro_line_opening_key(line_text, 3)
		var subject_key: String = IntroContentSceneSupport._startup_intro_subject_identity_key(line_text)

		return {
			"year": year_value,
			"era": era_tag,
			"line": line_text,
			"pool_label": clean_pool_id,
			"phase": phase,
			"slot_index": slot_index,
			"event_signature": event_signature,
			"line_identity_key": line_key,
			"intro_opening_key": opening_key,
			"subject_identity_key": subject_key,
			"year_identity_key": str(year_value),
		}

	return {}


static func _startup_intro_merge_pool_expansion(pool_rotation: Array, pools: Dictionary, expansion: Dictionary) -> void:
	for raw_pool_id in expansion.keys():
		var pool_id: String = str(raw_pool_id).strip_edges()
		if pool_id == "":
			continue

		if not pool_rotation.has(pool_id):
			pool_rotation.append(pool_id)

		var base_pool: Array = pools.get(pool_id, []) if typeof(pools.get(pool_id, [])) == TYPE_ARRAY else []
		var add_pool: Array = expansion.get(pool_id, []) if typeof(expansion.get(pool_id, [])) == TYPE_ARRAY else []

		var known_keys: Dictionary = {}
		for raw_existing in base_pool:
			if typeof(raw_existing) != TYPE_DICTIONARY:
				continue
			var existing: Dictionary = raw_existing
			known_keys [IntroContentSceneSupport._startup_intro_moment_key(existing)] = true

		for raw_moment in add_pool:
			if typeof(raw_moment) != TYPE_DICTIONARY:
				continue

			var moment: Dictionary = (raw_moment as Dictionary).duplicate(true)
			var moment_key: String = IntroContentSceneSupport._startup_intro_moment_key(moment)
			if known_keys.has(moment_key):
				continue

			known_keys [moment_key] = true
			base_pool.append(moment)

		pools [pool_id] = base_pool


static func _startup_intro_massive_generated_pool_expansion() -> Dictionary:
	var expansion: Dictionary = {}

	IntroContentSceneSupport._startup_intro_add_generated_pool(
		expansion,
		"grounded_modern_headlines",
		"modern",
		[1984, 1999, 2007, 2016, 2020, 2026, 2031, 2037],
		[
			"A teacher",
			"A lawyer",
			"A mayor",
			"A surgeon",
			"A principal",
			"A detective",
			"A preacher",
			"A billionaire",
			"A streamer",
			"A judge"
		],
		[
			"was arrested for murder",
			"abandoned his family",
			"vanished before sentencing",
			"confessed on live television",
			"hid a second life",
			"became a scandal overnight",
			"lost everything after one phone call",
			"bought silence and called it peace"
		]
	)

	IntroContentSceneSupport._startup_intro_add_generated_pool(
		expansion,
		"ancient_empire_pressure",
		"ancient",
		[-333, -218, -120, -60, -33, -12, 33, 41, 79, 177, 210, 305, 399],
		[
			"Empires",
			"Two kings",
			"A general",
			"A prophet",
			"A prince",
			"A queen",
			"A temple",
			"A hidden army",
			"A royal child",
			"A forgotten city"
		],
		[
			"go to war",
			"broke an oath before sunrise",
			"followed a sign nobody else could see",
			"buried a weapon beneath the river",
			"turned a betrayal into law",
			"survived a prophecy meant to kill them",
			"opened a door beneath the palace",
			"vanished from every official record"
		]
	)

	IntroContentSceneSupport._startup_intro_add_generated_pool(
		expansion,
		"medieval_oaths_and_realms",
		"medieval",
		[410, 476, 512, 580, 611, 620, 642, 666, 701, 718, 741, 750, 793, 1066, 1099, 1204, 1348, 1453, 1492],
		[
			"A knight",
			"A monk",
			"A queen",
			"A blacksmith",
			"A hidden realm",
			"A village",
			"A thief",
			"A singer",
			"A prince",
			"A plague doctor"
		],
		[
			"broke a vow and saved a kingdom",
			"copied a map to a place that should not exist",
			"hid an heir beneath a chapel",
			"heard metal speak back",
			"looked through a candle flame",
			"survived winter by blaming the wrong stranger",
			"stole a crown and started a dynasty",
			"exposed a king with one forbidden verse",
			"inherited a war before learning mercy",
			"was accused of selling curses"
		]
	)

	IntroContentSceneSupport._startup_intro_add_generated_pool(
		expansion,
		"industrial_pressure_cooker",
		"industrial",
		[1666, 1776, 1815, 1833, 1842, 1847, 1888, 1892, 1906, 1914, 1918],
		[
			"A factory",
			"A union",
			"A boxer",
			"A nurse",
			"A railroad heir",
			"A coal town",
			"A machine",
			"A newspaper",
			"A soldier",
			"A furnace"
		],
		[
			"changed how families survived",
			"began in whispers under smoke",
			"won a fight nobody paid to see",
			"kept working while the city counted its dead",
			"lost everything to a signed contract",
			"buried its shame under ash",
			"made a man rich and a city sick",
			"turned fear into a headline",
			"returned home as a ghost of himself",
			"revealed a crown made of black glass"
		]
	)

	IntroContentSceneSupport._startup_intro_add_generated_pool(
		expansion,
		"future_mythic_systems",
		"future",
		[2043, 2059, 2075, 2091, 2148, 2210, 2410, 2655, 2826, 3022, 4001],
		[
			"A Bender",
			"A colony",
			"A ghost",
			"A machine",
			"A cloned heir",
			"A prison moon",
			"A synthetic judge",
			"A memory",
			"A cosmic relic",
			"The last Avatar"
		],
		[
			"rises from sheer will power",
			"elected a ghost and called it democracy",
			"kept aging after being erased",
			"asked for a childhood",
			"remembered two timelines at once",
			"opened one cell and lost a civilization",
			"delivered a verdict nobody programmed",
			"survived the death of worlds",
			"refused every owner except a child",
			"heard every past life speak at once"
		]
	)

	return expansion


static func _startup_intro_add_generated_pool(expansion: Dictionary, pool_id: String, era_tag: String, years: Array, subjects: Array, outcomes: Array) -> void:
	var clean_pool_id: String = str(pool_id).strip_edges()
	if clean_pool_id == "":
		return

	if not expansion.has(clean_pool_id):
		expansion [clean_pool_id] = []

	var out: Array = expansion.get(clean_pool_id, []) if typeof(expansion.get(clean_pool_id, [])) == TYPE_ARRAY else []

	for special_moment in IntroContentSceneSupport._startup_intro_generated_pool_special_moments(clean_pool_id, era_tag):
		if typeof(special_moment) != TYPE_DICTIONARY:
			continue
		out.append((special_moment as Dictionary).duplicate(true))

	for raw_year in years:
		for raw_subject in subjects:
			for raw_outcome in outcomes:
				var subject_text: String = str(raw_subject).strip_edges()
				var outcome_text: String = str(raw_outcome).strip_edges()
				if subject_text == "" or outcome_text == "":
					continue

				if not IntroContentSceneSupport._startup_intro_generated_subject_allows_outcome(clean_pool_id, subject_text, outcome_text):
					continue

				var line_text: String = "%s %s." % [subject_text, outcome_text]
				var event_signature: String = IntroSceneSupport._startup_intro_event_signature_from_line(line_text)

				out.append({
					"year": int(raw_year),
					"era": str(era_tag).strip_edges().to_lower(),
					"line": line_text,
					"event_signature": event_signature,
				})

	expansion [clean_pool_id] = out


static func _startup_intro_line_identity_key(line_text: String) -> String:
	return IntroContentSceneSupport._startup_intro_compact_identity_text(line_text)


static func _startup_intro_identity_words(line_text: String) -> Array:
	var clean: String = IntroContentSceneSupport._startup_intro_compact_identity_text(line_text)
	if clean == "":
		return []

	var raw_words: Array = clean.split(" ", false)
	var out: Array = []
	for raw_word in raw_words:
		var word: String = str(raw_word).strip_edges()
		if word == "":
			continue
		out.append(word)

	return out


static func _startup_intro_line_opening_key(line_text: String, word_count: int = 3) -> String:
	var words: Array = IntroContentSceneSupport._startup_intro_identity_words(line_text)
	if words.is_empty():
		return ""

	var take_count: int = clamp(int(word_count), 1, words.size())
	var out: Array = []
	for i in range(take_count):
		out.append(str(words [i]))

	return " ".join(out)


static func _startup_intro_subject_identity_key(line_text: String) -> String:
	var words: Array = IntroContentSceneSupport._startup_intro_identity_words(line_text)
	if words.is_empty():
		return ""

	var start_index: int = 0
	if str(words [0]) in ["a", "an", "the"]:
		start_index = 1

	if start_index >= words.size():
		return IntroContentSceneSupport._startup_intro_line_opening_key(line_text, 3)

	var take_count: int = min(2, words.size() - start_index)
	var subject_words: Array = []
	for i in range(take_count):
		subject_words.append(str(words [start_index + i]))

	return " ".join(subject_words).strip_edges()


static func _startup_intro_perceptual_integrity_engine(gs: GameState):
	if gs == null:
		return null

	if not "perceptual_integrity_engine" in gs:
		return null

	if gs.perceptual_integrity_engine == null:
		gs.perceptual_integrity_engine = PerceptualIntegrityEngine.new(gs)

	return gs.perceptual_integrity_engine


static func _startup_intro_register_used_moment_identity(gs: GameState,
	moment: Dictionary, used_keys: Dictionary, fallback_phase: String = "") -> void:
	if typeof(moment) != TYPE_DICTIONARY:
		return

	var engine = IntroContentSceneSupport._startup_intro_perceptual_integrity_engine(gs)
	if engine != null and engine.has_method("register_used_moment_identity"):
		engine.register_used_moment_identity(
			moment,
			used_keys,
			IntroContentSceneSupport._startup_intro_perceptual_integrity_context(
				str(moment.get("phase", fallback_phase)),
				int(moment.get("slot_index", -1)),
				0,
				str(moment.get("pool_label", ""))
			)
		)
		return

	var line_text: String = str(moment.get("line", "")).strip_edges()
	var line_key: String = str(moment.get("line_identity_key", IntroContentSceneSupport._startup_intro_line_identity_key(line_text))).strip_edges()
	var opening_key: String = str(moment.get("intro_opening_key", IntroContentSceneSupport._startup_intro_line_opening_key(line_text, 3))).strip_edges()
	var subject_key: String = str(moment.get("subject_identity_key", IntroContentSceneSupport._startup_intro_subject_identity_key(line_text))).strip_edges()
	var event_signature: String = str(moment.get("event_signature", IntroSceneSupport._startup_intro_event_signature_from_line(line_text))).strip_edges()
	var year_key: String = IntroContentSceneSupport._startup_intro_moment_year_identity_key(moment)
	var pool_id: String = str(moment.get("pool_label", "")).strip_edges()
	var phase: String = str(moment.get("phase", fallback_phase)).strip_edges()

	if line_key != "":
		used_keys ["_line_identity:%s" % line_key] = true
		used_keys ["_last_line_identity_key"] = line_key
	if opening_key != "":
		used_keys ["_opening_identity:%s" % opening_key] = true
		used_keys ["_last_opening_key"] = opening_key
	if subject_key != "":
		used_keys ["_subject_identity:%s" % subject_key] = true
		used_keys ["_last_subject_key"] = subject_key
	if event_signature != "":
		used_keys ["_event_signature:%s" % event_signature] = true
	if year_key != "":
		used_keys ["_year_identity:%s" % year_key] = true
		used_keys ["_last_year_key"] = year_key
	if pool_id != "":
		var pool_use_key: String = "_pool_count:%s" % pool_id
		used_keys [pool_use_key] = int(used_keys.get(pool_use_key, 0)) + 1
		used_keys ["_last_pool_id"] = pool_id
	if line_text != "":
		used_keys ["%s|%s|%s" % [
			year_key,
			line_text,
			phase
		]] = true


static func _startup_intro_pool_allowed_for_current_reality(gs: GameState,
	pool_id: String) -> bool:
	var mode: String = IntroSceneSupport._startup_intro_current_reality_mode_tag(gs)
	var clean_pool: String = str(pool_id).strip_edges().to_lower()

	if mode == "chaos":
		return true

	if mode == "enhanced":
		if clean_pool in ["realm_anomalies", "future_mythic_systems"]:
			return true
		return true

	if mode == "realistic":
		if clean_pool.find("bending") >= 0:
			return false
		if clean_pool.find("cosmic") >= 0:
			return false
		if clean_pool.find("realm") >= 0:
			return false
		if clean_pool.find("mythic") >= 0:
			return false
		if clean_pool in ["artifact_discoveries"]:
			return false

	return true


static func _startup_intro_moment_to_beat(moment: Dictionary, timing: Dictionary = {}) -> Dictionary:
	var era_tag: String = str(moment.get("era", "unknown")).strip_edges().to_lower()
	var line_text: String = str(moment.get("line", "The world moved before anyone knew your name."))
	var event_signature: String = str(moment.get("event_signature", IntroSceneSupport._startup_intro_event_signature_from_line(line_text))).strip_edges()
	var line_key: String = str(moment.get("line_identity_key", IntroContentSceneSupport._startup_intro_line_identity_key(line_text))).strip_edges()
	var opening_key: String = str(moment.get("intro_opening_key", IntroContentSceneSupport._startup_intro_line_opening_key(line_text, 3))).strip_edges()
	var subject_key: String = str(moment.get("subject_identity_key", IntroContentSceneSupport._startup_intro_subject_identity_key(line_text))).strip_edges()
	var raw_year_value: int = int(moment.get("year", 1))
	var year_key: String = str(moment.get("year_identity_key", str(raw_year_value))).strip_edges()
	var colors: Dictionary = IntroContentSceneSupport._startup_intro_procedural_color_for_era_tag(era_tag)

	var beat: Dictionary = {
		"year": IntroContentSceneSupport._startup_intro_format_procedural_year(raw_year_value),
		"raw_year": raw_year_value,
		"line": line_text,
		"year_color": colors.get("year_color", Color(1.0, 1.0, 1.0, 1.0)),
		"line_color": colors.get("line_color", Color(1.0, 1.0, 1.0, 1.0)),
		"pitch": float(timing.get("pitch", 1.0)),
		"era_tag": era_tag,
		"pool_label": str(moment.get("pool_label", "unknown")),
		"event_signature": event_signature,
		"line_identity_key": line_key,
		"intro_opening_key": opening_key,
		"subject_identity_key": subject_key,
		"year_identity_key": year_key,
	}

	if timing.has("fade_in"):
		beat ["fade_in"] = float(timing.get("fade_in", 0.2))
	if timing.has("hold"):
		beat ["hold"] = float(timing.get("hold", 0.2))
	if timing.has("fade_out"):
		beat ["fade_out"] = float(timing.get("fade_out", 0.15))

	return beat

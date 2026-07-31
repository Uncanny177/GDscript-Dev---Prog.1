## RoomTemplatesData — All hand-crafted room templates defined here.
## Each room is drawn as ASCII art for readability.

class_name RoomTemplatesData
extends RefCounted


static func get_start_rooms() -> Array[RoomTemplate]:
	var rooms: Array[RoomTemplate] = []
	var r1 := RoomTemplate.new()
	r1.set_from_strings(["###D###","#.....#","#.....#","D.....D","#.....#","#.....#","###D###"], RoomTemplate.RoomType.START, "Start Open")
	rooms.append(r1)
	return rooms


static func get_corridor_rooms() -> Array[RoomTemplate]:
	var rooms: Array[RoomTemplate] = []
	var c1 := RoomTemplate.new()
	c1.set_from_strings(["#####","D...D","#####"], RoomTemplate.RoomType.CORRIDOR, "H-Corridor")
	rooms.append(c1)
	var c2 := RoomTemplate.new()
	c2.set_from_strings(["#D#","#.#","#.#","#.#","#D#"], RoomTemplate.RoomType.CORRIDOR, "V-Corridor")
	rooms.append(c2)
	var c3 := RoomTemplate.new()
	c3.set_from_strings(["##D##","##..#","##..#","D...#","#####"], RoomTemplate.RoomType.CORRIDOR, "L-Bend")
	rooms.append(c3)
	var c4 := RoomTemplate.new()
	c4.set_from_strings(["##D##","#...#","D...D","#...#","#####"], RoomTemplate.RoomType.CORRIDOR, "T-Junction")
	rooms.append(c4)
	return rooms


static func get_small_rooms() -> Array[RoomTemplate]:
	var rooms: Array[RoomTemplate] = []
	var s1 := RoomTemplate.new()
	s1.set_from_strings(["###D###","#.....#","#..E..#","D..E..D","#.....#","#.....#","###D###"], RoomTemplate.RoomType.SMALL, "Enemy Room")
	rooms.append(s1)
	var s2 := RoomTemplate.new()
	s2.set_from_strings(["###D###","#.#.#.#","#.....#","D.#.#.D","#.....#","#.#.#.#","###D###"], RoomTemplate.RoomType.SMALL, "Pillar Room")
	rooms.append(s2)
	var s3 := RoomTemplate.new()
	s3.set_from_strings(["#####D#####","#....#....#","#.E..#..E.#","#....#....#","D.........D","#....#....#","#####D#####"], RoomTemplate.RoomType.SMALL, "Ambush Room")
	rooms.append(s3)
	return rooms


static func get_large_rooms() -> Array[RoomTemplate]:
	var rooms: Array[RoomTemplate] = []
	var l1 := RoomTemplate.new()
	l1.set_from_strings(["####D####","#.......#","#.......#","#..E.E..#","D.......D","#..E.E..#","#.......#","#.......#","####D####"], RoomTemplate.RoomType.LARGE, "Arena")
	rooms.append(l1)
	var l2 := RoomTemplate.new()
	l2.set_from_strings(["####D####","#.......#","#.......#","#...?...#","D.......D","#.......#","#.......#","####D####"], RoomTemplate.RoomType.LARGE, "Event Hall")
	rooms.append(l2)
	return rooms


static func get_treasure_rooms() -> Array[RoomTemplate]:
	var rooms: Array[RoomTemplate] = []
	var t1 := RoomTemplate.new()
	t1.set_from_strings(["#####","#.C.#","#...#","##D##"], RoomTemplate.RoomType.TREASURE, "Treasure Alcove")
	rooms.append(t1)
	var t2 := RoomTemplate.new()
	t2.set_from_strings(["#######","#..C..#","#.###.#","#.....#","###D###"], RoomTemplate.RoomType.TREASURE, "Guarded Chest")
	rooms.append(t2)
	return rooms


static func get_exit_rooms() -> Array[RoomTemplate]:
	var rooms: Array[RoomTemplate] = []
	var e1 := RoomTemplate.new()
	e1.set_from_strings(["#######","#..?..#","#.....#","#.....#","###D###"], RoomTemplate.RoomType.EXIT, "Exit Chamber")
	rooms.append(e1)
	return rooms


static func get_boss_rooms() -> Array[RoomTemplate]:
	var rooms: Array[RoomTemplate] = []
	var b1 := RoomTemplate.new()
	b1.set_from_strings(["###########","#.........#","#.........#","#....E....#","#.........#","#.........#","#.........#","#####D#####"], RoomTemplate.RoomType.BOSS, "Boss Arena")
	rooms.append(b1)
	return rooms

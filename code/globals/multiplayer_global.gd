## Storing server-sided and general multiplayer data stuff
extends Node

const PACKED_SPLIT_TAG : float = -999.0

## id pool to assign everything on the server, to ensure the ids are unique and making objects persist instead of creating one each time 
var id_pool : int = 0

## return id and increment by one, anything can call this without problems (not sure about race conditions tho)
func get_id() -> int:
	id_pool += 1
	return id_pool

## Storing server-sided and general multiplayer data stuff
extends Node

## Hardcoding the server address temporarily, will change later when it scale to multiple servers
const SERVER_ADDRESS : String = "192.168.1.111"

## Port for the network connection
const NETWORK_PORT_MIN : int = 56000

const NETWORK_PORT_MAX : int = 57000

const MM_PORT : int = 55144

const MM_URL : String = "192.168.1.111"

const PACKED_SPLIT_TAG : float = -999.0

## IMPORTANT: region is defines as such: EU, NA, AS, SA, AF, OC
var server_region : String

## Syntax: Just the map name like "desolation" or "rebirth"
var server_map : String

var server_port : int

## id pool to assign everything on the server, to ensure the ids are unique and making objects persist instead of creating one each time 
var id_pool : int = 0

## return id and increment by one, anything can call this without problems (not sure about race conditions tho)
func get_id() -> int:
	id_pool += 1
	return id_pool

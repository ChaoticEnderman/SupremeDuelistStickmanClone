## Abstract class for connecting and sending data
class_name UDPConnector
extends PacketPeerUDP

const server_ip : String = "1.1.1.1"

func _ready():
	connect_server()

func connect_server():
	self.bind(Globals.NETWORK_PORT)
	
	self.set_dest_address(server_ip, Globals.NETWORK_PORT)
	self.put_packet("hello".to_utf8_buffer()) 

func _process(_delta):
	if self.get_available_packet_count() > 0:
		var array_bytes = self.get_packet()
		var packet_string = array_bytes.get_string_from_ascii()
		print("UDP/received message: ", packet_string)

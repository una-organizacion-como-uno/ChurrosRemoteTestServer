extends Node2D


const port : int = 0x4348  # "CH"

var server := UDPServer.new()
var peers = []

var data = {
	"global": {
		"size" : 1,
		"speed" : 0.5,
		},
	"games" : {
		0 : {},
	}
}  # Mockup data

#const Response = NetAPI.Response #GDscript bug
const Commands = NetAPI.Commands
const Responses = NetAPI.Responses
const COMMAND_INFO = NetAPI.COMMAND_INFO

func _ready():
	server.listen(port)

func _exit_tree():
	server.stop()

func _process(delta):
	server.poll() # Important!
	if server.is_connection_available():
		var peer : PacketPeerUDP = server.take_connection()
		print("Accepted peer: %s:%s" % [peer.get_packet_ip(), peer.get_packet_port()])
		# Keep a reference so we can keep contacting the remote peer.
		peers.append(peer)

	for peer in peers:
		_poll_peer(peer)
		

func _poll_peer( peer : PacketPeerUDP ):
	if peer.get_available_packet_count():
		var command = peer.get_var()
		_parse_command(peer, command)

func _parse_command(peer : PacketPeerUDP, command : Array ):
	# CHECK INVALID PACKET
	if typeof(command) != TYPE_ARRAY:
		_error(peer, Responses.INVALID_DATA, "Received %s" % command)
		return
	
	# CHECK INVALID COMMAND
	var command_name = command.pop_front()
	var params = command
	if not COMMAND_INFO.has(command_name):
		_error(peer, Responses.INVALID_COMMAND, "Command %s doesn't exist" % command_name )
		return
	
	# CHECK WRONG PARAM COUNT
	var info = COMMAND_INFO[command_name]
	if not info.parameters.size() == params.size():
		_error(peer, Responses.INCORRECT_PARAM_COUNT, "Received %s argumentes, expected %s" % [params.size(), info.parameters.size()] )
		return
	
	# CHECK WRONG PARAM TYPE
	for i in params.size():
		if info.parameters[i].has("type"):
			var param_type = info.parameters[i].type
			if typeof(params[i]) != param_type:
				_error(peer, Responses.INCORRECT_PARAM_TYPE, "Received %s, expected %s" % [params[i], param_type])
				return
	
	# CHECKS OK. CALL HANDLER
	var response : NetAPI.Response
	match command_name:
		Commands.GLOBAL_PARAM_LIST: 
			response = _global_param_list()
		Commands.GLOBAL_PARAM_GET:
			response =  _global_param_get(params[0])
		Commands.GLOBAL_PARAM_SET:
			response = _global_param_set(params[0], params[1])
		Commands.GAMES_LIST:
			response = _games_list()
		Commands.GAME_PARAM_LIST:
			response = _game_param_list(params[0])
		Commands.GAME_PARAM_GET:
			response = _game_param_get(params[0], params[1])
		Commands.GAME_PARAM_SET:
			response = _game_param_set(params[0], params[1], params[2])
		_:
			_error(peer, Responses.BUG, "Unknown bug")
			return
	
	# SEND RESPONSE TO PEER
	peer.put_var(response.as_array())

func _error(peer : PacketPeerUDP, error_type : int = Responses.BUG , error_text := "" ):
	peer.put_var(NetAPI.Response.new(error_type, { "message" : error_text }).as_array())

## COMMAND HANDLERS

func _global_param_list():
	
	pass
	
func _global_param_get( key : String):
	if data.global.has(key):
		var response_data = {}
		response_data["event"] = "global_param_changed"
		response_data["param"] = { key : data.global[key] }
		print_debug("got param %s" % [response_data])
		return NetAPI.Response.new(Responses.OK, response_data)
	
func _global_param_set( key : String, value ):
	if data.global.has(key):
		data.global[key] = value
		print_debug("set param %s" % [{key : value}])
		return _global_param_get(key)

	
func _game_param_list( game : int ):
	pass
	
func _game_param_get( game : int, key : String ):
	pass
	
func _game_param_set( game : int, key : String, value ):
	pass
	
func _games_list():
	pass

extends Node


const port : int = 0x4348  # "CH"

var server := TCP_Server.new()
var peers = []

var data = {
	"global":{
		"property_list": []
		
	},
}  # Mockup data


const TypeEnumToString = {
	TYPE_NIL : "null",
	TYPE_BOOL : "bool",
	TYPE_INT : "int",
	TYPE_REAL : "float",
	TYPE_STRING : "String",
	TYPE_VECTOR2 : "Vector2",
	TYPE_RECT2 : "Rect2",
	TYPE_VECTOR3 : "Vector3",
	TYPE_TRANSFORM2D : "Transform2D",
	TYPE_PLANE : "Plane",
	TYPE_QUAT : "Quat",
	TYPE_AABB : "AABB",
	TYPE_TRANSFORM : "Transform",
	TYPE_COLOR : "Color",
	TYPE_NODE_PATH : "NodePath",
	TYPE_RID : "RID",
	TYPE_OBJECT : "Object",
	TYPE_DICTIONARY : "Dictionary",
	TYPE_ARRAY : "Array",
	TYPE_RAW_ARRAY : "PoolByteArray",
	TYPE_INT_ARRAY : "PoolIntArray",
	TYPE_REAL_ARRAY : "PoolRealArray",
	TYPE_STRING_ARRAY : "PoolStringArray",
	TYPE_VECTOR2_ARRAY : "PoolVector2Array",
	TYPE_VECTOR3_ARRAY : "PoolVector3Array",
	TYPE_COLOR_ARRAY : "PoolColorArray",
}


#const Response = NetAPI.Response #GDscript bug
const Commands = NetAPI.Commands
const Responses = NetAPI.Responses
const COMMAND_INFO = NetAPI.COMMAND_INFO

func _ready():
	server.listen(port)

func _exit_tree():
	server.stop()

func _process(delta):
	#server.poll() # Important!
	if server.is_connection_available():
		var peer : StreamPeerTCP = server.take_connection()
		print("Accepted peer: %s:%s" % [peer.get_connected_host(), peer.get_connected_port()])
		# Keep a reference so we can keep contacting the remote peer.
		peers.append(peer)

	for peer in peers:
		_poll_peer(peer)
		

func _poll_peer( peer : StreamPeerTCP ):
	if peer.get_available_bytes():
		var command = peer.get_var()
		_parse_command(peer, command)

func _parse_command(peer : StreamPeerTCP, command ):
	# CHECK INVALID PACKET
	if typeof(command) != TYPE_ARRAY:
		peer.put_var(_error(Responses.INVALID_DATA, "Received %s" % command).as_array())
		return
	
	# CHECK INVALID COMMAND
	var command_name = command.pop_front()
	var params = command
	if not COMMAND_INFO.has(command_name):
		peer.put_var(_error(Responses.INVALID_COMMAND, "Command %s doesn't exist" % command_name ).as_array())
		return
	
	# CHECK WRONG PARAM COUNT
	var info = COMMAND_INFO[command_name]
	if not info.parameters.size() == params.size():
		peer.put_var(_error(Responses.INCORRECT_PARAM_COUNT, "Received %s argumentes, expected %s" % [params.size(), info.parameters.size()] ).as_array())
		return
	
	# CHECK WRONG PARAM TYPE
	for i in params.size():
		if info.parameters[i].has("type"):
			var param_type = info.parameters[i].type
			if typeof(params[i]) != param_type:
				peer.put_var(_error(Responses.INCORRECT_PARAM_TYPE, "Received %s, expected %s" % [params[i], param_type]))
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
			response = _error(Responses.BUG, "Unknown bug")
	
	# SEND RESPONSE TO PEER
	if !response:
		response = _error(Responses.BUG, "Unknown bug")
	peer.put_var(response.as_array())

func _error(error_type : int = Responses.BUG , error_text := "" ):
	printerr(error_text)
	return NetAPI.Response.new(error_type, { "message" : error_text })

## COMMAND HANDLERS

func _global_param_list():
	var response_data = {}
	response_data["event"] = "global_param_list_ready"
	response_data["list"] = data.global.property_list
	print_debug("sending property list:  %s" % response_data)
	return NetAPI.Response.new(Responses.OK, response_data)

	
func _global_param_get( key : String):
	if data.global.has(key):
		var response_data = {}
		response_data["event"] = "global_param_changed"
		response_data["param"] = [key, data.global[key]]
		print_debug("got param %s" % [response_data])
		return NetAPI.Response.new(Responses.OK, response_data)
	else:
		return _error(Responses.ERROR, "Global param key not found: %s" % key)
	
func _global_param_set( key : String, value ):
	if data.global.has(key):
		data.global[key] = value
		print_debug("set param %s" % [{key : value}])
		return _global_param_get(key)
	else:
		return _error(Responses.ERROR, "Global param key not found: %s" % key)

	
func _game_param_list( game : int ):
	pass
	
func _game_param_get( game : int, key : String ):
	pass
	
func _game_param_set( game : int, key : String, value ):
	pass
	
func _games_list():
	pass


func register_properties( node : Node ):
	var props = node.get_property_list()
	for prop in props:
		if prop.name.begins_with("param_"):
			data.global.property_list.append(prop)
			data.global[prop.name] = node.get(prop.name)
	print_debug(data)

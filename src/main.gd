extends Node2D

# réseau
var peer = ENetMultiplayerPeer.new()
var hostname = "localhost"
var port = 11234

# état du jeu
var host_text = ""
var host_morse = ""
var client_answer = []
# JF : on le mets a "true" car nous ne voulons pas
# utilise les son si jamais nous n'avons pas commencer une partie
var game_over = true

# ===== GAME LOOP =====
func _physics_process(_delta):
	if peer.get_connection_status() == 2 && !game_over:
		if (Input.is_action_just_pressed("ui_dot")): # fléche UP, point
			# jouer un son à J1
			_play_dot_on_server.rpc()
			pass
		elif (Input.is_action_just_pressed("ui_dash")): # fléche DOWN, trait d'union
			# jouer un son à J1
			_play_dash_on_server.rpc()
			pass
	# Note: Vous pouvez jouer le même son avec différentes durées pour le point (plus courte) et pour le trait d'union (plus longue), ou jouer des sons distincts.

# ===== EVÉNEMENTS INTERFACE =====
func _on_host_pressed():
	peer.create_server(port, 2)
	multiplayer.multiplayer_peer = peer
	
	
	# montrer l'interface host
	$SendText.show()
	$MainMenu.hide()
	
func _on_join_pressed():
	var response = peer.create_client(hostname, port)
	multiplayer.multiplayer_peer = peer
	$Sound/Login.play()
	
	# montrer l'interface client
	$ReceiveText.show()
	$MainMenu.hide()
	
func _on_btn_send_pressed():
	# à chaque fois que J1 envoye une message, le jeu est redémarré
	client_answer = []
	game_over = false
	host_text = $SendText/TextEdit.get_text()
	
	# chiffrer la message comme réference
	host_morse = get_morse_from_string(host_text)
	$SendText/AnswerPreview.set_text(host_morse)
	$Sound/Start.play()
	
	# envoyer la message à J2
	var isFabio = false
	if (host_text.to_upper() == "FABIO" or host_text.to_upper() == "FABIO PETRILLO" or host_text.to_upper() == "PETRILLO"):
		isFabio = true
	_show_text_on_client.rpc(host_text, isFabio)
	pass

# ===== LOGIQUE DU JEU =====
func get_morse_from_string(text: String) -> String:
	var morse_code = {
		'A': '.-', 'B': '-...', 'C': '-.-.', 'D': '-..', 'E': '.', 'F': '..-.', 'G': '--.', 'H': '....',
		'I': '..', 'J': '.---', 'K': '-.-', 'L': '.-..', 'M': '--', 'N': '-.', 'O': '---', 'P': '.--.',
		'Q': '--.-', 'R': '.-.', 'S': '...', 'T': '-', 'U': '..-', 'V': '...-', 'W': '.--', 'X': '-..-',
		'Y': '-.--', 'Z': '--..', '1': '.----', '2': '..---', '3': '...--', '4': '....-', '5': '.....',
		'6': '-....', '7': '--...', '8': '---..', '9': '----.', '0': '-----', ' ': '/'
	}
	
	var morse_text = []
	
	for aChar in text.to_upper():
		if aChar in morse_code:
			morse_text.append(morse_code[aChar])
	
	return "".join(morse_text)
	
func check_victory():
	#  Joueur 1 vérifie si la séquence reçue jusqu'à ce point correspond au message initial.
	if client_answer.size() == host_morse.length():
		game_over = true
		for i in client_answer.size():
			if client_answer[i] != host_morse[i]:
				_play_end_game_on_client.rpc(false)
				return
		_play_end_game_on_client.rpc(true)
	pass

# ===== MÉTHODES RPC =====
@rpc("authority", "call_remote", "reliable")
func _show_text_on_client(text, isFabio):
	# envoyer et montrer le texte à J2
	# et preparer client
	game_over = false
	if isFabio:
		$FabioProfilePicture.show()
		$LabelFabio.show()
	else:
		$FabioProfilePicture.hide()
		$LabelFabio.hide()
	$ReceiveText/Label.set_text("Message reçu:")
	$ReceiveText/TextDisplay.set_text(text)
	
@rpc("any_peer", "call_remote", "reliable")
func _play_dot_on_server():
	# cette méthode sera appelé par J2
	if (!game_over):
		# jouer le beep à J1
		$Sound/Dot.play()
		client_answer.append(".")
		check_victory()
	
@rpc("any_peer", "call_remote", "reliable")
func _play_dash_on_server():
	# cette méthode sera appelé par J2
	if (!game_over):
		# jouer le beep à J1
		$Sound/Dash.play()
		client_answer.append("-")
		check_victory()
	
	
@rpc("authority", "call_remote", "reliable")
func _play_end_game_on_client(isWin):
	# cette méthode sera appelé par J2
	$ReceiveText/TextDisplay.set_text("")
	if isWin:
		$ReceiveText/Label.set_text("Congratulation :)")
		$Sound/Win.play()
	else:
		$ReceiveText/Label.set_text("Game Over :(")
		$Sound/GameOver.play()	





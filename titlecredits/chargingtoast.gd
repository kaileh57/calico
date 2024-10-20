extends CanvasLayer

@onready var animation_player = $ColorRect/AnimationPlayer

# Called when the node enters the scene tree for the first time.
func _ready():
	var rawoutput = []
	var output : String
	OS.execute("cmd.exe", ["/c", "WMIC Path Win32_Battery Get BatteryStatus"], rawoutput)
	for line in rawoutput:
		line = line.strip_edges().replace("\r", "").replace("\n", "").replace(" ", "")
		if line != "":
			output = output + line
	if output == "BatteryStatus1":
		animation_player.play("toast")

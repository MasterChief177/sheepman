extends Node3D

signal pickedup  # Korrigierter Signalname

@onready var area = $Taschenlampe

func _ready():
	# Verbinden der Signale korrekt
	area.connect("body_entered", Callable(self, "_on_body_entered"))
	area.connect("body_exited", Callable(self, "_on_body_exited"))

func _on_area_entered(body):
	if body.is_in_group("player"):
		body.set("pickup_in_range", self)  # Informiert den Spieler, dass ein Objekt in Reichweite ist

func _on_area_exited(body):
	if body.is_in_group("player"):
		body.set("pickup_in_range", null)  # Informiert den Spieler, dass das Objekt nicht mehr in Reichweite ist

func pickup():
	emit_signal("picked_up")
	queue_free()

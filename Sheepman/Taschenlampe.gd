extends Node3D

signal picked_up  # Korrigierter Signalname

@onready var area = $Taschenlampe

func _ready():
	# Verbinden der Signale korrekt
	area.connect("area_entered", Callable(self, "_on_area_entered"))
	area.connect("area_exited", Callable(self, "_on_area_exited"))

func _on_area_entered(overlapping_area):
	if overlapping_area.is_in_group("player"):
		overlapping_area.set("pickup_in_range", self)  # Informiert den Spieler, dass ein Objekt in Reichweite ist

func _on_area_exited(overlapping_area):
	if overlapping_area.is_in_group("player"):
		overlapping_area.set("pickup_in_range", null)  # Informiert den Spieler, dass das Objekt nicht mehr in Reichweite ist

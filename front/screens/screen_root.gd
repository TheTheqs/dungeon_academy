extends Control

class_name ScreenRoot

@onready var screen_host: Control = $ScreenHost

func show_screen(screen: Control) -> void:
	assert(screen != null, "ScreenRoot requires a valid screen.")
	clear_screen()
	screen_host.add_child(screen)

func clear_screen() -> void:
	for child in screen_host.get_children():
		# Detach now; release the old screen safely at the end of the frame.
		screen_host.remove_child(child)
		child.queue_free()

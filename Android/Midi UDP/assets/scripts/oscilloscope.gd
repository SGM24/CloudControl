extends Line2D

@export var bus_name: String = "Master"
@export var amplitude: float = 400.0
@export var buffer_size: int = 250 
@export var trigger_threshold: float = 0.01
@export var x_scale: float = 1.0 

var effect: AudioEffectCapture
var bus_index: int
var accumulator: PackedVector2Array = [] # Para guardar audio entre frames

func _ready():
	bus_index = AudioServer.get_bus_index(bus_name)
	effect = AudioServer.get_bus_effect(bus_index, 0)
	
	points = []
	for i in range(buffer_size):
		add_point(Vector2(i * (800.0 / buffer_size), 0))

func _process(_delta):
	if not effect: return
	
	# 1. Acumulamos lo que haya llegado nuevo
	var new_data = effect.get_buffer(effect.get_frames_available())
	accumulator.append_array(new_data)
	
	# Limitamos el tamaño del acumulador para que no crezca infinitamente (ej. 4000 muestras)
	if accumulator.size() > 4000:
		accumulator = accumulator.slice(accumulator.size() - 4000)

	var needed_samples = int(buffer_size * x_scale)
	
	# 2. Si no tenemos suficiente para el zoom actual, esperamos
	if accumulator.size() < needed_samples: 
		return

	# 3. Lógica de Triggering (sobre el acumulador)
	var trigger_index = 0
	var search_range = accumulator.size() - needed_samples
	
	# Buscamos el cruce por cero (Zero-crossing)
	for i in range(1, search_range):
		var val_prev = (accumulator[i-1].x + accumulator[i-1].y) / 2.0
		var val_curr = (accumulator[i].x + accumulator[i].y) / 2.0
		
		if val_prev <= 0 and val_curr > 0 and val_curr > trigger_threshold:
			trigger_index = i
			break 
	
	# 4. Dibujo
	for i in range(buffer_size):
		var sample_idx = trigger_index + int(i * x_scale)
		
		if sample_idx < accumulator.size():
			var sample = accumulator[sample_idx]
			var value = (sample.x + sample.y) / 2.0
			set_point_position(i, Vector2(i * (800.0 / buffer_size), value * amplitude))

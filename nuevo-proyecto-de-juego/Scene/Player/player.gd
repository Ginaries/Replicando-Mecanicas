extends CharacterBody2D

const MAX_SPEED = 2000
const ACCELERATION = 1000
const DECELERATION = 800
const AIR_ACCEL = 400
const GRAVITY = 1200
const JUMP_GRAVITY = 800  # Más suave al subir
const FALL_GRAVITY = 1600  # Más fuerte al caer
const JUMP_FORCE = -500
const SPINDASH_SPEED = 4000
const MIN_ROLL_SPEED = 20  # Si baja de esto, se cancela el roll

var direction = 0
var on_ground = false
var is_rolling = false
var charging_spin = false
var last_facing = 1  # 1 = derecha, -1 = izquierda

@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _physics_process(delta):
	on_ground = is_on_floor()
	direction = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")

	# Guardamos la última dirección para disparar el spin
	if direction != 0:
		last_facing = sign(direction)
		anim_sprite.flip_h = direction < 0

	# ----------------
	# SPINDASH INPUTS
	# ----------------

	if on_ground and Input.is_action_pressed("ui_down") and Input.is_action_pressed("slide") and is_rolling==false:
		charging_spin = true
		is_rolling = false
		velocity.x = 0  # Detenido mientras carga

	# Disparo del spin
	if charging_spin and Input.is_action_just_released("slide"):
		charging_spin = false
		is_rolling = true
		velocity.x = last_facing * SPINDASH_SPEED

# ---------------------
# MOVIMIENTO HORIZONTAL (progresivo como Sonic)
# ---------------------
	if not charging_spin and not is_rolling:
		if direction != 0:
			var accel = ACCELERATION if on_ground else AIR_ACCEL
			velocity.x += direction * accel * delta

		# Dirección contraria = frenado más brusco
		if sign(velocity.x) != sign(direction):
			velocity.x = move_toward(velocity.x, direction * MAX_SPEED, DECELERATION * delta)

		# 👇 Tope de velocidad máxima
		if abs(velocity.x) > MAX_SPEED:
			velocity.x = sign(velocity.x) * MAX_SPEED

	else:
		if on_ground:
			velocity.x = move_toward(velocity.x, 0, DECELERATION * delta)


	# ---------------------
	# CANCELAR ROLLING
	# ---------------------
	if is_rolling:
	# Saltar en rolling cancela el estado pero mantiene velocidad
		if Input.is_action_just_pressed("ui_accept"):
			is_rolling = false
			velocity.y = JUMP_FORCE

	# Cambiar de dirección bruscamente cancela el rolling
		elif direction != 0 and sign(direction) != sign(velocity.x):
			is_rolling = false
			# Simula un derrape y frena más fuerte
			velocity.x = move_toward(velocity.x, 0, DECELERATION * 2 * delta)

	# Si frena mucho en el piso, cancelar también
		elif on_ground and abs(velocity.x) < MIN_ROLL_SPEED:
			is_rolling = false

	# ---------------------
	# SALTO NORMAL
	# ---------------------
	elif on_ground and Input.is_action_just_pressed("ui_accept") and not charging_spin:
		velocity.y = JUMP_FORCE

	# Salto más corto si se suelta el botón rápido
	elif velocity.y < 0 and Input.is_action_just_released("ui_accept"):
		velocity.y *= 0.5


	# ---------------------
	# GRAVEDAD
	# ---------------------
	if velocity.y < 0:
		velocity.y += JUMP_GRAVITY * delta  # Ascenso
	else:
		velocity.y += FALL_GRAVITY * delta  # Caída


	# ---------------------
	# MOVER PERSONAJE
	# ---------------------
	move_and_slide()

	# ---------------------
	# ANIMACIONES
	# ---------------------
	_update_animation()

func _update_animation():
	if not on_ground:
		if velocity.y < 0:
			anim_sprite.play("jump")
		else:
			anim_sprite.play("fall")
	elif charging_spin:
		anim_sprite.play("roll1")  # animación de carga
	elif is_rolling:
		anim_sprite.play("roll2")  # animación de bola rodando
	elif abs(velocity.x) < 10:
		anim_sprite.play("idle")
	elif abs(velocity.x) < MAX_SPEED:
		anim_sprite.play("walk")
	else:
		anim_sprite.play("run")

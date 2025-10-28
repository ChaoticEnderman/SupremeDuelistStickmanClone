extends RefCounted

const LINEAR_DAMP := 5.0
const ANGULAR_DAMP := 7.0

const MOVE_FORCE : float = 5000.0
const JUMP_FORCE : float = 200000.0
const UPRIGHT_TORQUE_FORCE : float = 500.0

const JUMP_TIME : int = 60

static func angle_to_360(angle_degree: float) -> float:
	if angle_degree < 0.0:
		angle_degree += 360.0
	return angle_degree

static func angle_to_180(angle_degree: float) -> float:
	if angle_degree > 180.0:
		angle_degree -= 360.0
	return angle_degree

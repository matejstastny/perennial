extends Control

var time = 1000.0

func _process(delta: float) -> void:
	time += delta
	var water_mat: ShaderMaterial = $Water.material
	var land_mat: ShaderMaterial = $Land.material
	var cloud_mat: ShaderMaterial = $Cloud.material

	var water_mult = (round(water_mat.get_shader_parameter("size")) * 2.0) / water_mat.get_shader_parameter("time_speed")
	var land_mult = (round(land_mat.get_shader_parameter("size")) * 2.0) / land_mat.get_shader_parameter("time_speed")
	var cloud_mult = (round(cloud_mat.get_shader_parameter("size")) * 2.0) / cloud_mat.get_shader_parameter("time_speed")

	water_mat.set_shader_parameter("time", time * water_mult * 0.02)
	land_mat.set_shader_parameter("time", time * land_mult * 0.02)
	cloud_mat.set_shader_parameter("time", time * cloud_mult * 0.01)

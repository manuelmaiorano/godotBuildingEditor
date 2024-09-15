extends Node
class_name Triangulation

static func get_polygon_internal_angle(p1: Vector2, p2: Vector2):
	return rad_to_deg(p1.angle_to(p2))
	return (PI + atan2(p1.cross(p2), p1.dot(p2)))* (180/PI)

static func area(x1, y1, x2, y2, x3, y3):
	return abs((x1 * (y2 - y3) + x2 * (y3 - y1) + x3 * (y1 - y2)) / 2.0)
	
static func is_point_inside_triangle(triangle, point):
	var A = triangle[0]
	var B = triangle[1]
	var C = triangle[2]
	var P = point

	var Area1 = area(A.x, A.y, B.x, B.y, C.x, C.y)
	var Area2 = area(P.x, P.y, B.x, B.y, C.x, C.y)
	var Area3 = area(A.x, A.y, P.x, P.y, C.x, C.y)
	var Area4 = area(A.x, A.y, B.x, B.y, P.x, P.y)

	return Area1 == Area2 + Area3 + Area4
	
static func triangulate(polygon: PackedVector2Array):

	var final_triangles = []
	var vertices = []
	for v in polygon:
		vertices.append(v)
	var original_vertices = polygon
	var triangles_finded = -1
	
	# While there are triangles to be found
	while(triangles_finded != 0): 
		triangles_finded = 0

		for index in vertices.size():
			var prev_vertice = vertices[index - 1]
			var next_vertice = vertices[(index + 1) % (vertices.size())] # using mod to avoid index out of range
			var vertice = vertices[index]
			
			# Get Vector from prev_vertice to vertice
			#var vector1 = Vector2(vertice[0] - prev_vertice[0], vertice[1] - prev_vertice[1])
			var vector1 = vertice - prev_vertice
			# Get Vector from vertice to next_vertice
			#var vector2 = Vector2(next_vertice[0] - vertice[0], next_vertice[1] - vertice[1])
			var vector2 = next_vertice - vertice
			# Get internal angle
			var angle = get_polygon_internal_angle(vector1, vector2)
			
			if angle < 0:
				angle += 360
			
			print("angle %d" % angle)
			if angle >= 180:
				# Skip because angle is greater than 180
				continue
			else:
				# Build a triangle with the three vertices
				var triangle = [prev_vertice, vertice, next_vertice]
				# Get vertices that are not part of the triangle
				var points = []
				for p in original_vertices:
					if not triangle.has(p):
						points.append(p)
				# Check if there is a vertice inside the triangle
				var inside_evaluation = []
				for point in points:
					inside_evaluation.append(is_point_inside_triangle(triangle, point))
				# If are not points inside the triangle
				if inside_evaluation.has(true):
					# Skip because point is inside triangle
					continue
				else:
					# Add triangle to final triangles
					final_triangles.append(triangle)
					# Remove vertice from vertices
					vertices.pop_at(index)
					# Increment triangles finded
					triangles_finded += 1
					break
	print("triangles")
	print(final_triangles)
	return final_triangles

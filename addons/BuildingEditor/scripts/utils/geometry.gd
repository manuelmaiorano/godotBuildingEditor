@tool
extends EditorScript
class_name GEOMETRY_UTILS

# Function to check if a point (px, py) is inside a polygon defined by vertices
static func is_point_in_polygon(point: Vector2, polygon: Array) -> bool:
	var n = polygon.size()
	var intersections = 0
	var p1 = polygon[0]
	
	# Loop through each edge of the polygon
	for i in range(n + 1):
		var p2 = polygon[i % n]
		
		# Check if the point is exactly on the edge of the polygon
		if point.is_equal_approx(p1):
			return false  # Point is exactly a vertex of the polygon
		
		#TODO: return false if exaxtly on edge
		if isBetween(point, p1, p2):
			return false
		
		# Check if the ray intersects the edge of the polygon
		if ((point.y > min(p1.y, p2.y)) and (point.y <= max(p1.y, p2.y)) and
			(point.x <= max(p1.x, p2.x)) and (p1.y != p2.y)):
			
			var xinters = (point.y - p1.y) * (p2.x - p1.x) / (p2.y - p1.y) + p1.x
			if p1.x == p2.x or point.x <= xinters:
				intersections += 1
		
		p1 = p2

	# If the number of intersections is odd, the point is inside
	return (intersections % 2 != 0)

static func isBetween(point: Vector2, p1: Vector2, p2: Vector2):
	if is_equal_approx(point.distance_to(p1) + point.distance_to(p2), p1.distance_to(p2)):
		return true

	return false

static func isClockwise(points: Array[Vector2]):
	var sum = 0
	for idx in points.size():
		var p1 = points[idx]
		var p2 = points[(idx+1)%points.size()]

		sum += (p2.x -p1.x)*(p1.y + p2.y)

	return sum > 0

# Check if a point is inside a polygon using the Ray-Casting algorithm
static func is_point_in_polygon2(point: Vector2, polygon: Array) -> bool:
	var n = polygon.size()
	var intersections = 0
	var p1 = polygon[0]
	
	# Loop through each edge of the polygon
	for i in range(n + 1):
		var p2 = polygon[i % n]
		
		# Check if the point is exactly on the edge of the polygon
		if point.is_equal_approx(p1):
			return true
		
		# Check if the ray intersects the edge of the polygon
		if ((point.y > min(p1.y, p2.y)) and (point.y <= max(p1.y, p2.y)) and
			(point.x <= max(p1.x, p2.x)) and (p1.y != p2.y)):
			
			var xinters = (point.y - p1.y) * (p2.x - p1.x) / (p2.y - p1.y) + p1.x
			if p1.x == p2.x or point.x <= xinters:
				intersections += 1
		
		p1 = p2

	# If the number of intersections is odd, the point is inside
	return (intersections % 2 != 0)

static func orientation(a: Vector2, b: Vector2, c: Vector2) -> int:
		var val = (b.y - a.y) * (c.x - b.x) - (b.x - a.x) * (c.y - b.y)
		if val == 0:
			return 0  # Collinear
		return 1 if val > 0 else 2  # Clockwise or Counterclockwise

static func on_segment(p: Vector2, q: Vector2, r: Vector2) -> bool:
	return min(p.x, r.x) <= q.x and q.x <= max(p.x, r.x) and min(p.y, r.y) <= q.y and q.y <= max(p.y, r.y)


# Check if two line segments intersect
static func do_lines_intersect(p1: Vector2, p2: Vector2, q1: Vector2, q2: Vector2) -> bool:
	# Helper function to determine orientation of three points (clockwise, counterclockwise, or collinear)
	

	# Helper function to check if a point c lies on the segment ab
	

	# Find the four orientations needed for the general and special cases
	var o1 = orientation(p1, p2, q1)
	var o2 = orientation(p1, p2, q2)
	var o3 = orientation(q1, q2, p1)
	var o4 = orientation(q1, q2, p2)

	# General case: If orientations differ, the segments intersect
	if o1 != o2 and o3 != o4:
		return true

	if isBetween(p1, q1, q2) and isBetween(p2, q1, q2):
		return false 
	if isBetween(q1, p1, p2) and isBetween(q2, p1, p2):
		return false

	# Special cases: collinear points
	if o1 == 0 and on_segment(p1, p2, q1):
		return true
	if o2 == 0 and on_segment(p1, p2, q2):
		return true
	if o3 == 0 and on_segment(q1, q2, p1):
		return true
	if o4 == 0 and on_segment(q1, q2, p2):
		return true

	return false

# Main function to check if one polygon is inside another
static func is_polygon_inside(outer_polygon: Array, inner_polygon: Array) -> bool:
	# Step 1: Check if all vertices of the inner polygon are inside the outer polygon
	for vertex in inner_polygon:
		if not is_point_in_polygon2(vertex, outer_polygon):
			return false

	# Step 2: Check if any edges of the inner polygon intersect with any edges of the outer polygon
	for i in range(inner_polygon.size()):
		var p1 = inner_polygon[i]
		var p2 = inner_polygon[(i + 1) % inner_polygon.size()]
		
		for j in range(outer_polygon.size()):
			var q1 = outer_polygon[j]
			var q2 = outer_polygon[(j + 1) % outer_polygon.size()]
			
			if do_lines_intersect(p1, p2, q1, q2):
				return false

	return true



# Example usage
func _run():
	# Define a polygon as a list of vertices (clockwise or counterclockwise)
	var polygon = [
		Vector2(1, 1),
		Vector2(5, 1),
		Vector2(5, 3),
		Vector2(4, 3),
		Vector2(3, 2),
		Vector2(2, 3),
		Vector2(1, 3),
	]

	# Test points
	var point1 = Vector2(3, 3)  # Inside the polygon
	var point2 = Vector2(6, 3)  # Outside the polygon

	#print("Point1 inside polygon: ", is_point_in_polygon(point1, polygon))  # Expected: true
	#print("Point2 inside polygon: ", is_point_in_polygon(point2, polygon))  # Expected: false

	var outer_polygon = [Vector2(0, 0), Vector2(10, 0), Vector2(10, 10), Vector2(0, 10)]
	var inner_polygon = [Vector2(2, 2), Vector2(8, 2), Vector2(8, 8), Vector2(2, 8)]
	
	outer_polygon = [Vector2(0, 0), Vector2(0, 2), Vector2(2, 2), Vector2(2, 0)]
	inner_polygon = [Vector2(0, 0), Vector2(0, 1), Vector2(1, 1), Vector2(1, 0)]

	var result = is_polygon_inside(outer_polygon, inner_polygon)
	#print(result)  # Output: True if inner polygon is inside the outer polygon

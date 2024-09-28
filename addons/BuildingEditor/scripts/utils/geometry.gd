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

	print("Point1 inside polygon: ", is_point_in_polygon(point1, polygon))  # Expected: true
	print("Point2 inside polygon: ", is_point_in_polygon(point2, polygon))  # Expected: false

@tool
extends Button
class_name AssetBtn

func set_data(asset_name, thumbnail):
	icon = thumbnail
	text = asset_name

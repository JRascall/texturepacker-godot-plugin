# The MIT License (MIT)
#
# Copyright (c) 2018 Andreas Loew / CodeAndWeb GmbH www.codeandweb.com
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

@tool
extends EditorImportPlugin

enum Preset { PRESET_DEFAULT }

func _get_importer_name():
	return "codeandweb.texturepacker_import_spritesheet"


func _get_visible_name():
	return "SpriteSheet from TexturePacker"


func _get_recognized_extensions():
	return ["tpsheet"]


func _get_save_extension():
	return "res"


func _get_resource_type():
	return "Resource"


func _get_preset_count():
	return Preset.size()


func _get_preset_name(preset):
	match preset:
		Preset.PRESET_DEFAULT: return "Default"


func _get_import_options(_path, _preset_index):
	return []


func _get_option_visibility(_path, _option_name, _options):
	return true


func _get_import_order():
	return 200


func _get_priority():
	return 1.0


func _import(source_file, save_path, _options, r_platform_variants, r_gen_files):
	print("Importing sprite sheet from " + source_file)
	
	var sheets = read_sprite_sheet(source_file)
	if not sheets:
		return ERR_PARSE_ERROR

	var sheet_folder = source_file.get_basename() + ".sprites"
	create_folder(sheet_folder)

	for sheet in sheets.textures:
		var sheet_file = source_file.get_base_dir() + "/" + sheet.image
		var image = ResourceLoader.load(sheet_file, "ImageTexture")
		if not image:
			printerr("Failed to load image file: " + sheet_file)
			return ERR_FILE_NOT_FOUND

		create_atlas_textures(sheet_folder, sheet, image, r_gen_files)

	return ResourceSaver.save(Resource.new(), "%s.%s" % [save_path, _get_save_extension()])


func create_folder(folder):
	var dir := DirAccess.open("res://")
	if !dir.dir_exists(folder):
		if dir.make_dir_recursive(folder) != OK:
			printerr("Failed to create folder: " + folder)


func create_atlas_textures(sheet_folder, sheet, image, r_gen_files):
	for sprite in sheet.sprites:
		if !create_atlas_texture(sheet_folder, sprite, image, r_gen_files):
			return false
	return true


func create_atlas_texture(sheet_folder, sprite, image, r_gen_files):
	var name = sheet_folder + "/" + sprite.filename.get_basename() + ".tres"
	var texture
	if ResourceLoader.exists(name, "AtlasTexture"):
		texture = ResourceLoader.load(name, "AtlasTexture")
	else:
		texture = AtlasTexture.new()

	texture.atlas = image
	texture.region = Rect2(sprite.region.x, sprite.region.y, sprite.region.w, sprite.region.h)
	texture.margin = Rect2(sprite.margin.x, sprite.margin.y, sprite.margin.w, sprite.margin.h)
	r_gen_files.push_back(name)
	return save_resource(name, texture)


func save_resource(name, texture):
	create_folder(name.get_base_dir())
	
	var status = ResourceSaver.save(texture, name)
	if status != OK:
		printerr("Failed to save resource " + name)
		return false
	return true


func read_sprite_sheet(file_name):
	var file = FileAccess.open(file_name, FileAccess.READ)
	if not file:
		printerr("Failed to load " + file_name)
		return null
		
	var text = file.get_as_text()
	var dict = JSON.parse_string(text)
	if dict == null:
		printerr("Invalid json data in " + file_name)
	return dict
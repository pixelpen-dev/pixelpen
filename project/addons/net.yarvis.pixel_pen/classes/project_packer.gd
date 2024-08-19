class_name ProjectPacker
extends RefCounted


static func load_project(path : String) -> PixelPenProject:
	if path.get_extension()  == "res":
		var res = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
		if res and res is PixelPenProject:
			return res
	elif path.get_extension() == "pxpen":
		var project : PixelPenProject = PixelPenProject.new()
		var zip := ZIPReader.new()
		var err := zip.open(path)
		if err != OK:
			return null
		if not zip.file_exists("config.json"):
			zip.close()
			return null
		var json : String = zip.read_file("config.json").get_string_from_utf8()
		err = project.from_json(json)
		if err != OK:
			zip.close()
			return null
		for frame in project.pool_frames:
			var frame_name : String = str(frame.frame_uid.x, "_", frame.frame_uid.y, "_", frame.frame_uid.z)
			for i in frame.layers.size():
				var layer_path : String = str("pool_frames/", frame_name, ".", i, ".bin")
				if not zip.file_exists(layer_path):
					zip.close()
					return null
				var byte : PackedByteArray = zip.read_file(layer_path)
				frame.layers[i].colormap.set_data(
					frame.layers[i].size.x,
					frame.layers[i].size.y,
					false, Image.FORMAT_R8, byte)
		for frame in project._cache_pool_frames:
			var frame_name : String = str(frame.frame_uid.x, "_", frame.frame_uid.y, "_", frame.frame_uid.z)
			for i in frame.layers.size():
				var layer_path : String = str("cache_pool_frames/", frame_name, ".", i, ".bin")
				if not zip.file_exists(layer_path):
					zip.close()
					return null
				var byte : PackedByteArray = zip.read_file(layer_path)
				frame.layers[i].colormap.set_data(
					frame.layers[i].size.x,
					frame.layers[i].size.y,
					false, Image.FORMAT_R8, byte)
		zip.close()
		return project
	return null


static func save(project : PixelPenProject, path : String) -> Error:
	if path.get_extension()  == "res":
		var err = ResourceSaver.save(project, path)
		return err
	elif path.get_extension() == "pxpen":
		var zip := ZIPPacker.new()
		var err := zip.open(path, ZIPPacker.APPEND_CREATE)
		if err != OK:
			return err
		zip.start_file("config.json")
		zip.write_file(project.get_json().to_utf8_buffer())
		zip.close_file()
		for frame in project.pool_frames:
			var frame_name : String = str(frame.frame_uid.x, "_", frame.frame_uid.y, "_", frame.frame_uid.z)
			for i in frame.layers.size():
				var layer_path : String = str("pool_frames/", frame_name, ".", i, ".bin")
				zip.start_file(layer_path)
				zip.write_file(frame.layers[i].colormap.get_data())
				zip.close_file()
		for frame in project._cache_pool_frames:
			var frame_name : String = str(frame.frame_uid.x, "_", frame.frame_uid.y, "_", frame.frame_uid.z)
			for i in frame.layers.size():
				var layer_path : String = str("cache_pool_frames/", frame_name, ".", i, ".bin")
				zip.start_file(layer_path)
				zip.write_file(frame.layers[i].colormap.get_data())
				zip.close_file()
		zip.close()
		return OK
	return FAILED

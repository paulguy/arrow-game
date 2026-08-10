class_name FileItem
extends Object

enum FileSource {
	INVALID = -1,
	RES = 0,
	USER
}

const FILE_SUFFIX : String = ".arrows"

const FILE_SOURCE_PATH : Array[String] = [
	"res://puzzles/",
	"user://puzzles/"
]

const FILE_EDIT_PATH : Array[String] = [
	"res:",
	"user:"
]

const FILE_SOURCE_GLYPH : Array[String] = [
	"📁",
	"👤"
]

var file_name : String
var file_source : FileSource

func _init(file_name : String,
		   file_source : FileSource):
	self.file_name = file_name
	self.file_source = file_source

static func match_name(fn : String):
	if fn.ends_with(FILE_SUFFIX) and not fn.contains("/"):
		# file must end with suffix and not have subdirectories
		return true
	return false

static func make_from_path(path : String) -> FileItem:
	var source : FileSource = FileSource.INVALID
	var name : String

	name = path

	# trim any suffix
	if path.ends_with(FILE_SUFFIX):
		name = name.substr(0, len(name) - len(FILE_SUFFIX))

	# find the file source and isolate the name from it
	for i in len(FILE_SOURCE_PATH):
		if path.begins_with(FILE_SOURCE_PATH[i]):
			name = name.substr(len(FILE_SOURCE_PATH[i]))
			source = i as FileSource
			break
	if source == FileSource.INVALID:
		# try edit names
		for i in len(FILE_EDIT_PATH):
			if path.begins_with(FILE_EDIT_PATH[i]):
				name = name.substr(len(FILE_EDIT_PATH[i]))
				source = i as FileSource
				break

	# if any more path components, don't accept
	if name.contains("/"):
		return null

	# default to user if one wasn't found
	if source == FileSource.INVALID:
		source = FileSource.USER

	return FileItem.new(name, source)

func get_path():
	return "%s%s%s" % [FILE_SOURCE_PATH[file_source], file_name, FILE_SUFFIX]

func get_display_string():
	return "%s%s" % [FILE_SOURCE_GLYPH[file_source], file_name]

func get_edit_string():
	return "%s%s" % [FILE_EDIT_PATH[file_source], file_name]

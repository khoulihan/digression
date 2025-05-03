extends RefCounted
## Logging for the dialogue graph editor components.
## To customise the output, set DGE_EDITOR_LOG_LEVEL and DGE_RUNTIME_LOG_LEVEL to
## the desired minimum log level for the editor and runtime nodes respectively.


enum DGELogLevel {
	TRACE = 0,
	DEBUG,
	INFO,
	WARN,
	ERROR,
	FATAL
}

const DGE_EDITOR_LOG_NAME = "Digression Dialogue Graph Editor"
const DGE_EDITOR_LOG_LEVEL = DGELogLevel.DEBUG
const DGE_PREVIEW_LOG_NAME = "Digression Dialogue Graph Previewer"
const DGE_PREVIEW_LOG_LEVEL = DGELogLevel.DEBUG
const DGE_RUNTIME_LOG_NAME = "Digression Dialogue Graph Runtime"
const DGE_RUNTIME_LOG_LEVEL = DGELogLevel.DEBUG


static var _editor_logger: Logger
static var _preview_logger: Logger
static var _runtime_logger: Logger


static func get_editor_logger() -> Logger:
	if _editor_logger == null:
		_editor_logger = Logger.new(DGE_EDITOR_LOG_NAME, DGE_EDITOR_LOG_LEVEL)
	return _editor_logger


static func get_preview_logger() -> Logger:
	if _preview_logger == null:
		_preview_logger = Logger.new(DGE_PREVIEW_LOG_NAME, DGE_PREVIEW_LOG_LEVEL)
	return _preview_logger


static func get_runtime_logger() -> Logger:
	if _runtime_logger == null:
		_runtime_logger = Logger.new(DGE_RUNTIME_LOG_NAME, DGE_RUNTIME_LOG_LEVEL)
	return _runtime_logger


class Logger:
	
	var _log_name: String = DGE_EDITOR_LOG_NAME
	var _log_level: DGELogLevel = DGELogLevel.INFO

	func _init(log_name: String, log_level: DGELogLevel):
		if not log_name == "":
			_log_name = log_name
		_log_level = log_level
	
	## Create a log at the default level (INFO).
	func log(text: String) -> void:
		_log(text, DGELogLevel.INFO)


	## Create a log at the TRACE level.
	func trace(text: String) -> void:
		_log(text, DGELogLevel.TRACE)


	## Create a log at the DEBUG level.
	func debug(text: String) -> void:
		_log(text, DGELogLevel.DEBUG)


	## Create a log at the INFO level.
	func info(text: String) -> void:
		_log(text, DGELogLevel.INFO)


	## Create a log at the WARN level.
	func warn(text: String) -> void:
		_log(text, DGELogLevel.WARN)


	## Create a log at the ERROR level.
	func error(text: String) -> void:
		_log(text, DGELogLevel.ERROR)


	## Create a log at the FATAL level.
	func fatal(text: String) -> void:
		_log(text, DGELogLevel.FATAL)


	func _get_level_name(level: DGELogLevel) -> String:
		match level:
			DGELogLevel.TRACE:
				return "TRACE"
			DGELogLevel.DEBUG:
				return "DEBUG"
			DGELogLevel.INFO:
				return "INFO"
			DGELogLevel.WARN:
				return "WARN"
			DGELogLevel.ERROR:
				return "ERROR"
			DGELogLevel.FATAL:
				return "FATAL"
		return "UNKNOWN"


	func _log(text: String, level: DGELogLevel) -> void:
		if level >= _log_level:
			var final_text := "%s - %s: %s" % [_log_name, _get_level_name(level), text]
			if level == DGELogLevel.WARN:
				push_warning(final_text)
				return
			if level == DGELogLevel.ERROR or level == DGELogLevel.FATAL:
				push_error(final_text)
				return
			print("%s - %s: %s" % [_log_name, _get_level_name(level), text])

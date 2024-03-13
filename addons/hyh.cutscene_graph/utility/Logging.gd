extends RefCounted
## Logging for the dialogue graph editor components.
## To customise the output, set CGE_EDITOR_LOG_LEVEL and CGE_NODES_LOG_LEVEL to
## the desired minimum log level for the editor and runtime nodes respectively.


enum CGELogLevel {
	TRACE = 0,
	DEBUG,
	INFO,
	WARN,
	ERROR,
	FATAL
}

const CGE_EDITOR_LOG_LEVEL = CGELogLevel.DEBUG
const CGE_NODES_LOG_LEVEL = CGELogLevel.DEBUG

var _log_name: String = "Cutscene Graph Editor"
var _log_level: CGELogLevel = CGELogLevel.INFO


func _init(log_name: String, log_level: CGELogLevel):
	_log_name = log_name
	_log_level = log_level


## Create a log at the default level (INFO).
func log(text: String) -> void:
	_log(text, CGELogLevel.INFO)


## Create a log at the TRACE level.
func trace(text: String) -> void:
	_log(text, CGELogLevel.TRACE)


## Create a log at the DEBUG level.
func debug(text: String) -> void:
	_log(text, CGELogLevel.DEBUG)


## Create a log at the INFO level.
func info(text: String) -> void:
	_log(text, CGELogLevel.INFO)


## Create a log at the WARN level.
func warn(text: String) -> void:
	_log(text, CGELogLevel.WARN)


## Create a log at the ERROR level.
func error(text: String) -> void:
	_log(text, CGELogLevel.ERROR)


## Create a log at the FATAL level.
func fatal(text: String) -> void:
	_log(text, CGELogLevel.FATAL)


func _get_level_name(level: CGELogLevel) -> String:
	match level:
		CGELogLevel.TRACE:
			return "TRACE"
		CGELogLevel.DEBUG:
			return "DEBUG"
		CGELogLevel.INFO:
			return "INFO"
		CGELogLevel.WARN:
			return "WARN"
		CGELogLevel.ERROR:
			return "ERROR"
		CGELogLevel.FATAL:
			return "FATAL"
	return "UNKNOWN"


func _log(text: String, level: CGELogLevel) -> void:
	if level >= _log_level:
		var final_text := "%s - %s: %s" % [_log_name, _get_level_name(level), text]
		if level == CGELogLevel.WARN:
			push_warning(final_text)
			return
		if level == CGELogLevel.ERROR or level ==CGELogLevel.FATAL:
			push_error(final_text)
			return
		print("%s - %s: %s" % [_log_name, _get_level_name(level), text])

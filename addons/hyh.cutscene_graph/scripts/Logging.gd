extends Object


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
		print("%s - %s: %s" % [_log_name, _get_level_name(level), text])


## Default log level is INFO
func log(text: String) -> void:
	_log(text, CGELogLevel.INFO)


func trace(text: String) -> void:
	_log(text, CGELogLevel.TRACE)


func debug(text: String) -> void:
	_log(text, CGELogLevel.DEBUG)


func info(text: String) -> void:
	_log(text, CGELogLevel.INFO)


func warn(text: String) -> void:
	_log(text, CGELogLevel.WARN)


func error(text: String) -> void:
	_log(text, CGELogLevel.ERROR)


func fatal(text: String) -> void:
	_log(text, CGELogLevel.FATAL)

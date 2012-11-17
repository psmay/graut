fs = require 'fs'
path = require 'path'
{spawn, exec} = require 'child_process'

build = "build"
src = "src"

header = """
"""

sources = [
	'lexer'
	'grammarDsl'
	'grammar'
	'model'
].map (filename) -> "src/#{filename}.coffee"

run = (args, cb) ->
	proc = spawn 'coffee', args
	proc.stderr.on 'data', (buffer) -> console.log buffer.toString()
	proc.on 'exit', (status) ->
		process.exit 1 if status isnt 0
		cb() if typeof cb is 'function'

task 'build', 'build graut from source', build = (cb) ->
	files = ("#{src}/#{file}" for file in (fs.readdirSync src) when file.match /\.coffee$/)
	console.log files
	run ['-c', '-o', build, files...], cb


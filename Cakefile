fs = require 'fs'
path = require 'path'
{spawn, exec} = require 'child_process'

BUILD = "build"
BUILD_LIBS = "#{BUILD}/lib/graut"
BUILD_BIN = "#{BUILD}/bin"
SRC = "src"

header = """
"""

#sources = [
#	'lexer'
#	'grammarDsl'
#	'grammar'
#	'model'
#].map (filename) -> "#{SRC}/#{filename}.coffee"

run = (args, cb) ->
	proc = spawn 'coffee', args
	proc.stderr.on 'data', (buffer) -> console.log buffer.toString()
	proc.on 'exit', (status) ->
		process.exit 1 if status isnt 0
		cb() if typeof cb is 'function'

findAll = (dir, filter) ->
	result = []
	filter ?= -> true
	recurse = (leadingDirs...) ->
		filenames = fs.readdirSync leadingDirs.join "/"
		for filename in filenames
			if filter leadingDirs, filename
				result.push [leadingDirs, filename]
			all = leadingDirs.concat([filename])
			if fs.statSync(all.join "/").isDirectory()
				recurse all...
	recurse dir
	result

coffeeFiles = (findAll SRC, (lead, filename) -> filename.match /\.coffee$/).map ([parents, file]) ->
	[parents.slice(1), file]

task 'build', 'build graut from source', (cb) ->
	files = ("#{SRC}/#{file}" for file in (fs.readdirSync SRC) when file.match /\.coffee$/)
	console.log files
	for [parents, file] in coffeeFiles
		srcFile = [SRC].concat(parents, [file]).join "/"
		destDir = [BUILD].concat(parents).join "/"
		console.log "Compile #{srcFile} into #{destDir}"
		run ['-c', '-o', destDir, srcFile], cb

task 'clean', 'remove build files', (cb) ->
	exec "rm -rf #{BUILD}", (err) ->
		throw err if err

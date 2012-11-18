fs = require 'fs'
path = require 'path'
{spawn, exec} = require 'child_process'

BUILD = "build"
DIST = "#{BUILD}/dist"
SRC = "src"

# Run coffee
coffee = (args, cb) ->
	proc = spawn 'coffee', args
	proc.stderr.on 'data', (buffer) -> console.log buffer.toString()
	proc.on 'exit', (status) ->
		process.exit 1 if status isnt 0
		cb() if typeof cb is 'function'

# Compile with coffee
coffeeco = (srcFile, destDir, cb) ->
	console.log "Compile #{srcFile} into #{destDir}"
	coffee ['-c', '-o', destDir, srcFile], cb

# Run mkdir -p
mkdirp = (dir) ->
	console.log "Create directory '#{dir}'"
	exec "mkdir -p '#{dir}'", (err) -> throw err if err

# Run cp -rf
cprf = (srcFile, destFile) ->
	console.log "Copy #{srcFile} to #{destFile}"
	exec "cp -rf '#{srcFile}' '#{destFile}'", (err) -> throw err if err

# Recurse, hitting every filename as both its path relative to here and its
# path relative to the start path.
findAllRelative = (path, filter, process) ->
	result = []
	
	filter ?= -> true
	process ?= (rel, full) -> rel
	
	add = (z) ->
		listVersion = [].concat z
		result.push listVersion...
	
	recurse = (relSubDir) ->
		fullParent = if relSubDir? then "#{path}/#{relSubDir}" else path
		relPrefix = if relSubDir? then "#{relSubDir}/" else ""
		
		names = fs.readdirSync fullParent
		for name in names
			rel = "#{relPrefix}#{name}"
			full = "#{fullParent}/#{name}"
			
			if filter rel, full
				add process(rel, full)
			if fs.statSync(full).isDirectory()
				recurse rel
	
	recurse()
	result

# Remove parent dirs from a filename.
stripDirs = (name) ->
	[all, lead] = /// ^(?:(.*)/)?.*?$ ///.exec name
	if lead?
		if lead is "" then "/" else lead
	else
		"."

# Locate sources, and make a list pairing each source with its corresponding
# build product.

coffeeFiles = findAllRelative SRC,
	( (name) -> name.match /\.coffee$/ ),
	(rel) ->
		[ [ "#{SRC}/#{rel}", "#{DIST}/#{rel.replace(/\.coffee$/,'.js')}" ] ]

directFiles = findAllRelative "#{SRC}/bin",
	( (name, full) -> ! fs.statSync(full).isDirectory() ),
	(rel) ->
		[ [ "#{SRC}/bin/#{rel}", "#{DIST}/bin/#{rel}" ] ]


task 'build', 'build graut from source', (cb) ->
	mkdirp "#{DIST}/bin"
	for [srcFile, destFile] in directFiles
		cprf srcFile, destFile
	
	for [srcFile, destFile] in coffeeFiles
		destDir = stripDirs destFile
		coffeeco srcFile, destDir, cb

task 'clean', 'remove build files', (cb) ->
	exec "rm -rf #{BUILD}", (err) ->
		throw err if err

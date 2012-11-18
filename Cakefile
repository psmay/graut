fs = require 'fs'
path = require 'path'
{spawn, exec} = require 'child_process'

notice = """
graut
Copyright (c) 2012 Peter S. May (halfgeek.org)

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
"""

jsNotice = "/*\n#{notice}\n*/\n"

BUILD = "./build"
DIST = "#{BUILD}/dist"
SRC = "./src"
GRAMMAR = "./grammar"
GRAMMAR_DEST = "#{DIST}/lib/graut/parser.js"

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
	buildDirectCopies cb
	buildLibs cb
	buildParser cb

buildDirectCopies = (cb) ->
	mkdirp "#{DIST}/bin"
	for [srcFile, destFile] in directFiles
		cprf srcFile, destFile
	
buildLibs = (cb) ->
	for [srcFile, destFile] in coffeeFiles
		destDir = stripDirs destFile
		coffeeco srcFile, destDir, cb

buildParser = (cb) ->
	srcGrammar = "#{GRAMMAR}/grammar"
	destFile = "#{GRAMMAR_DEST}"
	destDir = stripDirs destFile
	mkdirp destDir
	console.log "Generating grammar #{srcGrammar} to #{destFile}"
	parser = (require srcGrammar).parser
	fs.writeFile destFile, jsNotice + parser.generate()


task 'clean', 'remove build files', (cb) ->
	exec "rm -rf #{BUILD}", (err) ->
		throw err if err

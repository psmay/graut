###
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
###

fs = require 'fs'
# path = require 'path'
{ Lexer } = require './lexer'
{ parser } = require './parser'
Model = require './model'

exports.parse = parse = (string) ->
	if string.length > 0 and string.charCodeAt(0) is 0xFEFF
		# Strip BOM. Nasty thing.
		string = string.slice 1
	parser.parse string

exports.parseFile = parseFile = (filename, encoding) ->
	parse fs.readFileSync(filename, encoding ? 'utf8')

exports.parseStdin = parseStdin = (encoding) ->
	parseFile('/dev/stdin', encoding)

parser.lexer = Lexer.jisonLexer()
parser.yy = Model


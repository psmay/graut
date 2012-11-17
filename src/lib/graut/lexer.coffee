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


# Synopsis:

# As Jison:
# jl = Lexer.jisonLexer()
# jl.setInput str
# jl.lex()
#
# With Jison parser:
# parser.lexer = Lexer.jisonLexer()
# parser.yy = (whatever context the parser might need)

# As pullTokenizer:
# pullt = Lexer.pullTokenizer str
# foo(pullt.next()) while token = pullt.hasNext()
# or
# while pullt.tryNext(foo) # nothing

# As pushTokenizer:
# pusht = Lexer.pushTokenizer input, foo
# pusht.run() # Run past an arbitrary number of tokens
# pusht.runAll() # Run past all tokens unless an error occurs
# pusht.unfinished() # true until the end of input is read (does not go false
# 	# on error)

# The token values returned are an object type that has these properties:
#	token.type (string)
#	token.text (string)
#	token.startLine (int, 1-based)
#	token.startColumn (int, 1-based)
#	token.endLine (int, 1-based)
#	token.endColumn (int 1-based, position after, not at, end)
# And these methods:
#	token.visit (type,text,startLine,endLine,startColumn,endColumn) -> ...
#	token.toString() # returns token.text()
#	token.toLogString() # returns more informative string
#
# The object is contrived to be used instead of a string for yytext in Jison
# (the parser doesn't seem to require a string at all, but this object
# stringifies as if it were one anyway). Use token.toLogString() for diagnostic
# purposes.
#
# Columns are counted in codepoints, not characters. Matched surrogate pairs
# are counted as one column regardless of input encoding. (They don't appear in
# valid UTF-8 or UTF-32, but many implementations don't enforce this.)

FIRST_LINE = 1
FIRST_COLUMN = 1

Lexer = (exports ? this).Lexer =
	pullTokenizer : (input) ->
		return new PullTokenizer(input)
	pushTokenizer : (input, callback) ->
		return new TokenizerSession(input, callback)
	
	jisonLexer : () ->
		_setPosition(line, col) ->
			@yylineno = line
			@_positionNumber = col
		
		setInput : (input) ->
			@pullSession = Lexer.pullTokenizer(input)
			@_setPosition(0,0)
		
		showPosition : () -> @_positionNumber
		lex : () ->
			type = ""
			@pullSession.tryNext (ext) ->
				@yytext = ext
				@_setPosition(ext.startLine - FIRST_LINE, ext.startColumn)
				type = ext.type
			type

class TokenInfo
	constructor = (list) ->
		[@type, @text, @startLine, @startColumn, @endLine, @endColumn] = list
	
	@create = (info...) -> new TokenInfo(info)
	
	visit = (fn) ->
		fn(@type, @text, @startLine, @startColumn, @endLine, @endColumn)
	
	toString = () -> @text
	toLogString = () ->
		"[" +
		"#{@startLine}:#{@startColumn}-#{@endLine}:#{@endColumn} " +
		"#{@type} #{JSON.stringify(@text)}]"



class PullTokenizer
	constructor: (input) ->
		@buffer = []
		@_session = new PushTokenizer input, (tokenInfo) =>
			@buffer.push tokenInfo
	
	hasNext: () ->
		while @buffer.length is 0 and @_session.unfinished()
			@_session.run()
		@buffer.length > 0
	
	tryNext: (handler) ->
		if @hasNext()
			next = @buffer.shift()
			handler(next)
			true
		else
			false
	
	next: (handler) ->
		if not @hasNext()
			throw Error "Read past end of input"
		
		t = @buffer.shift()
		if isFunction handler then handler(t) else t


class PushTokenizer
	constructor: (input, callback) ->
		@_session = new TokenizerSession input, (stats...) =>
			callback(TokenInfo.create(stats...))
	run : () -> @_session.run()
	unfinished : () -> @_session.unfinished()
	runAll : () -> @run() while @unfinished()
	




UnquotedStringChar = """[\u0080-\uFFFF!%&*+,./:;=?^|~A-Za-z0-9_-]"""

countCodePoints = (str) ->
	# A wholly brutish transform to count surrogate pairs as a single unit
	(str.replace /[\uD800-\uDBFF][\uDC00-\uDFFF]/g, 'x').length

skipToLastLine = (str) ->
	lines = str.split /(?:\r\n?|\n)/g
	linesSkipped = lines.length - 1
	lastLine = lines[linesSkipped]
	[linesSkipped, lastLine]


ostring = (v) -> Object.prototype.toString.call(v)

isArray = (v) ->
	ostring(v) is '[object Array]'
isFunction = (v) ->
	ostring(v) is '[object Function]'

# This class is where the actual lexing happens.
class TokenizerSession
	constructor: (@input, @callback) ->
		@input = String(@input)
		
		# mark and pos are in chars
		# column is in codepoints
		
		@mark = 0
		@pos = 0
		
		@line = FIRST_LINE
		@column = FIRST_COLUMN
		
		@mode = []
		@push finalMode
		@push initialMode
	
	getPendingText: () ->
		@input[@mark ... @pos]

	advanceMark: () ->
		[skipped, lastLine] = skipToLastLine(@getPendingText())
		
		# Advance line counter if necessary
		if skipped > 0
			@line += skipped
			@column = FIRST_COLUMN
		
		# Advance column counter if necessary
		@column += countCodePoints lastLine
		
		# And finally
		@mark = @pos
	
	take: (toTake) ->
		if typeof toTake is 'string'
			count = toTake.length
			unless toTake is @input[@pos ... @pos+count]
				throw Error "Assert failed: Take text must match parsed text"
		else if typeof toTake is 'number'
			count = toTake
		
		@pos += count
	
	emit: (tokenName) ->
		lpre = @line
		cpre = @column
		text = @getPendingText()
		@advanceMark()
		lpost = @line
		cpost = @column
		
		@callback(tokenName, text, lpre, cpre, lpost, cpost)
		

	push: (modeFn, params...) ->
		throw Error "Assert failed: Mode function was not a function but #{typeof modeFn}: #{modeFn}" unless typeof modeFn is 'function'
		@mode.push [modeFn, params]
	
	pop: () ->
		@mode.pop()
	
	peek: () ->
		throw Error "Assert failed: Peek on empty stack" if @mode.length < 1
		@mode[@mode.length - 1]

	run: () ->
		if @unfinished()
			[modeFn, params] = @peek()
			modeFn.apply(@, params)
			@unfinished()
		else
			false
	
	unfinished: () ->
		(@mark < @input.length or @mode.length > 1)
	
	match: (description, pattern, onMatch) ->
		m = pattern.exec @input[@pos ..]
		if not m?
			throw new SyntaxError(
				"#{@line}:#{@column}: Expected #{description} " +
				"(pending text was '#{@getPendingText()}')"
			)
		else
			onMatch.apply(@, m)


finalMode = () ->
	@match "end of input", /^$/, () ->

initialMode = () ->
	@match "raw text, function call, or end of input", ///^
		([\s\S]*?)(\#\(|$)
	///, (all, rawText, after) ->
			if rawText.length > 0
				@take rawText
				@emit 'TEXT'
			if after.length > 0
				@push transMode
			else
				# eof
				@pop()

transMode = () ->
	@match "function call", /^(\#)(\()/, (all, sigil, down) ->
		@pop
		@take sigil
		@emit 'SIGIL'
		@take down
		@emit 'DOWN'
		@pop()
		@push codeMode

codeMode = () ->
	@match "list element or end of list", ///^(?:
		([\u0020\t\r\n]+) # space
		|
		(\() # down
		|
		(\)) # up
		|
		([$@\#])([\s\S]?) # sigil
		|
		("{1,3}|'{1,3}) # quote
		|
		(<<?) # left angle
		|
		(#{UnquotedStringChar}+)
	)///, (all, space, down, up, sigil, sigilFollow, quote, left, unquoted) ->
		if space?
			@take space
			@emit 'SPACE'
		else if down?
			@take down
			@emit 'DOWN'
			@push codeMode
		else if up?
			@take up
			@emit 'UP'
			@pop()
		else if sigil?
			@take sigil
			@emit 'SIGIL'
			# We'll also help the parser by producing a zero-width token when a
			# sigil does not appear to be followed by an element
			unless ///^[^\u0020\t\r\n\)]$///.test sigilFollow
				@emit 'EMPTYTOPIC'
		else if quote?
			single = quote[0..0]
			if quote.length >= 3
				@match "triple-quoted string",
					///^
						(#{quote})
						([\s\S]*?)
						(#{quote})
						(#{single}*)
					///, (all, openq, mainText, closeq, excessq) ->
						# We'll cheat and swap the positions of closeq and
						# excessq. It's not quite right morally, but the text
						# itself is no different. 
						@take openq
						@emit 'STRING3START'
						@take mainText
						@take excessq
						@emit 'STRING3TEXT'
						@take closeq
						@emit 'STRING3END'
			else
				@take single
				@emit 'STRING1START'
				@push singleQuoteMode, single
		else if left?
			if left.length >= 2
				@push deepHerePreMode
			else
				@push shallowHerePreMode
		else if unquoted?
			@take unquoted
			@emit 'STRING0'


# x28 is lparen
# x5c is bslash

functionCallStart = "#\\x28"
hashNonFunctionCall = "#(?!\\x28)"
bslashAndFollowingChar = "\\x5c[\\s\\S]"

singleQuoteMode = (single) ->
	nonQuoteHashBslash = "[^" + single + """#\\x5c]"""
	
	textPiece =
		"(?:" +
		"#{nonQuoteHashBslash}|" +
		"#{hashNonFunctionCall}|" +
		"#{bslashAndFollowingChar})"

	textPattern = ///^
		(#{textPiece}+)?
	///
	
	@match "text of single-quoted string", textPattern, (all, text) ->
		if text?
			@take text
			@emit 'STRING1TEXT'
	
	followPattern =
		///^(?:
			(#{functionCallStart}) |
			(#{single})
		)///
	
	@match "close quote of single-quoted string or function call",
		followPattern, (all, call, quote) ->
			if call?
				@push transMode
			else if quote?
				@take quote
				@emit 'STRING1END'
				@pop()

leftShallowHereToken = ///^(<(#{UnquotedStringChar}+)<)///
leftDeepHereToken = ///^(<<(#{UnquotedStringChar}+)<)///

shallowHerePreMode = () ->
	@match "shallow heredoc start", leftShallowHereToken, (all, st, name) ->
		@take st
		@emit 'SHSTART'
		@match "shallow heredoc end", ///^([\s\S]+?)?(>#{name}>)///,
			(all, text, close) ->
				if text?
					@take text
					@emit 'SHTEXT'
				@take close
				@emit 'SHEND'
				@pop()

deepHerePreMode = () ->
	@match "deep heredoc start", leftDeepHereToken, (all, st, name) ->
		@take st
		@emit 'DHSTART'
		@pop()
		@push deepHereMode, name

deepHereMode = (name) ->
	nonHashRAngle = "[^#>]"
	
	pattern = ///^
			((?:
				#{nonHashRAngle} |
				#{hashNonFunctionCall} | # hash, but not a call
				>(?!#{name}>>) # rangle, but not the end
			)+)?
			(?:
				(#{functionCallStart}) |
				(>#{name}>>)
			)
		///
	#console.log("Deep pattern : ", pattern)
	@match "deep heredoc end or function call",
		pattern,
		(all, text, call, close) ->
			if text?
				@take text
				@emit 'DHTEXT'
			
			if call?
				@push transMode
			else
				@take close
				@emit 'DHEND'
				@pop()


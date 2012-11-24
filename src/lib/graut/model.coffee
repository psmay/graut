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

extend = (obj, src) ->
	obj[key] = value for own key, value of src
	obj

isArray = (item) -> Object.prototype.toString.call(item) is '[object Array]'
isBoolean = (item) -> Boolean(item) is item
isNode = (item) -> item instanceof Node
isToken = (item) -> item instanceof Token
isTokenOrUnused = (item) -> if item? then isToken(item) else true

assertType = (expected, value, test) ->
	unless test value
		throw Error "Assert failed: Wrong type; expected #{expected}, got #{value}"

assertArray = (item) -> assertType "array", item, isArray
assertBoolean = (item) -> assertType "boolean", item, isBoolean
assertNode = (item) -> assertType "node", item, isNode
assertToken = (item) -> assertType "token", item, isToken
assertTokenOrUnused = (item) -> assertType "token or unused", item, isTokenOrUnused




render = (item, pfx) ->
	if not item?
		""
	else if item.toPrefixedString
		item.toPrefixedString pfx
	else if isArray item
		renderings = for e in item
			pfx + "<element>\n" + render(e, pfx + "#{TAB}")
		renderings.join ""
	else
		str = if item.toLogString
			item.toLogString()
		else
			item.toString()
		pfx + str + "\n"

class Token
	constructor : (list) ->
		[@type, @text, @startLine, @startColumn, @endLine, @endColumn] = list
	
	@create = (info...) -> new Token(info)
	
	visit : (fn) ->
		fn(@type, @text, @startLine, @startColumn, @endLine, @endColumn)
	
	toJSON : () ->
		["token",
			type : @type
			text : @text
			startLine : @startLine
			startColumn : @startColumn
			endLine : @endLine
			endColumn : @endColumn
		]
	
	toString : () -> @text
	toLogString : () ->
		"[" +
		"#{@startLine}:#{@startColumn}-#{@endLine}:#{@endColumn} " +
		"#{@type} #{JSON.stringify(@text)}]"

exports.createToken = Token.create

# Copy "own" properties from other objects onto this object. As a special case,
# the undefined value will delete the key from the target object. The maps are
# overlaid in order, so if a property exists in multiple maps, the value from
# the latest list prevails. Similarly, a later undefined value will delete the
# earlier value while a later defined value will re-create a key that has been
# deleted.
combineMapsOnto = (out, maps...) ->
	for map in maps
		for own k,v of map
			if v is undefined and Object::hasOwnProperty.call(out,k)
				delete out[k]
			else
				out[k] = v
			undefined # no collectible output
	out
				

TAB = "  "
class Node
	nodeType : "Node"
	
	constructor: (token) ->
		assertTokenOrUnused token
		if token?
			@line = token.startLine
			@column = token.startColumn
	
	toString : () -> @toPrefixedString("")
	
	properties : () ->
		combineMapsOnto {},
			line : @line
			column : @column
	
	toJSON : () ->
		p = {}
		[ @nodeType, @properties() ]
		
	toPrefixedString : (pfx) ->
		text = []
		text.push pfx + "[#{@nodeType}]\n"
		
		for own p, v of @
			if v?
				text.push pfx + "#{TAB}#{p}:\n"
				text.push render(v, pfx + "#{TAB}#{TAB}")
		text.join ""


extend exports,
	InterpolatedValue: class InterpolatedValue extends Node
		nodeType : "Interpolated"
		constructor: ({ @values, @startToken, @endToken }) ->
			super @startToken
			assertTokenOrUnused @startToken
			assertTokenOrUnused @endToken
			assertArray @values
		visit: (obj) -> obj.interpolatedValue @
		toJSON : () ->
			super.concat @values
		properties : () ->
			combineMapsOnto super,
				startToken : @startToken
				endToken : @endToken
	
	StringValue: class StringValue extends Node
		nodeType : "String"
		constructor: ({ @textToken, @doBslashEscapes, @openToken, @closeToken }) ->
			super @textToken
			assertTokenOrUnused @openToken
			assertTokenOrUnused @closeToken
			assertToken @textToken
			@doBslashEscapes ?= false
			assertBoolean @doBslashEscapes
		visit: (obj) -> obj.stringValue @
		properties : () ->
			combineMapsOnto super,
				textToken : @textToken
				doBslashEscapes : @doBslashEscapes
				openToken : @openToken
				closeToken : @closeToken

	ListValue: class ListValue extends Node
		nodeType : "List"
		constructor: ({ @values, @openToken, @closeToken }) ->
			super @openToken
			assertToken @openToken
			assertToken @closeToken
			assertArray @values
		visit: (obj) -> obj.listValue @
		toJSON : () ->
			super.concat @values
		properties : () ->
			combineMapsOnto super,
				openToken : @openToken
				closeToken : @closeToken
		

	InlineOp: class InlineOp extends Node
		nodeType : "Inline"
		constructor: ({ @sigilToken, @topic }) ->
			super @sigilToken
			assertToken @sigilToken
			assertNode @topic
		visit: (obj) -> obj.inlineOp @
		toJSON : () ->
			super.concat [@topic]
		properties : () ->
			combineMapsOnto super,
				sigilToken : @sigilToken

	ExpandOp: class ExpandOp extends Node
		nodeType : "Expand"
		constructor: ({ @sigilToken, @topic }) ->
			super @sigilToken
			assertToken @sigilToken
			assertNode @topic
		visit: (obj) -> obj.expandOp @
		toJSON : () ->
			super.concat [@topic]
		properties : () ->
			combineMapsOnto super,
				sigilToken : @sigilToken

	CallOp: class CallOp extends Node
		nodeType : "Call"
		constructor: ({ @sigilToken, @topic }) ->
			super @sigilToken
			assertToken @sigilToken
			assertNode @topic
		visit: (obj) -> obj.callOp @
		toJSON : () ->
			super.concat [@topic]
		properties : () ->
			combineMapsOnto super,
				sigilToken : @sigilToken
	
	NonceOp: class NonceOp extends Node
		nodeType : "Nonce"
		constructor: ({ @sigilToken }) ->
			super @sigilToken
			assertToken @sigilToken
		visit: (obj) -> obj.nonceOp @
		properties : () ->
			combineMapsOnto super,
				sigilToken : @sigilToken
	
	semanticError: (tokenInfo, message) ->
		tokenInfo = tokenInfo.token if Object(tokenInfo) instanceof Node
		locator = if tokenInfo?
			"#{tokenInfo.startLine}:#{tokenInfo.startColumn}: "
		else
			""
		message ?= "Assert failed"

		throw new Error "#{locator}#{message}"

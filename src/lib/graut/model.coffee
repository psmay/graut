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
isToken = (item) -> item? and item.type? and item.text? and item.startLine?
isTokenOrUnused = (item) -> if item? then isToken(item) else true

assertType = (expected, value, test) ->
	unless test value
		throw Error "Assert failed: Wrong type; expected #{expected}, got #{value}"

assertArray = (item) -> assertType "array", item, isArray
assertBoolean = (item) -> assertType "boolean", item, isBoolean
assertNode = (item) -> assertType "node", item, isNode
assertToken = (item) -> assertType "token", item, isToken
assertTokenOrUnused = (item) -> assertType "token or unused", item, isTokenOrUnused



TAB = "  "

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

class Node
	nodeType : "Node"
	
	constructor: (@token) ->
		if @token isnt null and not @token.text?
			throw new Error "Assert failed: #{@token} is not a token"
	
	toString : () -> @toPrefixedString("")
	
	
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
			assertTokenOrUnused @startToken
			assertTokenOrUnused @endToken
			assertArray @values
	
	StringValue: class StringValue extends Node
		nodeType : "String"
		constructor: ({ @textToken, @doBslashEscapes, @openToken, @closeToken }) ->
			assertTokenOrUnused @openToken
			assertTokenOrUnused @closeToken
			assertToken @textToken
			@doBslashEscapes ?= false
			assertBoolean @doBslashEscapes

	ListValue: class ListValue extends Node
		nodeType : "List"
		constructor: ({ @values, @openToken, @closeToken }) ->
			assertToken @openToken
			assertToken @closeToken
			assertArray @values

	InlineOp: class InlineOp extends Node
		nodeType : "Inline"
		constructor: ({ @sigilToken, @topic }) ->
			assertToken @sigilToken
			assertNode @topic

	ExpandOp: class ExpandOp extends Node
		nodeType : "Expand"
		constructor: ({ @sigilToken, @topic }) ->
			assertToken @sigilToken
			assertNode @topic

	CallOp: class CallOp extends Node
		nodeType : "Call"
		constructor: ({ @sigilToken, @topic }) ->
			assertToken @sigilToken
			assertNode @topic
	
	NonceOp: class NonceOp extends Node
		nodeType : "Nonce"
		constructor: ({ @sigilToken }) ->
			assertToken @sigilToken
	
	semanticError: (tokenInfo, message) ->
		locator = if tokenInfo?
			"#{tokenInfo.startLine}:#{tokenInfo.startColumn}: "
		else
			""
		message ?= "Assert failed"

		console.log "parseError called with ", tokenInfo, message
		console.log "---"
		throw new Error "#{locator}#{message}"

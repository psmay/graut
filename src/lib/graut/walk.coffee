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

Model = require './model'
{ InterpolatedNode, StringNode, ListNode, InlineNode, ExpandNode, CallNode, NonceNode, semanticError } = Model

callUnhandled = (obj) -> @unhandled obj

class Visitable
	constructor : (overrides) ->
		overrides ?= {}
		for own k, v of overrides
			@[k] = v
	
	unhandled : (obj) -> semanticError obj, "Unexpected item"
	interpolatedValue : callUnhandled
	stringValue : callUnhandled
	listValue : callUnhandled
	inlineOp : callUnhandled
	expandOp : callUnhandled
	callOp : callUnhandled
	nonceOp : callUnhandled
	
walkVisitable = new Visitable
	interpolatedValue : (node) -> walkInterpolated node

exports.walk = (top) -> top.visit walkVisitable


interpElementVisitable = new Visitable
	stringValue : (node) -> textOfStringNode node
	callOp : (node) -> walkCallNode node

walkInterpolated = (node) -> node.visit interpElementVisitable


codepointToString = (cp) ->
	if cp is (cp & 0xFFFF)
		String.fromCharCode(cp)
	else
		adj = (cp - 0x10000) & 0xFFFFF
		throw Error("Invalid codepoint " + cp) if cp isnt (adj + 0x10000)
		hi = adj >> 10
		lo = adj & 0x3FF
		String.fromCharCode(0xD800 + hi) + String.fromCharCode(0xDC00 + lo)


stringTextVisitable = new Visitable
	stringValue : (node) ->
		text = node.textToken.text
		if node.doBslashEscapes
			text = text.replace ///
				\\(?:
					U([0-9A-Fa-f]{8}) |
					u(?:
						([0-9A-Fa-f]{4}) |
						\{ ([0-9A-Fa-f]+) \}
					) |
					x([0-9A-Fa-f]{2}) |
					([bfnrt0]) |
					([\s\S])
				) ///g,
				(fullMatch, x8, x4, xarb, x2, letter, any) ->
					hex = x8 ? x4 ? xarb ? x2
					if hex?
						codepointToString parseInt hex, 16
					else if letter?
						switch letter
							when "b" then "\b"
							when "f" then "\f"
							when "n" then "\n"
							when "r" then "\r"
							when "t" then "\t"
							when "0" then "\0"
					else
						any
		text


textOfStringNode = (node) -> node.visit stringTextVisitable
	


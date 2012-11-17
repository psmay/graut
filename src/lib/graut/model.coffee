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

extend exports,
	InterpolatedValue: class InterpolatedValue
		constructor: (@token, @values, @open, @close) ->
	
	StringValue: class StringValue
		constructor: (@token, @rawText, @doBslashEscapes, @open, @close) ->

	ListValue: class ListValue
		constructor: (@token, @values) ->

	InlineOp: class InlineOp
		constructor: (@token, @topic) ->

	ExpandOp: class ExpandOp
		constructor: (@token, @topic) ->

	ApplyOp: class ApplyOp
		constructor: (@token, @topic) ->
	
	NonceOp: class NonceOp
		constructor: (@token) ->
	
	parseError: (tokenInfo, message) ->
		locator = if tokenInfo?
			"#{tokenInfo.startLine}:#{tokenInfo.startColumn}: "
		else
			""
		message ?= "Assert failed"

		throw new Error "#{locator}#{message}"

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

dsl = require "./grammarDsl"

# Bullet
o = (elements...) -> elements

#
# Grammar
#

parserSpec = dsl.convertToParserSpec 'Top',
	Top: [
		o '', -> new InterpolatedNode
			values: []
		o 'TopElements', -> new InterpolatedNode
			values: $1
	]
	TopElements: [
		o 'TopElement', -> [$1]
		o 'TopElements TopElement', -> $1.concat [$2]
	]
	TopElement: [
		o 'TopText', -> $1
		o 'Sigiled', -> $1
	]
	TopText: [
		o 'TEXT', -> new StringNode
			textToken: $1
	]
	Sigiled: [
		o 'SIGIL Topic',	-> new SigilNode
			sigilToken: $1
			topic: $2 ? undefined
	]
	Topic: [
		o 'Element', -> $1
		o 'EMPTYTOPIC', -> null
	]
	Space: [
		o 'SPACE'
	]
	SpaceOpt: [
		o 'Space'
		o ''
	]
	SsElementsOpt: [
		o 'SsElements',						-> $1
		o '',								-> []
	]
	# Space-suffixed
	SsElements: [
		o 'SsElement',						-> [$1]
		o 'SsElements SsElement',			-> $1.concat [$2]
	]
	SsElement: [
		o 'Element SpaceOpt',				-> $1
	]
	Element: [
		o 'List', -> $1
		o 'Sigiled', -> $1
		o 'PlainText', -> $1
		o 'InterpolatedText', -> $1
	]
	ListContents: [
		o 'SpaceOpt SsElementsOpt', -> $2
	]
	List: [
		o 'DOWN ListContents UP', -> new ListNode
			openToken: $1
			values: $2
			closeToken: $3
	]
	PlainText: [
		o 'UnquotedString', -> $1
		o 'TriquotedString', -> $1
		o 'ShallowHeredoc', -> $1
	]
	InterpolatedText: [
		o 'MonoquotedString', -> $1
		o 'DeepHeredoc', -> $1
	]
	UnquotedString: [
		o 'STRING0', -> new StringNode
			textToken: $1
	]
	TriquotedString: [
		o 'STRING3START TriquotedText STRING3END', -> new StringNode
			textToken: $2
			openToken: $1
			closeToken: $3
	]
	TriquotedText: [
		o 'STRING3TEXT', -> $1
		o '', -> ''
	]
	ShallowHeredoc: [
		o 'SHSTART ShallowHeredocText SHEND', -> new StringNode
			textToken: $2
			openToken: $1
			closeToken: $3
	]
	ShallowHeredocText: [
		o 'SHTEXT', -> $1
		o '', -> ''
	]
	MonoquotedString: [
		o 'STRING1START MonoquotedPartsOpt STRING1END', ->
			new InterpolatedNode
				values: $2
				startToken: $1
				endToken: $3
	]
	MonoquotedPartsOpt: [
		o 'MonoquotedParts', -> $1
		o '', -> []
	]
	MonoquotedParts: [
		o 'MonoquotedPart', -> [$1]
		o 'MonoquotedParts MonoquotedPart', -> $1.concat [$2]
	]
	MonoquotedPart: [
		o 'MonoquotedText', -> $1
		o 'Sigiled', -> $1
	]
	MonoquotedText: [
		o 'STRING1TEXT', -> new StringNode
			textToken: $1
			doBslashEscapes: true
	]
	DeepHeredoc: [
		o 'DHSTART DeepHeredocPartsOpt DHEND', ->
			new InterpolatedNode
				values: $2
				startToken: $1
				endToken: $3
	]
	DeepHeredocPartsOpt: [
		o 'DeepHeredocParts', -> $1
		o '', -> []
	]
	DeepHeredocParts: [
		o 'DeepHeredocPart', -> [$1]
		o 'DeepHeredocParts DeepHeredocPart', -> $1.concat [$2]
	]
	DeepHeredocPart: [
		o 'DeepHeredocText', -> $1
		o 'Sigiled', -> $1
	]
	DeepHeredocText: [
		o 'DHTEXT', -> new StringNode
			textToken: $1
			doBslashEscapes: true
	]

{ Parser } = require 'jison'

exports.parser = new Parser parserSpec

# For debugging purposes
# console.log(JSON.stringify(parserSpec, null, '\t'))

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
		o '', -> new InterpolatedValue null, []
		o 'TopElements', -> new InterpolatedValue null, $1
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
		o 'TEXT', -> new StringValue $1, false
	]
	Sigiled: [
		o 'SIGIL Element',	->
			sigil = $1
			elem = $2
			if elem is null
				switch sigil.text
					when "$" then new EmptyOp sigil
					else parseError sigil, "This sigil requires a topic"
			else if elem instanceof InlineOp
				parseError elem, "Inlined elements cannot be used as sigil topic"
			else switch sigil.text
				when "#" then new CallOp sigil, elem
				when "$" then new ExpandOp sigil, elem
				when "@" then new InlineOp sigil, elem
				else parseError sigil, "Assert failed: Unrecognized sigil"
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
		o 'SsElements',						-> [$1]
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
		o 'UP ListContents DOWN', -> new ListValue $2[0..]
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
		o 'STRING0', -> new StringValue $1, false
	]
	TriquotedString: [
		o 'STRING3START TriquotedText STRING3END', ->
			new StringValue $2, false, $1, $3
	]
	TriquotedText: [
		o 'STRING3TEXT', -> $1
		o '', -> ''
	]
	ShallowHeredoc: [
		o 'SHSTART ShallowHeredocText SHEND', ->
			new StringValue $2, false, $1, $3
	]
	ShallowHeredocText: [
		o 'SHTEXT', -> $1
		o '', -> ''
	]
	MonoquotedString: [
		o 'STRING1START MonoquotedPartsOpt STRING1END', ->
			new InterpolatedValue $2, $1, $3
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
		o 'STRING1TEXT', -> new StringValue $1, true
	]
	DeepHeredoc: [
		o 'DHSTART DeepHeredocPartsOpt DHEND', ->
			new InterpolatedValue $2, $1, $3
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
		o 'DHTEXT', -> new StringValue $1, true
	]

{ Parser } = require 'jison'

exports.parser = new Parser parserSpec

# For debugging purposes
# console.log(JSON.stringify(parserSpec, null, '\t'))

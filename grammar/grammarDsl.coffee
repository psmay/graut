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

###
The logic in this file is more or less entirely cribbed from CoffeeScript's
grammar.coffee, which is:
Copyright (c) 2009-2012 Jeremy Ashkenas
Under the OSI version of MIT license (same as graut itself).
###

# However, I've stuffed it all into a self-contained function and separated it
# from the grammar itself.


exports.convertToParserSpec = (startSymbol, rules) ->
	unwrap = /^function\s*\(\)\s*\{\s*return\s*([\s\S]*);\s*\}/
	
	convertBullet = (patternString, action, options) ->
		patternString = patternString.replace /\s{2,}/g, ' '
		return [patternString, '$$ = $1;', options] unless action
		action = if match = unwrap.exec action then match[1] else "(#{action}())"
		# Prefix our local stuff with yy. so the parser stuff can see it
		action = action.replace /\b(?:new|instanceof) /g, '$&yy.'
		action = action.replace /\bsemanticError\b/g, 'yy.$&'
		[patternString, "$$ = #{action};", options]
	
	bnf = {}
	tokens = []
	for name, bullets of rules
		bnf[name] = for bullet in bullets
			alt = convertBullet(bullet...)
			for token in alt[0].split ' '
				tokens.push token unless rules[token]
			alt[1] = "return #{alt[1]}" if name is startSymbol
			alt
	
	parserSpec =
		tokens: (tokens.join ' ').replace(/\s+/g,' ').replace(/^\s|\s$/g,'')
		bnf: bnf
		startSymbol: startSymbol



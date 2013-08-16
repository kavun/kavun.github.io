---
published: false
---

## Javascript Style Guide

### Indentation
An indent is equal to one tab. This allows the developer to configure how many spaces to show for each tab in their editor. Indent with tabs, and space with Spaces. Spaces should never occur on a line in front of a statement.

```js
// Good
function indent() {
	var noSpaces = true;
	var onlyUseTabs = true;
}

// Bad
function badIndent() {
	var onlySpaces = false;
   var onlyTabs = false;
}
```

### Operator Spacing
Operators with two operands must be preceded and followed by a single space to make the expression clear. Operators include assignments and logical operators.

```js
// bad
for (var i=0; i<50; i++) {
}

// good
for (var i = 0; i < 50; i++) {
}

//good
var spacedCorrectly = (50 < 100 && count === 0);
```

### Parenthesis Spacing
There should be no whitespace after an opening paren or before a closing paren.

```js
// bad
if ( sad ) {
	obj.fn( sad );
}
//good
if (sad) {
	obj.fn(sad);
}
```

### Function Spacing
Named functions should have no space between the function name and open paren for the parameter list. Anonymous (unnammed) functions should have one space between `function` and the opening paren.

```js
// bad
function namedFunction () {
}
var fn = function() {
};
obj.test(function() {
});

// good
function namedFunction() {
}
var fn = function () {
};
obj.test(function () {
});
```

### Semicolons
There should be at most one statement per line. Every statement should end with a semicolon. It is better to be safe than to assume that ASI will cover your mistakes.

```js
// bad
function createError() {
	var one = 1;
	var two = 2
	return
	{
		msg: ‘uh oh’
	};
}

// good
function noError() {
	var one = 1;
	var two = 2;
	return {
		msg: ‘ok’
	};
}
```

### Variables
Variable declarations should occur where needed. It is not necessary to have all variable declarations at the top of each function. Each variable should be on a separate line. The comma operator is not accepted when declaring variables, except in for loops.

```js
// bad
function test() {
	var one = 1,
		two = 2,
		three;
}
// good
function test() {
	var one = 1;
	var two = 2;
}
```

### Strings
Never mix single and double quotes in the same file when defining String literals. Prefer single over double quotes for String literals. Never use a slash to create a new line in a string.

```js
// bad
var help = “I’m coming!\
and I’m bringing a friend.”;
var me   = ‘I\’m not ok.’;

// good
var help = ‘I\’m coming! and I\’m bringing a friend.’;
var me   = ‘I\’m going to be ok.’;
```

### Numbers
Never use octal literals, leading decimals or hanging decimals.

```js
// bad
var octal = 010;
var leading = .1;
var hanging = 1.;
```

### Null
Only use null is these situations:
- To initialize a variable that may later be assigned to an object value
- To compare against an initialized variable that may or may not have an object value
- To compare against both null and undefined at once
- To pass into a function where an object is expected
- To return from a function where an object is expected

```js
// good
obj.test(null, null, i);
// bad
obj.test(undefined, undefined, i);

// good
var testRetValue = obj.test();
if (testRetValue == null) {
	// testRetValue must be nothing
}
```

### Undefined
Never use the value `undefined`. It is fragile because it can be redefined. To check if a variable has been initialized use the `typeof` operator, or `void 0` to ensure a valid instance of `undefined`.
```js
// good
if (typeof test === 'undefined') {
}
// good
if (test === void 0) {
}
// bad
if (test === undefined) {
}
```
To check is an object has a property, use the `in` operator, or `Object.prototype.hasOwnProperty()`. Do not use `.hasOwnProperty()` on DOM elements, because they do not have this method in IE7/8.
```js
// good
if ('test' in obj) {
}
// good
if (obj.hasOwnProperty('test')) {
}

// bad
var domElement = document.getElementById('testId');
if (domElement.hasOwnProperty('textContent')) {
}
// ok
if ({}.prototype.hasOwnProperty.call(domElement, 'textContent')) {
}
// better
if ('textContent' in domElement) {
}
```







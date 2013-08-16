---
published: false
---

## Javascript Style Guide

### Indentation
An indent is equal to one tab. This allows the developer to configure how many spaces to show for each tab in their editor. Indent with tabs, and space with spaces. Spaces should never occur on a line in front of a statement. Do not mix spaces and tabs.

```js
// good
function indent() {
	var noSpaces = true;
	var onlyUseTabs = true;
}

// bad
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

// good
var spacedCorrectly = (50 < 100 && count === 0);
```

### Parenthesis Spacing
There should be no whitespace after an opening paren or before a closing paren.

```js
// bad
if ( sad ) {
	obj.fn( sad );
}

// good
if (sad) {
	obj.fn(sad);
}
```

### Brackets
Brackets should be preceded by a space unless being used to pass an object literal as an argument to a function, in which case it should not be preceded by a space.
```js
// bad
if(true){
}

// good
if (true) {
}

// bad
obj.test( {
	row: 0,
    cell: 0
} );

// good
obj.test({
	row: 0,
    cell: 0
});
```
Always use brackets with `if`, `for`, `while`, and other compound statements. `else` should always be on the same line as the closing bracket on the preceding `if` statement.
```js
// bad
while (i--) obj.test();

// good
while (i--) {
	obj.test();
}

// good
if (1 < 2) {
	obj.test1();
} else {
	obj.test2();
}

// bad
if (1 < 2)
	obj.test1();
else
	obj.test2()
```

### Function Spacing
Named functions should have no space between the function name and open paren for the parameter list. Anonymous (unnamed) functions should have one space between `function` and the opening paren. This way, anonymous functions will appear like "functions with no name".

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

- Variable declarations should occur where needed. It is not necessary to have all variable declarations at the top of each function.
- Each variable should be on a separate line. The comma operator is not accepted when declaring variables, except in for loops. This allows adding and removing variable declarations trivial.
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
Do not declare `for` loop iteration variables outside of the `for` loop definition.
```js
// bad
var i = 0, l = arr.length;
for ( ; i < l; i++) {
}

// good
for (var i = 0, l = arr.length; i < l; i++) {
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
**Never** use the value `undefined`. It is fragile because it can be redefined. To check if a variable has been initialized use the `typeof` operator, or `void 0` to ensure a valid instance of `undefined`. Prefer `typeof`.
```js
// good
if (typeof test === 'undefined') {
}

// ok
if (test === void 0) {
}

// bad
if (test === undefined) {
}
```
To check if an object has a property, use the `in` operator, or `Object.prototype.hasOwnProperty()`. Do not use `.hasOwnProperty()` on DOM elements, because they do not have this method in IE7/8.
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

### for ... in
When using `for ... in`, always check if the object has each property. This is especially necessary for looping over an `Array` because `for ... in` checks all the way up the prototype chain.
```js
// good
for (var prop in obj) {
	if (obj.hasOwnProperty(prop)) {
    	var val = obj[prop];
    }
}
```

### Object literals

- Opening brace should be on the same line as the containing statement
- Each property value should be intendented once on the line underneath the opening brace
- Do not quote property names
- Do not insert a space preceding the colon between property names and values
- If the value is a function there should be an empty line preceding and following it
- The closing brace should be on the last line by itself, followed by a semicolon

```js
// good
var obj = {
	one: 1,
    
    isTwo: function (num) {
    	return (num === 2);
    },
    
    three: 3,
    four: 4
};

// bad - all on same line, no semicolon, quoted property name
var obj = { one: 1, 'two': 2 }
```

### Literals vs. Constructors
Use literals instead and native coersion instead of native Object contructors. Basically, never use the native Object constructors

```js
var obj = new Object(); // bad
var obj = {}; // good

var arr = new Array(); // bad
var arr = []; // good

var arr = new Array('a', 'b', 'c'); // very bad
var arr = ['a', 'b', 'c']; // good

var regex = new RegExp('abc'); // ok
var regex = /abc/; // good

var str = ('' + value); // good
var str = new String(value); // bad

var now = (+'2'); // good
var now = new Number('2'); // bad
```

### Comments

- Comment frequently to help other developers understand your code.
- Keep comments updated. Comments pertaining to deleted code, and misleading comments are worse than no comments.
- Document code using JSDoc. Document constuctors, objects, and methods.
- All comments on their own line including documentation comments should be preceded by an empty line.

### Single Line Comments

```js
// bad
function test() {
	var value1;
	// this should be preceded by an empty line
    var value2;
}

// good
var obj1 = 1; // comments on the same line are ok
var obj = {
	
    // the is readable
    prop1: value1,
    
    // so is this
    prop2: value2
};
```

### Multiline Comments
Use `/*` to begin multiline comments the are not documentation instead of the JSDoc standard of `/**`. There should be no comment on the first line after the first asterisk. All asterisks should be vertically aligned, and the last line should end with `*/`.

```js
//good

/**
 * this function will test something
 * @param {Array} arg1 - an array
 */
function test(arg1) {
	
    /*
     * this array will do bla-bla
     * and be used for bla-bla
     */
	var arr = arg1;
}
```






---
comments: true
date: "2013-10-19"
layout: "post"
slug: "understanding-the-shortcut-for-array-prototype-slice"
title: "Understanding the Shortcut for Array.prototype.slice"
summary: "Wrapping my head around Function.prototype.call.bind(Array.prototype.slice)"
tags: ["Javascript"]
---
There are [many scenarios](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Functions_and_function_scope/arguments#Examples) when accessing the `arguments` object as an array can be useful. Once the `arguments` object is copied to an array, the `Array.prototype` methods like `[].map` or `[].filter` can be used directly. To do so we can simply call `Array.prototype.slice` with `arguments` as the `this` object and pass no arguments, which will create a shallow copy of the `arguments` object as an array.

{% highlight javascript %}
function getArgumentsAsArray() {
    return Array.prototype.slice.call(arguments);
}

getArgumentsAsArray(1, 2, 3);
// > [1, 2, 3]
{% endhighlight %}

This, is nice, but many places you will see examples of code that uses a bound slice function directly on the `arguments` object.

{% highlight javascript %}
function getArgs() {
    return slice(arguments);
}
{% endhighlight %}

How is this `slice` function created? There is an [example on MDN](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Function/bind#Supplemental) of how you can create this bound slice function doing

{% highlight javascript %}
var slice = Function.prototype.call.bind(Array.prototype.slice);
{% endhighlight %}

What is going on here? First, we need to understand the `bind` function. `Function.prototype.bind` will force a function to be executed in a specified context with the `this` object inside that function being whatever you decide. So if you have a function that needs a different `this` object bound to it, you can use `Function.prototype.bind`. A very simplified version of `bind` would look like:

{% highlight javascript %}
function bind(fn, thisObj) {
    return function () {
        return fn.apply(thisObj, arguments);
    };
}
{% endhighlight %}

This is not the [full implementation](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Function/bind#Compatibility) of `Function.prototype.bind`, but it is enough for our needs right now. So, this can be used as follows:

{% highlight javascript %}
function returnThis() {
    return this;
}

returnThis();
// > Window

var boundReturner = bind(returnThis, { test: 0 });
boundReturner();
// > Object {test: 0}
{% endhighlight %}

So now that we can bind functions, how can we use this to create a shortcut for `Array.prototype.slice`? Well, in the example `var slice = Function.prototype.call.bind(Array.prototype.slice);`, we see that `call` is the function that is receiving the binding, and `slice` is the "object" that is bound as the `this` object for `call`. This may be confusing because `slice` is a function, but is still being bound as the `this` object. The binding is necessary because as you see in the first example of copying `arguments` to an array, `call` is being called **as a method of slice**. `Array.prototype.slice.call(arguments)` will make `slice` the `this` object for `call`. It the same for any method in javascript. The calling object is the `this` object for the method being called. So to create the bound slice shortcut function with our simple `bind` function we need to bind `slice` to `call`.

{% highlight javascript %}
var slice = bind(Function.prototype.call, Array.protoype.slice);
// or
var slice = bind(function () {}.call, [].slice);
{% endhighlight %}

And then to use it

{% highlight javascript %}
function getArgs() {
    return slice(arguments);
}
getArgs(1, 2, 3);
// > [1, 2, 3]
{% endhighlight %}

Although, if we don't have access to a `bind` function, we don't have to use it. We can utilize `Function.prototype.apply` to apply `slice` to `call` and pass our `arguments` object.

{% highlight javascript %}
var slice = function () {
    return Function.prototype.call.apply(Array.prototype.slice, arguments);
};
{% endhighlight %}

The version with `bind` is much cleaner and more functional, but seeing the example without `bind` helps us understand exactly what is happening.

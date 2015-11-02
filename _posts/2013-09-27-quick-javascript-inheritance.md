---
comments: true
date: 2013-09-27
layout: post
slug: quick-javascript-inheritance
title: Quick Javascript Inheritance
summary: 'Using jQuery.extend to create quick and dirty inheritance.'
---

Sometimes its best to keep things quick.

[`Object.create(Person.prototype)`](http://javascript.crockford.com/prototypal.html) is pretty simple, but what if we want an inheriting object to overwrite some properties as well as methods? By creating a new object from another's `prototype`, you are only inheriting methods, unless you just don't care and put [all your data in an object's `prototype`](http://www.2ality.com/2013/09/data-in-prototypes.html).

Of course [there are](https://github.com/Gozala/selfish) [more complex methods](http://ejohn.org/blog/simple-javascript-inheritance/) [of achieving inheritance](https://github.com/linkedin/Fiber) in javascript, but a lot of those require the use of an api that abstracts from bare bones javascript. Bare bones is good.

So lets keep things simple, quick, and a little dirty. Use [`$.extend`](http://api.jquery.com/jQuery.extend/) directly onto the created instance to create an inheritance chain. If jQuery is not your cup of tea, [`_.extend`](http://underscorejs.org/docs/underscore.html#section-78), or any [generic object extending function](https://github.com/segmentio/extend/blob/master/index.js) will work.

{% highlight javascript %}
function Person(options) {
    $.extend(this, Person.defaults, options);
}

Person.defaults = {
    name: '',
    age: 0
};

Person.prototype.makeImmortal = function () {
    this.age = Infinity;
};

function Guy(options) {
    $.extend(this, new Person(options), Guy.defaults, options);
}

Guy.defaults = {
    gender: 'male'
};

Guy.prototype.sayName = function () {
    return this.name;
};

/*
var person = new Person();
> Person {name: "", age: 0, makeImmortal: function}

var guy = new Guy();
> Guy {name: "", age: 0, makeImmortal: function, gender: "male", sayName: function}
*/
{% endhighlight %}

Is `new Guy() instanceof Person === true`? Of course not. Did I say it was quick and dirty? Yes.

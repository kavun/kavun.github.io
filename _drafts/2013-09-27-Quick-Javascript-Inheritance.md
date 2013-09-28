---
published: false
---

## Quick Javascript Inheritance

Sometimes its best to keep things quick and dirty.

`Object.create(Person.prototype)` is pretty simple, but what if we want our an inheriting object to overwrite some propertied as well as methods? By creating a new object from another's `prototype`, you are only inheriting methods, unless you just don't care and put [all your data in an object's `prototype`](http://www.2ality.com/2013/09/data-in-prototypes.html).

Of course there are more complex methods of achieving inheritance in javascript, but a lot of those require the use of an api that abstracts from bare bones javascript. Bare bones is good.

So lets keep things simple, quick, and a little dirty.

	function Person(options) {
        $.extend(this, Person.defaults, options);
    }
    
    Person.defaults = {
        name: '',
        age: 0
    };
    
    function Guy(options) {
        $.extend(this, new Person(options), Guy.defaults, options);
    }
    
    Guy.defaults = {
        gender: 'male'
    };

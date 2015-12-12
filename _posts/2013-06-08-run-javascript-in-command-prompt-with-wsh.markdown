---
comments: true
date: "2013-06-08"
layout: "post"
slug: "run-javascript-in-command-prompt-with-wsh"
title: "Run Javascript in Command Prompt with WSH"
summary: "Running javascript in a system console makes you feel like a much more powerful web developer."
tags: ["Javascript"]
---

When one initially happens upon Node.js, there is something awesome about being able to run javascript in a system console. Running javascript in a browser is cool and all, but executing some javascript in a console under Windows just feels too raw to be true. [Windows Script Host][1] can run both VBScript or JScript. Ok. So we don't actually care what WSH is capable of, we just want to run javascript in command prompt, right? This "hello WSH" type script will evaluate javascript statements and print the output. Sort of feels like running javascript on a Node.js REPL?

* Clone [this gist][3] from `https://gist.github.com/5718851.git`
* Execute the following script in command prompt with `cscript WSHRepl.js` and type in as many js one-liners as suits your fancy.

Behold the Windows Script Host REPL

{% highlight javascript %}
function print(text) {
    WScript.Echo('> ' + text);
}

var stdin  = WScript.StdIn;
var stdout = WScript.StdOut;
var input;

do {
    var input = stdin.ReadLine();
    try {
        print(eval(input));
    } catch (e) {
        print(e.name + ': ' + e.message);
    }
} while (input != 'exit');
{% endhighlight %}

This obviously isn't very useful other than maybe fiddling with Microsoft's implementation of ECMAScript. I used the [WSH Reference][2] to find the `WScript.StdOut` and `WScript.StdIn` objects.

[1]: http://msdn.microsoft.com/en-us/library/9bbdkx3k.aspx
[2]: http://msdn.microsoft.com/en-us/library/98591fh7.aspx
[3]: https://gist.github.com/kavun/5718851
---
comments: true
date: "2013-09-21"
layout: "post"
slug: "why-I-wrote-a-javascript-style-guide"
title: "Why I Wrote a Javascript Style Guide"
summary: "My reasoning for writing my own style guide instead of choosing to use one of the many excellent style guides that already exist."
---

If you are looking for a solid style guide, this is probably not where you should be. There are a myriad of style guides that have had large teams working under their guidelines and seasoned professionals contribute to them. If you are searching for one of the prior style guides, they are easy to find. I am not a seasoned professional, nor do I work on a large team of javascript developers. However, I am becoming increasingly more passionate about javascript and writing consistent, clean javascript. Messy and inconsistent javascript is easy to write - the langauge is privy of this. Working in a large code base, it's easy to find code like this.

{% highlight javascript %}
if(document.getElementById('btnSave')!=null){
    document.getElementById('btnSave').disabled = true
    document.getElementById('btnApprove').disabled = false;
}
else
{
    if (document.getElementById('btnApprove') != null)
        document.getElementById('btnApprove').value = "Approved";
        document.getElementById('btnApprove').disabled = true;
    document.getElementById('printArea').innerText = response;
}
{% endhighlight %}

This is a hypothetical code sample, but apart from the fact that this code is not cross browser compliant javascript, nor does it apply the DRY principle, whoever wrote this probably does not really have much experience with javascript. If this developer would have followed my style guide it could look something like this.

{% highlight javascript %}
var textType = null;
if ('innerText' in document.createElement('div')) {
    textType = 'innerText';
} else {
    textType = 'textContent';
}

var btnSave = document.getElementById('btnSave');
var btnApprove = document.getElementById('btnApprove');
if (btnSave) {
    btnSave.setAttribute('disabled', 'disabled');
    btnApprove.removeAttribute('disabled');
} else {
    if (btnApprove) {
        btnApprove.value = 'Approved';
        btnApprove.setAttribute('disabled', 'disabled');
    }
    document.getElementById('printArea')[textType] = response;
}
{% endhighlight %}

Suppose that you are a fresh graduate, you have little to no javascript experience, you just landed a new job, and are tasked with writing some javascript to wire up a click handler on a button that executes some task. Also suppose that the only javascript on the page is the above code sample. What are you going to do? Copy the style of the code in front of you. (1) The developer might not know better, and (2) he wants his code to be accepted in a code review, so he is going to make it look similar to the code around his.

This is the starting point for many javascript headaches to come in the future for any new javascript developer. Adding functionality into an existing app should be a learning experience. However, if a code base is messy, hard to read, or just plain wrong, how will one learn to write anything better? Not every developer has the will power to read about javascript design patterns on the weekend. We have to cultivate spaces in which all developers can learn from - just by looking at the code that they contribute to.

Clean, easy to read code is fun to write, and is something to be proud of once completed. This style guide ensures where my passion is. Its not in just getting the job done, or even having my code review accepted at first glance. My passion is in writing code that will not only teach other developers who contribute to the same code base, but code that pushes me to write clean, idiomatic, bug free code.

I recommend anyone new to javascript to write a style guide simply to know what you like or don't like about the language. It also forces you to research why one style is accepted over another style. Not using `undefined`, when and when not to use `null`, and the reasoning behing placing semicolons everywhere are examples of practices that I did not fully understand until researching for the style guide.

[Here is my javascript style guide.](https://github.com/kavun/js-style-guide)

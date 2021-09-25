---
layout: post
title: Using fetch correctly
tags: JavaScript
category: "Code Snippets"
---
One of my projects is using [axios](https://github.com/axios/axios) to handle
AJAX calls. However, the project comes from a framework that is very opinionated
as far as the front end setup. It comes with its own custom webpack setup and
javascript boilerplate. It is fine to not worry about setting up your JavaScript
environment when everything is built for you, but when you have a coding test or
a fairly simple or short-term project that just needs to get going, you need to
know how to do things yourself.

That brings us to [fetch](https://developer.mozilla.org/en-US/docs/Web/API/Fetch_API).
It's already part of 95% of [browsers](https://caniuse.com/#search=fetch)
(except for Internet Exploder and Opera Mini at the time of this writing), so
unless you absolutely need that last 5%, it looks fine. It does work a little
differently than axios, so it needs a slightly different structure.

{% highlight javascript linenos %}
// Setup the data to be sent.
const postData = {
  meat: 'good',
  jam: 'good',
  broccoli: 'icky'  
}

// Setup the request.
const request = new Request('/api.php', {
  body: JSON.stringify(postData),
  headers: { 'Content-Type': 'application/json' },
  method: 'POST',
  mode: 'same-origin'
  })

// Before the fetch() call might be a good place to display a spinner, disable buttons, or manipulate the DOM.
fetch(request).then(response => {
    // fetch doesn't handle errors the same was as axios.
    if (!response.ok) {
      alert(`Unable to fetch from API. Server Error ${response.status}.`)
    }
    return response
  })
  .then(result => result.json())
  .then(data => {
      doSomethingWith(data) // You have a good payload. Use it here.
   })
  .catch((error) => {
    // But, you can still get an error. Do something good here.
    alert(error)
  })
  .finally(() => {
    // Here the spinner can be removed, or other UI manipulations 
})

{% endhighlight %}

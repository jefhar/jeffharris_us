---
layout: post
title: Using fetch correctly
tags: JavaScript
category: Code Snippets
---
Using [fetch](https://developer.mozilla.org/en-US/docs/Web/API/Fetch_API) properly
in the client side. Setup your request, then fetch it properly:

{% highlight javascript %}
const postData = {
  meat: 'good',
  jam: 'good',
  broccoli: 'icky'  
}

const request = new Request('/api.php', {
  body: JSON.stringify(postData),
  headers: { 'Content-Type': 'application/json' },
  method: 'POST',
  mode: 'same-origin'
  })

// Before the fetch might be a good place to display a spinner or disable buttons.
fetch(request).then(response => {
    // fetch doesn't handle errors the same was as axios.
    if (!response.ok) {
      alert(`Unable to fetch from API. Server Error ${response.status}.`)
    }
    return response
  })
  .then(result => result.json())
  .then(data => {
      doSomethingWith(data) // You have a good payload.
   })
  .catch((error) => {
    // But you can still get an error. Do something good here.
    alert(error)
  })
  .finally(() => {
    // Here the spinner can be removed, or other UI manipulations 
})

{% endhighlight %}

# simple-ajax

Simple ajax module.


## Usage

``` javascript
var Ajax = require('simple-ajax'),
    ajax = new Ajax('https://api.github.com/users/octocat/orgs');

ajax.on('success', function(event) {
    console.log('success', event);
});

ajax.send();
```

#### Or Provide Options Object

``` javascript
var ajax = new Ajax(
        {
            url: 'https://api.github.com/users/octocat/orgs',
            method: 'GET',
            headers: {
                myCustomHeader: 'my custom header value'
            }
        }
    );
```

### Available Options

``` javascript
{
    url: 'url to request',
    method: 'method to request with',
    cors: 'is CORS request (only needed for IE)',
    cache: 'set to false to explicitly break cache',
    data: 'JSON data to be sent with request',
    dataType: 'type of expected response',
    contentType: 'if JSON will try to parse response data',
    requestedWith: 'defaults to XMLHttpRequest',
    auth: 'used to set the Authorization header',
    headers: 'custom headers object'
}
```

### Add Event Listeners

``` javascript
ajax.on('success', function(event) {
    console.log('success', event);
});

ajax.on('error', function(event) {
    console.log('error', event);
});

ajax.on('complete', function(event) {
    console.log('complete', event);
});
```

### Send Request

``` javascript
ajax.send();
```
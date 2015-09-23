var Ajax = require('../');

var ajax = new Ajax({
    url: 'https://api.github.com/users/octocat/orgs?thing=majigger',
    data: {
        foo: ['a', 'b', 'c'],
        stuff: 'meh'
    }
});

ajax.on('success', function(event) {
    console.log('success', event);
});

ajax.on('error', function(event) {
    console.log('error', event);
});

ajax.on('complete', function(event) {
    console.log('complete', event);
});

ajax.send();
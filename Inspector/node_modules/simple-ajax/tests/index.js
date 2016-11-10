var Ajax = require('../'),
    tape = require('tape');

function test(message, settings, testFn){
    if(arguments.length < 3){
        testFn = settings;
        settings = {};
    }

    settings.timeout = 2500;

    tape.apply(null, Array.prototype.slice.call(arguments, 0, -1).concat([function(t){
        testFn.apply(this, arguments);
        t._plan++;
        setTimeout(function(){
            t.pass();
        }, 2000);
    }]));
}

test('simple get', function(t){
    t.plan(2);

    var ajax = new Ajax({
        url: 'https://api.github.com/users/octocat/orgs?thing=majigger',
        data: {
            foo: ['a', 'b', 'c'],
            stuff: 'meh'
        }
    });

    ajax.on('success', function(event) {
        t.pass('should succeed');
    });

    ajax.on('error', function(event) {
        t.fail('should not error');
    });

    ajax.on('timeout', function(event) {
        t.fail('should not timeout');
    });

    ajax.on('complete', function(event) {
        t.pass('should complete');
    });

    ajax.send();
});

test('404', function(t){
    t.plan(3);

    var ajax = new Ajax({
        timeout: 1000,
        url: 'https://api.github.com/notactuallyaroute',
        data: {
            foo: ['a', 'b', 'c'],
            stuff: 'meh'
        }
    });

    ajax.on('success', function(event) {
        t.fail('Should not succeed');
    });

    ajax.on('error', function(event) {
        t.pass('should 404');
        t.equal(event.target.status, 404, 'should 404');
    });

    ajax.on('timeout', function(event) {
        t.fail('should not timeout');
    });

    ajax.on('complete', function(event) {
        t.pass();
    });

    ajax.send();
});
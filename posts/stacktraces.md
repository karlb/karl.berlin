# Stack Traces are Underrated

## I Love Stack Traces
When something goes wrong in a program, many languages will spit out a stack trace with lots of useful information. Here's an example from one of my Python programs:

```
Traceback (most recent call last):
  File "/home/piku/.piku/envs/wikdict/lib/python3.11/site-packages/flask/app.py", line 1511, in wsgi_app
    response = self.full_dispatch_request()
               ^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/home/piku/.piku/envs/wikdict/lib/python3.11/site-packages/flask/app.py", line 919, in full_dispatch_request
    rv = self.handle_user_exception(e)
         ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/home/piku/.piku/envs/wikdict/lib/python3.11/site-packages/flask/app.py", line 917, in full_dispatch_request
    rv = self.dispatch_request()
         ^^^^^^^^^^^^^^^^^^^^^^^
  File "/home/piku/.piku/envs/wikdict/lib/python3.11/site-packages/flask/app.py", line 902, in dispatch_request
    return self.ensure_sync(self.view_functions[rule.endpoint])(**view_args)  # type: ignore[no-any-return]
           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/home/piku/.piku/apps/wikdict/wikdict_web/lookup.py", line 119, in lookup
    if r := get_combined_result(lang, other_lang, query):
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/home/piku/.piku/apps/wikdict/wikdict_web/lookup.py", line 91, in get_combined_result
    conn = get_conn(lang + "-" + other_lang)
           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/home/piku/.piku/apps/wikdict/wikdict_web/base.py", line 103, in get_conn
    raise sqlite3.OperationalError(
sqlite3.OperationalError: Database file "/home/piku/.piku/data/wikdict/dict/en-ko.sqlite3" does not exist
```

Beautiful! In addition to the error, I immediately see the line that
caused the error, the full call stack and I have the file paths and line
numbers at hand to [quickly jump to each of the locations](https://github.com/karlb/vim-pytest-traceback).
Often, this is all I need to fix the problem.

## The Case of the Missing Trace

Stack traces are already a common debugging tool for decades, but unfortunately they are not ubiquitous and in some cases, they even disappear where we used to have them.
Let's take a look at a few of these cases.

### Modern Error Handling

Many people dislike exceptions since they break the usual control flow and make it easy to skip proper error handling. So instead of raising exceptions, they return errors as special return values. This was always the case in C because it doesn't have exceptions, but also more modern languages like Go and Rust do this, although in a nicer way. But this approach does not yield stack traces since the functions return normally, just with different values. So instead of the beautiful stack trace above, Go will give you

```
wrong number of elements
```

or, if the author was diligent and added context (preferably with `fmt.Errorf`'s `%w` format string) each time the error is passed along, something like:

```
can't load data: failed to parse header: wrong number of elements
```

While these prefixes resemble a poor man's stack trace, they
* don't show the file and line number
* don't show the code
* can be ambiguous (the same error message or prefix could be used in multiple places in the source)
* can't be trusted to be constructed consistently

The situation in Rust is similar, where errors are also passed as return values, just with more interesting typing than in Go. But Rust has a better workaround to create stack traces: the [`backtrace` module](https://doc.rust-lang.org/std/backtrace/index.html), which allows capturing stack traces that you can then add to the errors you return. The main problem with this approach is that you still have to add the stack trace to each error and also trust library authors to do so.

### More Complicated Architectures

Not only modern programming languages, but also modern architectures can be a threat to good error traces.
More and more often, a single system is split up across many programs, often under labels like microservices, containers or serverless functions.
This allows using different programming languages between components, better isolation and scalability.
But in addition to making everything a lot more complex, it breaks stack traces!
If you have an HTTP call between your functions, you will have to put a large amount of work into your tooling to get something nearly as useful and consistent as Python's default stack traces. Most people don't and even fewer succeed at doing that.

## Closing Thoughts

So while I can understand that not everybody likes exceptions, I don't see any reasons against having stack traces. Collecting the traces can cost some performance, but that is a small price to pay for the advantages and could even be turned off in production builds.
I'm really surprised that so few people complain about the lack of stack traces in some modern programming languages and ecosystems. Are they just not used to having them so that they don't miss them? Or are they heavily relying on other tools that mitigate the problem (e.g. debuggers)?
Please let me know your thoughts on this!

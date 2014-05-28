# CLJConcurrency #

This repo tiptoes toward the question: what would it look like to organize an iOS app using  approaches to concurrency inspired by Clojure?

## Why clojure? ##

Clojure has thoughtful support for concurrent programming baked into the language at low level.

It has relatively straightforwad structures like promises, futures, and delays.

It also has more exotic facilities, like persistent data structures
(not to be confused with immutable data structures), software
transactional memory (like in Haskell?), and mutable references types inspired by
Standard ML.

Most recently, it has also acquired facilities for CSP-style
concurrency (aka "communicating sequential processes", aka golang
channels), via the core.async library. This has inspired some
interesting ferment in thinking about how to organize UI code in the browser, e.g., David Nolen's work on [CSP in ClojureScript](http://swannodette.github.io/2013/07/12/communicating-sequential-processes/).
This last development is particulatly interesting because in general the Clojure community is not about UI development. But UI development is a key locus for real concurrency challenges, which stem from coordating user events, UI updates, and higher latency operations. So if Clojure's concurrency facilities are really so great, there should be an interesting opporuntity here in trying to use them for GUI code, no?

## Why does this matter for Objective-C? ##

iOS developers deal with concurrency issues routinely, in order to
maintain UI responsiveness.

Cocoa offers some great high-level concurrency tools, notably, operation queues and dispatch queues. But for the most part, in-process communication is handled by passing messages within a graph of interlocked mutable objects.

These objects are organized using the traditional MVC pattern, which is really a bit vague (what is the controller anyway? not what you know from Rails.). Some folks are doing great work exploring other alternatives like ReactiveCocoa, MVVM, etc..

I'd like to know, what would it look like to organize a serious Cocoa app using CSP-style concurrency? Using Clojure-style concurrency primitives more generally? Does that cash out to something exactly like ReactiveCocoa? Or something else?

This repo is just an effort to think through that question.

## Notes: planned work ##

For now, never mind STM and persistent data structures.

First look into basic concurrency primitive and core.async. See if it can all be implemented on top of GCD using serial queues, semaphores, and I/O channels.

### Futures, promises, delays ###

Done. 

### CSP ###

Core.async. Communicating Sequential Processes (CSP). Golang channels.

Maybe dispatch i/o channels with NSCoding?




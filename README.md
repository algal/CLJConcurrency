# CLJConcurrency #

This repo tiptoes toward the question: what would it look like to organize an iOS app using  approaches to concurrency inspired by Clojure?

## Why clojure? ##

Clojure has thoughtful support for concurrent programming baked into the language at a low level.

It has relatively straightforwad structures like promises, futures, and delays.

It also has more exotic facilities, like persistent data structures
(not to be confused with immutable data structures), software
transactional memory (like in Haskell?), and mutable reference types
inspired by Standard ML.

Most recently, it has also acquired
facilities for CSP-style concurrency (aka "communicating sequential
processes", aka golang channels), via the core.async library. The advent of core.async has inspired some interesting ferment in
thinking about how to organize UI code in the browser, e.g., David
Nolen's work on
[CSP in ClojureScript](http://swannodette.github.io/2013/07/12/communicating-sequential-processes/).

This last development is especially interesting because in general the Clojure community is not about UI development. But UI development is a key locus for real concurrency challenges, which stem from coordinating user events, UI updates, and higher latency operations. So if Clojure's concurrency facilities are really so great, and such a novel synthesis, there should be an interesting opporuntity here in trying to use them to write GUIs in a new way, no?

## Why does this matter for Objective-C? ##

iOS developers deal with concurrency issues routinely, in order to maintain UI responsiveness.

Cocoa offers some great and widely-used high-level concurrency tools, notably, operation queues and dispatch queues. But for the most part, in-process communication is handled by passing messages within a graph of interlocked mutable objects.

Of course this is fragile. The usual remedy is to follow the traditional MVC pattern. But the truth is, MVC is a bit vague. (What is the controller anyway? If you want three answers, ask three people). Like the pirate's code, the prescriptions of MVC are more what you'd call "guidelines" than actual rules. And those guidelines are only helpful if you have a fair bit of judgment and experience, which is another way of saying it's all tacit knowledge, which itself may be another way of saying that we don't really know what we're doing.

Is there a better way? Folks are doing very interesting work with ReactiveCocoa and MVVM. But what I'd like to know is, what would it look like to organize a serious Cocoa app using CSP-style concurrency? Using Clojure-style concurrency primitives more generally? Does that cash out to something exactly like ReactiveCocoa? Like MVVM? Or something else?

This repo is just an effort to think through that question. Thoughts welcome!

## Notes: planned work ##

For now, never mind STM and persistent data structures.

First look into basic concurrency primitive and core.async. See if it can all be implemented on top of GCD using serial queues, semaphores, and I/O channels.

### Futures, promises, delays ###

Done. 

### Channels ###

WIP. implementing put, take, close.

Could later revisit this to use GCD i/o data channels with NSCoding?




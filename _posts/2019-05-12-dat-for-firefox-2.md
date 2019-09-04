---
layout: post
title: Bringing the DAT protocol to Firefox, part 2
categories:
- blog
---

In the [previous post](/blog/2019/03/22/dat-for-firefox-1.html) I outlined firstly why we would like to be able to load `dat` websites hosted on the [Dat](https://datproject.org) network in Firefox, and the first attempt to do that with the [dat-fox WebExtension](https://github.com/sammacbeth/dat-fox). In this part we will look at how [Dat-webext](https://github.com/cliqz-oss/dat-webext) overcomes the limitations of WebExtensions to provide first-class support for the dat protocol in firefox, and how the method used can also be applied to potentially enable any p2p protocol implemented in node to run in Firefox.

Last time I mentioned three limitations of the current WebExtensions APIs, which make Dat support difficult:

1. APIs for low-level networking (TCP and UDP sockets) inside the webextension context.
2. Extension-implemented protocol handlers.
3. Making custom APIs, like `DatArchive`, available to pages on the custom protocol.

## Libdweb

The first two are being directly addressed by Mozilla's [libdweb](https://github.com/mozilla/libdweb) project, which is prototyping implementations of APIs for TCP and UDP sockets, protocol handlers and more which can be run from WebExtensions. The implementations are done using [experimental apis](https://firefox-source-docs.mozilla.org/toolkit/components/extensions/webextensions/basics.html), which is how new WebExtension APIs can be tested and developed for Firefox. The APIs are implemented using Firefox internal APIs (similar to the old legacy extension stack), and can then expose a simple API to the extension.

```javascript
// protocol handler
browser.protocol.registerProtocol('dweb', (request) => new Response(...))
```

The limitation of using libdweb for an extension is that, as they are experimental APIs, there are limitations to their use. An extension using these APIs can only be run in debugging mode (which means it will be removed when the browser is closed), or must otherwise be shipped with the browser itself as a privileged 'system' addon. This means that shipping extensions using these features to end-users is currently difficult.

## Webextify

The Dat stack is composed of two main components: [Hyperdrive](https://github.com/mafintosh/hyperdrive), which implements the Dat data structures and sync protocol, and [Discovery Swarm](https://github.com/mafintosh/discovery-swarm) which is the network stack used to discover peers to sync data with. The former can already run in the browser, with the use of packagers like browserify that shim missing node libraries. As Hyperdrive does not do any networking, all node APIs it uses can be polyfilled by equivalent browser ones. Discovery swarm, on the other hand, is at its core a networking library, which expects to be able to open TCP and UDP sockets in order to communicate with the network and peers. Therefore, we have two options to get the full stack running in an extension:

1. Implement an equivalent of discovery-swarm using the libdweb APIs directly, or
2. implement node's networking using libdweb APIs.

For dat-webext, I went with the latter, primarily because thanks to other developers around the libdweb project, most of the work was already done: [Gozala](https://github.com/Gozala/) (the prime developer behind libdweb) did [an implementation](https://github.com/libdweb/dgram-adapter) by of node's `dgram` module using the experimental API underneath, and [Substack](https://github.com/substack) did the same for `net` in a [gist](https://gist.github.com/substack/7d694274e2f11f6925299b01b31b2efa). To that we add a simple implementation of `dns`, using the already existing [browser.dns](https://developer.mozilla.org/en-US/docs/Mozilla/Add-ons/WebExtensions/API/dns) API, then we have all the shims needed to 'webextify' the entire dat-node implementation.

Putting this together, we can now use discovery swarm directly in our extension code:

```javascript
var swarm = require('discovery-swarm');
// do networking things
```

Then, using a browserify fork:

```bash
npm install @sammacbeth/webextify
webextify node_code.js > extension_code.js
```

## Putting it together

Now we have `webextify` for Dat modules, and the protocol handler API to make a handler for the `dat` protocol, we can write an extension which can serve content for `dat://` URLs with little extra effort, for example using beaker's [dat-node](https://github.com/beakerbrowser/dat-node) library:

```javascript
const { createNode } = require('@sammacbeth/dat-node')
const node = createNode({ storage, dns })

browser.protocol.registerProtocol('dat', (request) => {
    const url = new URL(request.url)
    const archive = await node.getArchive(request.url)
    const body = await archive.readFile(url.path)
    return new Response(body)
})
```

Storage of hyperdrive data (to allow offline access) is done using [random-access-idb-mutable-file](https://github.com/Gozala/random-access-idb-mutable-file), which provides a fast, Firefox compatible, implementation of the generic random-access-storage API used by hyperdrive.

[dat-webext](https://github.com/cliqz-oss/dat-webext) glues together these different pieces to provide a protocol handler with much the same behaviour as in the [Beaker browser](https://beakerbrowser.com/), including:

- Versioned Dat URLs: `dat://my.site:99/`.
- [web_root](https://beakerbrowser.com/docs/apis/manifest#web-root) and [fallback_page](https://beakerbrowser.com/docs/apis/manifest#fallback-page) directives in `dat.json`.
- Resolution of `index.htm(l)?` for URLs that point to folder roots.
- Directory listing for paths with no index file.

## DatArchive

The last requirement is to create a `DatArchive` object that is present on the `window` global for `dat://` pages. Here, we initially have an issue: the method of injecting this via [content-script](https://developer.mozilla.org/en-US/docs/Mozilla/Add-ons/WebExtensions/Content_scripts) as we did for dat-fox doesn't work. As custom protocols are an experimental feature, it is not possible to register urls of that protocol for content-script injection with the current APIs. However, as we are using experimental APIs now, we can write a new API to bypass this limitation!

In dat-webext we package an [extra experimental API](https://github.com/cliqz-oss/dat-webext/tree/master/addon/processScript), called `processScript`. This API allows the extension to register a script to be injected into dat pages. This injection is done using privileged APIs which means we can also guarantee that this injection happens before any script evaluation on the actual page, meaning that we can ensure that `DatArchive` is present even for inline page scripts - fixing a limitation of the injection method used by dat-fox. The API also exposes a messaging channel so `postMessage` calls in the page are delivered to the extension background script, messages from background are delivered as 'message' events in the page.

## Try it out!

You can test out dat-webext in [Firefox Nightly](https://www.mozilla.org/en-US/firefox/channel/desktop/#nightly) or [Developer Edition](https://www.mozilla.org/en-US/firefox/developer/):

```bash
git clone https://github.com/cliqz-oss/dat-webext
cd dat-webext
npm install
npm run build
npm run start
```

![Dat-webext-demo](/assets/images/dat-webext-demo.png)

## Summary

Dat-webext allows the dat protocol to be integrated into Firefox, and makes the experience of loading `dat://` URLs the same as for any other protocol the browser supports. As Dat syncing and networking now reside in the browser process, as opposed to a separate node process as in dat-fox, data from dat archives is properly stored inside the user profile directory. Resources are also better utilised, as an extra node runtime is not required - all code runs in Firefox's own SpiderMonkey engine.

The challenge with dat-webext is distribution: Firefox addon and security policies mean that it cannot be installed as a plain addon from the store. It also cannot be installed manually without adjusting the browser sandbox levels, which can incur a security risk. 

What we can do is bundle the addon with a Firefox build. In this setup the extension is a 'system addon', which permits it to use experimental APIs. We did this with the [Cliqz fork of Firefox](https://github.com/cliqz-oss/browser-f) and tested on the beta channel there. However, there are also further issues to solve with the application sandbox on Mac and Linux blocking the extension creating TCP sockets. Due to this, we don't have the extension fully working yet on this channel, but we're close!

Firefox is not the only possible target for libdweb-based projects though. Firefox is based on Gecko, and with the brilliant [GeckoView](https://github.com/mozilla/geckoview) project, we can have Gecko without Firefox. This opens up lots of possibilities, for example on android the dat-webext extension can run inside a Geckoview and provide dat-capabilities to any app. More on that in a future post!

The libdweb APIs, and the shims for node APIs on-top of them, are shaping up well to enable innovation around how the browser loads the pages it shows. As well as Dat, these APIs are being used to bring [WebTorrent](https://github.com/tom-james-watson/wtp-ext) and [IPFS](https://github.com/ipfs-shipyard/ipfs-companion/tree/libdweb) protocols to Firefox. With `webextify` we can theoretically compile any node program for the WebExtension platform, and thus open a vast array of possibilities inside the browser.
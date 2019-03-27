---
layout: post
title: Bringing the DAT protocol to Firefox, part 1
categories:
- blog
---

The Dat protocol enables peer-to-peer sharing of data and files across the web. Like similar technologies such as IPFS and Bittorrent it allows clients to validate the data received, so one can know that the data is replicated properly, but in contrast Dat also supports modification of the resources at a specific address, with fast updates propagated to peers. Other useful properties include private discovery - allowing data shared privately on the network to remain so.

These features have led to a movement to use it has a new protocol for the web, with the [Beaker browser](https://beakerbrowser.com/) pushing innovation around what this new peer-to-peer web could look like. The advantages of using Dat for the web are many-fold:

- Offline-first: Every site you load is implicitly kept locally, allowing it to be navigated when offline. Similarly, changes to sites (both local and remote) will propagate when connectivity is available, but functionality will always be the same.
- Transparent and censorship resistant: Sites are always the same for every user - the site owner cannot decide to change site content based on your device or location as is common on the current web. As sites are entirely published in Dat, and there is no server-side code, then all the code running the site can be seen with 'view source'.
- Self-archiving: Dat versions all mutations of sites, so as long as at least one peer keeps a copy of this data, the history of the site will remain accessible and viewable. This can also keep content online after the original publisher stops serving their content.
- Enables self-publishing: As servers are no longer required, anyone can push a site with DAT - no server or devops required. Publishing to the P2P web requires no payment, no technical expertise, and no platform lock-in.
- Resilient: Apps and sites stay up as long as people are using them, even if the original developers have stopped hosting.

The Beaker browser already demonstrates all of these features, but as an electron-based app lacks some of the security features, depth of configuration and extensibility of a fully-fledged browser. For this reason I wanted to explore how we could bring these features to Firefox, and could enable access to the Dat web for the low cost of installing a browser extension. (*Also as I work for a company building a fork of Firefox, I have a vested interest in getting this working in the browser I develop).

This article is split into two parts. The first part describes the dat-fox, a Firefox extension that provides the best-possible Dat support that is possible given the current limitations of the [webextensions APIs](https://developer.mozilla.org/en-US/docs/Mozilla/Add-ons/WebExtensions). The second describes the process and challenges in creating [dat-webext](https://github.com/cliqz-oss/dat-webext) a Firefox extension which uses experimental APIs from the [libdweb](https://github.com/mozilla/libdweb) project to build full Dat protocol support into a Webextension, and which is current bundled with the [Cliqz Browser nightly](https://cliqz.com/en/latest) build.

There were three main challenges to building Dat support in an extension:

1. Running Dat in an extension context. Dat is currently only implemented for nodejs (though a Rust implementation is on the way), and uses APIs such as `net` and `dgram` which have no analogues in the web-stack. This means that we need to find a way to running this implementation in a webextension, or  find alternative ways of communicating with other peers to get the content of DAT sites.
2. Adding new protocols to the browser, such that it can understand an address starting with `dat://` . This then has to be wired with the Dat implementation to return the correct content for that URL such that it can be rendered in the browser.
3. Adding new web APIs for Dat. In Beaker, a new API, `DatArchive` was proposed, which allows pages to programmatically read the contents of Dat sites. For sites where the user is the owner, and has write permissions, this API allows writes. This API is innovative as it enables self-mutating sites, and has spawned various 'Dat Apps' which behave like many modern web-apps, yet have no server.

## First Attempt: Dat-fox

Early last year, inspired by the [whitelisting of p2p protocols](https://bugzilla.mozilla.org/show_bug.cgi?id=1428446) for use with the Webextensions protocol handlers API, I started [dat-fox](https://github.com/sammacbeth/dat-fox) to build `dat://`support in a Webextensions compatible extension. Unfortunately, the current APIs are severely limiting, meaning that all three of the above challenges could only be partially solved.

Webextensions allow [protocol handlers](https://developer.mozilla.org/en-US/docs/Mozilla/Add-ons/WebExtensions/manifest.json/protocol_handlers) to be specified in their manifest, however these function as simple redirects. To render content under these handlers a HTTP server is still required, either on the web, or running locally. As we also cannot run a HTTP server inside the extension, the APIs necessitate the use of an external process that will serve the content for `dat://` URLs.

Dat-fox implemented a `dat://` protocol handler which redirected to a local process, launched via the [native messaging API](https://developer.mozilla.org/en-US/docs/Mozilla/Add-ons/WebExtensions/Native_messaging). The separate process, written in node, manages syncing with the dat network, and acts as a gateway HTTP server so that the browser can load `dat://` pages when redirected.

![dat-fox-protocol](/assets/images/dat-fox-protocol.png)

A further challenge for dat-fox was ensuring the origins of `dat://` pages were correct, and that URLs looked correct when browsing. Each Dat archive written as a webpage expects to be on it's own _origin_. For example, then page `dat://example.com/test.html` should have the origin `example.com`. This is important for both the browser's security model, such that `localStorage` is not shared between sites, and also for calculating relative paths to files from a specific document. A naive implementation of the protocol handler might redirect the browser to `http://localhost/example.com/test.html`. However, this page would then have the incorrect origin `localhost`, and could break links in the rendered page.

We solved this issue by tricking the browser into loading pages like `http://example.com/test.html` via the gateway. Using a [PAC file](https://github.com/sammacbeth/dat-fox/blob/master/addon/pac.js#L23), which allows the browser to dynamically send traffic to different proxies, we can take requests to `dat://` URLs, after redirecting and tell the browser to use the gateway as a proxy.

Finally, to support the `DatArchive` API, this class needed to be added to the `window` object on Dat pages. While Webextensions do allow for code to be run in the page context via a content-script, this code is sandboxed. This means any modifications to `window` from the content-script are not seen by the page. Instead, we have to use the content-script to firstly inject a script in the page which creates the `DatArchive` object. This script then communicates API calls to the content-script via the postmessage API, which in turn relays to the extension background. As Dat operations require the external node process, these must then be further forwarded via native messaging, then the response returned back up the stack. Luckily there are libraries like [spanan](https://github.com/chrmod/spanan) which make all this async messaging a bit easier to handle.

## Conclusion

While dat-fox does enable browsing the Dat web, multiple limitations of the Webextension API mean that this support is second-class: Users have to install a separate executable to bridge to Dat, and when visiting Dat sites the URL bar still displays `http://` as the protocol. 

To overcome these limitations we have to extend beyond what a standard Webextension can do, using experimental APIs to bring fully-fledged Dat support. In the next post I'll describe how [dat-webext]() bundles the Dat networking stack inside a Webextension using libdweb networking and protocol handler.
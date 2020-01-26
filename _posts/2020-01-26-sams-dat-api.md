---
layout: post
title: Two Dat extensions, one Dat API
categories:
- blog
---

Over the last couple of years I have built and release two browser extensions for loading pages over the [dat](//dat.foundation/) protocol: [dat-fox](https://github.com/sammacbeth/dat-fox), which can be [installed in Firefox](https://addons.mozilla.org/en-US/firefox/addon/dat-p2p-protocol/), but requires a [separate node executable](https://github.com/sammacbeth/dat-fox-helper/) to be installed, and [dat-webext](https://github.com/cliqz-oss/dat-webext) that runs uses internal Firefox APIs to run the full Dat stack inside the browser runtime, but requires extra privileges for installation, meaning it is currently only available in the [Cliqz browser](https://cliqz.com/download).

From building these extensions I ended up implementing some things twice, such as a protocol handler for Dat, and systems for handling multiple dat archives open concurrently. I decided to try to unify this work into a single library that both extensions could share, and that could also streamline the building of other Dat tooling. This is [sams-dat-api](https://github.com/sammacbeth/sams-dat-api), a set of Typescript libraries for common Dat tasks, and which already handles all Dat logic in both [dat-fox](https://github.com/sammacbeth/dat-fox) and [dat-webext](https://github.com/cliqz-oss/dat-webext).

The project is set up as a monorepo, with multiple different modules in one git repository. Using the tool [lerna] this makes it easy to handle the inter-dependencies between modules, but with the advantage of publishing each component as an independent module, minimising the dependency footprint for module consumers.

This post will give a quick overview of the modules that exist so far, and how they can be used in dat applications.

# Hyperdrive API

The [Hyperdrive API] is a high level API for working with multiple Hyperdrives and is designed to be agnostic of Hyperdrive version and swarm implementation. This is enables implementations on top of this API to be usable on multiple different stacks. This was done with Dat 2.0 in mind, as the Hyperdrive and swarming implementations are changing, but ideally we don't want to have to reimplement everything for this new stack.

The Hyperdrive API has implementations for the following:

 * `@sammacbeth/dat-api-v1`: The classic dat stack.
 * `@sammacbeth/dat-api-v1wrtc`: Classic dat with discovery-swarm-webrtc in parallel to improve connectivity. We use this in dat-webext.
 * `@sammacbeth/dat2-api`: The new dat stack, Hyperdrive 10 plus hyperswarm.
 * `@sammacbeth/dat2-daemon-client`: A dat2 implementation that talks to a hyperdrive-daemon instance instead of running dat itself.

With all of these implementation you can write the same code to load and use dats:

```javascript
// load a dat by it's address
const dat = await api.getDat(address);
await dat.ready
// join dat swarm
dat.joinSwarm();
// work with the underlying hyperdrive instance
dat.drive.readdir('/', cb);

// create a new dat
const myDat = await api.createDat();
```

# Building on Hyperdrive

Using the Hyperdrive API and Typescript definitions as a base, we can quickly build utilities on top:

## DatArchive

The [DatArchive API](//beakerbrowser.com/docs/apis/dat) is a popular abstraction for working with the Hyperdrive API. The `@sammacbeth/dat-archive` module provides a implementation of this API that can be used with a providered Hyperdrive instance (like those provided by the HyperdriveAPI).

```javascript
import createDatArchive, { create, fork } from '@sammacbeth/dat-archive';
// create a DatArchive for a Hyperdrive
const archive = createDatArchive(dat.drive);
archive.getInfo().then(...)

// create and fork
const myArchive = await create(api, options, manifest);
```

## Dat Protocol Handler

`@sammacbeth/dat-protocol-handler` implements a protocol handler that matches Beaker Browser's implementation, including extra directives specified in [dat.json](//beakerbrowser.com/docs/apis/manifest):

```javascript
import createHandler from '@sammacbeth/dat-protocol-handler';

const protocolHandler = createHandler(api, dnsResolver, options);

// get a stream from a dat URL.
const response = await protocolHandler('dat://dat.foundation/');
```

## Dat publisher

`@sammacbeth/dat-publisher` is a CLI tool and library that enables the creation, seeding and update of
dat archives, with a prime use-case of site publishing in mind. Building on my approach outline in a
[previous post](/blog/2019/05/26/automated-dat-publishing.html), the tool brings this into a single
command and using the aforementioned abstractions. This means we should be able to easily bring support
for the next gen of Dat down the line.

This tool is currently being used to publish this site, as well as [0x65.dev](dat://0x65.dev) and the
[Dat Foundation website](dat://dat.foundation).

# Summary

I've put together this library and these tools largely to help consolidate code across my own dat-related
projects, but hopefully they can also be useful for others. I am working on updating the documentation to make the project easier to approach (hence this post), but I also hope that the choice of Typescript make the modules 
an easier entrypoint to the dat ecosystem.

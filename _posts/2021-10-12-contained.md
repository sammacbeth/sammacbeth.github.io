---
layout: post
title: Contained - A Firefox container manager
categories:
- blog
---

Firefox's containers offer a way to create isolated browsing contexts, with browser storage (cookies, localStorage, cache etc) different in each one. Containers have many use-cases, from privacy - preventing cross-site tracking across contexts, to allowing you to login into multiple accounts of the same service simulataneously from a single browser.

Mozilla offer the [Multi-account Containers addon](https://addons.mozilla.org/en-US/firefox/addon/multi-account-containers/) for managing containers, and allowing you to automatically switch containers when visiting certain sites. However, I found a couple of use-cases missing for my needs:
 1. Having multiple containers defined for a given domain which I can choose between when I load the site. This enables the multi-account-for-a-service use-case, for example if I want to have both my work and personal Google accounts open in different tabs.
 2. Domains have to be added manually for containers via the UI. This ends up causing issues with sites that redirect you through multiple of their own domains (Microsoft is particularly guiltly of this) when logging in. Additionally, there's no way to add a list of all domains for a particular service if I always want to use the container for that company.
 3. For anything that's not in a container I don't want to keep the cookies and storage they set. I want this cleared reguarly to prevent tracking of return visits and so that I am a new visitor whenever I return to a site.

To get all these use-cases covered I implemented Contained. This is a simple webextension for Firefox that managed containers for you and switches between containers automatically.

The simplest way to describe what Contained does is by looking at how a container is configured. Let's look at an example:
```javascript
{
    name: "Microsoft",
    color: "purple",
    icon: "briefcase",
    domains: ["example.com"],
    entities: ["Microsoft Corporation"],
    enterAction: "ask",
    leaveAction: "default"
}
```

Going through the options:
 * `name` is the container name.
 * `color` is the colour this container is given in the Firefox UI.
 * `icon` is the icon for this container in the Firefox UI.
 * `domains` is a list of domains which should be loaded in this container.
 * `entities` are entities from [DuckDuckGo's entity list](https://github.com/duckduckgo/tracker-radar/tree/main/entities) which should be loaded in this container.
 * `enterAction`, can be 'ask' or 'switch' defines if the container should be automatically switched when navigating to this domain, or the user should be prompted to decide if they want to switch or stay in the current container. When there are multiple candidate containers for a domain the extension will always ask which container should be used.
 * `leaveAction`, can be 'ask', 'default' or 'stay', defines what happens when a the container tab navigates to a domain _not_ in the list of domains. 'ask' will prompt the user, 'default' will switch back to the default (ephemeral) container, and 'stay' will remain in this container.

For every site visited that doesn't match a persistent container, the extension creates a temporary container. Every 3 hours a new container is created for use in future tabs. Containers are only deleted when the extension restarts (e.g. on browser restart, or when the extension is updated).

Configuration currently can only be done via extension debugging: Open the devtools console for the extension by navigating to `about:devtools-toolbox?id=contained%40sammacbeth.eu&type=extension` in the browser. There, you can read and modify the config by executing code in the console:

```javascript
// check value of the config object
>> config
<- Object { default: "firefox-container-294", useTempContainers: true, tempContainerReplaceInterval: 120, containers: (7) […] }
// add or edit containers
>> config.containers.push({ name: 'New container', ... })
>> config.containers[0].domains.push('example.com')
// save the changes
>> storeConfig(config)
```
Config is kept in the browser's [sync](https://developer.mozilla.org/en-US/docs/Mozilla/Add-ons/WebExtensions/API/storage/sync) storage space, so if you are using Firefox sync you get the same container settings on all your devices.

The Contained extension can be downloaded for Firefox [here](https://sammacbeth.eu/addons/contained-2021.10.3-an+fx.xpi). The source code is available [here](https://github.com/sammacbeth/firefox-extensions/tree/main/contained).

---
layout: post
title: Install Dat protocol support in Firefox
categories:
- blog
---

The [Dat-Webext]() extension provides native dat support in Firefox-based browsers, but due to it's use of experimental APIs, installation can be a bit tricky. This post
will outline how to install it in [Firefox Developer Edition](https://www.mozilla.org/en-US/firefox/developer/) or [Nightly](https://www.mozilla.org/en-US/firefox/channel/desktop/).

As the extension uses [experimental APIs](https://github.com/libdweb/libdweb), it cannot be installed in stable Firefox release channels, as it is not signed by Mozilla. The developer edition and nightly channels allow this restriction to be lifted. There settings about be changed in the `about:config` page in the browser. Here are the full installation steps:

 1. Go to the `about:config` page and set `xpinstall.signatures.required` to `false` and `extensions.experiments.enabled` to `true`
 ![Setting prefs in about:config](/assets/images/firefox-prefs.png)
 2. Download the [latest version](https://github.com/cliqz-oss/dat-webext/releases/download/v0.2.3/dat_protocol-0.2.3.zip) of the extension.
 3. Go to about:addons and choose 'Install addon from file' from the cog menu in the top right, then browse to zip file you just downloaded. The browser will ask for permissions to install.
 ![Setting prefs in about:config](/assets/images/install-addon-from-file.png)

The addon should successfully install, and you should now be able to navigate to [dat sites](dat://dat.foundation) as well as sites on the new `hyper://` protocol.

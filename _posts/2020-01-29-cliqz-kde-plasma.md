---
layout: post
title: Setting up KDE Plasma Integration in Cliqz
categories:
- blog
---

The KDE [Plasma Integration](https://addons.mozilla.org/en-US/firefox/addon/plasma-integration/) browser
extensions enables better integration between Firefox and the KDE desktop environment, for example
allowing media controls to control music or video playing in the browser, and for the Plasma
search widget to be able to return open browser tabs in results.

As the [Cliqz Browser on Linux](https://cliqz.com/en/desktop/cliqz-for-linux) is also based on
Firefox the Plasma Integration extension should theoretically 'just work' too. However, as the
extension uses [Native messaging](https://developer.mozilla.org/en-US/docs/Mozilla/Add-ons/WebExtensions/Native_messaging)
to communicate between browser and desktop environment, a manifest file needs to be installed
so that the browser knows when process to launch. To get this working in Cliqz, we can simply
copy over the Firefox manifest to the appropriate location:

```bash
mkdir -p ~/.cliqz/native-messaging-hosts/
cp /usr/lib/mozilla/native-messaging-hosts/org.kde.plasma.browser_integration.json ~/.cliqz/native-messaging-hosts/
```

This installs the manifest for the current user, so after installing the [Plasma Integration extension](https://addons.mozilla.org/en-US/firefox/addon/plasma-integration/) in Cliqz
everything should be working properly!

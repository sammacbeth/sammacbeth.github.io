---
layout: post
title: Running Webextensions on Android with Geckoview
categories:
- blog
---

The new [Firefox Preview](https://hacks.mozilla.org/2019/06/geckoview-in-2019/) for Android uses Mozilla's Geckoview to replace Android's standard Webview component. This enables a fully Gecko-based browser, but without the bloat of much of the Firefox desktop codebase, that the original Firefox suffers from. We can expect a much faster and cleaner browsing experience thanks to these changes, and the Geckoview and Mozilla [Android Components](https://github.com/mozilla-mobile/android-components) libraries offer exiting tech for developers of Android apps that require some kind of Webview or browser functionality.

However, one thing missing from the Firefox Preview MVP are browser extensions. The availability of extensions on the original Firefox for Android has long been it's USP compared to other Android browsers. While the Mozilla Android team have not been working on Webextension compatibility, a lot comes for free with Geckoview, and the android components browser Engine abstraction also already contains a method to [installWebExtensions](https://mozac.org/api/mozilla.components.concept.engine/-engine/install-web-extension.html) and this is implemented in the Geckoview implementations. What that means is that Webextensions _can_ be run in Geckoview on Android, and this post will show how to do it.

## Installing the extension in your Android project

1. Unpack the extension (if it's a `.xpi` you can extract it as a `.zip`) in to a folder. This folder should have a `manifest.json` file in the root, and contain all the sources for the extension.
2. Move this folder into the `assets` folder of your Geckoview app:
```bash
mkdir -p ./app/src/main/assets/addons
mv /path/to/extension ./app/src/main/assets/addons/
```

3. Now, in your app, after you load your `Engine` instance, you can simply install the extension as follows:
```kotlin
// Engine creation
val engine = EngineProvider.createEngine(context, settings)
// Install addon
engine.installWebExtension(
    addonId, // addonId must be constant to ensure storage remains across restarts
    "resource://android/assets/addons/extension"
)
```

You can further check if the installation was successful by passing callbacks to the install operation.

## Debugging the extension

Extensions can be debugged on a connected computer using Firefox Nightly, in the same was as was [previously possible in Firefox for Android](https://developer.mozilla.org/en-US/docs/Tools/Remote_Debugging/Debugging_Firefox_for_Android_with_WebIDE). You can enable debugging of the Gecko engine simply by setting `engine.settings.remoteDebuggingEnabled = true`. In the [reference-browser](https://github.com/mozilla-mobile/reference-browser) this option is expose in the app settings. Once enabled, and the device is connected to a computer, the device should be visible in `about:debugging` in Nightly:

![Nightly debugging page](/assets/images/geckoview-debug-connect.png)

After connecting and selecting your device, you should be able to see various debuggable contexted, such as your currently open tabs and service workers. To debug the extension go to the very bottom and inspect the Main Process:

![](/assets/images/geckoview-debug-processes.png)

The last step is to chose your extension document in the dropdown on in the top right. This allows you to debug in the context of your extension background script.

![](/assets/images/geckoview-debug-contexts.png)

Now you can debug as you would on desktop!

## API Compatability

I mentioned at the start that a lot of extension compatibility 'comes for free'. Thanks to [patches](https://bugzilla.mozilla.org/show_bug.cgi?id=1539144) from my colleague [chrmod](https://github.com/chrmod) to specifically fix `tabs` and `webRequest` APIs, most common use-cases are covered now in the Nightly Geckoview build. One compatibility caveat is that all UI APIs do not work, as the hooks to handle concepts like page and browser actions should be handled on a per-app basis.

Here is a quick (and incomplete) list of the current [Javascript API](https://developer.mozilla.org/en-US/docs/Mozilla/Add-ons/WebExtensions/API) compatibility:

* `alarms` - ✔
* `bookmarks` - Not supported (`browser.bookmarks` is `undefined`)
* `browserAction` - Not supported 
* `browserSettings` - Partial. Some settings are not applicable and reject when accessed.
* `browsingData` - Partial. Some functions missing (`removeHistory`), and others do not return `removeCache`. 
* `contentScripts` - ✔
* `contextualIdentities` - API is present, but throws `"Contextual identities are currently disabled"`. May work if the preference is enabled in `about:config`
* `cookies` - ✔
* `dns` - ✔
* `extension` - ✔
* `find` - Not supported
* `history` - Not supported
* `idle` - ✔
* `management` - Partial.
* `menus` - Not supported
* `notifications` - API is present and responds as if successful, but no notifications are shown.
* `pageAction` - Not supported
* `privacy` - ✔
* `proxy` - ✔
* `runtime` - Partial. `openOptionsPage` throws for example.
* `search` - Not supported
* `sessions` - Not supported
* `sidebarAction` - Not supported
* `storage` - ✔
* `tabs` - ✔ (`tabs.create` requires a handler on the app side)
* `topSites` - Not supported
* `webNavigation` - ✔
* `webRequest` - ✔
* `windows` - Not supported

This means that most of the core is there, minus UI APIs. Also, as history and session storage is separate from the Webview, APIs based on access to this information do not currently work.


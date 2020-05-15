---
layout: post
title: Some things we built at Cliqz
categories:
- blog
---

Almost 5 years after I joined Cliqz, the company will be [shutting down](https://cliqz.com/en/magazine/farewell-from-cliqz)
and likely cease to exist in its current form. This post is a look back at some of the exiting things
we built during that time from my perspective, working on privacy and our web browsers.

### Anti-tracking

Our anti-tracking, released in 2015, was---and still is---one of the most sophisticated anti-tracking systems available.
The Cliqz browser had this anti-tracking enabled by default from it's first version, while at that time no other browser
had any protection by default (Safari's ITP would come two years later). Now all major browsers (except Chrome) ship with
tracking protections that are enabled by default, and Chrome are looking to deprecate third-party cookies entirely within
two years.

We also pushed hard for transparency on online tracking and where it occurs, naming the largest trackers and sites with the
most trackers via our transparency project [whotracks.me](https://whotracks.me). We analysed billions of page loads to see
which trackers were loaded and what they were doing, and published this data. We also collaborated with researchers to pull
insights out of this data to inform policy around online tracking, as well as helping journalists publish stories about some
of the most egregious cases.

The anti-tracking story is a big part of my story at Cliqz - maintaining and improving our anti-tracking was my main role
for the last 5 years. I was also part of the small team that built out whotracks.me. Luckily all this will live on: The Cliqz
anti-tracking tech has been built into Ghostery since version 8, and it will continue to be a core part of Ghostery's protections
into the future. Likewise, while anti-tracking continues to operate, the data required for whotracks.me will continue
to be available.

You can read more about the details of anti-tracking on the [Cliqz tech blog](https://0x65.dev/blog/2019-12-19/blocking-tracking-without-blocking-trackers.html).

### Experimenting with the distributed web

One constant theme at Cliqz was how the browser can empower users, and how we could help users avoid service lock-in and the
privacy consequences that often entails. One experiment in that direction was self publishing via the dweb, specifically the
[dat protocol](https://dat.foundation/). We [built support for dat](https://0x65.dev/blog/2020-03-02/implementing-the-dat-protocol-in-cliqz.html)
as a Firefox browser extension and shipped it as an experimental feature. Unfortunately this experiment is unlikely to
be able to continue after the browser shut down, but the extension is [open source](https://github.com/cliqz-oss/dat-webext)
and can also [be installed in Firefox](/blog/2020/05/08/install-dat-for-firefox.html).

### Crashing some Javascript engines

We put a lot of effort into running our large Javascript codebase on our mobile apps, in order to bring our features such as search
and anti-tracking to mobile. This idea (implementing mobile apps in Javascript), has matured significantly in the last few years,
but when we first approached this we were very much at the limits of what could be done with the platform and the tooling. A couple of
times we hit those limits:

Back in 2016, we were running JS in raw JavascriptCore on iOS. Suddenly, a new build of our code starting instantly crashing the app.
With essentially no debugging tools available that could pinpoint the error, we had to start dissecting the whole bundle. In the end we
got to a [55 character snippet](https://twitter.com/chrmod/status/793054270568468480) that would crash the Javascript engine, and bring the app with it.
This also affected Javascript loaded in Webviews, meaning we could craft a website that crashed every iOS web browser on load.

Just over a year later, we'd switched to React-Native for our Javascript needs. This provided some stability improvements, but still we
woke up one day to reports of our Android app crashing on launch. After a few hours of digging, we traced the cause to a version of a 
file in the CDN cache missing a `Content-Encoding` header. When the app fetched this gzipped file, but thought it was not compressed,
react-native would crash when trying to encode the data to send to Javascript. We reduced this file to
[3 bytes](https://github.com/facebook/react-native/issues/10756#issuecomment-360443914) that would crash any react-native app: 

### Wrote some high performance Javascript libraries

Performance was always very important in our browser, particularly in anti-tracking and the adblocker, which had to process URLs as
fast as possible in order to prevent an impact on page loading speed. We did a lot of optimisations here, and open sourced the libraries
that came out of it:

 * To parse out the individual components of URLs as fast as possible, we wrote a new [url-parser implementation](https://github.com/cliqz/url-parser)
 that is between 2 and 10 times faster than the standard URL parsers available in the browser and node.
 * Our anti-tracking needs to extract features such as [eTLD+1](https://web.dev/same-site-same-origin/) from URLs. [Tldts](https://github.com/remusao/tldts) is the fastest and most efficient
 Javascript library available for that purpose.
 * Our [open-source adblocker engine](https://github.com/cliqz-oss/adblocker) is the [fastest and most efficient](https://0x65.dev/blog/2019-12-20/not-all-adblockers-are-born-equal.html)
 javascript implementation available.
 * Both anti-tracking and the adblocker's block lists were shipped as raw array buffers, meaning that clients could load them with no parsing step required.
 This was a significant win on mobile, where loading and parsing block lists on startup was a significant performance cost.
 * To better understand performance bottlenecks in our browser extension code, we wrote an [emulator](https://github.com/cliqz-oss/webextension-emulator)
 which could mimic the webextension environment in node, and simulate different kinds of workloads. We could then use node profiling tools
 to detect issues.

### Automated Consent

After the arrival of the GDPR, users started to get bombarded with consent popups on sites they visit. As well as being horrendous for the
user experience of browsing the web, these consent popups manufactured false consent for online tracking. Publishers claimed 90+% opt-in
rates on their sites as evidence that the tracking status quo could continue with user consent. In reality users either did not know there
was a choice to opt-out, or the opt-out process was so complicated that privacy-fatigue set in quickly.

At Cliqz, we wanted to supplement the _technical_ protection from tracking, provided by anti-tracking, with a _legal_ protection by enabling
users to choose to opt-out on sites with the equal effort to the 1-click opt-in process. This would also send the important signal to
publishers that tracking is not wanted. We developed first the [re:consent](https://github.com/cliqz-oss/re-consent) browser extension, then
later the [Cookie popup blocker](https://cliqz.com/en/magazine/cookie-pop-up-blocker-cliqz-automatically-denies-consent-requests).

Re:consent was based on the IAB's Transparency and consent framework, which was not designed for external modification of consent settings,
and therefore was somewhat limited, and unable to reduce the number of popup seen by users. We learnt from that that the only way to inter-operate
with banners was by pretending to be a user and clicking on the elements. The open-source [autoconsent](https://github.com/cliqz-oss/autoconsent)
library implements this clicking, with rules for most major consent popup frameworks.

### And much more

There are many more things that should be mentioned here, but this post has to stop somewhere. These highlights are some that are freshest in
my memory, or had the most impact. Luckily most of this code for these projects is open-source, which means that no-matter the fate of Cliqz-itself,
these ideas can still be revived and built upon. 

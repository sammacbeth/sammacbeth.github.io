---
layout: post
title: Automated Dat publishing
categories:
- blog
---

With [Dat](//dat.foundation/) you can easily publish a website without having to deal with the hassle of servers and web hosting - just copy your HTML and CSS to a folder and run `dat share` and your site is online. However, every time you want to update the content on your site there is some manual work involved to copy over new files and update the archive for your site. With many personal sites now using static site generators such as [jekyll](https://jekyllrb.com/) to create their sites, this can get cumbersome. Systems like [Github Pages](https://pages.github.com/) are much more convenient - automatically publishing your site when you push changes to Github.
This post shows how to get a Github Pages level of convenience, using Dat.

As [I wrote previously](/blog/2018/03/29/dats-good.html), this site is published on both Dat and HTTPs as follows:

1. Site is built using [Jekyll](https://jekyllrb.com/), outputing a `_site` directory with HTML and CSS.
2. Contents of `_site` are copied to the folder with the current version of the site in.
3. Run `dat sync` to sync the changes to Dat version of the site to the network.
4. A seeder on my webserver pulls down the latest version, which causes the HTTPs site to update.

As running steps 1-3 is a bit tedious, we can automate it. This entire process can be run on continuous deployment, enabling the site to be updated with just a `git push`. 

The core of this, is a script that can update the website's Dat archive with only two bits of input data: The Dat's public and private keys. The keys can be obtained with the handy `dat keys` command:

```bash
# get public key (also its address)
$ dat keys
dat://d11665...
# get private key (keep this secret)
$ dat keys export
[128 chars of hex]
```

Armed with these two bits of information, we can run the following script anywhere to update the site:

```bash
npm install -g dat
dat clone dat://$(public_key)
rsync -rpgov --checksum --delete \
    --exclude .dat --exclude dat.json \
    --exclude .well-known/dat \
    _site/ $(public_key)/
cd $(public_key)
echo $(private_key) | dat keys import
timeout --preserve-status 3m dat share || true
```

Going through this line by line:

- `npm install -g dat` installs the Dat CLI
- `dat clone dat://$(public_key)` clones the current version of the site
- `rsync -rpgov --checksum --delete --exclude .dat --exclude dat.json --exclude .well-known/dat _site/ $(public_key)/` copies files from the build directory, `_site`, to the dat archive we just cloned. We only copy if the contents have changed, and we also delete files which were removed the in the site build. We exclude `dat.json` and `.well-known/dat` from this delete because they exist only in the dat archive. We also exclude `.dat` as to not delete the archive metadata.
- `echo $(private_key) | dat keys import` imports the private key for this dat, granting us write access to the archive.
- `timeout --preserve-status 3m dat share || true` runs `dat share`, which syncs the changes back to the network. We keep the process open for 3 minutes to ensure that the content is properly synced, and then return `true` so as to not throw an error when the timeout inevitably occurs.

As mentioned, we can run this script on a CI/CD system to automate publishing. We must, however, ensure that the private key is kept secret. Luckily most systems should offer a mechanisms for private variables to be securely uploaded and kept hidden from job logs.

There is a risk with this approach - namely that the final `dat share` operation may not sync a full copy of the changes to the network, or the peer who receives them subsequently disappears from the network. In this case, the archive could enter a broken state, where a full copy of the data can no longer be found. In my case, I run a seed at all times on my server, so I believe the risks of this are not high.

I currently have this automated publishing running as a 'Release pipeline' on [Azure Pipelines](https://dev.azure.com/sammacbeth/sammacbeth.eu/_release). This can be manually or automatically triggered with builds of this site done by [Build pipeline](https://github.com/sammacbeth/sammacbeth.github.io/blob/master/azure-pipelines.yml). This gives me the 'Github Pages' experience that I was looking for, but with an added deployment to the P2P web!
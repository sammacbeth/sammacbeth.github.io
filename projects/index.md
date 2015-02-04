---
layout: page
title: Projects
---

This page gives an overview of the coding work and projects I've been working on.

#### [Presage2]

This is a general purpose platform for the simulation of agent-based systems. This is used as a research tool for investigating the effects of governance and social structure on socio-technical systems based on micro-level interactions between agents.

The project is open-source, under the LGPL licence, and available at [Github](https://github.com/Presage/Presage2). Currently the core library contains over 18K lines of code, over a four year development history (as measured by [openhub](https://www.openhub.net/p/presage2)), the majority of which has been written by myself.

#### [Drools-EInst]

Drools-EInst is a library of specifications for electronic institutions written for the JBoss Drools rule engine. Each specification provides a module for programmatic access to the relevant state of the institution. It is used as a means of defining institutional rules for a system, and then monitoring the changes in institutional state from agents' actions within the system.

#### [Knowledge Commons]

This is an agent-based simulation of a knowledge commons, as defined in my thesis. It uses [Presage2] as a simulation library, and [Drools-EInst] to specify institutional rules.

#### [LPG' Game]

This is an implementation of the LPG' game using [Presage2] with the Drools rule engine. This implementation of the game was used for several papers on distributive justice. See the [research](/research) page to find these papers.

 [Presage2]: http://www.presage2.info/
 [Drools-EInst]: https://github.com/sammacbeth/electronic-institutions
 [Knowledge Commons]: https://github.com/sammacbeth/KnowledgeCommons
 [LPG' Game]: https://github.com/sammacbeth/LPG--Game

# luvit-seer
A new luvit based web system based loosely around the luvit blog.

## Purpose

I have been looking for a decent open source asset management tool (specifically for 3D assets and animations) and most of the good tools are commercial and very expensive, as well as being fairly mediocre in their capabilities. 

![Initial Projects Page](/projects/media/2026-05-23_17-52-initial-projects-page.png)

## Get Started

The requirements for this to currently work are:
- Linux (I havent bothered testing OSX or Win). Runs in WSL fine too.
- Redis server (can be anywhere - local network is assumed). Change settings in project/seer/server/server.lua for IPs and ports.

Start the redis server:

```.\redis-server.exe .\redis.conf```

I usually set the conf to have a specific server ip in the bind section of the conf.

I also set protected-mode to no so you can use it with WSL or other local services.

Start luvit-seer:

```./luvit projects/seer/server/server.lua "projects/seer"```

If you look at the luvit github you can build luvit for your platform. And it should work the same as the linux one provided here. I will add a win and osx binary at some stage, they are quite small. 

Once you have done this, it may take a little while to start - it goes through all the project and builds and imagecache (I will add ways to configure this). This is intended more for the threejs 3d textures and not for the web pages (but the web pages use it too). 

You should see something like this once it is ready to be used:

```
'Architecture: '        'x64'   ' OS:'  'linux'
HTTP server listening at https://127.0.0.1:8443/
```

Now you can access the page. Only Dashboard and Projects are operational at this time of writing. I should have quite a few ready over the coming week. Its quite easy to get working, but Im also re-developing the sqlite data lookup system into a more generic data lookup API so that multiple types of data backends can be used (Sqlite, Redis, Postgres etc). 

## How

The development will follow some basic first steps:
- Take my previous SEER simulation project management system and port it to luvit. 
- Once most of the port is done (the main project and 3D rendering parts) add in some versioning (prob via git)
- Generate some asset management tools (sorting, meta tags, filtering, light asset changes etc)
- Add multi-user capabilities with security levels (my SEER system has this, but will need updating). Things like multi auth and such will be important to include.
- Add plugin facilities for developers to make their own tools.
- Add Blender plugin to integrate with it.
- Add Image app plugins (may not even bother with this, deps on how much I need it)

By the end, I will have a server toolkit/framework that can be used as a work horse for my projects. Tight integration with Github or GitLab (more likely) will be important. From the project management side I want to be able to raise issues, monitor asset status and information, examine assets quickly and easily and ensure I can sync assets into a git based project (prob thru external git link). 

This is a reasonably large task, but the SEER project I built for defense has a large portion of what I need already so I expect to have something up and running in a week or two. 

I also need this for a game Im building where the assets are starting to get substantial and I want to track them closely, so I will have a project as a real-world test case.

## Luvit ??

Ive used this framework for a long time. And it is a very good framework. There will probably need to be a bunch of custom libs I need to rebuild for it (like OpenSSL etc) but this isnt a huge issue with the way the dll's are integrated.

The benefit of this tool is its Luajit basis which I have a large amount of commerical and personal experience with. Additionally, this framework is a very fast RDE... and time is something I dont have a huge amount of :) 

If you are interested in using this project. Feel free - its MIT based, and if you want to contribute then also please feel free to send PRs. Im not super picky, as long as you dont go adding tuns of OO crap :)

There are a few other projects that will integrate with this almost immediately and I hope to get them on a regular use cycle so that the framework gets a good battle tested regime in place.

The projects are:

https://github.com/dlannan/dim 

https://github.com/dlannan/ljos

https://github.com/dlannan/sokol-luajit

https://github.com/dlannan/defold-blender-export

There are some others that will probably also be revised and updated to use this as well. I may look at using the webkit app toolkit as a standalone app for interacting directly with this. Will see.



-- Fix some system paths - not liking luvit search paths
_G.PLATFORM = require('lua.platform')
_G.PLATFORM.get()

local spath = require('path')
local apppath = spath.resolve('.')

if _G.PLATFORM.os == "windows" then
local depth = apppath..'\\'
package.path = package.path..';'..depth..'deps\\?.lua;'..depth..'deps\\?\\init.lua;'..depth..'deps\\secure-socket\\?.lua;'..depth..'lua\\?.lua'
end

if _G.PLATFORM.os == "linux" then
local depth = apppath..'/'
package.path = package.path..';'..depth..'deps/?.lua;'..depth..'deps/?/init.lua;'..depth..'deps/secure-socket/?.lua;'..depth..'lua/?.lua;'
package.cpath = package.cpath..';'..depth..'deps/libimg/?.so'
end

-- print(package.path)
dofile 'luvit-loader.lua'

-- ------------------------------------------------------------------------------------------
-- Project name defaults to userassets folder.
local project = args[2] or "userassets"

_G.PROJECT    = project
_G.REDIS      = require('redis-tools')

-- Add prject lua folder t search path
if _G.PLATFORM.os == "windows" then
package.path = package.path..';'..project..'\\server\\lua\\?.lua'
end

if _G.PLATFORM.os == "linux" then
package.path = package.path..';'..project..'/server/lua/?.lua'
end

-- ------------------------------------------------------------------------------------------
-- Included objects for the list.

local pathJoin = require('luvi').path.join
local static = require('weblit-static')
local resty = require('weblit-static-resty')

local lfs = require('fs')

local admin = require('administration')
local msetup = require('setupmodules')
local asetup = require('setupassets')
local session = require('html_session')
local logger = require('flodstats')

-- ------------------------------------------------------------------------------------------
-- Data for testing events and carousels
local events = require( pathJoin(apppath, pathJoin(project, "server/lua/data_event")))
local news = require( pathJoin(apppath, pathJoin(project, "server/lua/data_news")))
local carousel =  require( pathJoin(apppath, pathJoin(project, "server/lua/data_carousel")))
local search =  require( pathJoin(apppath, pathJoin(project, "server/lua/data_search")))

_G.EVENTS   = events
_G.NEWS     = news 
_G.CAROUSEL = carousel
_G.SEARCH   = search

-- ------------------------------------------------------------------------------------------
-- Web serving settings. Split into REDIS and WWW IP host IPS.
--       REDIS uses localhost requests for security, no remote requests are allowed!!
--_G.LOCALHOST_IP         = "127.0.0.1"
_G.LOCALHOST_WWW_IP     = "127.0.0.1"
_G.LOCALHOST_IP         = "192.168.50.152"
_G.LOCALHOST_PORT       = 8443
_G.LOCALHOST_REDIS_PORT = 6379

-- Editing always defaults to false in case of something bad going wrong.
_G.LOCALADMIN = admin
_G.LOCALEDITING = {
    editing = (args[3] or 'false') == 'true'
}

-- Global editing flag - use this when checking if somehting should be in editing mode or not.
_G.editing = _G.LOCALEDITING.editing

-- ------------------------------------------------------------------------------------------
-- Some core global collection.
--    These are idea for fast hash lookups. Will consider moving these to redis in the
--    future. Not important right now.
_G.LINKING    = {}
_G.MODULES    = {}
_G.RESTYS     = {}
_G.JSS        = {}
_G.WEBLINKS   = {}
-- Meta tags are for SEO on the website, search tags are for our own fast internal lookups.
-- Meta tags are keyed by the webpage path and points to list of tags.
_G.TAGSMETA   = {}
-- Search tags are keyed by the tag itself (points to webpage)
_G.TAGSSEARCH = {}

-- User asset links are store here - to files within the user assets folder.
_G.USERASSETS = {}

_G.HTMLPAGES  = require('html_pagestore')
_G.HTMLBLOGS  = require('html_blogstore')

-- Sessions are logged as a per connected data  set, so that a request is
--  properly associated with a unique user.
_G.SESSIONS   = session

-- Exclude the about page 
_G.HTMLPAGES.excludepage('about-page-default.html')

-- ------------------------------------------------------------------------------------------
-- Init the modules and the assets (builds modules and asset pools from folders)
session.init( { loginrequired = true } )
msetup.init()
asetup.init()
logger.init()

dataset = {}
dataset[project] = _G.USERASSETS
dataset.grav = {
    user        = {
        username    = "Trevor",
    },
    language    = {
        getLanguage     = "en",
    },
}
dataset.site = {
    title           = "site title",
    description     = "site description",
    metadata        = {
        seerbuild = "Luvit Seer 1.0.0",
    }
}
dataset.theme_url = ""
dataset.page = {
    title = "page title",
    description = "page description", 
    url = "page url",
    collection = function() return "" end,
    tags = "page tags",

    meta = {
        http_equiv = "",
        charset = "",
        property = "",
        content = "",
    },
}

dataset.projects = {
    [1]     = {
        name    = "Project 1",
        uid     = "012345", 
        desc    = "Project 1 description",
        modified = "01/01/2001",
        scenes  = {
            [1] = {
                icon    = "/content/images/plywood.jpg",
            },
        },
    },
    [2]     = {
        name    = "Project 2",
        uid     = "012346", 
        desc    = "Project 2 description",
        modified = "01/02/2001",
        scenes  = {
            [1] = {
                icon    = "/content/images/wood.jpg",
            },
            [2] = {
                icon    = "/content/images/waternormals.jpg",
            }
        },
    },
    [3]     = {
        name    = "Project 3",
        uid     = "012347", 
        desc    = "Project 3 description",
        modified = "01/03/2001",
        scenes  = {
            [1] = {
                icon    = "/content/images/rocks.jpg",
            },
            [2] = {
                icon    = "/content/images/grass.png",
            }
        },
    },
}

_G.loginrequired = false
if _G.editing == true or _G.SESSIONS.loginrequired == true then
    _G.loginrequired = true
end

-- ------------------------------------------------------------------------------------------
-- Predefine the user paths that will be provied for each project (web site).
local csspath = pathJoin(apppath, pathJoin(project, "userassets/css"))
local htmlpath = pathJoin(apppath, pathJoin(project, "userassets/html"))
local jspath = pathJoin(apppath, pathJoin(project, "userassets/js"))
local iconspath = pathJoin(apppath, pathJoin(project, "userassets/icons"))
local fontspath = pathJoin(apppath, pathJoin(project, "userassets/fonts"))
local scriptspath = pathJoin(apppath, pathJoin(project, "userassets/scripts"))
local videospath = pathJoin(apppath, pathJoin(project, "userassets/videos"))
local imagespath = require('imagecache')

_G.IMAGES_PATH = pathJoin(apppath, pathJoin(project, "userassets/images"))
_G.PROJECT_USERASSETS = pathJoin(apppath, pathJoin(project, "userassets"))
_G.PROJECT_FOLDER = apppath

-- p('Building search table...')
search.init()

-- ------------------------------------------------------------------------------------------
-- Proper server starts here - need cleanup
require('weblit-app')

-- Bind the server to the IP and look for the keys. Need to generate proper keys.
.bind({
    host = _G.LOCALHOST_WWW_IP,
    port = _G.LOCALHOST_PORT,
    tls = {
        key = lfs.readFileSync(pathJoin(apppath, "/mnt/f/dev/web/blog_backup_23_03_2017/ssl/keys/server.key")),
        cert = lfs.readFileSync(pathJoin(apppath, "/mnt/f/dev/web/blog_backup_23_03_2017/ssl/keys/server.crt"))
    }
})

-- Configure weblit server
-- Enable this line to view detailed logging of the server
.use(logger.logger())
.use(require('weblit-auto-headers'))
-- Enable this line to allow the caching of etags - powerful when deploying (perf improvement)
--.use(require('weblit-etag-cache'))

-- Example of thow to map a folder to a specific path for access
--.use(static(pathJoin(module.dir, "static")))

-- Static data routes - these may become redis lookup (scripts and css especially)
--.route({ path = "/:path" }, static(pathJoin(module.dir, "static")))
.route({ path = "/styles/:path:" }, static(pathJoin(apppath, "static/styles")))
.route({ path = "/scripts/:path:" }, static(pathJoin(apppath, "static/scripts")))
.route({ path = "/images/:path:" }, static(pathJoin(apppath, "static/images")))
.route({ path = "/fonts/:path:" }, static(fontspath))

.route({ path = "/:name:.html" }, resty(pathJoin(project, "templates"), dataset) )
.route({ path = "/:path:/:name:.html" }, resty(pathJoin(project, "templates"), dataset) )

--Special static routes for templates - same data though.
.route({ path = "/:name:.twig" }, resty(pathJoin(project, "templates"), dataset) )
.route({ path = "/:path:/:name:.twig" }, resty(pathJoin(project, "templates"), dataset) )
.route({ path = "/:path:/:name:.html.twig" }, resty(pathJoin(project, "templates"), dataset) )
-- .route({ path = "/templates/styles/:path:" }, static(pathJoin(apppath, "static/styles")))
-- .route({ path = "/templates/scripts/:path:" }, static(pathJoin(apppath, "static/scripts")))
-- .route({ path = "/templates/images/:path:" }, static(pathJoin(apppath, "static/images")))
-- .route({ path = "/templates/fonts/:path:" }, static(pathJoin(apppath, "static/fonts")))

-- .route({ path = "/userassets/html/:path:" }, static(htmlpath))
.route({ path = "/css/:path:" }, static(csspath))
.route({ path = "/icons/:path:" }, static(iconspath))
-- .route({ path = "/images/:path:" }, static(imagespath))
.route({ path = "/scripts/:path:" }, static(scriptspath))
.route({ path = "/js/:path:" }, static(jspath))
.route({ path = "/videos/:path:" }, static(videospath))

-- .route({ path = "/userassets/images/:path:" }, imagespath(apppath) )

-- .route({ path = "/admin/:name:.html" }, require('controllers/admin'))
-- .route({ path = "/admin/:path:/:name:.html" }, require('controllers/admin'))
.route({ path = "/:name:" }, resty(pathJoin(project, "templates"), dataset) )
.route({ path = "/images/:name:" },  static(pathJoin(project, "userassets/images")) )

.route({ path = "/" }, require('controllers/index')(pathJoin(project, "templates"), dataset))

-- .route({ path = "/functions/event" }, require('html_event_details'))

-- .route({ path = "/functions/userlogin" }, require('userlogin'))
-- .route({ path = "/functions/getmodule" }, require('getmodule'))

-- .route({ path = "/functions/submit_event" }, require('html_event'))
-- .route({ path = "/functions/submit_news" }, require('html_news'))
-- .route({ path = "/functions/submit_carousel" }, require('html_carousel'))
-- .route({ path = "/functions/submit_published" }, require('html_publish'))
-- .route({ path = "/functions/submit_delete" }, require('html_delete'))
-- .route({ path = "/functions/submit_about_page" }, require('html_about'))

-- .route({ path = "/functions/select_event" }, require('select_event'))
-- .route({ path = "/functions/select_news" }, require('select_news'))

-- .route({ path = "/functions/upload_image" }, require('upload_image'))
-- .route({ path = "/functions/submit_contact_details" }, require('contact_mail'))
-- .route({ path = "/functions/site_search" }, function (req, res, go)
--     -- Handle route
--     return search.search(req, res, go)
--   end)

-- Only allow specific access when authenicating, and saving.

.start()

-- ------------------------------------------------------------------------------------------
-- Build some initial content - this will be removed, once everything is sorted out.
require('db_init').init()



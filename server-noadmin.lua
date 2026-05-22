-- Fix some system paths - not liking luvit search paths
_G.PLATFORM = require('lua.platform')
_G.PLATFORM.get()

if _G.PLATFORM.os == "windows" then
package.path = package.path..'.\\deps\\?.lua;.\\deps\\?\\init.lua;.\\deps\\secure-socket\\?.lua;.\\lua\\?.lua'
end

if _G.PLATFORM.os == "linux" then
package.path = package.path..';./deps/?.lua;./deps/?/init.lua;./deps/secure-socket/?.lua;./lua/?.lua;'
package.cpath = package.cpath..";./deps/libimg/?.so"
end

-- print(package.path)
dofile 'luvit-loader.lua'

-- ------------------------------------------------------------------------------------------
-- Project name defaults to userassets folder.
local project = args[2] or "userassets"

_G.PROJECT    = project
-- This is necessary to allow proper interop wth the library
_G.REDIS      = require('redis-tools')

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

-- ------------------------------------------------------------------------------------------
-- Web serving settings. Split into REDIS and WWW IP host IPS.
--       REDIS uses localhost requests for security, no remote requests are allowed!!
_G.LOCALHOST_IP         = "127.0.0.1"
_G.LOCALHOST_WWW_IP     = "127.0.0.1"
--_G.LOCALHOST_IP = "192.168.8.203"
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

-- ------------------------------------------------------------------------------------------
-- Init the modules and the assets (builds modules and asset pools from folders)
session.init( { loginrequired = true } )
msetup.init()
asetup.init()

dataset = {}
dataset[project] = _G.USERASSETS

_G.loginrequired = false
if _G.editing == true or _G.SESSIONS.loginrequired == true then
    _G.loginrequired = true
end

-- ------------------------------------------------------------------------------------------
-- Predefine the user paths that will be provied for each project (web site).
local csspath = pathJoin(module.dir, pathJoin(project, "userassets/css"))
local htmlpath = pathJoin(module.dir, pathJoin(project, "userassets/html"))
local iconspath = pathJoin(module.dir, pathJoin(project, "userassets/icons"))
local scriptspath = pathJoin(module.dir, pathJoin(project, "userassets/scripts"))
local videospath = pathJoin(module.dir, pathJoin(project, "userassets/videos"))
local imagespath = require('imagecache')

-- ------------------------------------------------------------------------------------------
-- Proper server starts here - need cleanup
require('weblit-app')

-- Bind the server to the IP and look for the keys. Need to generate proper keys.
.bind({
    host = _G.LOCALHOST_WWW_IP,
    port = _G.LOCALHOST_PORT,
    tls = {
        key = lfs.readFileSync(pathJoin(module.dir, "ssl/keys/server.key")),
        cert = lfs.readFileSync(pathJoin(module.dir, "ssl/keys/server.crt"))
    }
})

-- Configure weblit server
-- Enable this line to view detailed logging of the server
--.use(require('weblit-logger'))
.use(require('weblit-auto-headers'))
-- Enable this line to allow the caching of etags - powerful when deploying (perf improvement)
--.use(require('weblit-etag-cache'))

-- Example of thow to map a folder to a specific path for access
--.use(static(pathJoin(module.dir, "static")))

-- Static data routes - these may become redis lookup (scripts and css especially)
--.route({ path = "/:path" }, static(pathJoin(module.dir, "static")))
.route({ path = "/styles/:path:" }, static(pathJoin(module.dir, "static/styles")))
.route({ path = "/scripts/:path:" }, static(pathJoin(module.dir, "static/scripts")))
.route({ path = "/images/:path:" }, static(pathJoin(module.dir, "static/images")))
.route({ path = "/fonts/:path:" }, static(pathJoin(module.dir, "static/fonts")))

--Special static routes for templates - same data though.
.route({ path = "/templates/:path:" }, resty(pathJoin(module.dir, "templates"), dataset) )
.route({ path = "/templates/styles/:path:" }, static(pathJoin(module.dir, "static/styles")))
.route({ path = "/templates/scripts/:path:" }, static(pathJoin(module.dir, "static/scripts")))
.route({ path = "/templates/images/:path:" }, static(pathJoin(module.dir, "static/images")))
.route({ path = "/templates/fonts/:path:" }, static(pathJoin(module.dir, "static/fonts")))

--.route({ path = "/userassets/html/:path:" }, static(htmlpath))
.route({ path = "/userassets/css/:path:" }, static(csspath))
.route({ path = "/userassets/icons/:path:" }, static(iconspath))
.route({ path = "/userassets/scripts/:path:" }, static(scriptspath))
.route({ path = "/userassets/videos/:path:" }, static(videospath))

.route({ path = "/userassets/images/:path:" }, imagespath(module.dir) )

--.route({ path = "/admin/:name:.html" }, require('controllers/admin'))
--.route({ path = "/admin/:path:/:name:.html" }, require('controllers/admin'))
.route({ path = "/:name:.html" }, require('controllers/template'))
--.route({ path = "/:path:/:name:.html" }, require('controllers/template'))

--.route({ path = "/functions/website_demo" }, require('website_demo'))

--.route({ path = "/functions/pagenew" }, require('page_new'))
--.route({ path = "/functions/pageedit" }, require('page_edit'))

--.route({ path = "/functions/blognew   " }, require('blog_new'))
--.route({ path = "/functions/blogedit" }, require('blog_edit'))

.route({ path = "/functions/userlogin" }, require('userlogin'))
.route({ path = "/functions/getmodule" }, require('getmodule'))
--.route({ path = "/functions/likeblock" }, require('likeblock'))

-- TODO: Build an api interface for automating the above. These will be issued to the local
--       redis server as lua scripts that can be issued without restarting a server.
--.route({ path = "/functions/api" }, require('api'))
--.route({ method = "GET", path = "/admin/:userpage:/settings" }, require('website_settings'))

-- Saving pages must be done from admin with a valid userpage
--.route({ method = "POST", path = "/admin/:userpage:/save" }, require('website_save'))

.route({ method = "POST", path = "/functions/submit" }, require('form_submit'))
-- Only allow specific access when authenicating, and saving.
.route({ method = "POST", path = "/:userpage:/check" }, require('website_login'))
--.route({ method = "POST", path = "/admin/:userpage:/check" }, require('website_login'))
--.route({ method = "POST", path = "/admin/upload/:filename" }, require('controllers/upload'))

.start()

-- ------------------------------------------------------------------------------------------
-- Build some initial content - this will be removed, once everything is sorted out.
require('generatecontent').init(asetup)


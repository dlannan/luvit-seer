-- NOTE: This is a temporary dataset and will become a "test" dataset in the future.
--       All data will come from the redis server data (or an sqlite one - dep on suitability)

local dataset = {

    grav = {
        user     = {
            username = "Trevor",
            authenticated = true,
        },
        language = {
            getLanguage = "en",
        },
        session = {
            form    = {},
        }
    },

    site = {
        title       = "site title",
        description = "site description",
        metadata    = {
            title           = "SEER",
            seerbuild       = "SEER 1.0.0",
        },
        isMobile    = false,

        -- Data sources are a list of all data sources this server can access
        -- They will include git repo links, databases, and file paths.
        datasources     = {
            [1]     = {
                name        = "Local Seer Assets",
                type        = "filepath",
                params      = {
                    path        = "/mnt/f/dev/web/test-assets",
                    readonly    = true,
                    security    = true,
                    excluded    = { },      -- List of excluded folder within the path that is not allowed
                },
                modified    = "01-01-2001-00-00-00",  -- last modified
                updated     = "01-01-2001-00-00-00",  -- last updated (pulled from git, or checked db/fs)
                created     = "01-01-2001-00-00-00",  -- Creation datetime
            }
        }
    },

    theme_url = "",
    page = {
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
        uri = {
            query   = {},
        },
        sceneid     = 1,
        projectid   = 1,

        threed = {
            nearCamera = 1.0,
            farCamera = 1000.0,
        }
    },

    projects = {
        [1] = {
            name     = "Project 1",
            projectid = 1,
            uid      = "012345",
            desc     = "Project 1 description",
            modified = "01/01/2001",
            paths    = {

            },
            cases   = {
                [1] = {
                    caseid      = 1,
                    name        = "Case 1",
                    description = "Case 1 Description",

                    edituser    = "Joe Smith",
                    edittime    = "01-01-2001-12-30",
                    icon        = "/content/images/plywood.jpg",
                    
                    tags        = "vehicles, f18, static",
                    
                    models      = {},
                    images      = {},
                    animations  = {},
                }
            },
            scenes   = {
                [1] = {
                    name        = "Scene 1",
                    sceneid     = 1,
                    edituser    = "Joe Smith",
                    edittime    = "01-01-2001-12-30",
                    icon = "/content/images/plywood.jpg",
                },
            },
            users   = {
                [1] = {
                    name    = "Joe Smith",
                    email   = "joesmith@gmail.com",
                },
                [2] = {
                    name    = "Wendy Mundane",
                    email   = "wmundane@gmail.com",
                }
            },
        },
        [2] = {
            name     = "Project 2",
            projectid = 2,
            uid      = "012346",
            desc     = "Project 2 description",
            modified = "01/02/2001",
            scenes   = {
                [1] = {
                    name        = "Scene 1",
                    sceneid     = 1,
                    edituser    = "Joe Smith",
                    edittime    = "01-01-2001-12-31",
                    icon = "/content/images/wood.jpg",
                },
                [2] = {
                    name        = "Scene 2",
                    sceneid     = 2,
                    edituser    = "Joe Smith",
                    edittime    = "01-01-2001-12-32",
                    icon = "/content/images/waternormals.jpg",
                }
            },
            users   = {
                [1] = {
                    name    = "Joe Smith",
                    email   = "joesmith@gmail.com",
                },
                [2] = {
                    name    = "Wendy Mundane",
                    email   = "wmundane@gmail.com",
                }
            },            
        },
        [3] = {
            name     = "Project 3",
            projectid = 3,
            uid      = "012347",
            desc     = "Project 3 description",
            modified = "01/03/2001",
            scenes   = {
                [1] = {
                    name        = "Scene 1",
                    sceneid     = 1,
                    edituser    = "Joe Smith",
                    edittime    = "01-01-2001-12-33",
                    icon = "/content/images/rocks.jpg",
                },
                [2] = {
                    name        = "Scene 2",
                    sceneid     = 2,
                    edituser    = "Joe Smith",
                    edittime    = "01-01-2001-12-34",
                    icon = "/content/images/grass.png",
                }
            },
            users   = {
                [1] = {
                    name    = "Joe Smith",
                    email   = "joesmith@gmail.com",
                },
                [2] = {
                    name    = "Wendy Mundane",
                    email   = "wmundane@gmail.com",
                }
            },            
        },
    },
    envpages = {
        [1] = {
            title       = "City Road System",
            name        = "cityroadsystem",
            asset       = "cityroadsystem.gltf",
            format      = "gltf",
            loadscene   = "loadScene.js",
            path        = "/data/"
        },
        [2] = {
            title       = "Football Pitch",
            name        = "footballpitch",
            asset       = "FootballPitch.glb",
            format      = "glb",
            loadscene   = "loadScene.js",
        },
    },
    cameras = {
        position    = "{ pos = { x: 0, y: 0, z: -100 }  }",
        target      = "{ target = { x: 0, y: 0, z: 0 }  }",
    },
}

return dataset

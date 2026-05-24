-- NOTE: This is a temporary dataset and will become a "test" dataset in the future.
--       All data will come from the redis server data (or an sqlite one - dep on suitability)

local dataset = {

    grav = {
        user     = {
            username = "Trevor",
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
            title           = "Luvit Seer",
            seerbuild       = "Luvit Seer 1.0.0",
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
    },

    projects = {
        [1] = {
            name     = "Project 1",
            projectid = 1,
            uid      = "012345",
            desc     = "Project 1 description",
            modified = "01/01/2001",
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
        },
        [2] = {
            title       = "Football Pitch",
            name        = "footballpitch",
            asset       = "FootballPitch.glb",
            format      = "glb",
            loadscene   = "loadScene.js",
        },
    }
}

return dataset

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
    },
    site = {
        title       = "site title",
        description = "site description",
        metadata    = {
            seerbuild = "Luvit Seer 1.0.0",
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
    },

    projects = {
        [1] = {
            name     = "Project 1",
            uid      = "012345",
            desc     = "Project 1 description",
            modified = "01/01/2001",
            scenes   = {
                [1] = {
                    icon = "/content/images/plywood.jpg",
                },
            },
        },
        [2] = {
            name     = "Project 2",
            uid      = "012346",
            desc     = "Project 2 description",
            modified = "01/02/2001",
            scenes   = {
                [1] = {
                    icon = "/content/images/wood.jpg",
                },
                [2] = {
                    icon = "/content/images/waternormals.jpg",
                }
            },
        },
        [3] = {
            name     = "Project 3",
            uid      = "012347",
            desc     = "Project 3 description",
            modified = "01/03/2001",
            scenes   = {
                [1] = {
                    icon = "/content/images/rocks.jpg",
                },
                [2] = {
                    icon = "/content/images/grass.png",
                }
            },
        },
    }
}

return dataset

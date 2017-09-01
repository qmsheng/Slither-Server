local config = {
        {
            id = 1,
            value = 100,
            reward = 2,
            type = "killNum"
        },
        {
            id = 2,
            value = 1000,
            reward = 4,
            type = "killNum"
        },
        {
            id = 3,
            value = 5000,
            reward = 11,
            type = "killNum"
        },
        {
            id = 4,
            value = 400,
            reward = 2,
            type = "singleLen"
        },
        {
            id = 5,
            value = 700,
            reward = 4,
            type = "singleLen"
        },
        {
            id = 6,
            value = 1000,
            reward = 10,
            type = "singleLen"
        },
        {
            id = 7,
            value = 5000,
            reward = 2,
            type  = "topLength",
        },
        {
            id = 8,
            value = 10000,
            reward = 4,
            type  = "topLength",
        },
        {
            id = 9,
            value = 100000,
            reward = 11,
            type  = "topLength",
        },
        {
            id = 10,
            value = 5,
            reward = 2,
            type  = "level",
        },
        {
            id = 11,
            value = 15,
            reward = 4,
            type  = "level",
        },
        {
            id = 12,
            value = 30,
            reward = 10,
            type  = "level",
        },
        {
            id = 13,
            value = 100,
            reward = 2,
            type  = "follower",
        },
        {
            id = 14,
            value = 500,
            reward = 4,
            type  = "follower",
        },
        {
            id = 15,
            value = 5000,
            reward = 11,
            type  = "follower",
        },
        {
            id = 16,
            value = 100,
            reward = 2,
            type  = "following",
        },
        {
            id = 17,
            value = 500,
            reward = 4,
            type  = "following",
        },
        {
            id = 18,
            value = 5000,
            reward = 11,
            type  = "following",
        },



    -- killNum =  {
    --     value = {100,1000,5000},
    --     reward = {2,4,11}
    -- },
    -- singleLen = {
    --     value = {400,700,1000},
    --     reward = {2,4,10}
    -- },
    -- totalLen = {
    --     value = {5000,10000,100000},
    --     reward = {2,4,11}
    -- },
    -- level   = {
    --     value = {5,15,30},
    --     reward = {2,4,10}
    -- },
    -- follower =  {
    --     value = {100,500,5000},
    --     reward = {2,4,11}
    -- },
    -- following = {
    --     value = {100,500,5000},
    --     reward = {2,4,11}
    -- },
}

return config


local tcpPort = 9010
-- local tcpPort = 7000

local config = {
    DEBUG = cc.DEBUG_ERROR,

    -- all apps
    apps = {
        slither = "/Users/qms/Desktop/Slither-Server/apps/slither",
    },

    -- custom workers
    customWorkers = {
        slither = "GameServerInstance"
    },

    -- default app config
    app = {
        messageFormat              = "json",
        defaultAcceptedRequestType = "http",
        sessionExpiredTime         = 60 * 10, -- 10m

        httpEnabled                = true,
        httpMessageFormat          = "json",

        websocketEnabled           = true,
        websocketMessageFormat     = "json",
        websocketsTimeout          = 60 * 1000, -- 60s
        websocketsMaxPayloadLen    = 16 * 1024, -- 16KB

        jobMessageFormat           = "json",
        numOfJobWorkers            = 1,

        jobWorkerRequests          = 10000,
    },

    -- server config
    server = {
        nginx = {
            numOfWorkers = 1,
            port = tcpPort,
        },

        -- 游戏配置
        GameConfig = {
            loopInterval    = 1.0/100,  -- 逻辑循环更新间隔
            sectorSize      = 300,
            mapRadius       = 1000*9,
            foodMaxCount    = 6000,
            foodRadius      = {10, 20},
            bodyRadius      = 30,
            snakeLength     = 20,
            windowSize      = 6,
            snakeVelocity   = { x = 5, y = 5 },     --初始速度
            updateInterval  = 1/60 * 2,             --服务器广播消息的间隔,单位为s
            snakeMaxLength  = 400,
            deltaRadius     = 0.25,
            snakeMaxRadius  = 80,
            hitlessTime     = 5,
            roomMaxUser     = 100,
            roomExpired     = 60*60*24,
        },

        -- gamecore server
        gamecore = {
            type        = "websocket",
            port        = tcpPort,
            protocol    = "slither",
            decryptKey  = "mybogame.SnakeRender",
            timeout     = 3,
        },

        -- client build 要求, 判断强制升级
        client_build = 8,

        -- internal memory database
        redis = {
            -- socket     = "unix:/Users/qms/Desktop/Slither-Server/tmp/redis.sock",
            -- host       = "127.0.0.1",
            host       = "192.168.16.72",
            port       = 6379,
            timeout    = 10 * 1000, -- 10 seconds
        },

        -- websocket message subscribe redis
        redis_sub = {
            -- socket     = "unix:/Users/qms/Desktop/Slither-Server/tmp/redis_sub.sock",
            -- host       = "127.0.0.1",
            host       = "192.168.16.72",
            port       = 6379,
            timeout    = 10 * 1000, -- 10 seconds
        },

        -- background job server
        beanstalkd = {
            host         = "127.0.0.1",
            port         = 10000+tcpPort,
        },

        mysql = {
            host = "192.168.16.221",
            port = "3306",
            user = "root",
            password = "CS---107",
            database = "slither-dev",
        },

    }
}

return config

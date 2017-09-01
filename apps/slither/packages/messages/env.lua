
local env = {}

function env.init()
    if cc.import then
        -- Server
        env.import      = cc.import
        env.class       = cc.class
        env.ByteArray   = cc.import("framework.utils.ByteArray")
        env.new = function(cls, ...)
            return cls:new(...)
        end
        env.newByteArray = function()
            return env.ByteArray:new()
        end
        env.json        = require "cjson.safe"
    else
        -- Client
        env.import      = import
        env.class       = class
        env.ByteArray   = cc.load("quick").utils.ByteArray
        env.new = function(cls, ...)
            return cls.new(...)
        end
        env.newByteArray = function()
            return env.ByteArray.new()
        end
        env.json        = require "cjson"
    end
end

env.init()

return env

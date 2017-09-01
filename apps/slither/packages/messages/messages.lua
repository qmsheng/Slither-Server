
local _CUR = ...
local import = import or cc.import
local env = import(".env")

local _M = {
    env                = env,
    MessageBase        = env.import(".MessageBase"),
    Echo               = env.import(".Echo"),
    Ready              = env.import(".Ready"),
    Pos                = env.import(".ClientPos"),
    Init               = env.import(".InitMsg"),
    UpdateSnake        = env.import(".UpdateSnakeMsg"),
    SnakeHit           = env.import(".SnakeHit"),
    FoodHit            = env.import(".FoodHit"),
    ClientSnake        = env.import(".ClientSnake"),
    Sectors            = env.import(".UpdateSector"),
    AddSnake           = env.import(".AddSnakeMsg"),
    RemoveSnake        = env.import(".RemoveSnakeMsg"),
    AddFood            = env.import(".AddFoodMsg"),
    RemoveFood         = env.import(".RemoveFoodMsg"),
    EatFood            = env.import(".EatFoodMsg"),
    AddBody            = env.import(".AddBodyMsg"),
    RemoveBody         = env.import(".RemoveBodyMsg"),
    HeartBeat          = env.import(".HeartBeat"),
    Debug              = env.import(".DebugMsg"),
    EnterGame          = env.import(".EnterGame"),
    LeaveGame          = env.import(".LeaveGame"),
    CommonResult       = env.import(".CommonResult"),
    CommonRequest      = env.import(".CommonRequest"),
    SpeedUp            = env.import(".SpeedUp"),
    HitEnable          = env.import(".HitEnable")
}

local identifie = {
    Y = "Ready",
    A = "Init",
    F = "AddFood",
    f = "RemoveFood",
    S = "AddSnake",
    R = "RemoveSnake",
    P = "Pos",
    C = "ClientSnake",
    H = "FoodHit",
    E = "Echo",
    B = "SnakeHit",
    D = "Sectors",
    U = "UpdateSnake",
    G = "EatFood",
    J = "AddBody",
    j = "RemoveBody",
    T = "HeartBeat",
    X = "Debug",
    e = "EnterGame",
    L = "LeaveGame",
    c = "CommonResult",
    r = "CommonRequest",
    s = "SpeedUp",
    h = "HitEnable",
}

function _M.parse(stream)
    local ba = env.newByteArray()
    ba:writeBuf(stream)
    ba:setPos(1)
    local msgName = ba:readString(1)
    local clName = identifie[msgName]
    local msg = env.new(_M[clName])
    msg.name = clName
    msg:parse(ba)
    return msg
end

return _M

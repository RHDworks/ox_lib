---@class FreecamModule
lib.freecam = {}

local GetDisabledControlNormal = GetDisabledControlNormal
local GetFrameTime = GetFrameTime
local CreateCam = CreateCam
local SetCamCoord = SetCamCoord
local SetCamRot = SetCamRot
local SetCamFov = SetCamFov
local IsCamActive = IsCamActive
local DestroyCam = DestroyCam
local RenderScriptCams = RenderScriptCams
local SetPlayerControl = SetPlayerControl
local GetGameplayCamCoord = GetGameplayCamCoord
local GetGameplayCamRot = GetGameplayCamRot
local GetInteriorAtCoords = GetInteriorAtCoords
local LoadInterior = LoadInterior
local SetFocusArea = SetFocusArea
local ClearFocus = ClearFocus
local LockMinimapPosition = LockMinimapPosition
local UnlockMinimapPosition = UnlockMinimapPosition
local LockMinimapAngle = LockMinimapAngle
local UnlockMinimapAngle = UnlockMinimapAngle
local IsInputDisabled = IsInputDisabled
local IsPauseMenuActive = IsPauseMenuActive

local math_min = math.min
local math_max = math.max
local math_sin = math.sin
local math_cos = math.cos
local math_rad = math.rad
local math_floor = math.floor

local CONTROL_INPUTS = {
    LOOK_LR = 1,
    LOOK_UD = 2,
    CHARACTER_WHEEL = 19,
    SPRINT = 21,
    MOVE_UD = 31,
    MOVE_LR = 30,
    VEH_ACCELERATE = 71,
    VEH_BRAKE = 72,
    PARACHUTE_BRAKE_LEFT = 152,
    PARACHUTE_BRAKE_RIGHT = 153,
}

---@param tbl table
---@return table
local function protect_table(tbl)
    return setmetatable(tbl, {
        __index = function(_, key)
            error(('Key `%s` is not supported.'):format(tostring(key)), 2)
        end,
        __newindex = function(_, key)
            error(('Key `%s` is not supported.'):format(tostring(key)), 2)
        end
    })
end

---@return boolean
local function is_gamepad_active()
    return not IsInputDisabled(2)
end

---@param keyboard table
---@param gamepad table
---@return table
local function create_gamepad_metatable(keyboard, gamepad)
    return setmetatable({}, {
        __index = function(_, key)
            return (is_gamepad_active() and gamepad or keyboard)[key]
        end
    })
end

local CONFIG = {}

CONFIG.BASE_CONTROL_MAPPING = protect_table({
    LOOK_X = CONTROL_INPUTS.LOOK_LR,
    LOOK_Y = CONTROL_INPUTS.LOOK_UD,
    MOVE_X = CONTROL_INPUTS.MOVE_LR,
    MOVE_Y = CONTROL_INPUTS.MOVE_UD,
    MOVE_Z = { CONTROL_INPUTS.PARACHUTE_BRAKE_LEFT, CONTROL_INPUTS.PARACHUTE_BRAKE_RIGHT },
    MOVE_FAST = CONTROL_INPUTS.SPRINT,
    MOVE_SLOW = CONTROL_INPUTS.CHARACTER_WHEEL
})

CONFIG.BASE_CONTROL_SETTINGS = protect_table({
    LOOK_SENSITIVITY_X = 5,
    LOOK_SENSITIVITY_Y = 5,
    BASE_MOVE_MULTIPLIER = 1,
    FAST_MOVE_MULTIPLIER = 10,
    SLOW_MOVE_MULTIPLIER = 10,
})

CONFIG.BASE_CAMERA_SETTINGS = protect_table({
    FOV = 45.0,
    ENABLE_EASING = true,
    EASING_DURATION = 1000,
    KEEP_POSITION = false,
    KEEP_ROTATION = false
})

CONFIG.keyboard = {
    control_mapping = lib.table.deepclone(CONFIG.BASE_CONTROL_MAPPING),
    control_settings = lib.table.deepclone(CONFIG.BASE_CONTROL_SETTINGS)
}

CONFIG.gamepad = {
    control_mapping = lib.table.deepclone(CONFIG.BASE_CONTROL_MAPPING),
    control_settings = lib.table.deepclone(CONFIG.BASE_CONTROL_SETTINGS)
}

CONFIG.gamepad.control_mapping.MOVE_Z = { CONTROL_INPUTS.PARACHUTE_BRAKE_LEFT, CONTROL_INPUTS.PARACHUTE_BRAKE_RIGHT }
CONFIG.gamepad.control_mapping.MOVE_FAST = CONTROL_INPUTS.VEH_ACCELERATE
CONFIG.gamepad.control_mapping.MOVE_SLOW = CONTROL_INPUTS.VEH_BRAKE
CONFIG.gamepad.control_settings.LOOK_SENSITIVITY_X = 2
CONFIG.gamepad.control_settings.LOOK_SENSITIVITY_Y = 2

protect_table(CONFIG.keyboard.control_mapping)
protect_table(CONFIG.keyboard.control_settings)
protect_table(CONFIG.gamepad.control_mapping)
protect_table(CONFIG.gamepad.control_settings)

CONFIG.camera_settings = lib.table.deepclone(CONFIG.BASE_CAMERA_SETTINGS)
protect_table(CONFIG.camera_settings)

CONFIG.CONTROL_MAPPING = create_gamepad_metatable(
    CONFIG.keyboard.control_mapping,
    CONFIG.gamepad.control_mapping
)
CONFIG.CONTROL_SETTINGS = create_gamepad_metatable(
    CONFIG.keyboard.control_settings,
    CONFIG.gamepad.control_settings
)

local STATE = {
    camera = nil,
    is_frozen = false,
    is_active = false,
    position = nil,
    rotation = nil,
    fov = nil,
    matrix = {
        x = nil,
        y = nil,
        z = nil
    }
}

---@param value number
---@param min_val number
---@param max_val number
---@return number
local function clamp(value, min_val, max_val)
    return math_min(math_max(value, min_val), max_val)
end

---@param rot_x number
---@param rot_y number
---@param rot_z number
---@return number, number, number
local function clamp_camera_rotation(rot_x, rot_y, rot_z)
    return clamp(rot_x, -90.0, 90.0), rot_y % 360, rot_z % 360
end

---@param rot_x number
---@param rot_y number
---@param rot_z number
---@return vector3, vector3, vector3
local function euler_to_matrix(rot_x, rot_y, rot_z)
    local rad_x, rad_y, rad_z = math_rad(rot_x), math_rad(rot_y), math_rad(rot_z)
    local sin_x, sin_y, sin_z = math_sin(rad_x), math_sin(rad_y), math_sin(rad_z)
    local cos_x, cos_y, cos_z = math_cos(rad_x), math_cos(rad_y), math_cos(rad_z)

    return vector3(cos_y * cos_z, cos_y * sin_z, -sin_y),
           vector3(cos_z * sin_x * sin_y - cos_x * sin_z, cos_x * cos_z - sin_x * sin_y * sin_z, cos_y * sin_x),
           vector3(-cos_x * cos_z * sin_y + sin_x * sin_z, -cos_z * sin_x + cos_x * sin_y * sin_z, cos_x * cos_y)
end

---@return vector3
local function get_initial_position()
    return (CONFIG.camera_settings.KEEP_POSITION and STATE.position) or GetGameplayCamCoord()
end

---@return vector3
local function get_initial_rotation()
    if CONFIG.camera_settings.KEEP_ROTATION and STATE.rotation then
        return STATE.rotation
    end
    local rot = GetGameplayCamRot(0)
    return vector3(rot.x, 0.0, rot.z)
end

---@param control integer|table
---@return number
local function get_control_normal(control)
    if type(control) == 'table' then
        return GetDisabledControlNormal(0, control[1]) - GetDisabledControlNormal(0, control[2])
    end
    return GetDisabledControlNormal(0, control)
end

---@return number
local function get_speed_multiplier()
    local fast_normal = get_control_normal(CONFIG.CONTROL_MAPPING.MOVE_FAST)
    local slow_normal = get_control_normal(CONFIG.CONTROL_MAPPING.MOVE_SLOW)
    local settings = CONFIG.CONTROL_SETTINGS

    local base_speed = settings.BASE_MOVE_MULTIPLIER
    local fast_speed = 1 + ((settings.FAST_MOVE_MULTIPLIER - 1) * fast_normal)
    local slow_speed = 1 + ((settings.SLOW_MOVE_MULTIPLIER - 1) * slow_normal)

    return base_speed * fast_speed / slow_speed * GetFrameTime() * 60
end

local function update_camera()
    if not STATE.is_active or IsPauseMenuActive() or STATE.is_frozen then
        return
    end

    local vec_x, vec_y = STATE.matrix.x, STATE.matrix.y
    local vec_z = vector3(0, 0, 1)
    local position, rotation = STATE.position, STATE.rotation
    local controls, settings = CONFIG.CONTROL_MAPPING, CONFIG.CONTROL_SETTINGS

    local speed_multiplier = get_speed_multiplier()
    local look_x = get_control_normal(controls.LOOK_X)
    local look_y = get_control_normal(controls.LOOK_Y)
    local move_x = get_control_normal(controls.MOVE_X)
    local move_y = get_control_normal(controls.MOVE_Y)
    local move_z = get_control_normal(controls.MOVE_Z)

    local new_rotation = vector3(
        rotation?.x + (-look_y * settings.LOOK_SENSITIVITY_X),
        rotation?.y,
        rotation?.z + (-look_x * settings.LOOK_SENSITIVITY_Y)
    )

    local new_position = position
        + (vec_x * move_x * speed_multiplier)
        + (vec_y * -move_y * speed_multiplier)
        + (vec_z * move_z * speed_multiplier)

    -- Update camera
    lib.freecam.setPosition(new_position.x, new_position.y, new_position.z)
    lib.freecam.setRotation(new_rotation.x, new_rotation.y, new_rotation.z)
end

local camera_thread = nil
local function start_camera_loop()
    if camera_thread then return end
    
    CreateThread(function(id)
        camera_thread = id

        while STATE.is_active do
            update_camera()
            Wait(0)
        end

        camera_thread = nil
    end)
end

---@param distance number
---@return vector3
function lib.freecam.getTarget(distance)
    return STATE.position + (STATE.matrix.y * distance)
end

---@return vector3, vector3, vector3, vector3
function lib.freecam.getMatrix()
    return STATE.matrix.x, STATE.matrix.y, STATE.matrix.z, STATE.position
end

---@return vector3
function lib.freecam.getPosition()
    return STATE.position
end

---@param x number
---@param y number
---@param z number
function lib.freecam.setPosition(x, y, z)
    local position = vector3(x, y, z)
    local interior = GetInteriorAtCoords(position.x, position.y, position.z)

    LoadInterior(interior)
    SetFocusArea(position.x, position.y, position.z, 0.0, 0.0, 0.0)
    LockMinimapPosition(x, y)
    
    if STATE.camera then
        SetCamCoord(STATE.camera, position.x, position.y, position.z)
    end

    STATE.position = position
end

---@param fov number
function lib.freecam.setFov(fov)
    local clamped_fov = clamp(fov, 0.0, 90.0)
    
    if STATE.camera then
        SetCamFov(STATE.camera, clamped_fov)
    end
    
    STATE.fov = clamped_fov
end

---@return number
function lib.freecam.getFov()
    return STATE.fov
end

---@param frozen boolean
function lib.freecam.setFrozen(frozen)
    STATE.is_frozen = frozen == true
end

---@return boolean
function lib.freecam.isFrozen()
    return STATE.is_frozen
end

---@return boolean
function lib.freecam.isActive()
    ---@diagnostic disable-next-line: return-type-mismatch
    return STATE.is_active and STATE.camera and IsCamActive(STATE.camera) == 1
end

---@return vector3
function lib.freecam.getRotation()
    return STATE.rotation
end

---@param x number
---@param y number
---@param z number
function lib.freecam.setRotation(x, y, z)
    local rot_x, rot_y, rot_z = clamp_camera_rotation(x, y, z)
    local vec_x, vec_y, vec_z = euler_to_matrix(rot_x, rot_y, rot_z)
    local rotation = vector3(rot_x, rot_y, rot_z)

    LockMinimapAngle(math_floor(rot_z))
    
    if STATE.camera then
        SetCamRot(STATE.camera, rotation.x, rotation.y, rotation.z, 0)
    end

    STATE.rotation = rotation
    STATE.matrix.x = vec_x
    STATE.matrix.y = vec_y
    STATE.matrix.z = vec_z
end

function lib.freecam.toggle()
    STATE.is_active = not lib.freecam.isActive()

    if STATE.is_active then
        local position = get_initial_position()
        local rotation = get_initial_rotation()

        STATE.camera = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)

        lib.freecam.setFov(CONFIG.camera_settings.FOV)
        lib.freecam.setPosition(position.x, position.y, position.z)
        lib.freecam.setRotation(rotation.x, rotation.y, rotation.z)
        
        start_camera_loop()
        SetEntityVisible(cache.ped, false, false)
    else
        if STATE.camera then
            DestroyCam(STATE.camera, false)
            STATE.camera = nil
        end
        
        ClearFocus()
        UnlockMinimapPosition()
        UnlockMinimapAngle()
        SetEntityVisible(cache.ped, true, true)
    end

    SetPlayerControl(cache.playerId, not STATE.is_active, 0)
    RenderScriptCams(
        STATE.is_active,
        CONFIG.camera_settings.ENABLE_EASING,
        CONFIG.camera_settings.EASING_DURATION,
        false,
        false
    )
end

AddEventHandler('onResourceStop', function(resource_name)
    if resource_name == GetCurrentResourceName() and STATE.is_active then
        lib.freecam.toggle()
        SetPlayerControl(cache.playerId, true, 0)
        SetEntityVisible(cache.ped, true, true)
    end
end)


return lib.freecam

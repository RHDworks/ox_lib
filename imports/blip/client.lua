---@class BlipManager
lib.blip = {}

local blips = {}
local blip_counter = 0
local blip_groups = {}

local BLIP_DISPLAY = {
    BOTH = 2,
    MAP_ONLY = 3,
    MINIMAP_ONLY = 5,
    BOTH_SELECTABLE = 8
}

local BLIP_CATEGORY = {
    NONE = 0,
    BLIP_CATEGORY_HOUSE = 1,
    BLIP_CATEGORY_GARAGE = 2,
    BLIP_CATEGORY_ENTERTAINMENT = 3,
    BLIP_CATEGORY_BUSINESS = 4,
    BLIP_CATEGORY_EMERGENCY = 5,
    BLIP_CATEGORY_TRANSPORT = 6,
    BLIP_CATEGORY_FUEL = 7,
    BLIP_CATEGORY_OTHER = 10
}

local BLIP_SPRITES = {
    WAYPOINT = 8,
    PLAYER = 1,
    VEHICLE = 225,
    GARAGE = 50,
    HOUSE = 40,
    SHOP = 52,
    GUN_SHOP = 110,
    CLOTHING = 73,
    BARBER = 71,
    FUEL_STATION = 361,
    HOSPITAL = 61,
    POLICE = 60,
    FIRE_STATION = 436,
    BANK = 108,
    ATM = 277,
    AIRPORT = 307,
    HELIPAD = 43,
    MARINA = 471,
    GOLF = 109,
    CINEMA = 135,
    RESTAURANT = 93,
    BAR = 93,
    STRIP_CLUB = 121,
    CASINO = 679,
    MISSION = 1
}

local BLIP_COLORS = {
    WHITE = 0,
    RED = 1,
    GREEN = 2,
    BLUE = 3,
    YELLOW = 5,
    LIGHT_RED = 6,
    VIOLET = 7,
    PINK = 8,
    LIGHT_ORANGE = 17,
    ORANGE = 18,
    LIGHT_BLUE = 26,
    DARK_BLUE = 29,
    PURPLE = 27,
    DARK_GREEN = 25,
    LIGHT_GREEN = 11,
    LIME_GREEN = 43,
    GOLD = 46,
    BRONZE = 47,
    SILVER = 3,
    DARK_RED = 49,
    LIGHT_YELLOW = 66,
    DARK_ORANGE = 81
}

local DEFAULT_BLIP_CONFIG = {
    sprite = BLIP_SPRITES.WAYPOINT,
    color = BLIP_COLORS.WHITE,
    scale = 1.0,
    display = BLIP_DISPLAY.BOTH,
    category = BLIP_CATEGORY.NONE,
    short_range = true,
    high_detail = false,
    alpha = 255,
    rotation = 0.0,
    priority = 7,
    flash = false,
    flash_timer = 0,
    route = false,
    route_color = BLIP_COLORS.YELLOW,
    show_number = false,
    number = 0,
    show_tick = false,
    show_heading = false,
    pulse = false
}

---@param value any
---@param default any
---@return any
local function default_value(value, default)
    return value ~= nil and value or default
end

---@param config table
---@return table
local function merge_config(config)
    local merged = {}
    for key, default_val in pairs(DEFAULT_BLIP_CONFIG) do
        merged[key] = default_value(config[key], default_val)
    end
    return merged
end

---@param blip_handle integer
---@param name string
local function set_blip_name(blip_handle, name)
    if not name or name == '' then return end
    
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(name)
    EndTextCommandSetBlipName(blip_handle)
end

---@param blip_handle integer
---@param config table
local function apply_blip_config(blip_handle, config)
    if not DoesBlipExist(blip_handle) then return end

    SetBlipSprite(blip_handle, config.sprite)
    SetBlipColour(blip_handle, config.color)
    SetBlipScale(blip_handle, config.scale)
    SetBlipDisplay(blip_handle, config.display)
    SetBlipCategory(blip_handle, config.category)
    SetBlipAsShortRange(blip_handle, config.short_range)
    SetBlipAlpha(blip_handle, config.alpha)
    SetBlipRotation(blip_handle, math.rad(config.rotation))
    SetBlipPriority(blip_handle, config.priority)

    if config.flash then
        SetBlipFlashes(blip_handle, true)
        if config.flash_timer > 0 then
            SetBlipFlashTimer(blip_handle, config.flash_timer)
        end
    end

    if config.route then
        SetBlipRoute(blip_handle, true)
        SetBlipRouteColour(blip_handle, config.route_color)
    end

    if config.show_number then
        ShowNumberOnBlip(blip_handle, config.number)
    end

    if config.pulse then
        PulseBlip(blip_handle)
    end
end

---@return string
local function generate_blip_id()
    blip_counter += 1
    return ('blip_%d_%d'):format(blip_counter, GetGameTimer())
end

---@param coords vector3|table
---@param config? table
---@return string|nil
function lib.blip.create(coords, config)
    if not coords then
        lib.print.error('Blip creation failed: coords are required')
        return nil
    end

    config = merge_config(config or {})
    local blip_handle = AddBlipForCoord(coords.x or coords[1], coords.y or coords[2], coords.z or coords[3] or 0.0)
    
    if not DoesBlipExist(blip_handle) then
        lib.print.error('Failed to create blip at coordinates: %s', coords)
        return nil
    end

    apply_blip_config(blip_handle, config)
    
    if config.name then
        set_blip_name(blip_handle, config.name)
    end

    local blip_id = generate_blip_id()
    blips[blip_id] = {
        handle = blip_handle,
        type = 'coord',
        coords = coords,
        config = config,
        groups = {}
    }

    return blip_id
end

---@param entity integer
---@param config? table
---@return string|nil
function lib.blip.createForEntity(entity, config)
    if not entity or not DoesEntityExist(entity) then
        lib.print.error('Blip creation failed: invalid entity')
        return nil
    end

    config = merge_config(config or {})
    local blip_handle = AddBlipForEntity(entity)
    
    if not DoesBlipExist(blip_handle) then
        lib.print.error('Failed to create blip for entity: %d', entity)
        return nil
    end

    apply_blip_config(blip_handle, config)
    
    if config.name then
        set_blip_name(blip_handle, config.name)
    end

    local blip_id = generate_blip_id()
    blips[blip_id] = {
        handle = blip_handle,
        type = 'entity',
        entity = entity,
        config = config,
        groups = {}
    }

    return blip_id
end

---@param coords vector3|table
---@param radius number
---@param config? table
---@return string|nil
function lib.blip.createRadius(coords, radius, config)
    if not coords or not radius then
        lib.print.error('Radius blip creation failed: coords and radius are required')
        return nil
    end

    config = merge_config(config or {})
    local blip_handle = AddBlipForRadius(coords.x or coords[1], coords.y or coords[2], coords.z or coords[3] or 0.0, radius)
    
    if not DoesBlipExist(blip_handle) then
        lib.print.error('Failed to create radius blip at coordinates: %s', coords)
        return nil
    end

    apply_blip_config(blip_handle, config)
    
    if config.name then
        set_blip_name(blip_handle, config.name)
    end

    local blip_id = generate_blip_id()
    blips[blip_id] = {
        handle = blip_handle,
        type = 'radius',
        coords = coords,
        radius = radius,
        config = config,
        groups = {}
    }

    return blip_id
end

---@param blip_id string
---@return boolean
function lib.blip.remove(blip_id)
    local blip_data = blips[blip_id]
    if not blip_data then return false end

    if DoesBlipExist(blip_data.handle) then
        RemoveBlip(blip_data.handle)
    end

    for group_name in pairs(blip_data.groups) do
        if blip_groups[group_name] then
            blip_groups[group_name][blip_id] = nil
        end
    end

    blips[blip_id] = nil
    return true
end

---@param blip_id string
---@return boolean
function lib.blip.exists(blip_id)
    local blip_data = blips[blip_id]
    return blip_data and DoesBlipExist(blip_data.handle) or false
end

---@param blip_id string
---@param config table
---@return boolean
function lib.blip.update(blip_id, config)
    local blip_data = blips[blip_id]
    if not blip_data or not DoesBlipExist(blip_data.handle) then return false end

    for key, value in pairs(config) do
        blip_data.config[key] = value
    end

    apply_blip_config(blip_data.handle, blip_data.config)
    
    if config.name then
        set_blip_name(blip_data.handle, config.name)
    end

    return true
end

---@param blip_id string
---@return table|nil
function lib.blip.get(blip_id)
    local blip_data = blips[blip_id]
    if not blip_data or not DoesBlipExist(blip_data.handle) then return nil end

    local info = {
        id = blip_id,
        handle = blip_data.handle,
        type = blip_data.type,
        config = blip_data.config,
        groups = {}
    }

    for group_name in pairs(blip_data.groups) do
        info.groups[#info.groups + 1] = group_name
    end

    if blip_data.type == 'coord' or blip_data.type == 'radius' then
        info.coords = blip_data.coords
    end
    
    if blip_data.type == 'entity' then
        info.entity = blip_data.entity
    end
    
    if blip_data.type == 'radius' then
        info.radius = blip_data.radius
    end

    info.current_coords = GetBlipCoords(blip_data.handle)
    info.current_sprite = GetBlipSprite(blip_data.handle)
    info.current_color = GetBlipColour(blip_data.handle)
    info.is_short_range = IsBlipShortRange(blip_data.handle)
    info.is_on_minimap = IsBlipOnMinimap(blip_data.handle)

    return info
end

---@param group_name string
---@param blip_ids string[]
function lib.blip.createGroup(group_name, blip_ids)
    if blip_groups[group_name] then
        lib.print.warn('Blip group "%s" already exists', group_name)
        return
    end

    blip_groups[group_name] = {}
    
    if blip_ids then
        for _, blip_id in pairs(blip_ids) do
            lib.blip.addToGroup(blip_id, group_name)
        end
    end
end

---@param blip_id string
---@param group_name string
---@return boolean
function lib.blip.addToGroup(blip_id, group_name)
    local blip_data = blips[blip_id]
    if not blip_data then return false end

    if not blip_groups[group_name] then
        blip_groups[group_name] = {}
    end

    blip_groups[group_name][blip_id] = true
    blip_data.groups[group_name] = true
    
    return true
end

---@param blip_id string
---@param group_name string
---@return boolean
function lib.blip.removeFromGroup(blip_id, group_name)
    local blip_data = blips[blip_id]
    if not blip_data or not blip_groups[group_name] then return false end

    blip_groups[group_name][blip_id] = nil
    blip_data.groups[group_name] = nil
    
    return true
end

---@param group_name string
---@param config table
function lib.blip.updateGroup(group_name, config)
    local group = blip_groups[group_name]
    if not group then return end

    for blip_id in pairs(group) do
        lib.blip.update(blip_id, config)
    end
end

---@param group_name string
---@return boolean
function lib.blip.removeGroup(group_name)
    local group = blip_groups[group_name]
    if not group then return false end

    for blip_id in pairs(group) do
        lib.blip.remove(blip_id)
    end

    blip_groups[group_name] = nil
    return true
end

---@param group_name string
---@return string[]
function lib.blip.getGroup(group_name)
    local group = blip_groups[group_name]
    if not group then return {} end

    local blip_ids = {}
    for blip_id in pairs(group) do
        if lib.blip.exists(blip_id) then
            blip_ids[#blip_ids + 1] = blip_id
        end
    end

    return blip_ids
end

---@param blip_ids string[]
function lib.blip.removeMultiple(blip_ids)
    for _, blip_id in pairs(blip_ids) do
        lib.blip.remove(blip_id)
    end
end

---@param blip_ids string[]
---@param config table
function lib.blip.updateMultiple(blip_ids, config)
    for _, blip_id in pairs(blip_ids) do
        lib.blip.update(blip_id, config)
    end
end

function lib.blip.removeAll()
    for blip_id in pairs(blips) do
        lib.blip.remove(blip_id)
    end
end

---@param blip_type? string
function lib.blip.removeByType(blip_type)
    if not blip_type then return end

    for blip_id, blip_data in pairs(blips) do
        if blip_data.type == blip_type then
            lib.blip.remove(blip_id)
        end
    end
end

---@return string[]
function lib.blip.getAll()
    local all_blips = {}
    for blip_id in pairs(blips) do
        if lib.blip.exists(blip_id) then
            all_blips[#all_blips + 1] = blip_id
        end
    end
    return all_blips
end

---@param blip_type string
---@return string[]
function lib.blip.getByType(blip_type)
    local type_blips = {}
    for blip_id, blip_data in pairs(blips) do
        if blip_data.type == blip_type and lib.blip.exists(blip_id) then
            type_blips[#type_blips + 1] = blip_id
        end
    end
    return type_blips
end

---@param sprite integer
---@return string[]
function lib.blip.getBySprite(sprite)
    local sprite_blips = {}
    for blip_id, blip_data in pairs(blips) do
        if blip_data.config.sprite == sprite and lib.blip.exists(blip_id) then
            sprite_blips[#sprite_blips + 1] = blip_id
        end
    end
    return sprite_blips
end

---@param coords vector3|table
---@param radius number
---@return string[]
function lib.blip.getNearby(coords, radius)
    local nearby_blips = {}
    local radius_squared = radius * radius

    for blip_id, blip_data in pairs(blips) do
        if lib.blip.exists(blip_id) then
            local blip_coords = nil
            
            if blip_data.type == 'coord' or blip_data.type == 'radius' then
                blip_coords = blip_data.coords
            elseif blip_data.type == 'entity' then
                blip_coords = GetEntityCoords(blip_data.entity)
            end

            if blip_coords then
                local dx = (blip_coords.x or blip_coords[1]) - (coords.x or coords[1])
                local dy = (blip_coords.y or blip_coords[2]) - (coords.y or coords[2])
                local distance_squared = dx * dx + dy * dy

                if distance_squared <= radius_squared then
                    nearby_blips[#nearby_blips + 1] = blip_id
                end
            end
        end
    end

    return nearby_blips
end

---@return table
function lib.blip.getStats()
    local stats = {
        total_blips = 0,
        by_type = {},
        by_sprite = {},
        groups = {},
        orphaned = 0
    }

    for blip_id, blip_data in pairs(blips) do
        if lib.blip.exists(blip_id) then
            stats.total_blips += 1
            
            stats.by_type[blip_data.type] = (stats.by_type[blip_data.type] or 0) + 1
            stats.by_sprite[blip_data.config.sprite] = (stats.by_sprite[blip_data.config.sprite] or 0) + 1
        else
            stats.orphaned += 1
        end
    end

    for group_name, group_data in pairs(blip_groups) do
        local count = 0
        for blip_id in pairs(group_data) do
            if lib.blip.exists(blip_id) then
                count += 1
            end
        end
        stats.groups[group_name] = count
    end

    return stats
end

function lib.blip.cleanup()
    for blip_id, blip_data in pairs(blips) do
        if not DoesBlipExist(blip_data.handle) then
            blips[blip_id] = nil
        end
    end

    for group_name, group_data in pairs(blip_groups) do
        local has_blips = false
        for blip_id in pairs(group_data) do
            if lib.blip.exists(blip_id) then
                has_blips = true
                break
            end
        end
        
        if not has_blips then
            blip_groups[group_name] = nil
        end
    end
end

lib.blip.SPRITES = BLIP_SPRITES
lib.blip.COLORS = BLIP_COLORS
lib.blip.DISPLAY = BLIP_DISPLAY
lib.blip.CATEGORY = BLIP_CATEGORY

AddEventHandler('onResourceStop', function(resource_name)
    if resource_name == GetCurrentResourceName() then
        lib.blip.removeAll()
    end
end)

CreateThread(function()
    while true do
        Wait(300000)
        lib.blip.cleanup()
    end
end)

return lib.blip

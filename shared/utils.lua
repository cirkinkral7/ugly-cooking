-- ╔══════════════════════════════════════════════════════════════╗
-- ║            GLADIUS COOKING — SHARED UTILITIES                 ║
-- ╚══════════════════════════════════════════════════════════════╝

Gladius = Gladius or {}
Gladius.Utils = {}

---Debug log helper
---@param ... any
function Gladius.Utils.Log(...)
    if Config.Debug then
        print('[^5Gladius Cooking^7]', ...)
    end
end

---Get quality label from quality percentage
---@param quality number
---@return table { label, color }
function Gladius.Utils.GetQualityLabel(quality)
    quality = tonumber(quality) or 0
    local sorted = { 90, 70, 50, 0 }
    for _, threshold in ipairs(sorted) do
        if quality >= threshold then
            return Config.QualityMessages[threshold]
        end
    end
    return Config.QualityMessages[0]
end

---Calculate quality based on skillcheck success ratio
---@param successes number
---@param total number
---@return number quality (0–100)
function Gladius.Utils.CalculateQuality(successes, total)
    if total <= 0 then return 0 end
    local ratio = successes / total
    local quality = math.floor(Config.MinQuality + ((Config.MaxQuality - Config.MinQuality) * ratio))
    if quality > Config.MaxQuality then quality = Config.MaxQuality end
    if quality < 0 then quality = 0 end
    return quality
end

---Check if a timestamp is still fresh (within expiration hours)
---@param createdAt number unix seconds
---@param expirationHours number
---@return boolean fresh
---@return number hoursLeft
function Gladius.Utils.IsFresh(createdAt, expirationHours)
    createdAt = tonumber(createdAt) or 0
    expirationHours = tonumber(expirationHours) or 24
    local now = os.time()
    local elapsed = (now - createdAt) / 3600
    local hoursLeft = expirationHours - elapsed
    return hoursLeft > 0, hoursLeft
end

---Deep-copy a table
---@param t table
---@return table
function Gladius.Utils.DeepCopy(t)
    if type(t) ~= 'table' then return t end
    local out = {}
    for k, v in pairs(t) do
        out[k] = type(v) == 'table' and Gladius.Utils.DeepCopy(v) or v
    end
    return out
end

---@param shop table|nil
---@return number
function Gladius.Utils.GetShopProximityRadius(shop)
    if shop and shop.radius then return shop.radius end
    return Config.KitchenProximity or 2.0
end

---Get shop config for a job (Config.Shops key must match job name)
---@param job string
---@return table|nil
function Gladius.Utils.GetShopForJob(job)
    return Config.Shops[job]
end

---Get recipe from shop
---@param job string
---@param recipeId string
---@return table|nil
function Gladius.Utils.GetRecipe(job, recipeId)
    local shop = Gladius.Utils.GetShopForJob(job)
    if not shop then return nil end
    return shop.recipes and shop.recipes[recipeId]
end

---Get closest shop location for a player
---@param job string
---@param pos vector3
---@return number|nil index
---@return number|nil distance
function Gladius.Utils.GetClosestLocation(job, pos)
    local shop = Gladius.Utils.GetShopForJob(job)
    if not shop or not shop.locations then return nil, nil end
    local closestIdx, closestDist = nil, math.huge
    for idx, loc in ipairs(shop.locations) do
        local dist = #(pos - loc)
        if dist < closestDist then
            closestDist = dist
            closestIdx  = idx
        end
    end
    return closestIdx, closestDist
end

---Check if player is within radius of any shop location
---@param job string
---@param pos vector3
---@return boolean
function Gladius.Utils.IsInShop(job, pos)
    local shop = Gladius.Utils.GetShopForJob(job)
    if not shop then return false end
    local _, dist = Gladius.Utils.GetClosestLocation(job, pos)
    local maxDist = Gladius.Utils.GetShopProximityRadius(shop)
    return dist ~= nil and dist <= maxDist
end

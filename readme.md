# ugly Cooking

**ugly Cooking** is a **FiveM** resource for **QBCore** with **ox_inventory**: a multi-step cooking flow (preparation → cooking), **ox_lib** skillchecks, **NUI** menu, optional **ox_target** / **qb-target** zones at kitchen coordinates, and server-side validation (job, distance, ingredients) before items are removed or granted.

**Version:** 1.0.0 (see `fxmanifest.lua`)  
**Author:** ugly Development

---

## Features

- **Job-bound kitchens:** Each entry in `Config.Shops` is keyed by the **QB job name** (`PlayerData.job.name`). Players only see recipes for their current job and must be within the configured kitchen radius.
- **Recipes:** Per-shop recipes with ingredients (ox item names + amounts), prep step (difficulty + duration), cook step (appliance: `frying_pan` | `oven` | `grill`, duration, optional animation).
- **Quality:** Skillcheck success ratio maps to a quality percentage (`Config.MinQuality`–`Config.MaxQuality`); result items get **metadata** (quality label, colour, `created_at`, `expires_at`).
- **ox_lib:** Progress, points for proximity, and skillcheck APIs.
- **UI:** `html/` NUI; inventory sync while the menu is open (`ox_inventory:updateInventory`).
- **Commands:** Default `Config.OpenCommand` is **`/cook`** (changeable in `config.lua`). Optional keybind if `Config.OpenKey` is set to a key name (not the string `'nil'`).
- **Effects:** Optional **interact-sound** (`chopping.ogg`, `frying.ogg`), particle smoke, attached knife / pan props, BBQ-style cook animation (configurable in `Config.CookingEffects`).
- **Exports (client):** `HasKitchenAccess`, `OpenCookingMenu`, `CloseCookingMenu` (see `client/main.lua`).

---

## Dependencies

Declared in `fxmanifest.lua`:

| Resource | Role |
|----------|------|
| **qb-core** | Player data, callbacks, notifications |
| **ox_inventory** | Items, add/remove, search counts, metadata on cooked items |
| **ox_lib** | Points, progress, skillchecks, shared init |

**Strongly recommended if `Config.UseTarget` is true:**

- **ox_target** (when `Config.TargetResource == 'ox_target'`), or  
- **qb-target** / **qtarget** (when `Config.TargetResource == 'qb-target'` — code uses `exports.qtarget`; match this to your server’s target resource name).

**Optional:**

- **interact-sound** — for chopping/frying sounds (`Config.CookingEffects.interactSound`).

---

## Installation

### 1. Copy the resource

Place the folder under your resources tree, for example:

```text
resources/
  [ugly]/
    ugly-cooking/
      fxmanifest.lua
      config.lua
      ITEMS.lua
      ...
```

### 2. Register items in ox_inventory

Open `ugly-cooking/ITEMS.lua`. Merge the returned table into **`ox_inventory/data/items.lua`** (or your equivalent items file), following ox_inventory’s format. The file header explains:

- Copy item definitions from `ITEMS.lua` into ox_inventory’s items.
- Add item images to **`ox_inventory/web/images/`** (names must match what you use in recipes / config, e.g. `gourmet_burger.png`).

Cooked items use **`stack = false`** because metadata differs per craft.

### 3. Server configuration (`server.cfg`)

Start dependencies **before** this resource, for example:

```cfg
ensure qb-core
ensure oxmysql
ensure ox_lib
ensure ox_inventory
ensure ox_target
ensure [ugly]
```

Or explicitly:

```cfg
ensure ugly-cooking
```

If you use a bracket folder `ensure [ugly]`, ensure `ugly-cooking` is inside that folder.

### 4. Adjust `config.lua`

- **`Config.Shops`:** Keys must equal **QB job names** (e.g. `police`, `pizzaria` in the sample). Each shop has `locations` (`vector3` list), optional `radius`, optional `blip`, and `recipes`.
- **`Config.KitchenProximity`:** Default interaction distance (metres) if a shop has no `radius`.
- **`Config.UseTarget` / `Config.TargetResource`:** Enable zones and pick target script.
- **`Config.OpenCommand` / `Config.OpenKey`:** Menu open command and optional key.
- **`Config.Debug`:** Verbose prints to server/client console.

**Important:** The sample config maps **`police`** to an “LSPD Kitchen” at a fixed coordinate. Change keys, labels, coordinates, and recipes to match your **real** jobs and interiors.

### 5. Locale

`fxmanifest.lua` loads **`locales/tr.lua`**, which sets `Locale = Locales.tr`. To add English (or another language), create e.g. `locales/en.lua`, add it to `shared_scripts`, and set `Locale = Locales.en` (or a convar-driven switch).

### 6. Optional sounds (interact-sound)

If `Config.CookingEffects.interactSound.enabled` is true, add **`chopping.ogg`** and **`frying.ogg`** under your interact-sound resource’s client sound path (see comment in `config.lua`).

### 7. Restart

Restart the server or run:

```text
ensure ugly-cooking
```

Test with a character whose **job** exists in `Config.Shops`, standing at a **kitchen location**, with ingredients in inventory.

---

## How it works (short)

1. Client checks job + kitchen proximity (ox_lib **points** and/or **target**).
2. Opening the menu requests inventory summary via callback **`ugly_cooking:server:GetPlayerInventory`**.
3. Starting a recipe runs validation on the server (**`ugly_cooking:server:ValidateIngredients`**: job, recipe, distance, counts).
4. Client runs prep/cook progress and skillchecks; finishing triggers **`ugly_cooking:server:FinalizeCooking`**, which re-validates, removes ingredients, adds the result item with metadata, and uses a per-player lock against spam.

---

## Troubleshooting

| Issue | What to check |
|--------|----------------|
| “No access” / wrong location | Job key in `Config.Shops` matches `job.name`; player coords inside `locations` + radius. |
| Missing ingredients in UI | Items registered in ox_inventory; names match `ingredients[].item` in config. |
| Target does nothing | `ox_target` (or qtarget) started; `Config.TargetResource` matches your resource; job groups in zone options. |
| Menu does not open | `qb-core` loaded; try `/cook`; if keybind, `Config.OpenKey` must be a real key string, not `'nil'`. |
| Images missing in NUI | Files under `html/img/` and ox_inventory web images as documented in `ITEMS.lua`. |

---

## File map

| Path | Purpose |
|------|---------|
| `config.lua` | Shops, recipes, skillcheck map, effects, appliances |
| `ITEMS.lua` | ox_inventory item templates to merge |
| `client/main.lua` | Proximity, target, menu, commands |
| `client/cooking.lua` | Animations, progress, skillchecks, effects |
| `client/nui.lua` | NUI callbacks |
| `server/main.lua` | Callbacks, validation helpers |
| `server/cooking.lua` | Finalize cooking, metadata, cooldown lock |
| `shared/utils.lua` | Quality, distance, logging |
| `html/` | NUI assets |
| `middleware/v2_settings.js` | Pack middleware (shared) |

---

## License

If the pack includes a separate license file, follow that file. This README is documentation only.

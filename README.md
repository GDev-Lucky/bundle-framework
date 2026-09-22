# Bundle

A strictly typed bundle framework for Roblox and Luau.

Bundle is built around a simple idea: **code dependencies should be explicit, assets should be streamed only when needed, and the framework should stay out of the internals of a bundle.**

It provides:

* Full strict-mode type inference
* Typed cross-bundle APIs
* Automatic code dependency discovery
* Dependency-aware client code loading
* Per-player asset leasing
* Reference-counted asset lifetime
* Delayed unloading
* Recursive dependency asset access
* Server-configured binding assets
* Simple entry lifecycles
* No global service locator or stringly-typed runtime API

---

## Bundles

Each feature lives inside a bundle.

A bundle describes:

* its internal modules
* its public APIs
* its dependencies
* its assets
* optional catalogues used by binding assets

```luau
return framework.bundle({
    modules = {
        util = script.code.util,
        state = script.code.state,
    },

    assets = require(script.assets),

    dependencies = {
        inventory = framework.select(function()
            local inventory = require(path.to.inventory)

            return {
                bundle = inventory,
                server = require(inventory.public.server),
                assets = inventory.assets,
            }
        end),
    },
})
```

Dependencies explicitly choose what they expose to the current bundle.

A bundle does not automatically inherit every API from every dependency.

---

## APIs

Cross-bundle code is accessed through `fetch_api`.

```luau
local inventory = bundle.fetch_api("inventory.server")
local util = bundle.fetch_api("module.util")
```

`fetch_api` is fully typed and non-yielding.

API access happens during the bundle definition/require phase. This lets the framework observe API usage and automatically build the code dependency graph.

Once that phase is complete, new `fetch_api` calls are rejected.

This means code dependencies do not need to be manually duplicated in a second dependency table.

---

## Modules and entries

Modules are explicitly declared:

```luau
modules = {
    util = script.code.util,
    state = script.code.state,
}
```

Code that is not declared as a module is treated as an entry.

An entry is created with `bundle.entry`:

```luau
return bundle.entry(function()
    local inventory = bundle.fetch_api("inventory.client")
    local util = bundle.fetch_api("module.util")

    return {
        function()
            -- init
        end,

        function()
            -- start
        end,

        function()
            -- cleanup
        end,
    }
end)
```

Everything belonging to the entry should live inside its entry closure.

This gives the framework control over the require phase and lets it infer the complete code dependency chain.

---

## Lifecycle

Entries may return lifecycle functions.

The first function is always `init`.

The last function is `cleanup`.

Anything between them runs in order after initialization.

```luau
return {
    init,
    start,
    afterStart,
    cleanup,
}
```

A single returned function is treated as `init`.

Returning nothing means the entry has no lifecycle work.

Initialization happens dependency-first.

Cleanup happens in reverse dependency order.

This makes patterns such as registration straightforward:

```text
item bundle initializes
        ↑
sword bundle registers sword types
        ↑
game starts using those registrations
```

---

## Assets

Assets are separate from code dependencies.

A typical bundle can keep them in an `assets.luau` file:

```luau
return framework.assets({
    inventory = script.Inventory,
    hotbar = script.Hotbar,
    sword = script.Sword,
})
```

Assets do not form their own dependency graph.

They are leased directly when needed.

```luau
local handle = bundle.lease(player, "inventory")
```

A lease keeps that asset alive for the player.

When the final lease is released, the asset becomes eligible for unloading.

---

## Asset access

A bundle may access its own assets as well as assets exposed through its dependency tree.

For example:

```text
inventory
└── item
    └── sword
```

Inventory can reference:

```luau
bundle.fetch_asset("inventory")
bundle.fetch_asset("item.icon")
bundle.fetch_asset("item.sword.model")
```

The dependency path remains part of the asset name, so transitive access stays explicit.

APIs are still selectively exposed by each dependency.

Assets and APIs intentionally follow different visibility rules.

---

## Leasing

Leases are reference counted per player.

```luau
local handle = bundle.lease(player, "inventory")

handle:add(
    bundle.lease(player, "item.sword.model")
)

handle:add(
    bundle.lease(player, "item.sword.vfx")
)
```

Releasing the parent releases its children:

```luau
handle:release()
```

Lease handles use ownership semantics:

* release is idempotent
* a child has one parent
* releasing a parent recursively releases its children
* cyclic handle ownership is invalid

This makes it easy for one feature to own the complete lifetime of everything it temporarily needs.

---

## Delayed unloading

Assets do not need to disappear immediately when their reference count reaches zero.

A bundle can keep recently used assets alive for a short unload window.

This is useful for things like:

* opening and closing inventory quickly
* repeatedly equipping the same weapon
* temporary UI
* short-lived effects

If the asset is leased again before its unload deadline, the pending unload is cancelled.

This avoids unnecessary replication churn.

---

## Client assets

The server owns the authoritative asset lifetime.

When an asset is leased, its live copy is replicated into the player's bundle runtime.

Client code can fetch the replicated instance through the bundle gateway.

Client asset fetches may wait for replication, while server asset access is immediate.

Only one live copy of a normal asset exists for a player at a time.

The framework does not rely on Roblox replication arrival order. Client code starts only after the assets and code required for that activation are ready.

---

## Binding assets

Some assets represent a reusable structure that needs different data each time it is used.

For those, Bundle supports binding assets.

```luau
return framework.binding_asset({
    instance = script.InventorySlot,

    catalogue = {
        sword = {
            icon = "rbxassetid://...",
            name = "Sword",
        },

        bow = {
            icon = "rbxassetid://...",
            name = "Bow",
        },
    },

    bind = function(instance, choice)
        instance.Icon.Image = choice.icon
        instance.Label.Text = choice.name
    end,
})
```

The binding callback runs on the server before the asset is exposed to the player.

Most configuration then replicates normally through Roblox.

Binding assets are useful for things such as:

* inventory slots
* weapon models
* item displays
* UI templates
* world markers

Large reusable structures stay as assets, while lightweight data such as IDs, names, icons, colors, and animation references can stay in catalogues.

---

## Example

A larger project might look like this:

```text
bundles/
├── item/
│   ├── bundle.luau
│   ├── assets.luau
│   ├── public/
│   └── code/
│
├── sword/
│   ├── bundle.luau
│   ├── assets.luau
│   ├── public/
│   └── code/
│
└── inventory/
    ├── bundle.luau
    ├── assets.luau
    ├── public/
    └── code/
```

`item` can provide a common item API.

`sword` depends on `item` and registers its sword types during initialization.

`inventory` only needs to understand items, while still being able to lease assets exposed further down the dependency tree when necessary.

```text
inventory
    ↓
item
    ↑
sword
```

This keeps feature code decoupled without forcing every asset lifetime through the bundle that originally declared it.

---

## Philosophy

Bundle deliberately does not try to control what happens inside a feature.

The framework is responsible for:

* dependency boundaries
* loading order
* type-safe API access
* code replication
* asset replication
* asset lifetime

The bundle itself is responsible for using those tools correctly.

Invalid dependency usage should fail loudly during development rather than being hidden behind defensive runtime behavior.

The goal is to keep the framework predictable while leaving normal Luau code feeling like normal Luau code.

---

## Design goals

Bundle is designed around a few rules:

**Static where possible.**
Dependency names and API return types should be known to Luau.

**Explicit boundaries.**
Bundles choose exactly what they consume from another bundle.

**Automatic relationships.**
If code imports another API, the framework should be able to infer that dependency instead of making the developer declare it twice.

**One owner for lifetime.**
A feature should be able to lease everything it needs and release it through one handle.

**Server authority.**
The server controls what assets a player should currently have.

**Fail early.**
Invalid bundle architecture should become an obvious development error.

---

## License

See [LICENSE](LICENSE).

# Safe Together (Build 42)

Own your **own** safehouse and, at the same time, be a **guest** in your friends'
safehouses. The mod replaces the "one safehouse per player" limitation with a
list of every safehouse where you are the owner **or** an invited member, so
friends can enter, build, repair and look after each other's bases — even while
the owner is offline.

## What it does

- Each player may own **at most one** safehouse (owning one is optional).
- The owner can **invite** other players as guests. Only invited players can
  enter; without an invitation, nothing changes from vanilla.
- A player can be a guest in **any number** of safehouses at once.
- The user-panel **Safehouse** button opens a list of all your safehouses
  (owned + guest). Selecting one opens the normal safehouse window.
- If you become a guest before claiming your own base, a context-menu option
  ("Claim your own safehouse") lets you still create it.

## Why Build 42 needed a rewrite

In Build 42 safehouses became **server-authoritative**. The "one safehouse per
player" rule is enforced in the Java packet handlers
(`SafehouseInvitePacket` / `SafehouseAcceptPacket`), which a client-only Lua mod
cannot override, and the old `SafeHouse:syncSafehouse()` API was removed.

This mod therefore drives membership changes through its own client↔server
command protocol. The **server-side** Lua calls the (unrestricted, Lua-exposed)
`SafeHouse:addPlayer()` / `SafeHouse.addSafeHouse()` methods directly, then
mirrors the change to connected clients. Membership is persisted by the engine
(`SafeHouse.save`) and re-sent to every client on login via `MetaDataPacket`, so
it survives restarts and reconnects. Physical access (trespass, looting) is
enforced by the server from the member list, so guests keep access while the
owner is away.

## Structure (Build 42 layout)

```
Contents/mods/safetogether/
└── 42/
    ├── mod.info
    ├── safetogether.png
    └── media/lua/
        ├── shared/
        │   ├── SafeTogether_Shared.lua        -- namespace + helpers
        │   └── Translate/{EN,ES,AR}/*.json    -- Build 42 JSON translations
        ├── server/
        │   └── SafeTogether_Server.lua         -- OnClientCommand handlers (authoritative)
        └── client/
            ├── SafeTogether_Client.lua         -- invite dialog, sync mirror, panel + claim hooks
            └── ISUI/UserPanel/
                ├── ISSafeTogetherhousesList.lua -- the safehouse list
                └── SafeTogether_AddPlayerHook.lua -- invite-anyone patch
```

The vanilla `ISSafehouseUI` window is reused as-is; the mod only patches the
specific methods it needs, instead of replacing whole base-game files.

## Install (multiplayer)

The mod must be enabled on the **server** as well as the clients (membership
changes and access checks run server-side). Add its id to the server `Mods=`
line and to each client's mod list.

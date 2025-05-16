# Safehouse Together

This mod is intended to allow people to have multiple safe zones. They can be the owners of their own shelters, but at the same time, be invited by their friends, and be part of their friends' shelter as well. That way, you can help them to build, repair or even take care of their houses, in case they are not connected.

It also allows you to claim plots or land without having to have a building on them. Simply obtain the item set by the server and head to the central point, where you can claim the land. The limit is also set by the server.

![Image](https://github.com/user-attachments/assets/9ad97e6c-a341-45fa-a366-7be8ca05f144)

![Image](https://github.com/user-attachments/assets/5fc40e3f-ad60-4ac1-b1af-2fba3b640ddf)

![Image](https://github.com/user-attachments/assets/a7e20c1b-3da6-427c-aeb7-ebe6e0bda314)

```lua
local function setSafehouseData(title, owner, x, y, w, h)
```
<details>
<summary>setSafehouseData</summary>
--- Creates and configures a new safehouse in the world.
--- This function performs the following steps:
--- 1. Generates a random name for an initial "false" owner.
--- 2. Creates a safehouse object at the specified coordinates and dimensions.
--- 3. Sets the title of the safehouse.
--- 4. Enables respawning inside the safehouse for the real owner.
--- 5. Assigns the real owner to the safehouse.
--- 6. Removes the "false" owner from accessing the safehouse.
--- 7. Updates the safehouse information.
--- 8. Synchronizes the safehouse data with the clients.
--- @param title string The title of the safehouse.
--- @param owner Player The player object that will be the owner of the safehouse.
--- @param x number The X coordinate of the safehouse.
--- @param y number The Y coordinate of the safehouse.
--- @param w number The width of the safehouse area.
--- @param h number The height of the safehouse area.
</details>

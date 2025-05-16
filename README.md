# Safehouse Together

This mod is intended to allow people to have multiple safe zones. They can be the owners of their own shelters, but at the same time, be invited by their friends, and be part of their friends' shelter as well. That way, you can help them to build, repair or even take care of their houses, in case they are not connected.

It also allows you to claim plots or land without having to have a building on them. Simply obtain the item set by the server and head to the central point, where you can claim the land. The limit is also set by the server.

![Image](https://github.com/user-attachments/assets/9ad97e6c-a341-45fa-a366-7be8ca05f144)

![Image](https://github.com/user-attachments/assets/5fc40e3f-ad60-4ac1-b1af-2fba3b640ddf)

![Image](https://github.com/user-attachments/assets/a7e20c1b-3da6-427c-aeb7-ebe6e0bda314)

```lua
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
local function setSafehouseData(title, owner, x, y, w, h)
```

```lua
--- Allows the current player to claim an area to create a new safehouse.

--- This function performs the following steps:
--- 1. Retrieves the player object attempting to claim the land.
--- 2. Counts the number of safehouses the player already owns.
--- 3. Checks if land claiming is globally enabled.
--- 4. Verifies if the player has not exceeded the allowed limit of safehouses.
--- 5. Defines a 31x31 unit square area centered on the player's position.
--- 6. Calculates the exact coordinates and dimensions of the area to be claimed.
--- 7. Calls `setSafehouseData` to create the new safehouse with the player as the owner.
--- 8. Removes the necessary item and quantity from the player's inventory for the claim.
--- 9. Informs the player if land claiming is not enabled or if they have exceeded the safehouse limit.

--- @usage Safetogether.ClaimLand()
local Safetogether.ClaimLand = function()
```

```lua
--- Modifies the context menu that appears when interacting with world objects to allow claiming land.

--- This function is triggered when filling the context menu of a world object and performs the following actions:
--- 1. Exits the function if the current game mode is 'LastStand'.
--- 2. Retrieves the specific player object interacting.
--- 3. Initializes a `canClaim` variable to `false`.
--- 4. Exits the function if the player is inside a vehicle.
--- 5. Gets the quantity of the item needed to claim land from the player's inventory.
--- 6. Sets a global variable `Safetogether.canClaimLand` to `true` initially.
--- 7. Iterates through the list of existing safehouses:
---    - If the player is the owner of a safehouse and the `NotClaimEvenIfYouHaveHouse` setting is true, sets `Safetogether.canClaimLand` to `false` and breaks the loop.
---    - If the player is a guest in any safehouse and the `NotClaimIfYouAreGuest` setting is true, sets `Safetogether.canClaimLand` to `false` and breaks the inner loop.
--- 8. Defines a `restrictedLand` table with specific coordinates where claiming land is not allowed.
--- 9. Iterates through the restricted coordinates:
---    - If the player's current position matches any restricted coordinate, sets `canClaim` to `true` (this seems like inverted logic; it should be `false` to restrict).
--- 10. Gets the world grid square at the player's position.
--- 11. If the grid square exists and already contains a safehouse, sets `canClaim` to `false`.
--- 12. If the player has the required amount of the claiming item and the `canClaim` variable is `true`, adds an option to the context menu for "Claiming Land" that calls the `Safetogether.ClaimLand` function when selected.

--- @param player number The ID of the interacting player.
--- @param context UIContextMenu The context menu object being filled.
--- @param worldobjects table A table of world objects being interacted with (although this code doesn't seem to use it directly).
--- @param test boolean A test boolean value (doesn't seem to be used in this code).
Safetogether.OnFillWorldObjectContextMenu = function(player, context, worldobjects, test)
```

```lua
--- Removes a specific amount of an item from a player's inventory.

--- This function searches the player's inventory for the specified item and reduces its count.
--- If the item's count reaches zero or less after the reduction, the item is removed from the inventory.

--- @param item string The full type of the item to remove (getFullType).
--- @param amount number The amount of the item to remove.
--- @param player Player The player object from whose inventory to remove the item.
local function removeItem(item, amount, player)
```

```lua
--- Gets the total amount of a specific item in a player's inventory.

--- This function iterates through all the items in the player's inventory
--- and sums the count of those whose full type (getFullType) matches the
--- specified item.

--- @param player Player The player object whose inventory will be checked.
--- @param item string The full type of the item for which to get the count.
--- @return number The total amount of the specified item in the player's inventory.
local function getItems(player, item)
```

```lua
--- Gets the number of safehouses that a player owns.

--- This function iterates through the list of all existing safehouses
--- and counts those for which the specified player is the owner.

--- @param player Player The player object for whom to count their safehouses.
--- @return number The number of safehouses owned by the player.
local function getCountSafePerPlayer(player)
```

```lua
--- Gets the number of safehouses that a player owns, searching by their username.

--- This function iterates through the list of all existing safehouses
--- and counts those whose owner (obtained by their username) matches the
--- specified player name.

--- @param playerName string The username of the player for whom to count their safehouses.
--- @return number The number of safehouses owned by the player with that name.
local function getCountSafePerPlayerName(playerName)
```

```lua
--- Generates a random string containing mixed-case letters.

--- This function creates a string of the specified length by randomly selecting
--- characters from a set that includes all letters of the alphabet in both
--- uppercase and lowercase.

--- @param numberOfCharacters number The desired length of the random string.
--- @return string The generated random string.
local function generateMixedRandomName(numberOfCharacters)
```

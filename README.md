# Transformify
A roblox plugin that allows you to change classes of already created instances.

_Disclaimer: This repository only includes script files. Releases include also include any additional instances such as UI._

## Installation

You can either download the plugin from [Roblox]() or our [GitHub Releases](https://github.com/StinkUniverse69/Transformify/releases).

## Permissions

#### HttpPermission for "https://raw.githubusercontent.com/"
Roblox does not allow plugin developers to access reflection classes easily, that is what classes have what Properties and such. This is why _Transformify_ uses the [Roblox Client Tracker]() to get this information. It does this by reading [Roblox-Client-Tracker/roblox/Mini-API-Dump.json](https://raw.githubusercontent.com/MaximumADHD/Roblox-Client-Tracker/roblox/Mini-API-Dump.json)

An API dump is also included, so you can disable this permission with minimal effect. But will not be updated as frequently as the Roblox Client Tracker.

---
 
#### HttpPermission for "https://assetdelivery.roproxy.com/"
This will become necessary if you want to change a MeshParts MeshId by using an AssetId. Roblox only allows inserting Models using  that the owner of the place has in their inventory. 

#### HttpPermission for "https://inventory.roproxy.com/"


## Useage
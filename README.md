<img align="right" width="250" src="https://assetdelivery.roblox.com/v1/asset/?id=83506458688166" alt="Transformify logo" />

# Transformify
A roblox plugin that allows you to change classes of already created instances.

_Disclaimer: This repository only includes script files. Releases include also include any additional instances such as UI._

## Installation

You can either download the plugin from [Roblox]() or our [GitHub Releases](https://github.com/StinkUniverse69/Transformify/releases).

## Useage

Simply select the instances you want to transform and then press the Transformify (Instance Converter) Button in the Plugins tab.



## Permissions

#### Http Permission "https://raw.githubusercontent.com/"
Roblox does not allow plugin developers to access reflection classes easily, that is what classes have what Properties and such. This is why _Transformify_ uses the [Roblox Client Tracker](https://github.com/MaximumADHD/Roblox-Client-Tracker) to get this information. It does this by reading [Roblox-Client-Tracker/roblox/Mini-API-Dump.json](https://raw.githubusercontent.com/MaximumADHD/Roblox-Client-Tracker/roblox/Mini-API-Dump.json)

An API dump is also included, so you can disable this permission with minimal effect. But will not be updated as frequently as the Roblox Client Tracker.

---

#### Http Permission "https://inventory.roproxy.com/"

This is only required if you want _Transformify_ to suggest MeshParts and Models you've uploaded when transforming a MeshPart into another. Alternatively you can also just open the toolbox and copy a mesh/asset id manually.

Note: You need to have your inventory set to publicly visible for this to work.

---

#### Http Permission "https://assetdelivery.roproxy.com/"
Can be used instead of game:GetObjects() to retrive mesh ids from Models but isn't in use as long as it exists.

---

#### Script Injection Permission
Is be required if you transform a Script or Localscript. May be also if you transform something that has a script in it.
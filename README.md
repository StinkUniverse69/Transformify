<img align="right" width="150" src="icon.png" alt="Transformify logo" />

<h1 align="center">Transformify</h1>

A roblox plugin that allows you to change classes of already created instances.

_Disclaimer: This repository only includes script files. Releases include also include any additional instances such as UI._

## Installation

You can either download the plugin from [Roblox]() or our [GitHub Releases](https://github.com/StinkUniverse69/Transformify/releases).

## Useage

Simply select the instances you want to transform and then press the _Transformify (Instance Converter)_ Button in the Plugins tab.

## Features

**Convert any Instance into any other**

- blazingly fast conversion even on large instance volumes
- any properties that can, will be automatically transfered
- also transfers tags and attributes 
- uses ChangeHistoryService to make conversions reversable
- will not change the order of ui elements
- errors are caught and safely handled, as much as possible of the conversion will still be performed


### Special Cases
Not all instances are automatically be converted into any other as expected, due to the way Roblox is written.

For this reason _Transformify_ implements a variety of addons (called special operations) to cover these cases.

#### MeshPart to MeshPart
Normally when setting a _MeshId_ the _MeshPart.Size_ will be reset. So _Transformify_ allows you to convert a _MeshPart_ into another, which will open a new window where you can either input a _MeshId_, an _AssetId_ or select a MeshPart/Model from your inventory directly.

#### Part to MeshPart
Sets the correct _MeshId_ depending on the _ShapeType_ or if there is a _SpecialMesh_ parented to it and corrects the _Size_ among other things. Also inserts a _SurfaceAppearance_ if needed.

#### MeshPart to Part
Tries to guess the _ShapeType_ of the Mesh, if it fails a _SpecialMesh_ is parented. Also takes _SurfaceAppearances_ into account.

#### Decal to Texture
Sets the _StudsPerTileU_ and _StudsPerTileV_ so that it looks the same before.

#### Attachment to Part/MeshPart
Corrects the _CFrame_ to the _Attachment.WorldCFrame_ and welds it to the parent.

#### Part/MeshPart to Attachment
Sets the _WorldCFrame_ to the Part's.

#### Decal to MeshPart
Calculates the correct angles for any **Brick Part** and adds _MeshPart_ plains with the decal as surface appearance using the _AlphaMode:Transparency_

More of a demo on what can be done using this system.

#### LocalScript to Script
Sets the _RunContext_ to Client

#### Decal/Texture to SurfaceAppearance
Sets the _ColorMap_ to the _Texture_ of the previous.

#### Something missing?
Feel free to suggest additional special operations.

## Permissions

#### Http Permission "https://raw.githubusercontent.com/"
Roblox does not allow plugin developers to access reflection classes easily, that is what classes have what Properties and such. This is why _Transformify_ uses the [Roblox Client Tracker](https://github.com/MaximumADHD/Roblox-Client-Tracker) to get this information. It does this by reading [Roblox-Client-Tracker/roblox/Mini-API-Dump.json](https://raw.githubusercontent.com/MaximumADHD/Roblox-Client-Tracker/roblox/Mini-API-Dump.json)

An API dump is also included, so you can disable this permission with minimal effect. But it will not be updated as frequently as the Roblox Client Tracker, so you wouldn't always have the newest available classes.

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
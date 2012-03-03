s2b - Schematic to bo2 coverter
====================
This ruby script converts minecraft *.schematic files into *.bo2 files which is highly usable when creating custom trees for the plugin [TerrainControl](http://dev.bukkit.org/server-mods/terrain-control/). You build your custom tree ingame, select it and export it with [WorldEdit](http://dev.bukkit.org/server-mods/worldedit/).

Usage
---------
1. download the file s2b.rb from this repository.
1. [install ruby](http://www.ruby-lang.org/en/downloads/)
1. [install the nbtfile gem](http://rubygems.org/gems/nbtfile)
1. run s2b.rb once. This will create the folders "in" and "out" next to s2b.rb
1. place all *.schematics files in that folder named "in".
1. run s2b.rb.
1. The "out" folder now contains all new .bo2 files

Special behavior and Suggested workflow
---------
This script have some special behaviors:

 * Air blocks are not exported - Because in general you want the bo2 to to be transparent. Use the BBOB application to add in air blocks afterwards.
 * Magenta wool is not exported - Use magenta wool for cuboid min and max points. Since these will be in the WorldEdit selection it is handy if they are not exported.
 * Dark blue wool is not exported - We use this to stop wines from growing to long.
 * If the name of the .schematic file ends with R5 (as in Root-depth 5) a z-offset of 5 will be used. The numer can ofcource be any number and is not limited to 5.

This is how we do it on MassiveCraft:
Create a creative world on your server using a multiworld plugin such as [MultiVerse-Core](http://dev.bukkit.org/server-mods/multiverse-core/). You may also want to keep separate inventories for that world using a plugin such as [MultiVerse-Inventories](http://dev.bukkit.org/server-mods/multiverse-inventories/). To make that world be a nice huge grass field you will want to use a custom world generator for it. We suggest<br> [CleanroomGenerator](http://dev.bukkit.org/server-mods/cleanroomgenerator/):1,bedrock,30,dirt,1,grass

Now you can let people build custom trees there. The players place a sign with the name of the custom tree on top of the WorldEdit maxpoint. The name should end with something like R5 to make use of the z-offset feature.

We use a plugin called WorldEditSignSave. It will save the current WorldEdit clipboard using the name of the sign you are currently looking at. We will release this plugin when we get time.
# Nuts And Bolts
## Overview
This is a replication of the game commonly known as "water sort" or "nuts and bolts", written completely in x64 NASM assembly for Linux. Its main goal is to sort the "nuts" in different colors by moving them between bolts, while the player is prohibited from stacking a "nut" on top of another one with a different color.
## Platforms and Dependencies
The program is written x64 NASM assembly and depends on the **GNU C Library** and is a C program under the hood. It is not written as a position independent executable. Hence, the flag -no-pie is required for the linker. Porting to any Linux distributions is theoretically possible without any source changes.
## How to Play
The program accepts one command line argument containing a path to a text file. The level coded into the text file will be loaded before you can start playing. You can write levels using this level notation: each line represent a bolt (empty lines are ignored), and each letter represents a nut with a specific color. The following colors are supported: 

| Letter | Color   | RGB           |
|--------|---------|---------------|
| R      | Red     | 255, 0, 0     |
| G      | Green   | 0, 255, 0     |
| B      | Blue    | 0, 0, 255     |
| Y      | Yellow  | 255, 255, 0   |
| M      | Magenta | 255, 0, 255   |
| C      | Cyan    | 0, 255, 255   |
| W      | White   | 255, 255, 255 |
| O      | Orange  | 255, 85, 0    |
| L      | Lime    | 178, 255, 102 |

After the game starts, use 'd' and 'f' keys to move your cursor (represented by '<' or '>') up and down. Use 'j' to select bolt and 'k' to clear selection. After selecting a bolt, press 'j' again on another bolt to conduct a move operation. Moving from a bolt to itself will not take any effect.
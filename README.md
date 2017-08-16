# Roll20 Macro Generator

This scripts fetches an url from the [D&D Wiki](http://www.dandwiki.com/wiki/SRD:Spells) (great site btw) and converts the information there to a roll20-macro. There are some TODO's left but its already pretty good for most spells. Macros are based on the [D&D 3.5 StdRoll Template](https://wiki.roll20.net/Dungeons_and_Dragons_3.5#StdRoll_Template)

## TODO

- [ ] convert dice-rolls and level dependent stuff to auto-calulated values
- [ ] change the notes from the summary to the (shortened) description
- [ ] decide how to handle the clerics "domains"
- [ ] compare the wiki information with the Player's Handbook

## Spell-Status

* Sorcerer: 99% spells, some checked
* Cleric: few basic spells, unchecked
* Ranger: complete, unchecked

## Helpfull scripts

* rake readable['Sor/0-*']
* rake minify['Sor/0-*']
* rake autoconvert['Sor/0-*']

The validation process is something like this:

rake readable
git commit (for better comparison of the changes)
rake autoconvert
loop do
  rake readable
  edit
  rake minify
  C&P into Testgame in roll20
  Test/Modify macro
  [C&P back into editor]
end
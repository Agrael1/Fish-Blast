# fish blast

bullet hell game for class

## the idea

- looks like a bullet hell at first glance
- lots of flying objects and your character can move around and dodge them
- scrolling background so it looks like you’re moving quickly
- flying items are one of three types
  - fish sprites
  - junk
  - treasures
- you can left click to shoot a fishing line towards your mouse, it’s very fast
  and basically hitscan gun
- whatever you hit you reel in, this part is not as fast. while reeling in you
  can move your mouse to sort of swing the thing on your line around a bit,
  relates to the next point:
- right click to shoot out a slower line with a fishing bobber on it. this one
  doesn’t reel stuff in, instead it knocks it away. can be comboed with left click
  to grab + aim + launch away.
- get points when you reel in fish, less points for junk, and huge points when
  fish get knocked into other fish (they explode into coins or something)
- bottom left of the screen is three squares (could be reduced to 2 or even 1
  for smaller scope), these are your upgrades. whenever you get a treasure, game
  slows down and a popup appears telling you it’s name and effect, with two options:
  equip, or sell. sell to get a bunch of points or equip will then have another
  choice of which slot to put it in (replaces stuff you previously had equipped).
  as game continues the buffs offered by the treasures gets bigger.
- goal is just to get the biggest high score

### potential problems

- may need more of a feedback loop with points / coins. something to spend them
  on which gets more expensive as the game continues?
- losing coins when you get hit seems like not a big enough issue. maybe a separate
  health bar and some additional health items in the flow could be good
  - maybe losing a _lot_ of coins when you get hit could solve this bullet and
    the previous bullet? maybe a percentage of your total coins?

### additional notes about overall style / effects

- screenshake, hitstop, and white flash effects are very important
- hitboxes are bigger and game is more forgiving than touhou
- if your character gets hit you just drop coins like sonic and your score goes
  down, and get some iframes. any move you were doing gets cancelled.
- the original idea for the game is that every single combination of treasures in
  the slots would result in a unique fishing rod with different hook/bobber and an
  ability. but that seems way too big scope, so maybe just number buffs is a better
  idea.

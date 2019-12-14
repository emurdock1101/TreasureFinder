/* 
Elliot Murdock
ecm5tx
*/
/* Allow asserts and retracts for the predicate at */
:- dynamic at/2.
:- dynamic hasKey/2.

/*
  Descriptions of all the places in 
  the game.
*/
description(valley,
  'You are in a pleasant valley, with a trail ahead.').
description(path,
  'You are on a path, with ravines on both sides.').
description(cliff,
  'You are teetering on the edge of a cliff.').
description(fork,
  'You are at a fork in the path.').
description(maze(_),
  'You are in a maze of twisty trails, all alike.').
description(mountaintop,
  'You are on the mountaintop.').
description(gate,
  'You are at a gate. It needs to be unlocked with a key before being entered.').
description(gate2,
  'You are at a gate. It is now unlocked').

/* specifies what items you have. Implemented only for key */
items:-
    at(you, Loc),
    hasKey(you, Loc),
    write('one key. ').

items:-
    write('zero items. ').  

/*
  report prints the description of your current
  location.
*/
report :-
  at(you,X),
  write('You are holding '),
  items,
  description(X,Y),
  write(Y), nl.

/*
  Direction "back" allows the player to retrace to the previous for certain areas
*/
connect(path,back,valley).
connect(fork,back,path).
connect(gate,back,fork).

/*
  These connect predicates establish the map.
  The meaning of connect(X,Dir,Y) is that if you
  are at X and you move in direction Dir, you
  get to Y.  Recognized directions are
  forward, right, and left.
*/
connect(valley,forward,path).
connect(path,right,cliff).
connect(path,left,cliff).
connect(path,forward,fork).
connect(fork,left,maze(0)).
connect(fork,right,gate).
connect(gate2,forward,mountaintop).
connect(maze(0),left,maze(1)).
connect(maze(0),right,maze(3)).
connect(maze(1),left,maze(0)).
connect(maze(1),right,maze(2)).
connect(maze(2),left,fork).
connect(maze(2),right,maze(0)).
connect(maze(3),left,maze(0)).
connect(maze(3),right,maze(3)).

/* shortcuts for move */
move(f) :- move(forward).
move(b) :- move(back).
move(l) :- move(left).
move(r) :- move(right).
move(u) :- move(unlock).
move(p) :- move(pickup).
move(s) :- move(setdown).

/* specific check for the case when you are moving through the gate */
move(forward) :-
  at(you,gate2),
  hasKey(you, gate2),
  write('You try walking through the gate still holding the\n'),
  write('key and you are struck by lightning and killed.\n'),
  retract(at(you,gate2)),
  assert(at(you,done)),
  !.

/*
  move(Dir) moves you in direction Dir, then
  prints the description of your new location.
*/
move(Dir) :-
  at(you,Loc),
  connect(Loc,Dir,Next),
  write('--'),write(Dir),write('--d---'),
  retract(at(you,Loc)),
  assert(at(you,Next)),
  report,
  !.

/* specific rules for picking up objects (only keys implemented) */
move(pickup) :-
  at(you,Loc),
  key(Loc),
  report,
  !.

/* specific rules for setting down all items (only keys implemented) */
move(setdown) :-
  at(you,Loc),
  hasKey(you, Loc),
  retract(hasKey(you, _)),
  assert(hasKey(you, default)),
  retract(at(key,_)),
  assert(at(key,Loc)),
  write('You set down all your items. '),
  report,
  !.

/* specific rules for unlocking the gate */
move(unlock) :-
  at(you,gate),
  hasKey(you, gate),
  write('--'),write(unlock),write('-----\n'),
  write('You unlocked the gate!\n\n'),
  retract(at(you,gate)),
  assert(at(you,gate2)),
  report,
  !.

/*
  But if the argument was not a legal direction,
  print an error message and don't move.
*/
move(_) :-
  write('That is not a legal move here.\n'),
  report.

/*
  Shorthand for moves, mostly used for troubleshooting.
*/
forward :- move(forward).
back :- move(back).
left :- move(left).
right :- move(right).
unlock :- move(unlock).
pickup :- move(pickup).
setdown :- move(setdown).
f :- move(forward).
b :- move(back).
l :- move(left).
r :- move(right).
u :- move(unlock).
p :- move(pickup).
s :- move(setdown).

/*
  If you and the ogre are at the same place, it 
  kills you.
*/
ogre :-
  at(ogre,Loc),
  at(you,Loc),
  write('An ogre sucks your brain out through\n'),
  write('your eye sockets, and you die.\n'),
  retract(at(you,Loc)),
  assert(at(you,done)),
  !.

/*
  But if you and the ogre are not in the same place,
  nothing happens.
*/
ogre.

/*
  If you and the treasure are at the same place, you
  win.
*/
treasure :-
  at(treasure,Loc),
  at(you,Loc),
  write('There is a treasure here.\n'),
  write('Congratulations, you win!\n'),
  retract(at(you,Loc)),
  assert(at(you,done)),
  !.

/*
  But if you and the treasure are not in the same
  place, nothing happens.
*/
treasure.

/* Called by the pickup() atom, keeps track of when a key has been picked up */
key(Loc) :-
  at(key,Loc),
  at(you,Loc),
  retract(hasKey(you, default)),
  assert(hasKey(you, _)),
  write('There is a key here. You pick it up.\n'),
  !.

/* Called by the pickup() atom if there is no key at the location */
key(_) :-
  write('There is nothing here to pick up. \n'),
  !.  

/* default value for having no key */
hasKey(you, default).

/*
  If you are at the cliff, you fall off and die.
*/
cliff :-
  at(you,cliff),
  write('You fall off and die.\n'),
  retract(at(you,cliff)),
  assert(at(you,done)),
  !.

/*
  But if you are not at the cliff nothing happens.
*/
cliff.

/*
  Main loop.  Stop if player won or lost.
*/
main :- 
  at(you,done),
  write('Thanks for playing.\n'),
  !.

/*
  Main loop.  Not done, so get a move from the user
  and make it.  Then run all our special behaviors.  
  Then repeat.
*/
main :-
  write('\nNext move -- '),
  read(Move),
  call(move(Move)),
  ogre,
  treasure,
  cliff,
  main.

/*
  This is the starting point for the game.  We
  assert the initial conditions, print an initial
  report, then start the main loop.
*/
go :-
  retractall(at(_,_)), % clean up from previous runs
  assert(at(you,valley)),
  assert(at(ogre,maze(3))),
  assert(at(key,maze(2))),
  assert(at(treasure,mountaintop)),
  write('This is an adventure game. \n'),
  write('Legal moves are (l)eft, (r)ight, (f)orward, (b)ack, (u)nlock, (p)ickup or (s)etdown. \n'),
  report,
  main.


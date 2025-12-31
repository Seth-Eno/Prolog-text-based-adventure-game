/* Lost in the Mountains by Seth Eno */

/* Initialize "variables" */
:- dynamic i_am_at/1, at/2, holding/1, hoursRemaining/1, shack_unlocked/0, blast0/0, blast1/0, blast2/0, openCave/0.

/* Define valid paths */
path(basin, n, waterfall).
path(basin, e, easternPeak).
path(basin, s, saddle).
path(basin, w, westernPeak).

path(waterfall, s, basin).
path(easternPeak, w, basin).
path(saddle, n, basin).
path(westernPeak, e, basin).

path(saddle, e, easternPeak).
path(easternPeak, s, saddle).
path(saddle, w, westernPeak).
path(westernPeak, s, saddle).

path(shack, w, easternPeak).

path(easternPeak, e, shack) :-
    shack_unlocked.

path(easternPeak, e, shack) :-
    \+ shack_unlocked,
    write("The shack seems to be locked. "),
    fail.

path(cave, e, westernPeak).

path(westernPeak, w, cave) :-
    write("You found shelter and were rescued before you froze!"),
    die.

path(westernPeak, w, cave) :-
    \+ openCave,
    write("The cave is blocked. "),
    fail.

/* These rules describe how to pick up an object. */

take(X) :-
        holding(X),
        write('You\'re already holding it!'),
        !, nl.

take(X) :-
        i_am_at(Place),
        at(X, Place),
        assert(holding(X)),
        write('I wonder where I can use this...'),
        !, nl.

take(_) :-
        write('I don\'t see it here.'),
        nl.

/* This rule describes how to view inventory. */
i :-
    holding(shell) ->
        (write("shell"), nl)
    ;
    holding(key) ->
        (write("key"), nl)
    ;
    write("You aren\'t holding anything!").

/* These rules describe how to use the key and shells. */

use_item(X) :-
    \+ holding(X),
    write('You aren\'t holding'), write(X),
    nl.

use_item(X) :-
        holding(X),
        i_am_at(easternPeak),
        (X = key ->
            assert(shack_unlocked),
            write('It\'s hard with your numb hands, but eventually you unlock the shack.'), nl,
            retract(holding(key))
        ;
        X = shell ->
        (
        blast2 ->
            (assert(openCave),
            write("BOOM"), nl,
            write("The boulders crumble away revealing the entrance to a cave"), nl,
            retract(holding(shell)))
        ;
        blast1 ->
            (assert(blast2),
            write("BOOM"), nl,
            write("The boulders look very weak"), nl,
            retract(holding(shell))) 
        ;
        blast0 ->
            (assert(blast1),
            write("BOOM"), nl,
            write("The boulders look weakened"), nl,
            retract(holding(shell)))
        )
        ;
        write("You cannot use "), write(X), write(" here")
        ),
        !, nl.


/* These rules define the direction letters as calls to go/1. */

n :- go(n).

s :- go(s).

e :- go(e).

w :- go(w).


/* This rule tells how to move in a given direction. */

go(Direction) :-
    i_am_at(Here),
    path(Here, Direction, There),
    retract(i_am_at(Here)),
    assert(i_am_at(There)),
    !,

/* This conditional exists so you can move freely between the shack and firing platform */
    (
        ((Here = shack, There = easternPeak) ; (Here = easternPeak, There = shack) ; (Here = westernPeak, There = cave))
    ->  look, !
    ;
    /* Otherwise decrement the freeze counter. */
        retract(hoursRemaining(H)),
        H1 is H - 1,
        assert(hoursRemaining(H1)),
        (H1 =< 0 ->
            write('You have frozen!'),
            die()
        ; 
            write('You have '), write(H1),
            write(' hours before you freeze.'), nl,
            look,
            !
        )
    ).

go(_) :-
        write('You can\'t go that way.').


/* This rule tells how to look about you. */

look :-
        i_am_at(Place),
        describe(Place),
        nl,
        notice_objects_at(Place),
        nl.


/* These rules set up a loop to mention all the objects
   in your vicinity. */

notice_objects_at(Place) :-
        at(X, Place),
        write('There is a '), write(X), write(' here.'), nl,
        fail.

notice_objects_at(_).


/* This rule tells how to die. */

die :-
        finish.

/* Under UNIX, the "halt." command quits Prolog but does not
   remove the output window. On a PC, however, the window
   disappears before the final output can be seen. Hence this
   routine requests the user to perform the final "halt." */

finish :-
        nl,
        write('The game is over. Please enter the "halt." command.'),
        nl.


/* This rule writes out game instructions. */

instructions :-
        nl,
        write('Enter commands using standard Prolog syntax.'), nl,
        write('Available commands are:'), nl,
        write('start.             -- to start the game.'), nl,
        write('n.  s.  e.  w.     -- to go in that direction.'), nl,
        write('i.     -- to see your inventory.'), nl,
        write('take(Object).      -- to pick up an object.'), nl,
        write('use_item(Object).      -- to use an object.'), nl,
        write('look.              -- to look around you again.'), nl,
        write('instructions.      -- to see this message again.'), nl,
        write('halt.              -- to end the game and quit.'), nl,
        nl.


/* This rule resets the game state, sets initial variables, prints out instructions, and tells where you are. */

start :-

/* Reset game state */
    retractall(i_am_at(_)),
    retractall(at(_, _)),
    retractall(holding(_)),
    retractall(hoursRemaining(_)),
    retractall(shack_unlocked),
    retractall(blast0),
    retractall(blast1),
    retractall(blast2),
    retractall(openCave),

/* Set up initial "variables" */
    assert(hoursRemaining(12)),
    assert(i_am_at(basin)),
    assert(at(key, waterfall)),
    assert(at(shell, shack)),
    assert(blast0),

/* Write instructions and describe location and objective */
    instructions,
    write("You got lost on your hike and need to find shelter before you freeze."),
    nl,
    nl,
    look,
    write("You have 12 hours before you freeze."),
    nl,
    !.

/* These rules describe the various rooms.  Depending on
   circumstances, a room may have more than one description. */

describe(basin) :-
    write('You are standing in snow up to your waist at the basin of two peaks.'), nl,
    write('The peaks are to the east and west of you.'), nl,
    write('The saddle between the peaks is to the south.'), nl,
    write('A small creek gurgles beneath the snow heading north.'), nl.

describe(waterfall) :-
    write('You come to a frozen waterfall.'), nl,
    write('The basin is up to your south.'), nl,
    write('Something glints in the ice.'), nl,
    write('What\'s that? How did someone lose that here!?!?'), nl.

describe(saddle) :-
    write('You are standing in the saddle between the eastern and western peaks.'), nl,
    write('The wind whips past you, chilling you to the bone. You get a great view though!'), nl,
    write('You see a building on the eastern peak.'), nl,
    write('You see a rockslide on the side of the western peak.'), nl,
    write('The valley snakes it\'s way between the peaks to your north.'), nl.

describe(easternPeak) :- 
    write('you are on the side of the eastern peak, standing on a firing platform below a small storage shack.'), nl,
    write('There is an artillery cannon here, probably for avalanche blasting.'), nl,
    write('The saddle is to your south.'), nl,
    write('The basin is to your west.'), nl.

describe(westernPeak) :-
    (openCave ->
        write('You approach the mouth of the cave'), nl
    ;
    write('You are standing on the side of the western peak.'), nl,
    write('There appears to be a buried cave here. Boulders block the entrance.'), nl
    ).

describe(shack) :-
    write('You step inside, only to realize theres no roof! You must find shelter elsewhere'), nl,
    write('There are wooden crates in here containing 105mm howitzer shells!'), nl.
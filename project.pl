%Include the needed libraries.
:- use_module( library( lists ) ).
:- use_module( library( clpfd ) ).

%Create the Board (create the lines with createLines and the Board itself with createBoard), and add all elements of the Board to a list of Vars.
createLines( [], _, [] ).
createLines( [BH|BT], Size, Vars ) :-
	length( BH, Size ),
	append( BH, MoreVars, Vars ),
	createLines( BT, Size, MoreVars ).

createBoard( Board, Size, Vars ) :-
	length( Board, Size ),
	createLines( Board, Size, Vars ).

%Applies the given constraints to the given row or column. If Start/End is 0, no constraints are acknowledged.
applyConstraint( List, Size, Start, End ) :-
	nth1( 1, List, Elem1 ), %Get the first element.
	nth1( 2, List, Elem2 ), %Get the second element.
	NextToLast is Size-1,
	nth1( Size, List, ElemLast ), %Get the last element.
	nth1( NextToLast, List, ElemNTL ), %Get the next-to-last element.
	( Start #= 0 ; %Either the restriction we're applying is blank (0) and thus the first element can be anything, or...
	Elem1 #= Start ; %The restriction isn't blank but the first element is the same as the restriction, or...
	( Elem1 #= 0 , Elem2 #= Start ) ), %The first element is blank (0), so that the restriction is still the first to appear, and the second element is the restriction.
	( End #= 0 ; %The same logic applies to the ends of the lists.
	ElemLast #= End ;
	( ElemLast #= 0 , ElemNTL #= End ) ).

%Applies to all the lines or columns of the Board the Starts and Ends lists of constraints, as well as ensure that all lines and columns have different numbers by using permutations of a list of possible numbers.
listsConstraint( [], _, [], [] ). %Stop condition.
listsConstraint( [BoardH|BoardT], Size, [StartH|StartT], [EndH|EndT] ) :-
	all_distinct( BoardH ),
	applyConstraint( BoardH, Size, StartH, EndH ),
	listsConstraint( BoardT, Size, StartT, EndT ).

%Applies all the given constraints to the Board.
boardConstraints( Board, Left, Up, Right, Down, Size ) :-
	listsConstraint( Board, Size, Left, Right ),
	transpose( Board, TBoard ),
	listsConstraint( TBoard, Size, Up, Down ).

%Convert numbers to letters so they can be displayed properly.
translate( 0, ' ' ).
translate( N, C ) :- %Minimizing the usage of code.
	N < 27,
	NCode is N+64, %A = 65, NCode is N-1+'A' which is N-1+65 = N+64.
	char_code( C, NCode ). %Convert to character code.
translate( N, NN ) :- %In case the number is higher than 26, we start using numbers instead. This will help for Boards smaller than 38x38.
	NN is N-27. %So at N=27, we'll display 0. At N=37 it will be 10, which will break formatting, but normally it won't go that high.

%Draw a line of the Board.
drawLine( [], Separator ) :- %Stop condition.
	write( Separator ).
drawLine( [LineH|LineT], Separator ) :-
	write( Separator ),
	translate( LineH, Letter ), !,
	write( Letter ),
	drawLine( LineT, Separator ).

%Draw a separating horizontal line of hyphens, to create either the roof or floor of a line of the board.
drawHoriz( 0 ) :-
	write( '+' ), nl.
drawHoriz( N ) :-
	NN is N-1,
	write( '+---' ),
	drawHoriz( NN ).

%Draw the Board.
drawBoardAux( [], _, _, _ ). %Stop condition.
drawBoardAux( [BoardH|BoardT], Size, [LeftH|LeftT], [RightH|RightT] ) :-
	translate( LeftH, LeftChar ), %Get the character corresponding to the left restriction.
	translate( RightH, RightChar ), %Get the character corresponding to the right restriction.
	write( ' ' ), write( LeftChar ), drawLine( BoardH, ' | ' ), write( RightChar ), nl, %Draw the restriction at the left, the line of the board and the restriction at the right.
	write( '   ' ), drawHoriz( Size ), %Draw a separating horizontal line.
	drawBoardAux( BoardT, Size, LeftT, RightT ). %Recursive call.
drawBoard( Board, Size, Left, Up, Right, Down ) :-
	nl,
	write( '  ' ), drawLine( Up, '   ' ), nl, %Draw the restrictions at the top.
	write( '   ' ), drawHoriz( Size ), %Draw a separating horizontal line.
	drawBoardAux( Board, Size, Left, Right ), %Draw the Board, along with the restrictions to the left and right.
	write( '  ' ), drawLine( Down, '   ' ), nl, %Draw the restrictions at the bottom.
	nl.

%Functions to explain the proper controls for the project:
start :- write( 'Usage: start( LeftRestrictions, TopRestrictions, RightRestrictions, BottomRestrictions ).' ), nl,
		write( 'Left and Right restrictions start from the top and end at the bottom.' ), nl,
		write( 'Top and Bottom restrictions start from the left and end on the right.' ), nl,
		write( 'Minimum length for all parameters is 2, as a 1x1 Board would always be empty regardless.' ), nl,
		write( 'When something is unspecified, it should be represented by a zero.' ), nl,
		write( 'Using invalid numbers (such as -1 or numbers outside of the range) is allowed, but won\'t produce any results.' ), nl, nl,
		write( 'Example usages:' ), nl,
		write( ' start( [2,2,1], [2,1,1], [1,1,2], [1,2,2] ). ' ), nl,
		write( ' start( [0,0,0,1], [0,2,0,3], [1,0,0,0], [2,0,3,0] ). ' ), nl, nl.
start( _ ) :- start.
start( _, _ ) :- start.
start( _, _, _ ) :- start.

%The main function, used to create the Board with the given restrictions, assuming they are all fine.
start( Left, Up, Right, Down ) :-
	%Ensure that the length of all the lists of restrictions is the same, and that the Board is at least of size 2x2.
	length( Left, Size ),
	Size > 1, %We ensure that the size is at least 2x2 because a 1x1 Board would always be just blank.
	length( Up, Size ),
	length( Right, Size ),
	length( Down, Size ),
	%If all the restrictions are of the correct size, we can try to create a Board that they would fit and then try to apply them.
	createBoard( Board, Size, Vars ), %First, we create the Board, along with a list containing all the spaces of the Board.
	Limit is Size-1, %We get the upper-bound limit for the domain of each variable.
	domain( Vars, 0, Limit ), %And we apply said limit, which is between 0 and Size-1, both inclusive.
	boardConstraints( Board, Left, Up, Right, Down, Size ), %And then we apply the constraints.
	labeling( [], Vars ),
	%Finally, after applying all constraints and if we've done it successfully, we can draw the Board, as well as its constraints.
	drawBoard( Board, Size, Left, Up, Right, Down ).

%If the function fails, we ensure that the user is shown a message so they know why.
start( _, _, _, _ ) :-
	write( 'Please ensure that all lists of restrictions have the same size and that the Board can still have a solution!' ), nl, nl.

%Pre-made 'queries' to be used with the program.
puzzle0 :-
	start( [0,1], [1,0], [1,1], [0,0] ).
puzzle1 :-
	start( [2,2,1], [2,1,1], [1,1,2], [1,2,2] ).
puzzle2 :-
	start( [0,0,0,1], [0,2,0,3], [1,0,0,0], [2,0,3,0] ).
puzzle3 :-
	start( [0,0,0,1], [0,0,0,1], [1,0,0,0], [1,0,0,0] ).
puzzle4 :-
	start( [0,0,0,1,0], [0,2,0,3,0], [1,0,0,0,0], [2,0,3,0,0] ).
puzzle5 :-
	start( [4,2,3,1,2], [4,1,2,1,3], [3,1,4,2,1], [0,2,3,4,1] ).

# Dark Chess
Dark Chess is a variant of chess where a player (White or Black) can only see the pieces of their opponent in squares that they could potentially move to in that turn. Below we describe our implementation of how it would work in a ZKP setting.

## Overview:
To understand what’s going on at a high level, each player is constructing a set of possible sightings for each piece. IE, player 1 says: you could see my piece if you were this piece and located here & player 2 says: I could see your piece if it were located here. These sets are constructed using a ZKP so that we know these sets were validly calculated.

Then we use a private set intersection to reveal to the moving player which pieces they can actually see. A private set intersection is a mpc that enables one party (in this case, the moving player) to see the overlapping elements of two sets without revealing non-intersecting elements and without revealing to the other party which elements they could decrypt. Thus the moving player doesn’t reveal their “sight” to the other player.

Additionally, we can optimize part of the data transmission by using bloom filters instead of sending over the full sets. 

## Setup:
Black randomly samples a private number: b_0.
Black calculates its potential attack vector set. The set of potential attack vectors for your pieces which describes how each one of your pieces could potentially be moved on by any potential opponent piece. It would take 18 bits per vector and is bounded by 1168 vectors
3 bits for piece
3 bits for x coordinate
3 bits for y coordinate
3 bits for attacking piece
3 bits for attacking piece x
3 bits for attacking piece y
For each element in the attack vector set, Black calculates the hash(element)^b_0 and inserts it into a bloom filter.
Black sends the bloom filter to White.

## Making the first move (& future moves):
White randomly samples a private number: w_0.
White calculates its potential move set. This is the same structure as the potential attack vector set but is calculated where white calculates it can move given no information on Black’s pieces’ positions. 
For each vector in the move vector set, White calculates the hash(vector)^w_0 and then sends it to Black.
For each element in the move vector set received from White, Black calculates element^b_0 and then sends the set back to White.
White calculates element^(1 / w_0) and then checks each element in the bloom filter. Any elements in the bloom filter are there with some probability given by the size of the bloom filter. White now knows which black pieces can be seen given its current position. (For the first move, it’s empty).
White makes a valid move
White randomly samples a new private number: w_1
White calculates its potential attack vector set as Black did in the setup, calculates hash(vector)^w_1 and inserts it into a bloom filter
White sends its newly created bloom filter to Black

## Summary & Observations:
Each move essentially follows:
Moving player calculates potential move set and sends it to other player
Other player just raises each element to the power of its current secret key and sends it back.
Moving player makes a move and sends its potential attack vector bloom filter to other player
Game continues until the king is captured
The potential move vector set and potential attack vector set are each bounded by a limit of 1168 vectors. A much lower bound is achievable and as moves pieces are taken, fewer vectors are needed. As the set of the vector set reveals some limited information about piece position and number, we will pad each vector to be 1168 vectors each time to prevent leakage.
Since each vector requires 18 bits of information, making a move requires ~6KB of information exchanged. This is too much to put directly on-chain in records so it must be sent off-chain.
Sending information off-chain introduces the “who messed up” problem. The sets can be committed to on-chain but must be sent off-chain. Without a third party, it’s unclear who is responsible for failures (malicious or otherwise) when that communication fails.
A simpler game like checkers or limited chess would require a much smaller potential move/attack vector set and thus be doable entirely on-chain and may serve as a better example.
The reason these sets are so large is because in chess pieces can act as walls preventing pieces from seeing other pieces behind them. In range based fog of war where no pieces block sightlines for others (like DOTA or Starcraft), the sets become smaller. 

## Another method of Dark Chess:
Emanant Fog of War
64 tile board
(P) Pawn
(R) Rook
(Kn) Knight
(B) Bishop
(Q) Queen
(K) King

16 white pieces
16 black pieces

Given a random configuration of the board, how do we find fog-of-war from white’s perspective?
Strategy: White attempts to find the presence of Black pieces on the board, and then determines what type of piece each one is.
White emanates out from its piece positions, 8 tiles at a time. We use private set intersection, where the sets are of size 64 (the number of tiles on the chessboard). Each member of the set represents a Black piece being present on that tile. The set is A1, …, H8.

Given this configuration, a hashing function H(x), a constant w known to White, and a constant b known to Black:

White
Black
Emanating from QD4: H(C3)w, H(C4)w, H(C5)w, H(D5)w, H(E5)w, H(E4)w, H(D3)w 
Emanating from RA1: H(A2)w =>
All of Black’s Pieces’ Positions:H(A8)b, H(A7)b, H(B7)b, H(B4)b, H(C8)b…
<=



Take the set from White and raise them by b:
H(C3)wb, H(C4)wb, H(A2)wb, H(C5)wb, H(D5)wb, H(E5)wb, H(E4)wb, H(D3)wb 
<=
Emanating from RA1: H(A3)w
Emanating from PA4: H(A5)w, H(B5)w
Emanating from BB2: H(A3)w [duplicate in the set, skip],
H(C3)w [duplicate from last round, skip],
H(C1)w
Emanating from PC2: H(B3)w, H(C3)w [skip],
H(D3)w [skip]
Emanating from PD2: duplicates, skip
Emanating from KE1: H(D1)w, H(E2)w
Emanating from PF2: H(F3)w => 




Take the set from White and raise them by b:
H(A3)wb, H(A5)wb, H(B5)wb, H(C1)wb, H(B3)wb
H(D1)wb, H(E2)wb, H(F3)wb
5 more rounds…


White now knows there are pieces present on these tiles:
 B4, E5, G5
White sends one more round, the location of the piece in combination with all 6 types of Black’s pieces:
H(PB4)w, H(RB4)w, H(KnB4)w =>




Take the set from White and raise them by b…

Also send the actual set of 16 pieces:
H(RA8)b, H(PA7)b, H(PB7)b, H(PB4)b, H(BC8)b
White now knows its fog of war configuration:
PB4, PE5, QG5




For subsequent fog of war calculations, we can take advantage of the fact that only one piece can move at a time (except for castling, which we can handle as a specific edge case). Black moves a piece. From the configuration last time, White can send a set of its total fog of war. If Black has moved a piece outside of White’s fog of war, the set intersection will remain the same as last round: B4, E5, G5. If Black moved a piece from White’s fog of war out, then the set intersection will be a subset of B4, E5, G5. White can deduce which piece was moved. White can begin sending rounds for extending the fog of war, assuming the piece that was moved was blocking fog of war. If Black moved a piece from White’s fog of war elsewhere within White’s fog of war, White can see that change, deduce which piece moved, and make a note of new restrictions within its fog of war and begin sending rounds for extending its fog of war, assuming the piece moved unblocked a sight-line for a White piece. If Black moved a piece from outside the fog of war in, White will see B4, E5, G5 plus an additional piece. White can make a note of its reduced fog of war and query only for the piece that moved into the fog of war. If Black captures a White piece, this should be communicated before fog of war calculations begin. White can recalculate its fog of war based on remaining pieces, and begin sending rounds to fill out that fog of war.

When white moves a piece, it can simply send fog-of-war sets for the one piece that it moved.

Given that chess has a deterministic start, we should never have to do a full fog-of-war initialization as outlined in the first example, which helps to keep data transfer and calculations relatively small. In order to prevent leaking any information, we can always pad a round’s fog-of-war calculations to the worst-case scenario.

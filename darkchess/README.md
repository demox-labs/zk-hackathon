# Dark Chess
Dark Chess is a variant of chess where a player (White or Black) can only see the pieces of their opponent in squares that they could potentially move to in that turn. Below we describe our implementation of how it would work in a ZKP setting.

## Overview:
To understand what’s going on at a high level, each player is constructing a set of possible sightings for each piece. In other words, player 1 creates a large set of player 2's pieces and locations that could see player 1's own pieces. Player 2 constructs a set of possible pieces that could be sighted from player 2's piece locations on the board. These sets are constructed using a ZKP so that we know these sets were validly calculated.

Then we use a private set intersection to reveal to the moving player which pieces they can actually see. A private set intersection is a [multi-party computation](https://en.wikipedia.org/wiki/Secure_multi-party_computation) that enables one party (in this case, the moving player) to see the overlapping elements of two sets without revealing non-intersecting elements and without revealing to the other party which elements they could decrypt. Thus the moving player doesn’t reveal their “sight” to the other player.

Additionally, we can optimize part of the data transmission by using [bloom filters](https://brilliant.org/wiki/bloom-filter/) instead of sending over the full sets. 

## Setup:
Black randomly samples a private number: b_0.
Black calculates its potential attack vector set. The set of potential attack vectors for your pieces which describes how each one of your pieces could potentially be moved upon by any potential opponent piece. Each vector needs 18 bits, and the total vector set is bounded by 1168 vectors.

3 bits for piece description (6 unique chess pieces)

3 bits for x coordinate (8 squares for x)

3 bits for y coordinate (8 squares for y)

3 bits for attacking piece (6 unique chess pieces)

3 bits for attacking piece x (8 squares for x)

3 bits for attacking piece y (8 squares for y)

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
For a different method of dark chess, check out this paper we also wrote on calculating private set intersections using an emanation strategy: https://docs.google.com/document/d/15QpyQGP5RhnOHfbuxQAqZO_ufDSiNrF23aJ01vzvM14/edit?usp=sharing.

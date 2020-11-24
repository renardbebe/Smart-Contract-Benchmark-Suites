 

pragma solidity ^0.4.8;

contract Rubik {

    event Submission(address submitter, uint8[] moves);
    event NewLeader(address submitter, uint8[] moves);

    enum Color {Red, Blue, Yellow, Green, White, Orange}
    Color[9][6] state;

    address public owner = msg.sender;

     
    address public currentWinner = msg.sender;

     
    uint currentWinnerMoveCount = 9000;


     
    uint contestEndTime = now + 2592000;

    uint8 constant FRONT = 0;
    uint8 constant LEFT = 1;
    uint8 constant UP = 2;
    uint8 constant RIGHT = 3;
    uint8 constant DOWN = 4;
    uint8 constant BACK = 5;

     

    function Rubik() public {
        state[FRONT][0] = Color.Green;
        state[FRONT][1] = Color.Green;
        state[FRONT][2] = Color.Red;
        state[FRONT][3] = Color.Yellow;
        state[FRONT][4] = Color.Red;
        state[FRONT][5] = Color.Green;
        state[FRONT][6] = Color.Red;
        state[FRONT][7] = Color.Yellow;
        state[FRONT][8] = Color.Blue;

        state[LEFT][0] = Color.White;
        state[LEFT][1] = Color.White;
        state[LEFT][2] = Color.Yellow;
        state[LEFT][3] = Color.Red;
        state[LEFT][4] = Color.Blue;
        state[LEFT][5] = Color.White;
        state[LEFT][6] = Color.Red;
        state[LEFT][7] = Color.Red;
        state[LEFT][8] = Color.Blue;

        state[UP][0] = Color.Green;
        state[UP][1] = Color.Blue;
        state[UP][2] = Color.Yellow;
        state[UP][3] = Color.White;
        state[UP][4] = Color.Yellow;
        state[UP][5] = Color.Orange;
        state[UP][6] = Color.White;
        state[UP][7] = Color.Blue;
        state[UP][8] = Color.Blue;

        state[RIGHT][0] = Color.Yellow;
        state[RIGHT][1] = Color.Red;
        state[RIGHT][2] = Color.Orange;
        state[RIGHT][3] = Color.Orange;
        state[RIGHT][4] = Color.Green;
        state[RIGHT][5] = Color.White;
        state[RIGHT][6] = Color.Blue;
        state[RIGHT][7] = Color.Orange;
        state[RIGHT][8] = Color.Orange;

        state[DOWN][0] = Color.White;
        state[DOWN][1] = Color.Red;
        state[DOWN][2] = Color.Orange;
        state[DOWN][3] = Color.Yellow;
        state[DOWN][4] = Color.White;
        state[DOWN][5] = Color.Yellow;
        state[DOWN][6] = Color.Yellow;
        state[DOWN][7] = Color.Blue;
        state[DOWN][8] = Color.Green;

        state[BACK][0] = Color.Green;
        state[BACK][1] = Color.Green;
        state[BACK][2] = Color.Red;
        state[BACK][3] = Color.Blue;
        state[BACK][4] = Color.Orange;
        state[BACK][5] = Color.Orange;
        state[BACK][6] = Color.White;
        state[BACK][7] = Color.Green;
        state[BACK][8] = Color.Orange;
    }

    function getOwner() view public returns (address)  {
       return owner;
    }

    function getCurrentWinner() view public returns (address)  {
       return currentWinner;
    }

    function getCurrentWinnerMoveCount() view public returns (uint)  {
       return currentWinnerMoveCount;
    }

    function getBalance() view public returns (uint256) {
        return this.balance;
    }

    function getContestEndTime() view public returns (uint256) {
        return contestEndTime;
    }

     
    function addBalance() public payable {
        require(msg.sender == owner);
    }


     

    function verifySide(Color[9][6] memory aState, uint8 FACE, Color expectedColor) internal pure returns (bool) {
        return aState[FACE][0] == expectedColor &&
        aState[FACE][1] == expectedColor &&
        aState[FACE][2] == expectedColor &&
        aState[FACE][3] == expectedColor &&
        aState[FACE][4] == expectedColor &&
        aState[FACE][5] == expectedColor &&
        aState[FACE][6] == expectedColor &&
        aState[FACE][7] == expectedColor &&
        aState[FACE][8] == expectedColor;
    }


     

    function isSolved(Color[9][6] memory aState) public pure returns (bool) {
        return verifySide(aState, FRONT, Color.Red) &&
        verifySide(aState, LEFT, Color.Blue) &&
        verifySide(aState, UP, Color.Yellow) &&
        verifySide(aState, RIGHT, Color.Green) &&
        verifySide(aState, DOWN, Color.White) &&
        verifySide(aState, BACK, Color.Orange);
    }

    function getInitialState() public view returns (Color[9][6])  {
        return state;
    }


     

    function shuffleFace(Color[9][6] memory aState, uint FACE) pure internal {
        Color[9] memory swap;
        swap[0] = aState[FACE][0];
        swap[1] = aState[FACE][1];
        swap[2] = aState[FACE][2];
        swap[3] = aState[FACE][3];
        swap[4] = aState[FACE][4];
        swap[5] = aState[FACE][5];
        swap[6] = aState[FACE][6];
        swap[7] = aState[FACE][7];
        swap[8] = aState[FACE][8];

        aState[FACE][0] = swap[2];
        aState[FACE][1] = swap[5];
        aState[FACE][2] = swap[8];
        aState[FACE][3] = swap[1];
        aState[FACE][4] = swap[4];
        aState[FACE][5] = swap[7];
        aState[FACE][6] = swap[0];
        aState[FACE][7] = swap[3];
        aState[FACE][8] = swap[6];
    }

    function shuffleDown(Color[9][6] memory aState) pure internal {
        shuffleFace(aState, DOWN);
        Color[12] memory swap;
        swap[0] = aState[FRONT][2];
        swap[1] = aState[FRONT][5];
        swap[2] = aState[FRONT][8];

        swap[3] = aState[RIGHT][2];
        swap[4] = aState[RIGHT][5];
        swap[5] = aState[RIGHT][8];

        swap[6] = aState[BACK][6];
        swap[7] = aState[BACK][3];
        swap[8] = aState[BACK][0];

        swap[9] = aState[LEFT][2];
        swap[10] = aState[LEFT][5];
        swap[11] = aState[LEFT][8];

        aState[FRONT][2] = swap[9];
        aState[FRONT][5] = swap[10];
        aState[FRONT][8] = swap[11];

        aState[RIGHT][2] = swap[0];
        aState[RIGHT][5] = swap[1];
        aState[RIGHT][8] = swap[2];

        aState[BACK][6] = swap[3];
        aState[BACK][3] = swap[4];
        aState[BACK][0] = swap[5];

        aState[LEFT][2] = swap[6];
        aState[LEFT][5] = swap[7];
        aState[LEFT][8] = swap[8];
    }


    function shuffleRight(Color[9][6] memory aState) pure internal {
        shuffleFace(aState, RIGHT);
        Color[12] memory swap;
        swap[0] = aState[UP][8];
        swap[1] = aState[UP][7];
        swap[2] = aState[UP][6];

        swap[3] = aState[BACK][8];
        swap[4] = aState[BACK][7];
        swap[5] = aState[BACK][6];

        swap[6] = aState[DOWN][8];
        swap[7] = aState[DOWN][7];
        swap[8] = aState[DOWN][6];

        swap[9] = aState[FRONT][8];
        swap[10] = aState[FRONT][7];
        swap[11] = aState[FRONT][6];

        aState[UP][8] = swap[9];
        aState[UP][7] = swap[10];
        aState[UP][6] = swap[11];

        aState[BACK][8] = swap[0];
        aState[BACK][7] = swap[1];
        aState[BACK][6] = swap[2];

        aState[DOWN][8] = swap[3];
        aState[DOWN][7] = swap[4];
        aState[DOWN][6] = swap[5];

        aState[FRONT][8] = swap[6];
        aState[FRONT][7] = swap[7];
        aState[FRONT][6] = swap[8];
    }

    function shuffleUp(Color[9][6] memory aState) pure internal {
        shuffleFace(aState, UP);
        Color[12] memory swap;
        swap[0] = aState[BACK][2];
        swap[1] = aState[BACK][5];
        swap[2] = aState[BACK][8];

        swap[3] = aState[RIGHT][6];
        swap[4] = aState[RIGHT][3];
        swap[5] = aState[RIGHT][0];

        swap[6] = aState[FRONT][6];
        swap[7] = aState[FRONT][3];
        swap[8] = aState[FRONT][0];

        swap[9] = aState[LEFT][6];
        swap[10] = aState[LEFT][3];
        swap[11] = aState[LEFT][0];

        aState[BACK][2] = swap[9];
        aState[BACK][5] = swap[10];
        aState[BACK][8] = swap[11];

        aState[RIGHT][6] = swap[0];
        aState[RIGHT][3] = swap[1];
        aState[RIGHT][0] = swap[2];

        aState[FRONT][6] = swap[3];
        aState[FRONT][3] = swap[4];
        aState[FRONT][0] = swap[5];

        aState[LEFT][6] = swap[6];
        aState[LEFT][3] = swap[7];
        aState[LEFT][0] = swap[8];
    }


    function shuffleLeft(Color[9][6] memory aState) pure internal {
        shuffleFace(aState, LEFT);
        Color[12] memory swap;

        swap[0] = aState[UP][0];
        swap[1] = aState[UP][1];
        swap[2] = aState[UP][2];

        swap[3] = aState[FRONT][0];
        swap[4] = aState[FRONT][1];
        swap[5] = aState[FRONT][2];

        swap[6] = aState[DOWN][0];
        swap[7] = aState[DOWN][1];
        swap[8] = aState[DOWN][2];

        swap[9] = aState[BACK][0];
        swap[10] = aState[BACK][1];
        swap[11] = aState[BACK][2];

        aState[UP][0] = swap[9];
        aState[UP][1] = swap[10];
        aState[UP][2] = swap[11];

        aState[FRONT][0] = swap[0];
        aState[FRONT][1] = swap[1];
        aState[FRONT][2] = swap[2];

        aState[DOWN][0] = swap[3];
        aState[DOWN][1] = swap[4];
        aState[DOWN][2] = swap[5];

        aState[BACK][0] = swap[6];
        aState[BACK][1] = swap[7];
        aState[BACK][2] = swap[8];
    }

    function shuffleFront(Color[9][6] memory aState) pure internal {
        shuffleFace(aState, FRONT);
        Color[12] memory swap;

        swap[0] = aState[UP][2];
        swap[1] = aState[UP][5];
        swap[2] = aState[UP][8];

        swap[3] = aState[RIGHT][0];
        swap[4] = aState[RIGHT][1];
        swap[5] = aState[RIGHT][2];

        swap[6] = aState[DOWN][6];
        swap[7] = aState[DOWN][3];
        swap[8] = aState[DOWN][0];

        swap[9] = aState[LEFT][8];
        swap[10] = aState[LEFT][7];
        swap[11] = aState[LEFT][6];

        aState[UP][2] = swap[9];
        aState[UP][5] = swap[10];
        aState[UP][8] = swap[11];

        aState[RIGHT][0] = swap[0];
        aState[RIGHT][1] = swap[1];
        aState[RIGHT][2] = swap[2];

        aState[DOWN][6] = swap[3];
        aState[DOWN][3] = swap[4];
        aState[DOWN][0] = swap[5];

        aState[LEFT][8] = swap[6];
        aState[LEFT][7] = swap[7];
        aState[LEFT][6] = swap[8];
    }

     
    function trySolution(uint8[] moves) public view returns (Color[9][6]) {
        Color[9][6] memory aState = state;

        for (uint i = 0; i < moves.length; i++) {
            if (moves[i] == FRONT) {
                shuffleFront(aState);
            } else if (moves[i] == LEFT) {
                shuffleLeft(aState);
            } else if (moves[i] == UP) {
                shuffleUp(aState);
            } else if (moves[i] == RIGHT) {
                shuffleRight(aState);
            } else if (moves[i] == DOWN) {
                shuffleDown(aState);
            } else {
                 
                require(false);
            }
        }
        return aState;
    }


     
    function submitSolution(uint8[] moves) public {

        Submission(msg.sender, moves);
         
        require(now < contestEndTime);
        Color[9][6] memory stateAfterMoves = trySolution(moves);

         
        if (isSolved(stateAfterMoves)) {

             
            if(moves.length < currentWinnerMoveCount) {
                currentWinnerMoveCount = moves.length;
                currentWinner = msg.sender;
                NewLeader(msg.sender, moves);
            }
        }
    }

 
    function claim() public {
        require(now >= contestEndTime);
        require(msg.sender == currentWinner);
        msg.sender.transfer(this.balance);
    }

}
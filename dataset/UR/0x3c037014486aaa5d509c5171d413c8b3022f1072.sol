 

 

pragma solidity ^0.5.9;

library Reversi {
     
     
     
    uint8 constant BLACK = 1;  
    uint8 constant WHITE = 2;  
    uint8 constant EMPTY = 3;  

    struct Game {
        bool error;
        bool complete;
        bool symmetrical;
        bool RotSym;
        bool Y0Sym;
        bool X0Sym;
        bool XYSym;
        bool XnYSym;
        bytes16 board;
        bytes28 first32Moves;
        bytes28 lastMoves;

        uint8 currentPlayer;
        uint8 moveKey;
        uint8 blackScore;
        uint8 whiteScore;
         
    }


    function isValid (bytes28[2] memory moves) public pure returns (bool) {
        Game memory game = playGame(moves);
        if (game.error) {
            return false;
        } else if (!game.complete) {
            return false;
        } else {
            return true;
        }
    }

    function getGame (bytes28[2] memory moves) public pure returns (
        bool error,
        bool complete,
        bool symmetrical,
        bytes16 board,
        uint8 currentPlayer,
        uint8 moveKey
     
    ) {
        Game memory game = playGame(moves);
        return (
            game.error,
            game.complete,
            game.symmetrical,
            game.board,
            game.currentPlayer,
            game.moveKey
             
        );
    }

    function showColors () public pure returns(uint8, uint8, uint8) {
        return (EMPTY, BLACK, WHITE);
    }

    function emptyBoard() public pure returns (bytes16) {
         
        return bytes16(uint128(340282366920938456379662753540715053055));  
    }

    function playGame (bytes28[2] memory moves) internal pure returns (Game memory)  {
        Game memory game;

        game.first32Moves = moves[0];
        game.lastMoves = moves[1];
        game.moveKey = 0;
        game.blackScore = 2;
        game.whiteScore = 2;

        game.error = false;
        game.complete = false;
        game.currentPlayer = BLACK;

        game.board = emptyBoard();

        bool skip;
        uint8 move;
        uint8 col;
        uint8 row;
        uint8 i;
        bytes28 currentMoves;

        for (i = 0; i < 60 && !skip; i++) {
            currentMoves = game.moveKey < 32 ? game.first32Moves : game.lastMoves;
            move = readMove(currentMoves, game.moveKey % 32, 32);
            (col, row) = convertMove(move);
            skip = !validMove(move);
            if (i == 0 && (col != 2 || row != 3)) {
                skip = true;  
                game.error = true;
            }
            if (!skip && col < 8 && row < 8 && col >= 0 && row >= 0) {
                 
                game = makeMove(game, col, row);
                game.moveKey = game.moveKey + 1;
                if (game.error) {
                    if (!validMoveRemains(game)) {
                         
                        game.error = false;
                        if (game.currentPlayer == BLACK) {
                            game.currentPlayer = WHITE;
                        } else {
                            game.currentPlayer = BLACK;
                        }
                        game = makeMove(game, col, row);
                        if (game.error) {
                            game.error = true;
                            skip = true;
                        }
                    }
                }
            }
        }
        if (!game.error) {
            game = isComplete(game);
            game = isSymmetrical(game);
        }
        return game;
    }

    function validMoveRemains (Game memory game) internal pure returns (bool) {
        bool validMovesRemain = false;
        bytes16 board = game.board;
        uint8 i;
        for (i = 0; i < 64 && !validMovesRemain; i++) {
            uint8[2] memory move = [((i - (i % 8)) / 8), (i % 8)];
            uint8 tile = returnTile(game.board, move[0], move[1]);
            if (tile == EMPTY) {
                game.error = false;
                game.board = board;
                game = makeMove(game, move[0], move[1]);
                if (!game.error) {
                    validMovesRemain = true;
                }
            }
        }
        return validMovesRemain;
    }

    function makeMove (Game memory game, uint8 col, uint8 row) internal pure returns (Game memory)  {
         
        if (returnTile(game.board, col, row) != EMPTY){
            game.error = true;
             
            return game;
        }
        int8[2][8] memory possibleDirections;
        uint8  possibleDirectionsLength;
        (possibleDirections, possibleDirectionsLength) = getPossibleDirections(game, col, row);
         
        if (possibleDirectionsLength == 0) {
            game.error = true;
             
            return game;
        }

        bytes28 newFlips;
        uint8 newFlipsLength;
        uint8 newFlipCol;
        uint8 newFlipRow;
        uint8 j;
        bool valid = false;
        for (uint8 i = 0; i < possibleDirectionsLength; i++) {
            delete newFlips;
            delete newFlipsLength;
            (newFlips, newFlipsLength) = traverseDirection(game, possibleDirections[i], col, row);
            for (j = 0; j < newFlipsLength; j++) {
                if (!valid) valid = true;
                (newFlipCol, newFlipRow) = convertMove(readMove(newFlips, j, newFlipsLength));
                game.board = turnTile(game.board, game.currentPlayer, newFlipCol, newFlipRow);
                if (game.currentPlayer == WHITE) {
                    game.whiteScore += 1;
                    game.blackScore -= 1;
                } else {
                    game.whiteScore -= 1;
                    game.blackScore += 1;
                }
            }
        }

         
        if (valid) {
            game.board = turnTile(game.board, game.currentPlayer, col, row);
            if (game.currentPlayer == WHITE) {
                game.whiteScore += 1;
            } else {
                game.blackScore += 1;
            }
        } else {
            game.error = true;
             
            return game;
        }

         
        if (game.currentPlayer == BLACK) {
            game.currentPlayer = WHITE;
        } else {
            game.currentPlayer = BLACK;
        }
        return game;
    }

    function getPossibleDirections (Game memory game, uint8 col, uint8 row) internal pure returns(int8[2][8] memory, uint8){

        int8[2][8] memory possibleDirections;
        uint8 possibleDirectionsLength = 0;
        int8[2][8] memory dirs = [
            [int8(-1), int8(0)],  
            [int8(-1), int8(1)],  
            [int8(0), int8(1)],  
            [int8(1), int8(1)],  
            [int8(1), int8(0)],  
            [int8(1), int8(-1)],  
            [int8(0), int8(-1)],  
            [int8(-1), int8(-1)]  
        ];
        int8 focusedRowPos;
        int8 focusedColPos;
        int8[2] memory dir;
        uint8 testSquare;

        for (uint8 i = 0; i < 8; i++) {
            dir = dirs[i];
            focusedColPos = int8(col) + dir[0];
            focusedRowPos = int8(row) + dir[1];

             
            if (!(focusedRowPos > 7 || focusedRowPos < 0 || focusedColPos > 7 || focusedColPos < 0)) {
                testSquare = returnTile(game.board, uint8(focusedColPos), uint8(focusedRowPos));

                 
                if (testSquare != game.currentPlayer) {
                    if (testSquare != EMPTY) {
                        possibleDirections[possibleDirectionsLength] = dir;
                        possibleDirectionsLength++;
                    }
                }
            }
        }
        return (possibleDirections, possibleDirectionsLength);
    }

    function traverseDirection (Game memory game, int8[2] memory dir, uint8 col, uint8 row) internal pure returns(bytes28, uint8) {
        bytes28 potentialFlips;
        uint8 potentialFlipsLength = 0;
        uint8 opponentColor;
        if (game.currentPlayer == BLACK) {
            opponentColor = WHITE;
        } else {
            opponentColor = BLACK;
        }

         
         
        bool skip = false;
        int8 testCol;
        int8 testRow;
        uint8 tile;
        for (uint8 j = 1; j < 9; j++) {
            if (!skip) {
                testCol = (int8(j) * dir[0]) + int8(col);
                testRow = (int8(j) * dir[1]) + int8(row);
                 
                if (testCol > 7 || testCol < 0 || testRow > 7 || testRow < 0) {
                    delete potentialFlips;
                    potentialFlipsLength = 0;
                    skip = true;
                } else{

                    tile = returnTile(game.board, uint8(testCol), uint8(testRow));

                    if (tile == opponentColor) {
                         
                        (potentialFlips, potentialFlipsLength) = addMove(potentialFlips, potentialFlipsLength, uint8(testCol), uint8(testRow));
                    } else if (tile == game.currentPlayer && j > 1) {
                         
                        skip = true;
                    } else {
                         
                         
                        delete potentialFlips;
                        delete potentialFlipsLength;
                        skip = true;
                    }
                }
            }
        }
        return (potentialFlips, potentialFlipsLength);
    }

    function isComplete (Game memory game) internal pure returns (Game memory) {
        if (game.moveKey == 60) {
             
            game.complete = true;
            return game;
        } else {
            uint8 i;
            bool validMovesRemains = false;
            bytes16 board = game.board;
            for (i = 0; i < 64 && !validMovesRemains; i++) {
                uint8[2] memory move = [((i - (i % 8)) / 8), (i % 8)];
                uint8 tile = returnTile(game.board, move[0], move[1]);
                if (tile == EMPTY) {
                    game.currentPlayer = BLACK;
                    game.error = false;
                    game.board = board;
                    game = makeMove(game, move[0], move[1]);
                    if (!game.error) {
                        validMovesRemains = true;
                    }
                    game.currentPlayer = WHITE;
                    game.error = false;
                    game.board = board;
                    game = makeMove(game, move[0], move[1]);
                    if (!game.error) {
                        validMovesRemains = true;
                    }
                }
            }
            if (validMovesRemains) {
                game.error = true;
                 
            } else {
                 
                game.complete = true;
                game.error = false;
            }
        }
        return game;
    }

    function isSymmetrical (Game memory game) internal pure returns (Game memory) {
        bool RotSym = true;
        bool Y0Sym = true;
        bool X0Sym = true;
        bool XYSym = true;
        bool XnYSym = true;
        for (uint8 i = 0; i < 8 && (RotSym || Y0Sym || X0Sym || XYSym || XnYSym); i++) {
            for (uint8 j = 0; j < 8 && (RotSym || Y0Sym || X0Sym || XYSym || XnYSym); j++) {

                 
                if (returnBytes(game.board, i, j) != returnBytes(game.board, (7 - i), (7 - j))) {
                    RotSym = false;
                }
                 
                if (returnBytes(game.board, i, j) != returnBytes(game.board, i, (7 - j))) {
                    Y0Sym = false;
                }
                 
                if (returnBytes(game.board, i, j) != returnBytes(game.board, (7 - i), j)) {
                    X0Sym = false;
                }
                 
                if (returnBytes(game.board, i, j) != returnBytes(game.board, (7 - j), (7 - i))) {
                    XYSym = false;
                }
                 
                if (returnBytes(game.board, i, j) != returnBytes(game.board, j, i)) {
                    XnYSym = false;
                }
            }
        }
        if (RotSym || Y0Sym || X0Sym || XYSym || XnYSym) {
            game.symmetrical = true;
            game.RotSym = RotSym;
            game.Y0Sym = Y0Sym;
            game.X0Sym = X0Sym;
            game.XYSym = XYSym;
            game.XnYSym = XnYSym;
        }
        return game;
    }



     

    function returnSymmetricals (bool RotSym, bool Y0Sym, bool X0Sym, bool XYSym, bool XnYSym) public pure returns (uint256) {
        uint256 symmetries = 0;
        if(RotSym) symmetries |= 16;
        if(Y0Sym) symmetries |= 8;
        if(X0Sym) symmetries |= 4;
        if(XYSym) symmetries |= 2;
        if(XnYSym) symmetries |= 1;
        return symmetries;
    }


    function returnBytes (bytes16 board, uint8 col, uint8 row) internal pure returns (bytes16) {
        uint128 push = posToPush(col, row);
        return (board >> push) & bytes16(uint128(3));
    }

    function turnTile (bytes16 board, uint8 color, uint8 col, uint8 row) internal pure returns (bytes16){
        if (col > 7) revert("can't turn tile outside of board col");
        if (row > 7) revert("can't turn tile outside of board row");
        uint128 push = posToPush(col, row);
        bytes16 mask = bytes16(uint128(3)) << push; 

        board = ((board ^ mask) & board);

        return board | (bytes16(uint128(color)) << push);
    }

    function returnTile (bytes16 board, uint8 col, uint8 row) public pure returns (uint8){
        uint128 push = posToPush(col, row);
        bytes16 tile = (board >> push ) & bytes16(uint128(3));
        return uint8(uint128(tile));  
    }

    function posToPush (uint8 col, uint8 row) internal pure returns (uint128){
        return uint128(((64) - ((8 * col) + row + 1)) * 2);
    }

    function readMove (bytes28 moveSequence, uint8 moveKey, uint8 movesLength) public pure returns(uint8) {
        bytes28 mask = bytes28(uint224(127));
        uint8 push = (movesLength * 7) - (moveKey * 7) - 7;
        return uint8(uint224((moveSequence >> push) & mask));
    }

    function addMove (bytes28 moveSequence, uint8 movesLength, uint8 col, uint8 row) internal pure returns (bytes28, uint8) {
        uint256 foo = col + (row * 8) + 64;
        bytes28 move = bytes28(uint224(foo));
        moveSequence = moveSequence << 7;
        moveSequence = moveSequence | move;
        movesLength++;
        return (moveSequence, movesLength);
    }

    function validMove (uint8 move) internal pure returns(bool) {
        return move >= 64;
    }

    function convertMove (uint8 move) public pure returns(uint8, uint8) {
        move = move - 64;
        uint8 col = move % 8;
        uint8 row = (move - col) / 8;
        return (col, row);
    }

}

 

pragma solidity ^0.5.9;

contract IClovers {
    function ownerOf(uint256 _tokenId) public view returns (address _owner);
    function setCloverMoves(uint256 _tokenId, bytes28[2] memory moves) public;
    function getCloverMoves(uint256 _tokenId) public view returns (bytes28[2] memory);
    function getAllSymmetries() public view returns (uint256, uint256, uint256, uint256, uint256, uint256);
    function exists(uint256 _tokenId) public view returns (bool _exists);
    function getBlockMinted(uint256 _tokenId) public view returns (uint256);
    function setBlockMinted(uint256 _tokenId, uint256 value) public;
    function setKeep(uint256 _tokenId, bool value) public;
    function setSymmetries(uint256 _tokenId, uint256 _symmetries) public;
    function setReward(uint256 _tokenId, uint256 _amount) public;
    function mint (address _to, uint256 _tokenId) public;
    function getReward(uint256 _tokenId) public view returns (uint256);
    function getKeep(uint256 _tokenId) public view returns (bool);
    function transferFrom(address _from, address _to, uint256 _tokenId) public;
    function moveEth(address _to, uint256 _amount) public;
    function getSymmetries(uint256 _tokenId) public view returns (uint256);
    function deleteClover(uint256 _tokenId) public;
    function setAllSymmetries(uint256 _totalSymmetries, uint256 RotSym, uint256 Y0Sym, uint256 X0Sym, uint256 XYSym, uint256 XnYSym) public;
}

 

pragma solidity ^0.5.9;

contract IClubToken {
    function balanceOf(address _owner) public view returns (uint256);
    function burn(address _burner, uint256 _value) public;
    function mint(address _to, uint256 _amount) public returns (bool);
}

 

pragma solidity ^0.5.9;

contract IClubTokenController {
    function buy(address buyer) public payable returns(bool);
}

 

pragma solidity ^0.5.9;

contract ISimpleCloversMarket {
    function sell(uint256 _tokenId, uint256 price) public;
}

 

pragma solidity ^0.5.0;

 
library SafeMath {
     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
         

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

 

pragma solidity ^0.5.0;

 
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

     
    function owner() public view returns (address) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

     
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

     
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

     
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

 

pragma solidity ^0.5.0;

 
library ECDSA {
     
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
         
        if (signature.length != 65) {
            return (address(0));
        }

         
        bytes32 r;
        bytes32 s;
        uint8 v;

         
         
         
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

         
         
         
         
         
         
         
         
         
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return address(0);
        }

        if (v != 27 && v != 28) {
            return address(0);
        }

         
        return ecrecover(hash, v, r, s);
    }

     
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
         
         
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}

 

pragma solidity ^0.5.9;

 









contract CloversController is Ownable {
    event cloverCommitted(bytes32 movesHash, address owner);
    event cloverClaimed(uint256 tokenId, bytes28[2] moves, address sender, address recepient, uint reward, uint256 symmetries, bool keep);
    event cloverChallenged(uint256 tokenId, bytes28[2] moves, address owner, address challenger);

    using SafeMath for uint256;
    using ECDSA for bytes32;

    bool public paused;
    address public oracle;
    IClovers public clovers;
    IClubToken public clubToken;
    IClubTokenController public clubTokenController;
    ISimpleCloversMarket public simpleCloversMarket;
     

    uint256 public gasLastUpdated_fastGasPrice_averageGasPrice_safeLowGasPrice;
    uint256 public gasBlockMargin = 240;  

    uint256 public basePrice;
    uint256 public priceMultiplier;
    uint256 public payMultiplier;

    mapping(bytes32=>address) public commits;

    modifier notPaused() {
        require(!paused, "Must not be paused");
        _;
    }

    constructor(
        IClovers _clovers,
        IClubToken _clubToken,
        IClubTokenController _clubTokenController
         
    ) public {
        clovers = _clovers;
        clubToken = _clubToken;
        clubTokenController = _clubTokenController;
         
        paused = true;
    }

    function getMovesHash(bytes28[2] memory moves) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(moves));
    }

    function getMovesHashWithRecepient(bytes32 movesHash, address recepient) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(movesHash, recepient));
    }

     
    function isValid(bytes28[2] memory moves) public pure returns (bool) {
        Reversi.Game memory game = Reversi.playGame(moves);
        return isValidGame(game.error, game.complete);
    }

     
    function isValidGame(bool error, bool complete) public pure returns (bool) {
        if (error || !complete) {
            return false;
        } else {
            return true;
        }
    }

    function getGame (bytes28[2] memory moves) public pure returns (bool error, bool complete, bool symmetrical, bytes16 board, uint8 currentPlayer, uint8 moveKey) {
         
        Reversi.Game memory game = Reversi.playGame(moves);
        return (
            game.error,
            game.complete,
            game.symmetrical,
            game.board,
            game.currentPlayer,
            game.moveKey
             
        );
    }
     
    function calculateReward(uint256 symmetries) public view returns (uint256) {
        uint256 Symmetricals;
        uint256 RotSym;
        uint256 Y0Sym;
        uint256 X0Sym;
        uint256 XYSym;
        uint256 XnYSym;
        (Symmetricals,
        RotSym,
        Y0Sym,
        X0Sym,
        XYSym,
        XnYSym) = clovers.getAllSymmetries();
        uint256 base = 0;
        if (symmetries >> 4 & 1 == 1) base = base.add(payMultiplier.mul(Symmetricals + 1).div(RotSym + 1));
        if (symmetries >> 3 & 1 == 1) base = base.add(payMultiplier.mul(Symmetricals + 1).div(Y0Sym + 1));
        if (symmetries >> 2 & 1 == 1) base = base.add(payMultiplier.mul(Symmetricals + 1).div(X0Sym + 1));
        if (symmetries >> 1 & 1 == 1) base = base.add(payMultiplier.mul(Symmetricals + 1).div(XYSym + 1));
        if (symmetries & 1 == 1) base = base.add(payMultiplier.mul(Symmetricals + 1).div(XnYSym + 1));
        return base;
    }

    function getPrice(uint256 symmetries) public view returns(uint256) {
        return basePrice.add(calculateReward(symmetries));
    }

     
     
    function claimCloverSecurelyPartOne(bytes32 movesHashWithRecepient) public {
        commits[movesHashWithRecepient] = address(1);
        commits[keccak256(abi.encodePacked(msg.sender))] = address(block.number);
    }

     
     
    function claimCloverSecurelyPartTwo(bytes32 movesHash) public {
        require(uint256(commits[keccak256(abi.encodePacked(msg.sender))]) < block.number, "Can't combine step1 with step2");
        bytes32 commitHash = getMovesHashWithRecepient(movesHash, msg.sender);
        address commitOfMovesHashWithRecepient = commits[commitHash];
        require(
            address(commitOfMovesHashWithRecepient) == address(1),
            "Invalid commitOfMovesHashWithRecepient, please do claimCloverSecurelyPartOne"
        );
        delete(commits[commitHash]);
        commits[movesHash] = msg.sender;
    }

    function claimCloverWithVerification(bytes28[2] memory moves, bool keep) public payable returns (bool) {
        bytes32 movesHash = getMovesHash(moves);
        address committedRecepient = commits[movesHash];
        require(committedRecepient == address(0) || committedRecepient == msg.sender, "Invalid committedRecepient");

        Reversi.Game memory game = Reversi.playGame(moves);
        require(isValidGame(game.error, game.complete), "Invalid game");
        uint256 tokenId = convertBytes16ToUint(game.board);
        require(!clovers.exists(tokenId), "Clover already exists");

        uint256 symmetries = Reversi.returnSymmetricals(game.RotSym, game.Y0Sym, game.X0Sym, game.XYSym, game.XnYSym);
        require(_claimClover(tokenId, moves, symmetries, msg.sender, keep), "Claim must succeed");
        delete(commits[movesHash]);
        return true;
    }



     
    function claimCloverWithSignature(uint256 tokenId, bytes28[2] memory moves, uint256 symmetries, bool keep, bytes memory signature) public payable notPaused returns (bool) {
        address committedRecepient = commits[getMovesHash(moves)];
        require(committedRecepient == address(0) || committedRecepient == msg.sender, "Invalid committedRecepient");
        require(!clovers.exists(tokenId), "Clover already exists");
        require(checkSignature(tokenId, moves, symmetries, keep, msg.sender, signature, oracle), "Invalid Signature");
        require(_claimClover(tokenId, moves, symmetries, msg.sender, keep), "Claim must succeed");
        return true;
    }

    function _claimClover(uint256 tokenId, bytes28[2] memory moves, uint256 symmetries, address recepient, bool keep) internal returns (bool) {
        clovers.setCloverMoves(tokenId, moves);
        clovers.setKeep(tokenId, keep);
        uint256 reward;
        if (symmetries > 0) {
            clovers.setSymmetries(tokenId, symmetries);
            reward = calculateReward(symmetries);
            clovers.setReward(tokenId, reward);
            addSymmetries(symmetries);
        }
        uint256 price = basePrice.add(reward);
        if (keep && price > 0) {
             
             
            if (clubToken.balanceOf(msg.sender) < price) {
                clubTokenController.buy.value(msg.value)(msg.sender);
            }
            clubToken.burn(msg.sender, price);
        }

        if (keep) {
             
            clovers.mint(recepient, tokenId);
        } else {
             
             
             
            clovers.mint(address(clovers), tokenId);
            simpleCloversMarket.sell(tokenId, basePrice.add(reward.mul(priceMultiplier)));
            if (reward > 0) {
                require(clubToken.mint(recepient, reward), "mint must succeed");
            }
        }
        emit cloverClaimed(tokenId, moves, msg.sender, recepient, reward, symmetries, keep);
        return true;
    }


     
    function convertBytes16ToUint(bytes16 _board) public pure returns(uint256 number) {
        for(uint i=0;i<_board.length;i++){
            number = number + uint(uint8(_board[i]))*(2**(8*(_board.length-(i+1))));
        }
    }


     
    function challengeClover(uint256 tokenId) public returns (bool) {
        require(clovers.exists(tokenId), "Clover must exist to be challenged");
        bool valid = true;
        bytes28[2] memory moves = clovers.getCloverMoves(tokenId);
        address payable _owner = address(uint160(owner()));
        if (msg.sender != _owner && msg.sender != oracle) {
            Reversi.Game memory game = Reversi.playGame(moves);
            if(convertBytes16ToUint(game.board) != tokenId) {
                valid = false;
            }
            if(valid && isValidGame(game.error, game.complete)) {
                uint256 symmetries = clovers.getSymmetries(tokenId);
                valid = (symmetries >> 4 & 1) > 0 == game.RotSym ? valid : false;
                valid = (symmetries >> 3 & 1) > 0 == game.Y0Sym ? valid : false;
                valid = (symmetries >> 2 & 1) > 0 == game.X0Sym ? valid : false;
                valid = (symmetries >> 1 & 1) > 0 == game.XYSym ? valid : false;
                valid = (symmetries & 1) > 0 == game.XnYSym ? valid : false;
            } else {
                valid = false;
            }
            require(!valid, "Must be invalid to challenge");
        }

        removeSymmetries(tokenId);
        address committer = clovers.ownerOf(tokenId);
        emit cloverChallenged(tokenId, moves, committer, msg.sender);
        clovers.deleteClover(tokenId);
        return true;
    }

    function updateSalePrice(uint256 tokenId, uint256 _price) public onlyOwner {
        simpleCloversMarket.sell(tokenId, _price);
    }

     
    function transferFrom(address _from, address _to, uint256 tokenId) public {
        require(msg.sender == address(simpleCloversMarket), "transferFrom can only be done by simpleCloversMarket");
        clovers.transferFrom(_from, _to, tokenId);
    }

     
    function updatePaused(bool _paused) public onlyOwner {
        paused = _paused;
    }

     
    function updateOracle(address _oracle) public onlyOwner {
        oracle = _oracle;
    }

     
    function updateSimpleCloversMarket(ISimpleCloversMarket _simpleCloversMarket) public onlyOwner {
        simpleCloversMarket = _simpleCloversMarket;
    }

     
    function updateClubTokenController(IClubTokenController _clubTokenController) public onlyOwner {
        clubTokenController = _clubTokenController;
    }
     
    function updatePayMultipier(uint256 _payMultiplier) public onlyOwner {
        payMultiplier = _payMultiplier;
    }
     
    function updatePriceMultipier(uint256 _priceMultiplier) public onlyOwner {
        priceMultiplier = _priceMultiplier;
    }
     
    function updateBasePrice(uint256 _basePrice) public onlyOwner {
        basePrice = _basePrice;
    }

     
    function addSymmetries(uint256 symmetries) private {
        uint256 Symmetricals;
        uint256 RotSym;
        uint256 Y0Sym;
        uint256 X0Sym;
        uint256 XYSym;
        uint256 XnYSym;
        (Symmetricals,
        RotSym,
        Y0Sym,
        X0Sym,
        XYSym,
        XnYSym) = clovers.getAllSymmetries();
        Symmetricals = Symmetricals.add(symmetries > 0 ? 1 : 0);
        RotSym = RotSym.add(uint256(symmetries >> 4 & 1));
        Y0Sym = Y0Sym.add(uint256(symmetries >> 3 & 1));
        X0Sym = X0Sym.add(uint256(symmetries >> 2 & 1));
        XYSym = XYSym.add(uint256(symmetries >> 1 & 1));
        XnYSym = XnYSym.add(uint256(symmetries & 1));
        clovers.setAllSymmetries(Symmetricals, RotSym, Y0Sym, X0Sym, XYSym, XnYSym);
    }
     
    function removeSymmetries(uint256 tokenId) private {
        uint256 Symmetricals;
        uint256 RotSym;
        uint256 Y0Sym;
        uint256 X0Sym;
        uint256 XYSym;
        uint256 XnYSym;
        (Symmetricals,
        RotSym,
        Y0Sym,
        X0Sym,
        XYSym,
        XnYSym) = clovers.getAllSymmetries();
        uint256 symmetries = clovers.getSymmetries(tokenId);
        Symmetricals = Symmetricals.sub(symmetries > 0 ? 1 : 0);
        RotSym = RotSym.sub(uint256(symmetries >> 4 & 1));
        Y0Sym = Y0Sym.sub(uint256(symmetries >> 3 & 1));
        X0Sym = X0Sym.sub(uint256(symmetries >> 2 & 1));
        XYSym = XYSym.sub(uint256(symmetries >> 1 & 1));
        XnYSym = XnYSym.sub(uint256(symmetries & 1));
        clovers.setAllSymmetries(Symmetricals, RotSym, Y0Sym, X0Sym, XYSym, XnYSym);
    }

    function checkSignature(
        uint256 tokenId,
        bytes28[2] memory moves,
        uint256 symmetries,
        bool keep,
        address recepient,
        bytes memory signature,
        address signer
    ) public pure returns (bool) {
        bytes32 hash = toEthSignedMessageHash(getHash(tokenId, moves, symmetries, keep, recepient));
        address result = recover(hash, signature);
        return (result != address(0) && result == signer);
    }

    function getHash(uint256 tokenId, bytes28[2] memory moves, uint256 symmetries, bool keep, address recepient) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(tokenId, moves, symmetries, keep, recepient));
    }
    function recover(bytes32 hash, bytes memory signature) public pure returns (address) {
        return hash.recover(signature);
    }
    function toEthSignedMessageHash(bytes32 hash) public pure returns (bytes32) {
        return hash.toEthSignedMessageHash();
    }
}
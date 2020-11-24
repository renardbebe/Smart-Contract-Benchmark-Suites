 

 

pragma solidity ^0.4.18;

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


    function isValid (bytes28[2] moves) public pure returns (bool) {
        Game memory game = playGame(moves);
        if (game.error) {
            return false;
        } else if (!game.complete) {
            return false;
        } else {
            return true;
        }
    }

    function getGame (bytes28[2] moves) public pure returns (bool error, bool complete, bool symmetrical, bytes16 board, uint8 currentPlayer, uint8 moveKey) {
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

    function playGame (bytes28[2] moves) internal pure returns (Game)  {
        Game memory game;

        game.first32Moves = moves[0];
        game.lastMoves = moves[1];
        game.moveKey = 0;
        game.blackScore = 2;
        game.whiteScore = 2;

        game.error = false;
        game.complete = false;
        game.currentPlayer = BLACK;


         
        game.board = bytes16(340282366920938456379662753540715053055);  

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
        if (!game.error) {
            game.error = false;
            game = isComplete(game);
            game = isSymmetrical(game);
        }
        return game;
    }

    function makeMove (Game memory game, uint8 col, uint8 row) internal pure returns (Game)  {
         
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

    function getPossibleDirections (Game memory game, uint8 col, uint8 row) internal pure returns(int8[2][8], uint8){

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

    function traverseDirection (Game memory game, int8[2] dir, uint8 col, uint8 row) internal pure returns(bytes28, uint8) {
        bytes28 potentialFlips;
        uint8 potentialFlipsLength = 0;

        if (game.currentPlayer == BLACK) {
            uint8 opponentColor = WHITE;
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

    function isComplete (Game memory game) internal pure returns (Game) {

        if (game.moveKey == 60) {
             
            game.complete = true;
            return game;
        } else {
            uint8[2][60] memory empties;
            uint8 emptiesLength = 0;
            for (uint8 i = 0; i < 64; i++) {
                uint8 tile = returnTile(game.board, ((i - (i % 8)) / 8), (i % 8));
                if (tile == EMPTY) {
                    empties[emptiesLength] = [((i - (i % 8)) / 8), (i % 8)];
                    emptiesLength++;
                }
            }
            bool validMovesRemains = false;
            if (emptiesLength > 0) {
                bytes16 board = game.board;
                uint8[2] memory move;
                for (i = 0; i < emptiesLength && !validMovesRemains; i++) {
                    move = empties[i];

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
                game.board = board;
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

    function isSymmetrical (Game memory game) internal pure returns (Game) {
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



     

    function returnSymmetricals (bool RotSym, bool Y0Sym, bool X0Sym, bool XYSym, bool XnYSym) public view returns (uint256) {
        uint256 symmetries = (RotSym ? 1  : 0) << 1;
        symmetries = (symmetries & (Y0Sym ? 1 : 0)) << 1;
        symmetries = (symmetries & (X0Sym ? 1 : 0)) << 1;
        symmetries = (symmetries & (XYSym ? 1 : 0)) << 1;
        symmetries = symmetries & (XnYSym ? 1 : 0);
        return symmetries;
    }


    function returnBytes (bytes16 board, uint8 col, uint8 row) internal pure returns (bytes16) {
        uint128 push = posToPush(col, row);
        return (board >> push) & bytes16(3);
    }

    function turnTile (bytes16 board, uint8 color, uint8 col, uint8 row) internal pure returns (bytes16){
        if (col > 7) revert();
        if (row > 7) revert();
        uint128 push = posToPush(col, row);
        bytes16 mask = bytes16(3) << push; 

        board = ((board ^ mask) & board);

        return board | (bytes16(color) << push);
    }

    function returnTile (bytes16 board, uint8 col, uint8 row) internal pure returns (uint8){
        uint128 push = posToPush(col, row);
        bytes16 tile = (board >> push ) & bytes16(3);
        return uint8(tile);  
    }

    function posToPush (uint8 col, uint8 row) internal pure returns (uint128){
        return uint128(((64) - ((8 * col) + row + 1)) * 2);
    }

    function readMove (bytes28 moveSequence, uint8 moveKey, uint8 movesLength) public pure returns(uint8) {
        bytes28 mask = bytes28(127);
        uint8 push = (movesLength * 7) - (moveKey * 7) - 7;
        return uint8((moveSequence >> push) & mask);
    }

    function addMove (bytes28 moveSequence, uint8 movesLength, uint8 col, uint8 row) internal pure returns (bytes28, uint8) {
        bytes28 move = bytes28(col + (row * 8) + 64);
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

 

pragma solidity ^0.4.24;


 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 

pragma solidity ^0.4.24;



 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

 

pragma solidity ^0.4.24;


 
interface ERC165 {

   
  function supportsInterface(bytes4 _interfaceId)
    external
    view
    returns (bool);
}

 

pragma solidity ^0.4.24;



 
contract ERC721Basic is ERC165 {
  event Transfer(
    address indexed _from,
    address indexed _to,
    uint256 indexed _tokenId
  );
  event Approval(
    address indexed _owner,
    address indexed _approved,
    uint256 indexed _tokenId
  );
  event ApprovalForAll(
    address indexed _owner,
    address indexed _operator,
    bool _approved
  );

  function balanceOf(address _owner) public view returns (uint256 _balance);
  function ownerOf(uint256 _tokenId) public view returns (address _owner);
  function exists(uint256 _tokenId) public view returns (bool _exists);

  function approve(address _to, uint256 _tokenId) public;
  function getApproved(uint256 _tokenId)
    public view returns (address _operator);

  function setApprovalForAll(address _operator, bool _approved) public;
  function isApprovedForAll(address _owner, address _operator)
    public view returns (bool);

  function transferFrom(address _from, address _to, uint256 _tokenId) public;
  function safeTransferFrom(address _from, address _to, uint256 _tokenId)
    public;

  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes _data
  )
    public;
}

 

pragma solidity ^0.4.24;



 
contract ERC721Enumerable is ERC721Basic {
  function totalSupply() public view returns (uint256);
  function tokenOfOwnerByIndex(
    address _owner,
    uint256 _index
  )
    public
    view
    returns (uint256 _tokenId);

  function tokenByIndex(uint256 _index) public view returns (uint256);
}


 
contract ERC721Metadata is ERC721Basic {
  function name() external view returns (string _name);
  function symbol() external view returns (string _symbol);
  function tokenURI(uint256 _tokenId) public view returns (string);
}


 
contract ERC721 is ERC721Basic, ERC721Enumerable, ERC721Metadata {
}

 

pragma solidity ^0.4.24;


 
contract ERC721Receiver {
   
  bytes4 internal constant ERC721_RECEIVED = 0x150b7a02;

   
  function onERC721Received(
    address _operator,
    address _from,
    uint256 _tokenId,
    bytes _data
  )
    public
    returns(bytes4);
}

 

pragma solidity ^0.4.24;


 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
     
     
     
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    return a / b;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

 

pragma solidity ^0.4.24;


 
library AddressUtils {

   
  function isContract(address addr) internal view returns (bool) {
    uint256 size;
     
     
     
     
     
     
     
    assembly { size := extcodesize(addr) }
    return size > 0;
  }

}

 

pragma solidity ^0.4.24;



 
contract SupportsInterfaceWithLookup is ERC165 {
  bytes4 public constant InterfaceId_ERC165 = 0x01ffc9a7;
   

   
  mapping(bytes4 => bool) internal supportedInterfaces;

   
  constructor()
    public
  {
    _registerInterface(InterfaceId_ERC165);
  }

   
  function supportsInterface(bytes4 _interfaceId)
    external
    view
    returns (bool)
  {
    return supportedInterfaces[_interfaceId];
  }

   
  function _registerInterface(bytes4 _interfaceId)
    internal
  {
    require(_interfaceId != 0xffffffff);
    supportedInterfaces[_interfaceId] = true;
  }
}

 

pragma solidity ^0.4.24;







 
contract ERC721BasicToken is SupportsInterfaceWithLookup, ERC721Basic {

  bytes4 private constant InterfaceId_ERC721 = 0x80ac58cd;
   

  bytes4 private constant InterfaceId_ERC721Exists = 0x4f558e79;
   

  using SafeMath for uint256;
  using AddressUtils for address;

   
   
  bytes4 private constant ERC721_RECEIVED = 0x150b7a02;

   
  mapping (uint256 => address) internal tokenOwner;

   
  mapping (uint256 => address) internal tokenApprovals;

   
  mapping (address => uint256) internal ownedTokensCount;

   
  mapping (address => mapping (address => bool)) internal operatorApprovals;

   
  modifier onlyOwnerOf(uint256 _tokenId) {
    require(ownerOf(_tokenId) == msg.sender);
    _;
  }

   
  modifier canTransfer(uint256 _tokenId) {
    require(isApprovedOrOwner(msg.sender, _tokenId));
    _;
  }

  constructor()
    public
  {
     
    _registerInterface(InterfaceId_ERC721);
    _registerInterface(InterfaceId_ERC721Exists);
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
    require(_owner != address(0));
    return ownedTokensCount[_owner];
  }

   
  function ownerOf(uint256 _tokenId) public view returns (address) {
    address owner = tokenOwner[_tokenId];
    require(owner != address(0));
    return owner;
  }

   
  function exists(uint256 _tokenId) public view returns (bool) {
    address owner = tokenOwner[_tokenId];
    return owner != address(0);
  }

   
  function approve(address _to, uint256 _tokenId) public {
    address owner = ownerOf(_tokenId);
    require(_to != owner);
    require(msg.sender == owner || isApprovedForAll(owner, msg.sender));

    tokenApprovals[_tokenId] = _to;
    emit Approval(owner, _to, _tokenId);
  }

   
  function getApproved(uint256 _tokenId) public view returns (address) {
    return tokenApprovals[_tokenId];
  }

   
  function setApprovalForAll(address _to, bool _approved) public {
    require(_to != msg.sender);
    operatorApprovals[msg.sender][_to] = _approved;
    emit ApprovalForAll(msg.sender, _to, _approved);
  }

   
  function isApprovedForAll(
    address _owner,
    address _operator
  )
    public
    view
    returns (bool)
  {
    return operatorApprovals[_owner][_operator];
  }

   
  function transferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    public
    canTransfer(_tokenId)
  {
    require(_from != address(0));
    require(_to != address(0));

    clearApproval(_from, _tokenId);
    removeTokenFrom(_from, _tokenId);
    addTokenTo(_to, _tokenId);

    emit Transfer(_from, _to, _tokenId);
  }

   
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    public
    canTransfer(_tokenId)
  {
     
    safeTransferFrom(_from, _to, _tokenId, "");
  }

   
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes _data
  )
    public
    canTransfer(_tokenId)
  {
    transferFrom(_from, _to, _tokenId);
     
    require(checkAndCallSafeTransfer(_from, _to, _tokenId, _data));
  }

   
  function isApprovedOrOwner(
    address _spender,
    uint256 _tokenId
  )
    internal
    view
    returns (bool)
  {
    address owner = ownerOf(_tokenId);
     
     
     
    return (
      _spender == owner ||
      getApproved(_tokenId) == _spender ||
      isApprovedForAll(owner, _spender)
    );
  }

   
  function _mint(address _to, uint256 _tokenId) internal {
    require(_to != address(0));
    addTokenTo(_to, _tokenId);
    emit Transfer(address(0), _to, _tokenId);
  }

   
  function _burn(address _owner, uint256 _tokenId) internal {
    clearApproval(_owner, _tokenId);
    removeTokenFrom(_owner, _tokenId);
    emit Transfer(_owner, address(0), _tokenId);
  }

   
  function clearApproval(address _owner, uint256 _tokenId) internal {
    require(ownerOf(_tokenId) == _owner);
    if (tokenApprovals[_tokenId] != address(0)) {
      tokenApprovals[_tokenId] = address(0);
    }
  }

   
  function addTokenTo(address _to, uint256 _tokenId) internal {
    require(tokenOwner[_tokenId] == address(0));
    tokenOwner[_tokenId] = _to;
    ownedTokensCount[_to] = ownedTokensCount[_to].add(1);
  }

   
  function removeTokenFrom(address _from, uint256 _tokenId) internal {
    require(ownerOf(_tokenId) == _from);
    ownedTokensCount[_from] = ownedTokensCount[_from].sub(1);
    tokenOwner[_tokenId] = address(0);
  }

   
  function checkAndCallSafeTransfer(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes _data
  )
    internal
    returns (bool)
  {
    if (!_to.isContract()) {
      return true;
    }
    bytes4 retval = ERC721Receiver(_to).onERC721Received(
      msg.sender, _from, _tokenId, _data);
    return (retval == ERC721_RECEIVED);
  }
}

 

pragma solidity ^0.4.24;





 
contract ERC721Token is SupportsInterfaceWithLookup, ERC721BasicToken, ERC721 {

  bytes4 private constant InterfaceId_ERC721Enumerable = 0x780e9d63;
   

  bytes4 private constant InterfaceId_ERC721Metadata = 0x5b5e139f;
   

   
  string internal name_;

   
  string internal symbol_;

   
  mapping(address => uint256[]) internal ownedTokens;

   
  mapping(uint256 => uint256) internal ownedTokensIndex;

   
  uint256[] internal allTokens;

   
  mapping(uint256 => uint256) internal allTokensIndex;

   
  mapping(uint256 => string) internal tokenURIs;

   
  constructor(string _name, string _symbol) public {
    name_ = _name;
    symbol_ = _symbol;

     
    _registerInterface(InterfaceId_ERC721Enumerable);
    _registerInterface(InterfaceId_ERC721Metadata);
  }

   
  function name() external view returns (string) {
    return name_;
  }

   
  function symbol() external view returns (string) {
    return symbol_;
  }

   
  function tokenURI(uint256 _tokenId) public view returns (string) {
    require(exists(_tokenId));
    return tokenURIs[_tokenId];
  }

   
  function tokenOfOwnerByIndex(
    address _owner,
    uint256 _index
  )
    public
    view
    returns (uint256)
  {
    require(_index < balanceOf(_owner));
    return ownedTokens[_owner][_index];
  }

   
  function totalSupply() public view returns (uint256) {
    return allTokens.length;
  }

   
  function tokenByIndex(uint256 _index) public view returns (uint256) {
    require(_index < totalSupply());
    return allTokens[_index];
  }

   
  function _setTokenURI(uint256 _tokenId, string _uri) internal {
    require(exists(_tokenId));
    tokenURIs[_tokenId] = _uri;
  }

   
  function addTokenTo(address _to, uint256 _tokenId) internal {
    super.addTokenTo(_to, _tokenId);
    uint256 length = ownedTokens[_to].length;
    ownedTokens[_to].push(_tokenId);
    ownedTokensIndex[_tokenId] = length;
  }

   
  function removeTokenFrom(address _from, uint256 _tokenId) internal {
    super.removeTokenFrom(_from, _tokenId);

    uint256 tokenIndex = ownedTokensIndex[_tokenId];
    uint256 lastTokenIndex = ownedTokens[_from].length.sub(1);
    uint256 lastToken = ownedTokens[_from][lastTokenIndex];

    ownedTokens[_from][tokenIndex] = lastToken;
    ownedTokens[_from][lastTokenIndex] = 0;
     
     
     

    ownedTokens[_from].length--;
    ownedTokensIndex[_tokenId] = 0;
    ownedTokensIndex[lastToken] = tokenIndex;
  }

   
  function _mint(address _to, uint256 _tokenId) internal {
    super._mint(_to, _tokenId);

    allTokensIndex[_tokenId] = allTokens.length;
    allTokens.push(_tokenId);
  }

   
  function _burn(address _owner, uint256 _tokenId) internal {
    super._burn(_owner, _tokenId);

     
    if (bytes(tokenURIs[_tokenId]).length != 0) {
      delete tokenURIs[_tokenId];
    }

     
    uint256 tokenIndex = allTokensIndex[_tokenId];
    uint256 lastTokenIndex = allTokens.length.sub(1);
    uint256 lastToken = allTokens[lastTokenIndex];

    allTokens[tokenIndex] = lastToken;
    allTokens[lastTokenIndex] = 0;

    allTokens.length--;
    allTokensIndex[_tokenId] = 0;
    allTokensIndex[lastToken] = tokenIndex;
  }

}

 

pragma solidity ^0.4.24;


 
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

   
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

   
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

 

pragma solidity ^0.4.24;


 
contract Admin {
  mapping (address => bool) public admins;


  event AdminshipRenounced(address indexed previousAdmin);
  event AdminshipTransferred(
    address indexed previousAdmin,
    address indexed newAdmin
  );


   
  constructor() public {
    admins[msg.sender] = true;
  }

   
  modifier onlyAdmin() {
    require(admins[msg.sender]);
    _;
  }

  function isAdmin(address _admin) public view returns(bool) {
    return admins[_admin];
  }

   
  function renounceAdminship(address _previousAdmin) public onlyAdmin {
    emit AdminshipRenounced(_previousAdmin);
    admins[_previousAdmin] = false;
  }

   
  function transferAdminship(address _newAdmin) public onlyAdmin {
    _transferAdminship(_newAdmin);
  }

   
  function _transferAdminship(address _newAdmin) internal {
    require(_newAdmin != address(0));
    emit AdminshipTransferred(msg.sender, _newAdmin);
    admins[_newAdmin] = true;
  }
}

 

 

pragma solidity ^0.4.14;

library strings {
    struct slice {
        uint _len;
        uint _ptr;
    }

    function memcpy(uint dest, uint src, uint len) private pure{
         
        for(; len >= 32; len -= 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }

         
        uint mask = 256 ** (32 - len) - 1;
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }

     
    function toSlice(string self) internal pure returns (slice) {
        uint ptr;
        assembly {
            ptr := add(self, 0x20)
        }
        return slice(bytes(self).length, ptr);
    }

     
    function len(bytes32 self) internal pure returns (uint) {
        uint ret;
        if (self == 0)
            return 0;
        if (self & 0xffffffffffffffffffffffffffffffff == 0) {
            ret += 16;
            self = bytes32(uint(self) / 0x100000000000000000000000000000000);
        }
        if (self & 0xffffffffffffffff == 0) {
            ret += 8;
            self = bytes32(uint(self) / 0x10000000000000000);
        }
        if (self & 0xffffffff == 0) {
            ret += 4;
            self = bytes32(uint(self) / 0x100000000);
        }
        if (self & 0xffff == 0) {
            ret += 2;
            self = bytes32(uint(self) / 0x10000);
        }
        if (self & 0xff == 0) {
            ret += 1;
        }
        return 32 - ret;
    }

     
    function toSliceB32(bytes32 self) internal pure returns (slice ret) {
         
        assembly {
            let ptr := mload(0x40)
            mstore(0x40, add(ptr, 0x20))
            mstore(ptr, self)
            mstore(add(ret, 0x20), ptr)
        }
        ret._len = len(self);
    }

     
    function copy(slice self) internal pure returns (slice) {
        return slice(self._len, self._ptr);
    }

     
    function toString(slice self) internal pure returns (string) {
        var ret = new string(self._len);
        uint retptr;
        assembly { retptr := add(ret, 32) }

        memcpy(retptr, self._ptr, self._len);
        return ret;
    }

     
    function len(slice self) internal pure returns (uint l) {
         
        var ptr = self._ptr - 31;
        var end = ptr + self._len;
        for (l = 0; ptr < end; l++) {
            uint8 b;
            assembly { b := and(mload(ptr), 0xFF) }
            if (b < 0x80) {
                ptr += 1;
            } else if(b < 0xE0) {
                ptr += 2;
            } else if(b < 0xF0) {
                ptr += 3;
            } else if(b < 0xF8) {
                ptr += 4;
            } else if(b < 0xFC) {
                ptr += 5;
            } else {
                ptr += 6;
            }
        }
    }

     
    function empty(slice self) internal pure returns (bool) {
        return self._len == 0;
    }

     
    function compare(slice self, slice other) internal pure returns (int) {
        uint shortest = self._len;
        if (other._len < self._len)
            shortest = other._len;

        var selfptr = self._ptr;
        var otherptr = other._ptr;
        for (uint idx = 0; idx < shortest; idx += 32) {
            uint a;
            uint b;
            assembly {
                a := mload(selfptr)
                b := mload(otherptr)
            }
            if (a != b) {
                 
                uint mask = ~(2 ** (8 * (32 - shortest + idx)) - 1);
                var diff = (a & mask) - (b & mask);
                if (diff != 0)
                    return int(diff);
            }
            selfptr += 32;
            otherptr += 32;
        }
        return int(self._len) - int(other._len);
    }

     
    function equals(slice self, slice other) internal pure returns (bool) {
        return compare(self, other) == 0;
    }

     
    function nextRune(slice self, slice rune) internal pure returns (slice) {
        rune._ptr = self._ptr;

        if (self._len == 0) {
            rune._len = 0;
            return rune;
        }

        uint len;
        uint b;
         
        assembly { b := and(mload(sub(mload(add(self, 32)), 31)), 0xFF) }
        if (b < 0x80) {
            len = 1;
        } else if(b < 0xE0) {
            len = 2;
        } else if(b < 0xF0) {
            len = 3;
        } else {
            len = 4;
        }

         
        if (len > self._len) {
            rune._len = self._len;
            self._ptr += self._len;
            self._len = 0;
            return rune;
        }

        self._ptr += len;
        self._len -= len;
        rune._len = len;
        return rune;
    }

     
    function nextRune(slice self) internal pure returns (slice ret) {
        nextRune(self, ret);
    }

     
    function ord(slice self) internal pure returns (uint ret) {
        if (self._len == 0) {
            return 0;
        }

        uint word;
        uint length;
        uint divisor = 2 ** 248;

         
        assembly { word:= mload(mload(add(self, 32))) }
        var b = word / divisor;
        if (b < 0x80) {
            ret = b;
            length = 1;
        } else if(b < 0xE0) {
            ret = b & 0x1F;
            length = 2;
        } else if(b < 0xF0) {
            ret = b & 0x0F;
            length = 3;
        } else {
            ret = b & 0x07;
            length = 4;
        }

         
        if (length > self._len) {
            return 0;
        }

        for (uint i = 1; i < length; i++) {
            divisor = divisor / 256;
            b = (word / divisor) & 0xFF;
            if (b & 0xC0 != 0x80) {
                 
                return 0;
            }
            ret = (ret * 64) | (b & 0x3F);
        }

        return ret;
    }

     
    function keccak(slice self) internal pure returns (bytes32 ret) {
        assembly {
            ret := keccak256(mload(add(self, 32)), mload(self))
        }
    }

     
    function startsWith(slice self, slice needle) internal pure returns (bool) {
        if (self._len < needle._len) {
            return false;
        }

        if (self._ptr == needle._ptr) {
            return true;
        }

        bool equal;
        assembly {
            let length := mload(needle)
            let selfptr := mload(add(self, 0x20))
            let needleptr := mload(add(needle, 0x20))
            equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
        }
        return equal;
    }

     
    function beyond(slice self, slice needle) internal pure returns (slice) {
        if (self._len < needle._len) {
            return self;
        }

        bool equal = true;
        if (self._ptr != needle._ptr) {
            assembly {
                let length := mload(needle)
                let selfptr := mload(add(self, 0x20))
                let needleptr := mload(add(needle, 0x20))
                equal := eq(sha3(selfptr, length), sha3(needleptr, length))
            }
        }

        if (equal) {
            self._len -= needle._len;
            self._ptr += needle._len;
        }

        return self;
    }

     
    function endsWith(slice self, slice needle) internal pure returns (bool) {
        if (self._len < needle._len) {
            return false;
        }

        var selfptr = self._ptr + self._len - needle._len;

        if (selfptr == needle._ptr) {
            return true;
        }

        bool equal;
        assembly {
            let length := mload(needle)
            let needleptr := mload(add(needle, 0x20))
            equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
        }

        return equal;
    }

     
    function until(slice self, slice needle) internal pure returns (slice) {
        if (self._len < needle._len) {
            return self;
        }

        var selfptr = self._ptr + self._len - needle._len;
        bool equal = true;
        if (selfptr != needle._ptr) {
            assembly {
                let length := mload(needle)
                let needleptr := mload(add(needle, 0x20))
                equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
            }
        }

        if (equal) {
            self._len -= needle._len;
        }

        return self;
    }

     
     
    function findPtr(uint selflen, uint selfptr, uint needlelen, uint needleptr) private returns (uint) {
        uint ptr;
        uint idx;

        if (needlelen <= selflen) {
            if (needlelen <= 32) {
                 
                assembly {
                    let mask := not(sub(exp(2, mul(8, sub(32, needlelen))), 1))
                    let needledata := and(mload(needleptr), mask)
                    let end := add(selfptr, sub(selflen, needlelen))
                    ptr := selfptr
                    loop:
                    jumpi(exit, eq(and(mload(ptr), mask), needledata))
                    ptr := add(ptr, 1)
                    jumpi(loop, lt(sub(ptr, 1), end))
                    ptr := add(selfptr, selflen)
                    exit:
                }
                return ptr;
            } else {
                 
                bytes32 hash;
                assembly { hash := sha3(needleptr, needlelen) }
                ptr = selfptr;
                for (idx = 0; idx <= selflen - needlelen; idx++) {
                    bytes32 testHash;
                    assembly { testHash := sha3(ptr, needlelen) }
                    if (hash == testHash)
                        return ptr;
                    ptr += 1;
                }
            }
        }
        return selfptr + selflen;
    }

     
     
    function rfindPtr(uint selflen, uint selfptr, uint needlelen, uint needleptr) private returns (uint) {
        uint ptr;

        if (needlelen <= selflen) {
            if (needlelen <= 32) {
                 
                assembly {
                    let mask := not(sub(exp(2, mul(8, sub(32, needlelen))), 1))
                    let needledata := and(mload(needleptr), mask)
                    ptr := add(selfptr, sub(selflen, needlelen))
                    loop:
                    jumpi(ret, eq(and(mload(ptr), mask), needledata))
                    ptr := sub(ptr, 1)
                    jumpi(loop, gt(add(ptr, 1), selfptr))
                    ptr := selfptr
                    jump(exit)
                    ret:
                    ptr := add(ptr, needlelen)
                    exit:
                }
                return ptr;
            } else {
                 
                bytes32 hash;
                assembly { hash := sha3(needleptr, needlelen) }
                ptr = selfptr + (selflen - needlelen);
                while (ptr >= selfptr) {
                    bytes32 testHash;
                    assembly { testHash := sha3(ptr, needlelen) }
                    if (hash == testHash)
                        return ptr + needlelen;
                    ptr -= 1;
                }
            }
        }
        return selfptr;
    }

     
    function find(slice self, slice needle) internal returns (slice) {
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr);
        self._len -= ptr - self._ptr;
        self._ptr = ptr;
        return self;
    }

     
    function rfind(slice self, slice needle) internal returns (slice) {
        uint ptr = rfindPtr(self._len, self._ptr, needle._len, needle._ptr);
        self._len = ptr - self._ptr;
        return self;
    }

     
    function split(slice self, slice needle, slice token) internal returns (slice) {
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr);
        token._ptr = self._ptr;
        token._len = ptr - self._ptr;
        if (ptr == self._ptr + self._len) {
             
            self._len = 0;
        } else {
            self._len -= token._len + needle._len;
            self._ptr = ptr + needle._len;
        }
        return token;
    }

     
    function split(slice self, slice needle) internal returns (slice token) {
        split(self, needle, token);
    }

     
    function rsplit(slice self, slice needle, slice token) internal returns (slice) {
        uint ptr = rfindPtr(self._len, self._ptr, needle._len, needle._ptr);
        token._ptr = ptr;
        token._len = self._len - (ptr - self._ptr);
        if (ptr == self._ptr) {
             
            self._len = 0;
        } else {
            self._len -= token._len + needle._len;
        }
        return token;
    }

     
    function rsplit(slice self, slice needle) internal returns (slice token) {
        rsplit(self, needle, token);
    }

     
    function count(slice self, slice needle) internal returns (uint cnt) {
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr) + needle._len;
        while (ptr <= self._ptr + self._len) {
            cnt++;
            ptr = findPtr(self._len - (ptr - self._ptr), ptr, needle._len, needle._ptr) + needle._len;
        }
    }

     
    function contains(slice self, slice needle) internal returns (bool) {
        return rfindPtr(self._len, self._ptr, needle._len, needle._ptr) != self._ptr;
    }

     
    function concat(slice self, slice other) internal pure returns (string) {
        var ret = new string(self._len + other._len);
        uint retptr;
        assembly { retptr := add(ret, 32) }
        memcpy(retptr, self._ptr, self._len);
        memcpy(retptr + self._len, other._ptr, other._len);
        return ret;
    }

     
    function join(slice self, slice[] parts) internal pure returns (string) {
        if (parts.length == 0)
            return "";

        uint length = self._len * (parts.length - 1);
        for(uint i = 0; i < parts.length; i++)
            length += parts[i]._len;

        var ret = new string(length);
        uint retptr;
        assembly { retptr := add(ret, 32) }

        for(i = 0; i < parts.length; i++) {
            memcpy(retptr, parts[i]._ptr, parts[i]._len);
            retptr += parts[i]._len;
            if (i < parts.length - 1) {
                memcpy(retptr, self._ptr, self._len);
                retptr += self._len;
            }
        }

        return ret;
    }
}

 

pragma solidity ^0.4.18;

 



contract CloversMetadata {
    using strings for *;

    function tokenURI(uint _tokenId) public view returns (string _infoUrl) {
        string memory base = "https://api.clovers.network/clovers/metadata/0x";
        string memory id = uint2hexstr(_tokenId);
        string memory suffix = "";
        return base.toSlice().concat(id.toSlice()).toSlice().concat(suffix.toSlice());
    }
    function uint2hexstr(uint i) internal pure returns (string) {
        if (i == 0) return "0";
        uint j = i;
        uint length;
        while (j != 0) {
            length++;
            j = j >> 4;
        }
        uint mask = 15;
        bytes memory bstr = new bytes(length);
        uint k = length - 1;
        while (i != 0){
            uint curr = (i & mask);
            bstr[k--] = curr > 9 ? byte(55 + curr) : byte(48 + curr);  
            i = i >> 4;
        }
        return string(bstr);
    }
}

 

pragma solidity ^0.4.18;

 







contract Clovers is ERC721Token, Admin, Ownable {

    address public cloversMetadata;
    uint256 public totalSymmetries;
    uint256[5] symmetries;  
    address public cloversController;
    address public clubTokenController;

    mapping (uint256 => Clover) public clovers;
    struct Clover {
        bool keep;
        uint256 symmetries;
        bytes28[2] cloverMoves;
        uint256 blockMinted;
        uint256 rewards;
    }

    modifier onlyOwnerOrController() {
        require(
            msg.sender == cloversController ||
            owner == msg.sender ||
            admins[msg.sender]
        );
        _;
    }


     
    modifier canTransfer(uint256 _tokenId) {
        require(isApprovedOrOwner(msg.sender, _tokenId) || msg.sender == cloversController);
        _;
    }

    constructor(string name, string symbol) public
        ERC721Token(name, symbol)
    { }

    function () public payable {}

    function implementation() public view returns (address) {
        return cloversMetadata;
    }

    function tokenURI(uint _tokenId) public view returns (string _infoUrl) {
        return CloversMetadata(cloversMetadata).tokenURI(_tokenId);
    }
    function getHash(bytes28[2] moves) public pure returns (bytes32) {
        return keccak256(moves);
    }
    function getKeep(uint256 _tokenId) public view returns (bool) {
        return clovers[_tokenId].keep;
    }
    function getBlockMinted(uint256 _tokenId) public view returns (uint256) {
        return clovers[_tokenId].blockMinted;
    }
    function getCloverMoves(uint256 _tokenId) public view returns (bytes28[2]) {
        return clovers[_tokenId].cloverMoves;
    }
    function getReward(uint256 _tokenId) public view returns (uint256) {
        return clovers[_tokenId].rewards;
    }
    function getSymmetries(uint256 _tokenId) public view returns (uint256) {
        return clovers[_tokenId].symmetries;
    }
    function getAllSymmetries() public view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        return (
            totalSymmetries,
            symmetries[0],  
            symmetries[1],  
            symmetries[2],  
            symmetries[3],  
            symmetries[4]  
        );
    }

 

     
    function moveEth(address _to, uint256 _amount) public onlyOwnerOrController {
        require(_amount <= this.balance);
        _to.transfer(_amount);
    }
     
    function moveToken(address _to, uint256 _amount, address _token) public onlyOwnerOrController returns (bool) {
        require(_amount <= ERC20(_token).balanceOf(this));
        return ERC20(_token).transfer(_to, _amount);
    }
     
    function approveToken(address _to, uint256 _amount, address _token) public onlyOwnerOrController returns (bool) {
        return ERC20(_token).approve(_to, _amount);
    }

     
    function setKeep(uint256 _tokenId, bool value) public onlyOwnerOrController {
        clovers[_tokenId].keep = value;
    }
    function setBlockMinted(uint256 _tokenId, uint256 value) public onlyOwnerOrController {
        clovers[_tokenId].blockMinted = value;
    }
    function setCloverMoves(uint256 _tokenId, bytes28[2] moves) public onlyOwnerOrController {
        clovers[_tokenId].cloverMoves = moves;
    }
    function setReward(uint256 _tokenId, uint256 _amount) public onlyOwnerOrController {
        clovers[_tokenId].rewards = _amount;
    }
    function setSymmetries(uint256 _tokenId, uint256 _symmetries) public onlyOwnerOrController {
        clovers[_tokenId].symmetries = _symmetries;
    }

     
    function setAllSymmetries(uint256 _totalSymmetries, uint256 RotSym, uint256 Y0Sym, uint256 X0Sym, uint256 XYSym, uint256 XnYSym) public onlyOwnerOrController {
        totalSymmetries = _totalSymmetries;
        symmetries[0] = RotSym;
        symmetries[1] = Y0Sym;
        symmetries[2] = X0Sym;
        symmetries[3] = XYSym;
        symmetries[4] = XnYSym;
    }

     
    function deleteClover(uint256 _tokenId) public onlyOwnerOrController {
        delete(clovers[_tokenId]);
        unmint(_tokenId);
    }
     
    function updateCloversControllerAddress(address _cloversController) public onlyOwner {
        require(_cloversController != 0);
        cloversController = _cloversController;
    }



     
    function updateCloversMetadataAddress(address _cloversMetadata) public onlyOwner {
        require(_cloversMetadata != 0);
        cloversMetadata = _cloversMetadata;
    }

    function updateClubTokenController(address _clubTokenController) public onlyOwner {
        require(_clubTokenController != 0);
        clubTokenController = _clubTokenController;
    }

     
    function mint (address _to, uint256 _tokenId) public onlyOwnerOrController {
        super._mint(_to, _tokenId);
        setApprovalForAll(clubTokenController, true);
    }


    function mintMany(address[] _tos, uint256[] _tokenIds, bytes28[2][] memory _movess, uint256[] _symmetries) public onlyAdmin {
        require(_tos.length == _tokenIds.length && _tokenIds.length == _movess.length && _movess.length == _symmetries.length);
        for (uint256 i = 0; i < _tos.length; i++) {
            address _to = _tos[i];
            uint256 _tokenId = _tokenIds[i];
            bytes28[2] memory _moves = _movess[i];
            uint256 _symmetry = _symmetries[i];
            setCloverMoves(_tokenId, _moves);
            if (_symmetry > 0) {
                setSymmetries(_tokenId, _symmetry);
            }
            super._mint(_to, _tokenId);
            setApprovalForAll(clubTokenController, true);
        }
    }

     
    function unmint (uint256 _tokenId) public onlyOwnerOrController {
        super._burn(ownerOf(_tokenId), _tokenId);
    }


}

 

pragma solidity ^0.4.24;




 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}

 

pragma solidity ^0.4.24;




 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(
    address _owner,
    address _spender
   )
    public
    view
    returns (uint256)
  {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(
    address _spender,
    uint256 _addedValue
  )
    public
    returns (bool)
  {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(
    address _spender,
    uint256 _subtractedValue
  )
    public
    returns (bool)
  {
    uint256 oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

 

pragma solidity ^0.4.24;



 
contract DetailedERC20 is ERC20 {
  string public name;
  string public symbol;
  uint8 public decimals;

  constructor(string _name, string _symbol, uint8 _decimals) public {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
  }
}

 

pragma solidity ^0.4.24;




 
contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  modifier hasMintPermission() {
    require(msg.sender == owner);
    _;
  }

   
  function mint(
    address _to,
    uint256 _amount
  )
    hasMintPermission
    canMint
    public
    returns (bool)
  {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }

   
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}

 

pragma solidity ^0.4.24;



 
contract BurnableToken is BasicToken {

  event Burn(address indexed burner, uint256 value);

   
  function burn(uint256 _value) public {
    _burn(msg.sender, _value);
  }

  function _burn(address _who, uint256 _value) internal {
    require(_value <= balances[_who]);
     
     

    balances[_who] = balances[_who].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    emit Burn(_who, _value);
    emit Transfer(_who, address(0), _value);
  }
}

 

pragma solidity ^0.4.18;

 





contract ClubToken is StandardToken, DetailedERC20, MintableToken, BurnableToken {

    address public cloversController;
    address public clubTokenController;

    modifier hasMintPermission() {
      require(
          msg.sender == clubTokenController ||
          msg.sender == cloversController ||
          msg.sender == owner
      );
      _;
    }

     
    constructor(string _name, string _symbol, uint8 _decimals) public
        DetailedERC20(_name, _symbol, _decimals)
    {}

    function () public payable {}

    function updateClubTokenControllerAddress(address _clubTokenController) public onlyOwner {
        require(_clubTokenController != 0);
        clubTokenController = _clubTokenController;
    }

    function updateCloversControllerAddress(address _cloversController) public onlyOwner {
        require(_cloversController != 0);
        cloversController = _cloversController;
    }


       
      function transferFrom(
        address _from,
        address _to,
        uint256 _value
      )
        public
        returns (bool)
      {
        require(_to != address(0));
        require(_value <= balances[_from]);
        if (msg.sender != cloversController && msg.sender != clubTokenController) {
            require(_value <= allowed[_from][msg.sender]);
            allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        }
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(_from, _to, _value);
        return true;
      }

     
    function burn(uint256 _value) public {
        _value;
        revert();
    }

     
    function burn(address _burner, uint256 _value) public hasMintPermission {
      _burn(_burner, _value);
    }

     
    function moveEth(address _to, uint256 _amount) public hasMintPermission {
        require(this.balance >= _amount);
        _to.transfer(_amount);
    }
     
    function moveToken(address _to, uint256 _amount, address _token) public hasMintPermission returns (bool) {
        require(_amount <= StandardToken(_token).balanceOf(this));
        return StandardToken(_token).transfer(_to, _amount);
    }
     
    function approveToken(address _to, uint256 _amount, address _token) public hasMintPermission returns (bool) {
        return StandardToken(_token).approve(_to, _amount);
    }
}

 

pragma solidity ^0.4.24;

 
contract IBancorFormula {
    function calculatePurchaseReturn(uint256 _supply, uint256 _connectorBalance, uint32 _connectorWeight, uint256 _depositAmount) public view returns (uint256);
    function calculateSaleReturn(uint256 _supply, uint256 _connectorBalance, uint32 _connectorWeight, uint256 _sellAmount) public view returns (uint256);
    function calculateCrossConnectorReturn(uint256 _fromConnectorBalance, uint32 _fromConnectorWeight, uint256 _toConnectorBalance, uint32 _toConnectorWeight, uint256 _amount) public view returns (uint256);
}

 

pragma solidity ^0.4.24;

 
contract Utils {
     
    constructor() public {
    }

     
    modifier greaterThanZero(uint256 _amount) {
        require(_amount > 0);
        _;
    }

     
    modifier validAddress(address _address) {
        require(_address != address(0));
        _;
    }

     
    modifier notThis(address _address) {
        require(_address != address(this));
        _;
    }

     

     
    function safeAdd(uint256 _x, uint256 _y) internal pure returns (uint256) {
        uint256 z = _x + _y;
        assert(z >= _x);
        return z;
    }

     
    function safeSub(uint256 _x, uint256 _y) internal pure returns (uint256) {
        assert(_x >= _y);
        return _x - _y;
    }

     
    function safeMul(uint256 _x, uint256 _y) internal pure returns (uint256) {
        uint256 z = _x * _y;
        assert(_x == 0 || z / _x == _y);
        return z;
    }
}

 

pragma solidity ^0.4.24;



contract BancorFormula is IBancorFormula, Utils {
    string public version = '0.3';

    uint256 private constant ONE = 1;
    uint32 private constant MAX_WEIGHT = 1000000;
    uint8 private constant MIN_PRECISION = 32;
    uint8 private constant MAX_PRECISION = 127;

     
    uint256 private constant FIXED_1 = 0x080000000000000000000000000000000;
    uint256 private constant FIXED_2 = 0x100000000000000000000000000000000;
    uint256 private constant MAX_NUM = 0x200000000000000000000000000000000;

     
    uint256 private constant LN2_NUMERATOR   = 0x3f80fe03f80fe03f80fe03f80fe03f8;
    uint256 private constant LN2_DENOMINATOR = 0x5b9de1d10bf4103d647b0955897ba80;

     
    uint256 private constant OPT_LOG_MAX_VAL = 0x15bf0a8b1457695355fb8ac404e7a79e3;
    uint256 private constant OPT_EXP_MAX_VAL = 0x800000000000000000000000000000000;

     
    uint256[128] private maxExpArray;
    constructor() public {
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
        maxExpArray[ 32] = 0x1c35fedd14ffffffffffffffffffffffff;
        maxExpArray[ 33] = 0x1b0ce43b323fffffffffffffffffffffff;
        maxExpArray[ 34] = 0x19f0028ec1ffffffffffffffffffffffff;
        maxExpArray[ 35] = 0x18ded91f0e7fffffffffffffffffffffff;
        maxExpArray[ 36] = 0x17d8ec7f0417ffffffffffffffffffffff;
        maxExpArray[ 37] = 0x16ddc6556cdbffffffffffffffffffffff;
        maxExpArray[ 38] = 0x15ecf52776a1ffffffffffffffffffffff;
        maxExpArray[ 39] = 0x15060c256cb2ffffffffffffffffffffff;
        maxExpArray[ 40] = 0x1428a2f98d72ffffffffffffffffffffff;
        maxExpArray[ 41] = 0x13545598e5c23fffffffffffffffffffff;
        maxExpArray[ 42] = 0x1288c4161ce1dfffffffffffffffffffff;
        maxExpArray[ 43] = 0x11c592761c666fffffffffffffffffffff;
        maxExpArray[ 44] = 0x110a688680a757ffffffffffffffffffff;
        maxExpArray[ 45] = 0x1056f1b5bedf77ffffffffffffffffffff;
        maxExpArray[ 46] = 0x0faadceceeff8bffffffffffffffffffff;
        maxExpArray[ 47] = 0x0f05dc6b27edadffffffffffffffffffff;
        maxExpArray[ 48] = 0x0e67a5a25da4107fffffffffffffffffff;
        maxExpArray[ 49] = 0x0dcff115b14eedffffffffffffffffffff;
        maxExpArray[ 50] = 0x0d3e7a392431239fffffffffffffffffff;
        maxExpArray[ 51] = 0x0cb2ff529eb71e4fffffffffffffffffff;
        maxExpArray[ 52] = 0x0c2d415c3db974afffffffffffffffffff;
        maxExpArray[ 53] = 0x0bad03e7d883f69bffffffffffffffffff;
        maxExpArray[ 54] = 0x0b320d03b2c343d5ffffffffffffffffff;
        maxExpArray[ 55] = 0x0abc25204e02828dffffffffffffffffff;
        maxExpArray[ 56] = 0x0a4b16f74ee4bb207fffffffffffffffff;
        maxExpArray[ 57] = 0x09deaf736ac1f569ffffffffffffffffff;
        maxExpArray[ 58] = 0x0976bd9952c7aa957fffffffffffffffff;
        maxExpArray[ 59] = 0x09131271922eaa606fffffffffffffffff;
        maxExpArray[ 60] = 0x08b380f3558668c46fffffffffffffffff;
        maxExpArray[ 61] = 0x0857ddf0117efa215bffffffffffffffff;
        maxExpArray[ 62] = 0x07ffffffffffffffffffffffffffffffff;
        maxExpArray[ 63] = 0x07abbf6f6abb9d087fffffffffffffffff;
        maxExpArray[ 64] = 0x075af62cbac95f7dfa7fffffffffffffff;
        maxExpArray[ 65] = 0x070d7fb7452e187ac13fffffffffffffff;
        maxExpArray[ 66] = 0x06c3390ecc8af379295fffffffffffffff;
        maxExpArray[ 67] = 0x067c00a3b07ffc01fd6fffffffffffffff;
        maxExpArray[ 68] = 0x0637b647c39cbb9d3d27ffffffffffffff;
        maxExpArray[ 69] = 0x05f63b1fc104dbd39587ffffffffffffff;
        maxExpArray[ 70] = 0x05b771955b36e12f7235ffffffffffffff;
        maxExpArray[ 71] = 0x057b3d49dda84556d6f6ffffffffffffff;
        maxExpArray[ 72] = 0x054183095b2c8ececf30ffffffffffffff;
        maxExpArray[ 73] = 0x050a28be635ca2b888f77fffffffffffff;
        maxExpArray[ 74] = 0x04d5156639708c9db33c3fffffffffffff;
        maxExpArray[ 75] = 0x04a23105873875bd52dfdfffffffffffff;
        maxExpArray[ 76] = 0x0471649d87199aa990756fffffffffffff;
        maxExpArray[ 77] = 0x04429a21a029d4c1457cfbffffffffffff;
        maxExpArray[ 78] = 0x0415bc6d6fb7dd71af2cb3ffffffffffff;
        maxExpArray[ 79] = 0x03eab73b3bbfe282243ce1ffffffffffff;
        maxExpArray[ 80] = 0x03c1771ac9fb6b4c18e229ffffffffffff;
        maxExpArray[ 81] = 0x0399e96897690418f785257fffffffffff;
        maxExpArray[ 82] = 0x0373fc456c53bb779bf0ea9fffffffffff;
        maxExpArray[ 83] = 0x034f9e8e490c48e67e6ab8bfffffffffff;
        maxExpArray[ 84] = 0x032cbfd4a7adc790560b3337ffffffffff;
        maxExpArray[ 85] = 0x030b50570f6e5d2acca94613ffffffffff;
        maxExpArray[ 86] = 0x02eb40f9f620fda6b56c2861ffffffffff;
        maxExpArray[ 87] = 0x02cc8340ecb0d0f520a6af58ffffffffff;
        maxExpArray[ 88] = 0x02af09481380a0a35cf1ba02ffffffffff;
        maxExpArray[ 89] = 0x0292c5bdd3b92ec810287b1b3fffffffff;
        maxExpArray[ 90] = 0x0277abdcdab07d5a77ac6d6b9fffffffff;
        maxExpArray[ 91] = 0x025daf6654b1eaa55fd64df5efffffffff;
        maxExpArray[ 92] = 0x0244c49c648baa98192dce88b7ffffffff;
        maxExpArray[ 93] = 0x022ce03cd5619a311b2471268bffffffff;
        maxExpArray[ 94] = 0x0215f77c045fbe885654a44a0fffffffff;
        maxExpArray[ 95] = 0x01ffffffffffffffffffffffffffffffff;
        maxExpArray[ 96] = 0x01eaefdbdaaee7421fc4d3ede5ffffffff;
        maxExpArray[ 97] = 0x01d6bd8b2eb257df7e8ca57b09bfffffff;
        maxExpArray[ 98] = 0x01c35fedd14b861eb0443f7f133fffffff;
        maxExpArray[ 99] = 0x01b0ce43b322bcde4a56e8ada5afffffff;
        maxExpArray[100] = 0x019f0028ec1fff007f5a195a39dfffffff;
        maxExpArray[101] = 0x018ded91f0e72ee74f49b15ba527ffffff;
        maxExpArray[102] = 0x017d8ec7f04136f4e5615fd41a63ffffff;
        maxExpArray[103] = 0x016ddc6556cdb84bdc8d12d22e6fffffff;
        maxExpArray[104] = 0x015ecf52776a1155b5bd8395814f7fffff;
        maxExpArray[105] = 0x015060c256cb23b3b3cc3754cf40ffffff;
        maxExpArray[106] = 0x01428a2f98d728ae223ddab715be3fffff;
        maxExpArray[107] = 0x013545598e5c23276ccf0ede68034fffff;
        maxExpArray[108] = 0x01288c4161ce1d6f54b7f61081194fffff;
        maxExpArray[109] = 0x011c592761c666aa641d5a01a40f17ffff;
        maxExpArray[110] = 0x0110a688680a7530515f3e6e6cfdcdffff;
        maxExpArray[111] = 0x01056f1b5bedf75c6bcb2ce8aed428ffff;
        maxExpArray[112] = 0x00faadceceeff8a0890f3875f008277fff;
        maxExpArray[113] = 0x00f05dc6b27edad306388a600f6ba0bfff;
        maxExpArray[114] = 0x00e67a5a25da41063de1495d5b18cdbfff;
        maxExpArray[115] = 0x00dcff115b14eedde6fc3aa5353f2e4fff;
        maxExpArray[116] = 0x00d3e7a3924312399f9aae2e0f868f8fff;
        maxExpArray[117] = 0x00cb2ff529eb71e41582cccd5a1ee26fff;
        maxExpArray[118] = 0x00c2d415c3db974ab32a51840c0b67edff;
        maxExpArray[119] = 0x00bad03e7d883f69ad5b0a186184e06bff;
        maxExpArray[120] = 0x00b320d03b2c343d4829abd6075f0cc5ff;
        maxExpArray[121] = 0x00abc25204e02828d73c6e80bcdb1a95bf;
        maxExpArray[122] = 0x00a4b16f74ee4bb2040a1ec6c15fbbf2df;
        maxExpArray[123] = 0x009deaf736ac1f569deb1b5ae3f36c130f;
        maxExpArray[124] = 0x00976bd9952c7aa957f5937d790ef65037;
        maxExpArray[125] = 0x009131271922eaa6064b73a22d0bd4f2bf;
        maxExpArray[126] = 0x008b380f3558668c46c91c49a2f8e967b9;
        maxExpArray[127] = 0x00857ddf0117efa215952912839f6473e6;
    }

     
    function calculatePurchaseReturn(uint256 _supply, uint256 _connectorBalance, uint32 _connectorWeight, uint256 _depositAmount) public view returns (uint256) {
         
        require(_supply > 0 && _connectorBalance > 0 && _connectorWeight > 0 && _connectorWeight <= MAX_WEIGHT);

         
        if (_depositAmount == 0)
            return 0;

         
        if (_connectorWeight == MAX_WEIGHT)
            return safeMul(_supply, _depositAmount) / _connectorBalance;

        uint256 result;
        uint8 precision;
        uint256 baseN = safeAdd(_depositAmount, _connectorBalance);
        (result, precision) = power(baseN, _connectorBalance, _connectorWeight, MAX_WEIGHT);
        uint256 temp = safeMul(_supply, result) >> precision;
        return temp - _supply;
    }

     
    function calculateSaleReturn(uint256 _supply, uint256 _connectorBalance, uint32 _connectorWeight, uint256 _sellAmount) public view returns (uint256) {
         
        require(_supply > 0 && _connectorBalance > 0 && _connectorWeight > 0 && _connectorWeight <= MAX_WEIGHT && _sellAmount <= _supply);

         
        if (_sellAmount == 0)
            return 0;

         
        if (_sellAmount == _supply)
            return _connectorBalance;

         
        if (_connectorWeight == MAX_WEIGHT)
            return safeMul(_connectorBalance, _sellAmount) / _supply;

        uint256 result;
        uint8 precision;
        uint256 baseD = _supply - _sellAmount;
        (result, precision) = power(_supply, baseD, MAX_WEIGHT, _connectorWeight);
        uint256 temp1 = safeMul(_connectorBalance, result);
        uint256 temp2 = _connectorBalance << precision;
        return (temp1 - temp2) / result;
    }

     
    function calculateCrossConnectorReturn(uint256 _fromConnectorBalance, uint32 _fromConnectorWeight, uint256 _toConnectorBalance, uint32 _toConnectorWeight, uint256 _amount) public view returns (uint256) {
         
        require(_fromConnectorBalance > 0 && _fromConnectorWeight > 0 && _fromConnectorWeight <= MAX_WEIGHT && _toConnectorBalance > 0 && _toConnectorWeight > 0 && _toConnectorWeight <= MAX_WEIGHT);

         
        if (_fromConnectorWeight == _toConnectorWeight)
            return safeMul(_toConnectorBalance, _amount) / safeAdd(_fromConnectorBalance, _amount);

        uint256 result;
        uint8 precision;
        uint256 baseN = safeAdd(_fromConnectorBalance, _amount);
        (result, precision) = power(baseN, _fromConnectorBalance, _fromConnectorWeight, _toConnectorWeight);
        uint256 temp1 = safeMul(_toConnectorBalance, result);
        uint256 temp2 = _toConnectorBalance << precision;
        return (temp1 - temp2) / result;
    }

     
    function power(uint256 _baseN, uint256 _baseD, uint32 _expN, uint32 _expD) internal view returns (uint256, uint8) {
        require(_baseN < MAX_NUM);

        uint256 baseLog;
        uint256 base = _baseN * FIXED_1 / _baseD;
        if (base < OPT_LOG_MAX_VAL) {
            baseLog = optimalLog(base);
        }
        else {
            baseLog = generalLog(base);
        }

        uint256 baseLogTimesExp = baseLog * _expN / _expD;
        if (baseLogTimesExp < OPT_EXP_MAX_VAL) {
            return (optimalExp(baseLogTimesExp), MAX_PRECISION);
        }
        else {
            uint8 precision = findPositionInMaxExpArray(baseLogTimesExp);
            return (generalExp(baseLogTimesExp >> (MAX_PRECISION - precision), precision), precision);
        }
    }

     
    function generalLog(uint256 x) internal pure returns (uint256) {
        uint256 res = 0;

         
        if (x >= FIXED_2) {
            uint8 count = floorLog2(x / FIXED_1);
            x >>= count;  
            res = count * FIXED_1;
        }

         
        if (x > FIXED_1) {
            for (uint8 i = MAX_PRECISION; i > 0; --i) {
                x = (x * x) / FIXED_1;  
                if (x >= FIXED_2) {
                    x >>= 1;  
                    res += ONE << (i - 1);
                }
            }
        }

        return res * LN2_NUMERATOR / LN2_DENOMINATOR;
    }

     
    function floorLog2(uint256 _n) internal pure returns (uint8) {
        uint8 res = 0;

        if (_n < 256) {
             
            while (_n > 1) {
                _n >>= 1;
                res += 1;
            }
        }
        else {
             
            for (uint8 s = 128; s > 0; s >>= 1) {
                if (_n >= (ONE << s)) {
                    _n >>= s;
                    res |= s;
                }
            }
        }

        return res;
    }

     
    function findPositionInMaxExpArray(uint256 _x) internal view returns (uint8) {
        uint8 lo = MIN_PRECISION;
        uint8 hi = MAX_PRECISION;

        while (lo + 1 < hi) {
            uint8 mid = (lo + hi) / 2;
            if (maxExpArray[mid] >= _x)
                lo = mid;
            else
                hi = mid;
        }

        if (maxExpArray[hi] >= _x)
            return hi;
        if (maxExpArray[lo] >= _x)
            return lo;

        require(false);
        return 0;
    }

     
    function generalExp(uint256 _x, uint8 _precision) internal pure returns (uint256) {
        uint256 xi = _x;
        uint256 res = 0;

        xi = (xi * _x) >> _precision; res += xi * 0x3442c4e6074a82f1797f72ac0000000;  
        xi = (xi * _x) >> _precision; res += xi * 0x116b96f757c380fb287fd0e40000000;  
        xi = (xi * _x) >> _precision; res += xi * 0x045ae5bdd5f0e03eca1ff4390000000;  
        xi = (xi * _x) >> _precision; res += xi * 0x00defabf91302cd95b9ffda50000000;  
        xi = (xi * _x) >> _precision; res += xi * 0x002529ca9832b22439efff9b8000000;  
        xi = (xi * _x) >> _precision; res += xi * 0x00054f1cf12bd04e516b6da88000000;  
        xi = (xi * _x) >> _precision; res += xi * 0x0000a9e39e257a09ca2d6db51000000;  
        xi = (xi * _x) >> _precision; res += xi * 0x000012e066e7b839fa050c309000000;  
        xi = (xi * _x) >> _precision; res += xi * 0x000001e33d7d926c329a1ad1a800000;  
        xi = (xi * _x) >> _precision; res += xi * 0x0000002bee513bdb4a6b19b5f800000;  
        xi = (xi * _x) >> _precision; res += xi * 0x00000003a9316fa79b88eccf2a00000;  
        xi = (xi * _x) >> _precision; res += xi * 0x0000000048177ebe1fa812375200000;  
        xi = (xi * _x) >> _precision; res += xi * 0x0000000005263fe90242dcbacf00000;  
        xi = (xi * _x) >> _precision; res += xi * 0x000000000057e22099c030d94100000;  
        xi = (xi * _x) >> _precision; res += xi * 0x0000000000057e22099c030d9410000;  
        xi = (xi * _x) >> _precision; res += xi * 0x00000000000052b6b54569976310000;  
        xi = (xi * _x) >> _precision; res += xi * 0x00000000000004985f67696bf748000;  
        xi = (xi * _x) >> _precision; res += xi * 0x000000000000003dea12ea99e498000;  
        xi = (xi * _x) >> _precision; res += xi * 0x00000000000000031880f2214b6e000;  
        xi = (xi * _x) >> _precision; res += xi * 0x000000000000000025bcff56eb36000;  
        xi = (xi * _x) >> _precision; res += xi * 0x000000000000000001b722e10ab1000;  
        xi = (xi * _x) >> _precision; res += xi * 0x0000000000000000001317c70077000;  
        xi = (xi * _x) >> _precision; res += xi * 0x00000000000000000000cba84aafa00;  
        xi = (xi * _x) >> _precision; res += xi * 0x00000000000000000000082573a0a00;  
        xi = (xi * _x) >> _precision; res += xi * 0x00000000000000000000005035ad900;  
        xi = (xi * _x) >> _precision; res += xi * 0x000000000000000000000002f881b00;  
        xi = (xi * _x) >> _precision; res += xi * 0x0000000000000000000000001b29340;  
        xi = (xi * _x) >> _precision; res += xi * 0x00000000000000000000000000efc40;  
        xi = (xi * _x) >> _precision; res += xi * 0x0000000000000000000000000007fe0;  
        xi = (xi * _x) >> _precision; res += xi * 0x0000000000000000000000000000420;  
        xi = (xi * _x) >> _precision; res += xi * 0x0000000000000000000000000000021;  
        xi = (xi * _x) >> _precision; res += xi * 0x0000000000000000000000000000001;  

        return res / 0x688589cc0e9505e2f2fee5580000000 + _x + (ONE << _precision);  
    }

     
    function optimalLog(uint256 x) internal pure returns (uint256) {
        uint256 res = 0;

        uint256 y;
        uint256 z;
        uint256 w;

        if (x >= 0xd3094c70f034de4b96ff7d5b6f99fcd8) {res += 0x40000000000000000000000000000000; x = x * FIXED_1 / 0xd3094c70f034de4b96ff7d5b6f99fcd8;}  
        if (x >= 0xa45af1e1f40c333b3de1db4dd55f29a7) {res += 0x20000000000000000000000000000000; x = x * FIXED_1 / 0xa45af1e1f40c333b3de1db4dd55f29a7;}  
        if (x >= 0x910b022db7ae67ce76b441c27035c6a1) {res += 0x10000000000000000000000000000000; x = x * FIXED_1 / 0x910b022db7ae67ce76b441c27035c6a1;}  
        if (x >= 0x88415abbe9a76bead8d00cf112e4d4a8) {res += 0x08000000000000000000000000000000; x = x * FIXED_1 / 0x88415abbe9a76bead8d00cf112e4d4a8;}  
        if (x >= 0x84102b00893f64c705e841d5d4064bd3) {res += 0x04000000000000000000000000000000; x = x * FIXED_1 / 0x84102b00893f64c705e841d5d4064bd3;}  
        if (x >= 0x8204055aaef1c8bd5c3259f4822735a2) {res += 0x02000000000000000000000000000000; x = x * FIXED_1 / 0x8204055aaef1c8bd5c3259f4822735a2;}  
        if (x >= 0x810100ab00222d861931c15e39b44e99) {res += 0x01000000000000000000000000000000; x = x * FIXED_1 / 0x810100ab00222d861931c15e39b44e99;}  
        if (x >= 0x808040155aabbbe9451521693554f733) {res += 0x00800000000000000000000000000000; x = x * FIXED_1 / 0x808040155aabbbe9451521693554f733;}  

        z = y = x - FIXED_1;
        w = y * y / FIXED_1;
        res += z * (0x100000000000000000000000000000000 - y) / 0x100000000000000000000000000000000; z = z * w / FIXED_1;  
        res += z * (0x0aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa - y) / 0x200000000000000000000000000000000; z = z * w / FIXED_1;  
        res += z * (0x099999999999999999999999999999999 - y) / 0x300000000000000000000000000000000; z = z * w / FIXED_1;  
        res += z * (0x092492492492492492492492492492492 - y) / 0x400000000000000000000000000000000; z = z * w / FIXED_1;  
        res += z * (0x08e38e38e38e38e38e38e38e38e38e38e - y) / 0x500000000000000000000000000000000; z = z * w / FIXED_1;  
        res += z * (0x08ba2e8ba2e8ba2e8ba2e8ba2e8ba2e8b - y) / 0x600000000000000000000000000000000; z = z * w / FIXED_1;  
        res += z * (0x089d89d89d89d89d89d89d89d89d89d89 - y) / 0x700000000000000000000000000000000; z = z * w / FIXED_1;  
        res += z * (0x088888888888888888888888888888888 - y) / 0x800000000000000000000000000000000;                       

        return res;
    }

     
    function optimalExp(uint256 x) internal pure returns (uint256) {
        uint256 res = 0;

        uint256 y;
        uint256 z;

        z = y = x % 0x10000000000000000000000000000000;  
        z = z * y / FIXED_1; res += z * 0x10e1b3be415a0000;  
        z = z * y / FIXED_1; res += z * 0x05a0913f6b1e0000;  
        z = z * y / FIXED_1; res += z * 0x0168244fdac78000;  
        z = z * y / FIXED_1; res += z * 0x004807432bc18000;  
        z = z * y / FIXED_1; res += z * 0x000c0135dca04000;  
        z = z * y / FIXED_1; res += z * 0x0001b707b1cdc000;  
        z = z * y / FIXED_1; res += z * 0x000036e0f639b800;  
        z = z * y / FIXED_1; res += z * 0x00000618fee9f800;  
        z = z * y / FIXED_1; res += z * 0x0000009c197dcc00;  
        z = z * y / FIXED_1; res += z * 0x0000000e30dce400;  
        z = z * y / FIXED_1; res += z * 0x000000012ebd1300;  
        z = z * y / FIXED_1; res += z * 0x0000000017499f00;  
        z = z * y / FIXED_1; res += z * 0x0000000001a9d480;  
        z = z * y / FIXED_1; res += z * 0x00000000001c6380;  
        z = z * y / FIXED_1; res += z * 0x000000000001c638;  
        z = z * y / FIXED_1; res += z * 0x0000000000001ab8;  
        z = z * y / FIXED_1; res += z * 0x000000000000017c;  
        z = z * y / FIXED_1; res += z * 0x0000000000000014;  
        z = z * y / FIXED_1; res += z * 0x0000000000000001;  
        res = res / 0x21c3677c82b40000 + y + FIXED_1;  

        if ((x & 0x010000000000000000000000000000000) != 0) res = res * 0x1c3d6a24ed82218787d624d3e5eba95f9 / 0x18ebef9eac820ae8682b9793ac6d1e776;  
        if ((x & 0x020000000000000000000000000000000) != 0) res = res * 0x18ebef9eac820ae8682b9793ac6d1e778 / 0x1368b2fc6f9609fe7aceb46aa619baed4;  
        if ((x & 0x040000000000000000000000000000000) != 0) res = res * 0x1368b2fc6f9609fe7aceb46aa619baed5 / 0x0bc5ab1b16779be3575bd8f0520a9f21f;  
        if ((x & 0x080000000000000000000000000000000) != 0) res = res * 0x0bc5ab1b16779be3575bd8f0520a9f21e / 0x0454aaa8efe072e7f6ddbab84b40a55c9;  
        if ((x & 0x100000000000000000000000000000000) != 0) res = res * 0x0454aaa8efe072e7f6ddbab84b40a55c5 / 0x00960aadc109e7a3bf4578099615711ea;  
        if ((x & 0x200000000000000000000000000000000) != 0) res = res * 0x00960aadc109e7a3bf4578099615711d7 / 0x0002bf84208204f5977f9a8cf01fdce3d;  
        if ((x & 0x400000000000000000000000000000000) != 0) res = res * 0x0002bf84208204f5977f9a8cf01fdc307 / 0x0000003c6ab775dd0b95b4cbee7e65d11;  

        return res;
    }
}

 

pragma solidity ^0.4.18;

 





contract ClubTokenController is BancorFormula, Admin, Ownable {
    event Buy(address buyer, uint256 tokens, uint256 value, uint256 poolBalance, uint256 tokenSupply);
    event Sell(address seller, uint256 tokens, uint256 value, uint256 poolBalance, uint256 tokenSupply);

    bool public paused;
    address public clubToken;
    address public simpleCloversMarket;
    address public curationMarket;
    address public support;

     
    uint256 public virtualSupply;
    uint256 public virtualBalance;
    uint32 public reserveRatio;  

    constructor(address _clubToken) public {
        clubToken = _clubToken;
        paused = true;
    }

    function () public payable {
        buy(msg.sender);
    }

    modifier notPaused() {
        require(!paused || owner == msg.sender || admins[tx.origin], "Contract must not be paused");
        _;
    }

    function poolBalance() public constant returns(uint256) {
        return clubToken.balance;
    }

     
    function getBuy(uint256 buyValue) public constant returns(uint256) {
        return calculatePurchaseReturn(
            safeAdd(ClubToken(clubToken).totalSupply(), virtualSupply),
            safeAdd(poolBalance(), virtualBalance),
            reserveRatio,
            buyValue);
    }


     

    function getSell(uint256 sellAmount) public constant returns(uint256) {
        return calculateSaleReturn(
            safeAdd(ClubToken(clubToken).totalSupply(), virtualSupply),
            safeAdd(poolBalance(), virtualBalance),
            reserveRatio,
            sellAmount);
    }

    function updatePaused(bool _paused) public onlyOwner {
        paused = _paused;
    }

     
    function updateReserveRatio(uint32 _reserveRatio) public onlyOwner returns(bool){
        reserveRatio = _reserveRatio;
        return true;
    }

     
    function updateVirtualSupply(uint256 _virtualSupply) public onlyOwner returns(bool){
        virtualSupply = _virtualSupply;
        return true;
    }

     
    function updateVirtualBalance(uint256 _virtualBalance) public onlyOwner returns(bool){
        virtualBalance = _virtualBalance;
        return true;
    }
     
     

     
    function updateSimpleCloversMarket(address _simpleCloversMarket) public onlyOwner returns(bool){
        simpleCloversMarket = _simpleCloversMarket;
        return true;
    }

     
    function updateCurationMarket(address _curationMarket) public onlyOwner returns(bool){
        curationMarket = _curationMarket;
        return true;
    }

     
    function updateSupport(address _support) public onlyOwner returns(bool){
        support = _support;
        return true;
    }

     
    function donate() public payable {
        require(msg.value > 0);
         
        clubToken.transfer(msg.value);
    }

    function burn(address from, uint256 amount) public {
        require(msg.sender == simpleCloversMarket);
        ClubToken(clubToken).burn(from, amount);
    }

    function transferFrom(address from, address to, uint256 amount) public {
        require(msg.sender == simpleCloversMarket || msg.sender == curationMarket || msg.sender == support);
        ClubToken(clubToken).transferFrom(from, to, amount);
    }

     
    function buy(address buyer) public payable notPaused returns(bool) {
        require(msg.value > 0);
        uint256 tokens = getBuy(msg.value);
        require(tokens > 0);
        require(ClubToken(clubToken).mint(buyer, tokens));
         
        clubToken.transfer(msg.value);
        emit Buy(buyer, tokens, msg.value, poolBalance(), ClubToken(clubToken).totalSupply());
    }


     
    function sell(uint256 sellAmount) public notPaused returns(bool) {
        require(sellAmount > 0);
        require(ClubToken(clubToken).balanceOf(msg.sender) >= sellAmount);
        uint256 saleReturn = getSell(sellAmount);
        require(saleReturn > 0);
        require(saleReturn <= poolBalance());
        require(saleReturn <= clubToken.balance);
        ClubToken(clubToken).burn(msg.sender, sellAmount);
         
        ClubToken(clubToken).moveEth(msg.sender, saleReturn);
        emit Sell(msg.sender, sellAmount, saleReturn, poolBalance(), ClubToken(clubToken).totalSupply());
    }


 }

 

pragma solidity ^0.4.24;




 
library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    require(token.transfer(to, value));
  }

  function safeTransferFrom(
    ERC20 token,
    address from,
    address to,
    uint256 value
  )
    internal
  {
    require(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    require(token.approve(spender, value));
  }
}

 

pragma solidity ^0.4.24;





 
contract CanReclaimToken is Ownable {
  using SafeERC20 for ERC20Basic;

   
  function reclaimToken(ERC20Basic token) external onlyOwner {
    uint256 balance = token.balanceOf(this);
    token.safeTransfer(owner, balance);
  }

}

 

pragma solidity ^0.4.24;



 
contract HasNoTokens is CanReclaimToken {

  
  function tokenFallback(address from_, uint256 value_, bytes data_) external {
    from_;
    value_;
    data_;
    revert();
  }

}

 

pragma solidity ^0.4.24;



 
contract HasNoEther is Ownable {

   
  constructor() public payable {
    require(msg.value == 0);
  }

   
  function() external {
  }

   
  function reclaimEther() external onlyOwner {
    owner.transfer(address(this).balance);
  }
}

 

pragma solidity ^0.4.18;

 









contract ISimpleCloversMarket {
    function sell(uint256 _tokenId, uint256 price) public;
} 

contract CloversController is HasNoEther, HasNoTokens {
    event cloverCommitted(bytes32 movesHash, address owner);
    event cloverClaimed(bytes28[2] moves, uint256 tokenId, address owner, uint stake, uint reward, uint256 symmetries, bool keep);
    event stakeRetrieved(uint256 tokenId, address owner, uint stake);
    event cloverChallenged(bytes28[2] moves, uint256 tokenId, address owner, address challenger, uint stake);

    using SafeMath for uint256;
    bool public paused;
    address public oracle;
    address public clovers;
    address public clubToken;
    address public clubTokenController;
    address public simpleCloversMarket;
    address public curationMarket;

    uint256 public gasLastUpdated_fastGasPrice_averageGasPrice_safeLowGasPrice;
    uint256 public gasBlockMargin = 240;  

    uint256 public basePrice;
    uint256 public priceMultiplier;
    uint256 public payMultiplier;
    uint256 public stakeAmount;
    uint256 public stakePeriod;
    uint256 public constant oneGwei = 1000000000;
    uint256 public marginOfError = 3;
    struct Commit {
        bool collected;
        uint256 stake;
        address committer;
    }

    mapping (bytes32 => Commit) public commits;

    modifier notPaused() {
        require(!paused, "Must not be paused");
        _;
    }

    modifier onlyOwnerOrOracle () {
        require(msg.sender == owner || msg.sender == oracle);
        _;
    }

    constructor(address _clovers, address _clubToken, address _clubTokenController) public {
        clovers = _clovers;
        clubToken = _clubToken;
        clubTokenController = _clubTokenController;
        paused = true;
    }
     
    function getStake(bytes32 movesHash) public view returns (uint256) {
        return commits[movesHash].stake;
    }
     
    function getCommit(bytes32 movesHash) public view returns (address) {
        return commits[movesHash].committer;
    }
     
    function getMovesHash(uint _tokenId) public constant returns (bytes32) {
        return keccak256(Clovers(clovers).getCloverMoves(_tokenId));
    }
     
    function isValid(bytes28[2] moves) public constant returns (bool) {
        Reversi.Game memory game = Reversi.playGame(moves);
        return isValidGame(game.error, game.complete);
    }

     
    function isValidGame(bool error, bool complete) public pure returns (bool) {
        if (error) return false;
        if (!complete) return false;
        return true;
    }
     
    function isVerified(uint256 _tokenId) public constant returns (bool) {
        uint256 _blockMinted = Clovers(clovers).getBlockMinted(_tokenId);
        if(_blockMinted == 0) return false;
        return block.number.sub(_blockMinted) > stakePeriod;
    }
     
    function calculateReward(uint256 _symmetries) public constant returns (uint256) {
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
        XnYSym) = Clovers(clovers).getAllSymmetries();
        uint256 base = 0;
        if (_symmetries >> 4 & 1 == 1) base = base.add(payMultiplier.mul(Symmetricals + 1).div(RotSym + 1));
        if (_symmetries >> 3 & 1 == 1) base = base.add(payMultiplier.mul(Symmetricals + 1).div(Y0Sym + 1));
        if (_symmetries >> 2 & 1 == 1) base = base.add(payMultiplier.mul(Symmetricals + 1).div(X0Sym + 1));
        if (_symmetries >> 1 & 1 == 1) base = base.add(payMultiplier.mul(Symmetricals + 1).div(XYSym + 1));
        if (_symmetries & 1 == 1) base = base.add(payMultiplier.mul(Symmetricals + 1).div(XnYSym + 1));
        return base;
    }

 

    function getPrice(uint256 _symmetries) public constant returns(uint256) {
        return basePrice.add(calculateReward(_symmetries));
    }

    function updateGasBlockMargin(uint256 _gasBlockMargin) public onlyOwnerOrOracle {
        gasBlockMargin = _gasBlockMargin;
    }

    function updateMarginOfError(uint256 _marginOfError) public onlyOwnerOrOracle {
        marginOfError = _marginOfError;
    }

    function updateGasPrices(uint256 _fastGasPrice, uint256 _averageGasPrice, uint256 _safeLowGasPrice) public onlyOwnerOrOracle {
        uint256 gasLastUpdated = block.number << 192;
        uint256 fastGasPrice = _fastGasPrice << 128;
        uint256 averageGasPrice = _averageGasPrice << 64;
        uint256 safeLowGasPrice = _safeLowGasPrice;
        gasLastUpdated_fastGasPrice_averageGasPrice_safeLowGasPrice = gasLastUpdated | fastGasPrice | averageGasPrice | safeLowGasPrice;
    }

    function gasLastUpdated() public view returns(uint256) {
        return uint256(uint64(gasLastUpdated_fastGasPrice_averageGasPrice_safeLowGasPrice >> 192));
    }
    function fastGasPrice() public view returns(uint256) {
        return uint256(uint64(gasLastUpdated_fastGasPrice_averageGasPrice_safeLowGasPrice >> 128));
    }
    function averageGasPrice() public view returns(uint256) {
        return uint256(uint64(gasLastUpdated_fastGasPrice_averageGasPrice_safeLowGasPrice >> 64));
    }
    function safeLowGasPrice() public view returns(uint256) {
        return uint256(uint64(gasLastUpdated_fastGasPrice_averageGasPrice_safeLowGasPrice));
    }
    function getGasPriceForApp() public view returns(uint256) {
        if (block.number.sub(gasLastUpdated()) > gasBlockMargin) {
            return oneGwei.mul(10);
        } else {
            return fastGasPrice();
        }
    }

     
    function claimClover(bytes28[2] moves, uint256 _tokenId, uint256 _symmetries, bool _keep) public payable notPaused returns (bool) {
        emit cloverClaimed(moves, _tokenId, msg.sender, _tokenId, _tokenId, _symmetries, _keep);

        bytes32 movesHash = keccak256(moves);

        uint256 stakeWithGas = stakeAmount.mul(getGasPriceForApp());
        uint256 _marginOfError = stakeAmount.mul(oneGwei).mul(marginOfError);
        require(msg.value >= stakeWithGas.sub(_marginOfError));
        require(getCommit(movesHash) == 0);

        setCommit(movesHash, msg.sender);
        if (stakeWithGas > 0) {
            setStake(movesHash, stakeWithGas);
            clovers.transfer(stakeWithGas);
        }

        emit cloverCommitted(movesHash, msg.sender);

        require(!Clovers(clovers).exists(_tokenId));
        require(Clovers(clovers).getBlockMinted(_tokenId) == 0);

        Clovers(clovers).setBlockMinted(_tokenId, block.number);
        Clovers(clovers).setCloverMoves(_tokenId, moves);
        Clovers(clovers).setKeep(_tokenId, _keep);

        uint256 reward;
        if (_symmetries > 0) {
            Clovers(clovers).setSymmetries(_tokenId, _symmetries);
            reward = calculateReward(_symmetries);
            Clovers(clovers).setReward(_tokenId, reward);
        }
        uint256 price = basePrice.add(reward);
        if (_keep && price > 0) {
             
             
            if (ClubToken(clubToken).balanceOf(msg.sender) < price) {
                ClubTokenController(clubTokenController).buy.value(msg.value.sub(stakeWithGas))(msg.sender);
            }
             
            ClubToken(clubToken).burn(msg.sender, price);
        }
        Clovers(clovers).mint(clovers, _tokenId);
        emit cloverClaimed(moves, _tokenId, msg.sender, stakeWithGas, reward, _symmetries, _keep);
        return true;
    }


     
     
     
     
     

     
     
     


     
    function retrieveStakeWithGas(uint256 _tokenId, uint256 _fastGasPrice, uint256 _averageGasPrice, uint256 _safeLowGasPrice) public payable returns (bool) {
        require(retrieveStake(_tokenId));
        if (msg.sender == owner || msg.sender == oracle) {
            updateGasPrices(_fastGasPrice, _averageGasPrice, _safeLowGasPrice);
        }
    }

     
    function retrieveStake(uint256 _tokenId) public payable returns (bool) {
        bytes28[2] memory moves = Clovers(clovers).getCloverMoves(_tokenId);
        bytes32 movesHash = keccak256(moves);


        require(!commits[movesHash].collected);
        commits[movesHash].collected = true;

        require(isVerified(_tokenId) || msg.sender == owner || msg.sender == oracle);

        uint256 stake = getStake(movesHash);
        addSymmetries(_tokenId);
        address committer = getCommit(movesHash);
        require(committer == msg.sender || msg.sender == owner || msg.sender == oracle);
        uint256 reward = Clovers(clovers).getReward(_tokenId);
        bool _keep = Clovers(clovers).getKeep(_tokenId);

        if (_keep) {
             
             
            Clovers(clovers).transferFrom(clovers, committer, _tokenId);
        } else {
             
             
             
            ISimpleCloversMarket(simpleCloversMarket).sell(_tokenId, basePrice.add(reward.mul(priceMultiplier)));
            if (reward > 0) {
                require(ClubToken(clubToken).mint(committer, reward));
            }
        }
        if (stake > 0) {
            Clovers(clovers).moveEth(msg.sender, stake);
        }
        emit stakeRetrieved(_tokenId, msg.sender, stake);

        return true;
    }


     
    function convertBytes16ToUint(bytes16 _board) public view returns(uint256 number) {
        for(uint i=0;i<_board.length;i++){
            number = number + uint(_board[i])*(2**(8*(_board.length-(i+1))));
        }
    }


     
    function challengeCloverWithGas(uint256 _tokenId, uint256 _fastGasPrice, uint256 _averageGasPrice, uint256 _safeLowGasPrice) public returns (bool) {
        require(challengeClover(_tokenId));
        if (msg.sender == owner || msg.sender == oracle) {
            updateGasPrices(_fastGasPrice, _averageGasPrice, _safeLowGasPrice);
        }
        return true;
    }
     
    function challengeClover(uint256 _tokenId) public returns (bool) {
        bool valid = true;
        bytes28[2] memory moves = Clovers(clovers).getCloverMoves(_tokenId);

        if (msg.sender != owner && msg.sender != oracle) {
            Reversi.Game memory game = Reversi.playGame(moves);
            if(convertBytes16ToUint(game.board) != _tokenId) {
                valid = false;
            }
            if(valid && isValidGame(game.error, game.complete)) {
                uint256 _symmetries = Clovers(clovers).getSymmetries(_tokenId);
                valid = (_symmetries >> 4 & 1) > 0 == game.RotSym ? valid : false;
                valid = (_symmetries >> 3 & 1) > 0 == game.Y0Sym ? valid : false;
                valid = (_symmetries >> 2 & 1) > 0 == game.X0Sym ? valid : false;
                valid = (_symmetries >> 1 & 1) > 0 == game.XYSym ? valid : false;
                valid = (_symmetries & 1) > 0 == game.XnYSym ? valid : false;
            } else {
                valid = false;
            }
            require(!valid);
        }
        bytes32 movesHash = keccak256(moves);
        uint256 stake = getStake(movesHash);
        if (!isVerified(_tokenId) && stake > 0) {
            Clovers(clovers).moveEth(msg.sender, stake);
        }
        if (commits[movesHash].collected) {
            removeSymmetries(_tokenId);
        }

        address committer = getCommit(movesHash);
        emit cloverChallenged(moves, _tokenId, committer, msg.sender, stake);

        Clovers(clovers).deleteClover(_tokenId);
        deleteCommit(movesHash);
        return true;
    }

    function fixSalePrice(uint256 _tokenId, uint256 _price) public onlyOwnerOrOracle {
        ISimpleCloversMarket(simpleCloversMarket).sell(_tokenId, _price);
    }

     
    function transferFrom(address _from, address _to, uint256 _tokenId) public {
        require(msg.sender == simpleCloversMarket || msg.sender == curationMarket);
        Clovers(clovers).transferFrom(_from, _to, _tokenId);
    }

     
    function updatePaused(bool _paused) public onlyOwner {
        paused = _paused;
    }

     
    function updateCurationMarket(address _curationMarket) public onlyOwner {
        curationMarket = _curationMarket;
    }
     
    function updateOracle(address _oracle) public onlyOwner {
        oracle = _oracle;
    }

     
    function updateSimpleCloversMarket(address _simpleCloversMarket) public onlyOwner {
        simpleCloversMarket = _simpleCloversMarket;
    }

     
    function updateClubTokenController(address _clubTokenController) public onlyOwner {
        clubTokenController = _clubTokenController;
    }
     
    function updateStakeAmount(uint256 _stakeAmount) public onlyOwner {
        stakeAmount = _stakeAmount;
    }
     
    function updateStakePeriod(uint256 _stakePeriod) public onlyOwner {
        stakePeriod = _stakePeriod;
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

     
    function setStake(bytes32 movesHash, uint256 stake) private {
        commits[movesHash].stake = stake;
    }

     
    function setCommit(bytes32 movesHash, address committer) private {
        commits[movesHash].committer = committer;
    }

    function _setCommit(bytes32 movesHash, address committer) public onlyOwner {
        setCommit(movesHash, committer);
    }
    function deleteCommit(bytes32 movesHash) private {
        delete(commits[movesHash]);
    }

     
    function addSymmetries(uint256 _tokenId) private {
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
        XnYSym) = Clovers(clovers).getAllSymmetries();
        uint256 _symmetries = Clovers(clovers).getSymmetries(_tokenId);
        Symmetricals = Symmetricals.add(_symmetries > 0 ? 1 : 0);
        RotSym = RotSym.add(uint256(_symmetries >> 4 & 1));
        Y0Sym = Y0Sym.add(uint256(_symmetries >> 3 & 1));
        X0Sym = X0Sym.add(uint256(_symmetries >> 2 & 1));
        XYSym = XYSym.add(uint256(_symmetries >> 1 & 1));
        XnYSym = XnYSym.add(uint256(_symmetries & 1));
        Clovers(clovers).setAllSymmetries(Symmetricals, RotSym, Y0Sym, X0Sym, XYSym, XnYSym);
    }
     
    function removeSymmetries(uint256 _tokenId) private {
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
        XnYSym) = Clovers(clovers).getAllSymmetries();
        uint256 _symmetries = Clovers(clovers).getSymmetries(_tokenId);
        Symmetricals = Symmetricals.sub(_symmetries > 0 ? 1 : 0);
        RotSym = RotSym.sub(uint256(_symmetries >> 4 & 1));
        Y0Sym = Y0Sym.sub(uint256(_symmetries >> 3 & 1));
        X0Sym = X0Sym.sub(uint256(_symmetries >> 2 & 1));
        XYSym = XYSym.sub(uint256(_symmetries >> 1 & 1));
        XnYSym = XnYSym.sub(uint256(_symmetries & 1));
        Clovers(clovers).setAllSymmetries(Symmetricals, RotSym, Y0Sym, X0Sym, XYSym, XnYSym);
    }

}
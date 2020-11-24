 

pragma solidity ^0.4.18;
contract Lotto {

  address public owner = msg.sender;
  address[] internal playerPool;
  uint seed = 0;
  uint amount = 0.1 ether;
   
  event Payout(address from, address to, uint quantity);
  event BoughtIn(address from);
  event Rejected();

  modifier onlyBy(address _account) {
    require(msg.sender == _account);
    _;
  }
  
  function changeOwner(address _newOwner) public onlyBy(owner) {
    owner = _newOwner;
  }

 
  function random(uint upper) internal returns (uint) {
    seed = uint(keccak256(keccak256(playerPool[playerPool.length -1], seed), now));
    return seed % upper;
  }

   
   
  function buyIn() payable public returns (uint) {
    if (msg.value * 10 != 0.1 ether) {
      revert();
      Rejected();
    } else {
      playerPool.push(msg.sender);
      BoughtIn(msg.sender);
      if (playerPool.length >= 11) {
        selectWinner();
      }
    }
    return playerPool.length;
  }

  function selectWinner() private {
    address winner = playerPool[random(playerPool.length)];
    
    winner.transfer(amount);
    playerPool.length = 0;
    owner.transfer(this.balance);
    Payout(this, winner, amount);
    
  }
  
 
  function refund() public onlyBy(owner) payable {
    require(playerPool.length > 0);
    for (uint i = 0; i < playerPool.length; i++) {
      playerPool[i].transfer(100 finney);
    }
      playerPool.length = 0;
  }
  
 
  function close() public onlyBy(owner) {
    refund();
    selfdestruct(owner);
  }


 
  function () public payable {
    require(msg.value * 10 == 0.1 ether);
    playerPool.push(msg.sender);
    BoughtIn(msg.sender);
    if (playerPool.length >= 11) {
      selectWinner();
    }
  }
}
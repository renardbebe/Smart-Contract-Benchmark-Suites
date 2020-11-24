 

 
contract IntermediateVault  {

   
  bool public isIntermediateVault = true;

   
  address public teamMultisig;

   
  uint256 public unlockedAt;

  event Unlocked();
  event Paid(address sender, uint amount);

  function IntermediateVault(address _teamMultisig, uint _unlockedAt) {

    teamMultisig = _teamMultisig;
    unlockedAt = _unlockedAt;

     
    if(teamMultisig == 0x0)
      throw;

     
     
     
    if(_unlockedAt == 0)
      throw;
  }

   
  function unlock() public {
     
    if(now < unlockedAt) throw;

     
    if(!teamMultisig.send(address(this).balance)) throw;  

    Unlocked();
  }

  function () public payable {
     
    Paid(msg.sender, msg.value);
  }

}
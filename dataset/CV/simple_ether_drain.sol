/* @Labeled: [7] */
pragma solidity ^0.4.22;

contract SimpleEtherDrain {

  function withdrawAllAnyone() {
    msg.sender.transfer(this.balance);
  }

  function () public payable {
  }

}

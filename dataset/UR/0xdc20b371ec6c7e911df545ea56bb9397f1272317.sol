 

pragma solidity ^0.4.0;

contract Fundraiser {

   

  address signer1;
  address signer2;
  bool accept;  

  enum Action {
    None,
    Withdraw,
    Close,
    Open
  }
  
  struct Proposal {
    Action action;
    address destination;
    uint256 amount;
  }
  
  Proposal signer1_proposal;
  Proposal signer2_proposal;

   
  function Fundraiser(address init_signer1,
                      address init_signer2) {
    accept = true;
    signer1 = init_signer1;
    signer2 = init_signer2;
    signer1_proposal.action = Action.None;
    signer2_proposal.action = Action.None;
  }

   
  function () {
    throw;
  }

   

  event Deposit (
                 bytes20 tezos_pk_hash,
                 uint amount
                 );

  function Contribute(bytes24 tezos_pkh_and_chksum) payable {
     
    if (!accept) { throw; }
    bytes20 tezos_pk_hash = bytes20(tezos_pkh_and_chksum);
     
    bytes4 expected_chksum = bytes4(tezos_pkh_and_chksum << 160);
    bytes4 chksum = bytes4(sha256(sha256(tezos_pk_hash)));
     
    if (chksum != expected_chksum) { throw; }
    Deposit(tezos_pk_hash, msg.value);
  }

   

  function Withdraw(address proposed_destination,
                    uint256 proposed_amount) {
     
    if (proposed_amount > this.balance) { throw; }
     
    if (msg.sender == signer1) {
      signer1_proposal.action = Action.Withdraw;
      signer1_proposal.destination = proposed_destination;
      signer1_proposal.amount = proposed_amount;
    } else if (msg.sender == signer2) {
      signer2_proposal.action = Action.Withdraw;
      signer2_proposal.destination = proposed_destination;
      signer2_proposal.amount = proposed_amount;
    } else { throw; }
     
    MaybePerformWithdraw();
  }

  function Close(address proposed_destination) {
     
    if (msg.sender == signer1) {
      signer1_proposal.action = Action.Close;
      signer1_proposal.destination = proposed_destination;
    } else if (msg.sender == signer2) {
      signer2_proposal.action = Action.Close;
      signer2_proposal.destination = proposed_destination;
    } else { throw; }
     
    MaybePerformClose();
  }

  function Open() {
     
    if (msg.sender == signer1) {
      signer1_proposal.action = Action.Open;
    } else if (msg.sender == signer2) {
      signer2_proposal.action = Action.Open;
    } else { throw; }
     
    MaybePerformOpen();
  }

  function MaybePerformWithdraw() internal {
    if (signer1_proposal.action == Action.Withdraw
        && signer2_proposal.action == Action.Withdraw
        && signer1_proposal.amount == signer2_proposal.amount
        && signer1_proposal.destination == signer2_proposal.destination) {
      signer1_proposal.action = Action.None;
      signer2_proposal.action = Action.None;
      signer1_proposal.destination.transfer(signer1_proposal.amount);
    }
  }

  function MaybePerformClose() internal {
    if (signer1_proposal.action == Action.Close
        && signer2_proposal.action == Action.Close
        && signer1_proposal.destination == signer2_proposal.destination) {
      accept = false;
      signer1_proposal.destination.transfer(this.balance);
    }
  }

  function MaybePerformOpen() internal {
    if (signer1_proposal.action == Action.Open
        && signer2_proposal.action == Action.Open) {
      accept = true;
    }
  }
}
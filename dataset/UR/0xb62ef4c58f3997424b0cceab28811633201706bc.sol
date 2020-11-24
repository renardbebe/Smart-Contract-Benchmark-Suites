 

pragma solidity 0.4.11;

contract Fundraiser {

   

  address public signer1;
  address public signer2;

  enum Action {
    None,
    Withdraw
  }
  
  struct Proposal {
    Action action;
    address destination;
    uint256 amount;
  }
  
  Proposal public signer1_proposal;
  Proposal public signer2_proposal;

   
  function Fundraiser(address init_signer1,
                      address init_signer2) {
    signer1 = init_signer1;
    signer2 = init_signer2;
    signer1_proposal.action = Action.None;
    signer2_proposal.action = Action.None;
  }

   
  function () payable {
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

}
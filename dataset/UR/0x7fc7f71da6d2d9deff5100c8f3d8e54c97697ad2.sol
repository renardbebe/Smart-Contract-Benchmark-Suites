 

pragma solidity ^0.4.24;

 
 
 
contract VotingPowerDelegator {
     
    mapping (address => address) public delegations;
    mapping (address => uint)    public delegatedAt;
    event Delegated(address delegator, address beneficiary);

    constructor() public { }

    function delegate(address beneficiary) public {
        if (beneficiary == msg.sender) {
            beneficiary = 0;
        }
        delegations[msg.sender] = beneficiary;
        delegatedAt[msg.sender] = now;
        emit Delegated(msg.sender, beneficiary);
    }

    function () public payable {
        revert();
    }
}
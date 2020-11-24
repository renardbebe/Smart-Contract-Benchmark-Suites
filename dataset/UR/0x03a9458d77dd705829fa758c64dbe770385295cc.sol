 

pragma solidity ^0.4.24;

 
contract PolicyRegistry {
     

     
    event PolicyUpdate(uint indexed _subcourtID, string _policy);

     

    address public governor;
    mapping(uint => string) public policies;

     

     
    modifier onlyByGovernor() {require(governor == msg.sender, "Can only be called by the governor."); _;}

     

     
    constructor(address _governor) public {governor = _governor;}

     

     
    function changeGovernor(address _governor) external onlyByGovernor {governor = _governor;}

     
    function setPolicy(uint _subcourtID, string _policy) external onlyByGovernor {
        emit PolicyUpdate(_subcourtID, policies[_subcourtID]);
        policies[_subcourtID] = _policy;
    }
}
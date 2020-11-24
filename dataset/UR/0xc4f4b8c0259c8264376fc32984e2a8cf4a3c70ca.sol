 

pragma solidity 0.4.15;


 
contract Oracle {

    function isOutcomeSet() public constant returns (bool);
    function getOutcome() public constant returns (int);
}



 
 
contract CentralizedOracle is Oracle {

     
    event OwnerReplacement(address indexed newOwner);
    event OutcomeAssignment(int outcome);

     
    address public owner;
    bytes public ipfsHash;
    bool public isSet;
    int public outcome;

     
    modifier isOwner () {
         
        require(msg.sender == owner);
        _;
    }

     
     
     
    function CentralizedOracle(address _owner, bytes _ipfsHash)
        public
    {
         
        require(_ipfsHash.length == 46);
        owner = _owner;
        ipfsHash = _ipfsHash;
    }

     
     
    function replaceOwner(address newOwner)
        public
        isOwner
    {
         
        require(!isSet);
        owner = newOwner;
        OwnerReplacement(newOwner);
    }

     
     
    function setOutcome(int _outcome)
        public
        isOwner
    {
         
        require(!isSet);
        isSet = true;
        outcome = _outcome;
        OutcomeAssignment(_outcome);
    }

     
     
    function isOutcomeSet()
        public
        constant
        returns (bool)
    {
        return isSet;
    }

     
     
    function getOutcome()
        public
        constant
        returns (int)
    {
        return outcome;
    }
}



 
 
contract CentralizedOracleFactory {

     
    event CentralizedOracleCreation(address indexed creator, CentralizedOracle centralizedOracle, bytes ipfsHash);

     
     
     
     
    function createCentralizedOracle(bytes ipfsHash)
        public
        returns (CentralizedOracle centralizedOracle)
    {
        centralizedOracle = new CentralizedOracle(msg.sender, ipfsHash);
        CentralizedOracleCreation(msg.sender, centralizedOracle, ipfsHash);
    }
}
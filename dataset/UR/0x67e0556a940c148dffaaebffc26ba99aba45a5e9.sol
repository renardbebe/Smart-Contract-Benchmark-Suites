 

pragma solidity ^0.4.21;

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}
 

contract Roles {
     
    address public superAdmin ;

    address public canary ; 


     
    mapping (address => bool) public initiators ; 
    mapping (address => bool) public validators ;  
    address[] validatorsAcct ; 

     
    uint public qtyInitiators ; 

     
     
    uint constant public maxValidators = 20 ; 

     
    uint public qtyValidators ; 

    event superAdminOwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event initiatorAdded(address indexed newInitiator);
    event validatorAdded(address indexed newValidator);
    event initiatorRemoved(address indexed removedInitiator);
    event validatorRemoved(address indexed addedValidator);
    event canaryOwnershipTransferred(address indexed previousOwner, address indexed newOwner) ; 


    
    constructor() public 
    { 
      superAdmin = msg.sender ;
      
    }

    modifier onlySuperAdmin {
        require( msg.sender == superAdmin );
        _;
    }

    modifier onlyCanary {
        require( msg.sender == canary );
        _;
    }

    modifier onlyInitiators {
        require( initiators[msg.sender] );
        _;
    }
    
    modifier onlyValidators {
        require( validators[msg.sender] );
        _;
    }
    

function transferSuperAdminOwnership(address newOwner) public onlySuperAdmin 
{
  require(newOwner != address(0)) ;
  superAdmin = newOwner ;
  emit superAdminOwnershipTransferred(superAdmin, newOwner) ;  
}

function transferCanaryOwnership(address newOwner) public onlySuperAdmin 
{
  require(newOwner != address(0)) ;
  canary = newOwner ;
  emit canaryOwnershipTransferred(canary, newOwner) ;  
}


function addValidator(address _validatorAddr) public onlySuperAdmin 
{
  require(_validatorAddr != address(0));
  require(!validators[_validatorAddr]) ; 
  validators[_validatorAddr] = true ; 
  validatorsAcct.push(_validatorAddr) ; 
  qtyValidators++ ; 
  emit validatorAdded(_validatorAddr) ;  
}

function revokeValidator(address _validatorAddr) public onlySuperAdmin
{
  require(_validatorAddr != address(0));
  require(validators[_validatorAddr]) ; 
  validators[_validatorAddr] = false ; 
  
  for(uint i = 0 ; i < qtyValidators ; i++ ) 
    {
      if (validatorsAcct[i] == _validatorAddr)
         validatorsAcct[i] = address(0) ; 
    }
  qtyValidators-- ; 
  emit validatorRemoved(_validatorAddr) ;  
}

function addInitiator(address _initiatorAddr) public onlySuperAdmin
{
  require(_initiatorAddr != address(0));
  require(!initiators[_initiatorAddr]) ;
  initiators[_initiatorAddr] = true ; 
  qtyInitiators++ ; 
  emit initiatorAdded(_initiatorAddr) ; 
}

function revokeInitiator(address _initiatorAddr) public onlySuperAdmin
{
  require(_initiatorAddr != address(0));
  require(initiators[_initiatorAddr]) ; 
  initiators[_initiatorAddr] = false ;
  qtyInitiators-- ; 
  emit initiatorRemoved(_initiatorAddr) ; 
}
  

}  


contract Storage {

   
   

uint scoringThreshold ; 

struct Proposal 
  {
    string ipfsAddress ; 
    uint timestamp ; 
    uint totalAffirmativeVotes ; 
    uint totalNegativeVotes ; 
    uint totalVoters ; 
    address[] votersAcct ; 
    mapping (address => uint) votes ; 
  }

 
mapping (bytes32 => Proposal) public proposals ; 
uint256 totalProposals ; 

 
bytes32[] rootHashesProposals ; 


 
mapping (bytes32 => string) public ipfsAddresses ; 

 
bytes32[] ipfsAddressesAcct ;

}


contract Registry is Storage, Roles {

    address public logic_contract;

    function setLogicContract(address _c) public onlySuperAdmin returns (bool success){
        logic_contract = _c;
        return true;
    }

    function () payable public {
        address target = logic_contract;
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize)
            let result := delegatecall(gas, target, ptr, calldatasize, 0, 0)
            let size := returndatasize
            returndatacopy(ptr, 0, size)
            switch result
            case 0 { revert(ptr, size) }
            case 1 { return(ptr, size) }
        }
    }
}


contract FKXIdentitiesV1 is Storage, Roles {

using SafeMath for uint256;

event newProposalLogged(address indexed initiator, bytes32 rootHash, string ipfsAddress ) ; 
event newVoteLogged(address indexed voter, bool vote) ;
event newIpfsAddressAdded(bytes32 rootHash, string ipfsAddress ) ; 


constructor() public 
{
  qtyInitiators = 0 ; 
  qtyValidators = 0 ; 
  scoringThreshold = 10 ;
}

 
 
function setScoringThreshold(uint _scoreMax) public onlySuperAdmin
{
  scoringThreshold = _scoreMax ; 
}


 

function propose(bytes32 _rootHash, string _ipfsAddress) public onlyInitiators
{
   
  require(proposals[_rootHash].timestamp == 0 ) ;

   
  address[] memory newVoterAcct = new address[](maxValidators) ; 
  Proposal memory newProposal = Proposal( _ipfsAddress , now, 0, 0, 0, newVoterAcct ) ; 
  proposals[_rootHash] = newProposal ; 
  emit newProposalLogged(msg.sender, _rootHash, _ipfsAddress ) ; 
  rootHashesProposals.push(_rootHash) ; 
  totalProposals++ ; 
}


 
function getIpfsAddress(bytes32 _rootHash) constant public returns (string _ipfsAddress)
{
  return ipfsAddresses[_rootHash] ; 
}

 
function getProposedIpfs(bytes32 _rootHash) constant public returns (string _ipfsAddress)
{
  return proposals[_rootHash].ipfsAddress ; 
}

 
function howManyVoters(bytes32 _rootHash) constant public returns (uint)
{
  return proposals[_rootHash].totalVoters ; 
}

 
 
function vote(bytes32 _rootHash, bool _vote) public onlyValidators
{
   
   
  require(proposals[_rootHash].timestamp > 0) ;

   
   
   
   

  require(proposals[_rootHash].votes[msg.sender]==0) ; 

   
  proposals[_rootHash].votersAcct.push(msg.sender) ; 

  if (_vote ) 
    { 
      proposals[_rootHash].votes[msg.sender] = 1 ;  
      proposals[_rootHash].totalAffirmativeVotes++ ; 
    } 
       else 
        { proposals[_rootHash].votes[msg.sender] = 2 ;  
          proposals[_rootHash].totalNegativeVotes++ ; 
        } 

  emit newVoteLogged(msg.sender, _vote) ;
  proposals[_rootHash].totalVoters++ ; 

   
   
  if ( isConsensusObtained(proposals[_rootHash].totalAffirmativeVotes) )
  {
   
   
   
    bytes memory tempEmptyString = bytes(ipfsAddresses[_rootHash]) ; 
    if ( tempEmptyString.length == 0 ) 
      { 
        ipfsAddresses[_rootHash] = proposals[_rootHash].ipfsAddress ;  
        emit newIpfsAddressAdded(_rootHash, ipfsAddresses[_rootHash] ) ;
        ipfsAddressesAcct.push(_rootHash) ; 

      } 

  }

} 


 
function getTotalQtyIpfsAddresses() constant public returns (uint)
{ 
  return ipfsAddressesAcct.length ; 
}

 
function getOneByOneRootHash(uint _index) constant public returns (bytes32 _rootHash )
{
  require( _index <= (getTotalQtyIpfsAddresses()-1) ) ; 
  return ipfsAddressesAcct[_index] ; 
}

 
 
function isConsensusObtained(uint _totalAffirmativeVotes) constant public returns (bool)
{
  
  

 require (qtyValidators > 0) ;  
 uint dTotalVotes = _totalAffirmativeVotes * 10000 ; 
 return (dTotalVotes / qtyValidators > 5000 ) ;

}


 
 
 
function getProposals(uint _timestampFrom) constant public returns (bytes32 _rootHash)
{
    
   uint max = rootHashesProposals.length ; 

   for(uint i = 0 ; i < max ; i++ ) 
    {
      if (proposals[rootHashesProposals[i]].timestamp > _timestampFrom)
         return rootHashesProposals[i] ; 
    }

}

 
 

function getTimestampProposal(bytes32 _rootHash) constant public returns (uint _timeStamp) 
{
  return proposals[_rootHash].timestamp ; 
}



 
 
function getQtyValidators() constant public returns (uint)
{
  return qtyValidators ; 
}

 
 
 
function getValidatorAddress(int _t) constant public returns (address _validatorAddr)
{
   int x = -1 ; 
   uint size = validatorsAcct.length ; 

   for ( uint i = 0 ; i < size ; i++ )
   {

      if ( validators[validatorsAcct[i]] ) x++ ; 
      if ( x == _t ) return (validatorsAcct[i]) ;  
   }
}
 
 
 

function getStatusForRootHash(bytes32 _rootHash) constant public returns (bool)
{
 bytes memory tempEmptyStringTest = bytes(ipfsAddresses[_rootHash]);  
 if (tempEmptyStringTest.length == 0) {
     
    return false ; 
} else {
     
    return true ; 
}

} 

}  


 
 
 
 
 

 
 

 


 
 
 
 
 
 

  

 
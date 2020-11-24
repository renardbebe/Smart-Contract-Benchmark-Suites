 

pragma solidity ^0.5.1;

 
contract Ownable {
  address public owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
}

 
contract Claimable is Ownable {
  address public pendingOwner;

   
  modifier onlyPendingOwner() {
    require(msg.sender == pendingOwner);
    _;
  }
}  

 
 
 
 

contract Synpatreg is Claimable {
    string public version = '1.1.0';
    mapping(bytes32 => bool) public permlinkSaved;
    
    event SynpatRecord(string indexed permlinkSaved_permlink, bytes32 _hashSha);
    
    function() external { } 
 
     
     
     
     
     
    function writeSha3(string calldata _permlink, bytes32 _hashSha) external  returns (bool){
        bytes32 hash = calculateSha3(_permlink);
        require(!permlinkSaved[hash],"Permalink already exist!");
        permlinkSaved[hash]=true;
        emit SynpatRecord(_permlink, _hashSha);
        return true;
    }
    
     
     
     
     
    function calculateSha3(string memory _hashinput) public pure returns (bytes32){
        return keccak256(bytes(_hashinput)); 
    }
   
    
     
    function kill() external onlyOwner {
        selfdestruct(msg.sender);
    }
}
 

pragma solidity ^0.4.18;

 
contract Ownable {

  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  
  function Ownable() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
  
}

 
contract Mortal is Ownable {
    function executeSelfdestruct() onlyOwner {
        selfdestruct(owner);
    }
}

 
contract CCWhitelist is Mortal {
    
    mapping (address => bool) public whitelisted;

     
     
    function whitelist(address addr) public onlyOwner {
        require(!whitelisted[addr]);
        whitelisted[addr] = true;
    }

     
     
    function unwhitelist(address addr) public onlyOwner {
        require(whitelisted[addr]);
        whitelisted[addr] = false;
    }

     
     
    function bulkWhitelist(address[] arr) public onlyOwner {
        for (uint i = 0; i < arr.length; i++) {
            whitelisted[arr[i]] = true;
        }
    }

     
     
     
    function isWhitelisted(address addr) public constant returns (bool) {
        return whitelisted[addr];
    }   

}
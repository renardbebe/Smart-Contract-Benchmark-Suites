 

pragma solidity ^0.4.19;

 


 
contract Ownable {
  address public owner;
  
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

   
  function Ownable() internal {
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

 
contract Authorizable is Ownable {
  mapping(address => bool) public authorized;
  
  event AuthorizationSet(address indexed addressAuthorized, bool indexed authorization);

    
  function Authorizable() public {
	authorized[msg.sender] = true;
  }

   
  modifier onlyAuthorized() {
    require(authorized[msg.sender]);
    _;
  }

  
  function setAuthorized(address addressAuthorized, bool authorization) onlyOwner public {
    AuthorizationSet(addressAuthorized, authorization);
    authorized[addressAuthorized] = authorization;
  }
  
}

contract CoinCrowdExchangeRates is Ownable, Authorizable {
    uint256 public constant decimals = 18;
    mapping (string  => uint256) rate;
    
    function readRate(string _currency) public view returns (uint256 oneEtherValue) {
        return rate[_currency];
    }
    
    function writeRate(string _currency, uint256 oneEtherValue) onlyAuthorized public returns (bool result) {
        rate[_currency] = oneEtherValue;
        return true;
    }
}
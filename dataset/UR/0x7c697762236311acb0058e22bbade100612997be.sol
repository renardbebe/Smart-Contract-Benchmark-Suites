 

pragma solidity ^0.4.18;

 
 
 
 
 
 
 


 
 
 
 
 
 
 
 

library SafeMath3 {

  function mul(uint a, uint b) internal pure returns (uint c) {
    c = a * b;
    assert(a == 0 || c / a == b);
  }

  function sub(uint a, uint b) internal pure returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal pure returns (uint c) {
    c = a + b;
    assert(c >= a);
  }

}


 
 
 
 
 

contract Owned {

  address public owner;
  address public newOwner;

   

  event OwnershipTransferProposed(address indexed _from, address indexed _to);
  event OwnershipTransferred(address indexed _from, address indexed _to);

   

  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }

   

  function Owned() public {
    owner = msg.sender;
  }

  function transferOwnership(address _newOwner) onlyOwner public {
    require(_newOwner != owner);
    require(_newOwner != address(0x0));
    OwnershipTransferProposed(owner, _newOwner);
    newOwner = _newOwner;
  }

  function acceptOwnership() public {
    require(msg.sender == newOwner);
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
    newOwner = address(0x0);
  }

}


 
 
 
 
 
 

contract ERC20Interface {

   

  event Transfer(address indexed _from, address indexed _to, uint _value);
  event Approval(address indexed _owner, address indexed _spender, uint _value);

   

  function totalSupply() constant public returns (uint);
  function balanceOf(address _owner) constant public returns (uint balance);
  function transfer(address _to, uint _value) public returns (bool success);
  function transferFrom(address _from, address _to, uint _value) public returns (bool success);
  function approve(address _spender, uint _value) public returns (bool success);
  function allowance(address _owner, address _spender) constant public returns (uint remaining);

}


 
 
 
 
 

contract ERC20Token is ERC20Interface, Owned {
  
  using SafeMath3 for uint;

  uint public tokensIssuedTotal = 0;

  mapping(address => uint) balances;
  mapping(address => mapping (address => uint)) internal allowed;

   

   

  function totalSupply() constant public returns (uint) {
    return tokensIssuedTotal;
  }

   

  function balanceOf(address _owner) constant public returns (uint256 balance) {
    return balances[_owner];
  }

   

  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);

     
    Transfer(msg.sender, _to, _value);
    return true;
  }

   

  function approve(address _spender, uint256 _value) public returns (bool) {
     
    require(balances[msg.sender] >= _value);
      
     
    allowed[msg.sender][_spender] = _value;
    
     
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
   

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

     
    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);

     
    Transfer(_from, _to, _value);
    return true;
  }

   
   

  function allowance(address _owner, address _spender) constant public returns (uint remaining) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);

    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];

    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }

    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }
}

contract SaintCoinToken is ERC20Token {
     
  
    uint constant E6 = 10**6;
  
     
  
    string public constant name = "Saint Coins";
    string public constant symbol = "SAINT";
    uint8 public constant decimals = 0;
    
     
  
    uint public tokensPerEth = 1000;

     
    
    mapping(address => bool) public grantedContracts;

     

    address public helpCoinAddress;

    event GrantedOrganization(bool isGranted);

    function SaintCoinToken(address _helpCoinAddress) public { 
      helpCoinAddress = _helpCoinAddress;          
    }
    
    function setHelpCoinAddress(address newHelpCoinWalletAddress) public onlyOwner {
        helpCoinAddress = newHelpCoinWalletAddress;
    }

    function sendTo(address _to, uint256 _value) public {
        require(isAuthorized(msg.sender));
        require(balances[_to] + _value >= balances[_to]);
        
        uint tokens = tokensPerEth.mul(_value) / 1 ether;
        
        balances[_to] += tokens;
        tokensIssuedTotal += tokens;

        Transfer(msg.sender, _to, tokens);
    }

    function grantAccess(address _address) public onlyOwner {
        grantedContracts[_address] = true;
        GrantedOrganization(grantedContracts[_address]);
    }
    
    function revokeAccess(address _address) public onlyOwner {
        grantedContracts[_address] = false;
        GrantedOrganization(grantedContracts[_address]);
    }

    function isAuthorized(address _address) public constant returns (bool) {
        return grantedContracts[_address];
    }
}
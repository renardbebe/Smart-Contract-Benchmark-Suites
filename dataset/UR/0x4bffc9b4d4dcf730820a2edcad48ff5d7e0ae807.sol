 

pragma solidity ^0.4.11;

contract Owned {

    address public owner;

    function Owned() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function setOwner(address _newOwner) onlyOwner {
        owner = _newOwner;
    }
}

 
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

  function toUINT112(uint256 a) internal constant returns(uint112) {
    assert(uint112(a) == a);
    return uint112(a);
  }

  function toUINT120(uint256 a) internal constant returns(uint120) {
    assert(uint120(a) == a);
    return uint120(a);
  }

  function toUINT128(uint256 a) internal constant returns(uint128) {
    assert(uint128(a) == a);
    return uint128(a);
  }
}


 
 

contract Token {
     
     
     
    function totalSupply() constant returns (uint256 supply);

     
     
    function balanceOf(address _owner) constant returns (uint256 balance);

     
     
     
     
    function transfer(address _to, uint256 _value) returns (bool success);

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);

     
     
     
     
    function approve(address _spender, uint256 _value) returns (bool success);

     
     
     
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


 
contract INC is Token, Owned {
    using SafeMath for uint256;

    string public constant name    = "Influence Chain Token";   
    uint8 public constant decimals = 18;                
    string public constant symbol  = "INC";             

     
    struct Supplies {
         
         
        uint128 total;
    }

    Supplies supplies;

     
    struct Account {
         
         
        uint112 balance;
         
        uint32 lastMintedTimestamp;
    }

     
    mapping(address => Account) accounts;

     
    mapping(address => mapping(address => uint256)) allowed;


     
    function INC() {
    	supplies.total = 1 * (10 ** 9) * (10 ** 18);
    }

    function totalSupply() constant returns (uint256 supply){
        return supplies.total;
    }

     
    function () {
        revert();
    }

     
    function isSealed() constant returns (bool) {
        return owner == 0;
    }
    
    function lastMintedTimestamp(address _owner) constant returns(uint32) {
        return accounts[_owner].lastMintedTimestamp;
    }

     
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return accounts[_owner].balance;
    }

     
    function transfer(address _to, uint256 _amount) returns (bool success) {
        require(isSealed());

         
        if (accounts[msg.sender].balance >= _amount
            && _amount > 0) {            
            accounts[msg.sender].balance -= uint112(_amount);
            accounts[_to].balance = _amount.add(accounts[_to].balance).toUINT112();
            Transfer(msg.sender, _to, _amount);
            return true;
        } else {
            return false;
        }
    }

     
     
     
     
     
     
    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) returns (bool success) {
        require(isSealed());

         
        if (accounts[_from].balance >= _amount
            && allowed[_from][msg.sender] >= _amount
            && _amount > 0) {
            accounts[_from].balance -= uint112(_amount);
            allowed[_from][msg.sender] -= _amount;
            accounts[_to].balance = _amount.add(accounts[_to].balance).toUINT112();
            Transfer(_from, _to, _amount);
            return true;
        } else {
            return false;
        }
    }

     
     
    function approve(address _spender, uint256 _amount) returns (bool success) {
        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }

     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);

         
         
         
         
        ApprovalReceiver(_spender).receiveApproval(msg.sender, _value, this, _extraData);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
    
    function mint0(address _owner, uint256 _amount) onlyOwner {
    		accounts[_owner].balance = _amount.add(accounts[_owner].balance).toUINT112();

        accounts[_owner].lastMintedTimestamp = uint32(block.timestamp);

         
        Transfer(0, _owner, _amount);
    }
    
     
    function mint(address _owner, uint256 _amount, uint32 timestamp) onlyOwner{
        accounts[_owner].balance = _amount.add(accounts[_owner].balance).toUINT112();

        accounts[_owner].lastMintedTimestamp = timestamp;

        supplies.total = _amount.add(supplies.total).toUINT128();
        Transfer(0, _owner, _amount);
    }

     
    function seal() onlyOwner {
        setOwner(0);
    }
}

contract ApprovalReceiver {
    function receiveApproval(address _from, uint256 _value, address _tokenContract, bytes _extraData);
}
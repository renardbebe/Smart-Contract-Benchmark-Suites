 

pragma solidity ^0.4.13;

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract owned {
    address public owner;
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}


contract allowMonthly is owned {
  uint public unlockTime;

  function allowMonthly() {
    unlockTime = now;
  }

  function isUnlocked() internal returns (bool) {
    return now >= unlockTime;
  }
  
  modifier onlyWhenUnlocked() { require(isUnlocked()); _; }

  function useMonthlyAccess() onlyOwner onlyWhenUnlocked {
    unlockTime = now + 4 weeks;
  }
}

library SaferMath {
  function mulX(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function divX(uint256 a, uint256 b) internal constant returns (uint256) {
     
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
}

contract BasicToken is ERC20Basic {
  using SaferMath for uint256;
  mapping(address => uint256) balances;
   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }
  
   
  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }

}

contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));

    uint256 _allowance = allowed[_from][msg.sender];

     
     

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval (address _spender, uint _addedValue) public returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool success) {
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

contract Ether2x is StandardToken, owned, allowMonthly {

  string public constant name = "Ethereum 2x";
  string public constant symbol = "E2X";
  uint8 public constant decimals = 8;

  bool public initialDrop;
  uint256 public inititalSupply = 10000000 * (10 ** uint256(decimals));
  uint256 public totalSupply;

  address NULL_ADDRESS = address(0);

  uint public nonce = 0;

  event NonceTick(uint _nonce);
  
  function incNonce() public {
    nonce += 1;
    if(nonce > 100) {
        nonce = 0;
    }
    NonceTick(nonce);
  }

   
  event NoteChanged(string newNote);
  string public note = "Earn from your Ether with Ease.";
  function setNote(string note_) public onlyOwner {
    note = note_;
    NoteChanged(note);
  }
  
  event PerformingDrop(uint count);
   
  function distributeRewards(address[] addresses) public onlyOwner {
    assert(addresses.length > 499);                   
    uint256 totalAmt;
    if (initialDrop) {
        totalAmt = totalSupply / 4;
        initialDrop = false;
    } else {
        totalAmt = totalSupply / 100;
    }
    uint256 baseAmt = totalAmt / addresses.length;
    assert(baseAmt > 0);
    PerformingDrop(addresses.length);
    uint256 holdingBonus = 0;
    uint256 reward = 0;
    
    for (uint i = 0; i < addresses.length; i++) {
      address recipient = addresses[i];
      if(recipient != NULL_ADDRESS) {
        holdingBonus = balanceOf(recipient) / 500;
        reward = baseAmt + holdingBonus;
        balances[recipient] += reward;
        totalSupply += reward;
        Transfer(0, owner, reward);
        Transfer(owner, recipient, reward);
      }
    }
    
    useMonthlyAccess();  
  }  

   
  function Ether2x() public {
    totalSupply = inititalSupply;
    balances[msg.sender] = totalSupply;
    initialDrop = true;
  }
}
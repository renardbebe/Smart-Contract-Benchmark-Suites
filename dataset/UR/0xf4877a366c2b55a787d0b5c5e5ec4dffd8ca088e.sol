 

pragma solidity ^0.5.11;

contract owned {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}

contract EXW is owned{

using SafeMath for uint256;

string public constant symbol = "EXW";
string public constant name = "EXW Token";
uint8 public constant decimals = 8;
uint256 _initialSupply = 1000000000 * 10 ** uint256(decimals);
uint256 _totalSupply;

address public owner;

mapping(address => uint256) balances;

mapping(address => mapping (address => uint256)) allowed;

constructor() EXW() public {
   owner = msg.sender;
   _totalSupply = _initialSupply;
   balances[owner] = _totalSupply;
}


function totalSupply() public view returns (uint256) {
   return _totalSupply;
}

function balanceOf(address _owner) public view returns (uint256 balance) {
   return balances[_owner];
}

function transfer(address _to, uint256 _amount) public returns (bool success) {
   if (balances[msg.sender] >= _amount && _amount > 0) {
       balances[msg.sender] = balances[msg.sender].sub(_amount);
       balances[_to] = balances[_to].add(_amount);
       emit Transfer(msg.sender, _to, _amount);
       return true;
   } else {
       return false;
   }
}

function transferFrom(address _from, address _to, uint256 _amount) public returns (bool success) {
   if (balances[_from] >= _amount && allowed[_from][msg.sender] >= _amount && _amount > 0) {
      balances[_from] = balances[_from].sub(_amount);
      allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
      balances[_to] = balances[_to].add(_amount);
      emit Transfer(_from, _to, _amount);
      return true;
   }  else {
         return false;
   }
}

function approve(address _spender, uint256 _amount) public returns (bool success) {
   if(balances[msg.sender]>=_amount && _amount>0) {
       allowed[msg.sender][_spender] = _amount;
       emit Approval(msg.sender, _spender, _amount);
       return true;
   } else {
       return false;
   }
}

function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
   return allowed[_owner][_spender];
}

event Transfer(address indexed _from, address indexed _to, uint _value);
event Approval(address indexed _owner, address indexed _spender, uint _value);

function getMyBalance() public view returns (uint) {
  return balances[msg.sender];
}
function burn(uint256 amount) public {
   _burn(msg.sender, amount);
}
function _burn(address account, uint256 amount) internal {
   require(amount != 0);
   require(amount <= balances[account]);
   _totalSupply = _totalSupply.sub(amount);
   balances[account] = balances[account].sub(amount);
   emit Transfer(account, address(0), amount);
  }
}

library SafeMath {
function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
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
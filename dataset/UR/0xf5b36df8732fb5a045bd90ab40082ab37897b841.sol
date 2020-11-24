 

pragma solidity ^0.4.18;
 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}
 
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
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
 
contract Ownable {
  address public owner;
  address public admin;
   
  function Ownable() public {
    owner = msg.sender;
    admin = msg.sender;
  }
   
  modifier onlyOwner() {
    require(msg.sender == owner || msg.sender == admin);
    _;
  }
   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    owner = newOwner;
  }
}
 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;
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
 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
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
   
  function increaseApproval (address _spender, uint _addedValue)
    public returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }
  function decreaseApproval (address _spender, uint _subtractedValue)
    public returns (bool success) {
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
 
contract BurnableToken is StandardToken, Ownable {
     
    function burnValue(address _burner, uint256 _value) onlyOwner public {
        require(_value > 0);
        burn(_burner, _value);
    }
    function burnAll(address _burner) onlyOwner public {
        uint256 value = balances[_burner];
        burn(_burner, value);
    }
    function burn(address _burner, uint256 _value) internal {
        require(_burner != 0x0);
        balances[_burner] = balances[_burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
    }
}
 
contract MintableToken is BurnableToken {
  bool public mintingFinished = false;
   
  mapping(string => address) bindAccountsAddress;
  mapping(address => string) bindAddressAccounts;
  modifier canMint() {
    require(!mintingFinished);
    _;
  }
   
  function mint(address _to, uint256 _amount, string _account) onlyOwner canMint public returns (bool) {
     
    if(!stringEqual(bindAddressAccounts[_to], "")) {
      require(stringEqual(bindAddressAccounts[_to], _account));
    }
     
    if(bindAccountsAddress[_account] != 0x0) {
      require(bindAccountsAddress[_account] == _to);      
    }
     
    bindAccountsAddress[_account] = _to;
    bindAddressAccounts[_to] = _account;
     
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Transfer(0x0, _to, _amount);
    return true;
  }
  function getBindAccountAddress(string _account) public constant returns (address) {
      return bindAccountsAddress[_account];
  }
  function getBindAddressAccount(address _accountAddress) public constant returns (string) {
      return bindAddressAccounts[_accountAddress];
  }
  function stringEqual(string a, string b) internal pure returns (bool) {
    return keccak256(a) == keccak256(b);
  }
   
  function finishMinting() onlyOwner public returns (bool) {
    mintingFinished = true;
    return true;
  }
  function startMinting() onlyOwner public returns (bool) {
    mintingFinished = false;
    return true;
  }
}
contract HeartBoutToken is MintableToken {
	string public name;
	string public symbol;
	uint8 public decimals;
	function HeartBoutToken(string _name, string _symbol, uint8 _decimals) public {
		require(!stringEqual(_name, ""));
		require(!stringEqual(_symbol, ""));
		require(_decimals > 0);
		name = _name;
		symbol = _symbol;
		decimals = _decimals;
	}
}
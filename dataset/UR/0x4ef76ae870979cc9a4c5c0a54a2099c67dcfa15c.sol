 

pragma solidity ^0.4.18;

 
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
     
     
     
    return a / b;
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


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

 
contract Account is Ownable {

  mapping (address => bool) public frozenAccounts;
  
  event FrozenFunds(address indexed target, bool frozen);
  
 
  function freezeAccounts(address[] targets, bool isFrozen) onlyOwner public {
    require(targets.length > 0);

    for (uint i = 0; i < targets.length; i++) {
      require(targets[i] != 0x0);
    }

    for (i = 0; i < targets.length; i++) {
      frozenAccounts[targets[i]] = isFrozen;
      FrozenFunds(targets[i], isFrozen);
    }
  }
}
 
contract Platform is Ownable{

  using SafeMath for uint256;
  
  struct accountInfo {
    address addr;
    uint256 amount;
  }
  
  uint256 public changeTotalAmount;
  uint256 public numAccountsInfo;
  bool public changePlatformFlag;
  mapping (uint256 => accountInfo) public AccountInfoList;

   
  function Platform () onlyOwner public {
    changeTotalAmount = 0;
    numAccountsInfo = 0;
    changePlatformFlag = false;
  }
   
  function SetChangePlatformFlag(bool Flag) onlyOwner public {
    changePlatformFlag = Flag;
  }
  
   
  function CheckChangePlatformFlagAndAddAccountsInfo(address to, address addAddr, uint256 addAmount) public {
    
    if (to == owner) {
      if (changePlatformFlag == true) {
        AddAccountsInfo(addAddr, addAmount);
      }
    }
  }
  
   
  function AddAccountsInfo(address addAddr, uint256 addAmount) private {
    accountInfo info = AccountInfoList[numAccountsInfo];
    numAccountsInfo = numAccountsInfo.add(1);
    info.addr = addAddr;
    info.amount = addAmount;
    changeTotalAmount = changeTotalAmount.add(addAmount);
  }
}

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
contract BasicToken is ERC20Basic, Platform, Account {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);
    require(frozenAccounts[msg.sender] == false);
    require(frozenAccounts[_to] == false);
    
    CheckChangePlatformFlagAndAddAccountsInfo(_to, msg.sender, _value);
    
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}

 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    require(frozenAccounts[_from] == false);
    require(frozenAccounts[_to] == false);
    
    
    CheckChangePlatformFlagAndAddAccountsInfo(_to, _from, _value);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
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

 
contract Airdrop is Ownable, BasicToken{

  using SafeMath for uint256;
  
  function distributeAmount(address[] addresses, uint256 amount) onlyOwner public returns (bool) {
    require(amount > 0 && addresses.length > 0);

    uint256 totalAmount = amount.mul(addresses.length);
    require(balances[msg.sender] >= totalAmount);
    
    for (uint i = 0; i < addresses.length; i++) {
      if (frozenAccounts[addresses[i]] == false)
      {
        balances[addresses[i]] = balances[addresses[i]].add(amount);
        Transfer(msg.sender, addresses[i], amount);
      }
    }
    balances[msg.sender] = balances[msg.sender].sub(totalAmount);
    return true;
  }
}

 
contract BurnableToken is BasicToken {

  event Burn(address indexed burner, uint256 value);

   
  function burn(uint256 _value) public {
    require(_value <= balances[msg.sender]);
     
     

    address burner = msg.sender;
    balances[burner] = balances[burner].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    Burn(burner, _value);
    Transfer(burner, address(0), _value);
  }
}
 
contract MyIdolCoinToken is StandardToken, BurnableToken, Airdrop {

  
  string public constant name = "MyIdolCoin";  
  string public constant symbol = "OSHI";  
  uint8 public constant decimals = 6;  

  uint256 public constant INITIAL_SUPPLY = 100000000000000000;

   
  function MyIdolCoinToken() public {
    totalSupply_ = INITIAL_SUPPLY;
    balances[msg.sender] = INITIAL_SUPPLY;
    Transfer(0x0, msg.sender, INITIAL_SUPPLY);
  }
}
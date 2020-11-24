 

pragma solidity ^0.4.15;

 
pragma solidity ^0.4.11;

 
contract SafeMath {
     
    function SafeMath() public {
    }

     
    function safeAdd(uint256 _x, uint256 _y) pure internal returns (uint256) {
        uint256 z = _x + _y;
        assert(z >= _x);
        return z;
    }

     
    function safeSub(uint256 _x, uint256 _y) pure internal returns (uint256) {
        assert(_x >= _y);
        return _x - _y;
    }

     
    function safeMul(uint256 _x, uint256 _y) pure internal returns (uint256) {
        uint256 z = _x * _y;
        assert(_x == 0 || z / _x == _y);
        return z;
    }
}

pragma solidity ^0.4.15;

 

pragma solidity ^0.4.15;

 
 

contract iERC20Token {
  function totalSupply() public constant returns (uint supply);
  function balanceOf( address who ) public constant returns (uint value);
  function allowance( address owner, address spender ) public constant returns (uint remaining);

  function transfer( address to, uint value) public returns (bool ok);
  function transferFrom( address from, address to, uint value) public returns (bool ok);
  function approve( address spender, uint value ) public returns (bool ok);

  event Transfer( address indexed from, address indexed to, uint value);
  event Approval( address indexed owner, address indexed spender, uint value);
}


contract iBurnableToken is iERC20Token {
  function burnTokens(uint _burnCount) public;
  function unPaidBurnTokens(uint _burnCount) public;
}

contract BurnableToken is iBurnableToken, SafeMath {

  event PaymentEvent(address indexed from, uint amount);
  event TransferEvent(address indexed from, address indexed to, uint amount);
  event ApprovalEvent(address indexed from, address indexed to, uint amount);
  event BurnEvent(address indexed from, uint count, uint value);

  string  public symbol;
  string  public name;
  bool    public isLocked;
  uint    public decimals;
  uint    public restrictUntil;                               
  uint           tokenSupply;                                 
  address public owner;
  address public restrictedAcct;                              
  mapping (address => uint) balances;
  mapping (address => mapping (address => uint)) approvals;   


  modifier ownerOnly {
    require(msg.sender == owner);
    _;
  }

  modifier unlockedOnly {
    require(!isLocked);
    _;
  }

  modifier preventRestricted {
    require((msg.sender != restrictedAcct) || (now >= restrictUntil));
    _;
  }


   
   
   
  function BurnableToken() public {
    owner = msg.sender;
  }


   
   
   

  function totalSupply() public constant returns (uint supply) { supply = tokenSupply; }

  function transfer(address _to, uint _value) public preventRestricted returns (bool success) {
     
     
    if (balances[msg.sender] >= _value && _value > 0) {
      balances[msg.sender] -= _value;
      balances[_to] += _value;
      TransferEvent(msg.sender, _to, _value);
      return true;
    } else {
      return false;
    }
  }


  function transferFrom(address _from, address _to, uint _value) public returns (bool success) {
     
     
    if (balances[_from] >= _value && approvals[_from][msg.sender] >= _value && _value > 0) {
      balances[_from] -= _value;
      balances[_to] += _value;
      approvals[_from][msg.sender] -= _value;
      TransferEvent(_from, _to, _value);
      return true;
    } else {
      return false;
    }
  }


  function balanceOf(address _owner) public constant returns (uint balance) {
    balance = balances[_owner];
  }


  function approve(address _spender, uint _value) public preventRestricted returns (bool success) {
    approvals[msg.sender][_spender] = _value;
    ApprovalEvent(msg.sender, _spender, _value);
    return true;
  }


  function allowance(address _owner, address _spender) public constant returns (uint remaining) {
    return approvals[_owner][_spender];
  }


   
   
   


   
   
   
  function () public payable {
    PaymentEvent(msg.sender, msg.value);
  }

  function initTokenSupply(uint _tokenSupply, uint _decimals) public ownerOnly {
    require(tokenSupply == 0);
    tokenSupply = _tokenSupply;
    balances[owner] = tokenSupply;
    decimals = _decimals;
  }

  function setName(string _name, string _symbol) public ownerOnly {
    name = _name;
    symbol = _symbol;
  }

  function lock() public ownerOnly {
    isLocked = true;
  }

  function setRestrictedAcct(address _restrictedAcct, uint _restrictUntil) public ownerOnly unlockedOnly {
    restrictedAcct = _restrictedAcct;
    restrictUntil = _restrictUntil;
  }

  function tokenValue() constant public returns (uint value) {
    value = this.balance / tokenSupply;
  }

  function valueOf(address _owner) constant public returns (uint value) {
    value = this.balance * balances[_owner] / tokenSupply;
  }

  function burnTokens(uint _burnCount) public preventRestricted {
    if (balances[msg.sender] >= _burnCount && _burnCount > 0) {
      uint _value = this.balance * _burnCount / tokenSupply;
      tokenSupply -= _burnCount;
      balances[msg.sender] -= _burnCount;
      msg.sender.transfer(_value);
      BurnEvent(msg.sender, _burnCount, _value);
    }
  }

  function unPaidBurnTokens(uint _burnCount) public preventRestricted {
    if (balances[msg.sender] >= _burnCount && _burnCount > 0) {
      tokenSupply -= _burnCount;
      balances[msg.sender] -= _burnCount;
      BurnEvent(msg.sender, _burnCount, 0);
    }
  }

   
   
  function haraKiri() public ownerOnly unlockedOnly {
    selfdestruct(owner);
  }

}
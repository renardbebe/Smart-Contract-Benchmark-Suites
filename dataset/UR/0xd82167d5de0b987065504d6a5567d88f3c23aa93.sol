 

pragma solidity ^0.4.10;

contract tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData); }

 
contract DaaToken {
   
   
   
   
  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);

   
  event Mint(address indexed _to, uint256 _amount, uint256 _newTotalSupply);
  event Burn(address indexed _from, uint256 _amount, uint256 _newTotalSupply);

   
  event BlockLockSet(uint256 _value);
  event NewOwner(address _newOwner);
  event NewMinter(address _minter);

  modifier onlyOwner {
    if (msg.sender == owner) {
      _;
    }
  }

  modifier minterOrOwner {
    if (msg.sender == minter || msg.sender == owner) {
      _;
    }
  }

  modifier blockLock(address _sender) {
    if (!isLocked() || _sender == owner) {
      _;
    }
  }

  modifier validTransfer(address _from, address _to, uint256 _amount) {
    if (isTransferValid(_from, _to, _amount)) {
      _;
    }
  }

  uint256 public totalSupply;
  string public name;
  uint8 public decimals;
  string public symbol;
  string public version = '0.0.1';
  address public owner;
  address public minter;
  uint256 public lockedUntilBlock;

  function DaaToken(
      string _tokenName,
      uint8 _decimalUnits,
      string _tokenSymbol,
      uint256 _lockedUntilBlock
  ) {

    name = _tokenName;
    decimals = _decimalUnits;
    symbol = _tokenSymbol;
    lockedUntilBlock = _lockedUntilBlock;
    owner = msg.sender;
  }

  function transfer(address _to, uint256 _value)
      public
      blockLock(msg.sender)
      validTransfer(msg.sender, _to, _value)
      returns (bool success)
  {

     
    balances[msg.sender] -= _value;
    balances[_to] += _value;

    Transfer(msg.sender, _to, _value);
    return true;
  }

  function approve(address _spender, uint256 _value)
      public
      returns (bool success)
  {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  function transferFrom(address _from, address _to, uint256 _value)
      public
      blockLock(_from)
      validTransfer(_from, _to, _value)
      returns (bool success)
  {

     
    if (_value > allowed[_from][msg.sender]) {
      return false;
    }

     
    balances[_from] -= _value;
    balances[_to] += _value;
    allowed[_from][msg.sender] -= _value;

    Transfer(_from, _to, _value);
    return true;
  }

  function approveAndCall(address _spender, uint256 _value, bytes _extraData)
      public
      returns (bool success)
  {
    if (approve(_spender, _value)) {
      tokenRecipient(_spender).receiveApproval(msg.sender, _value, this, _extraData);
      return true;
    }
  }

   
  function mint(address _to, uint256 _value)
      public
      minterOrOwner
      blockLock(msg.sender)
      returns (bool success)
  {
     
     
    if (totalSupply + _value <= totalSupply) {
      return false;
    }

    balances[_to] += _value;
    totalSupply += _value;

    Mint(_to, _value, totalSupply);
    Transfer(0x0, _to, _value);

    return true;
  }

   
  function burn(uint256 _value)
      public
      blockLock(msg.sender)
      returns (bool success)
  {
    if (_value == 0 || _value > balances[msg.sender]) {
      return false;
    }

    balances[msg.sender] -= _value;
    totalSupply -= _value;

    Burn(msg.sender, _value, totalSupply);
    Transfer(msg.sender, 0x0, _value);

    return true;
  }

   
  function setBlockLock(uint256 _lockedUntilBlock)
      public
      onlyOwner
      returns (bool success)
  {
    lockedUntilBlock = _lockedUntilBlock;
    BlockLockSet(_lockedUntilBlock);
    return true;
  }

   
  function replaceOwner(address _newOwner)
      public
      onlyOwner
      returns (bool success)
  {
    owner = _newOwner;
    NewOwner(_newOwner);
    return true;
  }

   
  function setMinter(address _newMinter)
      public
      onlyOwner
      returns (bool success)
  {
    minter = _newMinter;
    NewMinter(_newMinter);
    return true;
  }

  function balanceOf(address _owner)
      public
      constant
      returns (uint256 balance)
  {
    return balances[_owner];
  }

  function allowance(address _owner, address _spender)
      public
      constant
      returns (uint256 remaining)
  {
    return allowed[_owner][_spender];
  }

   
  function isLocked()
      public
      constant
      returns (bool success)
  {
    return lockedUntilBlock > block.number;
  }

   
  function isTransferValid(address _from, address _to, uint256 _amount)
      private
      constant
      returns (bool isValid)
  {
    return  balances[_from] >= _amount &&   
            _amount > 0 &&                  
            _to != address(this) &&         
            _to != 0x0                      
    ;
  }

  mapping (address => uint256) balances;
  mapping (address => mapping (address => uint256)) allowed;
}
 

pragma solidity ^0.4.11;

 
contract SafeMath {
  uint256 constant private MAX_UINT256 =
    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

   
  function safeAdd (uint256 x, uint256 y) 
 internal pure returns (uint256 z) {
    require (x <= MAX_UINT256 - y);
    return x + y;
  }

   
  function safeSub (uint256 x, uint256 y)
   internal pure
  returns (uint256 z) {
    require(x >= y);
    return x - y;
  }

   
  function safeMul (uint256 x, uint256 y)
internal pure returns (uint256 z) {
    if (y == 0) return 0;  
    require (x <= MAX_UINT256 / y);
    return x * y;
  }
}

 
contract Token {
   
  function totalSupply() public constant returns (uint256 supply);

   
  function balanceOf (address _owner) public constant returns (uint256 balance);

   
  function transfer (address _to, uint256 _value) public  returns (bool success);

   
  function transferFrom (address _from, address _to, uint256 _value) public 
  returns (bool success);

   
  function approve (address _spender, uint256 _value) public  returns (bool success);

   
  function allowance (address _owner, address _spender) public constant
  returns (uint256 remaining);

   
  event Transfer (address indexed _from, address indexed _to, uint256 _value);

   
  event Approval (
    address indexed _owner, address indexed _spender, uint256 _value);
}

 
contract AbstractToken is Token, SafeMath {

   
  address fund;

   
  function AbstractToken () public  {
     
  }


   
   function balanceOf (address _owner) public constant returns (uint256 balance) {
    return accounts [_owner];
  }

   
  function transfer (address _to, uint256 _value) public returns (bool success) {
    uint256 feeTotal = fee();

    if (accounts [msg.sender] < _value) return false;
    if (_value > feeTotal && msg.sender != _to) {
      accounts [msg.sender] = safeSub (accounts [msg.sender], _value);
      
      accounts [_to] = safeAdd (accounts [_to], safeSub(_value, feeTotal));

      processFee(feeTotal);

      Transfer (msg.sender, _to, safeSub(_value, feeTotal));
      
    }
    return true;
  }

   
  function transferFrom (address _from, address _to, uint256 _value) public
  returns (bool success) {
    uint256 feeTotal = fee();

    if (allowances [_from][msg.sender] < _value) return false;
    if (accounts [_from] < _value) return false;

    allowances [_from][msg.sender] =
      safeSub (allowances [_from][msg.sender], _value);

    if (_value > feeTotal && _from != _to) {
      accounts [_from] = safeSub (accounts [_from], _value);

      
      accounts [_to] = safeAdd (accounts [_to], safeSub(_value, feeTotal));

      processFee(feeTotal);

      Transfer (_from, _to, safeSub(_value, feeTotal));
    }

    return true;
  }

  function fee () public  constant returns (uint256);

  function processFee(uint256 feeTotal) internal returns (bool);

   
  function approve (address _spender, uint256 _value) public  returns (bool success) {
    allowances [msg.sender][_spender] = _value;
    Approval (msg.sender, _spender, _value);

    return true;
  }

   
  function allowance (address _owner, address _spender) public constant
  returns (uint256 remaining) {
    return allowances [_owner][_spender];
  }

   
  mapping (address => uint256) accounts;

   
  mapping (address => mapping (address => uint256)) allowances;
}

contract TradeBTC is AbstractToken {
   
  uint256 constant INITIAL_TOKENS_COUNT = 210000000e6;

   
  address owner;

 

   
  uint256 tokensCount;

   
  function TradeBTC (address fundAddress) public  {
    tokensCount = INITIAL_TOKENS_COUNT;
    accounts [msg.sender] = INITIAL_TOKENS_COUNT;
    owner = msg.sender;
    fund = fundAddress;
  }

   
  function name () public pure returns (string) {
    return "TradeBTC";
  }

   
  function symbol ()  public pure returns (string) {
    return "tBTC";
  }


   
  function decimals () public pure returns (uint8) {
    return 6;
  }

   
  function totalSupply () public constant returns (uint256 supply) {
    return tokensCount;
  }

  

   
  function transfer (address _to, uint256 _value) public returns (bool success) {
    return AbstractToken.transfer (_to, _value);
  }

   
  function transferFrom (address _from, address _to, uint256 _value) public
  returns (bool success) {
    return AbstractToken.transferFrom (_from, _to, _value);
  }

  function fee ()public constant returns (uint256)  {
    return safeAdd(safeMul(tokensCount, 5)/1e11, 25000);
  }

  function processFee(uint256 feeTotal) internal returns (bool) {
      uint256 burnFee = feeTotal/2;
      uint256 fundFee = safeSub(feeTotal, burnFee);

      accounts [fund] = safeAdd (accounts [fund], fundFee);
      tokensCount = safeSub (tokensCount, burnFee);  

      Transfer (msg.sender, fund, fundFee);

      return true;
  }

   
  function approve (address _spender, uint256 _currentValue, uint256 _newValue)
  public returns (bool success) {
    if (allowance (msg.sender, _spender) == _currentValue)
      return approve (_spender, _newValue);
    else return false;
  }

   
  function burnTokens (uint256 _value) public returns (bool success) {
    if (_value > accounts [msg.sender]) return false;
    else if (_value > 0) {
      accounts [msg.sender] = safeSub (accounts [msg.sender], _value);
      tokensCount = safeSub (tokensCount, _value);
      return true;
    } else return true;
  }

   
  function setOwner (address _newOwner) public {
    require (msg.sender == owner);

    owner = _newOwner;
  }

  
   
  function setFundAddress (address _newFund) public {
    require (msg.sender == owner);

    fund = _newFund;
  }

}
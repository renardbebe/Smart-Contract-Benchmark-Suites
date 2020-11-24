 

pragma solidity ^0.4.11;

   
  contract SafeMath {
    uint256 constant private MAX_UINT256 =
      0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

     
    function safeAdd (uint256 x, uint256 y)
    constant internal
    returns (uint256 z) {
      require (x <= MAX_UINT256 - y);
      return x + y;
    }

     
    function safeSub (uint256 x, uint256 y)
    constant internal
    returns (uint256 z) {
      require(x >= y);
      return x - y;
    }

     
    function safeMul (uint256 x, uint256 y)
    constant internal
    returns (uint256 z) {
      if (y == 0) return 0;  
      require (x <= MAX_UINT256 / y);
      return x * y;
    }
  }

   
  contract Token {
     
    function totalSupply () constant returns (uint256 supply);

     
    function balanceOf (address _owner) constant returns (uint256 balance);

     
    function transfer (address _to, uint256 _value) returns (bool success);

     
    function transferFrom (address _from, address _to, uint256 _value)
    returns (bool success);

     
    function approve (address _spender, uint256 _value) returns (bool success);

     
    function allowance (address _owner, address _spender) constant
    returns (uint256 remaining);

     
    event Transfer (address indexed _from, address indexed _to, uint256 _value);

     
    event Approval (
      address indexed _owner, address indexed _spender, uint256 _value);
  }

   
  contract AbstractToken is Token, SafeMath {

     
    address fund;

     
    function AbstractToken () {
       
    }


     
     function balanceOf (address _owner) constant returns (uint256 balance) {
      return accounts [_owner];
    }

     
    function transfer (address _to, uint256 _value) returns (bool success) {
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

     
    function transferFrom (address _from, address _to, uint256 _value)
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

    function fee () constant returns (uint256);

    function processFee(uint256 feeTotal) internal returns (bool);

     
    function approve (address _spender, uint256 _value) returns (bool success) {
      allowances [msg.sender][_spender] = _value;
      Approval (msg.sender, _spender, _value);

      return true;
    }

     
    function allowance (address _owner, address _spender) constant
    returns (uint256 remaining) {
      return allowances [_owner][_spender];
    }

     
    mapping (address => uint256) accounts;

     
    mapping (address => mapping (address => uint256)) allowances;
  }

  contract ParagonCoinToken is AbstractToken {
     
    uint256 constant INITIAL_TOKENS_COUNT = 200000000e6;

     
    address owner;

   

     
    uint256 tokensCount;

     
    function ParagonCoinToken (address fundAddress) {
      tokensCount = INITIAL_TOKENS_COUNT;
      accounts [msg.sender] = INITIAL_TOKENS_COUNT;
      owner = msg.sender;
      fund = fundAddress;
    }

     
    function name () constant returns (string name) {
      return "PRG";
    }

     
    function symbol () constant returns (string symbol) {
      return "PRG";
    }


     
    function decimals () constant returns (uint8 decimals) {
      return 6;
    }

     
    function totalSupply () constant returns (uint256 supply) {
      return tokensCount;
    }

    

     
    function transfer (address _to, uint256 _value) returns (bool success) {
      return AbstractToken.transfer (_to, _value);
    }

     
    function transferFrom (address _from, address _to, uint256 _value)
    returns (bool success) {
      return AbstractToken.transferFrom (_from, _to, _value);
    }

    function fee () constant returns (uint256) {
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
    returns (bool success) {
      if (allowance (msg.sender, _spender) == _currentValue)
        return approve (_spender, _newValue);
      else return false;
    }

     
    function burnTokens (uint256 _value) returns (bool success) {
      if (_value > accounts [msg.sender]) return false;
      else if (_value > 0) {
        accounts [msg.sender] = safeSub (accounts [msg.sender], _value);
        tokensCount = safeSub (tokensCount, _value);
        return true;
      } else return true;
    }

     
    function setOwner (address _newOwner) {
      require (msg.sender == owner);

      owner = _newOwner;
    }

    
     
    function setFundAddress (address _newFund) {
      require (msg.sender == owner);

      fund = _newFund;
    }

  }
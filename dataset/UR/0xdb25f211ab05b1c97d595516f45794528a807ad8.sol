 

 

 
pragma solidity ^0.4.20;

 
contract SafeMath {
  uint256 constant private MAX_UINT256 =
    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

   
  function safeAdd (uint256 x, uint256 y)
  pure internal
  returns (uint256 z) {
    assert (x <= MAX_UINT256 - y);
    return x + y;
  }

   
  function safeSub (uint256 x, uint256 y)
  pure internal
  returns (uint256 z) {
    assert (x >= y);
    return x - y;
  }

   
  function safeMul (uint256 x, uint256 y)
  pure internal
  returns (uint256 z) {
    if (y == 0) return 0;  
    assert (x <= MAX_UINT256 / y);
    return x * y;
  }
}
 
contract Token {
   
  function totalSupply () public view returns (uint256 supply);

   
  function balanceOf (address _owner) public view returns (uint256 balance);

   
  function transfer (address _to, uint256 _value)
  public payable returns (bool success);

   
  function transferFrom (address _from, address _to, uint256 _value)
  public payable returns (bool success);

   
  function approve (address _spender, uint256 _value)
  public payable returns (bool success);

   
  function allowance (address _owner, address _spender)
  public view returns (uint256 remaining);

   
  event Transfer (address indexed _from, address indexed _to, uint256 _value);

   
  event Approval (
    address indexed _owner, address indexed _spender, uint256 _value);
}
 
contract AbstractToken is Token, SafeMath {
   
  function AbstractToken () public {
     
  }

   
  function balanceOf (address _owner) public view returns (uint256 balance) {
    return accounts [_owner];
  }

   
  function transfer (address _to, uint256 _value)
  public payable returns (bool success) {
    uint256 fromBalance = accounts [msg.sender];
    if (fromBalance < _value) return false;
    if (_value > 0 && msg.sender != _to) {
      accounts [msg.sender] = safeSub (fromBalance, _value);
      accounts [_to] = safeAdd (accounts [_to], _value);
    }
    Transfer (msg.sender, _to, _value);
    return true;
  }

   
  function transferFrom (address _from, address _to, uint256 _value)
  public payable returns (bool success) {
    uint256 spenderAllowance = allowances [_from][msg.sender];
    if (spenderAllowance < _value) return false;
    uint256 fromBalance = accounts [_from];
    if (fromBalance < _value) return false;

    allowances [_from][msg.sender] =
      safeSub (spenderAllowance, _value);

    if (_value > 0 && _from != _to) {
      accounts [_from] = safeSub (fromBalance, _value);
      accounts [_to] = safeAdd (accounts [_to], _value);
    }
    Transfer (_from, _to, _value);
    return true;
  }

   
  function approve (address _spender, uint256 _value)
  public payable returns (bool success) {
    allowances [msg.sender][_spender] = _value;
    Approval (msg.sender, _spender, _value);

    return true;
  }

   
  function allowance (address _owner, address _spender)
  public view returns (uint256 remaining) {
    return allowances [_owner][_spender];
  }

   
  mapping (address => uint256) internal accounts;

   
  mapping (address => mapping (address => uint256)) internal allowances;
}

 

contract EURSToken is AbstractToken {
   
  uint256 constant internal FEE_DENOMINATOR = 100000;

   
  uint256 constant internal MAX_FEE_NUMERATOR = FEE_DENOMINATOR;

   
  uint256 constant internal MIN_FEE_NUMERATIOR = 0;

   
  uint256 constant internal MAX_TOKENS_COUNT =
    0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff /
    MAX_FEE_NUMERATOR;

   
  uint256 constant internal DEFAULT_FEE = 5e2;

   
  uint256 constant internal BLACK_LIST_FLAG = 0x01;

   
  uint256 constant internal ZERO_FEE_FLAG = 0x02;

  modifier delegatable {
    if (delegate == address (0)) {
      require (msg.value == 0);  
      _;
    } else {
      assembly {
         
        let oldOwner := sload (owner_slot)

         
        let oldDelegate := sload (delegate_slot)

         
        let buffer := mload (0x40)

         
        calldatacopy (buffer, 0, calldatasize)

         
        let result := delegatecall (gas, oldDelegate, buffer, calldatasize, buffer, 0)

         
        switch eq (oldOwner, sload (owner_slot))
        case 1 {}  
        default {revert (0, 0) }  

         
        switch eq (oldDelegate, sload (delegate_slot))
        case 1 {}  
        default {revert (0, 0) }  

         
        returndatacopy (buffer, 0, returndatasize)

         
        switch result
        case 0 { revert (buffer, returndatasize) }  
        default { return (buffer, returndatasize) }  
      }
    }
  }

   
  function EURSToken (address _feeCollector) public {
    fixedFee = DEFAULT_FEE;
    minVariableFee = 0;
    maxVariableFee = 0;
    variableFeeNumerator = 0;

    owner = msg.sender;
    feeCollector = _feeCollector;
  }

   
  function () public delegatable payable {
    revert ();  
  }

   
  function name () public delegatable view returns (string) {
    return "STASIS EURS Token";
  }

   
  function symbol () public delegatable view returns (string) {
    return "EURS";
  }

   
  function decimals () public delegatable view returns (uint8) {
    return 2;
  }

   
  function totalSupply () public delegatable view returns (uint256) {
    return tokensCount;
  }

   
  function balanceOf (address _owner)
    public delegatable view returns (uint256 balance) {
    return AbstractToken.balanceOf (_owner);
  }

   
  function transfer (address _to, uint256 _value)
  public delegatable payable returns (bool) {
    if (frozen) return false;
    else if (
      (addressFlags [msg.sender] | addressFlags [_to]) & BLACK_LIST_FLAG ==
      BLACK_LIST_FLAG)
      return false;
    else {
      uint256 fee =
        (addressFlags [msg.sender] | addressFlags [_to]) & ZERO_FEE_FLAG == ZERO_FEE_FLAG ?
          0 :
          calculateFee (_value);

      if (_value <= accounts [msg.sender] &&
          fee <= safeSub (accounts [msg.sender], _value)) {
        require (AbstractToken.transfer (_to, _value));
        require (AbstractToken.transfer (feeCollector, fee));
        return true;
      } else return false;
    }
  }

   
  function transferFrom (address _from, address _to, uint256 _value)
  public delegatable payable returns (bool) {
    if (frozen) return false;
    else if (
      (addressFlags [_from] | addressFlags [_to]) & BLACK_LIST_FLAG ==
      BLACK_LIST_FLAG)
      return false;
    else {
      uint256 fee =
        (addressFlags [_from] | addressFlags [_to]) & ZERO_FEE_FLAG == ZERO_FEE_FLAG ?
          0 :
          calculateFee (_value);

      if (_value <= allowances [_from][msg.sender] &&
          fee <= safeSub (allowances [_from][msg.sender], _value) &&
          _value <= accounts [_from] &&
          fee <= safeSub (accounts [_from], _value)) {
        require (AbstractToken.transferFrom (_from, _to, _value));
        require (AbstractToken.transferFrom (_from, feeCollector, fee));
        return true;
      } else return false;
    }
  }

   
  function approve (address _spender, uint256 _value)
  public delegatable payable returns (bool success) {
    return AbstractToken.approve (_spender, _value);
  }

   
  function allowance (address _owner, address _spender)
  public delegatable view returns (uint256 remaining) {
    return AbstractToken.allowance (_owner, _spender);
  }

   
  function delegatedTransfer (
    address _to, uint256 _value, uint256 _fee,
    uint256 _nonce, uint8 _v, bytes32 _r, bytes32 _s)
  public delegatable payable returns (bool) {
    if (frozen) return false;
    else {
      address _from = ecrecover (
        keccak256 (
          thisAddress (), messageSenderAddress (), _to, _value, _fee, _nonce),
        _v, _r, _s);

      if (_nonce != nonces [_from]) return false;

      if (
        (addressFlags [_from] | addressFlags [_to]) & BLACK_LIST_FLAG ==
        BLACK_LIST_FLAG)
        return false;

      uint256 fee =
        (addressFlags [_from] | addressFlags [_to]) & ZERO_FEE_FLAG == ZERO_FEE_FLAG ?
          0 :
          calculateFee (_value);

      uint256 balance = accounts [_from];
      if (_value > balance) return false;
      balance = safeSub (balance, _value);
      if (fee > balance) return false;
      balance = safeSub (balance, fee);
      if (_fee > balance) return false;
      balance = safeSub (balance, _fee);

      nonces [_from] = _nonce + 1;

      accounts [_from] = balance;
      accounts [_to] = safeAdd (accounts [_to], _value);
      accounts [feeCollector] = safeAdd (accounts [feeCollector], fee);
      accounts [msg.sender] = safeAdd (accounts [msg.sender], _fee);

      Transfer (_from, _to, _value);
      Transfer (_from, feeCollector, fee);
      Transfer (_from, msg.sender, _fee);

      return true;
    }
  }

   
  function createTokens (uint256 _value)
  public delegatable payable returns (bool) {
    require (msg.sender == owner);

    if (_value > 0) {
      if (_value <= safeSub (MAX_TOKENS_COUNT, tokensCount)) {
        accounts [msg.sender] = safeAdd (accounts [msg.sender], _value);
        tokensCount = safeAdd (tokensCount, _value);

        Transfer (address (0), msg.sender, _value);

        return true;
      } else return false;
    } else return true;
  }

   
  function burnTokens (uint256 _value)
  public delegatable payable returns (bool) {
    require (msg.sender == owner);

    if (_value > 0) {
      if (_value <= accounts [msg.sender]) {
        accounts [msg.sender] = safeSub (accounts [msg.sender], _value);
        tokensCount = safeSub (tokensCount, _value);

        Transfer (msg.sender, address (0), _value);

        return true;
      } else return false;
    } else return true;
  }

   
  function freezeTransfers () public delegatable payable {
    require (msg.sender == owner);

    if (!frozen) {
      frozen = true;

      Freeze ();
    }
  }

   
  function unfreezeTransfers () public delegatable payable {
    require (msg.sender == owner);

    if (frozen) {
      frozen = false;

      Unfreeze ();
    }
  }

   
  function setOwner (address _newOwner) public {
    require (msg.sender == owner);

    owner = _newOwner;
  }

   
  function setFeeCollector (address _newFeeCollector)
  public delegatable payable {
    require (msg.sender == owner);

    feeCollector = _newFeeCollector;
  }

   
  function nonce (address _owner) public view delegatable returns (uint256) {
    return nonces [_owner];
  }

   
  function setFeeParameters (
    uint256 _fixedFee,
    uint256 _minVariableFee,
    uint256 _maxVariableFee,
    uint256 _variableFeeNumerator) public delegatable payable {
    require (msg.sender == owner);

    require (_minVariableFee <= _maxVariableFee);
    require (_variableFeeNumerator <= MAX_FEE_NUMERATOR);

    fixedFee = _fixedFee;
    minVariableFee = _minVariableFee;
    maxVariableFee = _maxVariableFee;
    variableFeeNumerator = _variableFeeNumerator;

    FeeChange (
      _fixedFee, _minVariableFee, _maxVariableFee, _variableFeeNumerator);
  }

   
  function getFeeParameters () public delegatable view returns (
    uint256 _fixedFee,
    uint256 _minVariableFee,
    uint256 _maxVariableFee,
    uint256 _variableFeeNumnerator) {
    _fixedFee = fixedFee;
    _minVariableFee = minVariableFee;
    _maxVariableFee = maxVariableFee;
    _variableFeeNumnerator = variableFeeNumerator;
  }

   
  function calculateFee (uint256 _amount)
    public delegatable view returns (uint256 _fee) {
    require (_amount <= MAX_TOKENS_COUNT);

    _fee = safeMul (_amount, variableFeeNumerator) / FEE_DENOMINATOR;
    if (_fee < minVariableFee) _fee = minVariableFee;
    if (_fee > maxVariableFee) _fee = maxVariableFee;
    _fee = safeAdd (_fee, fixedFee);
  }

   
  function setFlags (address _address, uint256 _flags)
  public delegatable payable {
    require (msg.sender == owner);

    addressFlags [_address] = _flags;
  }

   
  function flags (address _address) public delegatable view returns (uint256) {
    return addressFlags [_address];
  }

   
  function setDelegate (address _delegate) public {
    require (msg.sender == owner);

    if (delegate != _delegate) {
      delegate = _delegate;
      Delegation (delegate);
    }
  }

   
  function thisAddress () internal view returns (address) {
    return this;
  }

   
  function messageSenderAddress () internal view returns (address) {
    return msg.sender;
  }

   
  address internal owner;

   
  address internal feeCollector;

   
  uint256 internal tokensCount;

   
  bool internal frozen;

   
  mapping (address => uint256) internal nonces;

   
  uint256 internal fixedFee;

   
  uint256 internal minVariableFee;

   
  uint256 internal maxVariableFee;

   
  uint256 internal variableFeeNumerator;

   
  mapping (address => uint256) internal addressFlags;

   
  address internal delegate;

   
  event Freeze ();

   
  event Unfreeze ();

   
  event FeeChange (
    uint256 fixedFee,
    uint256 minVariableFee,
    uint256 maxVariableFee,
    uint256 variableFeeNumerator);

   
  event Delegation (address delegate);
}
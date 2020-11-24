 

pragma solidity ^0.4.19;

 
 
 
 
 

contract Token {
  function balanceOf(address _owner) public view returns (uint256 balance);
  function transfer(address _to, uint256 _value) public returns (bool success);
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
  function approve(address _spender, uint256 _value) public returns (bool success);
}

contract SafeMath {
  function safeMul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    require(c / a == b);
    return c;
  }
  
  function safeDiv(uint256 a, uint256 b) internal pure returns (uint256 c) {
    require(b > 0);  
    c = a / b;
    return c;
  }


  function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    return a - b;
  }


  function safeAdd(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    require(c >= a);
    return c;
  }
}

contract OwnerManager {

  address public owner;
  address public newOwner;
  address public manager;

  event OwnershipTransferProposed(address indexed _from, address indexed _to);
  event OwnershipTransferConfirmed(address indexed _from, address indexed _to);
  event NewManager(address indexed _newManager);


  modifier onlyOwner {
    assert(msg.sender == owner);
    _;
  }
  
  modifier onlyManager {
    assert(msg.sender == manager);
    _;
  }


  function OwnerManager() public{
    owner = msg.sender;
    manager = msg.sender;
  }


  function transferOwnership(address _newOwner) onlyOwner external{
    require(_newOwner != owner);
    
    OwnershipTransferProposed(owner, _newOwner);
    
    newOwner = _newOwner;
  }


  function confirmOwnership() external {
    assert(msg.sender == newOwner);
    
    OwnershipTransferConfirmed(owner, newOwner);
    
    owner = newOwner;
  }


  function newManager(address _newManager) onlyOwner external{
    require(_newManager != address(0x0));
    
    NewManager(_newManager);
    
    manager = _newManager;
  }

}


contract Helper is OwnerManager {

  mapping (address => bool) public isHelper;

  modifier onlyHelper {
    assert(isHelper[msg.sender] == true);
    _;
  }

  event ChangeHelper(
    address indexed helper,
    bool status
  );

  function Helper() public{
    isHelper[msg.sender] = true;
  }

  function changeHelper(address _helper, bool _status) external onlyManager {
	  ChangeHelper(_helper, _status);
    isHelper[_helper] = _status;
  }

}


contract Compliance {
  function canDeposit(address _user) public view returns (bool isAllowed);
  function canTrade(address _token, address _user) public view returns (bool isAllowed);
  function validateTrade(
    address _token,
    address _getUser,
    address _giveUser
  )
    public
    view
    returns (bool isAllowed)
  ;
}

contract OptionRegistry {
  function registerOptionPair(
    address _assetTokenAddress,
    uint256 _assetTokenAmount,
    address _strikeTokenAddress,
    uint256 _strikeTokenAmount,
    uint256 _optionExpires
  )
  public
  returns(bool)
  ;
  
  function isOptionPairRegistered(
    address _assetTokenAddress,
    uint256 _assetTokenAmount,
    address _strikeTokenAddress,
    uint256 _strikeTokenAmount,
    uint256 _optionExpires
  )
  public
  view
  returns(bool)  
  ;
  
}

contract EOS {
    function register(string key) public;
}

contract UberDelta is SafeMath, OwnerManager, Helper {

   
  address public feeAccount;
  
   
  address public sweepAccount;
  
   
  address public complianceAddress;
  
   
  address public optionsRegistryAddress;
  
   
  address public newExchange;

   
  bool public contractLocked;
  
  bytes32 signedTradeHash = keccak256(
    "address contractAddress",
    "address takerTokenAddress",
    "uint256 takerTokenAmount",
    "address makerTokenAddress",
    "uint256 makerTokenAmount",
    "uint256 tradeExpires",
    "uint256 salt",
    "address maker",
    "address restrictedTo"
  );
  
  bytes32 signedWithdrawHash = keccak256(
    "address contractAddress",
    "uint256 amount",
    "uint256 fee",
    "uint256 withdrawExpires",
    "uint256 salt",
    "address maker",
    "address restrictedTo"
  );


   
  mapping (address => mapping (address => uint256)) public balances;
  
   
  mapping (address => uint256) public globalBalance;
  
   
  mapping (bytes32 => bool) public orders;
  
   
  mapping (bytes32 => uint256) public orderFills;
  
   
  mapping (address => bool) public restrictedTokens;

   
  mapping (uint256 => uint256) public feeByClass;
  
   
  mapping (address => uint256) public userClass; 
  
  
   
  
   
  event Order(
    bytes32 indexed tradePair,
    address indexed maker,
    address[4] addressData,
    uint256[4] numberData
  );
  
  event Cancel(
    bytes32 indexed tradePair,
    address indexed maker,
    address[4] addressData,
    uint256[4] numberData,
    uint256 status
  );
  
   event FailedTrade( 
    bytes32 indexed tradePair,
    address indexed taker,
    bytes32 hash,
    uint256 failReason
  ); 
  
  event Trade( 
    bytes32 indexed tradePair,
    address indexed maker,
    address indexed taker,
    address makerToken,
    address takerToken,
    address restrictedTo,
    uint256[4] numberData,
    uint256 tradeAmount,
    bool fillOrKill
  );
  
  event Deposit(
    address indexed token,
    address indexed toUser,
    address indexed sender,
    uint256 amount
  );
  
  event Withdraw(
    address indexed token,
    address indexed toUser,
    uint256 amount
  );

  event InternalTransfer(
    address indexed token,
    address indexed toUser,
    address indexed sender,
    uint256 amount
  );

  event TokenSweep(
    address indexed token,
    address indexed sweeper,
    uint256 amount,
    uint256 balance
  );
  
  event RestrictToken(
    address indexed token,
    bool status
  );
  
  event NewExchange(
    address newExchange
  );
  
  event ChangeFeeAccount(
    address feeAccount
  );
  
  event ChangeSweepAccount(
    address sweepAccount
  );
  
  event ChangeClassFee(
    uint256 indexed class,
    uint256 fee
  );
  
  event ChangeUserClass(
    address indexed user,
    uint256 class
  );
  
  event LockContract(
    bool status
  );
  
  event UpdateComplianceAddress(
    address newComplianceAddress
  );
  
  event UpdateOptionsRegistryAddress(
    address newOptionsRegistryAddress
  );
  
  event Upgrade(
    address indexed user,
    address indexed token,
    address newExchange,
    uint256 amount
  );
  
  event RemoteWithdraw(
    address indexed maker,
    address indexed sender,
    uint256 withdrawAmount,
    uint256 feeAmount,
    uint256 withdrawExpires,
    uint256 salt,
    address restrictedTo
  );
  
  event CancelRemoteWithdraw(
    address indexed maker,
    uint256 withdrawAmount,
    uint256 feeAmount,
    uint256 withdrawExpires,
    uint256 salt,
    address restrictedTo,
    uint256 status
  );

   
  function UberDelta() public {
    feeAccount = owner;
    sweepAccount = owner;
    feeByClass[0x0] = 3000000000000000;
    contractLocked = false;
    complianceAddress = this;
    optionsRegistryAddress = this;
  }


   
  function() public {
    revert();
  }
  
  
  
   
  function changeNewExchange(address _newExchange) external onlyOwner {
     
     
    
    newExchange = _newExchange;
    
    NewExchange(_newExchange);
  }


  function changeFeeAccount(address _feeAccount) external onlyManager {
    require(_feeAccount != address(0x0));
    
    feeAccount = _feeAccount;
    
    ChangeFeeAccount(_feeAccount);
  }

  function changeSweepAccount(address _sweepAccount) external onlyManager {
    require(_sweepAccount != address(0x0));
    
    sweepAccount = _sweepAccount;
    
    ChangeSweepAccount(_sweepAccount);
  }

  function changeClassFee(uint256 _class, uint256 _fee) external onlyManager {
    require(_fee <= 10000000000000000);  

    feeByClass[_class] = _fee;

    ChangeClassFee(_class, _fee);
  }
  
  function changeUserClass(address _user, uint256 _newClass) external onlyHelper {
    userClass[_user] = _newClass;
    
    ChangeUserClass(_user, _newClass);
  }
  
   
  function lockContract(bool _lock) external onlyManager {
    contractLocked = _lock;
    
    LockContract(_lock);
  }
  
  function updateComplianceAddress(address _newComplianceAddress)
    external
    onlyManager
  {
    complianceAddress = _newComplianceAddress;
    
    UpdateComplianceAddress(_newComplianceAddress);
  }

  function updateOptionsRegistryAddress(address _newOptionsRegistryAddress)
    external
    onlyManager
  {
    optionsRegistryAddress = _newOptionsRegistryAddress;
    
    UpdateOptionsRegistryAddress(_newOptionsRegistryAddress);
  }


   
  function tokenRestriction(address _newToken, bool _status) external onlyHelper {
    restrictedTokens[_newToken] = _status;
    
    RestrictToken(_newToken, _status);
  }

  
   
  modifier notLocked() {
    require(!contractLocked);
    _;
  }
  
  
   
  
   
  
   
  function deposit() external notLocked payable returns(uint256) {
    require(Compliance(complianceAddress).canDeposit(msg.sender)); 
     
    
    balances[address(0x0)][msg.sender] = safeAdd(balances[address(0x0)][msg.sender], msg.value);
    globalBalance[address(0x0)] = safeAdd(globalBalance[address(0x0)], msg.value);

    Deposit(0x0, msg.sender, msg.sender, msg.value);
    
    return(msg.value);
  }

   
  function withdraw(uint256 _amount) external returns(uint256) {
     
     
    
    balances[address(0x0)][msg.sender] = safeSub(balances[address(0x0)][msg.sender], _amount);
    globalBalance[address(0x0)] = safeSub(globalBalance[address(0x0)], _amount);
 
     
    msg.sender.transfer(_amount);
    
    Withdraw(0x0, msg.sender, _amount);
    
    return(_amount);
  }


   
   
   
  function depositToken(address _token, uint256 _amount) external notLocked returns(uint256) {
    require(_token != address(0x0));
    
    require(Compliance(complianceAddress).canDeposit(msg.sender));

    balances[_token][msg.sender] = safeAdd(balances[_token][msg.sender], _amount);
    globalBalance[_token] = safeAdd(globalBalance[_token], _amount);
    
    require(Token(_token).transferFrom(msg.sender, this, _amount));

    Deposit(_token, msg.sender, msg.sender, _amount);
    
    return(_amount);
  }

   
  function withdrawToken(address _token, uint256 _amount)
    external
    returns (uint256)
  {
    if (_token == address(0x0)){
       
       
       
      balances[address(0x0)][msg.sender] = safeSub(balances[address(0x0)][msg.sender], _amount);
      globalBalance[address(0x0)] = safeSub(globalBalance[address(0x0)], _amount);

       
      msg.sender.transfer(_amount);
    } else {
       
       
 
      balances[_token][msg.sender] = safeSub(balances[_token][msg.sender], _amount);
      globalBalance[_token] = safeSub(globalBalance[_token], _amount);

      require(Token(_token).transfer(msg.sender, _amount));
    }    

    Withdraw(_token, msg.sender, _amount);
    
    return _amount;
  }

   
   
  function depositToUser(address _toUser) external payable notLocked returns (bool success) {
    require(
        (_toUser != address(0x0))
     && (_toUser != address(this))
     && (Compliance(complianceAddress).canDeposit(_toUser))
    );
    
    balances[address(0x0)][_toUser] = safeAdd(balances[address(0x0)][_toUser], msg.value);
    globalBalance[address(0x0)] = safeAdd(globalBalance[address(0x0)], msg.value);
    
    Deposit(0x0, _toUser, msg.sender, msg.value);
    
    return true;
  }

   
   
   
   
  function depositTokenToUser(
    address _toUser,
    address _token,
    uint256 _amount
  )
    external
    notLocked
    returns (bool success)
  {
    require(
        (_token != address(0x0))

     && (_toUser  != address(0x0))
     && (_toUser  != address(this))
     && (_toUser  != _token)
     && (Compliance(complianceAddress).canDeposit(_toUser))
    );
    
    balances[_token][_toUser] = safeAdd(balances[_token][_toUser], _amount);
    globalBalance[_token] = safeAdd(globalBalance[_token], _amount);

    require(Token(_token).transferFrom(msg.sender, this, _amount));

    Deposit(_token, _toUser, msg.sender, _amount);
    
    return true;
  }


   
   
  function tokenFallback(
    address _from,   
    uint256 _value,  
    bytes _sendTo      
    
  )
    external
    notLocked
  {
     
    address toUser = _from;      
    if (_sendTo.length == 20){   

       
       
       
      
      uint256 asmAddress;
      assembly {  
        asmAddress := calldataload(120)
      }
      toUser = address(asmAddress);
    }
    
     
    require(
        (toUser != address(0x0))
     && (toUser != address(this))
     && (toUser != msg.sender)   
     && (Compliance(complianceAddress).canDeposit(toUser))
    );
    
     
    uint256 codeLength;
    assembly {
      codeLength := extcodesize(caller)
    }
    require(codeLength > 0);    
    
    globalBalance[msg.sender] = safeAdd(globalBalance[msg.sender], _value);
    balances[msg.sender][toUser] = safeAdd(balances[msg.sender][toUser], _value);
    
     
    require(Token(msg.sender).balanceOf(this) >= _value);

    Deposit(msg.sender, toUser, _from, _value);
  }

   
  function internalTransfer(
    address _toUser,
    address _token,
    uint256 _amount
  )
    external
    notLocked 
    returns(uint256)
  {
    require(
        (balances[_token][msg.sender] >= _amount)
     && (_toUser != address(0x0))
     && (_toUser != address(this))
     && (_toUser != _token)
     && (Compliance(complianceAddress).canDeposit(_toUser))
    );
 
    balances[_token][msg.sender] = safeSub(balances[_token][msg.sender], _amount);
    balances[_token][_toUser] = safeAdd(balances[_token][_toUser], _amount);

    InternalTransfer(_token, _toUser, msg.sender, _amount);
    
    return(_amount);
  }
  
   
  function balanceOf(address _token, address _user) external view returns (uint) {
    return balances[_token][_user];
  }

  
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
    
   
   
  function sweepTokenAmount(address _token, uint256 _amount) external returns(uint256) {
    assert(msg.sender == sweepAccount);

    balances[_token][sweepAccount] = safeAdd(balances[_token][sweepAccount], _amount);
    globalBalance[_token] = safeAdd(globalBalance[_token], _amount);
    
     
	if(_token != address(0x0)) { 
      require(globalBalance[_token] <= Token(_token).balanceOf(this));
	} else {
	   
     
	  require(globalBalance[address(0x0)] <= this.balance); 
	}
    
    TokenSweep(_token, msg.sender, _amount, balances[_token][sweepAccount]);
    
    return(_amount);
  }
  
  
   
  
   
  
  
   
   
  function order(
    address[4] _addressData,
    uint256[4] _numberData  
  )
    external
    notLocked
    returns (bool success)
  {
  
 
    if (msg.sender != _addressData[2]) { return false; }
    
    bytes32 hash = getHash(_addressData, _numberData);

    orders[hash] = true;

    Order(
      (bytes32(_addressData[0]) ^ bytes32(_addressData[1])),
      msg.sender,
      _addressData,
      _numberData);
    
    return true;
  }  


  function tradeBalances(
    address _takerTokenAddress,
    uint256 _takerTokenAmount,
    address _makerTokenAddress,
    uint256 _makerTokenAmount,
    address _maker,
    uint256 _tradeAmount
  )
    internal
  {
    require(_takerTokenAmount > 0);  

     
    uint256 feeValue = safeMul(_tradeAmount, feeByClass[userClass[msg.sender]]) / (1 ether);
    
    balances[_takerTokenAddress][_maker] =
      safeAdd(balances[_takerTokenAddress][_maker], _tradeAmount);
    balances[_takerTokenAddress][msg.sender] =
      safeSub(balances[_takerTokenAddress][msg.sender], safeAdd(_tradeAmount, feeValue));
    
    balances[_makerTokenAddress][_maker] =
      safeSub(
        balances[_makerTokenAddress][_maker],
        safeMul(_makerTokenAmount, _tradeAmount) / _takerTokenAmount
      );
    balances[_makerTokenAddress][msg.sender] =
      safeAdd(
        balances[_makerTokenAddress][msg.sender],
        safeMul(_makerTokenAmount, _tradeAmount) / _takerTokenAmount
      );
    
    balances[_takerTokenAddress][feeAccount] =
      safeAdd(balances[_takerTokenAddress][feeAccount], feeValue);
  }


  function trade(
    address[4] _addressData,
    uint256[4] _numberData,  
    uint8 _v,
    bytes32 _r,
    bytes32 _s,
    uint256 _amount,
    bool _fillOrKill
  )
    external
    notLocked
    returns(uint256 tradeAmount)
  {
  
 
 
 
 
 
 
 
 
    
    bytes32 hash = getHash(_addressData, _numberData);
    
    tradeAmount = safeSub(_numberData[0], orderFills[hash]);  
    
     
    if (
      tradeAmount > safeDiv(
        safeMul(balances[_addressData[1]][_addressData[2]], _numberData[0]),
        _numberData[1]
      )
    )
    {
      tradeAmount = safeDiv(
        safeMul(balances[_addressData[1]][_addressData[2]], _numberData[0]),
        _numberData[1]
      );
    }
    
    if (tradeAmount > _amount) { tradeAmount = _amount; }
    
         
    if (tradeAmount == 0) {  
      if (orderFills[hash] < _numberData[0]) {  
        FailedTrade(
          (bytes32(_addressData[0]) ^ bytes32(_addressData[1])),
          msg.sender,
          hash,
          0
        );
      } else {   
        FailedTrade(
          (bytes32(_addressData[0]) ^ bytes32(_addressData[1])),
          msg.sender,
          hash,
          1
        );
      }
      return 0;
    }
    
    
    if (block.number > _numberData[2]) {  
      FailedTrade(
        (bytes32(_addressData[0]) ^ bytes32(_addressData[1])),
        msg.sender,
        hash,
        2
      );
      return 0;
    }


    if ((_fillOrKill == true) && (tradeAmount < _amount)) {  
      FailedTrade(
        (bytes32(_addressData[0]) ^ bytes32(_addressData[1])),
        msg.sender,
        hash,
        3
      );
      return 0;
    }
    
        
    uint256 feeValue = safeMul(_amount, feeByClass[userClass[msg.sender]]) / (1 ether);

     
    if ( (_amount + feeValue) > balances[_addressData[0]][msg.sender])  { 
      FailedTrade(
        (bytes32(_addressData[0]) ^ bytes32(_addressData[1])),
        msg.sender,
        hash,
        4
      );
      return 0;
    }
    
    if (  
        (ecrecover(keccak256(signedTradeHash, hash), _v, _r, _s) != _addressData[2])
        && (! orders[hash])
    )
    {
      FailedTrade(
        (bytes32(_addressData[0]) ^ bytes32(_addressData[1])),
        msg.sender,
        hash,
        5
      );
      return 0;
    }

    
    if ((_addressData[3] != address(0x0)) && (_addressData[3] != msg.sender)) {  
      FailedTrade(
        (bytes32(_addressData[0]) ^ bytes32(_addressData[1])),
        msg.sender,
        hash,
        6
      );
      return 0;
    }
        
    
    if (  
      ((_addressData[0] != address(0x0))  
        && (restrictedTokens[_addressData[0]] )
        && ! Compliance(complianceAddress).validateTrade(_addressData[0], _addressData[2], msg.sender)
      )
      || ((_addressData[1] != address(0x0))   
        && (restrictedTokens[_addressData[1]])
        && ! Compliance(complianceAddress).validateTrade(_addressData[1], _addressData[2], msg.sender)
      )
    )
    {
      FailedTrade(
        (bytes32(_addressData[0]) ^ bytes32(_addressData[1])),
        msg.sender,
        hash,
        7
      );
      return 0;
    }
    
     
    
    tradeBalances(
      _addressData[0],  
      _numberData[0],  
      _addressData[1],  
      _numberData[1],  
      _addressData[2],  
      tradeAmount
    );

    orderFills[hash] = safeAdd(orderFills[hash], tradeAmount);

    Trade(
      (bytes32(_addressData[0]) ^ bytes32(_addressData[1])),
      _addressData[2],
      msg.sender,
      _addressData[1],
      _addressData[0],
      _addressData[3],
      _numberData,
      tradeAmount,
      _fillOrKill
    );
    
    return(tradeAmount);
  }
  
  
   
  function cancelOrder(
    address[4] _addressData,
    uint256[4] _numberData  
  )
    external
    returns(uint256 amountCancelled)
  {
    
    require(msg.sender == _addressData[2]);
    
     
    bytes32 hash = getHash(_addressData, _numberData);
 
    amountCancelled = safeSub(_numberData[0],orderFills[hash]);
    
    orderFills[hash] = _numberData[0];
 
     
 
    Cancel(
      (bytes32(_addressData[0]) ^ bytes32(_addressData[1])),
      msg.sender,
      _addressData,
      _numberData,
      amountCancelled);

    return amountCancelled;    
  }



   
  
   
   
   
  function remoteWithdraw(
    uint256 _withdrawAmount,
    uint256 _feeAmount,
    uint256 _withdrawExpires,
    uint256 _salt,
    address _maker,
    address _restrictedTo,  
    uint8 _v,
    bytes32 _r,
    bytes32 _s
  )
    external
    notLocked
    returns(bool)
  {
     
    require(
        (balances[address(0x0)][_maker] >= safeAdd(_withdrawAmount, _feeAmount))
     && (
            (_restrictedTo == address(0x0))
         || (_restrictedTo == msg.sender)
        )
     && ((_feeAmount == 0) || (Compliance(complianceAddress).canDeposit(msg.sender)))
    );
    
     

    bytes32 hash = keccak256(
      this, 
      _withdrawAmount,
      _feeAmount,
      _withdrawExpires,
      _salt,
      _maker,
      _restrictedTo
    );

    require(orderFills[hash] == 0);

     
    require(
      ecrecover(keccak256(signedWithdrawHash, hash), _v, _r, _s) == _maker
    );
    
     
    orderFills[hash] = 1;

    balances[address(0x0)][_maker] =
      safeSub(balances[address(0x0)][_maker], safeAdd(_withdrawAmount, _feeAmount));
     
    balances[address(0x0)][msg.sender] = safeAdd(balances[address(0x0)][msg.sender], _feeAmount);
    
    globalBalance[address(0x0)] = safeSub(globalBalance[address(0x0)], _withdrawAmount);

    RemoteWithdraw(
      _maker,
      msg.sender,
      _withdrawAmount,
      _feeAmount,
      _withdrawExpires,
      _salt,
      _restrictedTo
    );

     
    _maker.transfer(_withdrawAmount);
    
    return(true);
  }

   
  function cancelRemoteWithdraw(
    uint256 _withdrawAmount,
    uint256 _feeAmount,
    uint256 _withdrawExpires,
    uint256 _salt,
    address _restrictedTo  
  )
    external
  {
       
    bytes32 hash = keccak256(
      this, 
      _withdrawAmount,
      _feeAmount,
      _withdrawExpires,
      _salt,
      msg.sender,
      _restrictedTo
    );
    
    CancelRemoteWithdraw(
      msg.sender,
      _withdrawAmount,
      _feeAmount,
      _withdrawExpires,
      _salt,
      _restrictedTo,
      orderFills[hash]
    );
    
     
    orderFills[hash] = 1;
  }
  
  
 

   
      
   
  function upgrade(address _token) external returns(uint256 moveBalance) {
    require (newExchange != address(0x0));

    moveBalance = balances[_token][msg.sender];

    globalBalance[_token] = safeSub(globalBalance[_token], moveBalance);
    balances[_token][msg.sender] = 0;

    if (_token != address(0x0)){
      require(Token(_token).approve(newExchange, moveBalance));
      require(UberDelta(newExchange).depositTokenToUser(msg.sender, _token, moveBalance));
    } else {
      require(UberDelta(newExchange).depositToUser.value(moveBalance)(msg.sender));
    }

    Upgrade(msg.sender, _token, newExchange, moveBalance);
    
    return(moveBalance);
  }


  
   
  
  function testTrade(
    address[4] _addressData,
    uint256[4] _numberData,  
    uint8 _v,
    bytes32 _r,
    bytes32 _s,
    uint256 _amount,
    address _sender,
    bool _fillOrKill
  )
    public
    view
    returns(uint256)
  {
    uint256 feeValue = safeMul(_amount, feeByClass[userClass[_sender]]) / (1 ether);

    if (
      contractLocked
      ||
      ((_addressData[0] != address(0x0))  
        && (restrictedTokens[_addressData[0]] )
        && ! Compliance(complianceAddress).validateTrade(_addressData[0], _addressData[2], _sender)
      )
      || ((_addressData[1] != address(0x0))   
        && (restrictedTokens[_addressData[1]])
        && ! Compliance(complianceAddress).validateTrade(_addressData[1], _addressData[2], _sender)
      )
          
      || ((_amount + feeValue) > balances[_addressData[0]][_sender]) 
      || ((_addressData[3] != address(0x0)) && (_addressData[3] != _sender))  
    )
    {
      return 0;
    }
      
    uint256 tradeAmount = availableVolume(
        _addressData,
        _numberData,
        _v,
        _r,
        _s
    );
    
    if (tradeAmount > _amount) { tradeAmount = _amount; }
    
    if ((_fillOrKill == true) && (tradeAmount < _amount)) {
      return 0;
    }

    return tradeAmount;
  }


   
   
  function availableVolume(
    address[4] _addressData,
    uint256[4] _numberData,  
    uint8 _v,
    bytes32 _r,
    bytes32 _s
  )
    public
    view
    returns(uint256 amountRemaining)
  {     
 
 
 
 
 
 
 
 

    bytes32 hash = getHash(_addressData, _numberData);

    if (
      (block.number > _numberData[2])
      || ( 
        (ecrecover(keccak256(signedTradeHash, hash), _v, _r, _s) != _addressData[2])
        && (! orders[hash])
      )
    ) { return 0; }

     
     amountRemaining = safeSub(_numberData[0], orderFills[hash]);

    if (
      amountRemaining < safeDiv(
        safeMul(balances[_addressData[1]][_addressData[2]], _numberData[0]),
        _numberData[1]
      )
    ) return amountRemaining;

    return (
      safeDiv(
        safeMul(balances[_addressData[1]][_addressData[2]], _numberData[0]),
        _numberData[1]
      )
    );
  }


   
   
  function getUserFee(
    address _user
  )
    external
    view
    returns(uint256)
  {
    return feeByClass[userClass[_user]];
  }


   
   
  function amountFilled(
    address[4] _addressData,
    uint256[4] _numberData  
  )
    external
    view
    returns(uint256)
  {
    bytes32 hash = getHash(_addressData, _numberData);

    return orderFills[hash];
  }

  
   
  function testRemoteWithdraw(
    uint256 _withdrawAmount,
    uint256 _feeAmount,
    uint256 _withdrawExpires,
    uint256 _salt,
    address _maker,
    address _restrictedTo,
    uint8 _v,
    bytes32 _r,
    bytes32 _s,
    address _sender
  )
    external
    view
    returns(uint256)
  {
    bytes32 hash = keccak256(
      this,
      _withdrawAmount,
      _feeAmount,
      _withdrawExpires,
      _salt,
      _maker,
      _restrictedTo
    );

    if (
      contractLocked
      ||
      (balances[address(0x0)][_maker] < safeAdd(_withdrawAmount, _feeAmount))
      ||((_restrictedTo != address(0x0)) && (_restrictedTo != _sender))
      || (orderFills[hash] != 0)
      || (ecrecover(keccak256(signedWithdrawHash, hash), _v, _r, _s) != _maker)
      || ((_feeAmount > 0) && (! Compliance(complianceAddress).canDeposit(_sender)))
    )
    {
      return 0;
    } else {
      return _withdrawAmount;
    }
  }
  
  
  
  function getHash(
    address[4] _addressData,
    uint256[4] _numberData  
  )
    public
    view
    returns(bytes32)
  {
    return(
      keccak256(
        this,
        _addressData[0],  
        _numberData[0],  
        _addressData[1],  
        _numberData[1],  
        _numberData[2],  
        _numberData[3],  
        _addressData[2],  
        _addressData[3]  
      )
    );
  }
  
  

   
   
   

    function testCanDeposit(
    address _user
  )
    external
    view
    returns (bool)
  {
    return(Compliance(complianceAddress).canDeposit(_user));
  }
  
  function testCanTrade(
    address _token,
    address _user
  )
    external
    view
    returns (bool)
  {
    return(Compliance(complianceAddress).canTrade(_token, _user));
  }

  
  function testValidateTrade(
    address _token,
    address _getUser,
    address _giveUser
  )
    external
    view
    returns (bool isAllowed)
  {
    return(Compliance(complianceAddress).validateTrade(_token, _getUser, _giveUser));
  }
  


   
   
   
   
   
  function canDeposit(
    address _user
  )
    public
    view
    returns (bool isAllowed)
  {
    return(true);
  }
  
  function canTrade(
    address _token,
    address _user
  )
    public
    view
    returns (bool isAllowed)
  {
    return(false);
  }

  
  function validateTrade(
    address _token,
    address _getUser,
    address _giveUser
  )
    public
    view
    returns (bool isAllowed)
  {
    return(false);
  }
  


   
  
  
  mapping (address => uint256) public exercisedOptions;
  
   
  event CollapseOption(
    address indexed user,
    address indexed holderTicketAddress,
    address indexed writerTicketAddress,
    uint256 ticketsCollapsed,
    bytes32 optionPair  
  );    
  
   
  event ExcerciseUnwind(
    address indexed user,
    address indexed holderTicketAddress,
    uint256 ticketsUnwound,
    bytes32 optionPair,
    bool fillOrKill
  );  
  
   
  event ExpireOption(
    address indexed user,
    address indexed writerTicketAddress,
    uint256 ticketsExpired,
    bytes32 optionPair
  );  
  
   
  event CreateOption(
    address indexed user,
    address indexed holderTicketAddress,
    address indexed writerTicketAddress,
    uint256 ticketsCreated,
    bytes32 optionPair
  );  
  
   
  event ExcerciseOption(
    address indexed user,
    address indexed holderTicketAddress,
    uint256 ticketsExcercised,
    bytes32 optionPair  
  );  
  
   
  
   
   
  function createOptionPair(  
    address _assetTokenAddress,
    uint256 _assetTokenAmount,
    address _strikeTokenAddress,
    uint256 _strikeTokenAmount,
    uint256 _optionExpires,
    uint256 _ticketAmount  
  )
    external
    notLocked
    returns (uint256 ticketsCreated)
  {
     
    require (block.number < _optionExpires);  
    
     
     

     
     
     
    balances[_assetTokenAddress][0x0] =
      safeAdd(
        balances[_assetTokenAddress][0x0],
        safeDiv(safeMul(_assetTokenAmount, _ticketAmount), 1 ether)
      );

    balances[_assetTokenAddress][msg.sender] =
      safeSub(
        balances[_assetTokenAddress][msg.sender],
        safeDiv(safeMul(_assetTokenAmount, _ticketAmount), 1 ether)
      );
    
    
    address holderTicketAddress = getOptionAddress(
      _assetTokenAddress,
      _assetTokenAmount,
      _strikeTokenAddress,
      _strikeTokenAmount,
      _optionExpires,
      false
    );
    
    address writerTicketAddress = getOptionAddress(
      _assetTokenAddress,
      _assetTokenAmount,
      _strikeTokenAddress,
      _strikeTokenAmount,
      _optionExpires,
      true
    );
    
     
    balances[writerTicketAddress][msg.sender] =
      safeAdd(balances[writerTicketAddress][msg.sender], _ticketAmount);
    globalBalance[writerTicketAddress] =
      safeAdd(globalBalance[writerTicketAddress], _ticketAmount);

     
    balances[holderTicketAddress][msg.sender] =
      safeAdd(balances[holderTicketAddress][msg.sender], _ticketAmount);
    globalBalance[holderTicketAddress] =
      safeAdd(globalBalance[holderTicketAddress], _ticketAmount);

    CreateOption(
      msg.sender,
      holderTicketAddress,
      writerTicketAddress,
      _ticketAmount,
      (bytes32(_assetTokenAddress) ^ bytes32(_strikeTokenAddress))
    );
    
     
    if (
      OptionRegistry(optionsRegistryAddress).isOptionPairRegistered(
        _assetTokenAddress,
        _assetTokenAmount,
        _strikeTokenAddress,
        _strikeTokenAmount,
        _optionExpires
      )
      == false
    )
    {
      require(
        OptionRegistry(optionsRegistryAddress).registerOptionPair(
          _assetTokenAddress,
          _assetTokenAmount,
          _strikeTokenAddress,
          _strikeTokenAmount,
          _optionExpires
        )
      );
    }
    return _ticketAmount;
  }
  
   
   
  function collapseOptionPair(  
    address _assetTokenAddress,
    uint256 _assetTokenAmount,
    address _strikeTokenAddress,
    uint256 _strikeTokenAmount,
    uint256 _optionExpires,
    uint256 _ticketAmount
  )
    external
    returns (uint256 ticketsCollapsed)
  {
    
    address holderTicketAddress = getOptionAddress(
      _assetTokenAddress,
      _assetTokenAmount,
      _strikeTokenAddress,
      _strikeTokenAmount,
      _optionExpires,
      false
    );
    
    address writerTicketAddress = getOptionAddress(
      _assetTokenAddress,
      _assetTokenAmount,
      _strikeTokenAddress,
      _strikeTokenAmount,
      _optionExpires,
      true
    );
    
     
     
    require (
      (balances[holderTicketAddress][msg.sender] >= _ticketAmount)
      && (balances[writerTicketAddress][msg.sender] >= _ticketAmount)
    );
     
    
     
    balances[writerTicketAddress][msg.sender] =
      safeSub(balances[writerTicketAddress][msg.sender], _ticketAmount);
    globalBalance[writerTicketAddress] =
      safeSub(globalBalance[writerTicketAddress], _ticketAmount);

     
    balances[holderTicketAddress][msg.sender] =
      safeSub(balances[holderTicketAddress][msg.sender], _ticketAmount);
    globalBalance[holderTicketAddress] =
      safeSub(globalBalance[holderTicketAddress], _ticketAmount);
 
     
    balances[_assetTokenAddress][0x0] = safeSub(
      balances[_assetTokenAddress][0x0],
      safeDiv(safeMul(_assetTokenAmount, _ticketAmount), 1 ether)
    );

    balances[_assetTokenAddress][msg.sender] = safeAdd(
      balances[_assetTokenAddress][msg.sender],
      safeDiv(safeMul(_assetTokenAmount, _ticketAmount), 1 ether)
    );
    
     
    CollapseOption(
      msg.sender,
      holderTicketAddress,
      writerTicketAddress,
      _ticketAmount,
      (bytes32(_assetTokenAddress) ^ bytes32(_strikeTokenAddress))
    );
    
    return _ticketAmount;
  }

   

   
 

  function optionExcerciseUnwind(
    address _assetTokenAddress,
    uint256 _assetTokenAmount,
    address _strikeTokenAddress,
    uint256 _strikeTokenAmount,
    uint256 _optionExpires,
    uint256 _ticketAmount,
    bool _fillOrKill  
  )
    external
    notLocked
    returns (uint256 ticketsUnwound)  
  {
     
    require(block.number <= _optionExpires);
    
    address holderTicketAddress = getOptionAddress(
      _assetTokenAddress,
      _assetTokenAmount,
      _strikeTokenAddress,
      _strikeTokenAmount,
      _optionExpires,
      false
    );
    
     
    ticketsUnwound = exercisedOptions[holderTicketAddress];

     
    require((_fillOrKill == false) || (ticketsUnwound >= _ticketAmount));

     
    if (ticketsUnwound > _ticketAmount) ticketsUnwound = _ticketAmount;
    
    require(ticketsUnwound > 0);
     
 
     
    require(
      (! restrictedTokens[holderTicketAddress])  
    || Compliance(complianceAddress).canTrade(holderTicketAddress, msg.sender)  
    );

     
    balances[_assetTokenAddress][msg.sender] = safeSub(
      balances[_assetTokenAddress][msg.sender],
      safeDiv(safeMul(_assetTokenAmount, ticketsUnwound), 1 ether)
    );

    balances[_assetTokenAddress][0x0] = safeAdd(
      balances[_assetTokenAddress][0x0],
      safeDiv(safeMul(_assetTokenAmount, ticketsUnwound), 1 ether)
    );
    
     
     
    exercisedOptions[holderTicketAddress] =
      safeSub(exercisedOptions[holderTicketAddress], ticketsUnwound);
    balances[holderTicketAddress][msg.sender] =
      safeAdd(balances[holderTicketAddress][msg.sender], ticketsUnwound);

     
    balances[_strikeTokenAddress][0x0] = safeSub(
      balances[_strikeTokenAddress][0x0],
      safeDiv(safeMul(_strikeTokenAmount, ticketsUnwound), 1 ether)
    );

    balances[_strikeTokenAddress][msg.sender] = safeAdd(
      balances[_strikeTokenAddress][msg.sender],
      safeDiv(safeMul(_strikeTokenAmount, ticketsUnwound), 1 ether)
    );
    
     
    ExcerciseUnwind(
      msg.sender,
      holderTicketAddress,
      ticketsUnwound,
      (bytes32(_assetTokenAddress) ^ bytes32(_strikeTokenAddress)),
      _fillOrKill
    );
    
    return ticketsUnwound;
  }
  
   
  function excerciseOption(  
    address _assetTokenAddress,
    uint256 _assetTokenAmount,
    address _strikeTokenAddress,
    uint256 _strikeTokenAmount,
    uint256 _optionExpires,
    uint256 _ticketAmount
  )
  external 
  returns (uint256 ticketsExcercised)
  {  
     
    require(block.number <= _optionExpires);
    
    address holderTicketAddress = getOptionAddress(
      _assetTokenAddress,
      _assetTokenAmount,
      _strikeTokenAddress,
      _strikeTokenAmount,
      _optionExpires,
      false
    );
    
     
    ticketsExcercised = balances[holderTicketAddress][msg.sender];
    require(ticketsExcercised >= _ticketAmount);  
    
     
    if (ticketsExcercised > _ticketAmount) ticketsExcercised = _ticketAmount;
    
     
    require(ticketsExcercised > 0);
    
     
    balances[holderTicketAddress][msg.sender] =
      safeSub(balances[holderTicketAddress][msg.sender], ticketsExcercised);
    exercisedOptions[holderTicketAddress] =
      safeAdd(exercisedOptions[holderTicketAddress], ticketsExcercised);
        
     
    balances[_strikeTokenAddress][msg.sender] = safeSub(
      balances[_strikeTokenAddress][msg.sender],
      safeDiv(safeMul(_strikeTokenAmount, ticketsExcercised), 1 ether)
    );

    balances[_strikeTokenAddress][0x0] = safeAdd(
      balances[_strikeTokenAddress][0x0],
      safeDiv(safeMul(_strikeTokenAmount, ticketsExcercised), 1 ether)
    );
    
     
    balances[_assetTokenAddress][0x0] = safeSub(
      balances[_assetTokenAddress][0x0],
      safeDiv(safeMul(_assetTokenAmount, ticketsExcercised), 1 ether)
    );
    
    balances[_assetTokenAddress][msg.sender] = safeAdd(
      balances[_assetTokenAddress][msg.sender],
      safeDiv(safeMul(_assetTokenAmount, ticketsExcercised), 1 ether)
    );

    
     
     
    ExcerciseOption(
      msg.sender,
      holderTicketAddress,
      ticketsExcercised,
      (bytes32(_assetTokenAddress) ^ bytes32(_strikeTokenAddress))
    );
    
    return ticketsExcercised;
  }

  
   
  function expireOption(  
    address _assetTokenAddress,
    uint256 _assetTokenAmount,
    address _strikeTokenAddress,
    uint256 _strikeTokenAmount,
    uint256 _optionExpires,
    uint256 _ticketAmount
  )
  external 
  returns (uint256 ticketsExpired)
  {
   
    require(block.number > _optionExpires);
        
    address holderTicketAddress = getOptionAddress(
      _assetTokenAddress,
      _assetTokenAmount,
      _strikeTokenAddress,
      _strikeTokenAmount,
      _optionExpires,
      false
    );
    
    address writerTicketAddress = getOptionAddress(
      _assetTokenAddress,
      _assetTokenAmount,
      _strikeTokenAddress,
      _strikeTokenAmount,
      _optionExpires,
      true
    );
    
     
    ticketsExpired = balances[writerTicketAddress][msg.sender];
    require(ticketsExpired >= _ticketAmount);  
    
     
    if (ticketsExpired > _ticketAmount) ticketsExpired = _ticketAmount;
    
     
    require(ticketsExpired > 0);
    
     
    balances[writerTicketAddress][msg.sender] =
      safeSub(balances[writerTicketAddress][msg.sender], ticketsExpired);
    exercisedOptions[writerTicketAddress] =
      safeAdd(exercisedOptions[writerTicketAddress], ticketsExpired);
    
     
    uint256 strikeTokenAmount =
      safeDiv(
        safeMul(
          safeDiv(safeMul(ticketsExpired, _strikeTokenAmount), 1 ether),  
          exercisedOptions[holderTicketAddress]
        ),
        globalBalance[holderTicketAddress]
      );

    uint256 assetTokenAmount =
      safeDiv(
        safeMul(
          safeDiv(safeMul(ticketsExpired, _assetTokenAmount), 1 ether),  
          safeSub(globalBalance[holderTicketAddress], exercisedOptions[holderTicketAddress])
        ),
        globalBalance[holderTicketAddress]
      );
    

     
    balances[_strikeTokenAddress][0x0] =
      safeSub(balances[_strikeTokenAddress][0x0], strikeTokenAmount);
    balances[_assetTokenAddress][0x0] =
      safeSub(balances[_assetTokenAddress][0x0], assetTokenAmount);
    balances[_strikeTokenAddress][msg.sender] =
      safeAdd(balances[_strikeTokenAddress][msg.sender], strikeTokenAmount);
    balances[_assetTokenAddress][msg.sender] =
      safeAdd(balances[_assetTokenAddress][msg.sender], assetTokenAmount);
  
   

    ExpireOption(  
      msg.sender,
      writerTicketAddress,
      ticketsExpired,
      (bytes32(_assetTokenAddress) ^ bytes32(_strikeTokenAddress))
    );
    return ticketsExpired;
  }


   
   
   
   
   
  function getOptionAddress(
    address _assetTokenAddress,
    uint256 _assetTokenAmount,
    address _strikeTokenAddress,
    uint256 _strikeTokenAmount,
    uint256 _optionExpires,
    bool _isWriter
  )
    public
    view
    returns(address)
  {
    return(
      address(
        keccak256(
          _assetTokenAddress,
          _assetTokenAmount,
          _strikeTokenAddress,
          _strikeTokenAmount,
          _optionExpires,
          _isWriter
        )
      )
    );
  }

   
   
   
  
  function testIsOptionPairRegistered(
    address _assetTokenAddress,
    uint256 _assetTokenAmount,
    address _strikeTokenAddress,
    uint256 _strikeTokenAmount,
    uint256 _optionExpires
  )
  external
  view
  returns(bool)
  {
    return(
      OptionRegistry(optionsRegistryAddress).isOptionPairRegistered(
        _assetTokenAddress,
        _assetTokenAmount,
        _strikeTokenAddress,
        _strikeTokenAmount,
        _optionExpires
      )
    );
  }
  

   
   
   
   
   
  
  event RegisterOptionsPair(
    bytes32 indexed optionPair,  
    address indexed writerTicketAddress,
    address indexed holderTicketAddress,
    address _assetTokenAddress,
    uint256 _assetTokenAmount,
    address _strikeTokenAddress,
    uint256 _strikeTokenAmount,
    uint256 _optionExpires
  );  
  
    
  function registerOptionPair(
    address _assetTokenAddress,
    uint256 _assetTokenAmount,
    address _strikeTokenAddress,
    uint256 _strikeTokenAmount,
    uint256 _optionExpires
  )
  public
  returns(bool)
  {
    address holderTicketAddress = getOptionAddress(
      _assetTokenAddress,
      _assetTokenAmount,
      _strikeTokenAddress,
      _strikeTokenAmount,
      _optionExpires,
      false
    );
    
 
 
 
 
 
 
 
 
 
     
    
    if (restrictedTokens[holderTicketAddress]) {
      return false;
     
    } else {

      address writerTicketAddress = getOptionAddress(
        _assetTokenAddress,
        _assetTokenAmount,
        _strikeTokenAddress,
        _strikeTokenAmount,
        _optionExpires,
        true
      );
    
      restrictedTokens[holderTicketAddress] = true;
      restrictedTokens[writerTicketAddress] = true;
    
       
       
       
       
    
      RegisterOptionsPair(
        (bytes32(_assetTokenAddress) ^ bytes32(_strikeTokenAddress)),
        holderTicketAddress,
        writerTicketAddress,
        _assetTokenAddress,
        _assetTokenAmount,
        _strikeTokenAddress,
        _strikeTokenAmount,
        _optionExpires
      );
    
      return(true);
    }
  }
  
  
   
  function isOptionPairRegistered(
    address _assetTokenAddress,
    uint256 _assetTokenAmount,
    address _strikeTokenAddress,
    uint256 _strikeTokenAmount,
    uint256 _optionExpires
  )
  public
  view
  returns(bool)
  {
    address holderTicketAddress = getOptionAddress(
      _assetTokenAddress,
      _assetTokenAmount,
      _strikeTokenAddress,
      _strikeTokenAmount,
      _optionExpires,
      false
    );
    
    return(restrictedTokens[holderTicketAddress]);
  }
  
  
  function getOptionPair(
    address _assetTokenAddress,
    uint256 _assetTokenAmount,
    address _strikeTokenAddress,
    uint256 _strikeTokenAmount,
    uint256 _optionExpires
  )
  public
  view
  returns(address holderTicketAddress, address writerTicketAddress)
  {
    holderTicketAddress = getOptionAddress(
      _assetTokenAddress,
      _assetTokenAmount,
      _strikeTokenAddress,
      _strikeTokenAmount,
      _optionExpires,
      false
    );
    
    writerTicketAddress = getOptionAddress(
      _assetTokenAddress,
      _assetTokenAmount,
      _strikeTokenAddress,
      _strikeTokenAmount,
      _optionExpires,
      true
    );
    
    return(holderTicketAddress, writerTicketAddress);
  }
  
  
   
   
  function EOSRegistration (string _key) external onlyOwner{
    EOS(0xd0a6E6C54DbC68Db5db3A091B171A77407Ff7ccf).register(_key);
  }
  
}
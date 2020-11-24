 

pragma solidity 0.4.25;

 

 


interface ERC20Token {
  function name() external view returns (string);
  function symbol() external view returns (string);
  function decimals() external view returns (uint8);
  function totalSupply() external view returns (uint256);
  function balanceOf(address owner) external view returns (uint256);
  function transfer(address to, uint256 amount) external returns (bool);
  function transferFrom(address from, address to, uint256 amount) external returns (bool);
  function approve(address spender, uint256 amount) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint256);

  event Transfer(address indexed from, address indexed to, uint256 amount);
  event Approval(address indexed owner, address indexed spender, uint256 amount);
}

 

contract ERC820Registry {
    function setInterfaceImplementer(address _addr, bytes32 _interfaceHash, address _implementer) external;
    function getInterfaceImplementer(address _addr, bytes32 _interfaceHash) external view returns (address);
    function setManager(address _addr, address _newManager) external;
    function getManager(address _addr) public view returns(address);
}


 
contract ERC820Client {
    ERC820Registry erc820Registry = ERC820Registry(0x820c4597Fc3E4193282576750Ea4fcfe34DdF0a7);

    function setInterfaceImplementation(string _interfaceLabel, address _implementation) internal {
        bytes32 interfaceHash = keccak256(abi.encodePacked(_interfaceLabel));
        erc820Registry.setInterfaceImplementer(this, interfaceHash, _implementation);
    }

    function interfaceAddr(address addr, string _interfaceLabel) internal view returns(address) {
        bytes32 interfaceHash = keccak256(abi.encodePacked(_interfaceLabel));
        return erc820Registry.getInterfaceImplementer(addr, interfaceHash);
    }

    function delegateManagement(address _newManager) internal {
        erc820Registry.setManager(this, _newManager);
    }
}

 

 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0);  
    uint256 c = a / b;
     

    return c;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

   
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

 

 
library Address {

   
  function isContract(address account) internal view returns (bool) {
    uint256 size;
     
     
     
     
     
     
     
    assembly { size := extcodesize(account) }
    return size > 0;
  }

}

 

 


interface ERC777Token {
  function name() external view returns (string);
  function symbol() external view returns (string);
  function totalSupply() external view returns (uint256);
  function balanceOf(address owner) external view returns (uint256);
  function granularity() external view returns (uint256);

  function defaultOperators() external view returns (address[]);
  function isOperatorFor(address operator, address tokenHolder) external view returns (bool);
  function authorizeOperator(address operator) external;
  function revokeOperator(address operator) external;

  function send(address to, uint256 amount, bytes holderData) external;
  function operatorSend(address from, address to, uint256 amount, bytes holderData, bytes operatorData) external;

  function burn(uint256 amount, bytes holderData) external;
  function operatorBurn(address from, uint256 amount, bytes holderData, bytes operatorData) external;

  event Sent(
    address indexed operator,
    address indexed from,
    address indexed to,
    uint256 amount,
    bytes holderData,
    bytes operatorData
  );
  event Minted(address indexed operator, address indexed to, uint256 amount, bytes operatorData);
  event Burned(address indexed operator, address indexed from, uint256 amount, bytes holderData, bytes operatorData);
  event AuthorizedOperator(address indexed operator, address indexed tokenHolder);
  event RevokedOperator(address indexed operator, address indexed tokenHolder);
}

 

 


interface ERC777TokensSender {
  function tokensToSend(
    address operator,
    address from,
    address to,
    uint amount,
    bytes userData,
    bytes operatorData
  ) external;
}

 

 


interface ERC777TokensRecipient {
  function tokensReceived(
    address operator,
    address from,
    address to,
    uint amount,
    bytes userData,
    bytes operatorData
  ) external;
}

 

 
   
   
   
   
   
  constructor(
    string _name,
    string _symbol,
    uint256 _granularity,
    address[] _defaultOperators
  )
    internal
  {
    mName = _name;
    mSymbol = _symbol;
    mTotalSupply = 0;
    require(_granularity >= 1);
    mGranularity = _granularity;

    mDefaultOperators = _defaultOperators;
    for (uint i = 0; i < mDefaultOperators.length; i++) {
      mIsDefaultOperator[mDefaultOperators[i]] = true;
    }

    setInterfaceImplementation("ERC777Token", this);
  }

   

   
   
   
  function send(address _to, uint256 _amount, bytes _userData) external {
    doSend(msg.sender, msg.sender, _to, _amount, _userData, "", true);
  }

   
   
   
   
   
   
  function operatorSend(address _from, address _to, uint256 _amount, bytes _userData, bytes _operatorData) external {
    require(isOperatorFor(msg.sender, _from));
    doSend(msg.sender, _from, _to, _amount, _userData, _operatorData, true);
  }

  function burn(uint256 _amount, bytes _holderData) external {
    doBurn(msg.sender, msg.sender, _amount, _holderData, "");
  }

  function operatorBurn(address _tokenHolder, uint256 _amount, bytes _holderData, bytes _operatorData) external {
    require(isOperatorFor(msg.sender, _tokenHolder));
    doBurn(msg.sender, _tokenHolder, _amount, _holderData, _operatorData);
  }

   
  function name() external view returns (string) { return mName; }

   
  function symbol() external view returns (string) { return mSymbol; }

   
  function granularity() external view returns (uint256) { return mGranularity; }

   
  function totalSupply() public view returns (uint256) { return mTotalSupply; }

   
   
   
  function balanceOf(address _tokenHolder) public view returns (uint256) { return mBalances[_tokenHolder]; }

   
   
  function defaultOperators() external view returns (address[]) { return mDefaultOperators; }

   
   
  function authorizeOperator(address _operator) external {
    require(_operator != msg.sender);
    require(!mAuthorized[_operator][msg.sender]);

    if (mIsDefaultOperator[_operator]) {
      mRevokedDefaultOperator[_operator][msg.sender] = false;
    } else {
      mAuthorized[_operator][msg.sender] = true;
    }
    emit AuthorizedOperator(_operator, msg.sender);
  }

   
   
  function revokeOperator(address _operator) external {
    require(_operator != msg.sender);
    require(mAuthorized[_operator][msg.sender]);

    if (mIsDefaultOperator[_operator]) {
      mRevokedDefaultOperator[_operator][msg.sender] = true;
    } else {
      mAuthorized[_operator][msg.sender] = false;
    }
    emit RevokedOperator(_operator, msg.sender);
  }

   
   
   
   
  function isOperatorFor(address _operator, address _tokenHolder) public view returns (bool) {
    return (
      _operator == _tokenHolder
      || mAuthorized[_operator][_tokenHolder]
      || (mIsDefaultOperator[_operator] && !mRevokedDefaultOperator[_operator][_tokenHolder])
    );
  }

   
   
   
   
  function requireMultiple(uint256 _amount) internal view {
    require(_amount.div(mGranularity).mul(mGranularity) == _amount);
  }

   
   
   
   
   
   
   
   
   
   
   
  function doSend(
    address _operator,
    address _from,
    address _to,
    uint256 _amount,
    bytes _userData,
    bytes _operatorData,
    bool _preventLocking
  )
    internal
  {
    requireMultiple(_amount);

    callSender(_operator, _from, _to, _amount, _userData, _operatorData);

    require(_to != address(0));           
    require(mBalances[_from] >= _amount);  

    mBalances[_from] = mBalances[_from].sub(_amount);
    mBalances[_to] = mBalances[_to].add(_amount);

    callRecipient(_operator, _from, _to, _amount, _userData, _operatorData, _preventLocking);

    emit Sent(_operator, _from, _to, _amount, _userData, _operatorData);
  }

   
   
   
   
   
   
  function doBurn(address _operator, address _tokenHolder, uint256 _amount, bytes _holderData, bytes _operatorData)
    internal
  {
    requireMultiple(_amount);
    require(balanceOf(_tokenHolder) >= _amount);

    mBalances[_tokenHolder] = mBalances[_tokenHolder].sub(_amount);
    mTotalSupply = mTotalSupply.sub(_amount);

    callSender(_operator, _tokenHolder, 0x0, _amount, _holderData, _operatorData);
    emit Burned(_operator, _tokenHolder, _amount, _holderData, _operatorData);
  }

   
   
   
   
   
   
   
   
   
   
   
   
  function callRecipient(
    address _operator,
    address _from,
    address _to,
    uint256 _amount,
    bytes _userData,
    bytes _operatorData,
    bool _preventLocking
  )
    internal
  {
    address recipientImplementation = interfaceAddr(_to, "ERC777TokensRecipient");
    if (recipientImplementation != 0) {
      ERC777TokensRecipient(recipientImplementation).tokensReceived(
        _operator, _from, _to, _amount, _userData, _operatorData);
    } else if (_preventLocking) {
      require(!_to.isContract());
    }
  }

   
   
   
   
   
   
   
   
   
   
  function callSender(
    address _operator,
    address _from,
    address _to,
    uint256 _amount,
    bytes _userData,
    bytes _operatorData
  )
    internal
  {
    address senderImplementation = interfaceAddr(_from, "ERC777TokensSender");
    if (senderImplementation == 0) {
      return;
    }
    ERC777TokensSender(senderImplementation).tokensToSend(_operator, _from, _to, _amount, _userData, _operatorData);
  }
}

 

 
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

   
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

   
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

 

 
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused() {
    require(paused);
    _;
  }

   
  function pause() public onlyOwner whenNotPaused {
    paused = true;
    emit Pause();
  }

   
  function unpause() public onlyOwner whenPaused {
    paused = false;
    emit Unpause();
  }
}

 

 
 
 
 
contract Freezable is Ownable {

  event AccountFrozen(address indexed _account);
  event AccountUnfrozen(address indexed _account);

   
  mapping(address=>bool) public frozenAccounts;


    
  modifier whenAccountFrozen(address _account) {
    require(frozenAccounts[_account] == true);
    _;
  }

   
  modifier whenAccountNotFrozen(address _account) {
    require(frozenAccounts[_account] == false);
    _;
  }


   
  function freeze(address _account)
    external
    onlyOwner
    whenAccountNotFrozen(_account)
    returns (bool)
  {
    frozenAccounts[_account] = true;
    emit AccountFrozen(_account);
    return true;
  }

   
  function unfreeze(address _account)
    external
    onlyOwner
    whenAccountFrozen(_account)
    returns (bool)
  {
    frozenAccounts[_account] = false;
    emit AccountUnfrozen(_account);
    return true;
  }


   
  function freezeMyAccount()
    external
    whenAccountNotFrozen(msg.sender)
    returns (bool)
  {
     

    frozenAccounts[msg.sender] = true;
    emit AccountFrozen(msg.sender);
    return true;
  }
}

 

 
 
 
contract PausableFreezableERC777ERC20Token is ERC777ERC20BaseToken, Pausable, Freezable {

   

   
   
  function send(address _to, uint256 _amount, bytes _userData)
    external
    whenNotPaused
    whenAccountNotFrozen(msg.sender)
    whenAccountNotFrozen(_to)
  {
    doSend(msg.sender, msg.sender, _to, _amount, _userData, "", true);
  }

  function operatorSend(address _from, address _to, uint256 _amount, bytes _userData, bytes _operatorData)
    external
    whenNotPaused
    whenAccountNotFrozen(msg.sender)
    whenAccountNotFrozen(_from)
    whenAccountNotFrozen(_to)
  {
    require(isOperatorFor(msg.sender, _from));
    doSend(msg.sender, _from, _to, _amount, _userData, _operatorData, true);
  }

  function burn(uint256 _amount, bytes _holderData)
    external
    whenNotPaused
    whenAccountNotFrozen(msg.sender)
  {
    doBurn(msg.sender, msg.sender, _amount, _holderData, "");
  }

  function operatorBurn(address _tokenHolder, uint256 _amount, bytes _holderData, bytes _operatorData)
    external
    whenNotPaused
    whenAccountNotFrozen(msg.sender)
    whenAccountNotFrozen(_tokenHolder)
  {
    require(isOperatorFor(msg.sender, _tokenHolder));
    doBurn(msg.sender, _tokenHolder, _amount, _holderData, _operatorData);
  }

   

  function transfer(address _to, uint256 _amount)
    public
    erc20
    whenNotPaused
    whenAccountNotFrozen(msg.sender)
    whenAccountNotFrozen(_to)
    returns (bool success)
  {
    return super.transfer(_to, _amount);
  }

  function transferFrom(address _from, address _to, uint256 _amount)
    public
    erc20
    whenNotPaused
    whenAccountNotFrozen(msg.sender)
    whenAccountNotFrozen(_from)
    whenAccountNotFrozen(_to)
    returns (bool success)
  {
    return super.transferFrom(_from, _to, _amount);
  }

  function approve(address _spender, uint256 _amount)
    public
    erc20
    whenNotPaused
    whenAccountNotFrozen(msg.sender)
    whenAccountNotFrozen(_spender)
    returns (bool success)
  {
    return super.approve(_spender, _amount);
  }

   
   
   
   
  function transferFromFrozenAccount(
    address _from,
    address _to,
    uint256 _amount
  )
    external
    onlyOwner
    whenNotPaused
    whenAccountFrozen(_from)
    whenAccountNotFrozen(_to)
    whenAccountNotFrozen(msg.sender)
  {
    super.doSend(msg.sender, _from, _to, _amount, "", "", true);
  }

  function doSend(
    address _operator,
    address _from,
    address _to,
    uint256 _amount,
    bytes _userData,
    bytes _operatorData,
    bool _preventLocking
  )
    internal
    whenNotPaused
    whenAccountNotFrozen(msg.sender)
    whenAccountNotFrozen(_operator)
    whenAccountNotFrozen(_from)
    whenAccountNotFrozen(_to)
  {
    super.doSend(_operator, _from, _to, _amount, _userData, _operatorData, _preventLocking);
  }

  function doBurn(address _operator, address _tokenHolder, uint256 _amount, bytes _holderData, bytes _operatorData)
    internal
    whenNotPaused
    whenAccountNotFrozen(msg.sender)
    whenAccountNotFrozen(_operator)
    whenAccountNotFrozen(_tokenHolder)
  {
    super.doBurn(_operator, _tokenHolder, _amount, _holderData, _operatorData);
  }
}

 

 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
contract ERC777ERC20TokenWithOfficialOperators is ERC777ERC20BaseToken, Ownable {
  using Address for address;

  mapping(address => bool) internal mIsOfficialOperator;
  mapping(address => bool) internal mIsUserNotAcceptingAllOfficialOperators;

  event OfficialOperatorAdded(address operator);
  event OfficialOperatorRemoved(address operator);
  event OfficialOperatorsAcceptedByUser(address indexed user);
  event OfficialOperatorsRejectedByUser(address indexed user);

   
   
   
  function addOfficialOperator(address _operator) external onlyOwner {
    require(_operator.isContract(), "An official operator must be a contract.");
    require(!mIsOfficialOperator[_operator], "_operator is already an official operator.");

    mIsOfficialOperator[_operator] = true;
    emit OfficialOperatorAdded(_operator);
  }

   
   
  function removeOfficialOperator(address _operator) external onlyOwner {
    require(mIsOfficialOperator[_operator], "_operator is not an official operator.");

    mIsOfficialOperator[_operator] = false;
    emit OfficialOperatorRemoved(_operator);
  }

   
  function rejectAllOfficialOperators() external {
    require(!mIsUserNotAcceptingAllOfficialOperators[msg.sender], "Official operators are already rejected by msg.sender.");

    mIsUserNotAcceptingAllOfficialOperators[msg.sender] = true;
    emit OfficialOperatorsRejectedByUser(msg.sender);
  }

   
  function acceptAllOfficialOperators() external {
    require(mIsUserNotAcceptingAllOfficialOperators[msg.sender], "Official operators are already accepted by msg.sender.");

    mIsUserNotAcceptingAllOfficialOperators[msg.sender] = false;
    emit OfficialOperatorsAcceptedByUser(msg.sender);
  }

   
  function isOfficialOperator(address _operator) external view returns(bool) {
    return mIsOfficialOperator[_operator];
  }

   
  function isUserAcceptingAllOfficialOperators(address _user) external view returns(bool) {
    return !mIsUserNotAcceptingAllOfficialOperators[_user];
  }

   
   
   
   
  function isOperatorFor(address _operator, address _tokenHolder) public view returns (bool) {
    return (
      _operator == _tokenHolder
      || (!mIsUserNotAcceptingAllOfficialOperators[_tokenHolder] && mIsOfficialOperator[_operator])
      || mAuthorized[_operator][_tokenHolder]
      || (mIsDefaultOperator[_operator] && !mRevokedDefaultOperator[_operator][_tokenHolder])
    );
  }
}

 

interface ApprovalRecipient {
  function receiveApproval(
    address _from,
    uint256 _value,
    address _token,
    bytes _extraData
  ) external;
}

 

contract ERC777ERC20TokenWithApproveAndCall is PausableFreezableERC777ERC20Token {
   
   
   
   
   
   
  function approveAndCall(address _spender, uint256 _value, bytes _extraData)
    external
    whenNotPaused
    whenAccountNotFrozen(msg.sender)
    whenAccountNotFrozen(_spender)
    returns (bool success)
  {
    ApprovalRecipient spender = ApprovalRecipient(_spender);
    if (approve(_spender, _value)) {
      spender.receiveApproval(msg.sender, _value, this, _extraData);
      return true;
    }
  }
}

 

contract ERC777ERC20TokenWithBatchTransfer is PausableFreezableERC777ERC20Token {
   
   
   
   
   
   
  function batchTransfer(address[] _recipients, uint256[] _amounts)
    external
    erc20
    whenNotPaused
    whenAccountNotFrozen(msg.sender)
    returns (bool success)
  {
    require(
      _recipients.length == _amounts.length,
      "The lengths of _recipients and _amounts should be the same."
    );

    for (uint256 i = 0; i < _recipients.length; i++) {
      doSend(msg.sender, msg.sender, _recipients[i], _amounts[i], "", "", false);
    }
    return true;
  }

   
   
   
   
   
   
  function batchSend(
    address[] _recipients,
    uint256[] _amounts,
    bytes _userData
  )
    external
    whenNotPaused
    whenAccountNotFrozen(msg.sender)
  {
    require(
      _recipients.length == _amounts.length,
      "The lengths of _recipients and _amounts should be the same."
    );

    for (uint256 i = 0; i < _recipients.length; i++) {
      doSend(msg.sender, msg.sender, _recipients[i], _amounts[i], _userData, "", true);
    }
  }

   
   
   
   
   
   
   
   
  function operatorBatchSend(
    address _from,
    address[] _recipients,
    uint256[] _amounts,
    bytes _userData,
    bytes _operatorData
  )
    external
    whenNotPaused
    whenAccountNotFrozen(msg.sender)
    whenAccountNotFrozen(_from)
  {
    require(
      _recipients.length == _amounts.length,
      "The lengths of _recipients and _amounts should be the same."
    );
    require(isOperatorFor(msg.sender, _from));

    for (uint256 i = 0; i < _recipients.length; i++) {
      doSend(msg.sender, _from, _recipients[i], _amounts[i], _userData, _operatorData, true);
    }
  }
}

 

 
 
 
 
contract CappedMintableERC777ERC20Token is ERC777ERC20BaseToken, Ownable {
  uint256 internal mTotalSupplyCap;

  constructor(uint256 _totalSupplyCap) public {
    mTotalSupplyCap = _totalSupplyCap;
  }

   
  function totalSupplyCap() external view returns(uint _totalSupplyCap) {
    return mTotalSupplyCap;
  }

   
   
   
   
   
   
  function mint(address _tokenHolder, uint256 _amount, bytes _operatorData) external onlyOwner {
    requireMultiple(_amount);
    require(mTotalSupply.add(_amount) <= mTotalSupplyCap);

    mTotalSupply = mTotalSupply.add(_amount);
    mBalances[_tokenHolder] = mBalances[_tokenHolder].add(_amount);

    callRecipient(msg.sender, address(0), _tokenHolder, _amount, "", _operatorData, true);

    emit Minted(msg.sender, _tokenHolder, _amount, _operatorData);
    if (mErc20compatible) {
      emit Transfer(0x0, _tokenHolder, _amount);
    }
  }
}

 

 
 
 
contract ERC777ERC20TokenWithOperatorApprove is ERC777ERC20BaseToken {
  function operatorApprove(
    address _tokenHolder,
    address _spender,
    uint256 _amount
  )
    external
    erc20
    returns (bool success)
  {
    require(
      isOperatorFor(msg.sender, _tokenHolder),
      "msg.sender is not an operator for _tokenHolder"
    );

    mAllowed[_tokenHolder][_spender] = _amount;
    emit Approval(_tokenHolder, _spender, _amount);
    return true;
  }
}

 

 
contract Claimable is Ownable {
  address public pendingOwner;

   
  modifier onlyPendingOwner() {
    require(msg.sender == pendingOwner);
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    pendingOwner = newOwner;
  }

   
  function claimOwnership() public onlyPendingOwner {
    emit OwnershipTransferred(owner, pendingOwner);
    owner = pendingOwner;
    pendingOwner = address(0);
  }
}

 

 
 
 
contract SelfToken is
  ERC777ERC20BaseToken,
  PausableFreezableERC777ERC20Token,
  ERC777ERC20TokenWithOfficialOperators,
  ERC777ERC20TokenWithApproveAndCall,
  ERC777ERC20TokenWithBatchTransfer,
  CappedMintableERC777ERC20Token,
  ERC777ERC20TokenWithOperatorApprove,
  Claimable
{
  constructor()
    public
    ERC777ERC20BaseToken("SELF TOKEN", "SELF", 1, new address[](0))
    CappedMintableERC777ERC20Token(1e9 * 1e18)
  {}
}
 

pragma solidity ^0.4.16;


 
contract Ownable {
  address public owner;


   
  function Ownable() public {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) external onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}



 
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}



 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}



 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) public returns (bool) {
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
    var _allowance = allowed[_from][msg.sender];

     
     

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {

     
     
     
     
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

}



 
contract Manageable is Ownable {

   

  mapping (address => bool) managerEnabled;   
  mapping (address => mapping (string => bool)) managerPermissions;   


   

  event ManagerEnabledEvent(address indexed manager);
  event ManagerDisabledEvent(address indexed manager);
  event ManagerPermissionGrantedEvent(address indexed manager, string permission);
  event ManagerPermissionRevokedEvent(address indexed manager, string permission);


   

   
  function enableManager(address _manager) external onlyOwner onlyValidAddress(_manager) {
    require(managerEnabled[_manager] == false);

    managerEnabled[_manager] = true;
    ManagerEnabledEvent(_manager);
  }

   
  function disableManager(address _manager) external onlyOwner onlyValidAddress(_manager) {
    require(managerEnabled[_manager] == true);

    managerEnabled[_manager] = false;
    ManagerDisabledEvent(_manager);
  }

   
  function grantManagerPermission(
    address _manager, string _permissionName
  )
    external
    onlyOwner
    onlyValidAddress(_manager)
    onlyValidPermissionName(_permissionName)
  {
    require(managerPermissions[_manager][_permissionName] == false);

    managerPermissions[_manager][_permissionName] = true;
    ManagerPermissionGrantedEvent(_manager, _permissionName);
  }

   
  function revokeManagerPermission(
    address _manager, string _permissionName
  )
    external
    onlyOwner
    onlyValidAddress(_manager)
    onlyValidPermissionName(_permissionName)
  {
    require(managerPermissions[_manager][_permissionName] == true);

    managerPermissions[_manager][_permissionName] = false;
    ManagerPermissionRevokedEvent(_manager, _permissionName);
  }


   

   
  function isManagerEnabled(address _manager) public constant onlyValidAddress(_manager) returns (bool) {
    return managerEnabled[_manager];
  }

   
  function isPermissionGranted(
    address _manager, string _permissionName
  )
    public
    constant
    onlyValidAddress(_manager)
    onlyValidPermissionName(_permissionName)
    returns (bool)
  {
    return managerPermissions[_manager][_permissionName];
  }

   
  function isManagerAllowed(
    address _manager, string _permissionName
  )
    public
    constant
    onlyValidAddress(_manager)
    onlyValidPermissionName(_permissionName)
    returns (bool)
  {
    return (managerEnabled[_manager] && managerPermissions[_manager][_permissionName]);
  }


   

   
  modifier onlyValidAddress(address _manager) {
    require(_manager != address(0x0));
    _;
  }

   
  modifier onlyValidPermissionName(string _permissionName) {
    require(bytes(_permissionName).length != 0);
    _;
  }


   

   
  modifier onlyAllowedManager(string _permissionName) {
    require(isManagerAllowed(msg.sender, _permissionName) == true);
    _;
  }
}



 
contract Pausable is Manageable {

   

  event PauseEvent();
  event UnpauseEvent();


   

  bool paused = true;


   
  modifier whenContractNotPaused() {
    require(paused == false);
    _;
  }

   
  modifier whenContractPaused {
    require(paused == true);
    _;
  }

   
  function pauseContract() external onlyAllowedManager('pause_contract') whenContractNotPaused {
    paused = true;
    PauseEvent();
  }

   
  function unpauseContract() external onlyAllowedManager('unpause_contract') whenContractPaused {
    paused = false;
    UnpauseEvent();
  }

   
  function getPaused() external constant returns (bool) {
    return paused;
  }
}



 
contract NamedToken {
  string public name;
  string public symbol;
  uint8 public decimals;

  function NamedToken(string _name, string _symbol, uint8 _decimals) public {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
  }

   
  function getNameHash() external constant returns (bytes32 result){
    return keccak256(name);
  }

   
  function getSymbolHash() external constant returns (bytes32 result){
    return keccak256(symbol);
  }
}



 
contract AngelToken is StandardToken, NamedToken, Pausable {

   

  event MintEvent(address indexed account, uint value);
  event BurnEvent(address indexed account, uint value);
  event SpendingBlockedEvent(address indexed account);
  event SpendingUnblockedEvent(address indexed account);


   

  address public centralBankAddress = 0x0;
  mapping (address => uint) spendingBlocksNumber;


   

  function AngelToken() public NamedToken('Angel Token', 'ANGL', 18) {
    centralBankAddress = msg.sender;
  }


   

  function transfer(address _to, uint _value) public returns (bool) {
    if (_to != centralBankAddress) {
      require(!paused);
    }
    require(spendingBlocksNumber[msg.sender] == 0);

    bool result = super.transfer(_to, _value);
    if (result == true && _to == centralBankAddress) {
      AngelCentralBank(centralBankAddress).angelBurn(msg.sender, _value);
    }
    return result;
  }

  function approve(address _spender, uint _value) public whenContractNotPaused returns (bool){
    return super.approve(_spender, _value);
  }

  function transferFrom(address _from, address _to, uint _value) public whenContractNotPaused returns (bool){
    require(spendingBlocksNumber[_from] == 0);

    bool result = super.transferFrom(_from, _to, _value);
    if (result == true && _to == centralBankAddress) {
      AngelCentralBank(centralBankAddress).angelBurn(_from, _value);
    }
    return result;
  }


  function mint(address _account, uint _value) external onlyAllowedManager('mint_tokens') {
    balances[_account] = balances[_account].add(_value);
    totalSupply = totalSupply.add(_value);
    MintEvent(_account, _value);
    Transfer(address(0x0), _account, _value);  
  }

  function burn(uint _value) external onlyAllowedManager('burn_tokens') {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    totalSupply = totalSupply.sub(_value);
    BurnEvent(msg.sender, _value);
  }

  function blockSpending(address _account) external onlyAllowedManager('block_spending') {
    spendingBlocksNumber[_account] = spendingBlocksNumber[_account].add(1);
    SpendingBlockedEvent(_account);
  }

  function unblockSpending(address _account) external onlyAllowedManager('unblock_spending') {
    spendingBlocksNumber[_account] = spendingBlocksNumber[_account].sub(1);
    SpendingUnblockedEvent(_account);
  }
}



 
contract AngelCentralBank {

   

  struct InvestmentRecord {
    uint tokensSoldBeforeWei;
    uint investedEthWei;
    uint purchasedTokensWei;
    uint refundedEthWei;
    uint returnedTokensWei;
  }


   

  uint public constant icoCap = 70000000 * (10 ** 18);

  uint public initialTokenPrice = 1 * (10 ** 18) / (10 ** 4);  

  uint public constant landmarkSize = 1000000 * (10 ** 18);
  uint public constant landmarkPriceStepNumerator = 10;
  uint public constant landmarkPriceStepDenominator = 100;

  uint public constant firstRefundRoundRateNumerator = 80;
  uint public constant firstRefundRoundRateDenominator = 100;
  uint public constant secondRefundRoundRateNumerator = 40;
  uint public constant secondRefundRoundRateDenominator = 100;

  uint public constant initialFundsReleaseNumerator = 20;  
  uint public constant initialFundsReleaseDenominator = 100;
  uint public constant afterFirstRefundRoundFundsReleaseNumerator = 50;  
  uint public constant afterFirstRefundRoundFundsReleaseDenominator = 100;

  uint public constant angelFoundationShareNumerator = 30;
  uint public constant angelFoundationShareDenominator = 100;

   

  address public angelFoundationAddress = address(0x2b0556a6298eA3D35E90F1df32cc126b31F59770);
  uint public icoLaunchTimestamp = 1511784000;   
  uint public icoFinishTimestamp = 1513727999;   
  uint public firstRefundRoundFinishTimestamp = 1520424000;   
  uint public secondRefundRoundFinishTimestamp = 1524744000;   


  AngelToken public angelToken;

  mapping (address => InvestmentRecord[]) public investments;  
  mapping (address => bool) public investors;
  uint public totalInvestors = 0;
  uint public totalTokensSold = 0;

  bool isIcoFinished = false;
  bool firstRefundRoundFundsWithdrawal = false;


   

  event InvestmentEvent(address indexed investor, uint eth, uint angel);
  event RefundEvent(address indexed investor, uint eth, uint angel);


   

  function AngelCentralBank() public {
    angelToken = new AngelToken();
    angelToken.enableManager(address(this));
    angelToken.grantManagerPermission(address(this), 'mint_tokens');
    angelToken.grantManagerPermission(address(this), 'burn_tokens');
    angelToken.grantManagerPermission(address(this), 'unpause_contract');
    angelToken.transferOwnership(angelFoundationAddress);
  }

   

   
  function () public payable {
    angelRaise();
  }

   
  function angelRaise() internal {
    require(msg.value > 0);
    require(now >= icoLaunchTimestamp && now < icoFinishTimestamp);

     
    uint _purchasedTokensWei = 0;
    uint _notProcessedEthWei = 0;
    (_purchasedTokensWei, _notProcessedEthWei) = calculatePurchasedTokens(totalTokensSold, msg.value);
    uint _actualInvestment = (msg.value - _notProcessedEthWei);

     
    uint _newRecordIndex = investments[msg.sender].length;
    investments[msg.sender].length += 1;
    investments[msg.sender][_newRecordIndex].tokensSoldBeforeWei = totalTokensSold;
    investments[msg.sender][_newRecordIndex].investedEthWei = _actualInvestment;
    investments[msg.sender][_newRecordIndex].purchasedTokensWei = _purchasedTokensWei;
    investments[msg.sender][_newRecordIndex].refundedEthWei = 0;
    investments[msg.sender][_newRecordIndex].returnedTokensWei = 0;

     
    if (investors[msg.sender] == false) {
      totalInvestors += 1;
    }
    investors[msg.sender] = true;
    totalTokensSold += _purchasedTokensWei;

     
    angelToken.mint(msg.sender, _purchasedTokensWei);
    angelToken.mint(angelFoundationAddress,
                    _purchasedTokensWei * angelFoundationShareNumerator / (angelFoundationShareDenominator - angelFoundationShareNumerator));
    angelFoundationAddress.transfer(_actualInvestment * initialFundsReleaseNumerator / initialFundsReleaseDenominator);
    if (_notProcessedEthWei > 0) {
      msg.sender.transfer(_notProcessedEthWei);
    }

     
    if (totalTokensSold >= icoCap) {
      icoFinishTimestamp = now;

      finishIco();
    }

     
    InvestmentEvent(msg.sender, _actualInvestment, _purchasedTokensWei);
  }

   
  function calculatePurchasedTokens(
    uint _totalTokensSoldBefore,
    uint _investedEthWei)
    constant public returns (uint _purchasedTokensWei, uint _notProcessedEthWei)
  {
    _purchasedTokensWei = 0;
    _notProcessedEthWei = _investedEthWei;

    uint _landmarkPrice;
    uint _maxLandmarkTokensWei;
    uint _maxLandmarkEthWei;
    bool _isCapReached = false;
    do {
       
      _landmarkPrice = calculateLandmarkPrice(_totalTokensSoldBefore + _purchasedTokensWei);
      _maxLandmarkTokensWei = landmarkSize - ((_totalTokensSoldBefore + _purchasedTokensWei) % landmarkSize);
      if (_totalTokensSoldBefore + _purchasedTokensWei + _maxLandmarkTokensWei >= icoCap) {
        _maxLandmarkTokensWei = icoCap - _totalTokensSoldBefore - _purchasedTokensWei;
        _isCapReached = true;
      }
      _maxLandmarkEthWei = _maxLandmarkTokensWei * _landmarkPrice / (10 ** 18);

       
      if (_notProcessedEthWei >= _maxLandmarkEthWei) {
        _purchasedTokensWei += _maxLandmarkTokensWei;
        _notProcessedEthWei -= _maxLandmarkEthWei;
      }
      else {
        _purchasedTokensWei += _notProcessedEthWei * (10 ** 18) / _landmarkPrice;
        _notProcessedEthWei = 0;
      }
    }
    while ((_notProcessedEthWei > 0) && (_isCapReached == false));

    assert(_purchasedTokensWei > 0);

    return (_purchasedTokensWei, _notProcessedEthWei);
  }


   

  function angelBurn(
    address _investor,
    uint _returnedTokensWei
  )
    external returns (uint)
  {
    require(msg.sender == address(angelToken));
    require(now >= icoLaunchTimestamp && now < secondRefundRoundFinishTimestamp);

    uint _notProcessedTokensWei = _returnedTokensWei;
    uint _refundedEthWei = 0;

    uint _allRecordsNumber = investments[_investor].length;
    uint _recordMaxReturnedTokensWei = 0;
    uint _recordTokensWeiToProcess = 0;
    uint _tokensSoldWei = 0;
    uint _recordRefundedEthWei = 0;
    uint _recordNotProcessedTokensWei = 0;
    for (uint _recordID = 0; _recordID < _allRecordsNumber; _recordID += 1) {
      if (investments[_investor][_recordID].purchasedTokensWei <= investments[_investor][_recordID].returnedTokensWei ||
          investments[_investor][_recordID].investedEthWei <= investments[_investor][_recordID].refundedEthWei) {
         
        continue;
      }

       
      _recordMaxReturnedTokensWei = investments[_investor][_recordID].purchasedTokensWei -
                                    investments[_investor][_recordID].returnedTokensWei;
      _recordTokensWeiToProcess = (_notProcessedTokensWei < _recordMaxReturnedTokensWei) ? _notProcessedTokensWei :
                                                                                           _recordMaxReturnedTokensWei;
      assert(_recordTokensWeiToProcess > 0);

       
      _tokensSoldWei = investments[_investor][_recordID].tokensSoldBeforeWei + investments[_investor][_recordID].returnedTokensWei;
      (_recordRefundedEthWei, _recordNotProcessedTokensWei) = calculateRefundedEth(_tokensSoldWei, _recordTokensWeiToProcess);
      if (_recordRefundedEthWei > (investments[_investor][_recordID].investedEthWei - investments[_investor][_recordID].refundedEthWei)) {
         
        _recordRefundedEthWei = (investments[_investor][_recordID].investedEthWei - investments[_investor][_recordID].refundedEthWei);
      }
      assert(_recordRefundedEthWei > 0);
      assert(_recordNotProcessedTokensWei == 0);

       
      _refundedEthWei += _recordRefundedEthWei;
      _notProcessedTokensWei -= _recordTokensWeiToProcess;

      investments[_investor][_recordID].refundedEthWei += _recordRefundedEthWei;
      investments[_investor][_recordID].returnedTokensWei += _recordTokensWeiToProcess;
      assert(investments[_investor][_recordID].refundedEthWei <= investments[_investor][_recordID].investedEthWei);
      assert(investments[_investor][_recordID].returnedTokensWei <= investments[_investor][_recordID].purchasedTokensWei);

       
      if (_notProcessedTokensWei == 0) {
        break;
      }
    }

     
    require(_notProcessedTokensWei < _returnedTokensWei);
    require(_refundedEthWei > 0);

     
    uint _refundedEthWeiWithDiscount = calculateRefundedEthWithDiscount(_refundedEthWei);

     
    angelToken.burn(_returnedTokensWei - _notProcessedTokensWei);
    if (_notProcessedTokensWei > 0) {
      angelToken.transfer(_investor, _notProcessedTokensWei);
    }
    _investor.transfer(_refundedEthWeiWithDiscount);

     
    RefundEvent(_investor, _refundedEthWeiWithDiscount, _returnedTokensWei - _notProcessedTokensWei);
  }

   
  function calculateRefundedEthWithDiscount(
    uint _refundedEthWei
  )
    public constant returns (uint)
  {
    if (now <= firstRefundRoundFinishTimestamp) {
      return (_refundedEthWei * firstRefundRoundRateNumerator / firstRefundRoundRateDenominator);
    }
    else {
      return (_refundedEthWei * secondRefundRoundRateNumerator / secondRefundRoundRateDenominator);
    }
  }

   
  function calculateRefundedEth(
    uint _totalTokensSoldBefore,
    uint _returnedTokensWei
  )
    public constant returns (uint _refundedEthWei, uint _notProcessedTokensWei)
  {
    _refundedEthWei = 0;
    uint _refundedTokensWei = 0;
    _notProcessedTokensWei = _returnedTokensWei;

    uint _landmarkPrice = 0;
    uint _maxLandmarkTokensWei = 0;
    uint _maxLandmarkEthWei = 0;
    bool _isCapReached = false;
    do {
       
      _landmarkPrice = calculateLandmarkPrice(_totalTokensSoldBefore + _refundedTokensWei);
      _maxLandmarkTokensWei = landmarkSize - ((_totalTokensSoldBefore + _refundedTokensWei) % landmarkSize);
      if (_totalTokensSoldBefore + _refundedTokensWei + _maxLandmarkTokensWei >= icoCap) {
        _maxLandmarkTokensWei = icoCap - _totalTokensSoldBefore - _refundedTokensWei;
        _isCapReached = true;
      }
      _maxLandmarkEthWei = _maxLandmarkTokensWei * _landmarkPrice / (10 ** 18);

       
      if (_notProcessedTokensWei > _maxLandmarkTokensWei) {
        _refundedEthWei += _maxLandmarkEthWei;
        _refundedTokensWei += _maxLandmarkTokensWei;
        _notProcessedTokensWei -= _maxLandmarkTokensWei;
      }
      else {
        _refundedEthWei += _notProcessedTokensWei * _landmarkPrice / (10 ** 18);
        _refundedTokensWei += _notProcessedTokensWei;
        _notProcessedTokensWei = 0;
      }
    }
    while ((_notProcessedTokensWei > 0) && (_isCapReached == false));

    assert(_refundedEthWei > 0);

    return (_refundedEthWei, _notProcessedTokensWei);
  }


   

   
  function calculateLandmarkPrice(uint _totalTokensSoldBefore) public constant returns (uint) {
    return initialTokenPrice + initialTokenPrice
                               * landmarkPriceStepNumerator / landmarkPriceStepDenominator
                               * (_totalTokensSoldBefore / landmarkSize);
  }


   

  function finishIco() public {
    require(now >= icoFinishTimestamp);
    require(isIcoFinished == false);

    isIcoFinished = true;

    angelToken.unpauseContract();
  }

  function withdrawFoundationFunds() external {
    require(now > firstRefundRoundFinishTimestamp);

    if (now > firstRefundRoundFinishTimestamp && now <= secondRefundRoundFinishTimestamp) {
      require(firstRefundRoundFundsWithdrawal == false);

      firstRefundRoundFundsWithdrawal = true;
      angelFoundationAddress.transfer(this.balance * afterFirstRefundRoundFundsReleaseNumerator / afterFirstRefundRoundFundsReleaseDenominator);
    } else {
      angelFoundationAddress.transfer(this.balance);
    }
  }
}
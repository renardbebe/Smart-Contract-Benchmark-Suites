 

pragma solidity ^0.4.24;

contract TokenInfo {
     
    uint256 public constant PRIVATESALE_BASE_PRICE_IN_WEI = 200000000000000;
    uint256 public constant PRESALE_BASE_PRICE_IN_WEI = 600000000000000;
    uint256 public constant ICO_BASE_PRICE_IN_WEI = 800000000000000;
    uint256 public constant FIRSTSALE_BASE_PRICE_IN_WEI = 200000000000000;

     
    uint256 public constant MIN_PURCHASE_OTHERSALES = 80000000000000000;
    uint256 public constant MIN_PURCHASE = 1000000000000000000;
    uint256 public constant MAX_PURCHASE = 1000000000000000000000;

     

    uint256 public constant PRESALE_PERCENTAGE_1 = 10;
    uint256 public constant PRESALE_PERCENTAGE_2 = 15;
    uint256 public constant PRESALE_PERCENTAGE_3 = 20;
    uint256 public constant PRESALE_PERCENTAGE_4 = 25;
    uint256 public constant PRESALE_PERCENTAGE_5 = 35;

    uint256 public constant ICO_PERCENTAGE_1 = 5;
    uint256 public constant ICO_PERCENTAGE_2 = 10;
    uint256 public constant ICO_PERCENTAGE_3 = 15;
    uint256 public constant ICO_PERCENTAGE_4 = 20;
    uint256 public constant ICO_PERCENTAGE_5 = 25;

     

    uint256 public constant PRESALE_LEVEL_1 = 5000000000000000000;
    uint256 public constant PRESALE_LEVEL_2 = 10000000000000000000;
    uint256 public constant PRESALE_LEVEL_3 = 15000000000000000000;
    uint256 public constant PRESALE_LEVEL_4 = 20000000000000000000;
    uint256 public constant PRESALE_LEVEL_5 = 25000000000000000000;

    uint256 public constant ICO_LEVEL_1 = 6666666666666666666;
    uint256 public constant ICO_LEVEL_2 = 13333333333333333333;
    uint256 public constant ICO_LEVEL_3 = 20000000000000000000;
    uint256 public constant ICO_LEVEL_4 = 26666666666666666666;
    uint256 public constant ICO_LEVEL_5 = 33333333333333333333;

     
    uint256 public constant PRIVATESALE_TOKENCAP = 18750000;
    uint256 public constant PRESALE_TOKENCAP = 18750000;
    uint256 public constant ICO_TOKENCAP = 22500000;
    uint256 public constant FIRSTSALE_TOKENCAP = 5000000;
    uint256 public constant LEDTEAM_TOKENS = 35000000;
    uint256 public constant TOTAL_TOKENCAP = 100000000;

    uint256 public constant DECIMALS_MULTIPLIER = 1 ether;

    address public constant LED_MULTISIG = 0x865e785f98b621c5fdde70821ca7cea9eeb77ef4;
}

 
contract Ownable {
  address public owner;


   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}


contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;

  constructor() public {}

   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused {
    require(paused);
    _;
  }

   
  function pause() public onlyOwner whenNotPaused returns (bool) {
    paused = true;
    emit Pause();
    return true;
  }

   
  function unpause() public onlyOwner whenPaused returns (bool) {
    paused = false;
    emit Unpause();
    return true;
  }
}

contract ApproveAndCallReceiver {
    function receiveApproval(address from, uint256 _amount, address _token, bytes _data) public;
}

 
contract Controllable {
  address public controller;


   
  constructor() public {
    controller = msg.sender;
  }

   
  modifier onlyController() {
    require(msg.sender == controller);
    _;
  }

   
  function transferControl(address newController) public onlyController {
    if (newController != address(0)) {
      controller = newController;
    }
  }

}

 
contract ControllerInterface {

    function proxyPayment(address _owner) public payable returns(bool);
    function onTransfer(address _from, address _to, uint _amount) public returns(bool);
    function onApprove(address _owner, address _spender, uint _amount) public returns(bool);
}

 
contract ERC20 {

  uint256 public totalSupply;

  function balanceOf(address _owner) public constant returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  function transferFrom(address _from, address _to, uint256 _amount) public returns (bool);
  function approve(address _spender, uint256 _amount) public returns (bool);
  function allowance(address _owner, address _spender) public constant returns (uint256);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);

}

contract Crowdsale is Pausable, TokenInfo {

  using SafeMath for uint256;

  LedTokenInterface public ledToken;
  uint256 public startTime;
  uint256 public endTime;

  uint256 public totalWeiRaised;
  uint256 public tokensMinted;
  uint256 public totalSupply;
  uint256 public contributors;
  uint256 public surplusTokens;

  bool public finalized;

  bool public ledTokensAllocated;
  address public ledMultiSig = LED_MULTISIG;

   
   
   

  bool public started = false;

  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
  event NewClonedToken(address indexed _cloneToken);
  event OnTransfer(address _from, address _to, uint _amount);
  event OnApprove(address _owner, address _spender, uint _amount);
  event LogInt(string _name, uint256 _value);
  event Finalized();

   
    

   
   
   

   
   
   
   

   
   


   
  function forwardFunds() internal {
    ledMultiSig.transfer(msg.value);
  }


   
  function validPurchase() internal constant returns (bool) {
    uint256 current = now;
    bool presaleStarted = (current >= startTime || started);
    bool presaleNotEnded = current <= endTime;
    bool nonZeroPurchase = msg.value != 0;
    return nonZeroPurchase && presaleStarted && presaleNotEnded;
  }

   
  function totalSupply() public constant returns (uint256) {
    return ledToken.totalSupply();
  }

   
  function balanceOf(address _owner) public constant returns (uint256) {
    return ledToken.balanceOf(_owner);
  }

   
  function changeController(address _newController) public onlyOwner {
    require(isContract(_newController));
    ledToken.transferControl(_newController);
  }

  function enableMasterTransfers() public onlyOwner {
    ledToken.enableMasterTransfers(true);
  }

  function lockMasterTransfers() public onlyOwner {
    ledToken.enableMasterTransfers(false);
  }

  function forceStart() public onlyOwner {
    started = true;
  }

   

  function isContract(address _addr) constant internal returns(bool) {
    uint size;
    if (_addr == 0)
      return false;
    assembly {
        size := extcodesize(_addr)
    }
    return size>0;
  }

  modifier whenNotFinalized() {
    require(!finalized);
    _;
  }

}
 
contract FirstSale is Crowdsale {

  uint256 public tokenCap = FIRSTSALE_TOKENCAP;
  uint256 public cap = tokenCap * DECIMALS_MULTIPLIER;
  uint256 public weiCap = tokenCap * FIRSTSALE_BASE_PRICE_IN_WEI;

  constructor(address _tokenAddress, uint256 _startTime, uint256 _endTime) public {
    

    startTime = _startTime;
    endTime = _endTime;
    ledToken = LedTokenInterface(_tokenAddress);

    assert(_tokenAddress != 0x0);
    assert(_startTime > 0);
    assert(_endTime > _startTime);
  }

     
  function() public payable {
    buyTokens(msg.sender);
  }

   
  function buyTokens(address _beneficiary) public payable whenNotPaused whenNotFinalized {
    require(_beneficiary != 0x0);
    require(validPurchase());

    uint256 weiAmount = msg.value;
    require(weiAmount >= MIN_PURCHASE && weiAmount <= MAX_PURCHASE);
    uint256 priceInWei = FIRSTSALE_BASE_PRICE_IN_WEI;
    totalWeiRaised = totalWeiRaised.add(weiAmount);

    uint256 tokens = weiAmount.mul(DECIMALS_MULTIPLIER).div(priceInWei);
    tokensMinted = tokensMinted.add(tokens);
    require(tokensMinted < cap);

    contributors = contributors.add(1);

    ledToken.mint(_beneficiary, tokens);
    emit TokenPurchase(msg.sender, _beneficiary, weiAmount, tokens);
    forwardFunds();
  }

  function getInfo() public view returns(uint256, uint256, string, bool,  uint256, uint256, uint256, 
  bool, uint256, uint256){
    uint256 decimals = 18;
    string memory symbol = "LED";
    bool transfersEnabled = ledToken.transfersEnabled();
    return (
      TOTAL_TOKENCAP,  
      decimals,  
      symbol,
      transfersEnabled,
      contributors,
      totalWeiRaised,
      tokenCap,  
      started,
      startTime,  
      endTime
    );
  }

  function finalize() public onlyOwner {
    require(paused);
    require(!finalized);
    surplusTokens = cap - tokensMinted;
    ledToken.mint(ledMultiSig, surplusTokens);
    ledToken.transferControl(owner);

    emit Finalized();

    finalized = true;
  }

}

contract LedToken is Controllable {

  using SafeMath for uint256;
  LedTokenInterface public parentToken;
  TokenFactoryInterface public tokenFactory;

  string public name;
  string public symbol;
  string public version;
  uint8 public decimals;

  uint256 public parentSnapShotBlock;
  uint256 public creationBlock;
  bool public transfersEnabled;

  bool public masterTransfersEnabled;
  address public masterWallet = 0x865e785f98b621c5fdde70821ca7cea9eeb77ef4;


  struct Checkpoint {
    uint128 fromBlock;
    uint128 value;
  }

  Checkpoint[] totalSupplyHistory;
  mapping(address => Checkpoint[]) balances;
  mapping (address => mapping (address => uint)) allowed;

  bool public mintingFinished = false;
  bool public presaleBalancesLocked = false;

  uint256 public totalSupplyAtCheckpoint;

  event MintFinished();
  event NewCloneToken(address indexed cloneToken);
  event Approval(address indexed _owner, address indexed _spender, uint256 _amount);
  event Transfer(address indexed from, address indexed to, uint256 value);




  constructor(
    address _tokenFactory,
    address _parentToken,
    uint256 _parentSnapShotBlock,
    string _tokenName,
    string _tokenSymbol
    ) public {
      tokenFactory = TokenFactoryInterface(_tokenFactory);
      parentToken = LedTokenInterface(_parentToken);
      parentSnapShotBlock = _parentSnapShotBlock;
      name = _tokenName;
      symbol = _tokenSymbol;
      decimals = 18;
      transfersEnabled = false;
      masterTransfersEnabled = false;
      creationBlock = block.number;
      version = '0.1';
  }


   
  function totalSupply() public constant returns (uint256) {
    return totalSupplyAt(block.number);
  }

   
  function totalSupplyAt(uint256 _blockNumber) public constant returns(uint256) {
     
     
     
     
     
    if ((totalSupplyHistory.length == 0) || (totalSupplyHistory[0].fromBlock > _blockNumber)) {
        if (address(parentToken) != 0x0) {
            return parentToken.totalSupplyAt(min(_blockNumber, parentSnapShotBlock));
        } else {
            return 0;
        }

     
    } else {
        return getValueAt(totalSupplyHistory, _blockNumber);
    }
  }

   
  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balanceOfAt(_owner, block.number);
  }

   
  function balanceOfAt(address _owner, uint256 _blockNumber) public constant returns (uint256) {
     
     
     
     
     
    if ((balances[_owner].length == 0) || (balances[_owner][0].fromBlock > _blockNumber)) {
        if (address(parentToken) != 0x0) {
            return parentToken.balanceOfAt(_owner, min(_blockNumber, parentSnapShotBlock));
        } else {
             
            return 0;
        }

     
    } else {
        return getValueAt(balances[_owner], _blockNumber);
    }
  }

   
  function transfer(address _to, uint256 _amount) public returns (bool success) {
    return doTransfer(msg.sender, _to, _amount);
  }

   
  function transferFrom(address _from, address _to, uint256 _amount) public returns (bool success) {
    require(allowed[_from][msg.sender] >= _amount);
    allowed[_from][msg.sender] -= _amount;
    return doTransfer(_from, _to, _amount);
  }

   
  function approve(address _spender, uint256 _amount) public returns (bool success) {
    require(transfersEnabled);

     
    require((_amount == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _amount;
    emit Approval(msg.sender, _spender, _amount);
    return true;
  }

   
  function approveAndCall(address _spender, uint256 _amount, bytes _extraData) public returns (bool success) {
    approve(_spender, _amount);

    ApproveAndCallReceiver(_spender).receiveApproval(
        msg.sender,
        _amount,
        this,
        _extraData
    );

    return true;
  }

   
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

   
  function doTransfer(address _from, address _to, uint256 _amount) internal returns(bool) {

    if (msg.sender != masterWallet) {
      require(transfersEnabled);
    } else {
      require(masterTransfersEnabled);
    }

    require(_amount > 0);
    require(parentSnapShotBlock < block.number);
    require((_to != address(0)) && (_to != address(this)));

     
     
    uint256 previousBalanceFrom = balanceOfAt(_from, block.number);
    require(previousBalanceFrom >= _amount);

     
     
    updateValueAtNow(balances[_from], previousBalanceFrom - _amount);

     
     
    uint256 previousBalanceTo = balanceOfAt(_to, block.number);
    require(previousBalanceTo + _amount >= previousBalanceTo);  
    updateValueAtNow(balances[_to], previousBalanceTo + _amount);

     
    emit Transfer(_from, _to, _amount);
    return true;
  }


   
  function mint(address _owner, uint256 _amount) public onlyController canMint returns (bool) {
    uint256 curTotalSupply = totalSupply();
    uint256 previousBalanceTo = balanceOf(_owner);

    require(curTotalSupply + _amount >= curTotalSupply);  
    require(previousBalanceTo + _amount >= previousBalanceTo);  

    updateValueAtNow(totalSupplyHistory, curTotalSupply + _amount);
    updateValueAtNow(balances[_owner], previousBalanceTo + _amount);
    emit Transfer(0, _owner, _amount);
    return true;
  }

  modifier canMint() {
    require(!mintingFinished);
    _;
  }


   
  function importPresaleBalances(address[] _addresses, uint256[] _balances) public onlyController returns (bool) {
    require(presaleBalancesLocked == false);

    for (uint256 i = 0; i < _addresses.length; i++) {
      totalSupplyAtCheckpoint += _balances[i];
      updateValueAtNow(balances[_addresses[i]], _balances[i]);
      updateValueAtNow(totalSupplyHistory, totalSupplyAtCheckpoint);
      emit Transfer(0, _addresses[i], _balances[i]);
    }
    return true;
  }

   
  function lockPresaleBalances() public onlyController returns (bool) {
    presaleBalancesLocked = true;
    return true;
  }

   
  function finishMinting() public onlyController returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }

   
  function enableTransfers(bool _value) public onlyController {
    transfersEnabled = _value;
  }

   
  function enableMasterTransfers(bool _value) public onlyController {
    masterTransfersEnabled = _value;
  }

   
  function getValueAt(Checkpoint[] storage _checkpoints, uint256 _block) constant internal returns (uint256) {

      if (_checkpoints.length == 0)
        return 0;
       
      if (_block >= _checkpoints[_checkpoints.length-1].fromBlock)
        return _checkpoints[_checkpoints.length-1].value;
      if (_block < _checkpoints[0].fromBlock)
        return 0;

       
      uint256 min = 0;
      uint256 max = _checkpoints.length-1;
      while (max > min) {
          uint256 mid = (max + min + 1) / 2;
          if (_checkpoints[mid].fromBlock<=_block) {
              min = mid;
          } else {
              max = mid-1;
          }
      }
      return _checkpoints[min].value;
  }


   
  function updateValueAtNow(Checkpoint[] storage _checkpoints, uint256 _value) internal {
      if ((_checkpoints.length == 0) || (_checkpoints[_checkpoints.length-1].fromBlock < block.number)) {
              Checkpoint storage newCheckPoint = _checkpoints[_checkpoints.length++];
              newCheckPoint.fromBlock = uint128(block.number);
              newCheckPoint.value = uint128(_value);
          } else {
              Checkpoint storage oldCheckPoint = _checkpoints[_checkpoints.length-1];
              oldCheckPoint.value = uint128(_value);
          }
  }


  function min(uint256 a, uint256 b) internal pure returns (uint) {
      return a < b ? a : b;
  }

   
  function createCloneToken(uint256 _snapshotBlock, string _name, string _symbol) public returns(address) {

      if (_snapshotBlock == 0) {
        _snapshotBlock = block.number;
      }

      if (_snapshotBlock > block.number) {
        _snapshotBlock = block.number;
      }

      LedToken cloneToken = tokenFactory.createCloneToken(
          this,
          _snapshotBlock,
          _name,
          _symbol
        );


      cloneToken.transferControl(msg.sender);

       
      emit NewCloneToken(address(cloneToken));
      return address(cloneToken);
    }

}

 
contract LedTokenInterface is Controllable {

  bool public transfersEnabled;

  event Mint(address indexed to, uint256 amount);
  event MintFinished();
  event ClaimedTokens(address indexed _token, address indexed _owner, uint _amount);
  event NewCloneToken(address indexed _cloneToken, uint _snapshotBlock);
  event Approval(address indexed _owner, address indexed _spender, uint256 _amount);
  event Transfer(address indexed from, address indexed to, uint256 value);

  function totalSupply() public constant returns (uint);
  function totalSupplyAt(uint _blockNumber) public constant returns(uint);
  function balanceOf(address _owner) public constant returns (uint256 balance);
  function balanceOfAt(address _owner, uint _blockNumber) public constant returns (uint);
  function transfer(address _to, uint256 _amount) public returns (bool success);
  function transferFrom(address _from, address _to, uint256 _amount) public returns (bool success);
  function approve(address _spender, uint256 _amount) public returns (bool success);
  function approveAndCall(address _spender, uint256 _amount, bytes _extraData) public returns (bool success);
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining);
  function mint(address _owner, uint _amount) public returns (bool);
  function importPresaleBalances(address[] _addresses, uint256[] _balances, address _presaleAddress) public returns (bool);
  function lockPresaleBalances() public returns (bool);
  function finishMinting() public returns (bool);
  function enableTransfers(bool _value) public;
  function enableMasterTransfers(bool _value) public;
  function createCloneToken(uint _snapshotBlock, string _cloneTokenName, string _cloneTokenSymbol) public returns (address);

}

 
contract Presale is Crowdsale {

  uint256 public tokenCap = PRESALE_TOKENCAP;
  uint256 public cap = tokenCap * DECIMALS_MULTIPLIER;
  uint256 public weiCap = tokenCap * PRESALE_BASE_PRICE_IN_WEI;

  constructor(address _tokenAddress, uint256 _startTime, uint256 _endTime) public {
    

    startTime = _startTime;
    endTime = _endTime;
    ledToken = LedTokenInterface(_tokenAddress);

    assert(_tokenAddress != 0x0);
    assert(_startTime > 0);
    assert(_endTime > _startTime);
  }

     
  function() public payable {
    buyTokens(msg.sender);
  }

   
  function buyTokens(address _beneficiary) public payable whenNotPaused whenNotFinalized {
    require(_beneficiary != 0x0);
    require(validPurchase());

    uint256 weiAmount = msg.value;
    require(weiAmount >= MIN_PURCHASE_OTHERSALES && weiAmount <= MAX_PURCHASE);
    uint256 priceInWei = PRESALE_BASE_PRICE_IN_WEI;
    
    totalWeiRaised = totalWeiRaised.add(weiAmount);

    uint256 bonusPercentage = determineBonus(weiAmount);
    uint256 bonusTokens;

    uint256 initialTokens = weiAmount.mul(DECIMALS_MULTIPLIER).div(priceInWei);
    if(bonusPercentage>0){
      uint256 initialDivided = initialTokens.div(100);
      bonusTokens = initialDivided.mul(bonusPercentage);
    } else {
      bonusTokens = 0;
    }
    uint256 tokens = initialTokens.add(bonusTokens);
    tokensMinted = tokensMinted.add(tokens);
    require(tokensMinted < cap);

    contributors = contributors.add(1);

    ledToken.mint(_beneficiary, tokens);
    emit TokenPurchase(msg.sender, _beneficiary, weiAmount, tokens);
    forwardFunds();
  }

  function determineBonus(uint256 _wei) public view returns (uint256) {
    if(_wei > PRESALE_LEVEL_1) {
      if(_wei > PRESALE_LEVEL_2) {
        if(_wei > PRESALE_LEVEL_3) {
          if(_wei > PRESALE_LEVEL_4) {
            if(_wei > PRESALE_LEVEL_5) {
              return PRESALE_PERCENTAGE_5;
            } else {
              return PRESALE_PERCENTAGE_4;
            }
          } else {
            return PRESALE_PERCENTAGE_3;
          }
        } else {
          return PRESALE_PERCENTAGE_2;
        }
      } else {
        return PRESALE_PERCENTAGE_1;
      }
    } else {
      return 0;
    }
  }

  function finalize() public onlyOwner {
    require(paused);
    require(!finalized);
    surplusTokens = cap - tokensMinted;
    ledToken.mint(ledMultiSig, surplusTokens);
    ledToken.transferControl(owner);

    emit Finalized();

    finalized = true;
  }

  function getInfo() public view returns(uint256, uint256, string, bool,  uint256, uint256, uint256, 
  bool, uint256, uint256){
    uint256 decimals = 18;
    string memory symbol = "LED";
    bool transfersEnabled = ledToken.transfersEnabled();
    return (
      TOTAL_TOKENCAP,  
      decimals,  
      symbol,
      transfersEnabled,
      contributors,
      totalWeiRaised,
      tokenCap,  
      started,
      startTime,  
      endTime
    );
  }
  
  function getInfoLevels() public view returns(uint256, uint256, uint256, uint256, uint256, uint256, 
  uint256, uint256, uint256, uint256){
    return (
      PRESALE_LEVEL_1,  
      PRESALE_LEVEL_2,
      PRESALE_LEVEL_3,
      PRESALE_LEVEL_4,
      PRESALE_LEVEL_5,
      PRESALE_PERCENTAGE_1,  
      PRESALE_PERCENTAGE_2,
      PRESALE_PERCENTAGE_3,
      PRESALE_PERCENTAGE_4,
      PRESALE_PERCENTAGE_5
    );
  }

}

 
contract PrivateSale is Crowdsale {

  uint256 public tokenCap = PRIVATESALE_TOKENCAP;
  uint256 public cap = tokenCap * DECIMALS_MULTIPLIER;
  uint256 public weiCap = tokenCap * PRIVATESALE_BASE_PRICE_IN_WEI;

  constructor(address _tokenAddress, uint256 _startTime, uint256 _endTime) public {
    

    startTime = _startTime;
    endTime = _endTime;
    ledToken = LedTokenInterface(_tokenAddress);

    assert(_tokenAddress != 0x0);
    assert(_startTime > 0);
    assert(_endTime > _startTime);
  }

     
  function() public payable {
    buyTokens(msg.sender);
  }

   
  function buyTokens(address _beneficiary) public payable whenNotPaused whenNotFinalized {
    require(_beneficiary != 0x0);
    require(validPurchase());


    uint256 weiAmount = msg.value;
    require(weiAmount >= MIN_PURCHASE_OTHERSALES && weiAmount <= MAX_PURCHASE);
    uint256 priceInWei = PRIVATESALE_BASE_PRICE_IN_WEI;
    totalWeiRaised = totalWeiRaised.add(weiAmount);

    uint256 tokens = weiAmount.mul(DECIMALS_MULTIPLIER).div(priceInWei);
    tokensMinted = tokensMinted.add(tokens);
    require(tokensMinted < cap);

    contributors = contributors.add(1);

    ledToken.mint(_beneficiary, tokens);
    emit TokenPurchase(msg.sender, _beneficiary, weiAmount, tokens);
    forwardFunds();
  }

  function finalize() public onlyOwner {
    require(paused);
    require(!finalized);
    surplusTokens = cap - tokensMinted;
    ledToken.mint(ledMultiSig, surplusTokens);
    ledToken.transferControl(owner);

    emit Finalized();

    finalized = true;
  }

  function getInfo() public view returns(uint256, uint256, string, bool,  uint256, uint256, uint256, 
  bool, uint256, uint256){
    uint256 decimals = 18;
    string memory symbol = "LED";
    bool transfersEnabled = ledToken.transfersEnabled();
    return (
      TOTAL_TOKENCAP,  
      decimals,  
      symbol,
      transfersEnabled,
      contributors,
      totalWeiRaised,
      tokenCap,  
      started,
      startTime,  
      endTime
    );
  }

}

 
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
    uint256 c = a / b;
     
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

contract TokenFactory {

    function createCloneToken(
        address _parentToken,
        uint _snapshotBlock,
        string _tokenName,
        string _tokenSymbol
        ) public returns (LedToken) {

        LedToken newToken = new LedToken(
            this,
            _parentToken,
            _snapshotBlock,
            _tokenName,
            _tokenSymbol
        );

        newToken.transferControl(msg.sender);
        return newToken;
    }
}

contract TokenFactoryInterface {

    function createCloneToken(
        address _parentToken,
        uint _snapshotBlock,
        string _tokenName,
        string _tokenSymbol
      ) public returns (LedToken newToken);
}

 
contract TokenSale is Crowdsale {

  uint256 public tokenCap = ICO_TOKENCAP;
  uint256 public cap = tokenCap * DECIMALS_MULTIPLIER;
  uint256 public weiCap = tokenCap * ICO_BASE_PRICE_IN_WEI;

  uint256 public allocatedTokens;

  constructor(address _tokenAddress, uint256 _startTime, uint256 _endTime) public {
    

    startTime = _startTime;
    endTime = _endTime;
    ledToken = LedTokenInterface(_tokenAddress);

    assert(_tokenAddress != 0x0);
    assert(_startTime > 0);
    assert(_endTime > _startTime);
  }

     
  function() public payable {
    buyTokens(msg.sender);
  }

   
  function buyTokens(address _beneficiary) public payable whenNotPaused whenNotFinalized {
    require(_beneficiary != 0x0);
    require(validPurchase());

    uint256 weiAmount = msg.value;
    require(weiAmount >= MIN_PURCHASE_OTHERSALES && weiAmount <= MAX_PURCHASE);
    uint256 priceInWei = ICO_BASE_PRICE_IN_WEI;
    totalWeiRaised = totalWeiRaised.add(weiAmount);

    uint256 bonusPercentage = determineBonus(weiAmount);
    uint256 bonusTokens;

    uint256 initialTokens = weiAmount.mul(DECIMALS_MULTIPLIER).div(priceInWei);
    if(bonusPercentage>0){
      uint256 initialDivided = initialTokens.div(100);
      bonusTokens = initialDivided.mul(bonusPercentage);
    } else {
      bonusTokens = 0;
    }
    uint256 tokens = initialTokens.add(bonusTokens);
    tokensMinted = tokensMinted.add(tokens);
    require(tokensMinted < cap);

    contributors = contributors.add(1);

    ledToken.mint(_beneficiary, tokens);
    emit TokenPurchase(msg.sender, _beneficiary, weiAmount, tokens);
    forwardFunds();
  }

  function determineBonus(uint256 _wei) public view returns (uint256) {
    if(_wei > ICO_LEVEL_1) {
      if(_wei > ICO_LEVEL_2) {
        if(_wei > ICO_LEVEL_3) {
          if(_wei > ICO_LEVEL_4) {
            if(_wei > ICO_LEVEL_5) {
              return ICO_PERCENTAGE_5;
            } else {
              return ICO_PERCENTAGE_4;
            }
          } else {
            return ICO_PERCENTAGE_3;
          }
        } else {
          return ICO_PERCENTAGE_2;
        }
      } else {
        return ICO_PERCENTAGE_1;
      }
    } else {
      return 0;
    }
  }

  function allocateLedTokens() public onlyOwner whenNotFinalized {
    require(!ledTokensAllocated);
    allocatedTokens = LEDTEAM_TOKENS.mul(DECIMALS_MULTIPLIER);
    ledToken.mint(ledMultiSig, allocatedTokens);
    ledTokensAllocated = true;
  }

  function finalize() public onlyOwner {
    require(paused);
    require(ledTokensAllocated);

    surplusTokens = cap - tokensMinted;
    ledToken.mint(ledMultiSig, surplusTokens);

    ledToken.finishMinting();
    ledToken.enableTransfers(true);
    emit Finalized();

    finalized = true;
  }

  function getInfo() public view returns(uint256, uint256, string, bool,  uint256, uint256, uint256, 
  bool, uint256, uint256){
    uint256 decimals = 18;
    string memory symbol = "LED";
    bool transfersEnabled = ledToken.transfersEnabled();
    return (
      TOTAL_TOKENCAP,  
      decimals,  
      symbol,
      transfersEnabled,
      contributors,
      totalWeiRaised,
      tokenCap,  
      started,
      startTime,  
      endTime
    );
  }
  
  function getInfoLevels() public view returns(uint256, uint256, uint256, uint256, uint256, uint256, 
  uint256, uint256, uint256, uint256){
    return (
      ICO_LEVEL_1,  
      ICO_LEVEL_2,
      ICO_LEVEL_3,
      ICO_LEVEL_4,
      ICO_LEVEL_5,
      ICO_PERCENTAGE_1,  
      ICO_PERCENTAGE_2,
      ICO_PERCENTAGE_3,
      ICO_PERCENTAGE_4,
      ICO_PERCENTAGE_5
    );
  }

}
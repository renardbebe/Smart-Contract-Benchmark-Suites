 

pragma solidity ^0.4.18;
 
contract SafeMath {
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
  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }
  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }
  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }
  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }
}
 
contract ERC20Basic {
  uint256 public totalSupply;
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
 
library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    assert(token.transfer(to, value));
  }
  function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
    assert(token.transferFrom(from, to, value));
  }
  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    assert(token.approve(spender, value));
  }
}
 
contract Ownable {
  address public owner;
   
  function Ownable() {
    owner = msg.sender;
  }
   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
   
  function transferOwnership(address newOwner) onlyOwner {
    require(newOwner != address(0));
    owner = newOwner;
  }
}
 
contract KYC is Ownable {
   
  mapping (address => bool) public registeredAddress;
   
  mapping (address => bool) public admin;
  event Registered(address indexed _addr);
  event Unregistered(address indexed _addr);
  event NewAdmin(address indexed _addr);
  event ClaimedTokens(address _token, address owner, uint256 balance);
   
  modifier onlyRegistered(address _addr) {
    require(registeredAddress[_addr]);
    _;
  }
   
  modifier onlyAdmin() {
    require(admin[msg.sender]);
    _;
  }
  function KYC() {
    admin[msg.sender] = true;
  }
   
  function setAdmin(address _addr)
    public
    onlyOwner
  {
    require(_addr != address(0) && admin[_addr] == false);
    admin[_addr] = true;
    NewAdmin(_addr);
  }
   
  function register(address _addr)
    public
    onlyAdmin
  {
    require(_addr != address(0) && registeredAddress[_addr] == false);
    registeredAddress[_addr] = true;
    Registered(_addr);
  }
   
  function registerByList(address[] _addrs)
    public
    onlyAdmin
  {
    for(uint256 i = 0; i < _addrs.length; i++) {
      require(_addrs[i] != address(0) && registeredAddress[_addrs[i]] == false);
      registeredAddress[_addrs[i]] = true;
      Registered(_addrs[i]);
    }
  }
   
  function unregister(address _addr)
    public
    onlyAdmin
    onlyRegistered(_addr)
  {
    registeredAddress[_addr] = false;
    Unregistered(_addr);
  }
   
  function unregisterByList(address[] _addrs)
    public
    onlyAdmin
  {
    for(uint256 i = 0; i < _addrs.length; i++) {
      require(registeredAddress[_addrs[i]]);
      registeredAddress[_addrs[i]] = false;
      Unregistered(_addrs[i]);
    }
  }
  function claimTokens(address _token) public onlyOwner {
    if (_token == 0x0) {
        owner.transfer(this.balance);
        return;
    }
    ERC20Basic token = ERC20Basic(_token);
    uint256 balance = token.balanceOf(this);
    token.transfer(owner, balance);
    ClaimedTokens(_token, owner, balance);
  }
}
 
 
 
 
 
 
 
 
contract Controlled {
     
     
    modifier onlyController { require(msg.sender == controller); _; }
    address public controller;
    function Controlled() public { controller = msg.sender;}
     
     
    function changeController(address _newController) public onlyController {
        controller = _newController;
    }
}
 
contract TokenController {
     
     
     
    function proxyPayment(address _owner) public payable returns(bool);
     
     
     
     
     
     
    function onTransfer(address _from, address _to, uint _amount) public returns(bool);
     
     
     
     
     
     
    function onApprove(address _owner, address _spender, uint _amount) public
        returns(bool);
}
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 _amount, address _token, bytes _data) public;
}
 
 
 
contract MiniMeToken is Controlled {
    string public name;                 
    uint8 public decimals;              
    string public symbol;               
    string public version = 'MMT_0.2';  
     
     
     
    struct  Checkpoint {
         
        uint128 fromBlock;
         
        uint128 value;
    }
     
     
    MiniMeToken public parentToken;
     
     
    uint public parentSnapShotBlock;
     
    uint public creationBlock;
     
     
     
    mapping (address => Checkpoint[]) balances;
     
    mapping (address => mapping (address => uint256)) allowed;
     
    Checkpoint[] totalSupplyHistory;
     
    bool public transfersEnabled;
     
    MiniMeTokenFactory public tokenFactory;
 
 
 
     
     
     
     
     
     
     
     
     
     
     
     
     
    function MiniMeToken(
        address _tokenFactory,
        address _parentToken,
        uint _parentSnapShotBlock,
        string _tokenName,
        uint8 _decimalUnits,
        string _tokenSymbol,
        bool _transfersEnabled
    ) public {
        tokenFactory = MiniMeTokenFactory(_tokenFactory);
        name = _tokenName;                                  
        decimals = _decimalUnits;                           
        symbol = _tokenSymbol;                              
        parentToken = MiniMeToken(_parentToken);
        parentSnapShotBlock = _parentSnapShotBlock;
        transfersEnabled = _transfersEnabled;
        creationBlock = block.number;
    }
 
 
 
     
     
     
     
    function transfer(address _to, uint256 _amount) public returns (bool success) {
        require(transfersEnabled);
        return doTransfer(msg.sender, _to, _amount);
    }
     
     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _amount
    ) public returns (bool success) {
         
         
         
         
        if (msg.sender != controller) {
            require(transfersEnabled);
             
            if (allowed[_from][msg.sender] < _amount) return false;
            allowed[_from][msg.sender] -= _amount;
        }
        return doTransfer(_from, _to, _amount);
    }
     
     
     
     
     
     
    function doTransfer(address _from, address _to, uint _amount
    ) internal returns(bool) {
           if (_amount == 0) {
               return true;
           }
           require(parentSnapShotBlock < block.number);
            
           require((_to != 0) && (_to != address(this)));
            
            
           var previousBalanceFrom = balanceOfAt(_from, block.number);
           if (previousBalanceFrom < _amount) {
               return false;
           }
            
           if (isContract(controller)) {
               require(TokenController(controller).onTransfer(_from, _to, _amount));
           }
            
            
           updateValueAtNow(balances[_from], previousBalanceFrom - _amount);
            
            
           var previousBalanceTo = balanceOfAt(_to, block.number);
           require(previousBalanceTo + _amount >= previousBalanceTo);  
           updateValueAtNow(balances[_to], previousBalanceTo + _amount);
            
           Transfer(_from, _to, _amount);
           return true;
    }
     
     
    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balanceOfAt(_owner, block.number);
    }
     
     
     
     
     
     
    function approve(address _spender, uint256 _amount) public returns (bool success) {
        require(transfersEnabled);
         
         
         
         
        require((_amount == 0) || (allowed[msg.sender][_spender] == 0));
         
        if (isContract(controller)) {
            require(TokenController(controller).onApprove(msg.sender, _spender, _amount));
        }
        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }
     
     
     
     
     
    function allowance(address _owner, address _spender
    ) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
     
     
     
     
     
     
     
    function approveAndCall(address _spender, uint256 _amount, bytes _extraData
    ) public returns (bool success) {
        require(approve(_spender, _amount));
        ApproveAndCallFallBack(_spender).receiveApproval(
            msg.sender,
            _amount,
            this,
            _extraData
        );
        return true;
    }
     
     
    function totalSupply() public constant returns (uint) {
        return totalSupplyAt(block.number);
    }
 
 
 
     
     
     
     
    function balanceOfAt(address _owner, uint _blockNumber) public constant
        returns (uint) {
         
         
         
         
         
        if ((balances[_owner].length == 0)
            || (balances[_owner][0].fromBlock > _blockNumber)) {
            if (address(parentToken) != 0) {
                return parentToken.balanceOfAt(_owner, min(_blockNumber, parentSnapShotBlock));
            } else {
                 
                return 0;
            }
         
        } else {
            return getValueAt(balances[_owner], _blockNumber);
        }
    }
     
     
     
    function totalSupplyAt(uint _blockNumber) public constant returns(uint) {
         
         
         
         
         
        if ((totalSupplyHistory.length == 0)
            || (totalSupplyHistory[0].fromBlock > _blockNumber)) {
            if (address(parentToken) != 0) {
                return parentToken.totalSupplyAt(min(_blockNumber, parentSnapShotBlock));
            } else {
                return 0;
            }
         
        } else {
            return getValueAt(totalSupplyHistory, _blockNumber);
        }
    }
 
 
 
     
     
     
     
     
     
     
     
     
     
    function createCloneToken(
        string _cloneTokenName,
        uint8 _cloneDecimalUnits,
        string _cloneTokenSymbol,
        uint _snapshotBlock,
        bool _transfersEnabled
        ) public returns(address) {
        if (_snapshotBlock == 0) _snapshotBlock = block.number;
        MiniMeToken cloneToken = tokenFactory.createCloneToken(
            this,
            _snapshotBlock,
            _cloneTokenName,
            _cloneDecimalUnits,
            _cloneTokenSymbol,
            _transfersEnabled
            );
        cloneToken.changeController(msg.sender);
         
        NewCloneToken(address(cloneToken), _snapshotBlock);
        return address(cloneToken);
    }
 
 
 
     
     
     
     
    function generateTokens(address _owner, uint _amount
    ) public onlyController returns (bool) {
        uint curTotalSupply = totalSupply();
        require(curTotalSupply + _amount >= curTotalSupply);  
        uint previousBalanceTo = balanceOf(_owner);
        require(previousBalanceTo + _amount >= previousBalanceTo);  
        updateValueAtNow(totalSupplyHistory, curTotalSupply + _amount);
        updateValueAtNow(balances[_owner], previousBalanceTo + _amount);
        Transfer(0, _owner, _amount);
        return true;
    }
     
     
     
     
    function destroyTokens(address _owner, uint _amount
    ) onlyController public returns (bool) {
        uint curTotalSupply = totalSupply();
        require(curTotalSupply >= _amount);
        uint previousBalanceFrom = balanceOf(_owner);
        require(previousBalanceFrom >= _amount);
        updateValueAtNow(totalSupplyHistory, curTotalSupply - _amount);
        updateValueAtNow(balances[_owner], previousBalanceFrom - _amount);
        Transfer(_owner, 0, _amount);
        return true;
    }
 
 
 
     
     
    function enableTransfers(bool _transfersEnabled) public onlyController {
        transfersEnabled = _transfersEnabled;
    }
 
 
 
     
     
     
     
    function getValueAt(Checkpoint[] storage checkpoints, uint _block
    ) constant internal returns (uint) {
        if (checkpoints.length == 0) return 0;
         
        if (_block >= checkpoints[checkpoints.length-1].fromBlock)
            return checkpoints[checkpoints.length-1].value;
        if (_block < checkpoints[0].fromBlock) return 0;
         
        uint min = 0;
        uint max = checkpoints.length-1;
        while (max > min) {
            uint mid = (max + min + 1)/ 2;
            if (checkpoints[mid].fromBlock<=_block) {
                min = mid;
            } else {
                max = mid-1;
            }
        }
        return checkpoints[min].value;
    }
     
     
     
     
    function updateValueAtNow(Checkpoint[] storage checkpoints, uint _value
    ) internal  {
        if ((checkpoints.length == 0)
        || (checkpoints[checkpoints.length -1].fromBlock < block.number)) {
               Checkpoint storage newCheckPoint = checkpoints[ checkpoints.length++ ];
               newCheckPoint.fromBlock =  uint128(block.number);
               newCheckPoint.value = uint128(_value);
           } else {
               Checkpoint storage oldCheckPoint = checkpoints[checkpoints.length-1];
               oldCheckPoint.value = uint128(_value);
           }
    }
     
     
     
    function isContract(address _addr) constant internal returns(bool) {
        uint size;
        if (_addr == 0) return false;
        assembly {
            size := extcodesize(_addr)
        }
        return size>0;
    }
     
    function min(uint a, uint b) pure internal returns (uint) {
        return a < b ? a : b;
    }
     
     
     
    function () public payable {
        require(isContract(controller));
        require(TokenController(controller).proxyPayment.value(msg.value)(msg.sender));
    }
 
 
 
     
     
     
     
    function claimTokens(address _token) public onlyController {
        if (_token == 0x0) {
            controller.transfer(this.balance);
            return;
        }
        MiniMeToken token = MiniMeToken(_token);
        uint balance = token.balanceOf(this);
        token.transfer(controller, balance);
        ClaimedTokens(_token, controller, balance);
    }
 
 
 
    event ClaimedTokens(address indexed _token, address indexed _controller, uint _amount);
    event Transfer(address indexed _from, address indexed _to, uint256 _amount);
    event NewCloneToken(address indexed _cloneToken, uint _snapshotBlock);
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _amount
        );
}
 
 
 
 
 
 
contract MiniMeTokenFactory {
     
     
     
     
     
     
     
     
     
     
    function createCloneToken(
        address _parentToken,
        uint _snapshotBlock,
        string _tokenName,
        uint8 _decimalUnits,
        string _tokenSymbol,
        bool _transfersEnabled
    ) public returns (MiniMeToken) {
        MiniMeToken newToken = new MiniMeToken(
            this,
            _parentToken,
            _snapshotBlock,
            _tokenName,
            _decimalUnits,
            _tokenSymbol,
            _transfersEnabled
            );
        newToken.changeController(msg.sender);
        return newToken;
    }
}
contract ATC is MiniMeToken {
  mapping (address => bool) public blacklisted;
  bool public generateFinished;
   
  function ATC(address _tokenFactory)
          MiniMeToken(
              _tokenFactory,
              0x0,                      
              0,                        
              "Aston Token",   
              18,                       
              "ATC",                    
              false                      
          ) {}
  function generateTokens(address _owner, uint _amount
      ) public onlyController returns (bool) {
        require(generateFinished == false);
         
        return super.generateTokens(_owner, _amount);
      }
  function doTransfer(address _from, address _to, uint _amount
      ) internal returns(bool) {
        require(blacklisted[_from] == false);
        return super.doTransfer(_from, _to, _amount);
      }
  function finishGenerating() public onlyController returns (bool success) {
    generateFinished = true;
    return true;
  }
  function blacklistAccount(address tokenOwner) public onlyController returns (bool success) {
    blacklisted[tokenOwner] = true;
    return true;
  }
  function unBlacklistAccount(address tokenOwner) public onlyController returns (bool success) {
    blacklisted[tokenOwner] = false;
    return true;
  }
}
 
contract RefundVault is Ownable, SafeMath{
  enum State { Active, Refunding, Closed }
  mapping (address => uint256) public deposited;
  mapping (address => uint256) public refunded;
  State public state;
  address[] public reserveWallet;
  event Closed();
  event RefundsEnabled();
  event Refunded(address indexed beneficiary, uint256 weiAmount);
   
  function RefundVault(address[] _reserveWallet) {
    state = State.Active;
    reserveWallet = _reserveWallet;
  }
   
  function deposit(address investor) onlyOwner payable {
    require(state == State.Active);
    deposited[investor] = add(deposited[investor], msg.value);
  }
  event Transferred(address _to, uint _value);
   
  function close() onlyOwner {
    require(state == State.Active);
    state = State.Closed;
    uint256 balance = this.balance;
    uint256 reserveAmountForEach = div(balance, reserveWallet.length);
    for(uint8 i = 0; i < reserveWallet.length; i++){
      reserveWallet[i].transfer(reserveAmountForEach);
      Transferred(reserveWallet[i], reserveAmountForEach);
    }
    Closed();
  }
   
  function enableRefunds() onlyOwner {
    require(state == State.Active);
    state = State.Refunding;
    RefundsEnabled();
  }
   
  function refund(address investor) returns (bool) {
    require(state == State.Refunding);
    if (refunded[investor] > 0) {
      return false;
    }
    uint256 depositedValue = deposited[investor];
    deposited[investor] = 0;
    refunded[investor] = depositedValue;
    investor.transfer(depositedValue);
    Refunded(investor, depositedValue);
    return true;
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
   
  function pause() onlyOwner whenNotPaused {
    paused = true;
    Pause();
  }
   
  function unpause() onlyOwner whenPaused {
    paused = false;
    Unpause();
  }
}
contract ATCCrowdSale is Ownable, SafeMath, Pausable {
  KYC public kyc;
  ATC public token;
  RefundVault public vault;
  address public presale;
  address public bountyAddress;  
  address public partnersAddress;  
  address public ATCReserveLocker;  
  address public teamLocker;  
  struct Period {
    uint256 startTime;
    uint256 endTime;
    uint256 bonus;  
  }
  uint256 public baseRate;  
  uint256[] public additionalBonusAmounts;
  Period[] public periods;
  uint8 constant public MAX_PERIOD_COUNT = 8;
  uint256 public weiRaised;
  uint256 public maxEtherCap;
  uint256 public minEtherCap;
  mapping (address => uint256) public beneficiaryFunded;
  address[] investorList;
  mapping (address => bool) inInvestorList;
  address public ATCController;
  bool public isFinalized;
  uint256 public refundCompleted;
  bool public presaleFallBackCalled;
  uint256 public finalizedTime;
  bool public initialized;
  event CrowdSaleTokenPurchase(address indexed _investor, address indexed _beneficiary, uint256 _toFund, uint256 _tokens);
  event StartPeriod(uint256 _startTime, uint256 _endTime, uint256 _bonus);
  event Finalized();
  event PresaleFallBack(uint256 _presaleWeiRaised);
  event PushInvestorList(address _investor);
  event RefundAll(uint256 _numToRefund);
  event ClaimedTokens(address _claimToken, address owner, uint256 balance);
  event Initialize();
  function initialize (
    address _kyc,
    address _token,
    address _vault,
    address _presale,
    address _bountyAddress,
    address _partnersAddress,
    address _ATCReserveLocker,
    address _teamLocker,
    address _tokenController,
    uint256 _maxEtherCap,
    uint256 _minEtherCap,
    uint256 _baseRate,
    uint256[] _additionalBonusAmounts
    ) onlyOwner {
      require(!initialized);
      require(_kyc != 0x00 && _token != 0x00 && _vault != 0x00 && _presale != 0x00);
      require(_bountyAddress != 0x00 && _partnersAddress != 0x00);
      require(_ATCReserveLocker != 0x00 && _teamLocker != 0x00);
      require(_tokenController != 0x00);
      require(0 < _minEtherCap && _minEtherCap < _maxEtherCap);
      require(_baseRate > 0);
      require(_additionalBonusAmounts[0] > 0);
      for (uint i = 0; i < _additionalBonusAmounts.length - 1; i++) {
        require(_additionalBonusAmounts[i] < _additionalBonusAmounts[i + 1]);
      }
      kyc = KYC(_kyc);
      token = ATC(_token);
      vault = RefundVault(_vault);
      presale = _presale;
      bountyAddress = _bountyAddress;
      partnersAddress = _partnersAddress;
      ATCReserveLocker = _ATCReserveLocker;
      teamLocker = _teamLocker;
      ATCController = _tokenController;
      maxEtherCap = _maxEtherCap;
      minEtherCap = _minEtherCap;
      baseRate = _baseRate;
      additionalBonusAmounts = _additionalBonusAmounts;
      initialized = true;
      Initialize();
    }
  function () public payable {
    buy(msg.sender);
  }
  function presaleFallBack(uint256 _presaleWeiRaised) public returns (bool) {
    require(!presaleFallBackCalled);
    require(msg.sender == presale);
    weiRaised = _presaleWeiRaised;
    presaleFallBackCalled = true;
    PresaleFallBack(_presaleWeiRaised);
    return true;
  }
  function buy(address beneficiary)
    public
    payable
    whenNotPaused
  {
       
      require(presaleFallBackCalled);
      require(beneficiary != 0x00);
      require(kyc.registeredAddress(beneficiary));
      require(onSale());
      require(validPurchase());
      require(!isFinalized);
       
      uint256 weiAmount = msg.value;
      uint256 toFund;
      uint256 postWeiRaised = add(weiRaised, weiAmount);
      if (postWeiRaised > maxEtherCap) {
        toFund = sub(maxEtherCap, weiRaised);
      } else {
        toFund = weiAmount;
      }
      require(toFund > 0);
      require(weiAmount >= toFund);
      uint256 rate = calculateRate(toFund);
      uint256 tokens = mul(toFund, rate);
      uint256 toReturn = sub(weiAmount, toFund);
      pushInvestorList(msg.sender);
      weiRaised = add(weiRaised, toFund);
      beneficiaryFunded[beneficiary] = add(beneficiaryFunded[beneficiary], toFund);
      token.generateTokens(beneficiary, tokens);
      if (toReturn > 0) {
        msg.sender.transfer(toReturn);
      }
      forwardFunds(toFund);
      CrowdSaleTokenPurchase(msg.sender, beneficiary, toFund, tokens);
  }
  function pushInvestorList(address investor) internal {
    if (!inInvestorList[investor]) {
      inInvestorList[investor] = true;
      investorList.push(investor);
      PushInvestorList(investor);
    }
  }
  function validPurchase() internal view returns (bool) {
    bool nonZeroPurchase = msg.value != 0;
    return nonZeroPurchase && !maxReached();
  }
  function forwardFunds(uint256 toFund) internal {
    vault.deposit.value(toFund)(msg.sender);
  }
   
  function minReached() public view returns (bool) {
    return weiRaised >= minEtherCap;
  }
   
  function maxReached() public view returns (bool) {
    return weiRaised == maxEtherCap;
  }
  function getPeriodBonus() public view returns (uint256) {
    bool nowOnSale;
    uint256 currentPeriod;
    for (uint i = 0; i < periods.length; i++) {
      if (periods[i].startTime <= now && now <= periods[i].endTime) {
        nowOnSale = true;
        currentPeriod = i;
        break;
      }
    }
    require(nowOnSale);
    return periods[currentPeriod].bonus;
  }
   
  function calculateRate(uint256 toFund) public view returns (uint256)  {
    uint bonus = getPeriodBonus();
     
    if (additionalBonusAmounts[0] <= toFund) {
      bonus = add(bonus, 5);  
    }
    if (additionalBonusAmounts[1] <= toFund) {
      bonus = add(bonus, 5);  
    }
    if (additionalBonusAmounts[2] <= toFund) {
      bonus = 25;  
    }
    if (additionalBonusAmounts[3] <= toFund) {
      bonus = 30;  
    }
    return div(mul(baseRate, add(bonus, 100)), 100);
  }
  function startPeriod(uint256 _startTime, uint256 _endTime) public onlyOwner returns (bool) {
    require(periods.length < MAX_PERIOD_COUNT);
    require(now < _startTime && _startTime < _endTime);
    if (periods.length != 0) {
      require(sub(_endTime, _startTime) <= 7 days);
      require(periods[periods.length - 1].endTime < _startTime);
    }
     
    Period memory newPeriod;
    newPeriod.startTime = _startTime;
    newPeriod.endTime = _endTime;
    if(periods.length < 3) {
      newPeriod.bonus = sub(15, mul(5, periods.length));
    } else {
      newPeriod.bonus = 0;
    }
    periods.push(newPeriod);
    StartPeriod(_startTime, _endTime, newPeriod.bonus);
    return true;
  }
  function onSale() public returns (bool) {
    bool nowOnSale;
    for (uint i = 0; i < periods.length; i++) {
      if (periods[i].startTime <= now && now <= periods[i].endTime) {
        nowOnSale = true;
        break;
      }
    }
    return nowOnSale;
  }
   
  function finalize() onlyOwner {
    require(!isFinalized);
    require(!onSale() || maxReached());
    finalizedTime = now;
    finalization();
    Finalized();
    isFinalized = true;
  }
   
  function finalization() internal {
    if (minReached()) {
      vault.close();
      uint256 totalToken = token.totalSupply();
       
      uint256 bountyAmount = div(mul(totalToken, 5), 50);
      uint256 partnersAmount = div(mul(totalToken, 15), 50);
      uint256 reserveAmount = div(mul(totalToken, 15), 50);
      uint256 teamAmount = div(mul(totalToken, 15), 50);
      distributeToken(bountyAmount, partnersAmount, reserveAmount, teamAmount);
      token.enableTransfers(true);
    } else {
      vault.enableRefunds();
    }
    token.finishGenerating();
    token.changeController(ATCController);
  }
  function distributeToken(uint256 bountyAmount, uint256 partnersAmount, uint256 reserveAmount, uint256 teamAmount) internal {
    require(bountyAddress != 0x00 && partnersAddress != 0x00);
    require(ATCReserveLocker != 0x00 && teamLocker != 0x00);
    token.generateTokens(bountyAddress, bountyAmount);
    token.generateTokens(partnersAddress, partnersAmount);
    token.generateTokens(ATCReserveLocker, reserveAmount);
    token.generateTokens(teamLocker, teamAmount);
  }
   
  function refundAll(uint256 numToRefund) onlyOwner {
    require(isFinalized);
    require(!minReached());
    require(numToRefund > 0);
    uint256 limit = refundCompleted + numToRefund;
    if (limit > investorList.length) {
      limit = investorList.length;
    }
    for(uint256 i = refundCompleted; i < limit; i++) {
      vault.refund(investorList[i]);
    }
    refundCompleted = limit;
    RefundAll(numToRefund);
  }
   
  function claimRefund(address investor) returns (bool) {
    require(isFinalized);
    require(!minReached());
    return vault.refund(investor);
  }
  function claimTokens(address _claimToken) public onlyOwner {
    if (token.controller() == address(this)) {
         token.claimTokens(_claimToken);
    }
    if (_claimToken == 0x0) {
        owner.transfer(this.balance);
        return;
    }
    ERC20Basic claimToken = ERC20Basic(_claimToken);
    uint256 balance = claimToken.balanceOf(this);
    claimToken.transfer(owner, balance);
    ClaimedTokens(_claimToken, owner, balance);
  }
}
 
contract ReserveLocker is SafeMath{
  using SafeERC20 for ERC20Basic;
  ERC20Basic public token;
  ATCCrowdSale public crowdsale;
  address public beneficiary;
  function ReserveLocker(address _token, address _crowdsale, address _beneficiary) {
    require(_token != 0x00);
    require(_crowdsale != 0x00);
    require(_beneficiary != 0x00);
    token = ERC20Basic(_token);
    crowdsale = ATCCrowdSale(_crowdsale);
    beneficiary = _beneficiary;
  }
   
   function release() public {
     uint256 finalizedTime = crowdsale.finalizedTime();
     require(finalizedTime > 0 && now > add(finalizedTime, 2 years));
     uint256 amount = token.balanceOf(this);
     require(amount > 0);
     token.safeTransfer(beneficiary, amount);
   }
  function setToken(address newToken) public {
    require(msg.sender == beneficiary);
    require(newToken != 0x00);
    token = ERC20Basic(newToken);
  }
}
 
contract TeamLocker is SafeMath{
  using SafeERC20 for ERC20Basic;
  ERC20Basic public token;
  ATCCrowdSale public crowdsale;
  address[] public beneficiaries;
  uint256 public collectedTokens;
  function TeamLocker(address _token, address _crowdsale, address[] _beneficiaries) {
    require(_token != 0x00);
    require(_crowdsale != 0x00);
    for (uint i = 0; i < _beneficiaries.length; i++) {
      require(_beneficiaries[i] != 0x00);
    }
    token = ERC20Basic(_token);
    crowdsale = ATCCrowdSale(_crowdsale);
    beneficiaries = _beneficiaries;
  }
   
  function release() public {
    uint256 balance = token.balanceOf(address(this));
    uint256 total = add(balance, collectedTokens);
    uint256 finalizedTime = crowdsale.finalizedTime();
    require(finalizedTime > 0);
    uint256 lockTime1 = add(finalizedTime, 183 days);  
    uint256 lockTime2 = add(finalizedTime, 1 years);  
    uint256 currentRatio = 20;
    if (now >= lockTime1) {
      currentRatio = 50;
    }
    if (now >= lockTime2) {
      currentRatio = 100;
    }
    uint256 releasedAmount = div(mul(total, currentRatio), 100);
    uint256 grantAmount = sub(releasedAmount, collectedTokens);
    require(grantAmount > 0);
    collectedTokens = add(collectedTokens, grantAmount);
    uint256 grantAmountForEach = div(grantAmount, 3);
    for (uint i = 0; i < beneficiaries.length; i++) {
        token.safeTransfer(beneficiaries[i], grantAmountForEach);
    }
  }
  function setToken(address newToken) public {
    require(newToken != 0x00);
    bool isBeneficiary;
    for (uint i = 0; i < beneficiaries.length; i++) {
      if (msg.sender == beneficiaries[i]) {
        isBeneficiary = true;
      }
    }
    require(isBeneficiary);
    token = ERC20Basic(newToken);
  }
}
contract ATCCrowdSale2 is Ownable, SafeMath, Pausable {
  KYC public kyc;
  ATC public token;
  RefundVault public vault;
  address public bountyAddress;  
  address public partnersAddress;  
  address public ATCReserveLocker;  
  address public teamLocker;  
  struct Period {
    uint256 startTime;
    uint256 endTime;
    uint256 bonus;  
  }
  uint256 public baseRate;  
  uint256[] public additionalBonusAmounts;
  Period[] public periods;
  uint8 constant public MAX_PERIOD_COUNT = 8;
  uint256 public weiRaised;
  uint256 public maxEtherCap;
  uint256 public minEtherCap;
  mapping (address => uint256) public beneficiaryFunded;
  address[] investorList;
  mapping (address => bool) inInvestorList;
  address public ATCController;
  bool public isFinalized;
  uint256 public refundCompleted;
  uint256 public finalizedTime;
  bool public initialized;
  event CrowdSaleTokenPurchase(address indexed _investor, address indexed _beneficiary, uint256 _toFund, uint256 _tokens);
  event StartPeriod(uint256 _startTime, uint256 _endTime, uint256 _bonus);
  event Finalized();
  event PushInvestorList(address _investor);
  event RefundAll(uint256 _numToRefund);
  event ClaimedTokens(address _claimToken, address owner, uint256 balance);
  event Initialize();
  function initialize (
    address _kyc,
    address _token,
    address _vault,
    address _bountyAddress,
    address _partnersAddress,
    address _ATCReserveLocker,
    address _teamLocker,
    address _tokenController,
    uint256 _maxEtherCap,
    uint256 _minEtherCap,
    uint256 _baseRate,
    uint256[] _additionalBonusAmounts
    ) onlyOwner {
      require(!initialized);
      require(_kyc != 0x00 && _token != 0x00 && _vault != 0x00);
      require(_bountyAddress != 0x00 && _partnersAddress != 0x00);
      require(_ATCReserveLocker != 0x00 && _teamLocker != 0x00);
      require(_tokenController != 0x00);
      require(0 < _minEtherCap && _minEtherCap < _maxEtherCap);
      require(_baseRate > 0);
      require(_additionalBonusAmounts[0] > 0);
      for (uint i = 0; i < _additionalBonusAmounts.length - 1; i++) {
        require(_additionalBonusAmounts[i] < _additionalBonusAmounts[i + 1]);
      }
      kyc = KYC(_kyc);
      token = ATC(_token);
      vault = RefundVault(_vault);
      bountyAddress = _bountyAddress;
      partnersAddress = _partnersAddress;
      ATCReserveLocker = _ATCReserveLocker;
      teamLocker = _teamLocker;
      ATCController = _tokenController;
      maxEtherCap = _maxEtherCap;
      minEtherCap = _minEtherCap;
      baseRate = _baseRate;
      additionalBonusAmounts = _additionalBonusAmounts;
      initialized = true;
      Initialize();
    }
  function () public payable {
    buy(msg.sender);
  }
  function buy(address beneficiary)
    public
    payable
    whenNotPaused
  {
       
      require(beneficiary != 0x00);
      require(kyc.registeredAddress(beneficiary));
      require(onSale());
      require(validPurchase());
      require(!isFinalized);
       
      uint256 weiAmount = msg.value;
      uint256 toFund;
      uint256 postWeiRaised = add(weiRaised, weiAmount);
      if (postWeiRaised > maxEtherCap) {
        toFund = sub(maxEtherCap, weiRaised);
      } else {
        toFund = weiAmount;
      }
      require(toFund > 0);
      require(weiAmount >= toFund);
      uint256 rate = calculateRate(toFund);
      uint256 tokens = mul(toFund, rate);
      uint256 toReturn = sub(weiAmount, toFund);
      pushInvestorList(msg.sender);
      weiRaised = add(weiRaised, toFund);
      beneficiaryFunded[beneficiary] = add(beneficiaryFunded[beneficiary], toFund);
      token.generateTokens(beneficiary, tokens);
      if (toReturn > 0) {
        msg.sender.transfer(toReturn);
      }
      forwardFunds(toFund);
      CrowdSaleTokenPurchase(msg.sender, beneficiary, toFund, tokens);
  }
  function pushInvestorList(address investor) internal {
    if (!inInvestorList[investor]) {
      inInvestorList[investor] = true;
      investorList.push(investor);
      PushInvestorList(investor);
    }
  }
  function validPurchase() internal view returns (bool) {
    bool nonZeroPurchase = msg.value != 0;
    return nonZeroPurchase && !maxReached();
  }
  function forwardFunds(uint256 toFund) internal {
    vault.deposit.value(toFund)(msg.sender);
  }
   
  function minReached() public view returns (bool) {
    return weiRaised >= minEtherCap;
  }
   
  function maxReached() public view returns (bool) {
    return weiRaised == maxEtherCap;
  }
  function getPeriodBonus() public view returns (uint256) {
    bool nowOnSale;
    uint256 currentPeriod;
    for (uint i = 0; i < periods.length; i++) {
      if (periods[i].startTime <= now && now <= periods[i].endTime) {
        nowOnSale = true;
        currentPeriod = i;
        break;
      }
    }
    require(nowOnSale);
    return periods[currentPeriod].bonus;
  }
   
  function calculateRate(uint256 toFund) public view returns (uint256)  {
    uint bonus = getPeriodBonus();
     
    if (additionalBonusAmounts[0] <= toFund) {
      bonus = add(bonus, 5);  
    }
    if (additionalBonusAmounts[1] <= toFund) {
      bonus = add(bonus, 5);  
    }
    if (additionalBonusAmounts[2] <= toFund) {
      bonus = 25;  
    }
    if (additionalBonusAmounts[3] <= toFund) {
      bonus = 30;  
    }
    return div(mul(baseRate, add(bonus, 100)), 100);
  }
  function startPeriod(uint256 _startTime, uint256 _endTime) public onlyOwner returns (bool) {
    require(periods.length < MAX_PERIOD_COUNT);
    require(now < _startTime && _startTime < _endTime);
    if (periods.length != 0) {
      require(sub(_endTime, _startTime) <= 7 days);
      require(periods[periods.length - 1].endTime < _startTime);
    }
     
    Period memory newPeriod;
    newPeriod.startTime = _startTime;
    newPeriod.endTime = _endTime;
    if(periods.length < 3) {
      newPeriod.bonus = sub(15, mul(5, periods.length));
    } else {
      newPeriod.bonus = 0;
    }
    periods.push(newPeriod);
    StartPeriod(_startTime, _endTime, newPeriod.bonus);
    return true;
  }
  function onSale() public returns (bool) {
    bool nowOnSale;
    for (uint i = 0; i < periods.length; i++) {
      if (periods[i].startTime <= now && now <= periods[i].endTime) {
        nowOnSale = true;
        break;
      }
    }
    return nowOnSale;
  }
   
  function finalize() onlyOwner {
    require(!isFinalized);
    require(!onSale() || maxReached());
    finalizedTime = now;
    finalization();
    Finalized();
    isFinalized = true;
  }
   
  function finalization() internal {
    if (minReached()) {
      vault.close();
      uint256 totalToken = token.totalSupply();
       
      uint256 bountyAmount = div(mul(totalToken, 5), 50);
      uint256 partnersAmount = div(mul(totalToken, 15), 50);
      uint256 reserveAmount = div(mul(totalToken, 15), 50);
      uint256 teamAmount = div(mul(totalToken, 15), 50);
      distributeToken(bountyAmount, partnersAmount, reserveAmount, teamAmount);
      token.enableTransfers(true);
    } else {
      vault.enableRefunds();
    }
    token.finishGenerating();
    token.changeController(ATCController);
  }
  function distributeToken(uint256 bountyAmount, uint256 partnersAmount, uint256 reserveAmount, uint256 teamAmount) internal {
    require(bountyAddress != 0x00 && partnersAddress != 0x00);
    require(ATCReserveLocker != 0x00 && teamLocker != 0x00);
    token.generateTokens(bountyAddress, bountyAmount);
    token.generateTokens(partnersAddress, partnersAmount);
    token.generateTokens(ATCReserveLocker, reserveAmount);
    token.generateTokens(teamLocker, teamAmount);
  }
   
  function refundAll(uint256 numToRefund) onlyOwner {
    require(isFinalized);
    require(!minReached());
    require(numToRefund > 0);
    uint256 limit = refundCompleted + numToRefund;
    if (limit > investorList.length) {
      limit = investorList.length;
    }
    for(uint256 i = refundCompleted; i < limit; i++) {
      vault.refund(investorList[i]);
    }
    refundCompleted = limit;
    RefundAll(numToRefund);
  }
   
  function claimRefund(address investor) returns (bool) {
    require(isFinalized);
    require(!minReached());
    return vault.refund(investor);
  }
  function claimTokens(address _claimToken) public onlyOwner {
    if (token.controller() == address(this)) {
         token.claimTokens(_claimToken);
    }
    if (_claimToken == 0x0) {
        owner.transfer(this.balance);
        return;
    }
    ERC20Basic claimToken = ERC20Basic(_claimToken);
    uint256 balance = claimToken.balanceOf(this);
    claimToken.transfer(owner, balance);
    ClaimedTokens(_claimToken, owner, balance);
  }
}
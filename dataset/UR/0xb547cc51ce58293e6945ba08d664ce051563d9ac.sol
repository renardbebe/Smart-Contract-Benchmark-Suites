 

pragma solidity ^0.4.13;

library Math {
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

contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
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

   
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
}

contract Configurable is Ownable {
   
  event Configured();

  bool public configured = false;

   
  function finishConfiguration() public configuration returns (bool) {
    configured = true;
    Configured();
    return true;
  }

   
   
   
   
   
  modifier configuration() {
    require(msg.sender == owner);
    require(!configured);
    _;
  }

  modifier onlyAfterConfiguration() {
    require(configured);
    _;
  }
}

contract Crowdsale {
  using SafeMath for uint256;

   
  uint256 public startTime;
  uint256 public endTime;

   
  address public wallet;

   
  uint256 public rate;

   
  uint256 public weiRaised;

   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

  function Crowdsale(uint256 _startTime, uint256 _endTime, uint256 _rate, address _wallet) public {
    require(_startTime >= now);  
    require(_endTime >= _startTime);
    require(_rate > 0);
    require(_wallet != 0x0);

    startTime = _startTime;
    endTime = _endTime;
    rate = _rate;
    wallet = _wallet;
  }

   
  function () public payable {
    proxyPayment(msg.sender);
  }

   
   
   
  function proxyPayment(address _owner) public payable returns(bool);

   
  function hasEnded() public constant returns (bool) {
    return now > endTime;
  }

   
   
  function forwardFunds() internal {
    wallet.transfer(msg.value);
  }

   
  function validPurchase() internal constant returns (bool) {
    bool withinPeriod = now >= startTime && now <= endTime;
    bool nonZeroPurchase = msg.value != 0;
    return withinPeriod && nonZeroPurchase;
  }
}

contract CappedCrowdsale is Crowdsale {
  using SafeMath for uint256;

  uint256 public cap;

  function CappedCrowdsale(uint256 _cap) public {
    require(_cap > 0);
    cap = _cap;
  }

   
   
  function hasEnded() public constant returns (bool) {
    bool capReached = weiRaised >= cap;
    return super.hasEnded() || capReached;
  }

   
   
  function validPurchase() internal constant returns (bool) {
    bool withinCap = weiRaised.add(msg.value) <= cap;
    return super.validPurchase() && withinCap;
  }

}

contract FinalizableCrowdsale is Crowdsale, Ownable {
  using SafeMath for uint256;

  bool public isFinalized = false;

  event Finalized();

   
  function finalize() public onlyOwner {
    require(!isFinalized);
    require(hasEnded());

    finalization();
    Finalized();

    isFinalized = true;
  }

   
  function finalization() internal { }  
}

contract TokenController {
     
     
     
    function proxyPayment(address _owner) payable returns(bool);

     
     
     
     
     
     
    function onTransfer(address _from, address _to, uint _amount) returns(bool);

     
     
     
     
     
     
    function onApprove(address _owner, address _spender, uint _amount)
        returns(bool);
}

contract BloomTokenSale is CappedCrowdsale, Ownable, TokenController, Pausable, Configurable, FinalizableCrowdsale {
  using SafeMath for uint256;

  BLT public token;

   
   
  uint256 public constant TOTAL_SUPPLY = 1.5e8 ether;  
  uint256 internal constant FOUNDATION_SUPPLY = (TOTAL_SUPPLY * 4) / 10;  
  uint256 internal constant ADVISOR_SUPPLY = TOTAL_SUPPLY / 20;  
  uint256 internal constant PARTNERSHIP_SUPPLY = TOTAL_SUPPLY / 20;  
  uint256 internal constant CONTROLLER_ALLOCATION =
    TOTAL_SUPPLY - FOUNDATION_SUPPLY - PARTNERSHIP_SUPPLY;  
  uint256 internal constant WALLET_ALLOCATION = TOTAL_SUPPLY - CONTROLLER_ALLOCATION;  
  uint256 internal constant MAX_RAISE_IN_USD = 5e7;  

   
  uint256 internal constant WEI_PER_ETHER_TWO_DECIMALS = 1e20;
  uint256 internal constant TOKEN_UNITS_PER_TOKEN = 1e18;  

  uint256 public advisorPool = ADVISOR_SUPPLY;

  uint256 internal constant DUST = 1 finney;  

  event NewPresaleAllocation(address indexed holder, uint256 bltAmount);

  function BloomTokenSale(
    uint256 _startTime,
    uint256 _endTime,
    uint256 _rate,
    address _wallet,
    uint256 _cap
  ) public
    Crowdsale(_startTime, _endTime, _rate, _wallet)
    CappedCrowdsale(_cap) { }  

   
   
  function setToken(address _token) public presaleOnly {
    token = BLT(_token);
  }

   
  function allocateSupply() public presaleOnly {
    require(token.totalSupply() == 0);
    token.generateTokens(address(this), CONTROLLER_ALLOCATION);
    token.generateTokens(wallet, WALLET_ALLOCATION);
  }

   
   
   
   
   
   
  function allocateAdvisorTokens(address _receiver, uint256 _amount, uint64 _cliffDate, uint64 _vestingDate)
           public
           presaleOnly {
    require(_amount <= advisorPool);
    advisorPool = advisorPool.sub(_amount);
    allocatePresaleTokens(_receiver, _amount, _cliffDate, _vestingDate);
  }

   
   
   
   
   
   
  function allocatePresaleTokens(address _receiver, uint256 _amount, uint64 cliffDate, uint64 vestingDate)
           public
           presaleOnly {

    require(_amount <= 10 ** 25);  

     
    token.grantVestedTokens(_receiver, _amount, uint64(now), cliffDate, vestingDate, true, false);

    NewPresaleAllocation(_receiver, _amount);
  }

   
   
   
   
   
   
   
   
  function finishPresale(uint256 _cents, uint256 _weiRaisedOffChain) public presaleOnly returns (bool) {
    setCapFromEtherPrice(_cents);
    syncPresaleWeiRaised(_weiRaisedOffChain);
    transferUnallocatedAdvisorTokens();
    updateRateBasedOnFundsAndSupply();
    finishConfiguration();
  }

   
   
   
   
  function revokeGrant(address _holder, uint256 _grantId) public onlyOwner {
    token.revokeTokenGrant(_holder, wallet, _grantId);
  }

   
   
  function proxyPayment(address _beneficiary)
    public
    payable
    whenNotPaused
    onlyAfterConfiguration
    returns (bool) {
    require(_beneficiary != 0x0);
    require(validPurchase());

    uint256 weiAmount = msg.value;

     
    weiRaised = weiRaised.add(weiAmount);

     
    allocateTokens(_beneficiary, weiAmount);

     
    forwardFunds();

    return true;
  }

   
   
   
   
  function onTransfer(address _from, address _to, uint) public returns (bool) {
    return _from == address(this) || _to == address(wallet);
  }

   
   
  function onApprove(address, address, uint) public returns (bool) {
    return false;
  }

   
   
   
  function changeTokenController(address _newController) public onlyOwner whenFinalized {
    token.changeController(_newController);
  }

   
   
  function setCapFromEtherPrice(uint256 _cents) internal {
    require(_cents > 10000 && _cents < 100000);
    uint256 weiPerDollar = WEI_PER_ETHER_TWO_DECIMALS.div(_cents);
    cap = MAX_RAISE_IN_USD.mul(weiPerDollar);
  }

   
  function syncPresaleWeiRaised(uint256 _weiRaisedOffChain) internal {
    require(weiRaised == 0);
    weiRaised = wallet.balance.add(_weiRaisedOffChain);
  }

   
  function transferUnallocatedAdvisorTokens() internal {
    uint256 _unallocatedTokens = advisorPool;
     
    advisorPool = 0;
    token.transferFrom(address(this), wallet, _unallocatedTokens);
  }

   
  function updateRateBasedOnFundsAndSupply() internal {
    uint256 _unraisedWei = cap - weiRaised;
    uint256 _tokensForSale = token.balanceOf(address(this));
    rate = _tokensForSale.mul(1e18).div(_unraisedWei);
  }

   
   
   
   
  function allocateTokens(address _beneficiary, uint256 _weiAmount) internal {
    token.transferFrom(address(this), _beneficiary, tokensFor(_weiAmount));
  }

   
   
   
  function tokensFor(uint256 _weiAmount) internal constant returns (uint256) {
    return _weiAmount.mul(rate).div(1e18);
  }

   
   
  function validPurchase() internal constant returns (bool) {
    return super.validPurchase() && msg.value >= DUST && configured;
  }

   
  function finalization() internal {
    token.transferFrom(address(this), wallet, token.balanceOf(address(this)));
  }

  function inPresalePhase() internal constant beforeSale configuration returns (bool) {
    return true;
  }

  modifier presaleOnly() {
    require(inPresalePhase());
    _;
  }

  modifier beforeSale {
    require(now < startTime);  
    _;
  }

  modifier whenFinalized {
    require(isFinalized);
    _;
  }
}

contract Controlled {
     
     
    modifier onlyController { require(msg.sender == controller); _; }

    address public controller;

    function Controlled() { controller = msg.sender;}

     
     
    function changeController(address _newController) onlyController {
        controller = _newController;
    }
}

contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 _amount, address _token, bytes _data);
}

contract MiniMeToken is Controlled {

    string public name;                 
    uint8 public decimals;              
    string public symbol;               
    string public version = 'MMT_0.1';  


     
     
     
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
    ) {
        tokenFactory = MiniMeTokenFactory(_tokenFactory);
        name = _tokenName;                                  
        decimals = _decimalUnits;                           
        symbol = _tokenSymbol;                              
        parentToken = MiniMeToken(_parentToken);
        parentSnapShotBlock = _parentSnapShotBlock;
        transfersEnabled = _transfersEnabled;
        creationBlock = block.number;
    }


 
 
 

     
     
     
     
    function transfer(address _to, uint256 _amount) returns (bool success) {
        require(transfersEnabled);
        return doTransfer(msg.sender, _to, _amount);
    }

     
     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _amount
    ) returns (bool success) {

         
         
         
         
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

     
     
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balanceOfAt(_owner, block.number);
    }

     
     
     
     
     
     
    function approve(address _spender, uint256 _amount) returns (bool success) {
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
    ) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

     
     
     
     
     
     
     
    function approveAndCall(address _spender, uint256 _amount, bytes _extraData
    ) returns (bool success) {
        require(approve(_spender, _amount));

        ApproveAndCallFallBack(_spender).receiveApproval(
            msg.sender,
            _amount,
            this,
            _extraData
        );

        return true;
    }

     
     
    function totalSupply() constant returns (uint) {
        return totalSupplyAt(block.number);
    }


 
 
 

     
     
     
     
    function balanceOfAt(address _owner, uint _blockNumber) constant
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

     
     
     
    function totalSupplyAt(uint _blockNumber) constant returns(uint) {

         
         
         
         
         
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
        ) returns(address) {
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
    ) onlyController returns (bool) {
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
    ) onlyController returns (bool) {
        uint curTotalSupply = totalSupply();
        require(curTotalSupply >= _amount);
        uint previousBalanceFrom = balanceOf(_owner);
        require(previousBalanceFrom >= _amount);
        updateValueAtNow(totalSupplyHistory, curTotalSupply - _amount);
        updateValueAtNow(balances[_owner], previousBalanceFrom - _amount);
        Transfer(_owner, 0, _amount);
        return true;
    }

 
 
 


     
     
    function enableTransfers(bool _transfersEnabled) onlyController {
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

     
    function min(uint a, uint b) internal returns (uint) {
        return a < b ? a : b;
    }

     
     
     
    function ()  payable {
        require(isContract(controller));
        require(TokenController(controller).proxyPayment.value(msg.value)(msg.sender));
    }

 
 
 

     
     
     
     
    function claimTokens(address _token) onlyController {
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
    ) returns (MiniMeToken) {
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

contract MiniMeVestedToken is MiniMeToken {
  using SafeMath for uint256;
  using Math for uint64;

  struct TokenGrant {
    address granter;      
    uint256 value;        
    uint64 cliff;
    uint64 vesting;
    uint64 start;         
    bool revokable;
    bool burnsOnRevoke;   
  }  

  event NewTokenGrant(address indexed from, address indexed to, uint256 value, uint256 grantId);

  mapping (address => TokenGrant[]) public grants;

  mapping (address => bool) public canCreateGrants;
  address public vestingWhitelister;

  modifier canTransfer(address _sender, uint _value) {
    require(spendableBalanceOf(_sender) >= _value);
    _;
  }

  modifier onlyVestingWhitelister {
    require(msg.sender == vestingWhitelister);
    _;
  }

  function MiniMeVestedToken (
      address _tokenFactory,
      address _parentToken,
      uint _parentSnapShotBlock,
      string _tokenName,
      uint8 _decimalUnits,
      string _tokenSymbol,
      bool _transfersEnabled
  ) public
    MiniMeToken(_tokenFactory, _parentToken, _parentSnapShotBlock, _tokenName, _decimalUnits, _tokenSymbol, _transfersEnabled) {
    vestingWhitelister = msg.sender;
    doSetCanCreateGrants(vestingWhitelister, true);
  }

   
  function transfer(address _to, uint _value)
           public
           canTransfer(msg.sender, _value)
           returns (bool success) {
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint _value)
           public
           canTransfer(_from, _value)
           returns (bool success) {
    return super.transferFrom(_from, _to, _value);
  }

  function spendableBalanceOf(address _holder) public constant returns (uint) {
    return transferableTokens(_holder, uint64(now));  
  }

   
  function grantVestedTokens(
    address _to,
    uint256 _value,
    uint64 _start,
    uint64 _cliff,
    uint64 _vesting,
    bool _revokable,
    bool _burnsOnRevoke
  ) public {
     
    require(_cliff >= _start);
    require(_vesting >= _cliff);

    require(canCreateGrants[msg.sender]);
    require(tokenGrantsCount(_to) < 20);    

    TokenGrant memory grant = TokenGrant(
      _revokable ? msg.sender : 0,
      _value,
      _cliff,
      _vesting,
      _start,
      _revokable,
      _burnsOnRevoke
    );

    uint256 count = grants[_to].push(grant);

    assert(transfer(_to, _value));

    NewTokenGrant(msg.sender, _to, _value, count - 1);
  }

  function setCanCreateGrants(address _addr, bool _allowed)
           public onlyVestingWhitelister {
    doSetCanCreateGrants(_addr, _allowed);
  }

  function changeVestingWhitelister(address _newWhitelister) public onlyVestingWhitelister {
    require(_newWhitelister != 0);
    doSetCanCreateGrants(vestingWhitelister, false);
    vestingWhitelister = _newWhitelister;
    doSetCanCreateGrants(vestingWhitelister, true);
  }

   
  function revokeTokenGrant(address _holder, address _receiver, uint256 _grantId) public onlyVestingWhitelister {
    require(_receiver != 0);

    TokenGrant storage grant = grants[_holder][_grantId];

    require(grant.revokable);
    require(grant.granter == msg.sender);  

    address receiver = grant.burnsOnRevoke ? 0xdead : _receiver;

    uint256 nonVested = nonVestedTokens(grant, uint64(now));

     
    delete grants[_holder][_grantId];
    grants[_holder][_grantId] = grants[_holder][grants[_holder].length.sub(1)];
    grants[_holder].length -= 1;

    doTransfer(_holder, receiver, nonVested);
  }

   
  function tokenGrantsCount(address _holder) public constant returns (uint index) {
    return grants[_holder].length;
  }

   
  function tokenGrant(address _holder, uint256 _grantId) public constant returns (address granter, uint256 value, uint256 vested, uint64 start, uint64 cliff, uint64 vesting, bool revokable, bool burnsOnRevoke) {
    TokenGrant storage grant = grants[_holder][_grantId];

    granter = grant.granter;
    value = grant.value;
    start = grant.start;
    cliff = grant.cliff;
    vesting = grant.vesting;
    revokable = grant.revokable;
    burnsOnRevoke = grant.burnsOnRevoke;

    vested = vestedTokens(grant, uint64(now));
  }

   
   
  function lastTokenIsTransferableDate(address holder) public constant returns (uint64 date) {
    date = uint64(now);
    uint256 grantIndex = tokenGrantsCount(holder);
    for (uint256 i = 0; i < grantIndex; i++) {
      date = grants[holder][i].vesting.max64(date);
    }
    return date;
  }

   
  function transferableTokens(address holder, uint64 time) public constant returns (uint256) {
    uint256 grantIndex = tokenGrantsCount(holder);

    if (grantIndex == 0) return balanceOf(holder);  

     
    uint256 nonVested = 0;
    for (uint256 i = 0; i < grantIndex; i++) {
      nonVested = nonVested.add(nonVestedTokens(grants[holder][i], time));
    }

     
    return balanceOf(holder).sub(nonVested);
  }

  function doSetCanCreateGrants(address _addr, bool _allowed)
           internal {
    canCreateGrants[_addr] = _allowed;
  }

   
  function calculateVestedTokens(
    uint256 tokens,
    uint256 time,
    uint256 start,
    uint256 cliff,
    uint256 vesting) internal constant returns (uint256)
    {

     
    if (time < cliff) return 0;
    if (time >= vesting) return tokens;

     
     
     

     
    uint256 vested = tokens.mul(
                             time.sub(start)
                           ).div(vesting.sub(start));

    return vested;
  }

   
  function nonVestedTokens(TokenGrant storage grant, uint64 time) internal constant returns (uint256) {
     
     
    return grant.value.sub(vestedTokens(grant, time));
  }

   
  function vestedTokens(TokenGrant grant, uint64 time) private constant returns (uint256) {
    return calculateVestedTokens(
      grant.value,
      uint256(time),
      uint256(grant.start),
      uint256(grant.cliff),
      uint256(grant.vesting)
    );
  }
}

contract BLT is MiniMeVestedToken {
  function BLT(address _tokenFactory) public MiniMeVestedToken(
    _tokenFactory,
    0x0,            
    0,              
    "Bloom Token",  
    18,             
    "BLT",          
    true            
  ) {}  
}
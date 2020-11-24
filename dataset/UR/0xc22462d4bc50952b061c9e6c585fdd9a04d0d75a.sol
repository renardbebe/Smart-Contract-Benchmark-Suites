 

pragma solidity ^0.4.15;

contract TokenController {
     
     
     
    function proxyPayment(address _owner) payable returns(bool);

     
     
     
     
     
     
    function onTransfer(address _from, address _to, uint _amount) returns(bool);

     
     
     
     
     
     
    function onApprove(address _owner, address _spender, uint _amount)
        returns(bool);
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

contract CND is MiniMeToken {
   
  uint256 public constant IS_CND_CONTRACT_MAGIC_NUMBER = 0x1338;
  function CND(address _tokenFactory)
    MiniMeToken(
      _tokenFactory,
      0x0,                       
      0,                         
      "Cindicator Token",    
      18,                        
      "CND",                     
      true                       
    ) 
    {}

    function() payable {
      require(false);
    }
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

library SafeMath {
  function mul(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract Contribution is Controlled, TokenController {
  using SafeMath for uint256;

  struct WhitelistedInvestor {
    uint256 tier;
    bool status;
    uint256 contributedAmount;
  }

  mapping(address => WhitelistedInvestor) investors;
  Tier[4] public tiers;
  uint256 public tierCount;

  MiniMeToken public cnd;
  bool public transferable = false;
  uint256 public October12_2017 = 1507830400;
  address public contributionWallet;
  address public foundersWallet;
  address public advisorsWallet;
  address public bountyWallet;
  bool public finalAllocation;

  uint256 public totalTokensSold;

  bool public paused = false;

  modifier notAllocated() {
    require(finalAllocation == false);
    _;
  }

  modifier endedSale() {
    require(tierCount == 4);  
    _;
  }

  modifier tokenInitialized() {
    assert(address(cnd) != 0x0);
    _;
  }

  modifier initialized() {
    Tier tier = tiers[tierCount];
    assert(tier.initializedTime() != 0);
    _;
  }
   
   
  function contributionOpen() public constant returns(bool) {
    Tier tier = tiers[tierCount];
    return (getBlockTimestamp() >= tier.startTime() && 
           getBlockTimestamp() <= tier.endTime() &&
           tier.finalizedTime() == 0);
  }

  modifier notPaused() {
    require(!paused);
    _;
  }

  function Contribution(address _contributionWallet, address _foundersWallet, address _advisorsWallet, address _bountyWallet) {
    require(_contributionWallet != 0x0);
    require(_foundersWallet != 0x0);
    require(_advisorsWallet != 0x0);
    require(_bountyWallet != 0x0);
    contributionWallet = _contributionWallet;
    foundersWallet = _foundersWallet;
    advisorsWallet =_advisorsWallet;
    bountyWallet = _bountyWallet;
    tierCount = 0;
  }
   
   
  function initializeToken(address _cnd) public onlyController {
    assert(CND(_cnd).controller() == address(this));
    assert(CND(_cnd).IS_CND_CONTRACT_MAGIC_NUMBER() == 0x1338);
    require(_cnd != 0x0);
    cnd = CND(_cnd);
  }
   
   
   
  function initializeTier(
    uint256 _tierNumber,
    address _tierAddress
  ) public onlyController tokenInitialized
  {
    Tier tier = Tier(_tierAddress);
    assert(tier.controller() == address(this));
     
    require(_tierNumber >= 0 && _tierNumber <= 3);
    assert(tier.IS_TIER_CONTRACT_MAGIC_NUMBER() == 0x1337);
     
    assert(tiers[_tierNumber] == address(0));
    tiers[_tierNumber] = tier;
    InitializedTier(_tierNumber, _tierAddress);
  }

   
   
  function () public {
    require(false);
  }
   
   
   
  function investorAmountTokensToBuy(address _investor) public constant returns(uint256) {
    WhitelistedInvestor memory investor = investors[_investor];
    Tier tier = tiers[tierCount];
    uint256 leftToBuy = tier.maxInvestorCap().sub(investor.contributedAmount).mul(tier.exchangeRate());
    return leftToBuy;
  }
   
   
   
   
  function isWhitelisted(address _investor, uint256 _tier) public constant returns(bool) {
    WhitelistedInvestor memory investor = investors[_investor];
    return (investor.tier <= _tier && investor.status);
  }
   
   
   
   
  function whitelistAddresses(address[] _addresses, uint256 _tier, bool _status) public onlyController {
    for (uint256 i = 0; i < _addresses.length; i++) {
        address investorAddress = _addresses[i];
        require(investors[investorAddress].contributedAmount == 0);
        investors[investorAddress] = WhitelistedInvestor(_tier, _status, 0);
    }
   }
   
   function buy() public payable {
     proxyPayment(msg.sender);
   }
   
   
  function proxyPayment(address) public payable 
    notPaused
    initialized
    returns (bool) 
  {
    assert(isCurrentTierCapReached() == false);
    assert(contributionOpen());
    require(isWhitelisted(msg.sender, tierCount));
    doBuy();
    return true;
  }

   
   
   
  function onTransfer(address  , address  , uint256  ) returns(bool) {
    return (transferable || getBlockTimestamp() >= October12_2017 );
  } 

   
   
   
  function onApprove(address  , address  , uint  ) returns(bool) {
    return (transferable || getBlockTimestamp() >= October12_2017);
  }
   
   
  function allowTransfers(bool _transferable) onlyController {
    transferable = _transferable;
  }
   
   
  function leftForSale() public constant returns(uint256) {
    Tier tier = tiers[tierCount];
    uint256 weiLeft = tier.cap().sub(tier.totalInvestedWei());
    uint256 tokensLeft = weiLeft.mul(tier.exchangeRate());
    return tokensLeft;
  }
   
  function doBuy() internal {
    Tier tier = tiers[tierCount];
    assert(msg.value <= tier.maxInvestorCap());
    address caller = msg.sender;
    WhitelistedInvestor storage investor = investors[caller];
    uint256 investorTokenBP = investorAmountTokensToBuy(caller);
    require(investorTokenBP > 0);

    if(investor.contributedAmount == 0) {
      assert(msg.value >= tier.minInvestorCap());  
    }

    uint256 toFund = msg.value;  
    uint256 tokensGenerated = toFund.mul(tier.exchangeRate());
     
    require(tokensGenerated >= 1);
    uint256 tokensleftForSale = leftForSale();    

    if(tokensleftForSale > investorTokenBP ) {
      if(tokensGenerated > investorTokenBP) {
        tokensGenerated = investorTokenBP;
        toFund = investorTokenBP.div(tier.exchangeRate());
      }
    }

    if(investorTokenBP > tokensleftForSale) {
      if(tokensGenerated > tokensleftForSale) {
        tokensGenerated = tokensleftForSale;
        toFund = tokensleftForSale.div(tier.exchangeRate());
      }
    }

    investor.contributedAmount = investor.contributedAmount.add(toFund);
    tier.increaseInvestedWei(toFund);
    if (tokensGenerated == tokensleftForSale) {
      finalize();
    }
    
    assert(cnd.generateTokens(caller, tokensGenerated));
    totalTokensSold = totalTokensSold.add(tokensGenerated);

    contributionWallet.transfer(toFund);

    NewSale(caller, toFund, tokensGenerated);

    uint256 toReturn = msg.value.sub(toFund);
    if (toReturn > 0) {
      caller.transfer(toReturn);
      Refund(toReturn);
    }
  }
   
   
  function allocate() public notAllocated endedSale returns(bool) {
    finalAllocation = true;
    uint256 totalSupplyCDN = totalTokensSold.mul(100).div(75);  
    uint256 foundersAllocation = totalSupplyCDN.div(5);  
    assert(cnd.generateTokens(foundersWallet, foundersAllocation));
    
    uint256 advisorsAllocation = totalSupplyCDN.mul(38).div(1000);  
    assert(cnd.generateTokens(advisorsWallet, advisorsAllocation));
    uint256 bountyAllocation = totalSupplyCDN.mul(12).div(1000);  
    assert(cnd.generateTokens(bountyWallet, bountyAllocation));
    return true;
  }

   
   
  function finalize() public initialized {
    Tier tier = tiers[tierCount];
    assert(tier.finalizedTime() == 0);
    assert(getBlockTimestamp() >= tier.startTime());
    assert(msg.sender == controller || getBlockTimestamp() > tier.endTime() || isCurrentTierCapReached());

    tier.finalize();
    tierCount++;

    FinalizedTier(tierCount, tier.finalizedTime());
  }
   
   
  function isCurrentTierCapReached() public constant returns(bool) {
    Tier tier = tiers[tierCount];
    return tier.isCapReached();
  }

   
   
   

  function getBlockTimestamp() internal constant returns (uint256) {
    return block.timestamp;
  }



   
   
   

   
   
   
   
  function claimTokens(address _token) public onlyController {
    if (cnd.controller() == address(this)) {
      cnd.claimTokens(_token);
    }

    if (_token == 0x0) {
      controller.transfer(this.balance);
      return;
    }

    CND token = CND(_token);
    uint256 balance = token.balanceOf(this);
    token.transfer(controller, balance);
    ClaimedTokens(_token, controller, balance);
  }

   
  function pauseContribution(bool _paused) onlyController {
    paused = _paused;
  }

  event ClaimedTokens(address indexed _token, address indexed _controller, uint256 _amount);
  event NewSale(address indexed _th, uint256 _amount, uint256 _tokens);
  event InitializedTier(uint256 _tierNumber, address _tierAddress);
  event FinalizedTier(uint256 _tierCount, uint256 _now);
  event Refund(uint256 _amount);
  
}

contract Tier is Controlled {
  using SafeMath for uint256;
  uint256 public cap;
  uint256 public exchangeRate;
  uint256 public minInvestorCap;
  uint256 public maxInvestorCap;
  uint256 public startTime;
  uint256 public endTime;
  uint256 public initializedTime;
  uint256 public finalizedTime;
  uint256 public totalInvestedWei;
  uint256 public constant IS_TIER_CONTRACT_MAGIC_NUMBER = 0x1337;

  modifier notFinished() {
    require(finalizedTime == 0);
    _;
  }

  function Tier(
    uint256 _cap,
    uint256 _minInvestorCap,
    uint256 _maxInvestorCap,
    uint256 _exchangeRate,
    uint256 _startTime,
    uint256 _endTime
  )
  {
    require(initializedTime == 0);
    assert(_startTime >= getBlockTimestamp());
    require(_startTime < _endTime);
    startTime = _startTime;
    endTime = _endTime;

    require(_cap > 0);
    require(_cap > _maxInvestorCap);
    cap = _cap;

    require(_minInvestorCap < _maxInvestorCap && _maxInvestorCap > 0);
    minInvestorCap = _minInvestorCap;
    maxInvestorCap = _maxInvestorCap;

    require(_exchangeRate > 0);
    exchangeRate = _exchangeRate;

    initializedTime = getBlockTimestamp();
    InitializedTier(_cap, _minInvestorCap, maxInvestorCap, _startTime, _endTime);
  }

  function getBlockTimestamp() internal constant returns (uint256) {
    return block.timestamp;
  }

  function isCapReached() public constant returns(bool) {
    return totalInvestedWei == cap;
  }

  function finalize() public onlyController {
    require(finalizedTime == 0);
    uint256 currentTime = getBlockTimestamp();
    assert(cap == totalInvestedWei || currentTime > endTime || msg.sender == controller);
    finalizedTime = currentTime;
  }

  function increaseInvestedWei(uint256 _wei) external onlyController notFinished {
    totalInvestedWei = totalInvestedWei.add(_wei);
    IncreaseInvestedWeiAmount(_wei, totalInvestedWei);
  }

  event InitializedTier(
   uint256 _cap,
   uint256 _minInvestorCap, 
   uint256 _maxInvestorCap, 
   uint256 _startTime,
   uint256 _endTime
  );

  function () public {
    require(false);
  }
  event IncreaseInvestedWeiAmount(uint256 _amount, uint256 _newWei);
}
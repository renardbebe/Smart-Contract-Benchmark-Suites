 

pragma solidity ^0.4.17;


 
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

 
contract ERC20 {
    function balanceOf(address who) public constant returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function allowance(address owner, address spender) public constant returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}







contract Controlled {
     
     
    modifier onlyController { require(msg.sender == controller); _; }

    address public controller;

    function Controlled() public { controller = msg.sender;}

     
     
    function changeController(address _newController) public onlyController {
        controller = _newController;
    }
}

 
contract ERC20MiniMe is ERC20, Controlled {
    function approveAndCall(address _spender, uint256 _amount, bytes _extraData) public returns (bool);
    function totalSupply() public constant returns (uint);
    function balanceOfAt(address _owner, uint _blockNumber) public constant returns (uint);
    function totalSupplyAt(uint _blockNumber) public constant returns(uint);
    function createCloneToken(string _cloneTokenName, uint8 _cloneDecimalUnits, string _cloneTokenSymbol, uint _snapshotBlock, bool _transfersEnabled) public returns(address);
    function generateTokens(address _owner, uint _amount) public returns (bool);
    function destroyTokens(address _owner, uint _amount)  public returns (bool);
    function enableTransfers(bool _transfersEnabled) public;
    function isContract(address _addr) constant internal returns(bool);
    function claimTokens(address _token) public;
    event ClaimedTokens(address indexed _token, address indexed _controller, uint _amount);
    event NewCloneToken(address indexed _cloneToken, uint _snapshotBlock);
}








 
contract Crowdsale {
  using SafeMath for uint256;

   
  ERC20MiniMe public token;

   
  uint256 public startTime;
  uint256 public endTime;

   
  address public wallet;

   
  uint256 public rate;

   
  uint256 public weiRaised;

   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);


  function Crowdsale(uint256 _startTime, uint256 _endTime, uint256 _rate, address _wallet) {
    require(_startTime >= now);
    require(_endTime >= _startTime);
    require(_rate > 0);
    require(_wallet != 0x0);

    startTime = _startTime;
    endTime = _endTime;
    rate = _rate;
    wallet = _wallet;
  }


   
  function () payable {
    buyTokens(msg.sender);
  }

   
  function buyTokens(address beneficiary) public payable {
    buyTokens(beneficiary, msg.value);
  }

   
  function buyTokens(address beneficiary, uint256 weiAmount) internal {
    require(beneficiary != 0x0);
    require(validPurchase(weiAmount));

    transferToken(beneficiary, weiAmount);

     
    weiRaised = weiRaised.add(weiAmount);

    forwardFunds(weiAmount);
  }

   
   
  function transferToken(address beneficiary, uint256 weiAmount) internal {
     
    uint256 tokens = weiAmount.mul(rate);

    token.generateTokens(beneficiary, tokens);

    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);
  }

   
   
  function forwardFunds(uint256 weiAmount) internal {
    wallet.transfer(weiAmount);
  }

   
  function validPurchase(uint256 weiAmount) internal constant returns (bool) {
    bool withinPeriod = now >= startTime && now <= endTime;
    bool nonZeroPurchase = weiAmount != 0;
    return withinPeriod && nonZeroPurchase;
  }

   
  function hasEnded() public constant returns (bool) {
    return now > endTime;
  }

   
  function hasStarted() public constant returns (bool) {
    return now >= startTime;
  }
}

 
contract CappedCrowdsale is Crowdsale {
  using SafeMath for uint256;

  uint256 public cap;

  function CappedCrowdsale(uint256 _cap) {
    require(_cap > 0);
    cap = _cap;
  }

   
   
  function validPurchase(uint256 weiAmount) internal constant returns (bool) {
    return super.validPurchase(weiAmount) && !capReached();
  }

   
   
  function hasEnded() public constant returns (bool) {
    return super.hasEnded() || capReached();
  }

   
  function capReached() internal constant returns (bool) {
   return weiRaised >= cap;
  }

   
  function buyTokens(address beneficiary) public payable {
     uint256 weiToCap = cap.sub(weiRaised);
     uint256 weiAmount = weiToCap < msg.value ? weiToCap : msg.value;

     buyTokens(beneficiary, weiAmount);

     uint256 refund = msg.value.sub(weiAmount);
     if (refund > 0) {
       msg.sender.transfer(refund);
     }
   }
}




 
contract TokenController {
    ERC20MiniMe public ethealToken;
    address public SALE;  

     
    function addHodlerStake(address _beneficiary, uint256 _stake) public;
    function setHodlerStake(address _beneficiary, uint256 _stake) public;
    function setHodlerTime(uint256 _time) public;


     
     
     
    function proxyPayment(address _owner) public payable returns(bool);

     
     
     
     
     
     
    function onTransfer(address _from, address _to, uint _amount) public returns(bool);

     
     
     
     
     
     
    function onApprove(address _owner, address _spender, uint _amount) public returns(bool);
}






 
contract FinalizableCrowdsale is Crowdsale, Ownable {
  using SafeMath for uint256;

  bool public isFinalized = false;

  event Finalized();

   
  function finalize() onlyOwner public {
    require(!isFinalized);
    require(hasEnded());

    finalization();
    Finalized();

    isFinalized = true;
  }

   
  function finalization() internal {
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






 

library ECRecovery {

   
  function recover(bytes32 hash, bytes sig) public pure returns (address) {
    bytes32 r;
    bytes32 s;
    uint8 v;

     
    if (sig.length != 65) {
      return (address(0));
    }

     
    assembly {
      r := mload(add(sig, 32))
      s := mload(add(sig, 64))
      v := byte(0, mload(add(sig, 96)))
    }

     
    if (v < 27) {
      v += 27;
    }

     
    if (v != 27 && v != 28) {
      return (address(0));
    } else {
      return ecrecover(hash, v, r, s);
    }
  }

}

 
contract EthealWhitelist is Ownable {
    using ECRecovery for bytes32;

     
    address public signer;

     
    mapping(address => bool) public isWhitelisted;

    event WhitelistSet(address indexed _address, bool _state);

     
     
     
    function EthealWhitelist(address _signer) {
        require(_signer != address(0));

        signer = _signer;
    }

     
    function setSigner(address _signer) public onlyOwner {
        require(_signer != address(0));

        signer = _signer;
    }

     
     
     

     
    function setWhitelist(address _addr, bool _state) public onlyOwner {
        require(_addr != address(0));
        isWhitelisted[_addr] = _state;
        WhitelistSet(_addr, _state);
    }

     
    function setManyWhitelist(address[] _addr, bool _state) public onlyOwner {
        for (uint256 i = 0; i < _addr.length; i++) {
            setWhitelist(_addr[i], _state);
        }
    }

     
    function isOffchainWhitelisted(address _addr, bytes _sig) public view returns (bool) {
        bytes32 hash = keccak256("\x19Ethereum Signed Message:\n20",_addr);
        return hash.recover(_sig) == signer;
    }
}

 
contract EthealNormalSale is Pausable, FinalizableCrowdsale, CappedCrowdsale {
     
    TokenController public ethealController;

     
     
    uint256 public rate = 700;
    uint256 public softCap = 6800 ether;
    uint256 public softCapTime = 120 hours;
    uint256 public softCapClose;
    uint256 public cap = 14300 ether;

     
    uint256 public tokenBalance;

     
    uint256 public tokenSold;

     
    uint256 public minContribution = 0.1 ether;

     
    EthealWhitelist public whitelist;
    uint256 public whitelistThreshold = 1 ether;

     
    address public deposit;
    
     
    mapping (address => uint256) public stakes;
    mapping (address => uint256) public contributions;

     
    address public promoTokenController;
    mapping (address => uint256) public bonusExtra;

     
    address[] public contributorsKeys; 

     
    event LogTokenClaimed(address indexed _claimer, address indexed _beneficiary, uint256 _amount);
    event LogTokenPurchase(address indexed _purchaser, address indexed _beneficiary, uint256 _value, uint256 _amount, uint256 _participants, uint256 _weiRaised);
    event LogTokenSoftCapReached(uint256 _closeTime);
    event LogTokenHardCapReached();

     
     
     

     
     
     
     
     
     
     
     
     
     
    function EthealNormalSale(
        address _ethealController,
        uint256 _startTime, 
        uint256 _endTime, 
        uint256 _minContribution, 
        uint256 _rate, 
        uint256 _softCap, 
        uint256 _softCapTime, 
        uint256 _cap, 
        address _wallet
    )
        CappedCrowdsale(_cap)
        FinalizableCrowdsale()
        Crowdsale(_startTime, _endTime, _rate, _wallet)
    {
         
        require(_ethealController != address(0));
        ethealController = TokenController(_ethealController);

         
        require(_softCap <= _cap);
        softCap = _softCap;
        softCapTime = _softCapTime;

         
        cap = _cap;
        rate = _rate;

        minContribution = _minContribution;
    }

     
     
     

     
    function setMinContribution(uint256 _minContribution) public onlyOwner {
        minContribution = _minContribution;
    }

     
    function setCaps(uint256 _softCap, uint256 _softCapTime, uint256 _cap) public onlyOwner {
        require(_softCap <= _cap);
        softCap = _softCap;
        softCapTime = _softCapTime;
        cap = _cap;
    }

     
    function setTimes(uint256 _startTime, uint256 _endTime) public onlyOwner {
        require(_startTime <= _endTime);
        require(!hasEnded());
        startTime = _startTime;
        endTime = _endTime;
    }

     
    function setRate(uint256 _rate) public onlyOwner {
        require(_rate > 0);
        rate = _rate;
    }

     
    function setPromoTokenController(address _addr) public onlyOwner {
        require(_addr != address(0));
        promoTokenController = _addr;
    }

     
    function setWhitelist(address _whitelist, uint256 _threshold) public onlyOwner {
         
        if (_whitelist != address(0)) {
            whitelist = EthealWhitelist(_whitelist);
        }
        whitelistThreshold = _threshold;
    }

     
    function setDeposit(address _deposit) public onlyOwner {
        deposit = _deposit;
    }

     
    function moveTokens(address _to, uint256 _amount) public onlyOwner {
        require(_to != address(0));
        require(_amount <= getHealBalance().sub(tokenBalance));
        require(ethealController.ethealToken().transfer(_to, _amount));
    }

     
     
     

     
     
    function buyTokens(address _beneficiary) public payable whenNotPaused {
        handlePayment(_beneficiary, msg.value, now, "");
    }

     
    function buyTokensSigned(address _beneficiary, bytes _whitelistSign) public payable whenNotPaused {
        handlePayment(_beneficiary, msg.value, now, _whitelistSign);
    }

     
    function handlePayment(address _beneficiary, uint256 _amount, uint256 _time, bytes memory _whitelistSign) internal {
        require(_beneficiary != address(0));

        uint256 weiAmount = handleContribution(_beneficiary, _amount, _time, _whitelistSign);      
        forwardFunds(weiAmount);  

         
        uint256 refund = _amount.sub(weiAmount);
        if (refund > 0) {
            _beneficiary.transfer(refund);
        }
    }

     
     
    function handleContribution(address _beneficiary, uint256 _amount, uint256 _time, bytes memory _whitelistSign) internal returns (uint256) {
        require(_beneficiary != address(0));

        uint256 weiToCap = howMuchCanXContributeNow(_beneficiary);
        uint256 weiAmount = uint256Min(weiToCap, _amount);

         
        transferToken(_beneficiary, weiAmount, _time, _whitelistSign);

         
        if (weiRaised >= softCap && softCapClose == 0) {
            softCapClose = now.add(softCapTime);
            LogTokenSoftCapReached(uint256Min(softCapClose, endTime));
        }

         
        if (weiRaised >= cap) {
            LogTokenHardCapReached();
        }

        return weiAmount;
    }

     
     
     
     
    function transferToken(address _beneficiary, uint256 _weiAmount, uint256 _time, bytes memory _whitelistSign) internal {
        require(_beneficiary != address(0));
        require(validPurchase(_weiAmount));

         
        weiRaised = weiRaised.add(_weiAmount);

         
        contributions[_beneficiary] = contributions[_beneficiary].add(_weiAmount);
        require(contributions[_beneficiary] <= whitelistThreshold 
                || whitelist.isWhitelisted(_beneficiary)
                || whitelist.isOffchainWhitelisted(_beneficiary, _whitelistSign)
        );

         
        uint256 _bonus = getBonus(_beneficiary, _weiAmount, _time);
        uint256 tokens = _weiAmount.mul(rate).mul(_bonus).div(100);
        tokenBalance = tokenBalance.add(tokens);

        if (stakes[_beneficiary] == 0) {
            contributorsKeys.push(_beneficiary);
        }
        stakes[_beneficiary] = stakes[_beneficiary].add(tokens);

        LogTokenPurchase(msg.sender, _beneficiary, _weiAmount, tokens, contributorsKeys.length, weiRaised);
    }

     
    function depositEth(address _beneficiary, uint256 _time, bytes _whitelistSign) public payable whenNotPaused {
        require(msg.sender == deposit);

        handlePayment(_beneficiary, msg.value, _time, _whitelistSign);
    }

     
    function depositOffchain(address _beneficiary, uint256 _amount, uint256 _time, bytes _whitelistSign) public onlyOwner whenNotPaused {
        handleContribution(_beneficiary, _amount, _time, _whitelistSign);
    }

     
     
     
    function validPurchase(uint256 _weiAmount) internal constant returns (bool) {
        bool nonEnded = !hasEnded();
        bool nonZero = _weiAmount != 0;
        bool enoughContribution = _weiAmount >= minContribution;
        return nonEnded && nonZero && enoughContribution;
    }

     
     
    function hasEnded() public constant returns (bool) {
        return super.hasEnded() || softCapClose > 0 && now > softCapClose;
    }

     
    function finalization() internal {
        uint256 _balance = getHealBalance();

         
        tokenSold = tokenBalance; 

         
        if (_balance > tokenBalance) {
            ethealController.ethealToken().transfer(ethealController.SALE(), _balance.sub(tokenBalance));
        }

         
        ethealController.setHodlerTime(now + 14 days);

        super.finalization();
    }


     
     
     

     
    modifier afterSale() {
        require(isFinalized);
        _;
    }

     
    function claimToken() public afterSale {
        claimTokenFor(msg.sender);
    }

     
     
     
    function claimTokenFor(address _beneficiary) public afterSale whenNotPaused {
        uint256 tokens = stakes[_beneficiary];
        require(tokens > 0);

         
        stakes[_beneficiary] = 0;

         
        tokenBalance = tokenBalance.sub(tokens);

         
        ethealController.addHodlerStake(_beneficiary, tokens);

         
        require(ethealController.ethealToken().transfer(_beneficiary, tokens));
        LogTokenClaimed(msg.sender, _beneficiary, tokens);
    }

     
     
     
    function claimManyTokenFor(address[] _beneficiaries) external afterSale {
        for (uint256 i = 0; i < _beneficiaries.length; i++) {
            claimTokenFor(_beneficiaries[i]);
        }
    }


     
     
     

     
     
     
     
    function setPromoBonus(address _addr, uint256 _value) public {
        require(msg.sender == promoTokenController || msg.sender == owner);
        require(_value>0);

        uint256 _bonus = keccak256(_value) == 0xbeced09521047d05b8960b7e7bcc1d1292cf3e4b2a6b63f48335cbde5f7545d2 ? 6 : 5;

        if (bonusExtra[ _addr ] < _bonus) {
            bonusExtra[ _addr ] = _bonus;
        }
    }

     
    function setBonusExtra(address _addr, uint256 _bonus) public onlyOwner {
        require(_addr != address(0));
        bonusExtra[_addr] = _bonus;
    }

     
    function setManyBonusExtra(address[] _addr, uint256 _bonus) external onlyOwner {
        for (uint256 i = 0; i < _addr.length; i++) {
            setBonusExtra(_addr[i],_bonus);
        }
    }

     
    function getBonusNow(address _addr, uint256 _size) public view returns (uint256) {
        return getBonus(_addr, _size, now);
    }

     
    function getBonus(address _addr, uint256 _size, uint256 _time) public view returns (uint256 _bonus) {
         
        _bonus = 100;
        
         
        uint256 _day = getSaleDay(_time);
        uint256 _hour = getSaleHour(_time);
        if (_day <= 1) {
            if (_hour <= 1) _bonus = 130;
            else if (_hour <= 5) _bonus = 125;
            else if (_hour <= 8) _bonus = 120;
            else _bonus = 118;
        } 
        else if (_day <= 2) { _bonus = 116; }
        else if (_day <= 3) { _bonus = 115; }
        else if (_day <= 5) { _bonus = 114; }
        else if (_day <= 7) { _bonus = 113; }
        else if (_day <= 9) { _bonus = 112; }
        else if (_day <= 11) { _bonus = 111; }
        else if (_day <= 13) { _bonus = 110; }
        else if (_day <= 15) { _bonus = 108; }
        else if (_day <= 17) { _bonus = 107; }
        else if (_day <= 19) { _bonus = 106; }
        else if (_day <= 21) { _bonus = 105; }
        else if (_day <= 23) { _bonus = 104; }
        else if (_day <= 25) { _bonus = 103; }
        else if (_day <= 27) { _bonus = 102; }

         
        if (_size >= 100 ether) { _bonus = _bonus + 4; }
        else if (_size >= 10 ether) { _bonus = _bonus + 2; }

         
        _bonus += bonusExtra[ _addr ];

        return _bonus;
    }


     
     
     

     
    function howMuchCanIContributeNow() view public returns (uint256) {
        return howMuchCanXContributeNow(msg.sender);
    }

     
     
     
    function howMuchCanXContributeNow(address _beneficiary) view public returns (uint256) {
        require(_beneficiary != address(0));

        if (hasEnded() || paused) 
            return 0;

         
        uint256 weiToCap = cap.sub(weiRaised);

        return weiToCap;
    }

     
     
     
     
    function getSaleDay(uint256 _time) view public returns (uint256) {
        uint256 _day = 0;
        if (_time > startTime) {
            _day = _time.sub(startTime).div(60*60*24).add(1);
        }
        return _day;
    }

     
     
    function getSaleDayNow() view public returns (uint256) {
        return getSaleDay(now);
    }

     
     
     
    function getSaleHour(uint256 _time) view public returns (uint256) {
        uint256 _hour = 0;
        if (_time > startTime) {
            _hour = _time.sub(startTime).div(60*60).add(1);
        }
        return _hour;
    }

     
     
    function getSaleHourNow() view public returns (uint256) {
        return getSaleHour(now);
    }

     
    function uint256Min(uint256 a, uint256 b) pure internal returns (uint256) {
        return a > b ? b : a;
    }


     
     
     

     
     
    function getContributorsCount() view public returns (uint256) {
        return contributorsKeys.length;
    }

     
     
     
     
     
     
    function getContributors(bool _pending, bool _claimed) view public returns (address[] contributors) {
        uint256 i = 0;
        uint256 results = 0;
        address[] memory _contributors = new address[](contributorsKeys.length);

         
        for (i = 0; i < contributorsKeys.length; i++) {
            if (_pending && stakes[contributorsKeys[i]] > 0 || _claimed && stakes[contributorsKeys[i]] == 0) {
                _contributors[results] = contributorsKeys[i];
                results++;
            }
        }

        contributors = new address[](results);
        for (i = 0; i < results; i++) {
            contributors[i] = _contributors[i];
        }

        return contributors;
    }

     
    function getHealBalance() view public returns (uint256) {
        return ethealController.ethealToken().balanceOf(address(this));
    }

     
    function getNow() view public returns (uint256) {
        return now;
    }
}
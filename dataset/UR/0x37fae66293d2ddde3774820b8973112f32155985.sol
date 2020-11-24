 

pragma solidity ^0.4.24;

 

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 

 
contract ERC20 is ERC20Basic {
  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  function approve(address _spender, uint256 _value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

 

 
library SafeMath {

   
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
     
     
     
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

   
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
     
     
     
    return _a / _b;
  }

   
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

   
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
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

 

 
library SafeERC20 {
  function safeTransfer(
    ERC20Basic _token,
    address _to,
    uint256 _value
  )
    internal
  {
    require(_token.transfer(_to, _value));
  }

  function safeTransferFrom(
    ERC20 _token,
    address _from,
    address _to,
    uint256 _value
  )
    internal
  {
    require(_token.transferFrom(_from, _to, _value));
  }

  function safeApprove(
    ERC20 _token,
    address _spender,
    uint256 _value
  )
    internal
  {
    require(_token.approve(_spender, _value));
  }
}

 

 
contract Crowdsale {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

     
    ERC20 public token;

     
    address public wallet;

     
     
     
     
    uint256 public rate;

     
    uint256 public weiRaised;

     
    uint256 public tokensSold;
    
     
    event TokenPurchase(
        address indexed purchaser,
        address indexed beneficiary,
        uint256 value,
        uint256 amount
    );

     
    constructor(uint256 _rate, address _wallet, ERC20 _token) public {
        require(_rate > 0);
        require(_wallet != address(0));
        require(_token != address(0));

        rate = _rate;
        wallet = _wallet;
        token = _token;
    }

     
     
     

     
    function () external payable {
        buyTokens(msg.sender);
    }

     
    function buyTokens(address _beneficiary) public payable {

        uint256 weiAmount = msg.value;

         
        uint256 tokens = _getTokenAmount(weiAmount);

        _preValidatePurchase(_beneficiary, weiAmount, tokens);

         
        weiRaised = weiRaised.add(weiAmount);
        tokensSold = tokensSold.add(tokens);

        _processPurchase(_beneficiary, tokens);
        emit TokenPurchase(
            msg.sender,
            _beneficiary,
            weiAmount,
            tokens
        );

        _updatePurchasingState(_beneficiary, weiAmount, tokens);

        _forwardFunds();
        _postValidatePurchase(_beneficiary, weiAmount, tokens);
    }

     
     
     

     
    function _preValidatePurchase(
        address _beneficiary,
        uint256 _weiAmount,
        uint256 _tokenAmount
    )
        internal
    {
        require(_beneficiary != address(0));
        require(_weiAmount != 0);
    }

     
    function _postValidatePurchase(
        address _beneficiary,
        uint256 _weiAmount,
        uint256 _tokenAmount
    )
        internal
    {
         
    }

     
    function _deliverTokens(
        address _beneficiary,
        uint256 _tokenAmount
    )
        internal
    {
        token.safeTransfer(_beneficiary, _tokenAmount);
    }

     
    function _processPurchase(
        address _beneficiary,
        uint256 _tokenAmount
    )
        internal
    {
        _deliverTokens(_beneficiary, _tokenAmount);
    }

     
    function _updatePurchasingState(
        address _beneficiary,
        uint256 _weiAmount,
        uint256 _tokenAmount
    )
        internal
    {
         
    }

     
    function _getTokenAmount(uint256 _weiAmount)
        internal view returns (uint256)
    {
        return _weiAmount.mul(rate);
    }

     
    function _forwardFunds() internal {
        wallet.transfer(msg.value);
    }
}

 

 
contract TimedCrowdsale is Crowdsale {
    using SafeMath for uint256;

    uint256 public openingTime;
    uint256 public closingTime;

     
    modifier onlyWhileOpen {
         
        require(block.timestamp >= openingTime && block.timestamp <= closingTime);
        _;
    }

     
    constructor(uint256 _openingTime, uint256 _closingTime) public {
         
        require(_openingTime >= block.timestamp);
        require(_closingTime > _openingTime);

        openingTime = _openingTime;
        closingTime = _closingTime;
    }

     
    function hasClosed() public view returns (bool) {
         
        return block.timestamp > closingTime;
    }

     
    function _preValidatePurchase(
        address _beneficiary,
        uint256 _weiAmount,
        uint256 _tokenAmount
    )
        internal
        onlyWhileOpen
    {
        super._preValidatePurchase(_beneficiary, _weiAmount, _tokenAmount);
    }

}

 

 
contract MilestoneCrowdsale is TimedCrowdsale {
    using SafeMath for uint256;

    uint256 public constant MAX_MILESTONE = 10;

     
    struct Milestone {

         
        uint256 index;

         
        uint256 startTime;

         
        uint256 tokensSold;

         
        uint256 cap;

         
        uint256 rate;

    }

     
    Milestone[10] public milestones;

     
    uint256 public milestoneCount = 0;


    bool public milestoningFinished = false;

    constructor(        
        uint256 _openingTime,
        uint256 _closingTime
        ) 
        TimedCrowdsale(_openingTime, _closingTime)
        public 
        {
        }

     
    function setMilestonesList(uint256[] _milestoneStartTime, uint256[] _milestoneCap, uint256[] _milestoneRate) public {
         
        require(!milestoningFinished);
        require(_milestoneStartTime.length > 0);
        require(_milestoneStartTime.length == _milestoneCap.length && _milestoneCap.length == _milestoneRate.length);
        require(_milestoneStartTime[0] == openingTime);
        require(_milestoneStartTime[_milestoneStartTime.length-1] < closingTime);

        for (uint iterator = 0; iterator < _milestoneStartTime.length; iterator++) {
            if (iterator > 0) {
                assert(_milestoneStartTime[iterator] > milestones[iterator-1].startTime);
            }
            milestones[iterator] = Milestone({
                index: iterator,
                startTime: _milestoneStartTime[iterator],
                tokensSold: 0,
                cap: _milestoneCap[iterator],
                rate: _milestoneRate[iterator]
            });
            milestoneCount++;
        }
        milestoningFinished = true;
    }

     
    function getMilestoneTimeAndRate(uint256 n) public view returns (uint256, uint256) {
        return (milestones[n].startTime, milestones[n].rate);
    }

     
    function capReached(uint256 n) public view returns (bool) {
        return milestones[n].tokensSold >= milestones[n].cap;
    }

     
    function getTokensSold(uint256 n) public view returns (uint256) {
        return milestones[n].tokensSold;
    }

    function getFirstMilestone() private view returns (Milestone) {
        return milestones[0];
    }

    function getLastMilestone() private view returns (Milestone) {
        return milestones[milestoneCount-1];
    }

    function getFirstMilestoneStartsAt() public view returns (uint256) {
        return getFirstMilestone().startTime;
    }

    function getLastMilestoneStartsAt() public view returns (uint256) {
        return getLastMilestone().startTime;
    }

     
    function getCurrentMilestoneIndex() internal view onlyWhileOpen returns  (uint256) {
        uint256 index;

         
         
         
        for(uint i = 0; i < milestoneCount; i++) {
            index = i;
             
            if(block.timestamp < milestones[i].startTime) {
                index = i - 1;
                break;
            }
        }

         
         
         
        if (milestones[index].tokensSold > milestones[index].cap) {
            index = index + 1;
        }

        return index;
    }

     
    function _preValidatePurchase(
        address _beneficiary,
        uint256 _weiAmount,
        uint256 _tokenAmount
    )
        internal
    {
        super._preValidatePurchase(_beneficiary, _weiAmount, _tokenAmount);
        require(milestones[getCurrentMilestoneIndex()].tokensSold.add(_tokenAmount) <= milestones[getCurrentMilestoneIndex()].cap);
    }

     
    function _updatePurchasingState(
        address _beneficiary,
        uint256 _weiAmount,
        uint256 _tokenAmount
    )
        internal
    {
        super._updatePurchasingState(_beneficiary, _weiAmount, _tokenAmount);
        milestones[getCurrentMilestoneIndex()].tokensSold = milestones[getCurrentMilestoneIndex()].tokensSold.add(_tokenAmount);
    }

     
    function getCurrentRate() internal view returns (uint result) {
        return milestones[getCurrentMilestoneIndex()].rate;
    }

     
    function _getTokenAmount(uint256 _weiAmount)
        internal view returns (uint256)
    {
        return _weiAmount.mul(getCurrentRate());
    }

}

 

 
contract USDPrice is Ownable {

    using SafeMath for uint256;

     
     
    uint256 public ETHUSD;

     
    uint256 public updatedTime;

     
    mapping (uint256 => uint256) public priceHistory;

    event PriceUpdated(uint256 price);

    constructor() public {
    }

    function getHistoricPrice(uint256 time) public view returns (uint256) {
        return priceHistory[time];
    } 

    function updatePrice(uint256 price) public onlyOwner {
        require(price > 0);

        priceHistory[updatedTime] = ETHUSD;

        ETHUSD = price;
         
        updatedTime = block.timestamp;

        emit PriceUpdated(ETHUSD);
    }

     
    function getPrice(uint256 _weiAmount)
        public view returns (uint256)
    {
        return _weiAmount.mul(ETHUSD);
    }
    
}

 

interface MintableERC20 {
    function mint(address _to, uint256 _amount) public returns (bool);
}
 
contract PreSale is Ownable, Crowdsale, MilestoneCrowdsale {
    using SafeMath for uint256;

     
    uint256 public cap;

     
    uint256 public minimumContribution;
    
    bool public isFinalized = false;

    USDPrice private usdPrice; 

    event Finalized();

    constructor(
        uint256 _rate,
        address _wallet,
        ERC20 _token,
        uint256 _openingTime,
        uint256 _closingTime,
        uint256 _cap,
        uint256 _minimumContribution,
        USDPrice _usdPrice
    )
        Crowdsale(_rate, _wallet, _token)
        MilestoneCrowdsale(_openingTime, _closingTime)
        public
    {  
        require(_cap > 0);
        require(_minimumContribution > 0);
        
        cap = _cap;
        minimumContribution = _minimumContribution;

        usdPrice = _usdPrice;
    }


     
    function capReached() public view returns (bool) {
        return tokensSold >= cap;
    }

     
    function finalize() public onlyOwner {
        require(!isFinalized);
        require(hasClosed());

        emit Finalized();

        isFinalized = true;
    }

     
    function _getTokenAmount(uint256 _weiAmount)
        internal view returns (uint256)
    {
        return usdPrice.getPrice(_weiAmount).div(getCurrentRate());
    }

     
    function _updatePurchasingState(
        address _beneficiary,
        uint256 _weiAmount,
        uint256 _tokenAmount
    )
        internal
    {
        super._updatePurchasingState(_beneficiary, _weiAmount, _tokenAmount);
    }
    
     
    function _deliverTokens(
        address _beneficiary,
        uint256 _tokenAmount
    )
        internal
    {
         
        require(MintableERC20(address(token)).mint(_beneficiary, _tokenAmount));
    }


     
    function _preValidatePurchase(
        address _beneficiary,
        uint256 _weiAmount,
        uint256 _tokenAmount
    )
        internal
    {
        super._preValidatePurchase(_beneficiary, _weiAmount, _tokenAmount);
        require(_weiAmount >= minimumContribution);
        require(tokensSold.add(_tokenAmount) <= cap);
    }

}
 

pragma solidity ^0.4.24;

 

 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
     
     
     
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    return a / b;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
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

 

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

 

 
contract Crowdsale {
  using SafeMath for uint256;

   
  ERC20 public token;

   
  address public wallet;

   
   
   
   
  uint256 public rate;

   
  uint256 public weiRaised;

   
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
    _preValidatePurchase(_beneficiary, weiAmount);

     
    uint256 tokens = _getTokenAmount(weiAmount);

     
    weiRaised = weiRaised.add(weiAmount);

    _processPurchase(_beneficiary, tokens);
    emit TokenPurchase(
      msg.sender,
      _beneficiary,
      weiAmount,
      tokens
    );

    _updatePurchasingState(_beneficiary, weiAmount);

    _forwardFunds();
    _postValidatePurchase(_beneficiary, weiAmount);
  }

   
   
   

   
  function _preValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
  {
    require(_beneficiary != address(0));
    require(_weiAmount != 0);
  }

   
  function _postValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount
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
    token.transfer(_beneficiary, _tokenAmount);
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
    uint256 _weiAmount
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
    require(_closingTime >= _openingTime);

    openingTime = _openingTime;
    closingTime = _closingTime;
  }

   
  function hasClosed() public view returns (bool) {
     
    return block.timestamp > closingTime;
  }

   
  function _preValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
    onlyWhileOpen
  {
    super._preValidatePurchase(_beneficiary, _weiAmount);
  }

}

 

 
contract FinalizableCrowdsale is TimedCrowdsale, Ownable {
  using SafeMath for uint256;

  bool public isFinalized = false;

  event Finalized();

   
  function finalize() onlyOwner public {
    require(!isFinalized);
    require(hasClosed());

    finalization();
    emit Finalized();

    isFinalized = true;
  }

   
  function finalization() internal {
  }

}

 

contract StageCrowdsale is FinalizableCrowdsale {
    bool public previousStageIsFinalized = false;
    StageCrowdsale public previousStage;

    constructor(
        uint256 _rate,
        address _wallet,
        ERC20 _token,
        uint256 _openingTime,
        uint256 _closingTime,
        StageCrowdsale _previousStage
    )
        public
        Crowdsale(_rate, _wallet, _token)
        TimedCrowdsale(_openingTime, _closingTime)
    {
        previousStage = _previousStage;
        if (_previousStage == address(0)) {
            previousStageIsFinalized = true;
        }
    }

    modifier isNotFinalized() {
        require(!isFinalized, "Call on finalized.");
        _;
    }

    modifier previousIsFinalized() {
        require(isPreviousStageFinalized(), "Call on previous stage finalized.");
        _;
    }

    function finalizeStage() public onlyOwner isNotFinalized {
        _finalizeStage();
    }

    function proxyBuyTokens(address _beneficiary) public payable {
        uint256 weiAmount = msg.value;
        _preValidatePurchase(_beneficiary, weiAmount);

         
        uint256 tokens = _getTokenAmount(weiAmount);

         
        weiRaised = weiRaised.add(weiAmount);

        _processPurchase(_beneficiary, tokens);
         
        emit TokenPurchase(tx.origin, _beneficiary, weiAmount, tokens);

        _updatePurchasingState(_beneficiary, weiAmount);

        _forwardFunds();
        _postValidatePurchase(_beneficiary, weiAmount);
    }

    function isPreviousStageFinalized() public returns (bool) {
        if (previousStageIsFinalized) {
            return true;
        }
        if (previousStage.isFinalized()) {
            previousStageIsFinalized = true;
        }
        return previousStageIsFinalized;
    }

    function _finalizeStage() internal isNotFinalized {
        finalization();
        emit Finalized();
        isFinalized = true;
    }

    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal isNotFinalized previousIsFinalized {
        super._preValidatePurchase(_beneficiary, _weiAmount);
    }
}

 

contract MultiStageCrowdsale is Ownable {

    uint256 public currentStageIndex = 0;
    StageCrowdsale[] public stages;

    event StageAdded();

    function () external payable {
        buyTokens(msg.sender);
    }

    modifier hasCurrentStage() {
        require(currentStageIndex < stages.length);
        _;
    }

    modifier validBuyCall(address _beneficiary) {
        require(_beneficiary != address(0));
        require(msg.value != 0);
        _;
    }

    function addStageCrowdsale(address _stageCrowdsaleAddress) public onlyOwner {
        require(_stageCrowdsaleAddress != address(0));
        StageCrowdsale stageToBeAdded = StageCrowdsale(_stageCrowdsaleAddress);
        if (stages.length > 0) {
            require(stageToBeAdded.previousStage() != address(0));
            StageCrowdsale lastStage = stages[stages.length - 1];
            require(stageToBeAdded.openingTime() >= lastStage.closingTime());
        }
        stages.push(stageToBeAdded);
        emit StageAdded();
    }

    function buyTokens(address _beneficiary) public payable validBuyCall(_beneficiary) hasCurrentStage {
        StageCrowdsale stage = updateCurrentStage();
        stage.proxyBuyTokens.value(msg.value)(_beneficiary);
        updateCurrentStage();
    }

    function getCurrentStage() public view returns (StageCrowdsale) {
        if (stages.length > 0) {
            return stages[currentStageIndex];
        }
    }

    function updateCurrentStage() public returns (StageCrowdsale currentStage) {
        if (currentStageIndex < stages.length) {
            currentStage = stages[currentStageIndex];
            while (currentStage.isFinalized() && currentStageIndex + 1 < stages.length) {
                currentStage = stages[++currentStageIndex];
            }
        }
    }
}
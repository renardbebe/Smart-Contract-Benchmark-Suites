 

pragma solidity ^0.4.24;

contract Crowdsale {
  using SafeMath for uint256;
  using SafeERC20 for ERC20;

   
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

    _processPurchase(_beneficiary, tokens, weiAmount);
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
    token.safeTransfer(_beneficiary, _tokenAmount);
  }

   
  function _processPurchase(
    address _beneficiary,
    uint256 _tokenAmount,
    uint256 _weiAmount
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

contract ScotchCrowdsale is Crowdsale, Ownable {
    using SafeMath for uint8;
    using SafeERC20 for ERC20;

    uint256 public TokenSaleSupply = 12000000000000000000000000000;
    uint256 public tokensSold;
    
     
    uint256 public preContrib    = 20000000000000000000;
    uint256 public icoContrib    = 10000000000000000;
     
    uint256 public minGetBonus    = 20000000000000000000;
    uint256 public minGetAddBonus = 50000000000000000000;
     
    uint8 public prePercentBonus = 10;
    uint8 public icoPercentBonus  = 5;
     
    uint256 public preSupply  = 2400000000000000000000000000;
    uint256 public icoSupply  = 9600000000000000000000000000;
     
    bool public preOpen = false;
    bool public icoOpen = false;

    bool public icoClosed = false;

    mapping(address => uint256) public contributions;
    mapping(address => uint256) public presaleTotalBuy;
    mapping(address => uint256) public icoTotalBuy;
    mapping(address => uint256) public presaleBonus;
    mapping(address => uint256) public icoBonus;
    mapping(uint8 => uint256) public soldPerStage;
    mapping(uint8 => uint256) public availablePerStage;
    mapping(address => bool) public allowPre;

     
    enum CrowdsaleStage { preSale, ICO }
    CrowdsaleStage public stage = CrowdsaleStage.preSale;
    uint256 public minContribution = preContrib;
    uint256 public stageAllocation = preSupply;

    constructor(
        uint256 _rate,
        address _wallet,
        ERC20 _token
    )
    Crowdsale(_rate, _wallet, _token)
    public {
        availablePerStage[0] = stageAllocation;
    }

     
    function openPresale(bool status) public onlyOwner {
        preOpen = status;
    }
    function openICOSale(bool status) public onlyOwner {
        icoOpen = status;
    }
    function closeICO(bool status) public onlyOwner {
        icoClosed = status;
    }
    function setCrowdsaleStage(uint8 _stage) public onlyOwner {
        _setCrowdsaleStage(_stage);
    }

    function _setCrowdsaleStage(uint8 _stage) internal {
         
        require(_stage > uint8(stage) && _stage < 2);

        if(uint8(CrowdsaleStage.preSale) == _stage) {
            stage = CrowdsaleStage.preSale;
            minContribution = preContrib;
            stageAllocation = preSupply;
        } else {
            stage = CrowdsaleStage.ICO;
            minContribution = icoContrib;
            stageAllocation = icoSupply;
        }

        availablePerStage[_stage] = stageAllocation;
    }

    function whitelistPresale(address _beneficiary, bool status) public onlyOwner {
        allowPre[_beneficiary] = status;
    }

    function _preValidatePurchase(
        address _beneficiary,
        uint256 _weiAmount
    )
        internal
    {
         
        require(!icoClosed);
        require(_beneficiary != address(0));
        if(stage == CrowdsaleStage.preSale) {
            require(preOpen);
            require(allowPre[_beneficiary]);
            allowPre[_beneficiary] = false;
            require(_weiAmount == minContribution);
        } else {
            require(icoOpen);
            require(_weiAmount >= minContribution);
        }
    }

    function _processPurchase(
        address _beneficiary,
        uint256 _tokenAmount,
        uint256 _weiAmount
    )
        internal
    {
        uint8 getBonusStage;
        uint256 bonusStage_;
        uint256 additionalBonus = 0;
        if(stage == CrowdsaleStage.preSale) {
            getBonusStage = prePercentBonus;
        } else {
            if(_weiAmount>=minGetBonus){
                getBonusStage = icoPercentBonus;
            } else {
                getBonusStage = 0;
            }
        }
        bonusStage_ = _tokenAmount.mul(getBonusStage).div(100);
        require(availablePerStage[uint8(stage)] >= _tokenAmount);
        tokensSold = tokensSold.add(_tokenAmount);

        soldPerStage[uint8(stage)] = soldPerStage[uint8(stage)].add(_tokenAmount);
        availablePerStage[uint8(stage)] = availablePerStage[uint8(stage)].sub(_tokenAmount);
         
        if(stage == CrowdsaleStage.preSale) {
            presaleTotalBuy[_beneficiary] = presaleTotalBuy[_beneficiary] + _tokenAmount;
            presaleBonus[_beneficiary] = presaleBonus[_beneficiary].add(bonusStage_);
        } else {
            icoTotalBuy[_beneficiary] = icoTotalBuy[_beneficiary] + _tokenAmount;
            icoBonus[_beneficiary] = icoBonus[_beneficiary].add(bonusStage_);
        }
        
        _deliverTokens(_beneficiary, _tokenAmount.add(bonusStage_).add(additionalBonus));

         
        if(availablePerStage[uint8(stage)]<=0){
             
            if(stage == CrowdsaleStage.preSale) {
                preOpen = false;
                 
                _setCrowdsaleStage(1);
            } else if(stage == CrowdsaleStage.ICO) {
                icoOpen = false;
                icoClosed = true;
            }
        }
    }

    function _updatePurchasingState(
        address _beneficiary,
        uint256 _weiAmount
    )
        internal
    {
         
        uint256 _existingContribution = contributions[_beneficiary];
        uint256 _newContribution = _existingContribution.add(_weiAmount);
        contributions[_beneficiary] = _newContribution;
    }

    function getuserContributions(address _beneficiary) public view returns (uint256) {
        return contributions[_beneficiary];
    }
    function getuserPresaleTotalBuy(address _beneficiary) public view returns (uint256) {
        return presaleTotalBuy[_beneficiary];
    }
    function getuserICOTotalBuy(address _beneficiary) public view returns (uint256) {
        return icoTotalBuy[_beneficiary];
    }
    function getuserPresaleBonus(address _beneficiary) public view returns (uint256) {
        return presaleBonus[_beneficiary];
    }
    function getuserICOBonus(address _beneficiary) public view returns (uint256) {
        return icoBonus[_beneficiary];
    }
    function getAvailableBuyETH(uint8 _stage) public view returns (uint256) {
        return availablePerStage[_stage].div(rate);
    }

     
    function sendToOwner(uint256 _amount) public onlyOwner {
        require(icoClosed);
        _deliverTokens(owner, _amount);
    }

}
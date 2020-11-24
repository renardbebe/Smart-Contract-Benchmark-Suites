 

pragma solidity ^0.4.18;


library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
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


interface ERC20 {
  function transfer (address _beneficiary, uint256 _tokenAmount) external returns (bool);  
  function mint (address _to, uint256 _amount) external returns (bool);
}


contract Ownable {
    address public owner;
    function Ownable() public {
        owner = msg.sender;
    }
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
}


contract Crowdsale is Ownable {
  using SafeMath for uint256;

  modifier onlyWhileOpen {
      require(
        (now >= preICOStartDate && now < preICOEndDate) || 
        (now >= ICOStartDate && now < ICOEndDate)
      );
      _;
  }

  modifier onlyWhileICOOpen {
      require(now >= ICOStartDate && now < ICOEndDate);
      _;
  }

   
  ERC20 public token;

   
  address public wallet;

   
  uint256 public rate = 1000;

   
  uint256 public preICOWeiRaised;

   
  uint256 public ICOWeiRaised;

   
  uint256 public ETHUSD;

   
  uint256 public preICOStartDate;

   
  uint256 public preICOEndDate;

   
  uint256 public ICOStartDate;

   
  uint256 public ICOEndDate;

   
  uint256 public softcap = 300000000;

   
  uint256 public hardcap = 2500000000;

   
  uint8 public referalBonus = 3;

   
  uint8 public invitedByReferalBonus = 2; 

   
  mapping(address => bool) public whitelist;

   
  mapping (address => uint256) public investors;

  event TokenPurchase(address indexed buyer, uint256 value, uint256 amount);

  function Crowdsale( 
    address _wallet, 
    uint256 _preICOStartDate, 
    uint256 _preICOEndDate,
    uint256 _ICOStartDate, 
    uint256 _ICOEndDate,
    uint256 _ETHUSD
  ) public {
    require(_preICOEndDate > _preICOStartDate);
    require(_ICOStartDate > _preICOEndDate);
    require(_ICOEndDate > _ICOStartDate);

    wallet = _wallet;
    preICOStartDate = _preICOStartDate;
    preICOEndDate = _preICOEndDate;
    ICOStartDate = _ICOStartDate;
    ICOEndDate = _ICOEndDate;
    ETHUSD = _ETHUSD;
  }

   

   
  function setRate (uint16 _rate) public onlyOwner {
    require(_rate > 0);
    rate = _rate;
  }

   
  function setWallet (address _wallet) public onlyOwner {
    require (_wallet != 0x0);
    wallet = _wallet;
      
  }
  

   
  function setToken (ERC20 _token) public onlyOwner {
    token = _token;
  }
  
   
  function setPreICOStartDate (uint256 _preICOStartDate) public onlyOwner {
    require(_preICOStartDate < preICOEndDate);
    preICOStartDate = _preICOStartDate;
  }

   
  function setPreICOEndDate (uint256 _preICOEndDate) public onlyOwner {
    require(_preICOEndDate > preICOStartDate);
    preICOEndDate = _preICOEndDate;
  }

   
  function setICOStartDate (uint256 _ICOStartDate) public onlyOwner {
    require(_ICOStartDate < ICOEndDate);
    ICOStartDate = _ICOStartDate;
  }

   
  function setICOEndDate (uint256 _ICOEndDate) public onlyOwner {
    require(_ICOEndDate > ICOStartDate);
    ICOEndDate = _ICOEndDate;
  }

   
  function setETHUSD (uint256 _ETHUSD) public onlyOwner {
    ETHUSD = _ETHUSD;
  }

  function () external payable {
    address beneficiary = msg.sender;
    uint256 weiAmount = msg.value;
    uint256 tokens;

    if(_isPreICO()){

        _preValidatePreICOPurchase(beneficiary, weiAmount);
        tokens = weiAmount.mul(rate.add(rate.mul(30).div(100)));
        preICOWeiRaised = preICOWeiRaised.add(weiAmount);
        wallet.transfer(weiAmount);
        investors[beneficiary] = weiAmount;
        _deliverTokens(beneficiary, tokens);
        TokenPurchase(beneficiary, weiAmount, tokens);

    } else if(_isICO()){

        _preValidateICOPurchase(beneficiary, weiAmount);
        tokens = _getTokenAmountWithBonus(weiAmount);
        ICOWeiRaised = ICOWeiRaised.add(weiAmount);
        investors[beneficiary] = weiAmount;
        _deliverTokens(beneficiary, tokens);
        TokenPurchase(beneficiary, weiAmount, tokens);

    }
  }

     
  function buyTokensWithReferal(address _referal) public onlyWhileICOOpen payable {
    address beneficiary = msg.sender;    
    uint256 weiAmount = msg.value;

    _preValidateICOPurchase(beneficiary, weiAmount);

    uint256 tokens = _getTokenAmountWithBonus(weiAmount).add(_getTokenAmountWithReferal(weiAmount, 2));
    uint256 referalTokens = _getTokenAmountWithReferal(weiAmount, 3);

    ICOWeiRaised = ICOWeiRaised.add(weiAmount);
    investors[beneficiary] = weiAmount;

    _deliverTokens(beneficiary, tokens);
    _deliverTokens(_referal, referalTokens);

    TokenPurchase(beneficiary, weiAmount, tokens);
  }

   
  function addToWhitelist(address _beneficiary) public onlyOwner {
    whitelist[_beneficiary] = true;
  }

   
  function addManyToWhitelist(address[] _beneficiaries) public onlyOwner {
    for (uint256 i = 0; i < _beneficiaries.length; i++) {
      whitelist[_beneficiaries[i]] = true;
    }
  }

   
  function removeFromWhitelist(address _beneficiary) public onlyOwner {
    whitelist[_beneficiary] = false;
  }

   
  function hasPreICOClosed() public view returns (bool) {
    return now > preICOEndDate;
  }

   
  function hasICOClosed() public view returns (bool) {
    return now > ICOEndDate;
  }

   
  function forwardFunds () public onlyOwner {
    require(now > ICOEndDate);
    require((preICOWeiRaised.add(ICOWeiRaised)).mul(ETHUSD).div(10**18) >= softcap);

    wallet.transfer(ICOWeiRaised);
  }

   
  function refund() public {
    require(now > ICOEndDate);
    require(preICOWeiRaised.add(ICOWeiRaised).mul(ETHUSD).div(10**18) < softcap);
    require(investors[msg.sender] > 0);
    
    address investor = msg.sender;
    investor.transfer(investors[investor]);
  }
  

   

    
   function _isPreICO() internal view returns(bool) {
       return now >= preICOStartDate && now < preICOEndDate;
   }
   
    
   function _isICO() internal view returns(bool) {
       return now >= ICOStartDate && now < ICOEndDate;
   }

    

  function _preValidatePreICOPurchase(address _beneficiary, uint256 _weiAmount) internal view {
    require(_weiAmount != 0);
    require(now >= preICOStartDate && now <= preICOEndDate);
  }

  function _preValidateICOPurchase(address _beneficiary, uint256 _weiAmount) internal view {
    require(_weiAmount != 0);
    require(whitelist[_beneficiary]);
    require((preICOWeiRaised + ICOWeiRaised + _weiAmount).mul(ETHUSD).div(10**18) <= hardcap);
    require(now >= ICOStartDate && now <= ICOEndDate);
  }

   
  function _getTokenAmountWithBonus(uint256 _weiAmount) internal view returns(uint256) {
    uint256 baseTokenAmount = _weiAmount.mul(rate);
    uint256 tokenAmount = baseTokenAmount;
    uint256 usdAmount = _weiAmount.mul(ETHUSD).div(10**18);

     
    if(usdAmount >= 10000000){
        tokenAmount = tokenAmount.add(baseTokenAmount.mul(7).div(100));
    } else if(usdAmount >= 5000000){
        tokenAmount = tokenAmount.add(baseTokenAmount.mul(5).div(100));
    } else if(usdAmount >= 1000000){
        tokenAmount = tokenAmount.add(baseTokenAmount.mul(3).div(100));
    }
    
     
    if(now < ICOStartDate + 15 days) {
        tokenAmount = tokenAmount.add(baseTokenAmount.mul(20).div(100));
    } else if(now < ICOStartDate + 28 days) {
        tokenAmount = tokenAmount.add(baseTokenAmount.mul(15).div(100));
    } else if(now < ICOStartDate + 42 days) {
        tokenAmount = tokenAmount.add(baseTokenAmount.mul(10).div(100));
    } else {
        tokenAmount = tokenAmount.add(baseTokenAmount.mul(5).div(100));
    }

    return tokenAmount;
  }

   
  function _getTokenAmountWithReferal(uint256 _weiAmount, uint8 _percent) internal view returns(uint256) {
    return _weiAmount.mul(rate).mul(_percent).div(100);
  }

   
  function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
    token.mint(_beneficiary, _tokenAmount);
  }
}
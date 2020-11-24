 

pragma solidity ^0.4.18;

 
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

  function Ownable() public {
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
  uint public totalSupply;
  function balanceOf(address who) public constant returns (uint);
  function transfer(address to, uint value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint value);
  
  function allowance(address owner, address spender) public constant returns (uint);
  function transferFrom(address from, address to, uint value) public returns (bool);
  function approve(address spender, uint value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint value);
}

 
contract ExtendedERC20 is ERC20 {
  function mint(address _to, uint _amount) public returns (bool);
}

 
contract WizzleInfinityHelper {
  function isWhitelisted(address addr) public constant returns (bool);
}

 
contract Crowdsale is Ownable {
  using SafeMath for uint256;
  
   
  ExtendedERC20 public token;
   
  WizzleInfinityHelper public helper;
   
  uint256 public startTimePre;
   
  uint256 public endTimePre;
   
  uint256 public startTimeIco;
   
  uint256 public endTimeIco;
   
  address public wallet;
   
  uint32 public rate;
   
  uint256 public tokensSoldPre;
   
  uint256 public tokensSoldIco;
   
  uint256 public weiRaised;
   
  uint256 public contributors;
   
  uint256 public preCap;
   
  uint256 public icoCap;
   
  uint8 public preDiscountPercentage;
   
  uint256 public icoDiscountLevel1;
   
  uint256 public icoDiscountLevel2;
   
  uint8 public icoDiscountPercentageLevel1;
   
  uint8 public icoDiscountPercentageLevel2;
   
  uint8 public icoDiscountPercentageLevel3;

  function Crowdsale(uint256 _startTimePre, uint256 _endTimePre, uint256 _startTimeIco, uint256 _endTimeIco, uint32 _rate, address _wallet, address _tokenAddress, address _helperAddress) {
    require(_startTimePre >= now);
    require(_endTimePre >= _startTimePre);
    require(_startTimeIco >= _endTimePre);
    require(_endTimeIco >= _startTimeIco);
    require(_rate > 0);
    require(_wallet != address(0));
    require(_tokenAddress != address(0));
    require(_helperAddress != address(0));
    startTimePre = _startTimePre;
    endTimePre = _endTimePre;
    startTimeIco = _startTimeIco;
    endTimeIco = _endTimeIco;
    rate = _rate;
    wallet = _wallet;
    token = ExtendedERC20(_tokenAddress);
    helper = WizzleInfinityHelper(_helperAddress);
    preCap = 1500 * 10**24;            
    preDiscountPercentage = 50;        
    icoCap = 3450 * 10**24;            
    icoDiscountLevel1 = 500 * 10**24;  
    icoDiscountLevel2 = 500 * 10**24;  
    icoDiscountPercentageLevel1 = 40;  
    icoDiscountPercentageLevel2 = 30;  
    icoDiscountPercentageLevel3 = 25;  
  }

   
   
  function setRate(uint32 _rate) public onlyOwner {
    require(_rate > 0);
    rate = _rate;
  }

   
  function () payable {
    buyTokens(msg.sender);
  }

   
   
  function buyTokens(address beneficiary) public payable {
    require(beneficiary != address(0));
    require(helper.isWhitelisted(beneficiary));
    uint256 weiAmount = msg.value;
    require(weiAmount > 0);
    uint256 tokenAmount = 0;
    if (isPresale()) {
       
      require(weiAmount >= 1 ether); 
      tokenAmount = getTokenAmount(weiAmount, preDiscountPercentage);
      uint256 newTokensSoldPre = tokensSoldPre.add(tokenAmount);
      require(newTokensSoldPre <= preCap);
      tokensSoldPre = newTokensSoldPre;
    } else if (isIco()) {
      uint8 discountPercentage = getIcoDiscountPercentage();
      tokenAmount = getTokenAmount(weiAmount, discountPercentage);
       
      require(tokenAmount >= 10**18); 
      uint256 newTokensSoldIco = tokensSoldIco.add(tokenAmount);
      require(newTokensSoldIco <= icoCap);
      tokensSoldIco = newTokensSoldIco;
    } else {
       
      require(false);
    }
    executeTransaction(beneficiary, weiAmount, tokenAmount);
  }

   
  function getIcoDiscountPercentage() internal constant returns (uint8) {
    if (tokensSoldIco <= icoDiscountLevel1) {
      return icoDiscountPercentageLevel1;
    } else if (tokensSoldIco <= icoDiscountLevel1.add(icoDiscountLevel2)) {
      return icoDiscountPercentageLevel2;
    } else { 
      return icoDiscountPercentageLevel3;  
    }
  }

   
  function getTokenAmount(uint256 weiAmount, uint8 discountPercentage) internal constant returns (uint256) {
     
    require(discountPercentage >= 0 && discountPercentage < 100); 
    uint256 baseTokenAmount = weiAmount.mul(rate);
    uint256 tokenAmount = baseTokenAmount.mul(10000).div(100 - discountPercentage);
    return tokenAmount;
  }

   
  function executeTransaction(address beneficiary, uint256 weiAmount, uint256 tokenAmount) internal {
    weiRaised = weiRaised.add(weiAmount);
    token.mint(beneficiary, tokenAmount);
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokenAmount);
	  contributors = contributors.add(1);
    wallet.transfer(weiAmount);
  }

   
   
  function changePresaleCap(uint256 _preCap) public onlyOwner {
    require(_preCap > 0);
    PresaleCapChanged(owner, _preCap);
    preCap = _preCap;
  }

   
   
  function changePresaleDiscountPercentage(uint8 _preDiscountPercentage) public onlyOwner {
    require(_preDiscountPercentage >= 0 && _preDiscountPercentage < 100);
    PresaleDiscountPercentageChanged(owner, _preDiscountPercentage);
    preDiscountPercentage = _preDiscountPercentage;
  }

   
   
   
  function changePresaleTimeRange(uint256 _startTimePre, uint256 _endTimePre) public onlyOwner {
    require(_endTimePre >= _startTimePre);
    PresaleTimeRangeChanged(owner, _startTimePre, _endTimePre);
    startTimePre = _startTimePre;
    endTimePre = _endTimePre;
  }

   
   
  function changeIcoCap(uint256 _icoCap) public onlyOwner {
    require(_icoCap > 0);
    IcoCapChanged(owner, _icoCap);
    icoCap = _icoCap;
  }

   
   
   
  function changeIcoTimeRange(uint256 _startTimeIco, uint256 _endTimeIco) public onlyOwner {
    require(_endTimeIco >= _startTimeIco);
    IcoTimeRangeChanged(owner, _startTimeIco, _endTimeIco);
    startTimeIco = _startTimeIco;
    endTimeIco = _endTimeIco;
  }

   
   
   
  function changeIcoDiscountLevels(uint256 _icoDiscountLevel1, uint256 _icoDiscountLevel2) public onlyOwner {
    require(_icoDiscountLevel1 > 0 && _icoDiscountLevel2 > 0);
    IcoDiscountLevelsChanged(owner, _icoDiscountLevel1, _icoDiscountLevel2);
    icoDiscountLevel1 = _icoDiscountLevel1;
    icoDiscountLevel2 = _icoDiscountLevel2;
  }

   
   
   
   
  function changeIcoDiscountPercentages(uint8 _icoDiscountPercentageLevel1, uint8 _icoDiscountPercentageLevel2, uint8 _icoDiscountPercentageLevel3) public onlyOwner {
    require(_icoDiscountPercentageLevel1 >= 0 && _icoDiscountPercentageLevel1 < 100);
    require(_icoDiscountPercentageLevel2 >= 0 && _icoDiscountPercentageLevel2 < 100);
    require(_icoDiscountPercentageLevel3 >= 0 && _icoDiscountPercentageLevel3 < 100);
    IcoDiscountPercentagesChanged(owner, _icoDiscountPercentageLevel1, _icoDiscountPercentageLevel2, _icoDiscountPercentageLevel3);
    icoDiscountPercentageLevel1 = _icoDiscountPercentageLevel1;
    icoDiscountPercentageLevel2 = _icoDiscountPercentageLevel2;
    icoDiscountPercentageLevel3 = _icoDiscountPercentageLevel3;
  }

   
  function isPresale() public constant returns (bool) {
    return now >= startTimePre && now <= endTimePre;
  }

   
  function isIco() public constant returns (bool) {
    return now >= startTimeIco && now <= endTimeIco;
  }

   
  function hasPresaleEnded() public constant returns (bool) {
    return now > endTimePre;
  }

   
  function hasIcoEnded() public constant returns (bool) {
    return now > endTimeIco;
  }

   
  function cummulativeTokensSold() public constant returns (uint256) {
    return tokensSoldPre + tokensSoldIco;
  }

   
   
  function claimTokens(address _token) public onlyOwner {
    if (_token == address(0)) { 
         owner.transfer(this.balance);
         return;
    }

    ERC20 erc20Token = ERC20(_token);
    uint balance = erc20Token.balanceOf(this);
    erc20Token.transfer(owner, balance);
    ClaimedTokens(_token, owner, balance);
  }

   
  event TokenPurchase(address indexed _purchaser, address indexed _beneficiary, uint256 _value, uint256 _amount);
  event PresaleTimeRangeChanged(address indexed _owner, uint256 _startTimePre, uint256 _endTimePre);
  event PresaleCapChanged(address indexed _owner, uint256 _preCap);
  event PresaleDiscountPercentageChanged(address indexed _owner, uint8 _preDiscountPercentage);
  event IcoCapChanged(address indexed _owner, uint256 _icoCap);
  event IcoTimeRangeChanged(address indexed _owner, uint256 _startTimeIco, uint256 _endTimeIco);
  event IcoDiscountLevelsChanged(address indexed _owner, uint256 _icoDiscountLevel1, uint256 _icoDiscountLevel2);
  event IcoDiscountPercentagesChanged(address indexed _owner, uint8 _icoDiscountPercentageLevel1, uint8 _icoDiscountPercentageLevel2, uint8 _icoDiscountPercentageLevel3);
  event ClaimedTokens(address indexed _token, address indexed _owner, uint _amount);

}

 
contract WizzleInfinityTokenCrowdsale is Crowdsale {

  function WizzleInfinityTokenCrowdsale(uint256 _startTimePre, uint256 _endTimePre, uint256 _startTimeIco, uint256 _endTimeIco, uint32 _rate, address _wallet, address _tokenAddress, address _helperAddress) 
  Crowdsale(_startTimePre, _endTimePre, _startTimeIco, _endTimeIco, _rate, _wallet, _tokenAddress, _helperAddress) public {

  }

}
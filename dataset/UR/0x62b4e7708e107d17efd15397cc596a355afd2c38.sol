 

pragma solidity ^0.4.24;

 
 
contract ERC20 {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  function mint(address _to, uint256 _amount) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
 
contract OwnableWithAdmin {
  address public owner;
  address public adminOwner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
   
  constructor() public {
    owner = msg.sender;
    adminOwner = msg.sender;
  }
   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  modifier onlyAdmin() {
    require(msg.sender == adminOwner);
    _;
  }

   
  modifier onlyOwnerOrAdmin() {
    require(msg.sender == adminOwner || msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

   
  function transferAdminOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(adminOwner, newOwner);
    adminOwner = newOwner;
  }

}

 
 
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

  function uint2str(uint i) internal pure returns (string){
      if (i == 0) return "0";
      uint j = i;
      uint length;
      while (j != 0){
          length++;
          j /= 10;
      }
      bytes memory bstr = new bytes(length);
      uint k = length - 1;
      while (i != 0){
          bstr[k--] = byte(48 + i % 10);
          i /= 10;
      }
      return string(bstr);
  }
 
  
}

 
 
contract Crowdsale is OwnableWithAdmin {
  using SafeMath for uint256;

  uint256 private constant DECIMALFACTOR = 10**uint256(18);

  event FundTransfer(address backer, uint256 amount, bool isContribution);
  event TokenPurchase(address indexed purchaser, uint256 value, uint256 amount  );
   
   
  bool internal crowdsaleActive = true;

   
  ERC20 public token;

   
  address public wallet;

   
  uint256 public rate;

   
  uint256 public minRate; 

   
  uint256 public minWeiAmount = 100000000000000000; 

   
  uint256 public tokensTotal = 0;

   
  uint256 public weiRaised;

   
  uint256 public hardCap = 0;

  
   
  uint256 public startTime;
  uint256 public endTime;
  
   
  mapping(address => bool) public whitelist;
  
 
  constructor(uint256 _startTime, uint256 _endTime, address _wallet, ERC20 _token) public {
     
    require(_wallet != address(0));
    require(_token != address(0));

     

    startTime   = _startTime;
    endTime     = _endTime;
  
    wallet = _wallet;
    token = _token;
  }

   
   
   

   
  function () public payable  {

     
    require( msg.value > 0 );

     
    require(isCrowdsaleActive());

     
    require(isWhitelisted(msg.sender));

     
    uint256 _weiAmount = msg.value;

     
    require(_weiAmount>minWeiAmount);

     
    uint256 _tokenAmount = _calculateTokens(_weiAmount);

     
    require(_validateHardCap(_tokenAmount));

     
    require(token.mint(msg.sender, _tokenAmount));

     
    tokensTotal = tokensTotal.add(_tokenAmount);

     
    weiRaised = weiRaised.add(_weiAmount);

     
    emit TokenPurchase(msg.sender, _tokenAmount , _weiAmount);

     
    _forwardFunds();

 
  }

 
   
  function _forwardFunds() internal {
    wallet.transfer(msg.value);
  }


   
  function fiatTransfer(address _recipient, uint256 _tokenAmount, uint256 _weiAmount) onlyOwnerOrAdmin public{
    
    require(_tokenAmount > 0);      
    require(_recipient != address(0)); 

     
    require(isCrowdsaleActive());

     
    require(isWhitelisted(_recipient));

     
    require(_weiAmount>minWeiAmount); 

     
    require(_validateHardCap(_tokenAmount));

     
    require(token.mint(_recipient, _tokenAmount));

     
    tokensTotal = tokensTotal.add(_tokenAmount);

     
    weiRaised = weiRaised.add(_weiAmount);

     
    emit TokenPurchase(_recipient, _tokenAmount, _weiAmount);

  }

   
  function isCrowdsaleActive() public view returns (bool) {
    bool withinPeriod = now >= startTime && now <= endTime;
    return withinPeriod;
  }

  function _validateHardCap(uint256 _tokenAmount) internal view returns (bool) {
      return tokensTotal.add(_tokenAmount) <= hardCap;
  }


  function _calculateTokens(uint256 _wei) internal view returns (uint256) {
    return _wei.mul(DECIMALFACTOR).div(rate);
  }

 

    
  function setRate(uint256 _rate) onlyOwnerOrAdmin public{
    require(_rate > minRate);
    rate = _rate;
  }


  function addToWhitelist(address _buyer) onlyOwnerOrAdmin public{
    require(_buyer != 0x0);     
    whitelist[_buyer] = true;
  }
  

  function addManyToWhitelist(address[] _beneficiaries) onlyOwnerOrAdmin public{
    for (uint256 i = 0; i < _beneficiaries.length; i++) {
      if(_beneficiaries[i] != 0x0){
        whitelist[_beneficiaries[i]] = true;
      }
    }
  }


  function removeFromWhitelist(address _buyer) onlyOwnerOrAdmin public{
    whitelist[_buyer] = false;
  }


   
  function isWhitelisted(address _buyer) public view returns (bool) {
      return whitelist[_buyer];
  }


  

   
  function refundTokens(address _recipient, ERC20 _token) public onlyOwner {
    uint256 balance = _token.balanceOf(this);
    require(_token.transfer(_recipient, balance));
  }


}

 
 
contract BYTMCrowdsale is Crowdsale {
  constructor(   
    uint256 _startTime, 
    uint256 _endTime,  
    address _wallet, 
    ERC20 _token
  ) public Crowdsale( _startTime, _endTime,  _wallet, _token) {

     
     
    rate = 870000000000000;   

     
     
     
    minRate = 670000000000000;  

     
    hardCap = 1000000000 * (10**uint256(18)); 

     
     
    minWeiAmount = 545000000000000000;

  }
}
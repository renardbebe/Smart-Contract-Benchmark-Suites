 

pragma solidity 0.4.25;

 

 

 
 
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
     
     
     
    return a / b;
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

 

 
 
 
 
interface ERC20Interface {
    function totalSupply() external returns (uint);
    function balanceOf(address tokenOwner) external returns (uint balance);
    function allowance(address tokenOwner, address spender) external returns (uint remaining);
    function transfer(address to, uint tokens) external returns (bool success);
    function approve(address spender, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);
    function burn(uint _amount) external returns (bool success);
    function burnFrom(address _from, uint _amount) external returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event LogBurn(address indexed _spender, uint256 _value);
}

 

 
 
 
 
 
 
contract TokenSale {
  using SafeMath for *;

  ERC20Interface mybToken;

  struct Day {
    uint totalWeiContributed;
    mapping (address => uint) weiContributed;
  }

   
  uint256 constant internal scalingFactor = 10**32;       
  uint256 constant public tokensPerDay = 10**23;     

   
  address public owner;
  address public mybitFoundation;
  address public developmentFund;

  uint256 public start;       

  mapping (uint16 => Day) public day;

  constructor(address _mybToken, address _mybFoundation, address _developmentFund)
  public {
    mybToken = ERC20Interface(_mybToken);
    developmentFund = _developmentFund;
    mybitFoundation = _mybFoundation;
    owner = msg.sender;
  }

   
   
  function startSale(uint _timestamp)
  external
  onlyOwner
  returns (bool){
    require(start == 0, 'Already started');
    require(_timestamp >= now  && _timestamp.sub(now) < 2592000, 'Start time not in range');
    uint saleAmount = tokensPerDay.mul(365);
    require(mybToken.transferFrom(msg.sender, address(this), saleAmount));
    start = _timestamp;
    emit LogSaleStarted(msg.sender, mybitFoundation, developmentFund, saleAmount, _timestamp);
    return true;
  }


   
   
  function fund(uint16 _day)
  payable
  public
  returns (bool) {
      require(addContribution(msg.sender, msg.value, _day));
      return true;
  }

   
   
  function batchFund(uint16[] _day)
  payable
  external
  returns (bool) {
    require(_day.length <= 50);        
    require(msg.value >= _day.length);    
    uint256 amountPerDay = msg.value.div(_day.length);
    assert (amountPerDay.mul(_day.length) == msg.value);    
    for (uint8 i = 0; i < _day.length; i++){
      require(addContribution(msg.sender, amountPerDay, _day[i]));
    }
    return true;
  }


   
  function withdraw(uint16 _day)
  external
  returns (bool) {
      require(dayFinished(_day), "day has not finished funding");
      Day storage thisDay = day[_day];
      uint256 amount = getTokensOwed(msg.sender, _day);
      delete thisDay.weiContributed[msg.sender];
      mybToken.transfer(msg.sender, amount);
      emit LogTokensCollected(msg.sender, amount, _day);
      return true;
  }

   
   
  function batchWithdraw(uint16[] _day)
  external
  returns (bool) {
    uint256 amount;
    require(_day.length <= 50);      
    for (uint8 i = 0; i < _day.length; i++){
      require(dayFinished(_day[i]));
      uint256 amountToAdd = getTokensOwed(msg.sender, _day[i]);
      amount = amount.add(amountToAdd);
      delete day[_day[i]].weiContributed[msg.sender];
      emit LogTokensCollected(msg.sender, amountToAdd, _day[i]);
    }
    mybToken.transfer(msg.sender, amount);
    return true;
  }

   
   
   
  function foundationWithdraw(uint _amount)
  external
  onlyOwner
  returns (bool){
    uint256 half = _amount.div(2);
    assert (half.mul(2) == _amount);    
    mybitFoundation.transfer(half);
    developmentFund.transfer(half);
    emit LogFoundationWithdraw(msg.sender, _amount, dayFor(now));
    return true;
  }

   
   
   
   
  function addContribution(address _investor, uint _amount, uint16 _day)
  internal
  returns (bool) {
    require(_amount > 0, "must send ether with the call");
    require(duringSale(_day), "day is not during the sale");
    require(!dayFinished(_day), "day has already finished");
    Day storage today = day[_day];
    today.totalWeiContributed = today.totalWeiContributed.add(_amount);
    today.weiContributed[_investor] = today.weiContributed[_investor].add(_amount);
    emit LogTokensPurchased(_investor, _amount, _day);
    return true;
  }

   
  function getTokensOwed(address _contributor, uint16 _day)
  public
  view
  returns (uint256) {
      require(dayFinished(_day));
      Day storage thisDay = day[_day];
      uint256 percentage = thisDay.weiContributed[_contributor].mul(scalingFactor).div(thisDay.totalWeiContributed);
      return percentage.mul(tokensPerDay).div(scalingFactor);
  }

   
   
  function getTotalTokensOwed(address _contributor, uint16[] _days)
  public
  view
  returns (uint256 amount) {
    require(_days.length < 100);           
    for (uint16 i = 0; i < _days.length; i++){
      amount = amount.add(getTokensOwed(_contributor, _days[i]));
    }
    return amount;
  }

   
  function getWeiContributed(uint16 _day, address _contributor)
  public
  view
  returns (uint256) {
    return day[_day].weiContributed[_contributor];
  }

   
   
  function getTotalWeiContributed(uint16 _day)
  public
  view
  returns (uint256) {
    return day[_day].totalWeiContributed;
  }

   
  function dayFor(uint _timestamp)
  public
  view
  returns (uint16) {
      require(_timestamp >= start);
      return uint16(_timestamp.sub(start).div(86400));
  }

   
  function dayFinished(uint16 _day)
  public
  view
  returns (bool) {
    if (now <= start) { return false; }    
    return dayFor(now) > _day;
  }

   
  function duringSale(uint16 _day)
  public
  view
  returns (bool){
    return start > 0 && _day <= uint16(364);
  }


   
  function currentDay()
  public
  view
  returns (uint16) {
    return dayFor(now);
  }

   
   
  function ()
  external
  payable {
      require(addContribution(msg.sender, msg.value, currentDay()));
  }

   
  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }

  event LogSaleStarted(address _owner, address _mybFoundation, address _developmentFund, uint _totalMYB, uint _startTime);
  event LogFoundationWithdraw(address _mybFoundation, uint _amount, uint16 _day);
  event LogTokensPurchased(address indexed _contributor, uint _amount, uint16 indexed _day);
  event LogTokensCollected(address indexed _contributor, uint _amount, uint16 indexed _day);

}
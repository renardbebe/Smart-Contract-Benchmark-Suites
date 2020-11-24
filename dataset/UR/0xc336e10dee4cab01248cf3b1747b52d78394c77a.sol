 

 


pragma solidity ^0.4.23;

contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract HoardCrowdsale {
    function invest(address addr,uint tokenAmount) public payable {
    }
}
library SafeMathLib {

  function times(uint a, uint b) public pure returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

   
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


contract HoardPresale is Ownable {

  using SafeMathLib for uint;
  
   
  mapping (address => bool) public presaleParticipantWhitelist;
  
   
  address[] public investors;
  mapping (address => bool) private investorsMapping;

   
  mapping(address => uint) public balances;
  
   
  mapping(address => uint256) public tokenDue;

   
  uint public freezeEndsAt;
  
   
  uint public weiRaised = 0;

   
  uint public maxFundLimit = 5333000000000000000000;  
  
   
  HoardCrowdsale public crowdsale;

   
  struct Tranche {
     
    uint amount;
     
    uint price;
  }
  
   
   
   
   
   
   
  Tranche[10] public tranches;

   
  uint public trancheCount;
  uint public constant MAX_TRANCHES = 10;
  uint public tokenDecimals = 18;
  
  event Invested(address investor, uint value);
  event Refunded(address investor, uint value);
  
   
  event Whitelisted(address[] addr, bool status);
  
   
  event FreezeEndChanged(uint newFreezeEnd);
  
   
  event CrowdsaleAdded(address newCrowdsale);
  
   
   
  constructor(address _owner, uint _freezeEndsAt) public {
    require(_owner != address(0) && _freezeEndsAt != 0);
    owner = _owner;
    freezeEndsAt = _freezeEndsAt;
  }

   
   
  function() public payable {  
     
    require(presaleParticipantWhitelist[msg.sender]);
    require(trancheCount > 0);
    
    address investor = msg.sender;

    bool existing = investorsMapping[investor];

    balances[investor] = balances[investor].add(msg.value);
    weiRaised = weiRaised.add(msg.value);
    require(weiRaised <= maxFundLimit);
    
    uint weiAmount = msg.value;
    uint tokenAmount = calculatePrice(weiAmount);
    
     
    tokenDue[investor] = tokenDue[investor].add(tokenAmount);
        
    if(!existing) {
      investors.push(investor);
      investorsMapping[investor] = true;
    }

    emit Invested(investor, msg.value);
  }
  
   
  function setPresaleParticipantWhitelist(address[] addr, bool status) public onlyOwner {
    for(uint i = 0; i < addr.length; i++ ){
      presaleParticipantWhitelist[addr[i]] = status;
    }
    emit Whitelisted(addr, status);
  }
    
    
  function setFreezeEnd(uint _freezeEndsAt) public onlyOwner {
    require(_freezeEndsAt != 0);
    freezeEndsAt = _freezeEndsAt;
    emit FreezeEndChanged(freezeEndsAt);
  }  
    
   
  function participateCrowdsaleInvestor(address investor) public onlyOwner {

     
    require(address(crowdsale) != 0);

    if(balances[investor] > 0) {
      uint amount = balances[investor];
      uint tokenAmount = tokenDue[investor];
      delete balances[investor];
      delete tokenDue[investor];
      crowdsale.invest.value(amount)(investor,tokenAmount);
    }
  }

   
  function participateCrowdsaleAll() public onlyOwner {
     
     
    for(uint i = 0; i < investors.length; i++) {
      participateCrowdsaleInvestor(investors[i]);
    }
  }
  
   
  function participateCrowdsaleSelected(address[] addr) public onlyOwner {
    for(uint i = 0; i < addr.length; i++ ){
      participateCrowdsaleInvestor(investors[i]);
    }
  }

   
  function refund() public {

     
    require(now > freezeEndsAt && balances[msg.sender] > 0);

    address investor = msg.sender;
    uint amount = balances[investor];
    delete balances[investor];
    emit Refunded(investor, amount);
    investor.transfer(amount);
  }

   
  function setCrowdsale(HoardCrowdsale _crowdsale) public onlyOwner {
    crowdsale = _crowdsale;
    emit CrowdsaleAdded(crowdsale);
  }

    
  function getInvestorsCount() public view returns(uint investorsCount) {
    return investors.length;
  }
  
   
   
  function setPricing(uint[] _tranches) public onlyOwner {
     
    if(_tranches.length % 2 == 1 || _tranches.length >= MAX_TRANCHES*2) {
      revert();
    }

    trancheCount = _tranches.length / 2;

    uint highestAmount = 0;

    for(uint i=0; i<_tranches.length/2; i++) {
      tranches[i].amount = _tranches[i*2];
      tranches[i].price = _tranches[i*2+1];

       
      if((highestAmount != 0) && (tranches[i].amount <= highestAmount)) {
        revert();
      }

      highestAmount = tranches[i].amount;
    }

     
    if(tranches[0].amount != 0) {
      revert();
    }

     
    if(tranches[trancheCount-1].price != 0) {
      revert();
    }
  }
  
   
   
  function getCurrentTranche() private view returns (Tranche) {
    uint i;

    for(i=0; i < tranches.length; i++) {
      if(weiRaised <= tranches[i].amount) {
        return tranches[i-1];
      }
    }
  }
  
   
   
  function getCurrentPrice() public view returns (uint result) {
    return getCurrentTranche().price;
  }
  
   
  function calculatePrice(uint value) public view returns (uint) {
    uint multiplier = 10 ** tokenDecimals;
    uint price = getCurrentPrice();
    return value.times(multiplier) / price;
  }
  
   
   
  function getTranche(uint n) public view returns (uint, uint) {
    return (tranches[n].amount, tranches[n].price);
  }

  function getFirstTranche() private view returns (Tranche) {
    return tranches[0];
  }

  function getLastTranche() private view returns (Tranche) {
    return tranches[trancheCount-1];
  }

  function getPricingStartsAt() public view returns (uint) {
    return getFirstTranche().amount;
  }

  function getPricingEndsAt() public view returns (uint) {
    return getLastTranche().amount;
  }
  
}
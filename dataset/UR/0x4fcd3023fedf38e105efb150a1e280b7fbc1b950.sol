 

 

pragma solidity ^0.4.11;

 
 
 
  
 
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

 function div(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b > 0);  
    uint256 c = a / b;
    assert(a == b * c + a % b);  
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

interface XRPCToken {
    function transfer(address receiver, uint amount) public;
    function balanceOf(address _owner) public returns (uint256 balance);
    function mint(address wallet, address buyer, uint256 tokenAmount) public;
    function showMyTokenBalance(address addr) public;
}

contract newCrowdsale is Ownable {
    
     
    using SafeMath for uint256;
    
     
    uint256 public startTime;
    uint256 public endTime;
  
     
    mapping(address=>uint256) public ownerAddresses;   
    
    address[] owners;
    
    uint256 public majorOwnerShares = 100;
    uint256 public minorOwnerShares = 10;
    uint256 public coinPercentage = 5;
  
     
    uint256 public rate = 650;

     
    uint256 public weiRaised;
  
    bool public isCrowdsaleStopped = false;
  
    bool public isCrowdsalePaused = false;
    
     
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

  
     
    XRPCToken public token;
    
    
    function newCrowdsale(uint _daysToStart, address _walletMajorOwner) public 
    {
        token = XRPCToken(0xAdb41FCD3DF9FF681680203A074271D3b3Dae526); 
        
        _daysToStart = _daysToStart * 1 days;
        
        startTime = now + _daysToStart;   
        endTime = startTime + 90 days;
        
        require(endTime >= startTime);
        require(_walletMajorOwner != 0x0);
        
        ownerAddresses[_walletMajorOwner] = majorOwnerShares;
        
        owners.push(_walletMajorOwner);
        
        owner = _walletMajorOwner;
    }
    
     
    function () public payable {
    buy(msg.sender);
    }
    
    function buy(address beneficiary) public payable
    {
        require (isCrowdsaleStopped != true);
        require (isCrowdsalePaused != true);
        
        require(beneficiary != 0x0);
        require(validPurchase());

        uint256 weiAmount = msg.value;
        uint256 tokens = weiAmount.mul(rate);

         
        weiRaised = weiRaised.add(weiAmount);

        token.transfer(beneficiary,tokens);
         uint partnerCoins = tokens.mul(coinPercentage);
        partnerCoins = partnerCoins.div(100);
        
        TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

        forwardFunds(partnerCoins);
    }
    
      
    function forwardFunds(uint256 partnerTokenAmount) internal {
      for (uint i=0;i<owners.length;i++)
      {
         uint percent = ownerAddresses[owners[i]];
         uint amountToBeSent = msg.value.mul(percent);
         amountToBeSent = amountToBeSent.div(100);
         owners[i].transfer(amountToBeSent);
         
         if (owners[i]!=owner &&  ownerAddresses[owners[i]]>0)
         {
             token.transfer(owners[i],partnerTokenAmount);
         }
      }
    }
   
        
    function addPartner(address partner) public onlyOwner {

        require(partner != 0x0);
        require(ownerAddresses[owner] >=20);
        require(ownerAddresses[partner] == 0);
        owners.push(partner);
        ownerAddresses[partner] = 10;
        uint majorOwnerShare = ownerAddresses[owner];
        ownerAddresses[owner] = majorOwnerShare.sub(10);
    }
    
      
    function removePartner(address partner) public onlyOwner  {
        require(partner != 0x0);
        require(ownerAddresses[partner] > 0);
        require(ownerAddresses[owner] <= 90);
        ownerAddresses[partner] = 0;
        uint majorOwnerShare = ownerAddresses[owner];
        ownerAddresses[owner] = majorOwnerShare.add(10);
    }

     
    function validPurchase() internal constant returns (bool) {
        bool withinPeriod = now >= startTime && now <= endTime;
        bool nonZeroPurchase = msg.value != 0;
        return withinPeriod && nonZeroPurchase;
    }

     
    function hasEnded() public constant returns (bool) {
        return now > endTime;
    }
  
    function showMyTokenBalance(address myAddress) public returns (uint256 tokenBalance) {
       tokenBalance = token.balanceOf(myAddress);
    }

      
    function setEndDate(uint256 daysToEndFromToday) public onlyOwner returns(bool) {
        daysToEndFromToday = daysToEndFromToday * 1 days;
        endTime = now + daysToEndFromToday;
    }

      
    function setPriceRate(uint256 newPrice) public onlyOwner returns (bool) {
        rate = newPrice;
    }
    
     
     
    function pauseCrowdsale() public onlyOwner returns(bool) {
        isCrowdsalePaused = true;
    }

      
    function resumeCrowdsale() public onlyOwner returns (bool) {
        isCrowdsalePaused = false;
    }
    
     
    function stopCrowdsale() public onlyOwner returns (bool) {
        isCrowdsaleStopped = true;
    }
    
     
    function startCrowdsale() public onlyOwner returns (bool) {
        isCrowdsaleStopped = false;
        startTime = now; 
    }
    
      
    function tokensRemainingForSale(address contractAddress) public returns (uint balance) {
        balance = token.balanceOf(contractAddress);
    }
    
     
    function checkOwnerShare (address owner) public onlyOwner constant returns (uint share) {
        share = ownerAddresses[owner];
    }

     
    function changePartnerCoinPercentage(uint percentage) public onlyOwner {
        coinPercentage = percentage;
    }
}
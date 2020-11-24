 

pragma solidity ^0.4.18;

 
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
    function transfer(address receiver, uint amount) public ;
    function transferFrom(address sender, address receiver, uint amount) public returns(bool success);  
    function balanceOf(address _owner) constant public returns (uint256 balance);
}

 

contract ASTRICOPreSale is Ownable {
  ERC20 public token;   

   
  uint256 public startTime;
  uint256 public endTime;

   

  address public wallet;   
  address public ownerAddress;   

   
  uint256 public weiRaised;
  
  uint8 internal decimals             = 4;  
  uint256 internal decimalsConversion = 10 ** uint256(decimals);
  uint256 internal ALLOC_CROWDSALE    = 10000000 * decimalsConversion;  
   
   
   
   
   
   

  uint internal BASIC_RATE        = 75 * decimalsConversion;  
  uint internal PRICE_STAGE_PS    = 625 * decimalsConversion; 
  uint internal STAGE_PS_TIME_END = 60 minutes;  
  uint internal PRICE_VARIABLE    = 0 * decimalsConversion;
  uint256 public astrSold         = 0;

  bool public halted;
  bool public crowdsaleClosed;

   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

  modifier isNotHalted() {     require(!halted);    _;  }
  modifier afterDeadline() { if (now >= endTime) _; }

   
    function ASTRICOPreSale() public  {

    crowdsaleClosed = false;
    halted          = false;
    startTime       = 1511758800;  
    endTime         = 1511798400;  
    wallet          = ERC20(0x3baDA155408AB1C9898FDF28e545b51f2f9a65CC);  
    ownerAddress    = ERC20(0x3EFAe2e152F62F5cc12cc0794b816d22d416a721);   
    token           = ERC20(0x80E7a4d750aDe616Da896C49049B7EdE9e04C191);  
  }   

         
  function () public payable {
    require(msg.sender                 != 0x0);
    require(validPurchase());
    require(!halted);  
    uint256 weiAmount                  = msg.value;  
    uint256 tokens                     = SafeMath.div(SafeMath.mul(weiAmount, getCurrentRate()), 1 ether);
    require(ALLOC_CROWDSALE - astrSold >= tokens);
    weiRaised                          += weiAmount;
    astrSold                           += tokens;
    token.transferFrom(ownerAddress, msg.sender, tokens);
    wallet.transfer(msg.value);  
  }


  function validPurchase() internal constant returns (bool) {
    bool withinPeriod = now >= startTime && now <= endTime;
    bool nonZeroPurchase = (msg.value != 0);
    bool astrAvailable = (ALLOC_CROWDSALE - astrSold) > 0; 
    return withinPeriod && nonZeroPurchase && astrAvailable && ! crowdsaleClosed;
  }

  function getCurrentRate() internal constant returns (uint256) {  
    if( PRICE_VARIABLE > 0 ) {
      return PRICE_VARIABLE;  
    }
    return PRICE_STAGE_PS;
  }


   
  function setNewRate(uint256 _coinsPerEther) onlyOwner public {
    if( _coinsPerEther > 0 ) {
        PRICE_VARIABLE = _coinsPerEther * decimalsConversion;
    }
  }
     
  function setFixedRate() onlyOwner public {
     PRICE_VARIABLE = 0 * decimalsConversion;
  }


   
  function closeSaleAnyway() onlyOwner public {
       
      crowdsaleClosed = true;
    }

     
  function safeCloseSale()  onlyOwner afterDeadline public {
     
    crowdsaleClosed = true;
  }

  function pause() onlyOwner public {
    halted = true;
  }


  function unpause() onlyOwner public {
    halted = false;
  }
}
 

pragma solidity ^0.4.4;

contract DigiPulse {

	 
  string public constant name = "DigiPulse";
  string public constant symbol = "DGT";
  uint8 public constant decimals = 8;
  mapping (address => uint256) public balanceOf;

   
  uint constant tokenSupply = 16125000 * 1e8;
  uint8 constant dgtRatioToEth = 250;
  uint constant raisedInPresale = 961735343125;
  mapping (address => uint256) ethBalanceOf;
  address owner;

   
  uint constant startOfIco = 1501833600;  
  uint constant endOfIco = 1504223999;  

  uint allocatedSupply = 0;
  bool icoFailed = false;
  bool icoFulfilled = false;

   
	event Transfer(address indexed from, address indexed to, uint256 value);
  event Refund(address indexed _from, uint256 _value);

   
  function DigiPulse() {
    owner = msg.sender;
  }

   
  function transfer(address _to, uint256 _value) {
    require (balanceOf[msg.sender] >= _value);           
    require (balanceOf[_to] + _value > balanceOf[_to]);  

    balanceOf[msg.sender] -= _value;                     
    balanceOf[_to] += _value;                            

    Transfer(msg.sender, _to, _value);
  }

   
  function() payable external {
     
    require (now > startOfIco);
    require (now < endOfIco);
    require (!icoFulfilled);

     
    require (msg.value != 0);

     
     
    uint256 dgtAmount = msg.value / 1e10 * dgtRatioToEth;
    require (dgtAmount < (tokenSupply - allocatedSupply));

     
    uint256 dgtWithBonus;
    uint256 applicable_for_tier;

    for (uint8 i = 0; i < 4; i++) {
       
      uint256 tier_amount = 3750000 * 1e8;
       
      uint8 tier_bonus = 115 - (i * 5);
      applicable_for_tier += tier_amount;

       
      if (allocatedSupply >= applicable_for_tier) continue;

       
      if (dgtAmount == 0) break;

       
      int256 diff = int(allocatedSupply) + int(dgtAmount - applicable_for_tier);

      if (diff > 0) {
         
         
        dgtWithBonus += (uint(int(dgtAmount) - diff) * tier_bonus / 100);
        dgtAmount = uint(diff);
      } else {
        dgtWithBonus += (dgtAmount * tier_bonus / 100);
        dgtAmount = 0;
      }
    }

     
    allocatedSupply += dgtWithBonus;

     
    ethBalanceOf[msg.sender] += msg.value;
    balanceOf[msg.sender] += dgtWithBonus;
    Transfer(0, msg.sender, dgtWithBonus);
  }

   
  function finalise() external {
    require (!icoFailed);
    require (!icoFulfilled);
    require (now > endOfIco || allocatedSupply >= tokenSupply);

     
    if (this.balance < 8000 ether) {
      icoFailed = true;
    } else {
      setPreSaleAmounts();
      allocateBountyTokens();
      icoFulfilled = true;
    }
  }

   
   
  function refundEther() external {
  	require (icoFailed);

    var ethValue = ethBalanceOf[msg.sender];
    require (ethValue != 0);
    ethBalanceOf[msg.sender] = 0;

     
    msg.sender.transfer(ethValue);
    Refund(msg.sender, ethValue);
  }

   
	function getBalanceInEth(address addr) returns(uint){
		return ethBalanceOf[addr];
	}

   
  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balanceOf[_owner];
  }

	 
	function getRemainingSupply() returns(uint) {
		return tokenSupply - allocatedSupply;
	}

   
  function totalSupply() returns (uint totalSupply) {
    return allocatedSupply;
  }

   
   
  function withdrawFundsToOwner(uint256 _amount) {
    require (icoFulfilled);
    require (this.balance >= _amount);

    owner.transfer(_amount);
  }

   
   
   
	function setPreSaleAmounts() private {
    balanceOf[0x8776A6fA922e65efcEa2371692FEFE4aB7c933AB] += raisedInPresale;
    allocatedSupply += raisedInPresale;
    Transfer(0, 0x8776A6fA922e65efcEa2371692FEFE4aB7c933AB, raisedInPresale);
	}

	 
	function allocateBountyTokens() private {
    uint256 bountyAmount = allocatedSupply * 100 / 98 * 2 / 100;
		balanceOf[0x663F98e9c37B9bbA460d4d80ca48ef039eAE4052] += bountyAmount;
    allocatedSupply += bountyAmount;
    Transfer(0, 0x663F98e9c37B9bbA460d4d80ca48ef039eAE4052, bountyAmount);
	}
}
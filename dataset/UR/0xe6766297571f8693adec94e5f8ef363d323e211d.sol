 

pragma solidity ^0.4.15;

 
library SafeMath {
  function mul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint a, uint b) internal returns (uint) {
     
    uint c = a / b;
     
    return c;
  }

  function sub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }

  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }
}


 
contract Ownable {
  address public owner;


   
  function Ownable() {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) public onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}




 
contract DatumTokenSale is  Ownable {

  using SafeMath for uint256;

  address public whiteListControllerAddress;

   
  mapping (address => bool) public whiteListAddresses;

   
  mapping (address => uint) public bonusAddresses;

   
  mapping(address => uint256) public maxAmountAddresses;

   
  mapping(address => uint256) public balances;

   
  uint256 public startDate = 1509282000; 
   
  
  uint256 public endDate = 1511960400;  

   
  uint256 public minimumParticipationAmount = 300000000000000000 wei;  

   
  uint256 public maximalParticipationAmount = 1000 ether;  

   
  address wallet;

   
  uint256 rate = 25000;

   
  uint256 private weiRaised;

   
  bool public isFinalized = false;

   
  uint256 public cap = 61200 ether;  

   
  uint256 public totalTokenSupply = 1530000000 ether;

   
  uint256 public tokensInWeiSold;

  uint private bonus1Rate = 28750;
  uint private bonus2Rate = 28375;
  uint private bonus3Rate = 28000;
  uint private bonus4Rate = 27625;
  uint private bonus5Rate = 27250;
  uint private bonus6Rate = 26875;
  uint private bonus7Rate = 26500;
  uint private bonus8Rate = 26125;
  uint private bonus9Rate = 25750;
  uint private bonus10Rate = 25375;
   
  event Finalized();
   
  event LogParticipation(address indexed sender, uint256 value);
  

   
  event LogTokenReceiver(address indexed sender, uint256 value);


   
  event LogTokenRemover(address indexed sender, uint256 value);
  
  function DatumTokenSale(address _wallet) payable {
    wallet = _wallet;
  }

  function () payable {
    require(whiteListAddresses[msg.sender]);
    require(validPurchase());

    buyTokens(msg.value);
  }

   
  function buyTokens(uint256 amount) internal {
     
    uint256 weiAmount = amount;

     
    weiRaised = weiRaised.add(weiAmount);

     
    uint256 tokens = getTokenAmount(weiAmount);
    tokensInWeiSold = tokensInWeiSold.add(tokens);

     
    LogTokenReceiver(msg.sender, tokens);

     
    balances[msg.sender] = balances[msg.sender].add(tokens);

     
    LogParticipation(msg.sender,msg.value);

     
    forwardFunds(amount);
  }


   
  function reserveTokens(address _address, uint256 amount)
  {
    require(msg.sender == whiteListControllerAddress);

     
    balances[_address] = balances[_address].add(amount);

     
    LogTokenReceiver(_address, amount);

    tokensInWeiSold = tokensInWeiSold.add(amount);
  }

   
  function releaseTokens(address _address, uint256 amount)
  {
    require(msg.sender == whiteListControllerAddress);

    balances[_address] = balances[_address].sub(amount);

     
    LogTokenRemover(_address, amount);

    tokensInWeiSold = tokensInWeiSold.sub(amount);
  }

   
   
  function forwardFunds(uint256 amount) internal {
    wallet.transfer(amount);
  }

   
  function finalize() onlyOwner {
    require(!isFinalized);
    Finalized();
    isFinalized = true;
  }

  function setWhitelistControllerAddress(address _controller) onlyOwner
  {
     whiteListControllerAddress = _controller;
  }

  function addWhitelistAddress(address _addressToAdd)
  {
      require(msg.sender == whiteListControllerAddress);
      whiteListAddresses[_addressToAdd] = true;
  }

  function addSpecialBonusConditions(address _address, uint _bonusPercent, uint256 _maxAmount) 
  {
      require(msg.sender == whiteListControllerAddress);

      bonusAddresses[_address] = _bonusPercent;
      maxAmountAddresses[_address] = _maxAmount;
  }

  function removeSpecialBonusConditions(address _address) 
  {
      require(msg.sender == whiteListControllerAddress);

      delete bonusAddresses[_address];
      delete maxAmountAddresses[_address];
  }

  function addWhitelistAddresArray(address[] _addressesToAdd)
  {
      require(msg.sender == whiteListControllerAddress);

      for (uint256 i = 0; i < _addressesToAdd.length;i++) 
      {
        whiteListAddresses[_addressesToAdd[i]] = true;
      }
      
  }

  function removeWhitelistAddress(address _addressToAdd)
  {
      require(msg.sender == whiteListControllerAddress);

      delete whiteListAddresses[_addressToAdd];
  }


    function getTokenAmount(uint256 weiAmount) internal returns (uint256 tokens){
         
        uint256 bonusRate = getBonus();

         
        if(bonusAddresses[msg.sender] != 0)
        {
            uint bonus = bonusAddresses[msg.sender];
             
            bonusRate = rate.add((rate.mul(bonus)).div(100));
        } 

         
        uint256 weiTokenAmount = weiAmount.mul(bonusRate);
        return weiTokenAmount;
    }


     
    function getBonus() internal constant returns (uint256 amount){
        uint diffInSeconds = now - startDate;
        uint diffInHours = (diffInSeconds/60)/60;
        
         
        if(diffInHours < 72){
            return bonus1Rate;
        }

         
        if(diffInHours >= 72 && diffInHours < 144){
            return bonus2Rate;
        }

         
        if(diffInHours >= 144 && diffInHours < 216){
            return bonus3Rate;
        }

         
        if(diffInHours >= 216 && diffInHours < 288){
            return bonus4Rate;
        }

          
        if(diffInHours >= 288 && diffInHours < 360){
            return bonus5Rate;
        }

          
        if(diffInHours >= 360 && diffInHours < 432){
            return bonus6Rate;
        }

          
        if(diffInHours >= 432 && diffInHours < 504){
            return bonus7Rate;
        }

          
        if(diffInHours >= 504 && diffInHours < 576){
            return bonus8Rate;
        }

           
        if(diffInHours >= 576 && diffInHours < 648){
            return bonus9Rate;
        }

           
        if(diffInHours >= 648 && diffInHours < 720){
            return bonus10Rate;
        }

        return rate; 
    }

   
   
  function validPurchase() internal constant returns (bool) {
    uint256 tokenAmount = getTokenAmount(msg.value);
    bool withinPeriod = startDate <= now && endDate >= now;
    bool nonZeroPurchase = msg.value != 0;
    bool minAmount = msg.value >= minimumParticipationAmount;
    bool maxAmount = msg.value <= maximalParticipationAmount;
    bool withTokensSupply = tokensInWeiSold.add(tokenAmount) <= totalTokenSupply;
     
    bool withMaxAmountForAddress = maxAmountAddresses[msg.sender] == 0 || balances[msg.sender].add(tokenAmount) <= maxAmountAddresses[msg.sender];

    if(maxAmountAddresses[msg.sender] != 0)
    {
      maxAmount = balances[msg.sender].add(tokenAmount) <= maxAmountAddresses[msg.sender];
    }

    return withinPeriod && nonZeroPurchase && minAmount && !isFinalized && withTokensSupply && withMaxAmountForAddress && maxAmount;
  }

     
  function capReached() public constant returns (bool) {
    return tokensInWeiSold >= totalTokenSupply;
  }

   
  function hasEnded() public constant returns (bool) {
    return isFinalized;
  }

}
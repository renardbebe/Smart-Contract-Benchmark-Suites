 

pragma solidity 0.4.23;


 
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


   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

interface Token {
    function transfer(address _to, uint256 _amount)external returns (bool success);
    function balanceOf(address _owner) external returns (uint256 balance);
    function decimals()external view returns (uint8);
}

 
contract Vault is Ownable {
    using SafeMath for uint256;

    mapping (address => uint256) public deposited;
    address public wallet;
    
    event Withdrawn(address _wallet);
    
    function Vault(address _wallet) public {
        require(_wallet != address(0));
        wallet = _wallet;
    }

    function deposit(address investor) public onlyOwner  payable{
        
        deposited[investor] = deposited[investor].add(msg.value);
        
    }

    
    function withdrawToWallet() public onlyOwner {
     wallet.transfer(this.balance);
     emit Withdrawn(wallet);
  }
  
}


contract CLXTokenSale is Ownable{
      using SafeMath for uint256;
      
       
      Token public token;
      
       
      Vault public vault;
  
       
      uint256 public rate = 8000;
      
       

      struct PhaseInfo{
          uint256 hardcap;
          uint256 startTime;
          uint256 endTime;
          uint8   bonusPercentages;
          uint256 minEtherContribution;
          uint256 weiRaised;
      }
      
         
       
      PhaseInfo[] public phases;
      
       
      uint256 public totalFunding;

       
      uint256 tokensAvailableForSale = 17700000000000000;
      
      
      uint8 public noOfPhases;
      
      
       
      bool public contractUp;
      
       
      bool public saleEnded;

        
      bool public ifEmergencyStop ;
      
       
      event SaleStopped(address _owner, uint256 time);
      
       
      event SaleRestarted(address _owner, uint256 time);
      
       
      event Finished(address _owner, uint256 time);
    
      
     event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
    
     
    modifier _contractUp(){
        require(contractUp);
        _;
    }
  
     modifier nonZeroAddress(address _to) {
        require(_to != address(0));
        _;
    }
    
    modifier _saleEnded() {
        require(saleEnded);
        _;
    }
    
    modifier _saleNotEnded() {
        require(!saleEnded);
        _;
    }

    modifier _ifNotEmergencyStop() {
        require(!ifEmergencyStop);
        _;
    }

     
    function powerUpContract() external onlyOwner {
         
        require(!contractUp);

         
        require(token.balanceOf(this) >= tokensAvailableForSale);
        
         
        contractUp = true;
    }
    
     
    function emergencyStop() external onlyOwner _contractUp _ifNotEmergencyStop {
       
        ifEmergencyStop = true;  
        
        emit SaleStopped(msg.sender, now);
    }

     
    function emergencyRestart() external onlyOwner _contractUp  {
        require(ifEmergencyStop);
       
        ifEmergencyStop = false;

        emit SaleRestarted(msg.sender, now);
    }
  
       
  function saleTimeOver() public view returns (bool) {
    
    return (phases[noOfPhases-1].endTime != 0);
  }
  
   
   
  function setTiersInfo(uint8 _noOfPhases, uint256[] _startTimes, uint256[] _endTimes, uint256[] _hardCaps ,uint256[] _minEtherContribution, uint8[2] _bonusPercentages)private {
    
    
    require(_noOfPhases == 2);
    
     
    require(_startTimes.length ==  2);
   require(_endTimes.length == _noOfPhases);
    require(_hardCaps.length == _noOfPhases);
    require(_bonusPercentages.length == _noOfPhases);
    
    noOfPhases = _noOfPhases;
    
    for(uint8 i = 0; i < _noOfPhases; i++){

        require(_hardCaps[i] > 0);
       
        if(i>0){

            phases.push(PhaseInfo({
                hardcap:_hardCaps[i],
                startTime:_startTimes[i],
                endTime:_endTimes[i],
                minEtherContribution : _minEtherContribution[i],
                bonusPercentages:_bonusPercentages[i],
                weiRaised:0
            }));
        }
        else{
             
            require(_startTimes[i] > now);
          
            phases.push(PhaseInfo({
                hardcap:_hardCaps[i],
                startTime:_startTimes[i],
                minEtherContribution : _minEtherContribution[i],
                endTime:_endTimes[i],
                bonusPercentages:_bonusPercentages[i],
                weiRaised:0
            }));
        }
    }
  }
  
  
       
    function CLXTokenSale(address _tokenToBeUsed, address _wallet)public nonZeroAddress(_tokenToBeUsed) nonZeroAddress(_wallet){
        
        token = Token(_tokenToBeUsed);
        vault = new Vault(_wallet);
        
        uint256[] memory startTimes = new uint256[](2);
        uint256[] memory endTimes = new uint256[](2);
        uint256[] memory hardCaps = new uint256[](2);
        uint256[] memory minEtherContribution = new uint256[](2);
        uint8[2] memory bonusPercentages;
        
         
        startTimes[0] = 1525910400;  
        endTimes[0] = 0;  
        hardCaps[0] = 7500 ether;
        minEtherContribution[0] = 0.3 ether;
        bonusPercentages[0] = 20;
        
         
        startTimes[1] = 0;  
        endTimes[1] = 0;  
        hardCaps[1] = 12500 ether;
        minEtherContribution[1] = 0.1 ether;
        bonusPercentages[1] = 5;
        
        setTiersInfo(2, startTimes, endTimes, hardCaps, minEtherContribution, bonusPercentages);
        
    }
    
    
   function()public payable{
       buyTokens(msg.sender);
   }

   function startNextPhase() public onlyOwner _saleNotEnded _contractUp _ifNotEmergencyStop returns(bool){

       int8 currentPhaseIndex = getCurrentlyRunningPhase();
       
       require(currentPhaseIndex == 0);

       PhaseInfo storage currentlyRunningPhase = phases[uint256(currentPhaseIndex)];
       
       uint256 tokensLeft;
       uint256 tokensInPreICO = 7200000000000000;  
             
        
       if(currentlyRunningPhase.weiRaised <= 7500 ether) {
           tokensLeft = tokensInPreICO.sub(currentlyRunningPhase.weiRaised.mul(9600).div(10000000000));
           token.transfer(msg.sender, tokensLeft);
       }
       
       phases[0].endTime = now;
       phases[1].startTime = now;

       return true;
       
   }

    
  function finishSale() public onlyOwner _contractUp _saleNotEnded returns (bool){
      
      int8 currentPhaseIndex = getCurrentlyRunningPhase();
      require(currentPhaseIndex == 1);
      
      PhaseInfo storage currentlyRunningPhase = phases[uint256(currentPhaseIndex)];
       
      uint256 tokensLeft;
      uint256 tokensInPublicSale = 10500000000000000;  
          
           
       if(currentlyRunningPhase.weiRaised <= 12500 ether) {
           tokensLeft = tokensInPublicSale.sub(currentlyRunningPhase.weiRaised.mul(8400).div(10000000000));
           token.transfer(msg.sender, tokensLeft);
       }
       
      saleEnded = true;
      
       
      phases[noOfPhases-1].endTime = now;
      
      emit Finished(msg.sender, now);
      return true;
  }

   
    
   function buyTokens(address beneficiary)public _contractUp _saleNotEnded _ifNotEmergencyStop nonZeroAddress(beneficiary) payable returns(bool){
       
       int8 currentPhaseIndex = getCurrentlyRunningPhase();
       assert(currentPhaseIndex >= 0);
       
         
       PhaseInfo storage currentlyRunningPhase = phases[uint256(currentPhaseIndex)];
       
       
       uint256 weiAmount = msg.value;

        
       require(weiAmount.add(currentlyRunningPhase.weiRaised) <= currentlyRunningPhase.hardcap);
       
        
       require(weiAmount >= currentlyRunningPhase.minEtherContribution);
       
       
       uint256 tokens = weiAmount.mul(rate).div(10000000000); 
       
       uint256 bonusedTokens = applyBonus(tokens, currentlyRunningPhase.bonusPercentages);


       totalFunding = totalFunding.add(weiAmount);
             
       currentlyRunningPhase.weiRaised = currentlyRunningPhase.weiRaised.add(weiAmount);
       
       vault.deposit.value(msg.value)(msg.sender);
       
       token.transfer(beneficiary, bonusedTokens);
       
       emit TokenPurchase(msg.sender, beneficiary, weiAmount, bonusedTokens);

       return true;
       
   }
   
     
     function applyBonus(uint256 tokens, uint8 percentage) private pure returns  (uint256) {
         
         uint256 tokensToAdd = 0;
         tokensToAdd = tokens.mul(percentage).div(100);
         return tokens.add(tokensToAdd);
    }
    
    
   function getCurrentlyRunningPhase()public view returns(int8){
      for(uint8 i=0;i<noOfPhases;i++){

          if(phases[i].startTime!=0 && now>=phases[i].startTime && phases[i].endTime == 0){
              return int8(i);
          }
      }   
      return -1;
   }
   
   
    
   function getFundingInfoForUser(address _user)public view nonZeroAddress(_user) returns(uint256){
       return vault.deposited(_user);
   }

    

    function withDrawFunds()public onlyOwner _saleNotEnded _contractUp {
      
       vault.withdrawToWallet();
    }
}
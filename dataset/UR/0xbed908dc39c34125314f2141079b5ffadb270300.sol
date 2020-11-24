 

pragma solidity 0.4.21;


 
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
    function transfer(address _to, uint256 _amount) public returns (bool success);
    function balanceOf(address _owner) public view returns (uint256 balance);
    function decimals()public view returns (uint8);
    function burnAllTokens() public;
}

 
contract Vault is Ownable {
    using SafeMath for uint256;

    enum State { Active, Refunding, Withdraw }

    mapping (address => uint256) public deposited;
    address public wallet;
    State public state;

    event Withdraw();
    event RefundsEnabled();
    event Withdrawn(address _wallet);
    event Refunded(address indexed beneficiary, uint256 weiAmount);
      
    function Vault(address _wallet) public {
        require(_wallet != address(0));
        wallet = _wallet;
        state = State.Active;
    }

    function deposit(address investor) public onlyOwner  payable{
        
        require(state == State.Active || state == State.Withdraw); 
        deposited[investor] = deposited[investor].add(msg.value);
        
    }

    function activateWithdrawal() public onlyOwner {
        if(state == State.Active){
          state = State.Withdraw;
          emit Withdraw();
        }
    }
    
    function activateRefund()public onlyOwner {
        require(state == State.Active);
        state = State.Refunding;
        emit RefundsEnabled();
    }
    
    function withdrawToWallet() onlyOwner public{
    require(state == State.Withdraw);
    wallet.transfer(this.balance);
    emit Withdrawn(wallet);
  }
  
   function refund(address investor) public {
    require(state == State.Refunding);
    uint256 depositedValue = deposited[investor];
    deposited[investor] = 0;
    investor.transfer(depositedValue);
    emit Refunded(investor, depositedValue);
  }
  
 function isRefunding()public onlyOwner view returns(bool) {
     return (state == State.Refunding);
 }
}


contract DroneTokenSale is Ownable{
      using SafeMath for uint256;
      
       
      Token public token;
      
       
      Vault public vault;
  
       
      uint256 public rate = 20000;
       
      struct PhaseInfo{
          uint256 hardcap;
          uint256 startTime;
          uint256 endTime;
          uint8 [3] bonusPercentages; 
          uint256 weiRaised;
      }
      
       
      PhaseInfo[] public phases;
      
       
      uint256 public totalFunding;
      
       
      uint256 tokensAvailableForSale = 3000000000;
      
      
      uint8 public noOfPhases;
      
      
       
      bool public contractUp;
      
       
      bool public saleEnded;
      
       
      event SaleStopped(address _owner, uint256 time);
      
       
      event Finalized(address _owner, uint256 time);
    
      
     event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
    
     
    modifier _contractUp(){
        require(contractUp);
        _;
    }
  
     modifier nonZeroAddress(address _to) {
        require(_to != address(0));
        _;
    }
    
    modifier minEthContribution() {
        require(msg.value >= 0.1 ether);
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
  
    
     
    function powerUpContract() external onlyOwner {
         
        require(!contractUp);

         
        require(token.balanceOf(this) >= tokensAvailableForSale);
        
        
      
         
        contractUp = true;
    }
    
     
    function emergencyStop() external onlyOwner _contractUp _saleNotEnded{
        saleEnded = true;    
        
     if(totalFunding < 10000 ether){
            vault.activateRefund();
        }
        else{
            vault.activateWithdrawal();
        }
        
      emit SaleStopped(msg.sender, now);
    }
    
     
    function finalize()public onlyOwner _contractUp _saleNotEnded{
        require(saleTimeOver());
        
        saleEnded = true;
        
        if(totalFunding < 10000 ether){
            vault.activateRefund();
        }
        else{
            vault.activateWithdrawal();
        }
       
       emit Finalized(msg.sender, now);
    }
    
       
  function saleTimeOver() public view returns (bool) {
    
    return now > phases[noOfPhases-1].endTime;
  }
  
     
  function withdrawFunds() public onlyOwner{
  
      vault.withdrawToWallet();
  }
  
   
  function getRefund()public {
      
      vault.refund(msg.sender);
  }
  
   
  function setTiersInfo(uint8 _noOfPhases, uint256[] _startTimes, uint256[] _endTimes, uint256[] _hardCaps, uint8[3][4] _bonusPercentages)private {
    
    
    require(_noOfPhases==4);
    
     
    require(_startTimes.length == _noOfPhases);
    require(_endTimes.length==_noOfPhases);
    require(_hardCaps.length==_noOfPhases);
    require(_bonusPercentages.length==_noOfPhases);
    
    noOfPhases = _noOfPhases;
    
    for(uint8 i=0;i<_noOfPhases;i++){
        require(_hardCaps[i]>0);
        require(_endTimes[i]>_startTimes[i]);
        if(i>0){
            
        
            
             
            require(_startTimes[i] > _endTimes[i-1]);
            
            phases.push(PhaseInfo({
                hardcap:_hardCaps[i],
                startTime:_startTimes[i],
                endTime:_endTimes[i],
                bonusPercentages:_bonusPercentages[i],
                weiRaised:0
            }));
        }
        else{
             
            require(_startTimes[i]>now);
          
            phases.push(PhaseInfo({
                hardcap:_hardCaps[i],
                startTime:_startTimes[i],
                endTime:_endTimes[i],
                bonusPercentages:_bonusPercentages[i],
                weiRaised:0
            }));
        }
    }
  }
  
  
       
    function DroneTokenSale(address _tokenToBeUsed, address _wallet)public nonZeroAddress(_tokenToBeUsed) nonZeroAddress(_wallet){
        
        token = Token(_tokenToBeUsed);
        vault = new Vault(_wallet);
        
        uint256[] memory startTimes = new uint256[](4);
        uint256[] memory endTimes = new uint256[](4);
        uint256[] memory hardCaps = new uint256[](4);
        uint8[3] [4] memory bonusPercentages;
        
         
        startTimes[0] = 1522321200;  
        endTimes[0] = 1523790000;  
        hardCaps[0] = 10000 ether;
        bonusPercentages[0][0] = 35;
        bonusPercentages[0][1] = 30;
        bonusPercentages[0][2] = 25;
        
         
        startTimes[1] = 1525172460;  
        endTimes[1] = 1526382000;  
        hardCaps[1] = 20000 ether;
        bonusPercentages[1][0] = 25; 
        bonusPercentages[1][1] = 20; 
        bonusPercentages[1][2] = 15; 
        
        
         
        startTimes[2] = 1526382060;  
        endTimes[2] = 1527850800;  
        hardCaps[2] = 30000 ether;
        bonusPercentages[2][0] = 15;
        bonusPercentages[2][1] = 10;
        bonusPercentages[2][2] = 5;
        
         
        startTimes[3] = 1527850860;  
        endTimes[3] = 1533034800;  
        hardCaps[3] = 75000 ether;
        bonusPercentages[3][0] = 0;
        bonusPercentages[3][1] = 0;
        bonusPercentages[3][2] = 0;

        setTiersInfo(4, startTimes, endTimes, hardCaps, bonusPercentages);
        
    }
    

    
   function()public payable{
       buyTokens(msg.sender);
   }
   
    
   function buyTokens(address beneficiary)public _contractUp _saleNotEnded minEthContribution nonZeroAddress(beneficiary) payable returns(bool){
       
       int8 currentPhaseIndex = getCurrentlyRunningPhase();
       assert(currentPhaseIndex>=0);
       
         
       PhaseInfo storage currentlyRunningPhase = phases[uint256(currentPhaseIndex)];
       
       
       uint256 weiAmount = msg.value;

        
       require(weiAmount.add(currentlyRunningPhase.weiRaised) <= currentlyRunningPhase.hardcap);
       
       
       uint256 tokens = weiAmount.mul(rate).div(1000000000000000000); 
       
       uint256 bonusedTokens = applyBonus(tokens, currentlyRunningPhase.bonusPercentages, weiAmount);
       
      
       
      
       totalFunding = totalFunding.add(weiAmount);
       
       currentlyRunningPhase.weiRaised = currentlyRunningPhase.weiRaised.add(weiAmount);
       
       vault.deposit.value(msg.value)(msg.sender);
       
       token.transfer(beneficiary, bonusedTokens);
       
       emit TokenPurchase(msg.sender, beneficiary, weiAmount, bonusedTokens);

       return true;
       
   }
   
     
     function applyBonus(uint256 tokens, uint8 [3]percentages, uint256 weiSent) private pure returns  (uint256) {
         
         uint256 tokensToAdd = 0;
         
         if(weiSent<10 ether){
             tokensToAdd = tokens.mul(percentages[2]).div(100);
         }
         else if(weiSent>=10 ether && weiSent<=100 ether){
              tokensToAdd = tokens.mul(percentages[1]).div(100);
         }
         
         else{
              tokensToAdd = tokens.mul(percentages[0]).div(100);
         }
        
        return tokens.add(tokensToAdd);
    }
    
    
   function getCurrentlyRunningPhase()public view returns(int8){
      for(uint8 i=0;i<noOfPhases;i++){
          if(now>=phases[i].startTime && now<=phases[i].endTime){
              return int8(i);
          }
      }   
      return -1;
   }
   
   
   
    
   function getFundingInfoForUser(address _user)public view nonZeroAddress(_user) returns(uint256){
       return vault.deposited(_user);
   }
   
    
   function isRefunding()public view returns(bool) {
       return vault.isRefunding();
   }
   
    
   function burnRemainingTokens()public onlyOwner _contractUp _saleEnded {
       
       token.burnAllTokens();
   }
   
    
   function activateWithdrawal()public onlyOwner _saleNotEnded _contractUp {
       
       require(totalFunding >= 10000 ether);
       vault.activateWithdrawal();
       
   }
      
}
 

pragma solidity 0.4.24;


 
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


   
  constructor () public {
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
    function transfer(address _to, uint256 _amount) external  returns (bool success);
    function balanceOf(address _owner) external view returns (uint256 balance);
    function decimals()external view returns (uint8);
}

 
contract Vault is Ownable {
    using SafeMath for uint256;

    mapping (address => uint256) public deposited;
    address public wallet;
   
    event Withdrawn(address _wallet);
         
    constructor (address _wallet) public {
        require(_wallet != address(0));
        wallet = _wallet;
    }

    function deposit(address investor) public onlyOwner  payable{
        
        deposited[investor] = deposited[investor].add(msg.value);
        
    }
    
    function withdrawToWallet() onlyOwner public{
    
    wallet.transfer(address(this).balance);
     emit Withdrawn(wallet);
  }
}


contract ESTTokenSale is Ownable{
      using SafeMath for uint256;
      
       
      Token public token;
      
       
      Vault public vault;

      
      mapping(address => bool) public whitelisted;
  
       
      uint256 public rate = 58040000000000;
       
      struct PhaseInfo{
          uint256 cummulativeHardCap;
          uint256 startTime;
          uint256 endTime;
          uint8 bonusPercentages;
          uint256 weiRaised;
      }
      
       
      PhaseInfo[] public phases;
      
       
      uint256 public totalFunding;
      
       
      uint256 tokensAvailableForSale = 45050000000000000;  
      
      
      uint8 public noOfPhases;
      
      
       
      bool public contractUp;
      
       
      bool public saleEnded;
      
       
      event SaleStopped(address _owner, uint256 time);
      
       
      event SaleEnded(address _owner, uint256 time);
      
       
      event LogUserAdded(address user);

       
      event LogUserRemoved(address user);
    
      
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
  
    
     
    function powerUpContract() external onlyOwner {
         
        require(!contractUp);

         
        require(token.balanceOf(this) >= tokensAvailableForSale);
        
         
        contractUp = true;
    }
    
     
    function emergencyStop() external onlyOwner _contractUp _saleNotEnded{
    
      saleEnded = true;    
        
      emit SaleStopped(msg.sender, now);
    }
    
     

   function endSale() public onlyOwner _contractUp _saleNotEnded {

       require(saleTimeOver());

       saleEnded = true;
       emit SaleEnded(msg.sender, now);
   }
    

       
  function saleTimeOver() public view returns (bool) {
    
    return now > phases[noOfPhases-1].endTime;
  }

  
   
  function setTiersInfo(uint8 _noOfPhases, uint256[] _startTimes, uint256[] _endTimes, uint256[] _cummulativeHardCaps, uint8[4] _bonusPercentages)private {
    
    
    require(_noOfPhases == 4);
    
     
    require(_startTimes.length == _noOfPhases);
    require(_endTimes.length ==_noOfPhases);
    require(_cummulativeHardCaps.length ==_noOfPhases);
    require(_bonusPercentages.length ==_noOfPhases);
    
    noOfPhases = _noOfPhases;
    
    for(uint8 i = 0; i < _noOfPhases; i++){
        require(_cummulativeHardCaps[i] > 0);
        require(_endTimes[i] > _startTimes[i]);
        if(i > 0){
            
             
            require(_startTimes[i] > _endTimes[i-1]);
            
            phases.push(PhaseInfo({
                cummulativeHardCap:_cummulativeHardCaps[i],
                startTime:_startTimes[i],
                endTime:_endTimes[i],
                bonusPercentages:_bonusPercentages[i],
                weiRaised:0
            }));
        }
        else{
             
            require(_startTimes[i] > now);
          
            phases.push(PhaseInfo({
                cummulativeHardCap:_cummulativeHardCaps[i],
                startTime:_startTimes[i],
                endTime:_endTimes[i],
                bonusPercentages:_bonusPercentages[i],
                weiRaised:0
            }));
        }
    }
  }
  
  
       
    constructor (address _tokenToBeUsed, address _wallet)public nonZeroAddress(_tokenToBeUsed) nonZeroAddress(_wallet){
        
        token = Token(_tokenToBeUsed);
        vault = new Vault(_wallet);
        
        uint256[] memory startTimes = new uint256[](4);
        uint256[] memory endTimes = new uint256[](4);
        uint256[] memory cummulativeHardCaps = new uint256[](4);
        uint8 [4] memory bonusPercentages;
        
         
        startTimes[0] = 1532044800;  
        endTimes[0] = 1535759999;  
        cummulativeHardCaps[0] = 2107040600000000000000 wei;
        bonusPercentages[0] = 67;
        
         
        startTimes[1] = 1535846400;  
        endTimes[1] = 1539647999;  
        cummulativeHardCaps[1] = 7766345900000000000000 wei;
        bonusPercentages[1] = 33;
        
        
         
        startTimes[2] = 1539648000;  
        endTimes[2] = 1543622399;  
        cummulativeHardCaps[2] = 14180545900000000000000 wei;
        bonusPercentages[2] = 18;
        
         
        startTimes[3] = 1543622400;  
        endTimes[3] = 1546300799;  
        cummulativeHardCaps[3] = 21197987200000000000000 wei;
        bonusPercentages[3] = 8;

        setTiersInfo(4, startTimes, endTimes, cummulativeHardCaps, bonusPercentages);
        
    }
    

    
   function()public payable{
       buyTokens(msg.sender);
   }
   
   function getFundingInfoOfPhase(uint8 phase) public view returns (uint256){
       
       PhaseInfo storage currentlyRunningPhase = phases[uint256(phase)];
       
       return currentlyRunningPhase.weiRaised;
       
   } 
   
    
   function buyTokens(address beneficiary)public _contractUp _saleNotEnded nonZeroAddress(beneficiary) payable returns(bool){
       
       require(whitelisted[beneficiary]);

       int8 currentPhaseIndex = getCurrentlyRunningPhase();
       assert(currentPhaseIndex >= 0);
       
         
       PhaseInfo storage currentlyRunningPhase = phases[uint256(currentPhaseIndex)];
       
       
       uint256 weiAmount = msg.value;

        
       require(weiAmount.add(totalFunding) <= currentlyRunningPhase.cummulativeHardCap);
       
       
       uint256 tokens = weiAmount.div(rate).mul(100000000); 
       
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
      for(uint8 i = 0; i < noOfPhases; i++){
          if(now >= phases[i].startTime && now <= phases[i].endTime){
              return int8(i);
          }
      }   
      return -1;
   }
   
    
   function addUser(address user) public nonZeroAddress(user) onlyOwner returns (bool) {

       require(whitelisted[user] == false);
       
       whitelisted[user] = true;

       emit LogUserAdded(user);
       
       return true;

    }

     
    function removeUser(address user) public nonZeroAddress(user) onlyOwner returns(bool){
      
        require(whitelisted[user] = true);

        whitelisted[user] = false;
        
        emit LogUserRemoved(user);
        
        return true;


    }

     
    function addManyUsers(address[] users)public onlyOwner {
        
        require(users.length < 100);

        for (uint8 index = 0; index < users.length; index++) {

             whitelisted[users[index]] = true;

             emit LogUserAdded(users[index]);

        }
    }

      
    function checkUser(address user) onlyOwner public view  returns (bool){
        return whitelisted[user];
    }
   
    
   function getFundingInfoForUser(address _user)public view nonZeroAddress(_user) returns(uint256){
       return vault.deposited(_user);
   }
   
   
    
   function transferRemainingTokens()public onlyOwner _contractUp _saleEnded {
       
       token.transfer(msg.sender,address(this).balance);
      
   }
   
    
   function tokensLeftForSale() public view returns (uint256){
       return token.balanceOf(address(this));
   }
   
    
   function checkUserTokenBalance(address _user) public view returns(uint256) {
       return token.balanceOf(_user);
   }
   
    
   function tokensSold() public view returns (uint256) {
       return tokensAvailableForSale.sub(token.balanceOf(address(this)));
   }
   
    
   function withDrawFunds()public onlyOwner _contractUp {
      
       vault.withdrawToWallet();
    }
      
}
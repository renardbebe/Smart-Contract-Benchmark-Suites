 

pragma solidity ^0.4.24;

 

contract CloneWars {
    using SafeMath for uint;
    
     
    
    event MarketBoost(
        uint amountSent  
    );
    
    event NorsefireSwitch(
        address from,
        address to,
        uint price
    );
    
     
    
    uint256 public clones_to_create_one_idea = 2 days;
    uint256 public starting_clones           = 232;
    uint256        PSN                       = 10000;
    uint256        PSNH                      = 5000;
    address        actualNorse               = 0x4F4eBF556CFDc21c3424F85ff6572C77c514Fcae;
    
     
    uint256 public marketIdeas;
    uint256 public norsefirePrice;
    bool    public initialized;
    address public currentNorsefire;
    mapping (address => uint256) public arrayOfClones;
    mapping (address => uint256) public claimedIdeas;
    mapping (address => uint256) public lastDeploy;
    mapping (address => address) public referrals;
    
    constructor () public {
        initialized      = false;
        norsefirePrice   = 0.1 ether;
        currentNorsefire = 0x4d63d933BFd882cB0A9D73f7bA4318DDF3e244B0;
    }
    
    function becomeNorsefire() public payable {
        require(initialized);
        address oldNorseAddr = currentNorsefire;
        uint oldNorsePrice   = norsefirePrice;
        norsefirePrice       = oldNorsePrice.add(oldNorsePrice.div(10));
        
        require(msg.value >= norsefirePrice);
        
        uint excess          = msg.value.sub(norsefirePrice);
        uint diffFivePct     = (norsefirePrice.sub(oldNorsePrice)).div(20);
        uint flipPrize       = diffFivePct.mul(10);
        uint marketBoost     = diffFivePct.mul(9);
        address _newNorse    = msg.sender;
        uint    _toRefund    = (oldNorsePrice.add(flipPrize)).add(excess);
        currentNorsefire     = _newNorse;
        oldNorseAddr.transfer(_toRefund);
        actualNorse.transfer(diffFivePct);
        boostCloneMarket(marketBoost);
        emit NorsefireSwitch(oldNorseAddr, _newNorse, norsefirePrice);
    }
    
    function boostCloneMarket(uint _eth) public payable {
        require(initialized);
        emit MarketBoost(_eth);
    }
    
    function deployIdeas(address ref) public{
        
        require(initialized);
        
        address _deployer = msg.sender;
        
        if(referrals[_deployer] == 0 && referrals[_deployer] != _deployer){
            referrals[_deployer]=ref;
        }
        
        uint256 myIdeas          = getMyIdeas();
        uint256 newIdeas         = myIdeas.div(clones_to_create_one_idea);
        arrayOfClones[_deployer] = arrayOfClones[_deployer].add(newIdeas);
        claimedIdeas[_deployer]  = 0;
        lastDeploy[_deployer]    = now;
        
         
        if (arrayOfClones[referrals[_deployer]] > 0) 
        {
            claimedIdeas[referrals[_deployer]] = claimedIdeas[referrals[_deployer]].add(myIdeas.div(20));
        }
        
         
        marketIdeas = marketIdeas.add(myIdeas.div(10));
    }
    
    function sellIdeas() public {
        require(initialized);
        
        address _caller = msg.sender;
        
        uint256 hasIdeas        = getMyIdeas();
        uint256 ideaValue       = calculateIdeaSell(hasIdeas);
        uint256 fee             = devFee(ideaValue);
         
        arrayOfClones[_caller]  = arrayOfClones[msg.sender].div(4);
        claimedIdeas[_caller]   = 0;
        lastDeploy[_caller]     = now;
        marketIdeas             = marketIdeas.add(hasIdeas);
        currentNorsefire.transfer(fee);
        _caller.transfer(ideaValue.sub(fee));
    }
    
    function buyIdeas() public payable{
        require(initialized);
        address _buyer       = msg.sender;
        uint    _sent        = msg.value;
        uint256 ideasBought  = calculateIdeaBuy(_sent, SafeMath.sub(address(this).balance,_sent));
        ideasBought          = ideasBought.sub(devFee(ideasBought));
        currentNorsefire.transfer(devFee(_sent));
        claimedIdeas[_buyer] = claimedIdeas[_buyer].add(ideasBought);
    }

    function calculateTrade(uint256 rt,uint256 rs, uint256 bs) public view returns(uint256){
        return SafeMath.div(SafeMath.mul(PSN,bs),SafeMath.add(PSNH,SafeMath.div(SafeMath.add(SafeMath.mul(PSN,rs),SafeMath.mul(PSNH,rt)),rt)));
    }
    
    function calculateIdeaSell(uint256 _ideas) public view returns(uint256){
        return calculateTrade(_ideas,marketIdeas,address(this).balance);
    }
    
    function calculateIdeaBuy(uint256 eth,uint256 _balance) public view returns(uint256){
        return calculateTrade(eth, _balance, marketIdeas);
    }
    function calculateIdeaBuySimple(uint256 eth) public view returns(uint256){
        return calculateIdeaBuy(eth,address(this).balance);
    }
    
    function devFee(uint256 amount) public pure returns(uint256){
        return amount.mul(4).div(100);
    }
    
    function releaseTheOriginal(uint256 _ideas) public payable {
        require(msg.sender  == currentNorsefire);
        require(marketIdeas == 0);
        initialized         = true;
        marketIdeas         = _ideas;
        boostCloneMarket(msg.value);
    }
    
    function hijackClones() public payable{
        require(initialized);
        require(msg.value==0.00232 ether);  
        address _caller        = msg.sender;
        currentNorsefire.transfer(msg.value);  
        require(arrayOfClones[_caller]==0);
        lastDeploy[_caller]    = now;
        arrayOfClones[_caller] = starting_clones;
    }
    
    function getBalance() public view returns(uint256){
        return address(this).balance;
    }
    
    function getMyClones() public view returns(uint256){
        return arrayOfClones[msg.sender];
    }
    
    function getNorsefirePrice() public view returns(uint256){
        return norsefirePrice;
    }
    
    function getMyIdeas() public view returns(uint256){
        address _caller = msg.sender;
        return claimedIdeas[_caller].add(getIdeasSinceLastDeploy(_caller));
    }
    
    function getIdeasSinceLastDeploy(address adr) public view returns(uint256){
        uint256 secondsPassed=min(clones_to_create_one_idea, now.sub(lastDeploy[adr]));
        return secondsPassed.mul(arrayOfClones[adr]);
    }
    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
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
}
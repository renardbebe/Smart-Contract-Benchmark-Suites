 

pragma solidity ^0.4.18;

 
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

  function Ownable() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  } 

  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    owner = newOwner;
  }
}

contract LoveToken {
  function transfer(address _to, uint256 _value) public returns (bool);
  function balanceOf(address _owner) public view returns (uint256 balance);
  function freeze(address target) public returns (bool);
  function release(address target) public returns (bool);
}

contract LoveContribution is Ownable {

  using SafeMath for uint256;

   
  LoveToken  token;
  
   
  mapping(address => uint256) public contributionOf;
  
   
  address[] contributors;
  
   
   address[] topWinners=[address(0),address(0),address(0),address(0),address(0),address(0),address(0),address(0),address(0),address(0),address(0)];
  
   
  address[] randomWinners;
  
   
  mapping(address => uint256) public amountWon;
  
   
  mapping(address => bool) public claimed;
  
   
  mapping(address => bool) public KYCDone;

   
  uint256 public startTime;
  uint256 public endTime;

   
  uint256 public rate = 10e14;

   
  uint256 public weiRaised;
  
   
  uint256 public ownerWithdrawn;
  
  event contributionSuccessful(address indexed contributedBy, uint256 contribution, uint256 tokenReceived);
  event FundTransfer(address indexed beneficiary, uint256 amount);
  event FundTransferFailed();
  event KYCApproved(address indexed contributor);

  function LoveContribution(uint256 _startTime, uint256 _endTime, LoveToken  _token) public {
    require(_startTime >= now);
    require(_endTime >= _startTime);
    require(_token != address(0));

    startTime = _startTime;
    endTime = _endTime;
    token = _token;
  }

   
  function () external payable {
    contribute();
  }
    
   
   
  function contribute() internal {
    uint256 weiAmount = msg.value;
    require(msg.sender != address(0) && weiAmount >= 5e15);
    require(now >= startTime && now <= endTime);
    
     
    uint256 numToken = getTokenAmount(weiAmount).mul(10 ** 8);
    
     
    require(token.balanceOf(this).sub(numToken) > 0 );
    
     
    if(contributionOf[msg.sender] <= 0){
        contributors.push(msg.sender);
        token.freeze(msg.sender);
    }
    
    contributionOf[msg.sender] = contributionOf[msg.sender].add(weiAmount);
    
    token.transfer(msg.sender, numToken);
    
    weiRaised = weiRaised.add(weiAmount);
    
    updateWinnersList();
    
    contributionSuccessful(msg.sender,weiAmount,numToken);
  }

   
  function getTokenAmount(uint256 weiAmount) internal returns(uint256) {
       uint256 tokenAmount;
       
        if(weiRaised <= 100 ether){
            rate = 10e14;
            tokenAmount = weiAmount.div(rate);
            return tokenAmount;
        }
        else if(weiRaised > 100 ether && weiRaised <= 150 ether){
            rate = 15e14;
            tokenAmount = weiAmount.div(rate);
            return tokenAmount;
        }
        else if(weiRaised > 150 ether && weiRaised <= 200 ether){
            rate = 20e14;
            tokenAmount = weiAmount.div(rate);
            return tokenAmount;
        }
        else if(weiRaised > 200 ether && weiRaised <= 250 ether){
            rate = 25e14;
            tokenAmount = weiAmount.div(rate);
            return tokenAmount;
        }
        else if(weiRaised > 250){
            rate = 30e14;
            tokenAmount = weiAmount.div(rate);
            return tokenAmount;
        }
        
  }
  
   
  function updateWinnersList() internal returns(bool) {
      if(topWinners[0] != msg.sender){
       bool flag=false;
       for(uint256 i = 0; i < 10; i++){
           if(topWinners[i] == msg.sender){
               break;
           }
           if(contributionOf[msg.sender] > contributionOf[topWinners[i]]){
               flag=true;
               break;
           }
       }
       if(flag == true){
           for(uint256 j = 10; j > i; j--){
               if(topWinners[j-1] != msg.sender){
                   topWinners[j]=topWinners[j-1];
               }
               else{
                   for(uint256 k = j; k < 10; k++){
                       topWinners[k]=topWinners[k+1];
                   }
               }
            }
            topWinners[i]=msg.sender;
       }
       return true;
     }
  }

   
  function hasEnded() public view returns (bool) {
    return (now > endTime) ;
  }
  
   
  function findWinners() public onlyOwner {
    require(now >= endTime);
    
     
    uint256 len=contributors.length;
    
     
    uint256 mulFactor=50;
    
     
    for(uint256 num = 0; num < 10 && num < len; num++){
      amountWon[topWinners[num]]=(weiRaised.div(1000)).mul(mulFactor);
      mulFactor=mulFactor.sub(5);
     }
     topWinners.length--;
       
     
    if(len > 10 && len <= 20 ){
        for(num = 0 ; num < 20 && num < len; num++){
            if(amountWon[contributors[num]] <= 0){
            randomWinners.push(contributors[num]);
            amountWon[contributors[num]]=(weiRaised.div(1000)).mul(3);
            }
        }
    }
    else if(len > 20){
        for(uint256 i = 0 ; i < 10; i++){
             
            uint256 randomNo=random(i+1) % len;
             
            if(amountWon[contributors[randomNo]] <= 0){
                randomWinners.push(contributors[randomNo]);
                amountWon[contributors[randomNo]]=(weiRaised.div(1000)).mul(3);
            }
            else{
                
                for(uint256 j = 0; j < len; j++){
                    randomNo=(randomNo.add(1)) % len;
                    if(amountWon[contributors[randomNo]] <= 0){
                        randomWinners.push(contributors[randomNo]);
                        amountWon[contributors[randomNo]]=(weiRaised.div(1000)).mul(3);
                        break;
                    }
                }
            }
        }    
    }
  }
  
    
   
   function random(uint256 count) internal constant returns (uint256) {
    uint256 rand = block.number.mul(count);
    return rand;
  }
  
   
  function stop() public onlyOwner  {
    endTime = now ;
  }
  
   
  function ownerWithdrawal(uint256 amt) public onlyOwner  {
     
    require((amt.add(ownerWithdrawn)) <= (weiRaised.div(100)).mul(70));
    if (owner.send(amt)) {
        ownerWithdrawn=ownerWithdrawn.add(amt);
        FundTransfer(owner, amt);
    }
  }
  
   
  function KYCApprove(address[] contributorsList) public onlyOwner  {
    for (uint256 i = 0; i < contributorsList.length; i++) {
        address addr=contributorsList[i];
         
        KYCDone[addr]=true;
        KYCApproved(addr);
        token.release(addr);
    }
  }
  
   
  function winnerWithdrawal() public {
    require(now >= endTime);
     
    require(amountWon[msg.sender] > 0);
     
    require(KYCDone[msg.sender]);
     
    require(!claimed[msg.sender]);

    if (msg.sender.send(amountWon[msg.sender])) {
        claimed[msg.sender]=true;
        FundTransfer(msg.sender,amountWon[msg.sender] );
    }
  }
  
   
  function tokensAvailable()public view returns (uint256) {
    return token.balanceOf(this);
  }
  
   
  function showTopWinners() public view returns (address[]) {
    require(now >= endTime);
        return (topWinners);
  }
  
   
  function showRandomWinners() public view returns (address[]) {
    require(now >= endTime);
        return (randomWinners);
  }
  
   
  function destroy() public onlyOwner {
    require(now >= endTime);
    uint256 balance= this.balance;
    owner.transfer(balance);
    FundTransfer(owner, balance);
    uint256 balanceToken = tokensAvailable();
    token.transfer(owner, balanceToken);
    selfdestruct(owner);
  }
}
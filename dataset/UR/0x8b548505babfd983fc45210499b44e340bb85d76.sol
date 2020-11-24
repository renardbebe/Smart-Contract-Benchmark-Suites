 

pragma solidity ^0.4.19;

 
 
 

 
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
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}



 
contract Syndicate is Ownable{

    uint256 public totalSyndicateShares = 20000;
    uint256 public availableEarlyPlayerShares = 5000;
    uint256 public availableBuyInShares = 5000;
    uint256 public minimumBuyIn = 10;
    uint256 public buyInSharePrice = 500000000000000;  
    uint256 public shareCycleSessionSize = 1000;  
    uint256 public shareCycleIndex = 0;  
    uint256 public currentSyndicateValue = 0;  
    uint256 public numberSyndicateMembers = 0;
    uint256 public syndicatePrecision = 1000000000000000;

    struct member {
        uint256 numShares;
        uint256 profitShare;
     }

    address[] private syndicateMembers;
    mapping(address => member ) private members;

    event ProfitShare(
          uint256 _currentSyndicateValue,
          uint256 _numberSyndicateMembers,
          uint256 _totalOwnedShares,
          uint256 _profitPerShare
    );

    function Syndicate() public {
        members[msg.sender].numShares = 10000;  
        members[msg.sender].profitShare = 0;
        numberSyndicateMembers = 1;
        syndicateMembers.push(msg.sender);
    }

     
    function claimProfit() public {
      if (members[msg.sender].numShares==0) revert();  
      uint256 profitShare = members[msg.sender].profitShare;
      if (profitShare>0){
        members[msg.sender].profitShare = 0;
        msg.sender.transfer(profitShare);
      }
    }

     
    function distributeProfit() internal {

      uint256 totalOwnedShares = totalSyndicateShares-(availableEarlyPlayerShares+availableBuyInShares);
      uint256 profitPerShare = SafeMath.div(currentSyndicateValue,totalOwnedShares);

       
      for(uint i = 0; i< numberSyndicateMembers; i++)
      {
         
        members[syndicateMembers[i]].profitShare+=SafeMath.mul(members[syndicateMembers[i]].numShares,profitPerShare);
      }

       
      ProfitShare(currentSyndicateValue, numberSyndicateMembers, totalOwnedShares , profitPerShare);

      currentSyndicateValue=0;  
      shareCycleIndex = 0;  
    }

     
    function allocateEarlyPlayerShare() internal {
        if (availableEarlyPlayerShares==0) return;
		    availableEarlyPlayerShares--;
       	addMember();  
        members[msg.sender].numShares+=1;

    }

     
    function addMember() internal {
    	 if (members[msg.sender].numShares == 0){
		          syndicateMembers.push(msg.sender);
		          numberSyndicateMembers++;
		    }
    }

     
    function buyIntoSyndicate() public payable  {
    		if(msg.value==0 || availableBuyInShares==0) revert();
      		if(msg.value < minimumBuyIn*buyInSharePrice) revert();

     		uint256 value = (msg.value/syndicatePrecision)*syndicatePrecision;  
		    uint256 allocation = value/buyInSharePrice;

		    if (allocation >= availableBuyInShares){
		        allocation = availableBuyInShares;  
		    }
		    availableBuyInShares-=allocation;
		    addMember();  
	      members[msg.sender].numShares+=allocation;

    }

     
    function memberShareCount() public  view returns (uint256) {
        return members[msg.sender].numShares;
    }

     
    function memberProfitShare() public  view returns (uint256) {
        return members[msg.sender].profitShare;
    }

}


 
contract Hedgely is Ownable, Syndicate {

    
   address[] private players;
   mapping(address => bool) private activePlayers;
   uint256 numPlayers = 0;

    
   mapping(address => uint256 [10] ) private playerPortfolio;

   uint256 public totalHedgelyWinnings;
   uint256 public totalHedgelyInvested;

   uint256[10] private marketOptions;

    
   uint256 public totalInvested;
    
   uint256 private seedInvestment;

    
   uint256 public numberOfInvestments;

    
   uint256 public numberWinner;

    
   uint256 public startingBlock;
   uint256 public endingBlock;
   uint256 public sessionBlockSize;
   uint256 public sessionNumber;
   uint256 public currentLowest;
   uint256 public currentLowestCount;  

   uint256 public precision = 1000000000000000;  
   uint256 public minimumStake = 1 finney;

     event Invest(
           address _from,
           uint256 _option,
           uint256 _value,
           uint256[10] _marketOptions,
           uint _blockNumber
     );

     event EndSession(
           uint256 _sessionNumber,
           uint256 _winningOption,
           uint256[10] _marketOptions,
           uint256 _blockNumber
     );

     event StartSession(
           uint256 _sessionNumber,
           uint256 _sessionBlockSize,
           uint256[10] _marketOptions,
           uint256 _blockNumber
     );

    bool locked;
    modifier noReentrancy() {
        require(!locked);
        locked = true;
        _;
        locked = false;
    }

   function Hedgely() public {
     owner = msg.sender;
     sessionBlockSize = 100;
     sessionNumber = 0;
     totalHedgelyWinnings = 0;
     totalHedgelyInvested = 0;
     numPlayers = 0;
     resetMarket();
   }

     
   function getMarketOptions() public constant returns (uint256[10])
    {
        return marketOptions;
    }

     
   function getPlayerPortfolio() public constant returns (uint256[10])
    {
        return playerPortfolio[msg.sender];
    }

     
    function numberOfInvestors() public constant returns(uint count) {
        return numPlayers;
    }

     
    function rand() internal returns (uint64) {
      return random(19)+1;
    }

     
    uint64 _seed = 0;
    function random(uint64 upper) private returns (uint64 randomNumber) {
       _seed = uint64(keccak256(keccak256(block.blockhash(block.number), _seed), now));
       return _seed % upper;
     }

     
   function resetMarket() internal {

    sessionNumber ++;
    startingBlock = block.number;
    endingBlock = startingBlock + sessionBlockSize;  
    numPlayers = 0;

     
    uint256 sumInvested = 0;
    for(uint i=0;i<10;i++)
    {
        uint256 num =  rand();
        marketOptions[i] =num * precision;  
        sumInvested+=  marketOptions[i];
    }

     playerPortfolio[this] = marketOptions;
     totalInvested =  sumInvested;
     seedInvestment = sumInvested;
     insertPlayer(this);
     numPlayers=1;
     numberOfInvestments = 10;

     currentLowest = findCurrentLowest();
     StartSession(sessionNumber, sessionBlockSize, marketOptions , startingBlock);

   }


     
    function roundIt(uint256 amount) internal constant returns (uint256)
    {
         
        uint256 result = (amount/precision)*precision;
        return result;
    }

     
    function invest(uint256 optionNumber) public payable noReentrancy {

       
      assert(optionNumber <= 9);
      uint256 amount = roundIt(msg.value);  
      assert(amount >= minimumStake);

      uint256 holding = playerPortfolio[msg.sender][optionNumber];
      holding = SafeMath.add(holding, amount);
      playerPortfolio[msg.sender][optionNumber] = holding;

      marketOptions[optionNumber] = SafeMath.add(marketOptions[optionNumber],amount);

      numberOfInvestments += 1;
      totalInvested += amount;
      totalHedgelyInvested += amount;
      if (!activePlayers[msg.sender]){
                    insertPlayer(msg.sender);
                    activePlayers[msg.sender]=true;
       }

      Invest(msg.sender, optionNumber, amount, marketOptions, block.number);

       
      allocateEarlyPlayerShare();  

      currentLowest = findCurrentLowest();
      if (block.number >= endingBlock && currentLowestCount==1) distributeWinnings();

    }  


     
    function findCurrentLowest() internal returns (uint lowestOption) {

      uint winner = 0;
      uint lowestTotal = marketOptions[0];
      currentLowestCount = 0;
      for(uint i=0;i<10;i++)
      {
          if (marketOptions [i]<lowestTotal){
              winner = i;
              lowestTotal = marketOptions [i];
              currentLowestCount = 0;
          }
         if (marketOptions [i]==lowestTotal){currentLowestCount+=1;}
      }
      return winner;
    }

     
    function distributeWinnings() internal {

      if (currentLowestCount>1){
      return;  
      }

      numberWinner = currentLowest;

       
      EndSession(sessionNumber, numberWinner, marketOptions , block.number);

      uint256 sessionWinnings = 0;
      for(uint j=1;j<numPlayers;j++)
      {
      if (playerPortfolio[players[j]][numberWinner]>0){
        uint256 winningAmount =  playerPortfolio[players[j]][numberWinner];
        uint256 winnings = SafeMath.mul(8,winningAmount);  
        totalHedgelyWinnings+=winnings;
        sessionWinnings+=winnings;
        players[j].transfer(winnings);  
      }

      playerPortfolio[players[j]] = [0,0,0,0,0,0,0,0,0,0];
      activePlayers[players[j]]=false;

      }

      uint256 playerInvestments = totalInvested-seedInvestment;

      if (sessionWinnings>playerInvestments){
        uint256 loss = sessionWinnings-playerInvestments;  
        if (currentSyndicateValue>=loss){
          currentSyndicateValue-=loss;
        }else{
          currentSyndicateValue = 0;
        }
      }

      if (playerInvestments>sessionWinnings){
        currentSyndicateValue+=playerInvestments-sessionWinnings;  
      }

       
      shareCycleIndex+=1;
      if (shareCycleIndex >= shareCycleSessionSize){
        distributeProfit();
      }

      resetMarket();
    }  


     
    function insertPlayer(address value) internal {
        if(numPlayers == players.length) {
            players.length += 1;
        }
        players[numPlayers++] = value;
    }

    
    function setsessionBlockSize (uint256 blockCount) public onlyOwner {
        sessionBlockSize = blockCount;
    }

     

    function withdraw(uint256 amount) public onlyOwner {
        require(amount<=this.balance);
        if (amount==0){
            amount=this.balance;
        }
        owner.transfer(amount);
    }


    
    function kill()  public onlyOwner {
         if(msg.sender == owner)
            selfdestruct(owner);
    }

     
     function() public payable {}


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
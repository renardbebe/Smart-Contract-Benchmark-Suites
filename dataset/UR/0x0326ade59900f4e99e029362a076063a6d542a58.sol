 

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



 
contract Hedgely is Ownable {

    uint256 public numberSyndicateMembers;
    uint256 public totalSyndicateShares = 20000;
    uint256 public playersShareAllocation = 5000;  
    uint256 public availableBuyInShares = 5000;  
    uint256 public minimumBuyIn = 10;
    uint256 public buyInSharePrice = 1000000000000000;  
    uint256 public shareCycleSessionSize = 1000;  
    uint256 public shareCycleIndex = 0;  
    uint256 public shareCycle = 1;
    uint256 public currentSyndicateValue = 150000000000000000;  

     
     
    uint256 public maxCyclePlayersConsidered = 100;

    address[] public cyclePlayers;  
    uint256 public numberOfCyclePlayers = 0;

    struct somePlayer {
        uint256 playCount;
        uint256 profitShare;  
        uint256 shareCycle;  
        uint256 winnings;  
     }

    mapping(address => somePlayer ) private allPlayers;  

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

    event Invest(
          address _from,
          uint256 _option,
          uint256 _value,
          uint256[10] _marketOptions,
          uint _blockNumber
    );

    event Winning(
          address _to,
          uint256 _amount,
          uint256 _session,
          uint256 _winningOption,
          uint _blockNumber
    );

    event EndSession(
          address _sessionEnder,
          uint256 _sessionNumber,
          uint256 _winningOption,
          uint256[10] _marketOptions,
          uint256 _blockNumber
    );

    event StartSession(
          uint256 _sessionNumber,
          uint256 _sessionEndTime,
          uint256[10] _marketOptions,
          uint256 _blockNumber
    );


     
    function claimProfit() public {
      if (members[msg.sender].numShares==0) revert();
      uint256 profitShare = members[msg.sender].profitShare;
      if (profitShare>0){
        members[msg.sender].profitShare = 0;
        msg.sender.transfer(profitShare);
      }
    }

     
    function claimPlayerProfit() public {
      if (allPlayers[msg.sender].profitShare==0) revert();
      uint256 profitShare = allPlayers[msg.sender].profitShare;
      if (profitShare>0){
        allPlayers[msg.sender].profitShare = 0;
        msg.sender.transfer(profitShare);
      }
    }

     
    function claimPlayerWinnings() public {
      if (allPlayers[msg.sender].winnings==0) revert();
      uint256 winnings = allPlayers[msg.sender].winnings;

      if (now > sessionEndTime && playerPortfolio[msg.sender][currentLowest]>0){
           
         winnings+= SafeMath.mul(playerPortfolio[msg.sender][currentLowest],winningMultiplier);
         playerPortfolio[msg.sender][currentLowest]=0;
      }

      if (winnings>0){
        allPlayers[msg.sender].winnings = 0;
        msg.sender.transfer(winnings);
      }
    }

     
    function allocateWinnings(address _playerAddress, uint256 winnings) internal {
      allPlayers[_playerAddress].winnings+=winnings;
    }

     
    function roundIt(uint256 amount) internal constant returns (uint256)
    {
         
        uint256 result = (amount/precision)*precision;
        return result;
    }

     
    function distributeProfit() internal {

      uint256 totalOwnedShares = totalSyndicateShares-(playersShareAllocation+availableBuyInShares);
      uint256 profitPerShare = SafeMath.div(currentSyndicateValue,totalOwnedShares);

      if (profitPerShare>0){
           
          for(uint i = 0; i< numberSyndicateMembers; i++)
          {
             
            members[syndicateMembers[i]].profitShare+=SafeMath.mul(members[syndicateMembers[i]].numShares,profitPerShare);
          }
      }  

      uint256 topPlayerDistributableProfit =  SafeMath.div(currentSyndicateValue,4);  
       
      uint256 numberOfRecipients = min(numberOfCyclePlayers,10);  
      uint256 profitPerTopPlayer = roundIt(SafeMath.div(topPlayerDistributableProfit,numberOfRecipients));

      if (profitPerTopPlayer>0){

           
          address[] memory arr = new address[](numberOfCyclePlayers);

           
          for(i=0; i<numberOfCyclePlayers && i<maxCyclePlayersConsidered; i++) {
            arr[i] = cyclePlayers[i];
          }
          address key;
          uint j;
          for(i = 1; i < arr.length; i++ ) {
            key = arr[i];

            for(j = i; j > 0 && allPlayers[arr[j-1]].playCount > allPlayers[key].playCount; j-- ) {
              arr[j] = arr[j-1];
            }
            arr[j] = key;
          }   

           

           
          for(i = 0; i< numberOfRecipients; i++)
          {
             
            if (arr[i]!=0) {  
              allPlayers[arr[i]].profitShare+=profitPerTopPlayer;
            }
          }  

      }  


       
      ProfitShare(currentSyndicateValue, numberSyndicateMembers, totalOwnedShares , profitPerShare);

       
      numberOfCyclePlayers=0;
      currentSyndicateValue=0;
      shareCycleIndex = 1;
      shareCycle++;
    }

     
    function updatePlayCount() internal{
       
      if(allPlayers[msg.sender].shareCycle!=shareCycle){
          allPlayers[msg.sender].playCount=0;
          allPlayers[msg.sender].shareCycle=shareCycle;
          insertCyclePlayer();
      }
        allPlayers[msg.sender].playCount++;
         
    }

     
    function insertCyclePlayer() internal {
        if(numberOfCyclePlayers == cyclePlayers.length) {
            cyclePlayers.length += 1;
        }
        cyclePlayers[numberOfCyclePlayers++] = msg.sender;
    }

     
    function addMember(address _memberAddress) internal {
       if (members[_memberAddress].numShares == 0){
              syndicateMembers.push(_memberAddress);
              numberSyndicateMembers++;
        }
    }

     
    function buyIntoSyndicate() public payable  {
        if(msg.value==0 || availableBuyInShares==0) revert();
        if(msg.value < minimumBuyIn*buyInSharePrice) revert();

        uint256 value = (msg.value/precision)*precision;  
        uint256 allocation = value/buyInSharePrice;

        if (allocation >= availableBuyInShares){
            allocation = availableBuyInShares;  
        }
        availableBuyInShares-=allocation;
        addMember(msg.sender);  
        members[msg.sender].numShares+=allocation;
    }

     
    function memberShareCount() public  view returns (uint256) {
        return members[msg.sender].numShares;
    }

     
    function memberProfitShare() public  view returns (uint256) {
        return members[msg.sender].profitShare;
    }

     
    function allocateShares(uint256 allocation, address stakeholderAddress)  public onlyOwner {
        if (allocation > availableBuyInShares) revert();
        availableBuyInShares-=allocation;
        addMember(stakeholderAddress);  
        members[stakeholderAddress].numShares+=allocation;
    }

    function setShareCycleSessionSize (uint256 size) public onlyOwner {
        shareCycleSessionSize = size;
    }

    function setMaxCyclePlayersConsidered (uint256 numPlayersConsidered) public onlyOwner {
        maxCyclePlayersConsidered = numPlayersConsidered;
    }

     
     
    function playerStatus(address _playerAddress) public constant returns(uint256, uint256, uint256, uint256) {
         uint256 playCount = allPlayers[_playerAddress].playCount;
         if (allPlayers[_playerAddress].shareCycle!=shareCycle){playCount=0;}
         uint256 winnings = allPlayers[_playerAddress].winnings;
           if (now >sessionEndTime){
              
              winnings+=  SafeMath.mul(playerPortfolio[_playerAddress][currentLowest],winningMultiplier);
           }
        return (playCount, allPlayers[_playerAddress].shareCycle, allPlayers[_playerAddress].profitShare , winnings);
    }

    function min(uint a, uint b) private pure returns (uint) {
           return a < b ? a : b;
    }


    
   address[] private players;
   mapping(address => bool) private activePlayers;
   uint256 numPlayers = 0;

    
   mapping(address => uint256 [10] ) private playerPortfolio;

   uint256[10] private marketOptions;

    
   uint256 public totalInvested;
    
   uint256 private seedInvestment;

    
   uint256 public numberOfInvestments;

    
   uint256 public numberWinner;

    
   uint256 public sessionNumber;
   uint256 public currentLowest;
   uint256 public currentLowestCount;  

   uint256 public precision = 1000000000000000;  
   uint256 public minimumStake = 1 finney;

   uint256 public winningMultiplier;  

   uint256 public sessionDuration = 20 minutes;
   uint256 public sessionEndTime = 0;

   function Hedgely() public {
     owner = msg.sender;
     members[msg.sender].numShares = 10000;  
     members[msg.sender].profitShare = 0;
     numberSyndicateMembers = 1;
     syndicateMembers.push(msg.sender);
     sessionNumber = 0;
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


     
    uint64 _seed = 0;
    function random(uint64 upper) private returns (uint64 randomNumber) {
       _seed = uint64(keccak256(keccak256(block.blockhash(block.number), _seed), now));
       return _seed % upper;
     }

     
   function resetMarket() internal {

      
     shareCycleIndex+=1;
     if (shareCycleIndex > shareCycleSessionSize){
       distributeProfit();
     }

    sessionNumber ++;
    winningMultiplier = 8;  
    numPlayers = 0;

     
    uint256 sumInvested = 0;
    uint256[10] memory startingOptions;

     
     
    startingOptions[0]=0;
    startingOptions[1]=0;
    startingOptions[2]=0;
    startingOptions[3]=precision*(random(2));  
    startingOptions[4]=precision*(random(3)+1);  
    startingOptions[5]=precision*(random(2)+3);  
    startingOptions[6]=precision*(random(3)+4);  
    startingOptions[7]=precision*(random(3)+5);  
    startingOptions[8]=precision*(random(3)+8);  
    startingOptions[9]=precision*(random(3)+8);  

     

      uint64 currentIndex = uint64(marketOptions.length);
      uint256 temporaryValue;
      uint64 randomIndex;

       
      while (0 != currentIndex) {

         
        randomIndex = random(currentIndex);
        currentIndex -= 1;

         
        temporaryValue = startingOptions[currentIndex];
        startingOptions[currentIndex] = startingOptions[randomIndex];
        startingOptions[randomIndex] = temporaryValue;
      }

     marketOptions = startingOptions;
     playerPortfolio[this] = marketOptions;
     totalInvested =  sumInvested;
     seedInvestment = sumInvested;
     insertPlayer(this);
     numPlayers=1;
     numberOfInvestments = 10;

     currentLowest = findCurrentLowest();
     sessionEndTime = now + sessionDuration;
     StartSession(sessionNumber, sessionEndTime, marketOptions , now);

   }


     
    function invest(uint256 optionNumber) public payable {

       
      assert(optionNumber <= 9);
      uint256 amount = roundIt(msg.value);  
      assert(amount >= minimumStake);

        
      if (now> sessionEndTime){
        endSession();
         
        optionNumber = currentLowest;
      }

      uint256 holding = playerPortfolio[msg.sender][optionNumber];
      holding = SafeMath.add(holding, amount);
      playerPortfolio[msg.sender][optionNumber] = holding;

      marketOptions[optionNumber] = SafeMath.add(marketOptions[optionNumber],amount);

      numberOfInvestments += 1;
      totalInvested += amount;
      if (!activePlayers[msg.sender]){
                    insertPlayer(msg.sender);
                    activePlayers[msg.sender]=true;
       }

      Invest(msg.sender, optionNumber, amount, marketOptions, block.number);
      updatePlayCount();  
      currentLowest = findCurrentLowest();

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

     
    function endSession() internal {

      uint256 sessionWinnings = 0;
      if (currentLowestCount>1){
        numberWinner = 10;  
      }else{
        numberWinner = currentLowest;
      }

       
      for(uint j=1;j<numPlayers;j++)
      {
        if (numberWinner<10 && playerPortfolio[players[j]][numberWinner]>0){
          uint256 winningAmount =  playerPortfolio[players[j]][numberWinner];
          uint256 winnings = SafeMath.mul(winningMultiplier,winningAmount);  
          sessionWinnings+=winnings;

          allocateWinnings(players[j],winnings);  

          Winning(players[j], winnings, sessionNumber, numberWinner,block.number);  
        }
        playerPortfolio[players[j]] = [0,0,0,0,0,0,0,0,0,0];
        activePlayers[players[j]]=false;
      }

      EndSession(msg.sender, sessionNumber, numberWinner, marketOptions , block.number);

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
      resetMarket();
    }  


     
    function insertPlayer(address value) internal {
        if(numPlayers == players.length) {
            players.length += 1;
        }
        players[numPlayers++] = value;
    }


     
    function setSessionDurationMinutes (uint256 _m) public onlyOwner {
        sessionDuration = _m * 1 minutes ;
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
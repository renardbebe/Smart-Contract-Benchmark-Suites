 

pragma solidity ^0.4.18;


contract DataSourceInterface {

    function isDataSource() public pure returns (bool);

    function getGroupResult(uint matchId) external;
    function getRoundOfSixteenTeams(uint index) external;
    function getRoundOfSixteenResult(uint matchId) external;
    function getQuarterResult(uint matchId) external;
    function getSemiResult(uint matchId) external;
    function getFinalTeams() external;
    function getYellowCards() external;
    function getRedCards() external;

}


 
contract DataLayer{

    
    uint256 constant WCCTOKEN_CREATION_LIMIT = 5000000;
    uint256 constant STARTING_PRICE = 45 finney;
    
     
    uint256 constant FIRST_PHASE  = 1527476400;
    uint256 constant SECOND_PHASE = 1528081200;
    uint256 constant THIRD_PHASE  = 1528686000;
    uint256 constant WORLD_CUP_START = 1528945200;

    DataSourceInterface public dataSource;
    address public dataSourceAddress;

    address public adminAddress;
    uint256 public deploymentTime = 0;
    uint256 public gameFinishedTime = 0;  
    uint32 public lastCalculatedToken = 0;
    uint256 public pointsLimit = 0;
    uint32 public lastCheckedToken = 0;
    uint32 public winnerCounter = 0;
    uint32 public lastAssigned = 0;
    uint256 public auxWorstPoints = 500000000;
    uint32 public payoutRange = 0;
    uint32 public lastPrizeGiven = 0;
    uint256 public prizePool = 0;
    uint256 public adminPool = 0;
    uint256 public finalizedTime = 0;

    enum teamState { None, ROS, QUARTERS, SEMIS, FINAL }
    enum pointsValidationState { Unstarted, LimitSet, LimitCalculated, OrderChecked, TopWinnersAssigned, WinnersAssigned, Finished }
    
     
    struct Token {
        uint192 groups1;
        uint192 groups2;
        uint160 brackets;
        uint64 timeStamp;
        uint32  extra;
    }

    struct GroupResult{
        uint8 teamOneGoals;
        uint8 teamTwoGoals;
    }

    struct BracketPhase{
        uint8[16] roundOfSixteenTeamsIds;
        mapping (uint8 => bool) teamExists;
        mapping (uint8 => teamState) middlePhaseTeamsIds;
        uint8[4] finalsTeamsIds;
    }

    struct Extras {
        uint16 yellowCards;
        uint16 redCards;
    }

    
     
    Token[] tokens;

    GroupResult[48] groupsResults;
    BracketPhase bracketsResults;
    Extras extraResults;

     
    uint256[] sortedWinners;

     
    uint256[] worstTokens;
    pointsValidationState public pValidationState = pointsValidationState.Unstarted;

    mapping (address => uint256[]) public tokensOfOwnerMap;
    mapping (uint256 => address) public ownerOfTokenMap;
    mapping (uint256 => address) public tokensApprovedMap;
    mapping (uint256 => uint256) public tokenToPayoutMap;
    mapping (uint256 => uint16) public tokenToPointsMap;    


    event LogTokenBuilt(address creatorAddress, uint256 tokenId, Token token);
    event LogDataSourceCallbackList(uint8[] result);
    event LogDataSourceCallbackInt(uint8 result);
    event LogDataSourceCallbackTwoInt(uint8 result, uint8 result2);

}


 
contract ERC721 {

    event LogTransfer(address from, address to, uint256 tokenId);
    event LogApproval(address owner, address approved, uint256 tokenId);

    function name() public view returns (string);
    function symbol() public view returns (string);
    function totalSupply() public view returns (uint256 total);
    function balanceOf(address _owner) public view returns (uint256 balance);
    function ownerOf(uint256 _tokenId) external view returns (address owner);
    function approve(address _to, uint256 _tokenId) external;
    function transfer(address _to, uint256 _tokenId) external;
    function transferFrom(address _from, address _to, uint256 _tokenId) external;
    function tokensOfOwner(address _owner) external view returns (uint256[] tokenIds);

}












 
contract AccessControlLayer is DataLayer{

    bool public paused = false;
    bool public finalized = false;
    bool public saleOpen = true;

    
    modifier onlyAdmin() {
        require(msg.sender == adminAddress);
        _;
    }

     
    modifier isNotPaused() {
        require(!paused);
        _;
    }

     
    modifier isPaused() {
        require(paused);
        _;
    }

     
    modifier hasFinished() {
        require((gameFinishedTime != 0) && now >= (gameFinishedTime + (15 days)));
        _;
    }

     
    modifier hasFinalized() {
        require(finalized);
        _;
    }

     
    modifier checkState(pointsValidationState state){
        require(pValidationState == state);
        _;
    }

     
    function setAdmin(address _newAdmin) external onlyAdmin {

        require(_newAdmin != address(0));
        adminAddress = _newAdmin;
    }

     
    function setPauseState(bool state) external onlyAdmin {
        paused = state;
    }

     
    function setFinalized(bool state) external onlyAdmin {
        paused = state;
        finalized = state;
        if(finalized == true)
            finalizedTime = now;
    }
}

 
contract CryptocupToken is AccessControlLayer, ERC721 {

     
     
    function _userOwnsToken(address userAddress, uint256 tokenId) internal view returns (bool){

         return ownerOfTokenMap[tokenId] == userAddress;

    }

     
    function _tokenIsApproved(address userAddress, uint256 tokenId) internal view returns (bool) {

        return tokensApprovedMap[tokenId] == userAddress;
    }

     
    function _transfer(address fromAddress, address toAddress, uint256 tokenId) internal {

      require(tokensOfOwnerMap[toAddress].length < 100);
      require(pValidationState == pointsValidationState.Unstarted);
      
      tokensOfOwnerMap[toAddress].push(tokenId);
      ownerOfTokenMap[tokenId] = toAddress;

      uint256[] storage tokenArray = tokensOfOwnerMap[fromAddress];
      for (uint256 i = 0; i < tokenArray.length; i++){
        if(tokenArray[i] == tokenId){
          tokenArray[i] = tokenArray[tokenArray.length-1];
        }
      }
      delete tokenArray[tokenArray.length-1];
      tokenArray.length--;

      delete tokensApprovedMap[tokenId];

    }

     
    function _approve(uint256 tokenId, address userAddress) internal {
        tokensApprovedMap[tokenId] = userAddress;
    }

     
    function _setTokenOwner(address ownerAddress, uint256 tokenId) internal{

    	tokensOfOwnerMap[ownerAddress].push(tokenId);
      ownerOfTokenMap[tokenId] = ownerAddress;
    
    }

     
    function name() public view returns (string){
      return "Cryptocup";
    }

    function symbol() public view returns (string){
      return "CC";
    }

    
    function balanceOf(address userAddress) public view returns (uint256 count) {
      return tokensOfOwnerMap[userAddress].length;

    }

    function transfer(address toAddress,uint256 tokenId) external isNotPaused {

      require(toAddress != address(0));
      require(toAddress != address(this));
      require(_userOwnsToken(msg.sender, tokenId));

      _transfer(msg.sender, toAddress, tokenId);
      LogTransfer(msg.sender, toAddress, tokenId);

    }


    function transferFrom(address fromAddress, address toAddress, uint256 tokenId) external isNotPaused {

      require(toAddress != address(0));
      require(toAddress != address(this));
      require(_tokenIsApproved(msg.sender, tokenId));
      require(_userOwnsToken(fromAddress, tokenId));

      _transfer(fromAddress, toAddress, tokenId);
      LogTransfer(fromAddress, toAddress, tokenId);

    }

    function approve( address toAddress, uint256 tokenId) external isNotPaused {

        require(toAddress != address(0));
        require(_userOwnsToken(msg.sender, tokenId));

        _approve(tokenId, toAddress);
        LogApproval(msg.sender, toAddress, tokenId);

    }

    function totalSupply() public view returns (uint) {

        return tokens.length;

    }

    function ownerOf(uint256 tokenId) external view returns (address ownerAddress) {

        ownerAddress = ownerOfTokenMap[tokenId];
        require(ownerAddress != address(0));

    }

    function tokensOfOwner(address ownerAddress) external view returns(uint256[] tokenIds) {

        tokenIds = tokensOfOwnerMap[ownerAddress];

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


 
contract GameLogicLayer is CryptocupToken{

    using SafeMath for *;

    uint8 TEAM_RESULT_MASK_GROUPS = 15;
    uint160 RESULT_MASK_BRACKETS = 31;
    uint16 EXTRA_MASK_BRACKETS = 65535;

    uint16 private lastPosition;
    uint16 private superiorQuota;
    
    uint16[] private payDistributionAmount = [1,1,1,1,1,1,1,1,1,1,5,5,10,20,50,100,100,200,500,1500,2500];
    uint32[] private payoutDistribution;

	event LogGroupDataArrived(uint matchId, uint8 result, uint8 result2);
    event LogRoundOfSixteenArrived(uint id, uint8 result);
    event LogMiddlePhaseArrived(uint matchId, uint8 result);
    event LogFinalsArrived(uint id, uint8[4] result);
    event LogExtrasArrived(uint id, uint16 result);
    
     
    function dataSourceGetGroupResult(uint matchId) external onlyAdmin{
        dataSource.getGroupResult(matchId);
    }

    function dataSourceGetRoundOfSixteen(uint index) external onlyAdmin{
        dataSource.getRoundOfSixteenTeams(index);
    }

    function dataSourceGetRoundOfSixteenResult(uint matchId) external onlyAdmin{
        dataSource.getRoundOfSixteenResult(matchId);
    }

    function dataSourceGetQuarterResult(uint matchId) external onlyAdmin{
        dataSource.getQuarterResult(matchId);
    }
    
    function dataSourceGetSemiResult(uint matchId) external onlyAdmin{
        dataSource.getSemiResult(matchId);
    }

    function dataSourceGetFinals() external onlyAdmin{
        dataSource.getFinalTeams();
    }

    function dataSourceGetYellowCards() external onlyAdmin{
        dataSource.getYellowCards();
    }

    function dataSourceGetRedCards() external onlyAdmin{
        dataSource.getRedCards();
    }

     
    
    function dataSourceCallbackGroup(uint matchId, uint8 result, uint8 result2) public {

        require (msg.sender == dataSourceAddress);
        require (matchId >= 0 && matchId <= 47);

        groupsResults[matchId].teamOneGoals = result;
        groupsResults[matchId].teamTwoGoals = result2;

        LogGroupDataArrived(matchId, result, result2);

    }

     

    function dataSourceCallbackRoundOfSixteen(uint id, uint8 result) public {

        require (msg.sender == dataSourceAddress);

        bracketsResults.roundOfSixteenTeamsIds[id] = result;
        bracketsResults.teamExists[result] = true;
        
        LogRoundOfSixteenArrived(id, result);

    }

    function dataSourceCallbackTeamId(uint matchId, uint8 result) public {
        require (msg.sender == dataSourceAddress);

        teamState state = bracketsResults.middlePhaseTeamsIds[result];

        if (matchId >= 48 && matchId <= 55){
            if (state < teamState.ROS)
                bracketsResults.middlePhaseTeamsIds[result] = teamState.ROS;
        } else if (matchId >= 56 && matchId <= 59){
            if (state < teamState.QUARTERS)
                bracketsResults.middlePhaseTeamsIds[result] = teamState.QUARTERS;
        } else if (matchId == 60 || matchId == 61){
            if (state < teamState.SEMIS)
                bracketsResults.middlePhaseTeamsIds[result] = teamState.SEMIS;
        }

        LogMiddlePhaseArrived(matchId, result);
    }

     
    function dataSourceCallbackFinals(uint id, uint8[4] result) public {

        require (msg.sender == dataSourceAddress);

        uint256 i;

        for(i = 0; i < 4; i++){
            bracketsResults.finalsTeamsIds[i] = result[i];
        }

        LogFinalsArrived(id, result);

    }

     
    function dataSourceCallbackExtras(uint id, uint16 result) public {

        require (msg.sender == dataSourceAddress);

        if (id == 101){
            extraResults.yellowCards = result;
        } else if (id == 102){
            extraResults.redCards = result;
        }

        LogExtrasArrived(id, result);

    }

     
    function matchWinnerOk(uint8 realResultOne, uint8 realResultTwo, uint8 tokenResultOne, uint8 tokenResultTwo) internal pure returns(bool){

        int8 realR = int8(realResultOne - realResultTwo);
        int8 tokenR = int8(tokenResultOne - tokenResultTwo);

        return (realR > 0 && tokenR > 0) || (realR < 0 && tokenR < 0) || (realR == 0 && tokenR == 0);

    }

     
    function getMatchPointsGroups (uint256 matchIndex, uint192 groupsPhase) internal view returns(uint16 matchPoints) {

        uint8 tokenResultOne = uint8(groupsPhase & TEAM_RESULT_MASK_GROUPS);
        uint8 tokenResultTwo = uint8((groupsPhase >> 4) & TEAM_RESULT_MASK_GROUPS);

        uint8 teamOneGoals = groupsResults[matchIndex].teamOneGoals;
        uint8 teamTwoGoals = groupsResults[matchIndex].teamTwoGoals;

        if (teamOneGoals == tokenResultOne && teamTwoGoals == tokenResultTwo){
            matchPoints += 10;
        } else {
            if (matchWinnerOk(teamOneGoals, teamTwoGoals, tokenResultOne, tokenResultTwo)){
                matchPoints += 3;
            }
        }

    }

     
    function getFinalRoundPoints (uint160 brackets) internal view returns(uint16 finalRoundPoints) {

        uint8[3] memory teamsIds;

        for (uint i = 0; i <= 2; i++){
            brackets = brackets >> 5;  
            teamsIds[2-i] = uint8(brackets & RESULT_MASK_BRACKETS);
        }

        if (teamsIds[0] == bracketsResults.finalsTeamsIds[0]){
            finalRoundPoints += 100;
        }

        if (teamsIds[2] == bracketsResults.finalsTeamsIds[2]){
            finalRoundPoints += 25;
        }

        if (teamsIds[0] == bracketsResults.finalsTeamsIds[1]){
            finalRoundPoints += 50;
        }

        if (teamsIds[1] == bracketsResults.finalsTeamsIds[0] || teamsIds[1] == bracketsResults.finalsTeamsIds[1]){
            finalRoundPoints += 50;
        }

    }

     
    function getMiddleRoundPoints(uint8 size, teamState round, uint160 brackets) internal view returns(uint16 middleRoundResults){

        uint8 teamId;

        for (uint i = 0; i < size; i++){
            teamId = uint8(brackets & RESULT_MASK_BRACKETS);

            if (uint(bracketsResults.middlePhaseTeamsIds[teamId]) >= uint(round) ) {
                middleRoundResults+=60;
            }

            brackets = brackets >> 5;
        }

    }

     
    function getQualifiersPoints(uint160 brackets) internal view returns(uint16 qualifiersPoints){

        uint8 teamId;

        for (uint256 i = 0; i <= 15; i++){
            teamId = uint8(brackets & RESULT_MASK_BRACKETS);

            if (teamId == bracketsResults.roundOfSixteenTeamsIds[15-i]){
                qualifiersPoints+=30;
            } else if (bracketsResults.teamExists[teamId]){
                qualifiersPoints+=25;
            }
            
            brackets = brackets >> 5;
        }

    }

     
    function getExtraPoints(uint32 extras) internal view returns(uint16 extraPoints){

        uint16 redCards = uint16(extras & EXTRA_MASK_BRACKETS);
        extras = extras >> 16;
        uint16 yellowCards = uint16(extras);

        if (redCards == extraResults.redCards){
            extraPoints+=20;
        }

        if (yellowCards == extraResults.yellowCards){
            extraPoints+=20;
        }

    }

     
    function calculateTokenPoints (Token memory t) internal view returns(uint16 points){
        
         
        uint192 g1 = t.groups1;
        for (uint256 i = 0; i <= 23; i++){
            points+=getMatchPointsGroups(23-i, g1);
            g1 = g1 >> 8;
        }

         
        uint192 g2 = t.groups2;
        for (i = 0; i <= 23; i++){
            points+=getMatchPointsGroups(47-i, g2);
            g2 = g2 >> 8;
        }
        
        uint160 bracketsLocal = t.brackets;

         
        points+=getFinalRoundPoints(bracketsLocal);
        bracketsLocal = bracketsLocal >> 20;

         
        points+=getMiddleRoundPoints(4, teamState.QUARTERS, bracketsLocal);
        bracketsLocal = bracketsLocal >> 20;

         
        points+=getMiddleRoundPoints(8, teamState.ROS, bracketsLocal);
        bracketsLocal = bracketsLocal >> 40;

         
        points+=getQualifiersPoints(bracketsLocal);

         
        points+=getExtraPoints(t.extra);

    }

     
	function calculatePointsBlock(uint32 amount) external{

        require (gameFinishedTime == 0);
        require(amount + lastCheckedToken <= tokens.length);


        for (uint256 i = lastCalculatedToken; i < (lastCalculatedToken + amount); i++) {
            uint16 points = calculateTokenPoints(tokens[i]);
            tokenToPointsMap[i] = points;
            if(worstTokens.length == 0 || points <= auxWorstPoints){
                if(worstTokens.length != 0 && points < auxWorstPoints){
                  worstTokens.length = 0;
                }
                if(worstTokens.length < 100){
                    auxWorstPoints = points;
                    worstTokens.push(i);
                }
            }
        }

        lastCalculatedToken += amount;
  	}

     
    function setPayoutDistributionId () internal {
        if(tokens.length < 101){
            payoutDistribution = [289700, 189700, 120000, 92500, 75000, 62500, 52500, 42500, 40000, 35600, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
            lastPosition = 0;
            superiorQuota = 10;
        }else if(tokens.length < 201){
            payoutDistribution = [265500, 165500, 105500, 75500, 63000, 48000, 35500, 20500, 20000, 19500, 18500, 17800, 0, 0, 0, 0, 0, 0, 0, 0, 0];
            lastPosition = 0;
            superiorQuota = 20;
        }else if(tokens.length < 301){
            payoutDistribution = [260700, 155700, 100700, 70900, 60700, 45700, 35500, 20500, 17900, 12500, 11500, 11000, 10670, 0, 0, 0, 0, 0, 0, 0, 0];
            lastPosition = 0;
            superiorQuota = 30;
        }else if(tokens.length < 501){
            payoutDistribution = [238600, 138600, 88800, 63800, 53800, 43800, 33800, 18800, 17500, 12500, 9500, 7500, 7100, 6700, 0, 0, 0, 0, 0, 0, 0];
            lastPosition = 0;
            superiorQuota = 50;
        }else if(tokens.length < 1001){
            payoutDistribution = [218300, 122300, 72300, 52400, 43900, 33900, 23900, 16000, 13000, 10000, 9000, 7000, 5000, 4000, 3600, 0, 0, 0, 0, 0, 0];
            lastPosition = 4000;
            superiorQuota = 100;
        }else if(tokens.length < 2001){
            payoutDistribution = [204500, 114000, 64000, 44100, 35700, 26700, 22000, 15000, 11000, 9500, 8500, 6500, 4600, 2500, 2000, 1800, 0, 0, 0, 0, 0];
            lastPosition = 2500;
            superiorQuota = 200;
        }else if(tokens.length < 3001){
            payoutDistribution = [189200, 104800, 53900, 34900, 29300, 19300, 15300, 14000, 10500, 8300, 8000, 6000, 3800, 2500, 2000, 1500, 1100, 0, 0, 0, 0];
            lastPosition = 2500;
            superiorQuota = 300;
        }else if(tokens.length < 5001){
            payoutDistribution = [178000, 100500, 47400, 30400, 24700, 15500, 15000, 12000, 10200, 7800, 7400, 5500, 3300, 2000, 1500, 1200, 900, 670, 0, 0, 0];
            lastPosition = 2000;
            superiorQuota = 500;
        }else if(tokens.length < 10001){
            payoutDistribution = [157600, 86500, 39000, 23100, 18900, 15000, 14000, 11000, 9300, 6100, 6000, 5000, 3800, 1500, 1100, 900, 700, 500, 360, 0, 0];
            lastPosition = 1500;
            superiorQuota = 1000;
        }else if(tokens.length < 25001){
            payoutDistribution = [132500, 70200, 31300, 18500, 17500, 14000, 13500, 10500, 7500, 5500, 5000, 4000, 3000, 1000, 900, 700, 600, 400, 200, 152, 0];
            lastPosition = 1000;
            superiorQuota = 2500;
        } else {
            payoutDistribution = [120000, 63000,  27000, 18800, 17300, 13700, 13000, 10000, 6300, 5000, 4500, 3900, 2500, 900, 800, 600, 500, 350, 150, 100, 70];
            lastPosition = 900;
            superiorQuota = 5000;
        }

    }

     
    function setLimit(uint256 tokenId) external onlyAdmin{
        require(tokenId < tokens.length);
        require(pValidationState == pointsValidationState.Unstarted || pValidationState == pointsValidationState.LimitSet);
        pointsLimit = tokenId;
        pValidationState = pointsValidationState.LimitSet;
        lastCheckedToken = 0;
        lastCalculatedToken = 0;
        winnerCounter = 0;
        
        setPayoutDistributionId();
    }

     
    function calculateWinners(uint32 amount) external onlyAdmin checkState(pointsValidationState.LimitSet){
        require(amount + lastCheckedToken <= tokens.length);
        uint256 points = tokenToPointsMap[pointsLimit];

        for(uint256 i = lastCheckedToken; i < lastCheckedToken + amount; i++){
            if(tokenToPointsMap[i] > points ||
                (tokenToPointsMap[i] == points && i <= pointsLimit)){
                winnerCounter++;
            }
        }
        lastCheckedToken += amount;

        if(lastCheckedToken == tokens.length){
            require(superiorQuota == winnerCounter);
            pValidationState = pointsValidationState.LimitCalculated;
        }
    }

     
    function checkOrder(uint32[] sortedChunk) external onlyAdmin checkState(pointsValidationState.LimitCalculated){
        require(sortedChunk.length + sortedWinners.length <= winnerCounter);

        for(uint256 i=0;i < sortedChunk.length-1;i++){
            uint256 id = sortedChunk[i];
            uint256 sigId = sortedChunk[i+1];
            require(tokenToPointsMap[id] > tokenToPointsMap[sigId] ||
                (tokenToPointsMap[id] == tokenToPointsMap[sigId] &&  id < sigId));
        }

        if(sortedWinners.length != 0){
            uint256 id2 = sortedWinners[sortedWinners.length-1];
            uint256 sigId2 = sortedChunk[0];
            require(tokenToPointsMap[id2] > tokenToPointsMap[sigId2] ||
                (tokenToPointsMap[id2] == tokenToPointsMap[sigId2] && id2 < sigId2));
        }

        for(uint256 j=0;j < sortedChunk.length;j++){
            sortedWinners.push(sortedChunk[j]);
        }

        if(sortedWinners.length == winnerCounter){
            require(sortedWinners[sortedWinners.length-1] == pointsLimit);
            pValidationState = pointsValidationState.OrderChecked;
        }

    }

     
    function resetWinners(uint256 newLength) external onlyAdmin checkState(pointsValidationState.LimitCalculated){
        
        sortedWinners.length = newLength;
    
    }

     
    function setTopWinnerPrizes() external onlyAdmin checkState(pointsValidationState.OrderChecked){

        uint256 percent = 0;
        uint[] memory tokensEquals = new uint[](30);
        uint16 tokenEqualsCounter = 0;
        uint256 currentTokenId;
        uint256 currentTokenPoints;
        uint256 lastTokenPoints;
        uint32 counter = 0;
        uint256 maxRange = 13;
        if(tokens.length < 201){
          maxRange = 10;
        }
        

        while(payoutRange < maxRange){
          uint256 inRangecounter = payDistributionAmount[payoutRange];
          while(inRangecounter > 0){
            currentTokenId = sortedWinners[counter];
            currentTokenPoints = tokenToPointsMap[currentTokenId];

            inRangecounter--;

             
            if(inRangecounter == 0 && payoutRange == maxRange - 1){
                if(currentTokenPoints == lastTokenPoints){
                  percent += payoutDistribution[payoutRange];
                  tokensEquals[tokenEqualsCounter] = currentTokenId;
                  tokenEqualsCounter++;
                }else{
                  tokenToPayoutMap[currentTokenId] = payoutDistribution[payoutRange];
                }
            }

            if(counter != 0 && (currentTokenPoints != lastTokenPoints || (inRangecounter == 0 && payoutRange == maxRange - 1))){  
                    for(uint256 i=0;i < tokenEqualsCounter;i++){
                        tokenToPayoutMap[tokensEquals[i]] = percent.div(tokenEqualsCounter);
                    }
                    percent = 0;
                    tokensEquals = new uint[](30);
                    tokenEqualsCounter = 0;
            }

            percent += payoutDistribution[payoutRange];
            tokensEquals[tokenEqualsCounter] = currentTokenId;
            
            tokenEqualsCounter++;
            counter++;

            lastTokenPoints = currentTokenPoints;
           }
           payoutRange++;
        }

        pValidationState = pointsValidationState.TopWinnersAssigned;
        lastPrizeGiven = counter;
    }

     
    function setWinnerPrizes(uint32 amount) external onlyAdmin checkState(pointsValidationState.TopWinnersAssigned){
        require(lastPrizeGiven + amount <= winnerCounter);
        
        uint16 inRangeCounter = payDistributionAmount[payoutRange];
        for(uint256 i = 0; i < amount; i++){
          if (inRangeCounter == 0){
            payoutRange++;
            inRangeCounter = payDistributionAmount[payoutRange];
          }

          uint256 tokenId = sortedWinners[i + lastPrizeGiven];

          tokenToPayoutMap[tokenId] = payoutDistribution[payoutRange];

          inRangeCounter--;
        }
         
        lastPrizeGiven += amount;
        payDistributionAmount[payoutRange] = inRangeCounter;

        if(lastPrizeGiven == winnerCounter){
            pValidationState = pointsValidationState.WinnersAssigned;
            return;
        }
    }

     
    function setLastPositions() external onlyAdmin checkState(pointsValidationState.WinnersAssigned){
        
            
        for(uint256 j = 0;j < worstTokens.length;j++){
            uint256 tokenId = worstTokens[j];
            tokenToPayoutMap[tokenId] += lastPosition.div(worstTokens.length);
        }

        uint256 balance = address(this).balance;
        adminPool = balance.mul(25).div(100);
        prizePool = balance.mul(75).div(100);

        pValidationState = pointsValidationState.Finished;
        gameFinishedTime = now;
    }

}


 
contract CoreLayer is GameLogicLayer {
    
    function CoreLayer() public {
        adminAddress = msg.sender;
        deploymentTime = now;
    }

     
    function() external payable {
        require(msg.sender == adminAddress);

    }

    function isDataSourceCallback() public pure returns (bool){
        return true;
    }   

     
    function buildToken(uint192 groups1, uint192 groups2, uint160 brackets, uint32 extra) external payable isNotPaused {

        Token memory token = Token({
            groups1: groups1,
            groups2: groups2,
            brackets: brackets,
            timeStamp: uint64(now),
            extra: extra
        });

        require(msg.value >= _getTokenPrice());
        require(msg.sender != address(0));
        require(tokens.length < WCCTOKEN_CREATION_LIMIT);
        require(tokensOfOwnerMap[msg.sender].length < 100);
        require(now < WORLD_CUP_START);  

        uint256 tokenId = tokens.push(token) - 1;
        require(tokenId == uint256(uint32(tokenId)));

        _setTokenOwner(msg.sender, tokenId);
        LogTokenBuilt(msg.sender, tokenId, token);

    }

     
    function getToken(uint256 tokenId) external view returns (uint192 groups1, uint192 groups2, uint160 brackets, uint64 timeStamp, uint32 extra) {

        Token storage token = tokens[tokenId];

        groups1 = token.groups1;
        groups2 = token.groups2;
        brackets = token.brackets;
        timeStamp = token.timeStamp;
        extra = token.extra;

    }

     
    function adminWithdrawBalance() external onlyAdmin {

        adminAddress.transfer(adminPool);
        adminPool = 0;

    }

     
    function withdrawPrize() external checkState(pointsValidationState.Finished){
        uint256 prize = 0;
        uint256[] memory tokenList = tokensOfOwnerMap[msg.sender];
        
        for(uint256 i = 0;i < tokenList.length; i++){
            prize += tokenToPayoutMap[tokenList[i]];
            tokenToPayoutMap[tokenList[i]] = 0;
        }
        
        require(prize > 0);
        msg.sender.transfer((prizePool.mul(prize)).div(1000000));
      
    }

    
     
    function _getTokenPrice() internal view returns(uint256 tokenPrice){

        if ( now >= THIRD_PHASE){
            tokenPrice = (150 finney);
        } else if (now >= SECOND_PHASE) {
            tokenPrice = (110 finney);
        } else if (now >= FIRST_PHASE) {
            tokenPrice = (75 finney);
        } else {
            tokenPrice = STARTING_PRICE;
        }

        require(tokenPrice >= STARTING_PRICE && tokenPrice <= (200 finney));

    }

     
    function setDataSourceAddress(address _address) external onlyAdmin {
        
        DataSourceInterface c = DataSourceInterface(_address);

        require(c.isDataSource());

        dataSource = c;
        dataSourceAddress = _address;
    }

     
    function getGroupData(uint x) external view returns(uint8 a, uint8 b){
        a = groupsResults[x].teamOneGoals;
        b = groupsResults[x].teamTwoGoals;  
    }

     
    function getBracketData() external view returns(uint8[16] a){
        a = bracketsResults.roundOfSixteenTeamsIds;
    }

     
    function getBracketDataMiddleTeamIds(uint8 x) external view returns(teamState a){
        a = bracketsResults.middlePhaseTeamsIds[x];
    }

     
    function getBracketDataFinals() external view returns(uint8[4] a){
        a = bracketsResults.finalsTeamsIds;
    }

     
    function getExtrasData() external view returns(uint16 a, uint16 b){
        a = extraResults.yellowCards;
        b = extraResults.redCards;  
    }

     
     

     
    function emergencyWithdraw() external hasFinalized{

        uint256 balance = STARTING_PRICE * tokensOfOwnerMap[msg.sender].length;

        delete tokensOfOwnerMap[msg.sender];
        msg.sender.transfer(balance);

    }

      
    function finishedGameWithdraw() external onlyAdmin hasFinished{

        uint256 balance = address(this).balance;
        adminAddress.transfer(balance);

    }
    
     
    function emergencyWithdrawAdmin() external hasFinalized onlyAdmin{

        require(finalizedTime != 0 &&  now >= finalizedTime + 10 days );
        msg.sender.transfer(address(this).balance);

    }
}
 

pragma solidity ^0.4.24;

 

library PointsCalculator {

    uint8 constant MATCHES_NUMBER = 20;
    uint8 constant BONUS_MATCHES = 5;
    
    uint16 constant EXTRA_STATS_MASK = 65535;
    uint8 constant MATCH_UNDEROVER_MASK = 1;
    uint8 constant MATCH_RESULT_MASK = 3;
    uint8 constant MATCH_TOUCHDOWNS_MASK = 31;
    uint8 constant BONUS_STAT_MASK = 63;

    struct MatchResult{
        uint8 result;  
        uint8 under49;
        uint8 touchdowns;
    }

    struct Extras {
        uint16 interceptions;
        uint16 missedFieldGoals;
        uint16 overtimes;
        uint16 sacks;
        uint16 fieldGoals;
        uint16 fumbles;
    }

    struct BonusMatch {
        uint16 bonus;
    }    
    
     
    function getMatchPoints (uint256 matchIndex, uint160 matches, MatchResult[] matchResults, bool[] starMatches) private pure returns(uint16 matchPoints) {

        uint8 tResult = uint8(matches & MATCH_RESULT_MASK);
        uint8 tUnder49 = uint8((matches >> 2) & MATCH_UNDEROVER_MASK);
        uint8 tTouchdowns = uint8((matches >> 3) & MATCH_TOUCHDOWNS_MASK);

        uint8 rResult = matchResults[matchIndex].result;
        uint8 rUnder49 = matchResults[matchIndex].under49;
        uint8 rTouchdowns = matchResults[matchIndex].touchdowns;
        
        if (rResult == tResult) {
            matchPoints += 5;
            if(rResult == 0) {
                matchPoints += 5;
            }
            if(starMatches[matchIndex]) {
                matchPoints += 2;
            }
        }
        if(tUnder49 == rUnder49) {
            matchPoints += 1;
        }
        if(tTouchdowns == rTouchdowns) {
            matchPoints += 4;
        }
    }

     
    function getExtraPoints(uint96 extras, Extras extraStats) private pure returns(uint16 extraPoints){

        uint16 interceptions = uint16(extras & EXTRA_STATS_MASK);
        extras = extras >> 16;
        uint16 missedFieldGoals = uint16(extras & EXTRA_STATS_MASK);
        extras = extras >> 16;
        uint16 overtimes = uint16(extras & EXTRA_STATS_MASK);
        extras = extras >> 16;
        uint16 sacks = uint16(extras & EXTRA_STATS_MASK);
        extras = extras >> 16;
        uint16 fieldGoals = uint16(extras & EXTRA_STATS_MASK);
        extras = extras >> 16;
        uint16 fumbles = uint16(extras & EXTRA_STATS_MASK);

        if (interceptions == extraStats.interceptions){
            extraPoints += 6;
        }
        
        if (missedFieldGoals == extraStats.missedFieldGoals){
            extraPoints += 6;
        }

        if (overtimes == extraStats.overtimes){
            extraPoints += 6;
        }

        if (sacks == extraStats.sacks){
            extraPoints += 6;
        }

        if (fieldGoals == extraStats.fieldGoals){
            extraPoints += 6;
        }

        if (fumbles == extraStats.fumbles){
            extraPoints += 6;
        }

    }

     
    function getBonusPoints (uint256 bonusId, uint32 bonuses, BonusMatch[] bonusMatches) private pure returns(uint16 bonusPoints) {
        uint8 bonus = uint8(bonuses & BONUS_STAT_MASK);

        if(bonusMatches[bonusId].bonus == bonus) {
            bonusPoints += 2;
        }
    }


    function calculateTokenPoints (uint160 tMatchResults, uint32 tBonusMatches, uint96 tExtraStats, MatchResult[] storage matchResults, Extras storage extraStats, BonusMatch[] storage bonusMatches, bool[] starMatches) 
    external pure returns(uint16 points){
        
         
        uint160 m = tMatchResults;
        for (uint256 i = 0; i < MATCHES_NUMBER; i++){
            points += getMatchPoints(MATCHES_NUMBER - i - 1, m, matchResults, starMatches);
            m = m >> 8;
        }

         
        uint32 b = tBonusMatches;
        for(uint256 j = 0; j < BONUS_MATCHES; j++) {
            points += getBonusPoints(BONUS_MATCHES - j - 1, b, bonusMatches);
            b = b >> 6;
        }

         
        points += getExtraPoints(tExtraStats, extraStats);

    }
}

 

contract DataSourceInterface {

    function isDataSource() public pure returns (bool);

    function getMatchResults() external;
    function getExtraStats() external;
    function getBonusResults() external;

}

 

 
     
     
     
     
     
     
     
     





contract GameStorage{

    event LogTokenBuilt(address creatorAddress, uint256 tokenId, string message, uint160 m, uint96 e, uint32 b);
    event LogTokenGift(address creatorAddress, address giftedAddress, uint256 tokenId, string message, uint160 m, uint96 e, uint32 b);
    event LogPrepaidTokenBuilt(address creatorAddress, bytes32 secret);
    event LogPrepaidRedeemed(address redeemer, uint256 tokenId, string message, uint160 m, uint96 e, uint32 b);

    uint256 constant STARTING_PRICE = 50 finney;
    uint256 constant FIRST_PHASE  = 1540393200;
    uint256 constant EVENT_START = 1541084400;

    uint8 constant MATCHES_NUMBER = 20;
    uint8 constant BONUS_MATCHES = 5;

     
    bool[] internal starMatches = [false, false, false, false, false, false, true, false, false, false, false, false, true, false, false, false, false, false, true, false];
    
    uint16 constant EXTRA_STATS_MASK = 65535;
    uint8 constant MATCH_UNDEROVER_MASK = 1;
    uint8 constant MATCH_RESULT_MASK = 3;
    uint8 constant MATCH_TOUCHDOWNS_MASK = 31;
    uint8 constant BONUS_STAT_MASK = 63;

    uint256 public prizePool = 0;
    uint256 public adminPool = 0;

    mapping (uint256 => uint16) public tokenToPointsMap;    
    mapping (uint256 => uint256) public tokenToPayoutMap;
    mapping (bytes32 => uint8) public secretsMap;


    address public dataSourceAddress;
    DataSourceInterface internal dataSource;


    enum pointsValidationState { Unstarted, LimitSet, LimitCalculated, OrderChecked, TopWinnersAssigned, WinnersAssigned, Finished }
    pointsValidationState public pValidationState = pointsValidationState.Unstarted;

    uint256 internal pointsLimit = 0;
    uint32 internal lastCalculatedToken = 0;
    uint32 internal lastCheckedToken = 0;
    uint32 internal winnerCounter = 0;
    uint32 internal lastAssigned = 0;
    uint32 internal payoutRange = 0;
    uint32 internal lastPrizeGiven = 0;

    uint16 internal superiorQuota;
    
    uint16[] internal payDistributionAmount = [1,1,1,1,1,1,1,1,1,1,5,5,10,20,50,100,100,200,500,1500,2500];
    uint24[21] internal payoutDistribution;

    uint256[] internal sortedWinners;

    PointsCalculator.MatchResult[] public matchResults;
    PointsCalculator.BonusMatch[] public bonusMatches;
    PointsCalculator.Extras public extraStats;


}

 

contract CryptocupStorage is GameStorage {

}

 

 
interface TicketInterface {

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );


    function balanceOf(address owner) public view returns (uint256 balance);
    function ownerOf(uint256 tokenId) public view returns (address owner);
    function getOwnedTokens(address _from) public view returns(uint256[]);


    function approve(address to, uint256 tokenId) public;
    function getApproved(uint256 tokenId) public view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) public;
    function isApprovedForAll(address owner, address operator) public view returns (bool);

    function transferFrom(address from, address to, uint256 tokenId) public;
    function safeTransferFrom(address from, address to, uint256 tokenId) public;

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes data) public;

}

 

contract TicketStorage is TicketInterface{

     
     
    bytes4 private constant ERC721_RECEIVED = 0x150b7a02;

    struct Token {
        uint160 matches;
        uint32 bonusMatches;
        uint96 extraStats;
        uint64 timeStamp;
        string message;  
    }
    
     
    Token[] tokens;

    mapping (uint256 => address) public tokenOwner;
    mapping (uint256 => address) public tokenApprovals;
    mapping (address => uint256[]) internal ownedTokens;
    mapping (address => mapping (address => bool)) public operatorApprovals;

}

 

 
library SafeMath {

   
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
     
     
     
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

   
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
     
     
     
    return _a / _b;
  }

   
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

   
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}

 

 
library AddressUtils {

   
  function isContract(address _addr) internal view returns (bool) {
    uint256 size;
     
     
     
     
     
     
     
    assembly { size := extcodesize(_addr) }
    return size > 0;
  }

}

 

contract AccessStorage{

	bool public paused = false;
    bool public finalized = false;
    
    address public adminAddress;
    address public dataSourceAddress;
    address public marketplaceAddress;

    uint256 internal deploymentTime = 0;
    uint256 public gameFinishedTime = 0; 
    uint256 public finalizedTime = 0;

}

 

 
contract AccessRegistry is AccessStorage {


    
    modifier onlyAdmin() {
        require(msg.sender == adminAddress, "Only admin.");
        _;
    }

     
    modifier onlyDataSource() {
        require(msg.sender == dataSourceAddress, "Only dataSource.");
        _;
    }

     
    modifier onlyMarketPlace() {
        require(msg.sender == marketplaceAddress, "Only marketplace.");
        _;
    }


     
    modifier isNotPaused() {
        require(!paused, "Only if not paused.");
        _;
    }

     
    modifier isPaused() {
        require(paused, "Only if paused.");
        _;
    }

     
    modifier hasFinished() {
        require((gameFinishedTime != 0) && now >= (gameFinishedTime + (15 days)), "Only if game has finished.");
        _;
    }

     
    modifier hasFinalized() {
        require(finalized, "Only if game has finalized.");
        _;
    }

    function setPause () internal {
        paused = true;
    }

    function unSetPause() internal {
        paused = false;
    }

     
    function setAdmin(address _newAdmin) external onlyAdmin {

        require(_newAdmin != address(0));
        adminAddress = _newAdmin;
    }

      
    function setMarketplaceAddress(address _newMkt) external onlyAdmin {

        require(_newMkt != address(0));
        marketplaceAddress = _newMkt;
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

 

 
contract TicketRegistry is TicketInterface, TicketStorage, AccessRegistry{

    using SafeMath for uint256;
    using AddressUtils for address;
    
     
    function balanceOf(address _owner) public view returns (uint256) {
        require(_owner != address(0));
        return ownedTokens[_owner].length;
    }

     
    function ownerOf(uint256 _tokenId) public view returns (address) {
        address owner = tokenOwner[_tokenId];
        require(owner != address(0));
        return owner;
    }

     
    function getOwnedTokens(address _from) public view returns(uint256[]) {
        return ownedTokens[_from];   
    }

     
    function exists(uint256 _tokenId) public view returns (bool) {
        address owner = tokenOwner[_tokenId];
        return owner != address(0);
    }

     
    function approve(address _to, uint256 _tokenId) public {
        address owner = ownerOf(_tokenId);
        require(_to != owner);
        require(msg.sender == owner || isApprovedForAll(owner, msg.sender));

        tokenApprovals[_tokenId] = _to;
        emit Approval(owner, _to, _tokenId);
    }

     
    function getApproved(uint256 _tokenId) public view returns (address) {
        return tokenApprovals[_tokenId];
    }

     
    function setApprovalForAll(address _to, bool _approved) public {
        require(_to != msg.sender);
        operatorApprovals[msg.sender][_to] = _approved;
        emit ApprovalForAll(msg.sender, _to, _approved);
    }

     
    function isApprovedForAll(address _owner, address _operator) public view returns (bool)  {
        return operatorApprovals[_owner][_operator];
    }

     
    function transferFrom(address _from, address _to, uint256 _tokenId) public isNotPaused{
        
        require(isApprovedOrOwner(msg.sender, _tokenId));
        require(_from != address(0));
        require(_to != address(0));
        require (_from != _to);
        
        clearApproval(_from, _tokenId);
        removeTokenFrom(_from, _tokenId);
        addTokenTo(_to, _tokenId);

        emit Transfer(_from, _to, _tokenId);
    }

     
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) public {
         
        safeTransferFrom(_from, _to, _tokenId, "");
    }

     
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes _data) public {
        transferFrom(_from, _to, _tokenId);
         
         
    }


     
    function isApprovedOrOwner(address _spender, uint256 _tokenId) internal view returns (bool){
        address owner = ownerOf(_tokenId);
         
         
         
        return (
            _spender == owner ||
            getApproved(_tokenId) == _spender ||
            isApprovedForAll(owner, _spender)
        );
    }

     
    function _mint(address _to, uint256 _tokenId) internal {
        require(_to != address(0));
        addTokenTo(_to, _tokenId);
         
    }

     
    function clearApproval(address _owner, uint256 _tokenId) internal {
        require(ownerOf(_tokenId) == _owner);
        if (tokenApprovals[_tokenId] != address(0)) {
            tokenApprovals[_tokenId] = address(0);
        }
    }

     
    function addTokenTo(address _to, uint256 _tokenId) internal {
        require(tokenOwner[_tokenId] == address(0));
        tokenOwner[_tokenId] = _to;
        ownedTokens[_to].push(_tokenId);
    }

     
    function removeTokenFrom(address _from, uint256 _tokenId) internal {

        require(ownerOf(_tokenId) == _from);
        require(ownedTokens[_from].length < 100);

        tokenOwner[_tokenId] = address(0);

        uint256[] storage tokenArray = ownedTokens[_from];
        for (uint256 i = 0; i < tokenArray.length; i++){
            if(tokenArray[i] == _tokenId){
                tokenArray[i] = tokenArray[tokenArray.length-1];
            }
        }
        
        delete tokenArray[tokenArray.length-1];
        tokenArray.length--;

    }



}

 

library PayoutDistribution {

	function getDistribution(uint256 tokenCount) external pure returns (uint24[21] payoutDistribution) {

		if(tokenCount < 101){
            payoutDistribution = [289700, 189700, 120000, 92500, 75000, 62500, 52500, 42500, 40000, 35600, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
        }else if(tokenCount < 201){
            payoutDistribution = [265500, 165500, 105500, 75500, 63000, 48000, 35500, 20500, 20000, 19500, 18500, 17800, 0, 0, 0, 0, 0, 0, 0, 0, 0];
        }else if(tokenCount < 301){
            payoutDistribution = [260700, 155700, 100700, 70900, 60700, 45700, 35500, 20500, 17900, 12500, 11500, 11000, 10670, 0, 0, 0, 0, 0, 0, 0, 0];
        }else if(tokenCount < 501){
            payoutDistribution = [238600, 138600, 88800, 63800, 53800, 43800, 33800, 18800, 17500, 12500, 9500, 7500, 7100, 6700, 0, 0, 0, 0, 0, 0, 0];
        }else if(tokenCount < 1001){
            payoutDistribution = [218300, 122300, 72300, 52400, 43900, 33900, 23900, 16000, 13000, 10000, 9000, 7000, 5000, 4000, 3600, 0, 0, 0, 0, 0, 0];
        }else if(tokenCount < 2001){
            payoutDistribution = [204500, 114000, 64000, 44100, 35700, 26700, 22000, 15000, 11000, 9500, 8500, 6500, 4600, 2500, 2000, 1800, 0, 0, 0, 0, 0];
        }else if(tokenCount < 3001){
            payoutDistribution = [189200, 104800, 53900, 34900, 29300, 19300, 15300, 14000, 10500, 8300, 8000, 6000, 3800, 2500, 2000, 1500, 1100, 0, 0, 0, 0];
        }else if(tokenCount < 5001){
            payoutDistribution = [178000, 100500, 47400, 30400, 24700, 15500, 15000, 12000, 10200, 7800, 7400, 5500, 3300, 2000, 1500, 1200, 900, 670, 0, 0, 0];
        }else if(tokenCount < 10001){
            payoutDistribution = [157600, 86500, 39000, 23100, 18900, 15000, 14000, 11000, 9300, 6100, 6000, 5000, 3800, 1500, 1100, 900, 700, 500, 360, 0, 0];
        }else if(tokenCount < 25001){
            payoutDistribution = [132500, 70200, 31300, 18500, 17500, 14000, 13500, 10500, 7500, 5500, 5000, 4000, 3000, 1000, 900, 700, 600, 400, 200, 152, 0];
        } else {
            payoutDistribution = [120000, 63000,  27000, 18800, 17300, 13700, 13000, 10000, 6300, 5000, 4500, 3900, 2500, 900, 800, 600, 500, 350, 150, 100, 70];
        }
	}

	function getSuperiorQuota(uint256 tokenCount) external pure returns (uint16 superiorQuota){

		if(tokenCount < 101){
            superiorQuota = 10;
        }else if(tokenCount < 201){
            superiorQuota = 20;
        }else if(tokenCount < 301){
            superiorQuota = 30;
        }else if(tokenCount < 501){
            superiorQuota = 50;
        }else if(tokenCount < 1001){
            superiorQuota = 100;
        }else if(tokenCount < 2001){
            superiorQuota = 200;
        }else if(tokenCount < 3001){
            superiorQuota = 300;
        }else if(tokenCount < 5001){
            superiorQuota = 500;
        }else if(tokenCount < 10001){
            superiorQuota = 1000;
        }else if(tokenCount < 25001){
            superiorQuota = 2500;
        } else {
            superiorQuota = 5000;
        }
	}

}

 

contract GameRegistry is CryptocupStorage, TicketRegistry{
	
    using PointsCalculator for PointsCalculator.MatchResult;
    using PointsCalculator for PointsCalculator.BonusMatch;
    using PointsCalculator for PointsCalculator.Extras;

      
    modifier checkState(pointsValidationState state){
        require(pValidationState == state, "Points validation stage invalid.");
        _;
    }
    
     
    function _getTokenPrice() internal view returns(uint256 tokenPrice){

        if (now >= FIRST_PHASE) {
            tokenPrice = (80 finney);
        } else {
            tokenPrice = STARTING_PRICE;
        }

        require(tokenPrice >= STARTING_PRICE && tokenPrice <= (80 finney));

    }

    function _prepareMatchResultsArray() internal {
        matchResults.length = MATCHES_NUMBER;
    }

    function _prepareBonusResultsArray() internal {
        bonusMatches.length = BONUS_MATCHES;
    }

     
    function _createToken(uint160 matches, uint32 bonusMatches, uint96 extraStats, string userMessage) internal returns (uint256){

        Token memory token = Token({
            matches: matches,
            bonusMatches: bonusMatches,
            extraStats: extraStats,
            timeStamp: uint64(now),
            message: userMessage
        });

        uint256 tokenId = tokens.push(token) - 1;
        require(tokenId == uint256(uint32(tokenId)), "Failed to convert tokenId to uint256.");
        
        return tokenId;
    }

     
    function setDataSourceAddress(address _address) external onlyAdmin {
        
        DataSourceInterface c = DataSourceInterface(_address);

        require(c.isDataSource());

        dataSource = c;
        dataSourceAddress = _address;
    }


     
    function adminWithdrawBalance() external onlyAdmin {

        uint256 adminPrize = adminPool;

        adminPool = 0;
        adminAddress.transfer(adminPrize);

    }


      
    function finishedGameWithdraw() external onlyAdmin hasFinished{

        uint256 balance = address(this).balance;
        adminAddress.transfer(balance);

    }
    
     
    function emergencyWithdrawAdmin() external hasFinalized onlyAdmin{

        require(finalizedTime != 0 &&  now >= finalizedTime + 10 days );
        msg.sender.transfer(address(this).balance);

    }


    function isDataSourceCallback() external pure returns (bool){
        return true;
    }

    function dataSourceGetMatchesResults() external onlyAdmin {
        dataSource.getMatchResults();
    }

    function dataSourceGetBonusResults() external onlyAdmin{
        dataSource.getBonusResults();
    }

    function dataSourceGetExtraStats() external onlyAdmin{
        dataSource.getExtraStats();
    }

    function dataSourceCallbackMatch(uint160 matches) external onlyDataSource{
        uint160 m = matches;
        for(uint256 i = 0; i < MATCHES_NUMBER; i++) {
            matchResults[MATCHES_NUMBER - i - 1].result = uint8(m & MATCH_RESULT_MASK);
            matchResults[MATCHES_NUMBER - i - 1].under49 = uint8((m >> 2) & MATCH_UNDEROVER_MASK);
            matchResults[MATCHES_NUMBER - i - 1].touchdowns = uint8((m >> 3) & MATCH_TOUCHDOWNS_MASK);
            m = m >> 8;
        }
    }

    function dataSourceCallbackBonus(uint32 bonusResults) external onlyDataSource{
        uint32 b = bonusResults;
        for(uint256 i = 0; i < BONUS_MATCHES; i++) {
            bonusMatches[BONUS_MATCHES - i - 1].bonus = uint8(b & BONUS_STAT_MASK);
            b = b >> 6;
        }
    }

    function dataSourceCallbackExtras(uint96 es) external onlyDataSource{
        uint96 e = es;
        extraStats.interceptions = uint16(e & EXTRA_STATS_MASK);
        e = e >> 16;
        extraStats.missedFieldGoals = uint16(e & EXTRA_STATS_MASK);
        e = e >> 16;
        extraStats.overtimes = uint16(e & EXTRA_STATS_MASK);
        e = e >> 16;
        extraStats.sacks = uint16(e & EXTRA_STATS_MASK);
        e = e >> 16;
        extraStats.fieldGoals = uint16(e & EXTRA_STATS_MASK);
        e = e >> 16;
        extraStats.fumbles = uint16(e & EXTRA_STATS_MASK);
    }

     
    function calculatePointsBlock(uint32 amount) external{

        require (gameFinishedTime == 0);
        require(amount + lastCheckedToken <= tokens.length);

        for (uint256 i = lastCalculatedToken; i < (lastCalculatedToken + amount); i++) {
            uint16 points = PointsCalculator.calculateTokenPoints(tokens[i].matches, tokens[i].bonusMatches,
                tokens[i].extraStats, matchResults, extraStats, bonusMatches, starMatches);
            tokenToPointsMap[i] = points;
        }

        lastCalculatedToken += amount;
    }

     
    function setPayoutDistributionId () internal {

        uint24[21] memory auxArr = PayoutDistribution.getDistribution(tokens.length);

        for(uint256 i = 0; i < auxArr.length; i++){
            payoutDistribution[i] = auxArr[i];
        }
        
        superiorQuota = PayoutDistribution.getSuperiorQuota(tokens.length);
    }

     
    function setLimit(uint256 tokenId) external onlyAdmin{
        require(tokenId < tokens.length);
        require(pValidationState == pointsValidationState.Unstarted || pValidationState == pointsValidationState.LimitSet);
        pointsLimit = tokenId;
        pValidationState = pointsValidationState.LimitSet;
        lastCheckedToken = 0;
        lastCalculatedToken = 0;
        winnerCounter = 0;
        
        setPause();
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

        for(uint256 i = 0; i < sortedChunk.length - 1; i++){
            uint256 id = sortedChunk[i];
            uint256 sigId = sortedChunk[i+1];
            require(tokenToPointsMap[id] > tokenToPointsMap[sigId] || (tokenToPointsMap[id] == tokenToPointsMap[sigId] &&
                id < sigId));
        }

        if(sortedWinners.length != 0){
            uint256 id2 = sortedWinners[sortedWinners.length-1];
            uint256 sigId2 = sortedChunk[0];
            require(tokenToPointsMap[id2] > tokenToPointsMap[sigId2] ||
                (tokenToPointsMap[id2] == tokenToPointsMap[sigId2] && id2 < sigId2));
        }

        for(uint256 j = 0; j < sortedChunk.length; j++){
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
                    } else {
                        tokenToPayoutMap[currentTokenId] = payoutDistribution[payoutRange];
                    }
                }

                 
                if(counter != 0 && (currentTokenPoints != lastTokenPoints || (inRangecounter == 0 && payoutRange == maxRange - 1))){ 
                    for(uint256 i = 0; i < tokenEqualsCounter; i++){
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


      
    function setEnd() external onlyAdmin checkState(pointsValidationState.WinnersAssigned){
            
        uint256 balance = address(this).balance;
        adminPool = balance.mul(10).div(100);
        prizePool = balance.mul(90).div(100);

        pValidationState = pointsValidationState.Finished;
        gameFinishedTime = now;
        unSetPause();
    }

}

 

contract CryptocupNFL is GameRegistry {

	constructor() public {
        adminAddress = msg.sender;
        deploymentTime = now;

        _prepareMatchResultsArray();
        _prepareBonusResultsArray();
    }

      
    function() external payable {
        require(msg.sender == adminAddress || msg.sender == marketplaceAddress);

    }

    function buildToken(uint160 matches, uint32 bonusMatches, uint96 extraStats, string message) external payable isNotPaused returns(uint256){

        require(msg.value >= _getTokenPrice(), "Eth sent is not enough.");
        require(msg.sender != address(0), "Sender cannot be 0 address.");
        require(ownedTokens[msg.sender].length < 100, "Sender cannot have more than 100 tokens.");
        require(now < EVENT_START, "Event already started.");  
        require (bytes(message).length <= 100);
        

        uint256 tokenId = _createToken(matches, bonusMatches, extraStats, message);
        
        _mint(msg.sender, tokenId);
        
        emit LogTokenBuilt(msg.sender, tokenId, message, matches, extraStats, bonusMatches);

        return tokenId;
    }

    function giftToken(address giftedAddress, uint160 matches, uint32 bonusMatches, uint96 extraStats, string message) external payable isNotPaused returns(uint256){

        require(msg.value >= _getTokenPrice(), "Eth sent is not enough.");
        require(msg.sender != address(0), "Sender cannot be 0 address.");
        require(ownedTokens[giftedAddress].length < 100, "Sender cannot have more than 100 tokens.");
        require(now < EVENT_START, "Event already started.");  
        require (bytes(message).length <= 100);

        uint256 tokenId = _createToken(matches, bonusMatches, extraStats, message);

        _mint(giftedAddress, tokenId);
        
        emit LogTokenGift(msg.sender, giftedAddress, tokenId, message, matches, extraStats, bonusMatches);

        return tokenId;
    }

    function buildPrepaidToken(bytes32 secret) external payable onlyAdmin isNotPaused {

        require(msg.value >= _getTokenPrice(), "Eth sent is not enough.");
        require(msg.sender != address(0), "Sender cannot be 0 address.");
        require(now < EVENT_START, "Event already started.");  

        secretsMap[secret] = 1;
        
        emit LogPrepaidTokenBuilt(msg.sender, secret);
    }

    function redeemPrepaidToken(bytes32 preSecret, uint160 matches, uint32 bonusMatches, uint96 extraStats, string message) external isNotPaused returns(uint256){

        require(msg.sender != address(0), "Sender cannot be 0 address.");
        require(ownedTokens[msg.sender].length < 100, "Sender cannot have more than 100 tokens.");
        require(now < EVENT_START, "Event already started.");  
        require (bytes(message).length <= 100);

        bytes32 secret = keccak256(preSecret);

        require (secretsMap[secret] == 1, "Invalid secret.");
        
        secretsMap[secret] = 0;

        uint256 tokenId = _createToken(matches, bonusMatches, extraStats, message);
        _mint(msg.sender, tokenId);
        
        emit LogPrepaidRedeemed(msg.sender, tokenId, message, matches, extraStats, bonusMatches);

        return tokenId;
    }


     
    function getToken(uint256 tokenId) external view returns (uint160 matches, uint32 bonusMatches, uint96 extraStats, uint64 timeStamp, string message) {

        Token storage token = tokens[tokenId];

        matches = token.matches;
        bonusMatches = token.bonusMatches;
        extraStats = token.extraStats;
        timeStamp = token.timeStamp;
        message = token.message;

    }

     
    function withdrawPrize() external checkState(pointsValidationState.Finished){
        
        uint256 prize = 0;
        uint256[] memory tokenList = ownedTokens[msg.sender];
        
        for(uint256 i = 0;i < tokenList.length; i++){
            prize += tokenToPayoutMap[tokenList[i]];
            tokenToPayoutMap[tokenList[i]] = 0;
        }
        
        require(prize > 0);
        msg.sender.transfer((prizePool.mul(prize)).div(1000000));   
    }


     
     

     
    function emergencyWithdraw() external hasFinalized{

        uint256 balance = STARTING_PRICE * ownedTokens[msg.sender].length;

        delete ownedTokens[msg.sender];
        msg.sender.transfer(balance);

    }

}
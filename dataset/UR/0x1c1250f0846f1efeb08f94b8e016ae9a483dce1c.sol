 

 

pragma solidity ^0.5.0;

 
contract SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b != 0);  
        uint256 c = a / b;
        assert(a == b * c + a % b);  
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

    function mulByFraction(uint256 number, uint256 numerator, uint256 denominator) internal pure returns (uint256) {
        return div(mul(number, numerator), denominator);
    }
}

contract Owned {

    address payable public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address payable newOwner) onlyOwner public {
        require(newOwner != address(0x0));
        owner = newOwner;
    }
}

 
interface OracleContract {
    function getEventOutputPossibleResultsCount(uint id, uint outputId) external view returns(uint possibleResultsCount); 
    function getOracleVersion() external view returns(uint version);
    function owner() external view returns (address);
    function getEventDataForHouse(uint id, uint outputId) external view returns(uint startDateTime, uint outputDateTime, bool isCancelled, uint timeStamp);
    function getEventOutcomeIsSet(uint eventId, uint outputId) external view returns (bool isSet);
    function getEventOutcome(uint eventId, uint outputId) external view returns (uint outcome); 
    function getEventOutcomeNumeric(uint eventId, uint outputId) external view returns(uint256 outcome1, uint256 outcome2,uint256 outcome3,uint256 outcome4, uint256 outcome5, uint256 outcome6);
}

 
interface HouseContract {
    function owner() external view returns (address payable); 
    function isHouse() external view returns (bool); 
}



 
contract House is SafeMath, Owned {

    uint constant mimumumSupportedOracle = 105;

    enum BetType { headtohead, multiuser, poolbet }

    enum BetEvent { placeBet, callBet, removeBet, refuteBet, settleWinnedBet, settleCancelledBet, increaseWager, cancelledByHouse }

    uint private betNextId;




    struct Bet { 
        address oracleAddress;
        uint256 dataCombined;
        bool isOutcomeSet;
        bool isCancelled;
        uint256 minimumWager;
        uint256 maximumWager;
        address createdBy;
        BetType betType;
    } 

    struct HouseData { 
        bool managed;
        string  name;
        string  creatorName;
        address oracleAddress;
        address oldOracleAddress;       
        bool  newBetsPaused;
        uint  housePercentage;
        uint oraclePercentage;   
        uint version;
        string shortMessage;          
    } 

    address public _newHouseAddress;

    HouseData public houseData;  

     
    mapping (uint => Bet) public bets;

     
    mapping (address => uint256) public balance;


     
    uint public lastBettingActivity;

    uint public closeBeforeStartTime;
        
    uint public closeEventOutcomeTime;  

     
    mapping (uint => uint256) public betTotalAmount;

     
    mapping (uint => uint) public betTotalBets;

     
    mapping (uint => uint256) public betRefutedAmount;

     
    mapping (uint => mapping (uint => uint256)) public betForcastTotalAmount;    

     
    mapping (address => mapping (uint => uint256)) public playerBetTotalAmount;

     
    mapping (address => mapping (uint => uint)) public playerBetTotalBets;

     
    mapping (address => mapping (uint => mapping (uint => uint256))) public playerBetForecastWager;

     
    mapping (uint => mapping (address => uint)) public headToHeadForecasts;  

     
    mapping (address => mapping (uint => bool)) public playerBetRefuted;    

     
    mapping (address => mapping (uint => bool)) public playerBetSettled; 

     
    mapping (uint => bool) public housePaid;

     
    mapping (address => bool) public playerHasBet;

     
    event HouseCreated();

     
    event HousePropertiesUpdated();    

    event BetPlacedOrModified(uint id, address sender, BetEvent betEvent, uint256 amount, uint forecast, string createdBy, uint closeDateTime);


    event transfer(address indexed wallet, uint256 amount,bool inbound);


     
    constructor(bool managed, string memory houseName, string memory houseCreatorName, address oracleAddress, uint housePercentage,uint oraclePercentage, uint closeTime, uint freezeTime, uint version) public {
        require(add(housePercentage,oraclePercentage)<1000,"House + Oracle percentage should be lower than 100%");
        require(OracleContract(oracleAddress).getOracleVersion() >= mimumumSupportedOracle , "Oracle version don't supported");
        houseData.managed = managed;
        houseData.name = houseName;
        houseData.creatorName = houseCreatorName;
        houseData.housePercentage = housePercentage;
        houseData.oraclePercentage = oraclePercentage; 
        houseData.oracleAddress = oracleAddress;      
        houseData.shortMessage = "";
        houseData.newBetsPaused = true;
        houseData.version = version;

        closeBeforeStartTime = closeTime;
        closeEventOutcomeTime = freezeTime;

        emit HouseCreated();
    }


    function getBetInternal(uint id) public view returns (uint eventId, uint outputId, uint outcome, uint closeDateTime, uint freezeDateTime, uint payoutRate, uint timeStamp) {
        uint256 dataCombined = bets[id].dataCombined;
        return (uint32(dataCombined), uint32(dataCombined >> 32), uint32(dataCombined >> 64), uint32(dataCombined >> 96), uint32(dataCombined >> 128), uint24(dataCombined >> 160), uint32(dataCombined >> 184));
    }

    function getBetEventId(uint id) public view returns (uint eventId) {
        return (uint32(bets[id].dataCombined));
    }

    function getBetEventOutputId(uint id) public view returns (uint eventOutputId) {
        return (uint32(bets[id].dataCombined >> 32));
    }

    function getBetOutcome(uint id) public view returns (uint eventOutcome) {
        return (uint32(bets[id].dataCombined >> 64));
    }

    function getBetCloseTime(uint id) public view returns (uint betCloseTime) {
        return (uint32(bets[id].dataCombined >> 96));
    }

    function getBetFreezeTime(uint id) public view returns (uint betFreezeTime) {
        return (uint32(bets[id].dataCombined >> 128));
    }

    function getBetPayoutRate(uint id) public view returns (uint eventId) {
        return (uint24(bets[id].dataCombined >> 160));
    }

    function getBetEventTimeStamp(uint id) public view returns (uint timeStamp) {
        return (uint32(bets[id].dataCombined >> 184));
    }

    function setBetInternal(uint id, uint eventId, uint outputId, uint outcome, uint closeDateTime, uint freezeDateTime, uint payoutRate, uint timeStamp) private {
        bets[id].dataCombined = (eventId & 0xFFFFFFFF) | ((outputId & 0xFFFFFFFF) << 32) | ((outcome & 0xFFFFFFFF) << 64) | ((closeDateTime & 0xFFFFFFFF) << 96) | ((freezeDateTime & 0xFFFFFFFF) << 128 | ((payoutRate & 0xFFFFFF) << 160) | ((timeStamp & 0xFFFFFFFF) << 184));
    }

    function setBetEventTimeStamp(uint id, uint timeStamp) private {
        (uint  eventId, uint  outputId, uint  outcome, uint  closeDateTime, uint freezeDateTime, uint payoutRate, ) = getBetInternal(id);
        bets[id].dataCombined = (eventId & 0xFFFFFFFF) | ((outputId & 0xFFFFFFFF) << 32) | ((outcome & 0xFFFFFFFF) << 64) | ((closeDateTime & 0xFFFFFFFF) << 96) | ((freezeDateTime & 0xFFFFFFFF) << 128) | ((payoutRate & 0xFFFFFF) << 160) | ((timeStamp & 0xFFFFFFFF) << 184);
    }

    function setBetEventId(uint id, uint eventId) private {
        (, uint  outputId, uint  outcome, uint  closeDateTime, uint freezeDateTime, uint payoutRate, uint timeStamp) = getBetInternal(id);
        bets[id].dataCombined = (eventId & 0xFFFFFFFF) | ((outputId & 0xFFFFFFFF) << 32) | ((outcome & 0xFFFFFFFF) << 64) | ((closeDateTime & 0xFFFFFFFF) << 96) | ((freezeDateTime & 0xFFFFFFFF) << 128) | ((payoutRate & 0xFFFFFF) << 160) | ((timeStamp & 0xFFFFFFFF) << 184);
    }

    function setBetEventOutputId(uint id, uint outputId) private {
        (uint  eventId, , uint  outcome, uint  closeDateTime, uint freezeDateTime, uint payoutRate, uint timeStamp ) = getBetInternal(id);
        bets[id].dataCombined = (eventId & 0xFFFFFFFF) | ((outputId & 0xFFFFFFFF) << 32) | ((outcome & 0xFFFFFFFF) << 64) | ((closeDateTime & 0xFFFFFFFF) << 96) | ((freezeDateTime & 0xFFFFFFFF) << 128) | ((payoutRate & 0xFFFFFF) << 160) | ((timeStamp & 0xFFFFFFFF) << 184);
    }

    function setBetOutcome(uint id, uint outcome) private {
        (uint  eventId, uint  outputId, , uint  closeDateTime, uint freezeDateTime, uint payoutRate, uint timeStamp) = getBetInternal(id);
        bets[id].dataCombined = (eventId & 0xFFFFFFFF) | ((outputId & 0xFFFFFFFF) << 32) | ((outcome & 0xFFFFFFFF) << 64) | ((closeDateTime & 0xFFFFFFFF) << 96) | ((freezeDateTime & 0xFFFFFFFF) << 128) | ((payoutRate & 0xFFFFFF) << 160) | ((timeStamp & 0xFFFFFFFF) << 184);
    }

    function setBetCloseTime(uint id, uint closeDateTime) private {
        (uint  eventId, uint  outputId, uint  outcome, , uint freezeDateTime, uint payoutRate, uint timeStamp) = getBetInternal(id);
        bets[id].dataCombined = (eventId & 0xFFFFFFFF) | ((outputId & 0xFFFFFFFF) << 32) | ((outcome & 0xFFFFFFFF) << 64) | ((closeDateTime & 0xFFFFFFFF) << 96) | ((freezeDateTime & 0xFFFFFFFF) << 128) | ((payoutRate & 0xFFFFFF) << 160) | ((timeStamp & 0xFFFFFFFF) << 184);
    }

    function setBetFreezeTime(uint id, uint freezeDateTime) private {
        (uint  eventId, uint  outputId, uint  outcome, uint  closeDateTime, , uint payoutRate, uint timeStamp) = getBetInternal(id);
        bets[id].dataCombined = (eventId & 0xFFFFFFFF) | ((outputId & 0xFFFFFFFF) << 32) | ((outcome & 0xFFFFFFFF) << 64) | ((closeDateTime & 0xFFFFFFFF) << 96) | ((freezeDateTime & 0xFFFFFFFF) << 128) | ((payoutRate & 0xFFFFFF) << 160) | ((timeStamp & 0xFFFFFFFF) << 184);
    }

    function setBetPayoutRate(uint id, uint payoutRate) private {
        (uint  eventId, uint  outputId, uint  outcome, uint  closeDateTime, uint freezeDateTime, , uint timeStamp) = getBetInternal(id);
        bets[id].dataCombined = (eventId & 0xFFFFFFFF) | ((outputId & 0xFFFFFFFF) << 32) | ((outcome & 0xFFFFFFFF) << 64) | ((closeDateTime & 0xFFFFFFFF) << 96) | ((freezeDateTime & 0xFFFFFFFF) << 128 | ((payoutRate & 0xFFFFFF) << 160) | ((timeStamp & 0xFFFFFFFF) << 184));
    }

    


     
    function isHouse() public pure returns(bool response) {
        return true;    
    }

      
    function updateHouseProperties(string memory houseName, string memory houseCreatorName) onlyOwner public {
        houseData.name = houseName;
        houseData.creatorName = houseCreatorName; 
        emit HousePropertiesUpdated();
    }    

     
    function setTimeConstants(uint closeTime, uint freezeTime) onlyOwner public {
        closeBeforeStartTime = closeTime;
        closeEventOutcomeTime = freezeTime;
        emit HousePropertiesUpdated();
    }   

     
    function changeHouseOracle(address oracleAddress, uint oraclePercentage) onlyOwner public {
        require(add(houseData.housePercentage,oraclePercentage)<1000,"House + Oracle percentage should be lower than 100%");
        if (oracleAddress != houseData.oracleAddress) {
            houseData.oldOracleAddress = houseData.oracleAddress;
            houseData.oracleAddress = oracleAddress;
        }
        houseData.oraclePercentage = oraclePercentage;
        emit HousePropertiesUpdated();
    } 

     
    function changeHouseEdge(uint housePercentage) onlyOwner public {
        require(housePercentage != houseData.housePercentage,"New percentage is identical with current");
        require(add(housePercentage,houseData.oraclePercentage)<1000,"House + Oracle percentage should be lower than 100%");
        houseData.housePercentage = housePercentage;
        emit HousePropertiesUpdated();
    } 



    function updateBetDataFromOracle(uint betId, uint eventId, uint eventOutputId) private {
        if (!bets[betId].isOutcomeSet) {
            (bets[betId].isOutcomeSet) = OracleContract(bets[betId].oracleAddress).getEventOutcomeIsSet(eventId,eventOutputId); 
        }
        if (bets[betId].isOutcomeSet) {
            (uint outcome) = OracleContract(bets[betId].oracleAddress).getEventOutcome(eventId,eventOutputId); 
            setBetOutcome(betId,outcome);
        }
            
        if (!bets[betId].isCancelled) {
            uint eventStart;
            uint eventOutcomeDateTime;
            uint eventTimeStamp;
            (eventStart, eventOutcomeDateTime, bets[betId].isCancelled, eventTimeStamp) = OracleContract(bets[betId].oracleAddress).getEventDataForHouse(eventId, eventOutputId); 
            uint currentEventTimeStamp = getBetEventTimeStamp(betId);
            if (currentEventTimeStamp==0) {
                setBetEventTimeStamp(betId, eventTimeStamp);
            } else if (currentEventTimeStamp != eventTimeStamp) {
                bets[betId].isCancelled = true;
            }
            setBetFreezeTime(betId, eventOutcomeDateTime + closeEventOutcomeTime * 1 minutes);
            if (getBetCloseTime(betId) == 0) {
                setBetCloseTime(betId, eventStart - closeBeforeStartTime * 1 minutes);
            }  
            if (!bets[betId].isOutcomeSet && getBetFreezeTime(betId) <= now) {
            bets[betId].isCancelled = true;
            }  
        }  
        
    }

     
    function getEventOutputMaxUint(address oracleAddress, uint eventId, uint outputId) private view returns (uint) {
        return 2 ** OracleContract(oracleAddress).getEventOutputPossibleResultsCount(eventId,outputId) - 1;
    }


    function checkPayoutRate(uint256 payoutRate) public view {
        uint256 multBase = 10 ** 18;
        uint256 houseFees = houseData.housePercentage + houseData.oraclePercentage;
        uint256 check1 = div(multBase , (1000 - houseFees));
        check1 = div(mul(100000 , check1), multBase);
        uint256 check2 = 10000;
        if (houseFees > 0) {
            check2 =  div(multBase , houseFees);
            check2 = div(mul(100000 ,check2), multBase);
        }
        require(payoutRate>check1 && payoutRate<check2,"Payout rate out of accepted range");
    }


     
    function placePoolBet(uint eventId, uint outputId, uint forecast, uint closingDateTime, uint256 minimumWager, uint256 maximumWager, string memory createdBy) payable public {
        require(msg.value > 0,"Wager should be greater than zero");
        require(!houseData.newBetsPaused,"Bets are paused right now");
        betNextId += 1;
        bets[betNextId].oracleAddress = houseData.oracleAddress;
        bets[betNextId].betType = BetType.poolbet;
        bets[betNextId].createdBy = msg.sender;

        updateBetDataFromOracle(betNextId, eventId, outputId);
        require(!bets[betNextId].isCancelled,"Event has been cancelled");
        require(!bets[betNextId].isOutcomeSet,"Event has already an outcome");
        if (closingDateTime>0) {
            setBetCloseTime(betNextId, closingDateTime);
        } 
        uint betCloseTime = getBetCloseTime(betNextId);
        require(betCloseTime >= now,"Close time has passed");
        setBetEventId(betNextId, eventId);
        setBetEventOutputId(betNextId, outputId);
        if (minimumWager != 0) {
            bets[betNextId].minimumWager = minimumWager;
        } else {
            bets[betNextId].minimumWager = msg.value;
        }
        if (maximumWager != 0) {
            bets[betNextId].maximumWager = maximumWager;
        }
 
        playerBetTotalBets[msg.sender][betNextId] = 1;
        betTotalBets[betNextId] = 1;
        betTotalAmount[betNextId] = msg.value;
 
        betForcastTotalAmount[betNextId][forecast] = msg.value;

        playerBetTotalAmount[msg.sender][betNextId] = msg.value;

        playerBetForecastWager[msg.sender][betNextId][forecast] = msg.value;

        lastBettingActivity = block.number;

        playerHasBet[msg.sender] = true;
        
        emit BetPlacedOrModified(betNextId, msg.sender, BetEvent.placeBet, msg.value, forecast, createdBy, betCloseTime);
    }  

     
    function placeH2HBet(uint eventId, uint outputId, uint forecast, uint closingDateTime, uint256 payoutRate, string memory createdBy) payable public {
        require(msg.value > 0,"Wager should be greater than zero");
        require(!houseData.newBetsPaused,"Bets are paused right now");
        betNextId += 1;
        bets[betNextId].oracleAddress = houseData.oracleAddress;
        bets[betNextId].betType = BetType.headtohead;
        bets[betNextId].createdBy = msg.sender;
        updateBetDataFromOracle(betNextId, eventId, outputId);
        require(!bets[betNextId].isCancelled,"Event has been cancelled");
        require(!bets[betNextId].isOutcomeSet,"Event has already an outcome");
        if (closingDateTime>0) {
            setBetCloseTime(betNextId, closingDateTime);
        } 
        uint betCloseTime = getBetCloseTime(betNextId);
        require( betCloseTime >= now,"Close time has passed");
        setBetEventId(betNextId, eventId);
        setBetEventOutputId(betNextId, outputId);
        checkPayoutRate(payoutRate);
        require(forecast>0 && forecast < getEventOutputMaxUint(bets[betNextId].oracleAddress, eventId, outputId),"Forecast should be greater than zero and less than Max accepted forecast(All options true)");
        setBetPayoutRate(betNextId, payoutRate);
        headToHeadForecasts[betNextId][msg.sender] = forecast;
        
              
        playerBetTotalBets[msg.sender][betNextId] = 1;
        betTotalBets[betNextId] = 1;
        betTotalAmount[betNextId] = msg.value;
 
        betForcastTotalAmount[betNextId][forecast] = msg.value;

        playerBetTotalAmount[msg.sender][betNextId] = msg.value;

        playerBetForecastWager[msg.sender][betNextId][forecast] = msg.value;

        lastBettingActivity = block.number;
        
        playerHasBet[msg.sender] = true;

        emit BetPlacedOrModified(betNextId, msg.sender, BetEvent.placeBet, msg.value, forecast, createdBy, betCloseTime);
    }

 


     
    function callBet(uint betId, uint forecast, string memory createdBy) payable public {
        require(msg.value>0,"Wager should be greater than zero");
        require(bets[betId].betType == BetType.headtohead || bets[betId].betType == BetType.poolbet,"Only poolbet and headtohead bets are implemented");
        require(bets[betId].betType != BetType.headtohead || betTotalBets[betId] == 1,"Head to head bet has been already called");
        require(msg.value>=bets[betId].minimumWager,"Wager is lower than the minimum accepted");
        require(bets[betId].maximumWager==0 || msg.value<=bets[betId].maximumWager,"Wager is higher then the maximum accepted");
        uint eventId = getBetEventId(betId);
        uint outputId = getBetEventOutputId(betId);
        updateBetDataFromOracle(betId, eventId, outputId);
        require(!bets[betId].isCancelled,"Bet has been cancelled");
        require(!bets[betId].isOutcomeSet,"Event has already an outcome");
        uint betCloseTime = getBetCloseTime(betId);
        require(betCloseTime >= now,"Close time has passed");
        if (bets[betId].betType == BetType.headtohead) {
            require(bets[betId].createdBy != msg.sender,"Player has been opened the bet");
            require(msg.value == mulByFraction( betTotalAmount[betId], getBetPayoutRate(betId) - 100, 100),"Wager should be equal to [Opened bet Wager  * PayoutRate - 100]");
            require(headToHeadForecasts[betId][bets[betId].createdBy] & forecast == 0,"Forecast overlaps opened bet forecast");
            require(headToHeadForecasts[betId][bets[betId].createdBy] | forecast == getEventOutputMaxUint(bets[betId].oracleAddress, eventId, outputId),"Forecast should be opposite to the opened");
            headToHeadForecasts[betId][msg.sender] = forecast;           
        } else if (bets[betId].betType == BetType.poolbet) {
            require(playerBetForecastWager[msg.sender][betId][forecast] == 0,"Already placed a bet on this forecast, use increaseWager method instead");
        }

        betTotalBets[betId] += 1;
        betTotalAmount[betId] += msg.value;

        playerBetTotalBets[msg.sender][betId] += 1;

        betForcastTotalAmount[betId][forecast] += msg.value;

        playerBetTotalAmount[msg.sender][betId] += msg.value;

        playerBetForecastWager[msg.sender][betId][forecast] = msg.value;

        lastBettingActivity = block.number;

        playerHasBet[msg.sender] = true;

        emit BetPlacedOrModified(betId, msg.sender, BetEvent.callBet, msg.value, forecast, createdBy, betCloseTime);   
    }  

     
    function increaseWager(uint betId, uint forecast, string memory createdBy) payable public {
        require(msg.value > 0,"Increase wager amount should be greater than zero");
        require(bets[betId].betType == BetType.poolbet,"Only poolbet supports the increaseWager");
        require(playerBetForecastWager[msg.sender][betId][forecast] > 0,"Haven't placed any bet for this forecast. Use callBet instead");
        uint256 wager = playerBetForecastWager[msg.sender][betId][forecast] + msg.value;
        require(bets[betId].maximumWager==0 || wager<=bets[betId].maximumWager,"The updated wager is higher then the maximum accepted");
        updateBetDataFromOracle(betId, getBetEventId(betId), getBetEventOutputId(betId));
        require(!bets[betId].isCancelled,"Bet has been cancelled");
        require(!bets[betId].isOutcomeSet,"Event has already an outcome");
        uint betCloseTime = getBetCloseTime(betId);
        require(betCloseTime >= now,"Close time has passed");
        betTotalAmount[betId] += msg.value;

        betForcastTotalAmount[betId][forecast] += msg.value;

        playerBetTotalAmount[msg.sender][betId] += msg.value;

        playerBetForecastWager[msg.sender][betId][forecast] += msg.value;

        lastBettingActivity = block.number;

        emit BetPlacedOrModified(betId, msg.sender, BetEvent.increaseWager, msg.value, forecast, createdBy, betCloseTime);       
    }

     
    function removeBet(uint betId, string memory createdBy) public {
        require(bets[betId].createdBy == msg.sender,"Caller and player created don't match");
        require(playerBetTotalBets[msg.sender][betId] > 0, "Player should has placed at least one bet");
        require(betTotalBets[betId] == playerBetTotalBets[msg.sender][betId],"The bet has been called by other player");
        require(bets[betId].betType == BetType.headtohead || bets[betId].betType == BetType.poolbet,"Only poolbet and headtohead bets are implemented");
        updateBetDataFromOracle(betId, getBetEventId(betId), getBetEventOutputId(betId));
        bets[betId].isCancelled = true;
        uint256 wager = betTotalAmount[betId];
        betTotalBets[betId] = 0;
        betTotalAmount[betId] = 0;
        playerBetTotalAmount[msg.sender][betId] = 0;
        playerBetTotalBets[msg.sender][betId] = 0;
        lastBettingActivity = block.number;    
        msg.sender.transfer(wager);   
        emit BetPlacedOrModified(betId, msg.sender, BetEvent.removeBet, wager, 0, createdBy, getBetCloseTime(betId));      
    } 

     
    function refuteBet(uint betId, string memory createdBy) public {
        require(playerBetTotalAmount[msg.sender][betId]>0,"Caller hasn't placed any bet");
        require(!playerBetRefuted[msg.sender][betId],"Already refuted");
        require(bets[betId].betType == BetType.headtohead || bets[betId].betType == BetType.poolbet,"Only poolbet and headtohead bets are implemented");
        updateBetDataFromOracle(betId, getBetEventId(betId), getBetEventOutputId(betId)); 
        require(bets[betId].isOutcomeSet, "Refute isn't allowed when no outcome has been set");
        require(getBetFreezeTime(betId) > now, "Refute isn't allowed when Event freeze has passed");
        playerBetRefuted[msg.sender][betId] = true;
        betRefutedAmount[betId] += playerBetTotalAmount[msg.sender][betId];
        if (betRefutedAmount[betId] >= betTotalAmount[betId]) {
            bets[betId].isCancelled = true;   
        }
        lastBettingActivity = block.number;       
        emit BetPlacedOrModified(betId, msg.sender, BetEvent.refuteBet, 0, 0, createdBy, getBetCloseTime(betId));    
    } 

    function settleHouseFees(uint betId, uint256 houseEdgeAmountForBet, uint256 oracleEdgeAmountForBet) private {
            if (!housePaid[betId]) {
                housePaid[betId] = true;
                if (houseEdgeAmountForBet > 0) {
                    owner.transfer(houseEdgeAmountForBet);
                } 
                if (oracleEdgeAmountForBet > 0) {
                    address payable oracleOwner = HouseContract(bets[betId].oracleAddress).owner();
                    oracleOwner.transfer(oracleEdgeAmountForBet);
                } 
            }
    }

     
    function settleBet(uint betId, string memory createdBy) public {
        require(playerBetTotalAmount[msg.sender][betId]>0, "Caller hasn't placed any bet");
        require(!playerBetSettled[msg.sender][betId],"Already settled");
        require(bets[betId].betType == BetType.headtohead || bets[betId].betType == BetType.poolbet,"Only poolbet and headtohead bets are implemented");
        updateBetDataFromOracle(betId, getBetEventId(betId), getBetEventOutputId(betId));
        require(bets[betId].isCancelled || bets[betId].isOutcomeSet,"Bet should be cancelled or has an outcome");
        require(getBetFreezeTime(betId) <= now,"Bet payments are freezed");
        BetEvent betEvent;
        uint256 playerOutputFromBet = 0;
        if (bets[betId].isCancelled) {
            betEvent = BetEvent.settleCancelledBet;
            playerOutputFromBet = playerBetTotalAmount[msg.sender][betId];            
        } else {
            uint betOutcome = getBetOutcome(betId);
            uint256 houseEdgeAmountForBet = mulByFraction(betTotalAmount[betId], houseData.housePercentage, 1000);
            uint256 oracleEdgeAmountForBet = mulByFraction(betTotalAmount[betId], houseData.oraclePercentage, 1000);
            settleHouseFees(betId, houseEdgeAmountForBet, oracleEdgeAmountForBet);
            uint256 totalBetAmountAfterFees = betTotalAmount[betId] - houseEdgeAmountForBet - oracleEdgeAmountForBet;
            betEvent = BetEvent.settleWinnedBet;
            if (bets[betId].betType == BetType.poolbet) {
                if (betForcastTotalAmount[betId][betOutcome]>0) {                  
                    playerOutputFromBet = mulByFraction(totalBetAmountAfterFees, playerBetForecastWager[msg.sender][betId][betOutcome], betForcastTotalAmount[betId][betOutcome]);            
                } else {
                    playerOutputFromBet = playerBetTotalAmount[msg.sender][betId] - mulByFraction(playerBetTotalAmount[msg.sender][betId], houseData.housePercentage, 1000) - mulByFraction(playerBetTotalAmount[msg.sender][betId], houseData.oraclePercentage, 1000);
                    betEvent = BetEvent.settleCancelledBet;
                }
            } else if (bets[betId].betType == BetType.headtohead) {
                if (headToHeadForecasts[betId][msg.sender] & (2 ** betOutcome) > 0) {
                    playerOutputFromBet = totalBetAmountAfterFees;
                } else {
                    playerOutputFromBet = 0;
                }
            }
            require(playerOutputFromBet > 0,"Settled amount should be greater than zero");         
        }      
        playerBetSettled[msg.sender][betId] = true;
        lastBettingActivity = block.number;
        msg.sender.transfer(playerOutputFromBet); 
        emit BetPlacedOrModified(betId, msg.sender, betEvent, playerOutputFromBet,0, createdBy, getBetCloseTime(betId));  
    } 

    function() external payable {
        revert();
    }

     
    function withdraw(uint256 amount) public {
        require(address(this).balance>=amount,"Insufficient House balance. Shouldn't have happened");
        require(balance[msg.sender]>=amount,"Insufficient balance");
        balance[msg.sender] = sub(balance[msg.sender],amount);
        msg.sender.transfer(amount);
        emit transfer(msg.sender,amount,false);
    }

     
    function withdrawToAddress(address payable destinationAddress,uint256 amount) public {
        require(address(this).balance>=amount);
        require(balance[msg.sender]>=amount,"Insufficient balance");
        balance[msg.sender] = sub(balance[msg.sender],amount);
        destinationAddress.transfer(amount);
        emit transfer(msg.sender,amount,false);
    }



     
    function isPlayer(address playerAddress) public view returns(bool) {
        return (playerHasBet[playerAddress]);
    }

     
    function updateShortMessage(string memory shortMessage) onlyOwner public {
        houseData.shortMessage = shortMessage;
        emit HousePropertiesUpdated();
    }


     
    function startNewBets(string memory shortMessage) onlyOwner public {
        houseData.shortMessage = shortMessage;
        houseData.newBetsPaused = false;
        emit HousePropertiesUpdated();
    }

     
    function stopNewBets(string memory shortMessage) onlyOwner public {
        houseData.shortMessage = shortMessage;
        houseData.newBetsPaused = true;
        emit HousePropertiesUpdated();
    }

     
    function linkToNewHouse(address newHouseAddress) onlyOwner public {
        require(newHouseAddress!=address(this),"New address is current address");
        require(HouseContract(newHouseAddress).isHouse(),"New address should be a House smart contract");
        _newHouseAddress = newHouseAddress;
        houseData.newBetsPaused = true;
        emit HousePropertiesUpdated();
    }

     
    function unLinkNewHouse() onlyOwner public {
        _newHouseAddress = address(0);
        houseData.newBetsPaused = false;
        emit HousePropertiesUpdated();
    }

     
    function getHouseVersion() public view returns(uint version) {
        return houseData.version;
    }

     
    function cancelBet(uint betId) onlyOwner public {
        require(houseData.managed, "Cancel available on managed Houses");
        updateBetDataFromOracle(betId, getBetEventId(betId), getBetEventOutputId(betId));
        require(getBetFreezeTime(betId) > now,"Freeze time passed");       
        bets[betId].isCancelled = true;
        emit BetPlacedOrModified(betId, msg.sender, BetEvent.cancelledByHouse, 0, 0, "", getBetCloseTime(betId));  
    }

     
    function settleBetFees(uint betId) onlyOwner public {
        require(bets[betId].isCancelled || bets[betId].isOutcomeSet,"Bet should be cancelled or has an outcome");
        require(getBetFreezeTime(betId) <= now,"Bet payments are freezed");
        settleHouseFees(betId, mulByFraction(betTotalAmount[betId], houseData.housePercentage, 1000), mulByFraction(betTotalAmount[betId], houseData.oraclePercentage, 1000));
    }




}
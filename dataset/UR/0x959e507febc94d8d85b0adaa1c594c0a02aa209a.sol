 

 

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
    function eventOutputs(uint eventId, uint outputId) external view returns (bool isSet, string memory title, uint possibleResultsCount, uint  eventOutputType, string memory announcement, uint decimals); 
    function owner() external view returns (address);
    function getEventForHousePlaceBet(uint id) external view returns (uint closeDateTime, uint freezeDateTime, bool isCancelled); 
    function getEventOutcomeIsSet(uint eventId, uint outputId) external view returns (bool isSet);
    function getEventOutcome(uint eventId, uint outputId) external view returns (uint outcome); 
    function getEventOutcomeNumeric(uint eventId, uint outputId) external view returns(uint256 outcome1, uint256 outcome2,uint256 outcome3,uint256 outcome4, uint256 outcome5, uint256 outcome6);
}

 
interface HouseContract {
    function owner() external view returns (address payable); 
    function isHouse() external view returns (bool); 
}



 
contract House is SafeMath, Owned {

     

    enum BetType { headtohead, multiuser, poolbet }

    enum BetEvent { placeBet, callBet, removeBet, refuteBet, settleWinnedBet, settleCancelledBet, increaseWager, cancelledByHouse }

    uint private betNextId;


    struct Bet { 
        uint id;
        address oracleAddress;
        uint eventId;
        uint outputId;
        uint outcome;
        bool isOutcomeSet;
        uint closeDateTime;
        uint freezeDateTime;
        bool isCancelled;
        uint256 minimumWager;
        uint256 maximumWager;
        uint256 payoutRate;
        address createdBy;
        BetType betType;
    } 


    struct HouseData { 
        bool managed;
        string  name;
        string  creatorName;
        string  countryISO; 
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


     
    mapping (uint => uint256) public betTotalAmount;

     
    mapping (uint => uint) public betTotalBets;

     
    mapping (uint => uint256) public betRefutedAmount;

     
    mapping (uint => mapping (uint => uint256)) public betForcastTotalAmount;    

     
    mapping (address => mapping (uint => uint256)) public playerBetTotalAmount;

     
    mapping (address => mapping (uint => uint)) public playerBetTotalBets;

     
    mapping (address => mapping (uint => mapping (uint => uint256))) public playerBetForecastWager;

     
    mapping (uint => mapping (address => uint)) public headToHeadForecasts;  

     
    mapping (uint => uint) public headToHeadMaxAcceptedForecasts;  


     
    mapping (address => mapping (uint => bool)) public playerBetRefuted;    

     
    mapping (address => mapping (uint => bool)) public playerBetSettled; 


     
    mapping (address => uint) public ownerPerc;

     
    address payable[] public owners;

     
    mapping (uint => bool) public housePaid;

     
    mapping (address => bool) public playerHasBet;

     
    event HouseCreated();

     
    event HousePropertiesUpdated();    

    event BetPlacedOrModified(uint id, address sender, BetEvent betEvent, uint256 amount, uint forecast, string createdBy, uint closeDateTime);


    event transfer(address indexed wallet, uint256 amount,bool inbound);

    event testevent(uint betTotalAmount, uint AcceptedWager, uint headToHeadForecastsOPEN, uint matchedANDforecast, uint matchedORforecast, uint headToHeadMaxAcceptedForecast);


     
    constructor(bool managed, string memory houseName, string memory houseCreatorName, string memory houseCountryISO, address oracleAddress, address payable[] memory ownerAddress, uint[] memory ownerPercentage, uint housePercentage,uint oraclePercentage, uint version) public {
        require(add(housePercentage,oraclePercentage)<1000,"House + Oracle percentage should be lower than 100%");
        houseData.managed = managed;
        houseData.name = houseName;
        houseData.creatorName = houseCreatorName;
        houseData.countryISO = houseCountryISO;
        houseData.housePercentage = housePercentage;
        houseData.oraclePercentage = oraclePercentage; 
        houseData.oracleAddress = oracleAddress;
        houseData.shortMessage = "";
        houseData.newBetsPaused = true;
        houseData.version = version;
        uint ownersTotal = 0;
        for (uint i = 0; i<ownerAddress.length; i++) {
            owners.push(ownerAddress[i]);
            ownerPerc[ownerAddress[i]] = ownerPercentage[i];
            ownersTotal += ownerPercentage[i];
            }
        require(ownersTotal == 1000);    
        emit HouseCreated();
    }



     
    function isHouse() public pure returns(bool response) {
        return true;    
    }

      
    function updateHouseProperties(string memory houseName, string memory houseCreatorName, string memory houseCountryISO) onlyOwner public {
        houseData.name = houseName;
        houseData.creatorName = houseCreatorName;
        houseData.countryISO = houseCountryISO;     
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



    function updateBetDataFromOracle(uint betId) private {
        if (!bets[betId].isOutcomeSet) {
            (bets[betId].isOutcomeSet) = OracleContract(bets[betId].oracleAddress).getEventOutcomeIsSet(bets[betId].eventId,bets[betId].outputId); 
            if (bets[betId].isOutcomeSet) {
                (bets[betId].outcome) = OracleContract(bets[betId].oracleAddress).getEventOutcome(bets[betId].eventId,bets[betId].outputId); 
            }
        }     
        if (!bets[betId].isCancelled) {
        (bets[betId].closeDateTime, bets[betId].freezeDateTime, bets[betId].isCancelled) = OracleContract(bets[betId].oracleAddress).getEventForHousePlaceBet(bets[betId].eventId);      
        }  
        if (!bets[betId].isOutcomeSet && bets[betId].freezeDateTime <= now) {
            bets[betId].isCancelled = true;
        }
    }

     
    function getEventOutputMaxUint(address oracleAddress, uint eventId, uint outputId) private view returns (uint) {
        (bool isSet, string memory title, uint possibleResultsCount, uint  eventOutputType, string memory announcement, uint decimals) = OracleContract(oracleAddress).eventOutputs(eventId,outputId);
        return 2 ** possibleResultsCount - 1;
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
        bets[betNextId].id = betNextId;
        bets[betNextId].oracleAddress = houseData.oracleAddress;
        bets[betNextId].outputId = outputId;
        bets[betNextId].eventId = eventId;
        bets[betNextId].betType = BetType.poolbet;
        bets[betNextId].createdBy = msg.sender;
        updateBetDataFromOracle(betNextId);
        require(!bets[betNextId].isCancelled,"Event has been cancelled");
        require(!bets[betNextId].isOutcomeSet,"Event has already an outcome");
        if (closingDateTime>0) {
            bets[betNextId].closeDateTime = closingDateTime;
        }  
        require(bets[betNextId].closeDateTime >= now,"Close time has passed");
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
        
        emit BetPlacedOrModified(betNextId, msg.sender, BetEvent.placeBet, msg.value, forecast, createdBy, bets[betNextId].closeDateTime);
    }  

     
    function placeH2HBet(uint eventId, uint outputId, uint forecast, uint closingDateTime, uint256 payoutRate, string memory createdBy) payable public {
        require(msg.value > 0,"Wager should be greater than zero");
        require(!houseData.newBetsPaused,"Bets are paused right now");
        betNextId += 1;
        bets[betNextId].id = betNextId;
        bets[betNextId].oracleAddress = houseData.oracleAddress;
        bets[betNextId].outputId = outputId;
        bets[betNextId].eventId = eventId;
        bets[betNextId].betType = BetType.headtohead;
        bets[betNextId].createdBy = msg.sender;
        updateBetDataFromOracle(betNextId);
        require(!bets[betNextId].isCancelled,"Event has been cancelled");
        require(!bets[betNextId].isOutcomeSet,"Event has already an outcome");
        if (closingDateTime>0) {
            bets[betNextId].closeDateTime = closingDateTime;
        }  
        require(bets[betNextId].closeDateTime >= now,"Close time has passed");

        checkPayoutRate(payoutRate);
        uint maxAcceptedForecast = getEventOutputMaxUint(bets[betNextId].oracleAddress, bets[betNextId].eventId, bets[betNextId].outputId);
        headToHeadMaxAcceptedForecasts[betNextId] = maxAcceptedForecast;
        require(forecast>0 && forecast < maxAcceptedForecast,"Forecast should be greater than zero and less than Max accepted forecast(All options true)");
        bets[betNextId].payoutRate = payoutRate;
        headToHeadForecasts[betNextId][msg.sender] = forecast;
        
              
        playerBetTotalBets[msg.sender][betNextId] = 1;
        betTotalBets[betNextId] = 1;
        betTotalAmount[betNextId] = msg.value;
 
        betForcastTotalAmount[betNextId][forecast] = msg.value;

        playerBetTotalAmount[msg.sender][betNextId] = msg.value;

        playerBetForecastWager[msg.sender][betNextId][forecast] = msg.value;

        lastBettingActivity = block.number;
        
        playerHasBet[msg.sender] = true;

        emit BetPlacedOrModified(betNextId, msg.sender, BetEvent.placeBet, msg.value, forecast, createdBy, bets[betNextId].closeDateTime);
    }

     
    function callBet(uint betId, uint forecast, string memory createdBy) payable public {
        require(msg.value>0,"Wager should be greater than zero");
        require(bets[betId].betType == BetType.headtohead || bets[betId].betType == BetType.poolbet,"Only poolbet and headtohead bets are implemented");
        require(bets[betId].betType != BetType.headtohead || betTotalBets[betId] == 1,"Head to head bet has been already called");
        require(msg.value>=bets[betId].minimumWager,"Wager is lower than the minimum accepted");
        require(bets[betId].maximumWager==0 || msg.value<=bets[betId].maximumWager,"Wager is higher then the maximum accepted");
        updateBetDataFromOracle(betId);
        require(!bets[betId].isCancelled,"Bet has been cancelled");
        require(!bets[betId].isOutcomeSet,"Event has already an outcome");
        require(bets[betId].closeDateTime >= now,"Close time has passed");
        if (bets[betId].betType == BetType.headtohead) {
            require(bets[betId].createdBy != msg.sender,"Player has been opened the bet");
            require(msg.value == mulByFraction( betTotalAmount[betId], bets[betId].payoutRate - 100, 100),"Wager should be equal to [Opened bet Wager  * PayoutRate - 100]");
            require(headToHeadForecasts[betId][bets[betId].createdBy] & forecast == 0,"Forecast overlaps opened bet forecast");
            require(headToHeadForecasts[betId][bets[betId].createdBy] | forecast == headToHeadMaxAcceptedForecasts[betId],"Forecast should be opposite to the opened");
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

        emit BetPlacedOrModified(betId, msg.sender, BetEvent.callBet, msg.value, forecast, createdBy, bets[betId].closeDateTime);   
    }  

     
    function increaseWager(uint betId, uint forecast, string memory createdBy) payable public {
        require(msg.value > 0,"Increase wager amount should be greater than zero");
        require(bets[betId].betType == BetType.poolbet,"Only poolbet supports the increaseWager");
        require(playerBetForecastWager[msg.sender][betId][forecast] > 0,"Haven't placed any bet for this forecast. Use callBet instead");
        uint256 wager = playerBetForecastWager[msg.sender][betId][forecast] + msg.value;
        require(bets[betId].maximumWager==0 || wager<=bets[betId].maximumWager,"The updated wager is higher then the maximum accepted");
        updateBetDataFromOracle(betId);
        require(!bets[betId].isCancelled,"Bet has been cancelled");
        require(!bets[betId].isOutcomeSet,"Event has already an outcome");
        require(bets[betId].closeDateTime >= now,"Close time has passed");
        betTotalAmount[betId] += msg.value;

        betForcastTotalAmount[betId][forecast] += msg.value;

        playerBetTotalAmount[msg.sender][betId] += msg.value;

        playerBetForecastWager[msg.sender][betId][forecast] += msg.value;

        lastBettingActivity = block.number;

        emit BetPlacedOrModified(betId, msg.sender, BetEvent.increaseWager, msg.value, forecast, createdBy, bets[betId].closeDateTime);       
    }

     
    function removeBet(uint betId, string memory createdBy) public {
        require(bets[betId].createdBy == msg.sender,"Caller and player created don't match");
        require(playerBetTotalBets[msg.sender][betId] > 0, "Player should has placed at least one bet");
        require(betTotalBets[betId] == playerBetTotalBets[msg.sender][betId],"The bet has been called by other player");
        require(bets[betId].betType == BetType.headtohead || bets[betId].betType == BetType.poolbet,"Only poolbet and headtohead bets are implemented");
        updateBetDataFromOracle(betId);  
        bets[betId].isCancelled = true;
        uint256 wager = betTotalAmount[betId];
        betTotalBets[betId] = 0;
        betTotalAmount[betId] = 0;
        playerBetTotalAmount[msg.sender][betId] = 0;
        playerBetTotalBets[msg.sender][betId] = 0;
        lastBettingActivity = block.number;    
        msg.sender.transfer(wager);   
        emit BetPlacedOrModified(betId, msg.sender, BetEvent.removeBet, wager, 0, createdBy, bets[betId].closeDateTime);      
    } 

     
    function refuteBet(uint betId, string memory createdBy) public {
        require(playerBetTotalAmount[msg.sender][betId]>0,"Caller hasn't placed any bet");
        require(!playerBetRefuted[msg.sender][betId],"Already refuted");
        require(bets[betId].betType == BetType.headtohead || bets[betId].betType == BetType.poolbet,"Only poolbet and headtohead bets are implemented");
        updateBetDataFromOracle(betId);  
        require(bets[betId].isOutcomeSet, "Refute isn't allowed when no outcome has been set");
        require(bets[betId].freezeDateTime > now, "Refute isn't allowed when Event freeze has passed");
        playerBetRefuted[msg.sender][betId] = true;
        betRefutedAmount[betId] += playerBetTotalAmount[msg.sender][betId];
        if (betRefutedAmount[betId] >= betTotalAmount[betId]) {
            bets[betId].isCancelled = true;   
        }
        lastBettingActivity = block.number;       
        emit BetPlacedOrModified(betId, msg.sender, BetEvent.refuteBet, 0, 0, createdBy, bets[betId].closeDateTime);    
    } 

    function settleHouseFees(uint betId, uint256 houseEdgeAmountForBet, uint256 oracleEdgeAmountForBet) private {
            if (!housePaid[betId]) {
                housePaid[betId] = true;
                if (houseEdgeAmountForBet > 0) {
                    for (uint i = 0; i<owners.length; i++) {
                        owners[i].transfer(mulByFraction(houseEdgeAmountForBet, ownerPerc[owners[i]], 1000));
                    }
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
        updateBetDataFromOracle(betId);
        require(bets[betId].isCancelled || bets[betId].isOutcomeSet,"Bet should be cancelled or has an outcome");
        require(bets[betId].freezeDateTime <= now,"Bet payments are freezed");
        BetEvent betEvent;
        uint256 playerOutputFromBet = 0;
        if (bets[betId].isCancelled) {
            betEvent = BetEvent.settleCancelledBet;
            playerOutputFromBet = playerBetTotalAmount[msg.sender][betId];            
        } else {
            uint256 houseEdgeAmountForBet = mulByFraction(betTotalAmount[betId], houseData.housePercentage, 1000);
            uint256 oracleEdgeAmountForBet = mulByFraction(betTotalAmount[betId], houseData.oraclePercentage, 1000);
            settleHouseFees(betId, houseEdgeAmountForBet, oracleEdgeAmountForBet);
            uint256 totalBetAmountAfterFees = betTotalAmount[betId] - houseEdgeAmountForBet - oracleEdgeAmountForBet;
            betEvent = BetEvent.settleWinnedBet;
            if (bets[betId].betType == BetType.poolbet) {
                if (betForcastTotalAmount[betId][bets[betId].outcome]>0) {                  
                    playerOutputFromBet = mulByFraction(totalBetAmountAfterFees, playerBetForecastWager[msg.sender][betId][bets[betId].outcome], betForcastTotalAmount[betId][bets[betId].outcome]);            
                } else {
                    playerOutputFromBet = playerBetTotalAmount[msg.sender][betId] - mulByFraction(playerBetTotalAmount[msg.sender][betId], houseData.housePercentage, 1000) - mulByFraction(playerBetTotalAmount[msg.sender][betId], houseData.oraclePercentage, 1000);
                    betEvent = BetEvent.settleCancelledBet;
                }
            } else if (bets[betId].betType == BetType.headtohead) {
                if (headToHeadForecasts[betId][msg.sender] & (2 ** bets[betId].outcome) > 0) {
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
        emit BetPlacedOrModified(betId, msg.sender, betEvent, playerOutputFromBet,0, createdBy, bets[betId].closeDateTime);  
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

     
    function cancelBet(uint betId) onlyOwner public {
        require(houseData.managed, "Cancel available on managed Houses");
        updateBetDataFromOracle(betId);
        require(bets[betId].freezeDateTime > now,"Freeze time passed");       
        bets[betId].isCancelled = true;
        emit BetPlacedOrModified(betId, msg.sender, BetEvent.cancelledByHouse, 0, 0, "", bets[betId].closeDateTime);  
    }

     
    function settleBetFees(uint betId) onlyOwner public {
        require(bets[betId].isCancelled || bets[betId].isOutcomeSet,"Bet should be cancelled or has an outcome");
        require(bets[betId].freezeDateTime <= now,"Bet payments are freezed");
        settleHouseFees(betId, mulByFraction(betTotalAmount[betId], houseData.housePercentage, 1000), mulByFraction(betTotalAmount[betId], houseData.oraclePercentage, 1000));
    }




}
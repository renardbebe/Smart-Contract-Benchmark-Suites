 

 
 
 
 

 
 

 

 
 
 
 
 
 
 
 
 
 
 
 
 
 

 

 
 
 
 
 
 
 

 
 
 

pragma solidity ^0.4.24;

contract ZEROxRACER {

     

     
    address public owner;
    uint256 public devBalance;
    uint256 public devFeeRate = 4;  
    uint256 public precisionFactor = 6;  
    address public addressThreshold = 0x7F00000000000000000000000000000000000000;  
    uint256 public divRate = 50;  

     
    uint256 public teamOneId = 1; 
    string public teamOnePrefix = "Team 0x1234567";
    uint256 public teamOneVolume;
    uint256 public teamOneShares;
    uint256 public teamOneDivsTotal;
    uint256 public teamOneDivsUnclaimed;
    uint256 public teamOneSharePrice = 1000000000000000;  


    uint256 public teamTwoId = 2;
    string public teamTwoPrefix = "Team 0x89abcdef";
    uint256 public teamTwoVolume;
    uint256 public teamTwoShares;
    uint256 public teamTwoDivsTotal;
    uint256 public teamTwoDivsUnclaimed;
    uint256 public teamTwoSharePrice = 1000000000000000;  

     
    address[] public teamOneMembers;
    mapping (address => bool) public isTeamOneMember;
    mapping (address => uint256) public userTeamOneStake;
    mapping (address => uint256) public userTeamOneShares;
    mapping (address => uint256) private userDivsTeamOneTotal;
    mapping (address => uint256) private userDivsTeamOneClaimed;
    mapping (address => uint256) private userDivsTeamOneUnclaimed;
    mapping (address => uint256) private userDivRateTeamOne;
    
    address[] public teamTwoMembers;
    mapping (address => bool) public isTeamTwoMember;
    mapping (address => uint256) public userTeamTwoStake;
    mapping (address => uint256) public userTeamTwoShares;
    mapping (address => uint256) private userDivsTeamTwoTotal;
    mapping (address => uint256) private userDivsTeamTwoClaimed;
    mapping (address => uint256) private userDivsTeamTwoUnclaimed;
    mapping (address => uint256) private userDivRateTeamTwo;

     
    uint256 public pot;
    uint256 public timerStart;
    uint256 public timerMax;
    uint256 public roundStartTime;
    uint256 public roundEndTime;
    bool public roundOpen = false;
    bool public roundSetUp = false;
    bool public roundResolved = false;
    

     

    constructor() public {
        owner = msg.sender;
        emit contractLaunched(owner);
    }
    

     

    modifier onlyOwner() { 
        require (msg.sender == owner, "you are not the owner"); 
        _; 
    }

    modifier gameOpen() {
        require (roundResolved == false);
        require (roundSetUp == true);
        require (now < roundEndTime, "it is too late to play");
        require (now >= roundStartTime, "it is too early to play");
        _; 
    }

    modifier onlyHumans() { 
        require (msg.sender == tx.origin, "you cannot use a contract"); 
        _; 
    }
    

     

    event potFunded(
        address _funder, 
        uint256 _amount,
        string _message
    );
    
    event teamBuy(
        address _buyer, 
        uint256 _amount, 
        uint256 _teamID,
        string _message
    );
    
    event roundEnded(
        uint256 _winningTeamId, 
        string _winningTeamString, 
        uint256 _pot,
        string _message
    );
    
    event newRoundStarted(
        uint256 _timeStart, 
        uint256 _timeMax,
        uint256 _seed,
        string _message
    );

    event userWithdrew(
        address _user,
        uint256 _teamID,
        uint256 _teamAmount,
        string _message
    );

    event devWithdrew(
        address _owner,
        uint256 _amount, 
        string _message
    );

    event contractClosed(
        address _owner,
        uint256 _amount,
        string _message
    );

    event contractLaunched(
        address _owner
    );


     

     
    function openRound (uint _timerStart, uint _timerMax) public payable onlyOwner() {
        require (roundOpen == false, "you can only start the game once");
        require (roundResolved == false, "you cannot restart a finished game"); 
        require (msg.value == 2 ether, "you must give a decent seed");

         
        roundSetUp = true;
        timerStart = _timerStart;
        timerMax = _timerMax;
        roundStartTime = 1535504400;  
        roundEndTime = 1535504400 + timerStart;
        pot += msg.value;

         
         
        address devA = 0x5C035Bb4Cb7dacbfeE076A5e61AA39a10da2E956;
        address devB = 0x84ECB387395a1be65E133c75Ff9e5FCC6F756DB3;
        teamOneVolume = 1 ether;
        teamTwoVolume = 1 ether;
        teamOneMembers.push(devA);
        teamTwoMembers.push(devB);
        isTeamOneMember[devA] = true;
        isTeamOneMember[devB] = true;
        userTeamOneStake[devA] = 1 ether;
        userTeamTwoStake[devB] = 1 ether;
        userTeamOneShares[devA] = 1000;
        userTeamTwoShares[devB] = 1000;
        teamOneShares = 1000;
        teamTwoShares = 1000;

        emit newRoundStarted(timerStart, timerMax, msg.value, "a new game was just set up");
    }

     
    function devWithdraw() public onlyOwner() {
        require (devBalance > 0, "you must have an available balance");
        require(devBalance <= address(this).balance, "you cannot print money");

        uint256 shareTemp = devBalance;
        devBalance = 0;
        owner.transfer(shareTemp);

        emit devWithdrew(owner, shareTemp, "the dev just withdrew");
    }

     
     
     
     
    function zeroOut() public onlyOwner() { 
        require (now >= roundEndTime + 100 days, "too early to exit scam"); 
        require (roundResolved == true && roundOpen == false, "the game is not resolved");

        emit contractClosed(owner, address(this).balance, "the contract is now closed");

        selfdestruct(owner);
    }


     

    function buy() public payable gameOpen() onlyHumans() { 

         
        if (roundOpen == false && now >= roundStartTime && now < roundEndTime) {
            roundOpen = true;
        }
        
         
        uint256 _teamID;
        if (checkAddressTeamOne(msg.sender) == true) {
            _teamID = 1;
        } else if (checkAddressTeamTwo(msg.sender) == true) {
            _teamID = 2;
        }

         
        if (_teamID == 1 && teamOneMembers.length == 0 || _teamID == 2 && teamTwoMembers.length == 0) { 
             
             
            pot += msg.value;
        } else {
            uint256 divContribution = uint256(SafeMaths.div(SafeMaths.mul(msg.value, divRate), 100)); 
            uint256 potContribution = msg.value - divContribution;
            pot += potContribution; 
            distributeDivs(divContribution, _teamID); 
        }

         
        timeAdjustPlus();

         
        if (_teamID == 1) {
            require (msg.value >= teamOneSharePrice, "you must buy at least one Team One share");

            if (isTeamOneMember[msg.sender] == false) {
                isTeamOneMember[msg.sender] = true;
                teamOneMembers.push(msg.sender);
            }

            userTeamOneStake[msg.sender] += msg.value;
            teamOneVolume += msg.value;

             
            uint256 shareIncreaseOne = SafeMaths.mul(SafeMaths.div(msg.value, 100000), 2);  
            teamOneSharePrice += shareIncreaseOne;

            uint256 newSharesOne = SafeMaths.div(msg.value, teamOneSharePrice);
            userTeamOneShares[msg.sender] += newSharesOne;
            teamOneShares += newSharesOne;

        } else if (_teamID == 2) {
            require (msg.value >= teamTwoSharePrice, "you must buy at least one Team Two share");

            if (isTeamTwoMember[msg.sender] == false) {
                isTeamTwoMember[msg.sender] = true;
                teamTwoMembers.push(msg.sender);
            }

            userTeamTwoStake[msg.sender] += msg.value;
            teamTwoVolume += msg.value;

             
            uint256 shareIncreaseTwo = SafeMaths.mul(SafeMaths.div(msg.value, 100000), 2);  
            teamTwoSharePrice += shareIncreaseTwo;

            uint256 newSharesTwo = SafeMaths.div(msg.value, teamTwoSharePrice);
            userTeamTwoShares[msg.sender] += newSharesTwo;
            teamTwoShares += newSharesTwo;
        }
    
        emit teamBuy(msg.sender, msg.value, _teamID, "a new buy just happened");
    }  

    function resolveRound() public onlyHumans() { 

         
        require (now > roundEndTime, "you can only call this if time has expired");
        require (roundSetUp == true, "you cannot call this before the game starts");
        require (roundResolved == false, "you can only call this once");

         
        if (teamOneVolume > teamTwoVolume) {
            teamOneWin();
        } else if (teamOneVolume < teamTwoVolume) {
            teamTwoWin();
        } else if (teamOneVolume == teamTwoVolume) {
            tie();
        }

         
        roundResolved = true; 
        roundOpen = false;
    }

    function userWithdraw() public onlyHumans() {

         
        if (userTeamOneShares[msg.sender] > 0) { 

             
             
             
            userDivRateTeamOne[msg.sender] = SafeMaths.div(SafeMaths.div(SafeMaths.mul(userTeamOneShares[msg.sender], 10 ** (precisionFactor + 1)), teamOneShares) + 5, 10);
            userDivsTeamOneTotal[msg.sender] = uint256(SafeMaths.div(SafeMaths.mul(teamOneDivsTotal, userDivRateTeamOne[msg.sender]), 10 ** precisionFactor));
            userDivsTeamOneUnclaimed[msg.sender] = SafeMaths.sub(userDivsTeamOneTotal[msg.sender], userDivsTeamOneClaimed[msg.sender]);

            if (userDivsTeamOneUnclaimed[msg.sender] > 0) {
                 
                assert(userDivsTeamOneUnclaimed[msg.sender] <= address(this).balance && userDivsTeamOneUnclaimed[msg.sender] <= teamOneDivsUnclaimed);

                 
                teamOneDivsUnclaimed -= userDivsTeamOneUnclaimed[msg.sender];
                userDivsTeamOneClaimed[msg.sender] = userDivsTeamOneTotal[msg.sender];
                uint256 shareTempTeamOne = userDivsTeamOneUnclaimed[msg.sender];
                userDivsTeamOneUnclaimed[msg.sender] = 0;
                msg.sender.transfer(shareTempTeamOne);

                emit userWithdrew(msg.sender, 1, shareTempTeamOne, "a user just withdrew team one shares");
            }

        }  else if (userTeamTwoShares[msg.sender] > 0) {

             
             
             
            userDivRateTeamTwo[msg.sender] = SafeMaths.div(SafeMaths.div(SafeMaths.mul(userTeamTwoShares[msg.sender], 10 ** (precisionFactor + 1)), teamTwoShares) + 5, 10);
            userDivsTeamTwoTotal[msg.sender] = uint256(SafeMaths.div(SafeMaths.mul(teamTwoDivsTotal, userDivRateTeamTwo[msg.sender]), 10 ** precisionFactor));
            userDivsTeamTwoUnclaimed[msg.sender] = SafeMaths.sub(userDivsTeamTwoTotal[msg.sender], userDivsTeamTwoClaimed[msg.sender]);

            if (userDivsTeamTwoUnclaimed[msg.sender] > 0) {
                 
                assert(userDivsTeamTwoUnclaimed[msg.sender] <= address(this).balance && userDivsTeamTwoUnclaimed[msg.sender] <= teamTwoDivsUnclaimed);

                 
                teamTwoDivsUnclaimed -= userDivsTeamTwoUnclaimed[msg.sender];
                userDivsTeamTwoClaimed[msg.sender] = userDivsTeamTwoTotal[msg.sender];
                uint256 shareTempTeamTwo = userDivsTeamTwoUnclaimed[msg.sender];
                userDivsTeamTwoUnclaimed[msg.sender] = 0;
                msg.sender.transfer(shareTempTeamTwo);

                emit userWithdrew(msg.sender, 2, shareTempTeamTwo, "a user just withdrew team one shares");
            }
        }
    }

    function fundPot() public payable onlyHumans() gameOpen() {
         
        pot += msg.value;
        emit potFunded(msg.sender, msg.value, "a generous person funded the pot");
    }

    function reduceTime() public payable onlyHumans() gameOpen() {
         
        timeAdjustNeg();
        pot += msg.value;
        emit potFunded(msg.sender, msg.value, "someone just reduced the clock");
    }


     

    function calcUserDivsTotal(address _user) public view returns(uint256 _divs) {

         
        if (userTeamOneShares[_user] > 0) {

            uint256 userDivRateTeamOneView = SafeMaths.div(SafeMaths.div(SafeMaths.mul(userTeamOneShares[_user], 10 ** (precisionFactor + 1)), teamOneShares) + 5, 10);
            uint256 userDivsTeamOneTotalView = uint256(SafeMaths.div(SafeMaths.mul(teamOneDivsTotal, userDivRateTeamOneView), 10 ** precisionFactor));

        } else if (userTeamTwoShares[_user] > 0) {

            uint256 userDivRateTeamTwoView = SafeMaths.div(SafeMaths.div(SafeMaths.mul(userTeamTwoShares[_user], 10 ** (precisionFactor + 1)), teamTwoShares) + 5, 10);
            uint256 userDivsTeamTwoTotalView = uint256(SafeMaths.div(SafeMaths.mul(teamTwoDivsTotal, userDivRateTeamTwoView), 10 ** precisionFactor));

        }

        uint256 userDivsTotal = userDivsTeamOneTotalView + userDivsTeamTwoTotalView;
        return userDivsTotal;
    }

    function calcUserDivsAvailable(address _user) public view returns(uint256 _divs) {

         
        if (userTeamOneShares[_user] > 0) {

            uint256 userDivRateTeamOneView = SafeMaths.div(SafeMaths.div(SafeMaths.mul(userTeamOneShares[_user], 10 ** (precisionFactor + 1)), teamOneShares) + 5, 10);
            uint256 userDivsTeamOneTotalView = uint256(SafeMaths.div(SafeMaths.mul(teamOneDivsTotal, userDivRateTeamOneView), 10 ** precisionFactor));
            uint256 userDivsTeamOneUnclaimedView = SafeMaths.sub(userDivsTeamOneTotalView, userDivsTeamOneClaimed[_user]);

        } else if (userTeamTwoShares[_user] > 0) {

            uint256 userDivRateTeamTwoView = SafeMaths.div(SafeMaths.div(SafeMaths.mul(userTeamTwoShares[_user], 10 ** (precisionFactor + 1)), teamTwoShares) + 5, 10);
            uint256 userDivsTeamTwoTotalView = uint256(SafeMaths.div(SafeMaths.mul(teamTwoDivsTotal, userDivRateTeamTwoView), 10 ** precisionFactor));
            uint256 userDivsTeamTwoUnclaimedView = SafeMaths.sub(userDivsTeamTwoTotalView, userDivsTeamTwoClaimed[_user]);

        }

        uint256 userDivsUnclaimed = userDivsTeamOneUnclaimedView + userDivsTeamTwoUnclaimedView;
        return userDivsUnclaimed;
    }

    function currentRoundInfo() public view returns(
        uint256 _pot, 
        uint256 _teamOneVolume, 
        uint256 _teamTwoVolume, 
        uint256 _teamOnePlayerCount,
        uint256 _teamTwoPlayerCount,
        uint256 _totalPlayerCount,
        uint256 _timerStart, 
        uint256 _timerMax, 
        uint256 _roundStartTime, 
        uint256 _roundEndTime, 
        uint256 _timeLeft,
        string _currentWinner
    ) {
        return (
            pot, 
            teamOneVolume, 
            teamTwoVolume, 
            teamOneTotalPlayers(), 
            teamTwoTotalPlayers(), 
            totalPlayers(), 
            timerStart, 
            timerMax, 
            roundStartTime, 
            roundEndTime, 
            getTimeLeft(),
            currentWinner()
        );
    }

    function getTimeLeft() public view returns(uint256 _timeLeftSeconds) {
         
        if (now >= roundEndTime) {
            return 0;
         
        } else if (roundOpen == false && roundResolved == false && roundSetUp == false) {
            return roundStartTime - now;
         
        } else {
            return roundEndTime - now;
        }
    }
    
    function teamOneTotalPlayers() public view returns(uint256 _teamOnePlayerCount) {
        return teamOneMembers.length;
    }

    function teamTwoTotalPlayers() public view returns(uint256 _teamTwoPlayerCount) {
        return teamTwoMembers.length;
    }

    function totalPlayers() public view returns(uint256 _totalPlayerCount) {
        return teamOneMembers.length + teamTwoMembers.length;
    }

    function adjustedPotBalance() public view returns(uint256 _adjustedPotBalance) {
        uint256 devFee = uint256(SafeMaths.div(SafeMaths.mul(pot, devFeeRate), 100));
        return pot - devFee;
    }

    function contractBalance() public view returns(uint256 _contractBalance) {
        return address(this).balance;
    }

    function currentTime() public view returns(uint256 _time) {
        return now;
    }

    function currentWinner() public view returns(string _winner) {
        if (teamOneVolume > teamTwoVolume) {
            return teamOnePrefix;
        } else if (teamOneVolume < teamTwoVolume) {
            return teamTwoPrefix;
        } else if (teamOneVolume == teamTwoVolume) {
            return "a tie? wtf";
        }
    }


     

     
    function timeAdjustPlus() internal {
        if (msg.value >= 1 finney) {
            uint256 timeFactor = 1000000000000000;  
            uint256 timeShares = uint256(SafeMaths.div(msg.value, timeFactor)); 

            if (timeShares + roundEndTime > now + timerMax) {
                roundEndTime = now + timerMax;
            } else {
                roundEndTime += timeShares;  
            }
        }
    }

    function timeAdjustNeg() internal {
        if (msg.value >= 1 finney) {
            uint256 timeFactor = 1000000000000000;  
            uint256 timeShares = uint256(SafeMaths.div(msg.value, timeFactor));

             
            require (timeShares < roundEndTime, "you sent an absurd amount! relax vitalik"); 

            if (roundEndTime - timeShares < now + 5 minutes) {
                roundEndTime = now + 5 minutes;  
            } else {
                roundEndTime -= timeShares;  
            }
        }
    }

     
    function distributeDivs(uint256 _divContribution, uint256 _teamID) internal {
        if (_teamID == 1) {
            teamOneDivsTotal += _divContribution;
            teamOneDivsUnclaimed += _divContribution;
        } else if (_teamID == 2) {
            teamTwoDivsTotal += _divContribution;
            teamTwoDivsUnclaimed += _divContribution;
        }
    }

     
    function teamOneWin() internal {
        uint256 devShare = uint256(SafeMaths.div(SafeMaths.mul(pot, devFeeRate), 100)); 
        devBalance += devShare;
        uint256 potAdjusted = pot - devShare;

        teamOneDivsTotal += potAdjusted;
        teamOneDivsUnclaimed += potAdjusted;

        emit roundEnded(1, teamOnePrefix, potAdjusted, "team one won!");
    }

    function teamTwoWin() internal {
        uint256 devShare = uint256(SafeMaths.div(SafeMaths.mul(pot, devFeeRate), 100)); 
        devBalance += devShare;
        uint256 potAdjusted = pot - devShare;

        teamTwoDivsTotal += potAdjusted;
        teamTwoDivsUnclaimed += potAdjusted;

        emit roundEnded(2, teamTwoPrefix, potAdjusted, "team two won!");        
    }

    function tie() internal {  
        uint256 devShare = uint256(SafeMaths.div(SafeMaths.mul(pot, devFeeRate), 100)); 
        devBalance += devShare;
        uint256 potAdjusted = pot - devShare;

        teamOneDivsTotal += SafeMaths.div(potAdjusted, 2);
        teamOneDivsUnclaimed += SafeMaths.div(potAdjusted, 2);
        teamTwoDivsTotal += SafeMaths.div(potAdjusted, 2);
        teamTwoDivsUnclaimed += SafeMaths.div(potAdjusted, 2);

        emit roundEnded(0, "Tied", potAdjusted, "a tie?! wtf");
    }


     
    function toBytes(address a) internal pure returns (bytes b) {
        assembly {
            let m := mload(0x40)
            mstore(add(m, 20), xor(0x140000000000000000000000000000000000000000, a))
            mstore(0x40, add(m, 52))
            b := m
        }
        return b;
    }
    
     
    function toBytes1(bytes data) internal pure returns (bytes1) {
        uint val;
        for (uint i = 0; i < 1; i++)  {
            val *= 256;
            if (i < data.length)
                val |= uint8(data[i]);
        }
        return bytes1(val);
    }
    
     
    function addressToBytes1(address input) internal pure returns(bytes1) {
        bytes1 output = toBytes1(toBytes(input));
        return output;
    }

     
    function checkAddressTeamOne(address _input) internal view returns(bool) {
        if (addressToBytes1(_input) <= addressToBytes1(addressThreshold)) {
            return true;
        } else {
            return false;
        }
    }
    
    function checkAddressTeamTwo(address _input) internal view returns(bool) {
        if (addressToBytes1(_input) > addressToBytes1(addressThreshold)) {
            return true;
        } else {
            return false;
        }
    }

}  

 

library SafeMaths {

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
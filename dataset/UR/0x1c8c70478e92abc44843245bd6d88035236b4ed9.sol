 

pragma solidity ^0.4.24;

contract MajorityGameFactory {

    address[] private deployedGames;
    address[] private endedGames;

    address private adminAddress;

    mapping(address => uint) private gameAddressIdMap;

    uint private gameCount = 38;
    uint private endedGameCount = 0;

    modifier adminOnly() {
        require(msg.sender == adminAddress);
        _;
    }

    constructor () public {
        adminAddress = msg.sender;
    }

     
    function createGame (uint _gameBet, uint _endTime, string _questionText, address _officialAddress) public adminOnly payable {
        gameCount ++;
        address newGameAddress = new MajorityGame(gameCount, _gameBet, _endTime, _questionText, _officialAddress);
        deployedGames.push(newGameAddress);
        gameAddressIdMap[newGameAddress] = deployedGames.length;

        setJackpot(newGameAddress, msg.value);
    }

     
    function getDeployedGames() public view returns (address[]) {
        return deployedGames;
    }

     
    function getEndedGames() public view returns (address[]) {
        return endedGames;
    }

     
    function setJackpot(address targetAddress, uint val) adminOnly public {
        if (val > 0) {
            MajorityGame mGame = MajorityGame(targetAddress);
            mGame.setJackpot.value(val)();
        }
    }

     
    function endGame(address targetAddress) public {
        uint targetGameIndex = gameAddressIdMap[address(targetAddress)];
        endedGameCount++;
        endedGames.push(targetAddress);
        deployedGames[targetGameIndex-1] = deployedGames[deployedGames.length-1];

        gameAddressIdMap[deployedGames[deployedGames.length-1]] = targetGameIndex;

        delete deployedGames[deployedGames.length-1];
        deployedGames.length--;

        MajorityGame mGame = MajorityGame(address(targetAddress));
        mGame.endGame();
    }

     
    function forceEndGame(address targetAddress) public adminOnly {
        uint targetGameIndex = gameAddressIdMap[address(targetAddress)];
        endedGameCount++;
        endedGames.push(targetAddress);
        deployedGames[targetGameIndex-1] = deployedGames[deployedGames.length-1];

        gameAddressIdMap[deployedGames[deployedGames.length-1]] = targetGameIndex;

        delete deployedGames[deployedGames.length-1];
        deployedGames.length--;

        MajorityGame mGame = MajorityGame(address(targetAddress));
        mGame.forceEndGame();
    }
}


contract MajorityGame {

    uint private gameId;

    uint private jackpot;
    uint private gameBet;

     
    address private adminAddress;
    address private officialAddress;

     
    uint private startTime;
    uint private endTime;

     
    string private questionText;

     
    mapping(address => bool) private option1List;
    mapping(address => bool) private option2List;

     
    address[] private option1AddressList;
    address[] private option2AddressList;

	 
    uint private awardCounter;

    address[] private first6AddresstList;
    address private lastAddress;

    uint private winnerSide;
    uint private finalBalance;
    uint private award;

    modifier adminOnly() {
        require(msg.sender == adminAddress);
        _;
    }

    modifier withinGameTime() {
		require(now >= startTime);
        require(now <= endTime);
        _;
    }

    modifier afterGameTime() {
        require(now > endTime);
        _;
    }

    modifier notEnded() {
        require(winnerSide == 0);
        _;
    }

    modifier isEnded() {
        require(winnerSide > 0);
        _;
    }

    modifier withinLimitPlayer() {
        require((option1AddressList.length + option2AddressList.length) < 500);
        _;
    }

    constructor(uint _gameId, uint _gameBet, uint _endTime, string _questionText, address _officialAddress) public {
        gameId = _gameId;
        adminAddress = msg.sender;

        gameBet = _gameBet;
        startTime = _endTime - 25*60*60;
        endTime = _endTime;
        questionText = _questionText;

        winnerSide = 0;
        award = 0;

        officialAddress = _officialAddress;
    }

     
    function setJackpot() public payable adminOnly returns (bool) {
        if (msg.value > 0) {
            jackpot += msg.value;
            return true;
        }
        return false;
    }

     
    function getGameData() public view returns (uint, uint, uint, uint, uint, string, uint, uint, uint) {

        return (
            gameId,
            startTime,
            endTime,
            option1AddressList.length + option2AddressList.length,
            address(this).balance,
            questionText,
            jackpot,
            winnerSide,
            gameBet
        );
    }

     
    function submitChoose(uint _chooseValue) public payable notEnded withinGameTime {
        require(!option1List[msg.sender] && !option2List[msg.sender]);
        require(msg.value == gameBet);
		
        if (_chooseValue == 1) {
            option1List[msg.sender] = true;
            option1AddressList.push(msg.sender);
        } else if (_chooseValue == 2) {
            option2List[msg.sender] = true;
            option2AddressList.push(msg.sender);
        }

         
        if(option1AddressList.length + option2AddressList.length <= 6){
            first6AddresstList.push(msg.sender);
        }

         
        lastAddress = msg.sender;
    }

     
    function endGame() public afterGameTime {
        require(winnerSide == 0);

        finalBalance = address(this).balance;

         
        uint totalAward = finalBalance * 9 / 10;

        uint option1Count = uint(option1AddressList.length);
        uint option2Count = uint(option2AddressList.length);

        uint sumCount = option1Count + option2Count;

        if(sumCount == 0 ){
            award = 0;
            awardCounter = 0;
            if(gameId % 2 == 1){
                winnerSide = 1;
            }else{
                winnerSide = 2;
            }
            return;
        }else{
            if (option1Count != 0 && sumCount / option1Count > 10) {
				winnerSide = 1;
			} else if (option2Count != 0 && sumCount / option2Count > 10) {
				winnerSide = 2;
			} else if (option1Count > option2Count || (option1Count == option2Count && gameId % 2 == 1)) {
				winnerSide = 1;
			} else {
				winnerSide = 2;
			}
        }

        if (winnerSide == 1) {
            award = uint(totalAward / option1Count);
            awardCounter = option1Count;
        } else {
            award = uint(totalAward / option2Count);
            awardCounter = option2Count;
        }
    }

     
    function forceEndGame() public adminOnly {
        require(winnerSide == 0);

        finalBalance = address(this).balance;

         
        uint totalAward = finalBalance * 9 / 10;

        uint option1Count = uint(option1AddressList.length);
        uint option2Count = uint(option2AddressList.length);

        uint sumCount = option1Count + option2Count;

        if(sumCount == 0 ){
            award = 0;
            awardCounter = 0;
            if(gameId % 2 == 1){
                winnerSide = 1;
            }else{
                winnerSide = 2;
            }
            return;
        }

        if (option1Count != 0 && sumCount / option1Count > 10) {
            winnerSide = 1;
        } else if (option2Count != 0 && sumCount / option2Count > 10) {
            winnerSide = 2;
        } else if (option1Count > option2Count || (option1Count == option2Count && gameId % 2 == 1)) {
            winnerSide = 1;
        } else {
            winnerSide = 2;
        }

        if (winnerSide == 1) {
            award = uint(totalAward / option1Count);
            awardCounter = option1Count;
        } else {
            award = uint(totalAward / option2Count);
            awardCounter = option2Count;
        }
    }

         
    function sendAward() public isEnded {
        require(awardCounter > 0);

        uint count = awardCounter;

        if (awardCounter > 400) {
            for (uint i = 0; i < 400; i++) {
                this.sendAwardToLastOne();
            }
        } else {
            for (uint j = 0; j < count; j++) {
                this.sendAwardToLastOne();
            }
        }
    }

         
    function sendAwardToLastOne() public isEnded {
		require(awardCounter > 0);
        if(winnerSide == 1){
            address(option1AddressList[awardCounter - 1]).transfer(award);
        }else{
            address(option2AddressList[awardCounter - 1]).transfer(award);
        }
        
        awardCounter--;

        if(awardCounter == 0){
            if(option1AddressList.length + option2AddressList.length >= 7){
                 
                uint awardFirst6 = uint(finalBalance / 200);
                for (uint k = 0; k < 6; k++) {
                    address(first6AddresstList[k]).transfer(awardFirst6);
                }
                 
                address(lastAddress).transfer(uint(finalBalance / 50));
            }

             
            address(officialAddress).transfer(address(this).balance);
        }
    }

     
    function getEndGameStatus() public isEnded view returns (uint, uint, uint, uint, uint) {
        return (
            winnerSide,
            option1AddressList.length,
            option2AddressList.length,
            finalBalance,
            award
        );
    }

     
    function getPlayerOption() public view returns (uint) {
        if (option1List[msg.sender]) {
            return 1;
        } else if (option2List[msg.sender]) {
            return 2;
        } else {
            return 0;
        }
    }

     
    function getWinnerAddressList() public isEnded view returns (address[]) {
      if (winnerSide == 1) {
        return option1AddressList;
      }else {
        return option2AddressList;
      }
    }

     
    function getLoserAddressList() public isEnded view returns (address[]) {
      if (winnerSide == 1) {
        return option2AddressList;
      }else {
        return option1AddressList;
      }
    }
}
 

pragma solidity ^0.4.24;

contract MajorityGameFactory {

    address[] public deployedGames;
    address[] public endedGames;
    address[] public tempArray;

    address public adminAddress;

    mapping(address => uint) private gameAddressIdMap;

    uint public gameCount = 0;
    uint public endedGameCount = 0;

    modifier adminOnly() {
        require(msg.sender == adminAddress);
        _;
    }

    constructor () public {
        adminAddress = msg.sender;
    }

     
    function createGame (uint _gameBet, uint _startTime, string _questionText, address _officialAddress) public adminOnly payable {
        gameCount ++;
        address newGameAddress = new MajorityGame(gameCount, _gameBet, _startTime, _questionText, _officialAddress);
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

     
     
    uint constant private MINIMUM_BET = 50000000000000000;
    uint constant private MAXIMUM_BET = 50000000000000000;

    uint public gameId;

    uint private jackpot;
    uint private gameBet;

     
    address public adminAddress;
    address public officialAddress;

     
    uint private startTime;

     
    string private questionText;

     
    mapping(address => bool) private playerList;
    uint public playersCount;

     
    mapping(address => bool) private option1List;
    mapping(address => bool) private option2List;

     
    address[] private option1AddressList;
    address[] private option2AddressList;
    address[] private winnerList;

    uint private winnerSide;
    uint private finalBalance;
    uint private award;

     
     
     
    modifier adminOnly() {
        require(msg.sender == adminAddress);
        _;
    }

    modifier withinGameTime() {
        require(now <= startTime);
         
        _;
    }

    modifier afterGameTime() {
        require(now > startTime);
         
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

    constructor(uint _gameId, uint _gameBet, uint _startTime, string _questionText, address _officialAddress) public {
        gameId = _gameId;
        adminAddress = msg.sender;

        gameBet = _gameBet;
        startTime = _startTime;
        questionText = _questionText;

        playersCount = 0;
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

     
    function getGamePlayingStatus() public view returns (uint, uint, uint, uint, uint, uint, uint) {
        return (
        startTime,
        startTime,
         
        playersCount,
        address(this).balance,
        jackpot,
        winnerSide,
        gameBet
        );
    }

     
    function getGameData() public view returns (uint, uint, uint, uint, uint, string, uint, uint, uint) {
        return (
        gameId,
        startTime,
        startTime,
         
        playersCount,
        address(this).balance,
        questionText,
        jackpot,
        winnerSide,
        gameBet
        );
    }

     
    function submitChoose(uint _chooseValue) public payable notEnded withinGameTime {
        require(!playerList[msg.sender]);
        require(msg.value == gameBet);

        playerList[msg.sender] = true;
        playersCount++;

        if (_chooseValue == 1) {
            option1List[msg.sender] = true;
            option1AddressList.push(msg.sender);
        } else if (_chooseValue == 2) {
            option2List[msg.sender] = true;
            option2AddressList.push(msg.sender);
        }
    }

     
    function endGame() public afterGameTime {
        require(winnerSide == 0);

         
        finalBalance = address(this).balance;

        uint totalAward = uint(finalBalance * 9 / 10);

        uint option1Count = option1AddressList.length;
        uint option2Count = option2AddressList.length;

        if (option1Count > option2Count || (option1Count == option2Count && gameId % 2 == 1)) {  
            award = option1Count == 0 ? 0 : uint(totalAward / option1Count);
            winnerSide = 1;
            winnerList = option1AddressList;
        } else if (option2Count > option1Count || (option1Count == option2Count && gameId % 2 == 0)) {  
            award = option2Count == 0 ? 0 : uint(totalAward / option2Count);
            winnerSide = 2;
            winnerList = option2AddressList;
        }
    }

     
    function forceEndGame() public adminOnly {
        require(winnerSide == 0);
         
        finalBalance = address(this).balance;

        uint totalAward = uint(finalBalance * 9 / 10);

        uint option1Count = option1AddressList.length;
        uint option2Count = option2AddressList.length;

        if (option1Count > option2Count || (option1Count == option2Count && gameId % 2 == 1)) {  
            award = option1Count == 0 ? 0 : uint(totalAward / option1Count);
            winnerSide = 1;
            winnerList = option1AddressList;
        } else if (option2Count > option1Count || (option1Count == option2Count && gameId % 2 == 0)) {  
            award = option2Count == 0 ? 0 : uint(totalAward / option2Count);
            winnerSide = 2;
            winnerList = option2AddressList;
        }
    }

     
    function sendAward() public isEnded {
        require(winnerList.length > 0);

        uint count = winnerList.length;

        if (count > 250) {
            for (uint i = 0; i < 250; i++) {
                this.sendAwardToLastWinner();
            }
        } else {
            for (uint j = 0; j < count; j++) {
                this.sendAwardToLastWinner();
            }
        }
    }

     
    function sendAwardToLastWinner() public isEnded {
        address(winnerList[winnerList.length - 1]).transfer(award);

        delete winnerList[winnerList.length - 1];
        winnerList.length--;

        if(winnerList.length == 0){
          address add=address(officialAddress);
          address(add).transfer(address(this).balance);
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

     
    function getWinnerList() public isEnded view returns (address[]) {
        return winnerList;
    }

     
    function getWinnerListLength() public isEnded view returns (uint) {
        return winnerList.length;
    }
}
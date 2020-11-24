 

pragma solidity ^0.4.23;

 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
     
     
     
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    return a / b;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}


 
library AddressUtils {

   
  function isContract(address addr) internal view returns (bool) {
    uint256 size;
     
     
     
     
     
     
     
    assembly { size := extcodesize(addr) }
    return size > 0;
  }

}

 
contract Ownable {
    address public owner;
    address public admin;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
     
    constructor() public {
        owner = msg.sender;
        admin = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin || msg.sender == owner);
        _;
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function setAdmin(address newAdmin) public onlyOwner {
        require(newAdmin != address(0));
        admin = newAdmin;
    }
}

 
contract Pausable is Ownable {
    bool public paused = true;

     
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

     
    modifier whenPaused {
        require(paused);
        _;
    }

     
    function pause() public onlyOwner whenNotPaused {
        paused = true;
    }

     
    function unpause() public onlyOwner whenPaused {
        paused = false;
    }
}

contract BrokenContract is Pausable {
     
    address public newContractAddress;

     
    function setNewAddress(address _v2Address) external onlyOwner whenPaused {
         
        owner.transfer(address(this).balance);

        newContractAddress = _v2Address;
    }
}


 
contract ERC721Basic {
    event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
     

    function balanceOf(address _owner) public view returns (uint256 _balance);
    function ownerOf(uint256 _tokenId) public view returns (address _owner);
    function exists(uint256 _tokenId) public view returns (bool _exists);

     
     
     
}

 
contract ERC721Enumerable is ERC721Basic {
    function totalSupply() public view returns (uint256);
    function tokenOfOwnerByIndex(address _owner, uint256 _index) public view returns (uint256 _tokenId);
    function tokenByIndex(uint256 _index) public view returns (uint256);
}


 
contract ERC721Metadata is ERC721Basic {
    function name() public view returns (string _name);
    function symbol() public view returns (string _symbol);
}


 
contract ERC721 is ERC721Basic, ERC721Enumerable, ERC721Metadata {
}

 
contract ERC721BasicToken is BrokenContract, ERC721Basic {
    using SafeMath for uint256;
    using AddressUtils for address;

     
    mapping (uint256 => address) internal tokenOwner;

     
     

     
    mapping (address => uint256) internal ownedTokensCount;

     
    modifier onlyOwnerOf(uint256 _tokenId) {
        require(ownerOf(_tokenId) == msg.sender);
        _;
    }

     
     

     
    function balanceOf(address _owner) public view returns (uint256) {
        require(_owner != address(0));
        return ownedTokensCount[_owner];
    }

     
    function ownerOf(uint256 _tokenId) public view returns (address) {
        address owner = tokenOwner[_tokenId];
        require(owner != address(0));
        return owner;
    }

     
    function exists(uint256 _tokenId) public view returns (bool) {
        address owner = tokenOwner[_tokenId];
        return owner != address(0);
    }

     
     

     
     

     
     

     
    function isApprovedOrOwner(address _spender, uint256 _tokenId) internal view returns (bool) {
        address owner = ownerOf(_tokenId);
        return _spender == owner ;
    }

     
    function _mint(address _to, uint256 _tokenId) internal {
        require(_to != address(0));
        addTokenTo(_to, _tokenId);
        emit Transfer(address(0), _to, _tokenId);
    }

     
     

     
    function addTokenTo(address _to, uint256 _tokenId) internal {
        require(tokenOwner[_tokenId] == address(0));
        tokenOwner[_tokenId] = _to;
        ownedTokensCount[_to] = ownedTokensCount[_to].add(1);
    }

     
    function removeTokenFrom(address _from, uint256 _tokenId) internal {
        require(ownerOf(_tokenId) == _from);
        ownedTokensCount[_from] = ownedTokensCount[_from].sub(1);
        tokenOwner[_tokenId] = address(0);
    }
}


 
contract ERC721Token is ERC721, ERC721BasicToken {
     
    string internal name_;

     
    string internal symbol_;

     
    mapping(address => uint256[]) internal ownedTokens;

     
    mapping(uint256 => uint256) internal ownedTokensIndex;

     
    uint256[] internal allTokens;

     
    mapping(uint256 => uint256) internal allTokensIndex;

     
    constructor(string _name, string _symbol) public {
        name_ = _name;
        symbol_ = _symbol;
    }

     
    function name() public view returns (string) {
        return name_;
    }

     
    function symbol() public view returns (string) {
        return symbol_;
    }

     
    function tokenOfOwnerByIndex(address _owner, uint256 _index) public view returns (uint256) {
        require(_index < balanceOf(_owner));
        return ownedTokens[_owner][_index];
    }

     
    function totalSupply() public view returns (uint256) {
        return allTokens.length;
    }

     
    function tokenByIndex(uint256 _index) public view returns (uint256) {
        require(_index < totalSupply());
        return allTokens[_index];
    }

     
    function addTokenTo(address _to, uint256 _tokenId) internal {
        super.addTokenTo(_to, _tokenId);
        uint256 length = ownedTokens[_to].length;
        ownedTokens[_to].push(_tokenId);
        ownedTokensIndex[_tokenId] = length;
    }

     
    function removeTokenFrom(address _from, uint256 _tokenId) internal {
        super.removeTokenFrom(_from, _tokenId);

        uint256 tokenIndex = ownedTokensIndex[_tokenId];
        uint256 lastTokenIndex = ownedTokens[_from].length.sub(1);
        uint256 lastToken = ownedTokens[_from][lastTokenIndex];

        ownedTokens[_from][tokenIndex] = lastToken;
        ownedTokens[_from][lastTokenIndex] = 0;
         
         
         

        ownedTokens[_from].length--;
        ownedTokensIndex[_tokenId] = 0;
        ownedTokensIndex[lastToken] = tokenIndex;
    }

     
    function _mint(address _to, uint256 _tokenId) internal {
        super._mint(_to, _tokenId);

        allTokensIndex[_tokenId] = allTokens.length;
        allTokens.push(_tokenId);
    }

}


 
contract BaseGame is ERC721Token {
     
     
    event NewAccount(address owner, uint tokenId, uint parentTokenId, uint blockNumber);

     
    event NewForecast(address owner, uint tokenId, uint forecastId, uint _gameId,
        uint _forecastData);

     
     
    struct Token {
         
        uint createBlockNumber;

         
        uint parentId;
    }

    enum Teams { DEF,
        RUS, SAU, EGY, URY,      
        PRT, ESP, MAR, IRN,      
        FRA, AUS, PER, DNK,      
        ARG, ISL, HRV, NGA,      
        BRA, CHE, CRI, SRB,      
        DEU, MEX, SWE, KOR,      
        BEL, PAN, TUN, GBR,      
        POL, SEN, COL, JPN       
    }

     
    event GameChanged(uint _gameId, uint64 gameDate, Teams teamA, Teams teamB,
        uint goalA, uint goalB, bool odds, uint shotA, uint shotB);


     
    struct Game {
         
        uint64 gameDate;

         
        Teams teamA;
        Teams teamB;

         
        uint goalA;
        uint goalB;

         
        bool odds;

         
        uint shotA;
        uint shotB;

         
        uint[] forecasts;
    }

     
    struct Forecast {
         
        uint gameId;
        uint forecastBlockNumber;

        uint forecastData;
    }

     
     
    Token[] tokens;

     
     
     
    mapping (uint => Game) games;

     
    Forecast[] forecasts;

     
    mapping (uint => uint) internal forecastToToken;

     
    mapping (uint => uint[]) internal tokenForecasts;

     
    constructor(string _name, string _symbol) ERC721Token(_name, _symbol) public {}

     
     
    function _createToken(uint _parentId, address _owner) internal whenNotPaused
    returns (uint) {
        Token memory _token = Token({
            createBlockNumber: block.number,
            parentId: _parentId
            });
        uint newTokenId = tokens.push(_token) - 1;

        emit NewAccount(_owner, newTokenId, uint(_token.parentId), uint(_token.createBlockNumber));
        _mint(_owner, newTokenId);
        return newTokenId;
    }

     
    function _createForecast(uint _tokenId, uint _gameId, uint _forecastData) internal whenNotPaused returns (uint) {
        require(_tokenId < tokens.length);

        Forecast memory newForecast = Forecast({
            gameId: _gameId,
            forecastBlockNumber: block.number,
            forecastData: _forecastData
            });

        uint newForecastId = forecasts.push(newForecast) - 1;

        forecastToToken[newForecastId] = _tokenId;
        tokenForecasts[_tokenId].push(newForecastId);
        games[_gameId].forecasts.push(newForecastId);

         
        emit NewForecast(tokenOwner[_tokenId], _tokenId, newForecastId, _gameId, _forecastData);
        return newForecastId;
    }    
}


contract BaseGameLogic is BaseGame {

     
    uint public prizeFund = 0;
     
    uint public basePrice = 21 finney;
     

     
    uint public gameCloneFee = 7000;          
    uint public priceFactor = 10000;          
    uint public prizeFundFactor = 5000;       

     
    constructor(string _name, string _symbol) BaseGame(_name, _symbol) public {}

     
    function _addToFund(uint _val, bool isAll) internal whenNotPaused {
        if(isAll) {
            prizeFund = prizeFund.add(_val);
        } else {
            prizeFund = prizeFund.add(_val.mul(prizeFundFactor).div(10000));
        }
    }

     
    function createAccount() external payable whenNotPaused returns (uint) {
        require(msg.value >= basePrice);

         
        _addToFund(msg.value, false);
        return _createToken(0, msg.sender);
    }

     
    function cloneAccount(uint _tokenId) external payable whenNotPaused returns (uint) {
        require(exists(_tokenId));

        uint tokenPrice = calculateTokenPrice(_tokenId);
        require(msg.value >= tokenPrice);

         
        uint newToken = _createToken( _tokenId, msg.sender);

         
         
        uint gameFee = tokenPrice.mul(gameCloneFee).div(10000);
         
        _addToFund(gameFee, false);
         
        uint ownerProceed = tokenPrice.sub(gameFee);
        address tokenOwnerAddress = tokenOwner[_tokenId];
        tokenOwnerAddress.transfer(ownerProceed);

        return newToken;
    }


     
    function createForecast(uint _tokenId, uint _gameId,
        uint8 _goalA, uint8 _goalB, bool _odds, uint8 _shotA, uint8 _shotB)
    external whenNotPaused onlyOwnerOf(_tokenId) returns (uint){
        require(exists(_tokenId));
        require(block.timestamp < games[_gameId].gameDate);

        uint _forecastData = toForecastData(_goalA, _goalB, _odds, _shotA, _shotB);
        return _createForecast(_tokenId, _gameId, _forecastData);

         
         
    }

     
    function tokensOfOwner(address _owner) public view returns(uint[] ownerTokens) {
        uint tokenCount = balanceOf(_owner);

        if (tokenCount == 0) {
             
            return new uint[](0);
        } else {
            uint[] memory result = new uint[](tokenCount);
            uint totalToken = totalSupply();
            uint resultIndex = 0;

            uint _tokenId;
            for (_tokenId = 1; _tokenId <= totalToken; _tokenId++) {
                if (tokenOwner[_tokenId] == _owner) {
                    result[resultIndex] = _tokenId;
                    resultIndex++;
                }
            }

            return result;
        }
    }

     
    function forecastOfToken(uint _tokenId) public view returns(uint[]) {
        uint forecastCount = tokenForecasts[_tokenId].length;

        if (forecastCount == 0) {
             
            return new uint[](0);
        } else {
            uint[] memory result = new uint[](forecastCount);
            uint resultIndex;
            for (resultIndex = 0; resultIndex < forecastCount; resultIndex++) {
                result[resultIndex] = tokenForecasts[_tokenId][resultIndex];
            }

            return result;
        }
    }

     
    function gameInfo(uint _gameId) external view returns(
        uint64 gameDate, Teams teamA, Teams teamB, uint goalA, uint gaolB,
        bool odds, uint shotA, uint shotB, uint forecastCount
    ){
        gameDate = games[_gameId].gameDate;
        teamA = games[_gameId].teamA;
        teamB = games[_gameId].teamB;
        goalA = games[_gameId].goalA;
        gaolB = games[_gameId].goalB;
        odds = games[_gameId].odds;
        shotA = games[_gameId].shotA;
        shotB = games[_gameId].shotB;
        forecastCount = games[_gameId].forecasts.length;
    }

     
    function forecastInfo(uint _fId) external view
        returns(uint gameId, uint f) {
        gameId = forecasts[_fId].gameId;
        f = forecasts[_fId].forecastData;
    }

    function tokenInfo(uint _tokenId) external view
        returns(uint createBlockNumber, uint parentId, uint forecast, uint score, uint price) {

        createBlockNumber = tokens[_tokenId].createBlockNumber;
        parentId = tokens[_tokenId].parentId;
        price = calculateTokenPrice(_tokenId);
        forecast = getForecastCount(_tokenId, block.number, false);
        score = getScore(_tokenId);
    }

     
    function calculateTokenPrice(uint _tokenId) public view returns(uint) {
        require(exists(_tokenId));
         
        uint forecastCount = getForecastCount(_tokenId, block.number, true);
        return (forecastCount.add(1)).mul(basePrice).mul(priceFactor).div(10000);
    }

     
    function getForecastCount(uint _tokenId, uint _blockNumber, bool isReleased) public view returns(uint) {
        require(exists(_tokenId));

        uint forecastCount = 0 ;

        uint index = 0;
        uint count = tokenForecasts[_tokenId].length;
        for (index = 0; index < count; index++) {
             
            if(forecasts[tokenForecasts[_tokenId][index]].forecastBlockNumber < _blockNumber){
                if(isReleased) {
                    if (games[forecasts[tokenForecasts[_tokenId][index]].gameId].gameDate < block.timestamp) {
                        forecastCount = forecastCount + 1;
                    }
                } else {
                    forecastCount = forecastCount + 1;
                }
            }
        }

         
        if(tokens[_tokenId].parentId != 0){
            forecastCount = forecastCount.add(getForecastCount(tokens[_tokenId].parentId,
                tokens[_tokenId].createBlockNumber, isReleased));
        }
        return forecastCount;
    }

     
    function getScore(uint _tokenId) public view returns (uint){
        uint[] memory _gameForecast = new uint[](65);
        return getScore(_tokenId, block.number, _gameForecast);
    }

     
    function getScore(uint _tokenId, uint _blockNumber, uint[] _gameForecast) public view returns (uint){
        uint score = 0;

         
        uint[] memory _forecasts = forecastOfToken(_tokenId);
        if (_forecasts.length > 0){
            uint256 _index;
            for(_index = _forecasts.length - 1; _index >= 0 && _index < _forecasts.length ; _index--){
                 
                 
                 
                if(forecasts[_forecasts[_index]].forecastBlockNumber < _blockNumber &&
                    _gameForecast[forecasts[_forecasts[_index]].gameId] == 0 &&
                    block.timestamp > games[forecasts[_forecasts[_index]].gameId].gameDate
                ){
                    score = score.add(calculateScore(
                            forecasts[_forecasts[_index]].gameId,
                            forecasts[_forecasts[_index]].forecastData
                        ));
                    _gameForecast[forecasts[_forecasts[_index]].gameId] = forecasts[_forecasts[_index]].forecastBlockNumber;
                }
            }
        }

         
        if(tokens[_tokenId].parentId != 0){
            score = score.add(getScore(tokens[_tokenId].parentId, tokens[_tokenId].createBlockNumber, _gameForecast));
        }
        return score;
    }

     
    function getForecastScore(uint256 _forecastId) external view returns (uint256) {
        require(_forecastId < forecasts.length);

        return calculateScore(
            forecasts[_forecastId].gameId,
            forecasts[_forecastId].forecastData
        );
    }

     
    function calculateScore(uint256 _gameId, uint d)
    public view returns (uint256){
        require(block.timestamp > games[_gameId].gameDate);

        uint256 _shotB = (d & 0xff);
        d = d >> 8;
        uint256 _shotA = (d & 0xff);
        d = d >> 8;
        uint odds8 = (d & 0xff);
        bool _odds = odds8 == 1 ? true: false;
        d = d >> 8;
        uint256 _goalB = (d & 0xff);
        d = d >> 8;
        uint256 _goalA = (d & 0xff);
        d = d >> 8;

        Game memory cGame = games[_gameId];

        uint256 _score = 0;
        bool isDoubleScore = true;
        if(cGame.shotA == _shotA) {
            _score = _score.add(1);
        } else {
            isDoubleScore = false;
        }
        if(cGame.shotB == _shotB) {
            _score = _score.add(1);
        } else {
            isDoubleScore = false;
        }
        if(cGame.odds == _odds) {
            _score = _score.add(1);
        } else {
            isDoubleScore = false;
        }

         
        if((cGame.goalA + cGame.goalB) == (_goalA + _goalB)) {
            _score = _score.add(2);
        } else {
            isDoubleScore = false;
        }

         
        if(cGame.goalA == _goalA && cGame.goalB == _goalB) {
            _score = _score.add(3);
        } else {
            isDoubleScore = false;
        }

        if( ((cGame.goalA > cGame.goalB) && (_goalA > _goalB)) ||
            ((cGame.goalA < cGame.goalB) && (_goalA < _goalB)) ||
            ((cGame.goalA == cGame.goalB) && (_goalA == _goalB))) {
            _score = _score.add(1);
        } else {
            isDoubleScore = false;
        }

         
        if(isDoubleScore) {
            _score = _score.mul(2);
        }
        return _score;
    }

     
     
    function setBasePrice(uint256 _val) external onlyAdmin {
        require(_val > 0);
        basePrice = _val;
    }

     
    function setGameCloneFee(uint256 _val) external onlyAdmin {
        require(_val <= 10000);
        gameCloneFee = _val;
    }

     
    function setPrizeFundFactor(uint256 _val) external onlyAdmin {
        require(_val <= 10000);
        prizeFundFactor = _val;
    }

     
    function setPriceFactor(uint256 _val) external onlyAdmin {
        priceFactor = _val;
    }

     
    function gameEdit(uint256 _gameId, uint64 gameDate,
        Teams teamA, Teams teamB)
    external onlyAdmin {
        games[_gameId].gameDate = gameDate;
        games[_gameId].teamA = teamA;
        games[_gameId].teamB = teamB;

        emit GameChanged(_gameId, games[_gameId].gameDate, games[_gameId].teamA, games[_gameId].teamB,
            0, 0, true, 0, 0);
    }

    function gameResult(uint256 _gameId, uint256 goalA, uint256 goalB, bool odds, uint256 shotA, uint256 shotB)
    external onlyAdmin {
        games[_gameId].goalA = goalA;
        games[_gameId].goalB = goalB;
        games[_gameId].odds = odds;
        games[_gameId].shotA = shotA;
        games[_gameId].shotB = shotB;

        emit GameChanged(_gameId, games[_gameId].gameDate, games[_gameId].teamA, games[_gameId].teamB,
            goalA, goalB, odds, shotA, shotB);
    }

    function toForecastData(uint8 _goalA, uint8 _goalB, bool _odds, uint8 _shotA, uint8 _shotB)
    pure internal returns (uint) {
        uint forecastData;
        forecastData = forecastData << 8 | _goalA;
        forecastData = forecastData << 8 | _goalB;
        uint8 odds8 = _odds ? 1 : 0;
        forecastData = forecastData << 8 | odds8;
        forecastData = forecastData << 8 | _shotA;
        forecastData = forecastData << 8 | _shotB;

        return forecastData;
    }
}


contract HWCIntegration is BaseGameLogic {

    event NewHWCRegister(address owner, string aD, string aW);

    constructor(string _name, string _symbol) BaseGameLogic(_name, _symbol) public {}

    struct HWCInfo {
        string aDeposit;
        string aWithdraw;
        uint deposit;
        uint index1;         
    }

    uint public cHWCtoEth = 0;
    uint256 public prizeFundHWC = 0;

     
    mapping (address => HWCInfo) hwcAddress;
    address[] hwcAddressList;

    function _addToFundHWC(uint256 _val) internal whenNotPaused {
        prizeFundHWC = prizeFundHWC.add(_val.mul(prizeFundFactor).div(10000));
    }

    function registerHWCDep(string _a) public {
        require(bytes(_a).length == 34);
        hwcAddress[msg.sender].aDeposit = _a;

        if(hwcAddress[msg.sender].index1 == 0){
            hwcAddress[msg.sender].index1 = hwcAddressList.push(msg.sender);
        }

        emit NewHWCRegister(msg.sender, _a, '');
    }

    function registerHWCWit(string _a) public {
        require(bytes(_a).length == 34);
        hwcAddress[msg.sender].aWithdraw = _a;

        if(hwcAddress[msg.sender].index1 == 0){
            hwcAddress[msg.sender].index1 = hwcAddressList.push(msg.sender);
        }

        emit NewHWCRegister(msg.sender, '', _a);
    }

    function getHWCAddressCount() public view returns (uint){
        return hwcAddressList.length;
    }

    function getHWCAddressByIndex(uint _index) public view returns (string aDeposit, string aWithdraw, uint d) {
        require(_index < hwcAddressList.length);
        return getHWCAddress(hwcAddressList[_index]);
    }

    function getHWCAddress(address _val) public view returns (string aDeposit, string aWithdraw, uint d) {
        aDeposit = hwcAddress[_val].aDeposit;
        aWithdraw = hwcAddress[_val].aWithdraw;
        d = hwcAddress[_val].deposit;
    }

    function setHWCDeposit(address _user, uint _val) external onlyAdmin {
        hwcAddress[_user].deposit = _val;
    }

    function createTokenByHWC(address _userTo, uint256 _parentId) external onlyAdmin whenNotPaused returns (uint) {
         
        uint256 tokenPrice = basePrice.div(1e10).mul(cHWCtoEth);
        if(_parentId > 0) {
            tokenPrice = calculateTokenPrice(_parentId);
            tokenPrice = tokenPrice.div(1e10).mul(cHWCtoEth);
             
            uint gameFee = tokenPrice.mul(gameCloneFee).div(10000);
            _addToFundHWC(gameFee);

            uint256 ownerProceed = tokenPrice.sub(gameFee);
            address tokenOwnerAddress = tokenOwner[_parentId];

            hwcAddress[tokenOwnerAddress].deposit = hwcAddress[tokenOwnerAddress].deposit + ownerProceed;
        } else {
            _addToFundHWC(tokenPrice);
        }

        return _createToken(_parentId, _userTo);
    }

    function setCourse(uint _val) external onlyAdmin {
        cHWCtoEth = _val;
    }
}


contract SolutionGame is HWCIntegration {

     
    uint256 countWinnerPlace;
     
    mapping (uint256 => uint256) internal prizeDistribution;
     
    mapping (uint256 => uint256) internal prizesByPlace;
    mapping (uint256 => uint256) internal scoreByPlace;
     
    mapping (uint => uint) winnerMap;
    uint[] winnerList;

    mapping (uint256 => uint256) internal prizesByPlaceHWC;

    bool isWinnerTime = false;

    modifier whenWinnerTime() {
        require(isWinnerTime);
        _;
    }

    constructor(string _name, string _symbol) HWCIntegration(_name, _symbol) public {
        countWinnerPlace = 0;       
    }

     
     
     
    function() external payable {
        _addToFund(msg.value, true);
    }

    function setWinnerTimeStatus(bool _status) external onlyOwner {
        isWinnerTime = _status;
    }

     
    function withdrawBalance() external onlyOwner {
        owner.transfer(address(this).balance.sub(prizeFund));
    }

     
    function setCountWinnerPlace(uint256 _val) external onlyOwner {
        countWinnerPlace = _val;
    }

     
    function setWinnerPlaceDistribution(uint256 place, uint256 _val) external onlyOwner {
        require(place <= countWinnerPlace);
        require(_val <= 10000);

        uint256 testVal = 0;
        uint256 index;
        for (index = 1; index <= countWinnerPlace; index ++) {
            if(index != place) {
                testVal = testVal + prizeDistribution[index];
            }
        }

        testVal = testVal + _val;
        require(testVal <= 10000);
        prizeDistribution[place] = _val;
    }

     
     
    function setCountWinnerByPlace(uint256 place, uint256 _winnerCount, uint256 _winnerScore) public onlyOwner whenPaused {
        require(_winnerCount > 0);
        require(place <= countWinnerPlace);
        prizesByPlace[place] = prizeFund.mul(prizeDistribution[place]).div(10000).div(_winnerCount);
        prizesByPlaceHWC[place] = prizeFundHWC.mul(prizeDistribution[place]).div(10000).div(_winnerCount);
        scoreByPlace[place] = _winnerScore;
    }

    function checkIsWinner(uint _tokenId) public view whenPaused onlyOwnerOf(_tokenId)
    returns (uint place) {
        place = 0;
        uint score = getScore(_tokenId);
        for(uint index = 1; index <= countWinnerPlace; index ++) {
            if (score == scoreByPlace[index]) {
                 
                place = index;
                break;
            }
        }
    }

    function getMyPrize() external whenWinnerTime {
        uint[] memory tokenList = tokensOfOwner(msg.sender);

        for(uint index = 0; index < tokenList.length; index ++) {
            getPrizeByToken(tokenList[index]);
        }
    }

    function getPrizeByToken(uint _tokenId) public whenWinnerTime onlyOwnerOf(_tokenId) {
        uint place = checkIsWinner(_tokenId);
        require (place > 0);

        uint prize = prizesByPlace[place];
        if(prize > 0) {
            if(winnerMap[_tokenId] == 0) {
                winnerMap[_tokenId] = prize;
                winnerList.push(_tokenId);

                address _owner = tokenOwner[_tokenId];
                if(_owner != address(0)){
                     
                    uint hwcPrize = prizesByPlaceHWC[place];
                    hwcAddress[_owner].deposit = hwcAddress[_owner].deposit + hwcPrize;

                    _owner.transfer(prize);
                }
            }
        }
    }

    function getWinnerList() external view onlyAdmin returns (uint[]) {
        return winnerList;
    }

    function getWinnerInfo(uint _tokenId) external view onlyAdmin returns (uint){
        return winnerMap[_tokenId];
    }

    function getResultTable(uint _start, uint _count) external view returns (uint[]) {
        uint[] memory results = new uint[](_count);
        for(uint index = _start; index < tokens.length && index < (_start + _count); index++) {
            results[(index - _start)] = getScore(index);
        }
        return results;
    }
}
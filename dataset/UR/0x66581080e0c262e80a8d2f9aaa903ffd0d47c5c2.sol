 

pragma solidity 0.4.24;

contract AccessControl {
      
    event ContractUpgrade(address newContract);

     
    address public ceoAddress;
    address public cfoAddress;
    address public cooAddress;

    address newContractAddress;

    uint public totalTipForDeveloper = 0;

     
    bool public paused = false;

     
    modifier onlyCEO() {
        require(msg.sender == ceoAddress, "You're not a CEO!");
        _;
    }

     
    modifier onlyCFO() {
        require(msg.sender == cfoAddress, "You're not a CFO!");
        _;
    }

     
    modifier onlyCOO() {
        require(msg.sender == cooAddress, "You're not a COO!");
        _;
    }

    modifier onlyCLevel() {
        require((msg.sender == cooAddress || msg.sender == ceoAddress || msg.sender == cfoAddress), "You're not C-Level");
        _;
    }

     
    function () public payable{
        totalTipForDeveloper = totalTipForDeveloper + msg.value;
    }

     
     
    function addTipForDeveloper(uint valueTip) internal {
        totalTipForDeveloper += valueTip;
    }

     
    function withdrawTipForDeveloper() external onlyCEO {
        require(totalTipForDeveloper > 0, "Need more tip to withdraw!");
        msg.sender.transfer(totalTipForDeveloper);
        totalTipForDeveloper = 0;
    }

     
    function setNewAddress(address newContract) external onlyCEO whenPaused {
        newContractAddress = newContract;
        emit ContractUpgrade(newContract);
    }

     
     
    function setCEO(address _newCEO) external onlyCEO {
        require(_newCEO != address(0), "Address to set CEO wrong!");

        ceoAddress = _newCEO;
    }

     
     
    function setCFO(address _newCFO) external onlyCEO {
        require(_newCFO != address(0), "Address to set CFO wrong!");

        cfoAddress = _newCFO;
    }

     
     
    function setCOO(address _newCOO) external onlyCEO {
        require(_newCOO != address(0), "Address to set COO wrong!");

        cooAddress = _newCOO;
    }

     

     
    modifier whenNotPaused() {
        require(!paused, "Paused!");
        _;
    }

     
    modifier whenPaused {
        require(paused, "Not paused!");
        _;
    }

     
     
    function pause() external onlyCLevel whenNotPaused {
        paused = true;
    }

     
     
     
     
     
    function unpause() public onlyCEO whenPaused {
         
        paused = false;
    }
}

contract RPSCore is AccessControl {
    uint constant ROCK = 1000;
    uint constant PAPER = 2000;
    uint constant SCISSOR = 3000;

    uint constant GAME_RESULT_DRAW = 1;
    uint constant GAME_RESULT_HOST_WIN = 2;
    uint constant GAME_RESULT_GUEST_WIN = 3;

    uint constant DEVELOPER_TIP_PERCENT = 1;
    uint constant DEVELOPER_TIP_MIN = 0.0005 ether;

    uint constant VALUE_BET_MIN = 0.01 ether;
    uint constant VALUE_BET_MAX = 5 ether;

    struct GameInfo {
        uint id;
        uint valueBet;
        address addressHost;  
    }

    struct GameSecret {
        uint gestureHost;
    }

    event LogCloseGameSuccessed(uint _id, uint _valueReturn);
    event LogCreateGameSuccessed(uint _id, uint _valuePlayerHostBid);
    event LogJoinAndBattleSuccessed(uint _id,
                                    uint _result,
                                    address indexed _addressPlayerWin,
                                    address indexed _addressPlayerLose,
                                    uint _valuePlayerWin,
                                    uint _valuePlayerLose,
                                    uint _gesturePlayerWin,
                                    uint _gesturePlayerLose);
 
    uint public totalCreatedGame;
    uint public totalAvailableGames;
    GameInfo[] public arrAvailableGames;
    mapping(uint => uint) idToIndexAvailableGames;
    mapping(uint => GameSecret) idToGameSecret;

    constructor() public {
        ceoAddress = msg.sender;
        cfoAddress = msg.sender;
        cooAddress = msg.sender;

        totalCreatedGame = 0;
        totalAvailableGames = 0;
    }

    function createGame(uint _gestureHost)
        external
        payable
        verifiedGesture(_gestureHost)
        verifiedValueBet(msg.value)
    {
        GameInfo memory gameInfo = GameInfo({
            id: totalCreatedGame + 1,
            addressHost: msg.sender,
            valueBet: msg.value
        });

        GameSecret memory gameSecret = GameSecret({
            gestureHost: _gestureHost
        });

        arrAvailableGames.push(gameInfo);
        idToIndexAvailableGames[gameInfo.id] = arrAvailableGames.length - 1;
        idToGameSecret[gameInfo.id] = gameSecret;

        totalCreatedGame++;
        totalAvailableGames++;

        emit LogCreateGameSuccessed(gameInfo.id, gameInfo.valueBet);
    }

    function joinGameAndBattle(uint _id, uint _gestureGuest)
        external
        payable 
        verifiedGesture(_gestureGuest)
        verifiedValueBet(msg.value)
        verifiedGameAvailable(_id)
    {
        uint result = GAME_RESULT_DRAW;
        uint gestureHostCached = 0;

        GameInfo memory gameInfo = arrAvailableGames[idToIndexAvailableGames[_id]];
       
        require(gameInfo.addressHost != msg.sender, "Don't play with yourself");
        require(msg.value == gameInfo.valueBet, "Value bet to battle not extractly with value bet of host");
        
        gestureHostCached = idToGameSecret[gameInfo.id].gestureHost;

         
        if(gestureHostCached == _gestureGuest) {
            result = GAME_RESULT_DRAW;
            sendPayment(msg.sender, msg.value);
            sendPayment(gameInfo.addressHost, gameInfo.valueBet);
            destroyGame(_id);
            emit LogJoinAndBattleSuccessed(_id,
                                            GAME_RESULT_DRAW,
                                            gameInfo.addressHost,
                                            msg.sender,
                                            0,
                                            0,
                                            gestureHostCached, 
                                            _gestureGuest);
        }
        else {
            if(gestureHostCached == ROCK) 
                result = _gestureGuest == SCISSOR ? GAME_RESULT_HOST_WIN : GAME_RESULT_GUEST_WIN;
            else
                if(gestureHostCached == PAPER) 
                    result = (_gestureGuest == ROCK ? GAME_RESULT_HOST_WIN : GAME_RESULT_GUEST_WIN);
                else
                    if(gestureHostCached == SCISSOR) 
                        result = (_gestureGuest == PAPER ? GAME_RESULT_HOST_WIN : GAME_RESULT_GUEST_WIN);

             
            uint valueTip = getValueTip(gameInfo.valueBet);
            addTipForDeveloper(valueTip);
            
            if(result == GAME_RESULT_HOST_WIN) {
                sendPayment(gameInfo.addressHost, gameInfo.valueBet * 2 - valueTip);
                destroyGame(_id);    
                emit LogJoinAndBattleSuccessed(_id,
                                                result,
                                                gameInfo.addressHost,
                                                msg.sender,
                                                gameInfo.valueBet - valueTip,
                                                gameInfo.valueBet,
                                                gestureHostCached,
                                                _gestureGuest);
            }
            else {
                sendPayment(msg.sender, gameInfo.valueBet * 2 - valueTip);
                destroyGame(_id);
                emit LogJoinAndBattleSuccessed(_id,
                                                result,
                                                msg.sender,
                                                gameInfo.addressHost,
                                                gameInfo.valueBet - valueTip,
                                                gameInfo.valueBet,
                                                _gestureGuest,
                                                gestureHostCached);
            }          
        }

    }

    function closeMyGame(uint _id) external payable verifiedHostOfGame(_id) verifiedGameAvailable(_id) {
        GameInfo storage gameInfo = arrAvailableGames[idToIndexAvailableGames[_id]];

        require(gameInfo.valueBet > 0, "Can't close game!");

        uint valueBet = gameInfo.valueBet;
        gameInfo.valueBet = 0;
        sendPayment(gameInfo.addressHost, valueBet);
        destroyGame(_id);
        emit LogCloseGameSuccessed(_id, valueBet);
    }

    function () public payable {
    }

    function destroyGame(uint _id) private {
        uint indexGameInfo = idToIndexAvailableGames[_id];
        delete idToIndexAvailableGames[_id];
        delete idToGameSecret[_id];
        removeGameInfoFromArray(indexGameInfo);
        totalAvailableGames--;
    }

    function removeGameInfoFromArray(uint _index) private {
        if(_index >= 0 && arrAvailableGames.length > 0) {
            if(_index == arrAvailableGames.length - 1)
            arrAvailableGames.length--;
            else {
                arrAvailableGames[_index] = arrAvailableGames[arrAvailableGames.length - 1];
                idToIndexAvailableGames[arrAvailableGames[_index].id] = _index;
                arrAvailableGames.length--;
            }
        }
    }

    function getValueTip(uint _valueWin) private pure returns(uint) {
        uint valueTip = _valueWin * DEVELOPER_TIP_PERCENT / 100;

        if(valueTip < DEVELOPER_TIP_MIN)
            valueTip = DEVELOPER_TIP_MIN;

        return valueTip;
    }

    function sendPayment(address _receiver, uint _amount) private {
        _receiver.transfer(_amount);
    }

    modifier verifiedGameAvailable(uint _id) {
        require(idToIndexAvailableGames[_id] >= 0, "Game ID not exist!");
        _;
    }

    modifier verifiedGesture(uint _resultSelect) {
        require((_resultSelect == ROCK || _resultSelect == PAPER || _resultSelect == SCISSOR), "Gesture can't verify");
        _;
    }

    modifier verifiedHostOfGame(uint _id) {
        require(msg.sender == arrAvailableGames[idToIndexAvailableGames[_id]].addressHost, "Verify host of game failed");
        _;
    }

    modifier verifiedValueBet(uint _valueBet) {
        require(_valueBet >= VALUE_BET_MIN && _valueBet <= VALUE_BET_MAX, "Your value bet out of rule");
        _;
    }

}
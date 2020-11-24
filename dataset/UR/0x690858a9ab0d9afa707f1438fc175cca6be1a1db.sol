 

pragma solidity ^0.4.25;

 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0);  
    uint256 c = a / b;
     

    return c;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

   
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

 
contract Ownable {
     
    using SafeMath for uint;
    
    enum RequestType {
        None,
        Owner,
        CoOwner1,
        CoOwner2
    }
    
    address public owner;
    address coOwner1;
    address coOwner2;
    RequestType requestType;
    address newOwnerRequest;
    
    mapping(address => bool) voterList;
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor() public {
      owner = msg.sender;
      coOwner1 = address(0x625789684cE563Fe1f8477E8B3c291855E3470dF);
      coOwner2 = address(0xe80a08C003b0b601964b4c78Fb757506d2640055);
    }
    
     
    modifier onlyOwner() {
      require(msg.sender == owner);
      _;
    }
    modifier onlyCoOwner1() {
        require(msg.sender == coOwner1);
        _;
    }
    modifier onlyCoOwner2() {
        require(msg.sender == coOwner2);
        _;
    }
    
     
    function transferOwnership(address newOwner) public {
      require(msg.sender == owner || msg.sender == coOwner1 || msg.sender == coOwner2);
      require(newOwner != address(0));
      
      if(msg.sender == owner) {
          requestType = RequestType.Owner;
      }
      else if(msg.sender == coOwner1) {
          requestType = RequestType.CoOwner1;
      }
      else if(msg.sender == coOwner2) {
          requestType = RequestType.CoOwner2;
      }
      newOwnerRequest = newOwner;
      voterList[msg.sender] = true;
    }
    
    function voteChangeOwner(bool isAgree) public {
        require(msg.sender == owner || msg.sender == coOwner1 || msg.sender == coOwner2);
        require(requestType != RequestType.None);
        voterList[msg.sender] = isAgree;
        checkVote();
    }
    
    function checkVote() private {
        uint iYesCount = 0;
        uint iNoCount = 0;
        if(voterList[owner] == true) {
            iYesCount = iYesCount.add(1);
        }
        else {
            iNoCount = iNoCount.add(1);
        }
        if(voterList[coOwner1] == true) {
            iYesCount = iYesCount.add(1);
        }
        else {
            iNoCount = iNoCount.add(1);
        }
        if(voterList[coOwner2] == true) {
            iYesCount = iYesCount.add(1);
        }
        else {
            iNoCount = iNoCount.add(1);
        }
        
        if(iYesCount >= 2) {
            emit OwnershipTransferred(owner, newOwnerRequest);
            if(requestType == RequestType.Owner) {
                owner = newOwnerRequest;
            }
            else if(requestType == RequestType.CoOwner1) {
                coOwner1 = newOwnerRequest;
            }
            else if(requestType == RequestType.CoOwner2) {
                coOwner2 = newOwnerRequest;
            }
            
            newOwnerRequest = address(0);
            requestType = RequestType.None;
        }
        else if(iNoCount >= 2) {
            newOwnerRequest = address(0);
            requestType = RequestType.None;
        }
    }
}

 
contract Configurable {
    uint256 constant cfgPercentDivider = 10000;
    uint256 constant cfgPercentMaxReceive = 30000;
    
    uint256 public cfgMinDepositRequired = 2 * 10**17;  
    uint256 public cfgMaxDepositRequired = 100*10**18;  
    
    uint256 public minReceiveCommission = 2 * 10**16;  
    uint256 public maxReceiveCommissionPercent = 15000;  
    
    uint256 public supportWaitingTime;
    uint256 public supportPercent;
    uint256 public receiveWaitingTime;
    uint256 public receivePercent;
    
    uint256 public systemFeePercent = 300;           
    address public systemFeeAddress;
    
    uint256 public commissionFeePercent = 300;       
    address public commissionFeeAddress;
    
    uint256 public tokenSupportPercent = 500;        
    address public tokenSupportAddress;
    
    uint256 public directCommissionPercent = 1000;
}
    
 
contract EbcFund is Ownable, Configurable {
    
     
    enum Stages {
        Preparing,
        Started,
        Paused
    }
    enum GameStatus {
        none,
        processing,
        completed
    }
    
     
    struct Player {
        address parentAddress;
        uint256 totalDeposited;
        uint256 totalAmountInGame;
        uint256 totalReceived;
        uint256 totalCommissionReceived;
        uint lastReceiveCommission;
        bool isKyc;
        uint256 directCommission;
    }
    
    struct Game {
        address playerAddress;
        uint256 depositAmount;
        uint256 receiveAmount;
        GameStatus status;
         
        uint nextRoundTime;
        uint256 nextRoundAmount;
    }
    
     
    Stages public currentStage;
    address transporter;
    
     
    event Logger(string _label, uint256 _note);
    
     
    mapping(address => bool) public donateList;
    mapping(address => Player) public playerList;
    mapping(uint => Game) public gameList;
    
     
    constructor() public {
         
        systemFeeAddress = owner;
        commissionFeeAddress = address(0x4c0037cd34804aB3EB6f54d6596A22A68b05c8CF);
        tokenSupportAddress = address(0xC739c85ffE468fA7a6f2B8A005FF0eacAb4D5f0e);
         
        supportWaitingTime = 20*86400; 
        supportPercent = 70; 
        receiveWaitingTime = 5*86400; 
        receivePercent = 10; 
         
        currentStage = Stages.Preparing;
         
        donateList[owner] = true;
        donateList[commissionFeeAddress] = true;
        donateList[tokenSupportAddress] = true;
    }
    
     
    modifier onlyPreparing() {
        require (currentStage == Stages.Preparing);
        _;
    }
    modifier onlyStarted() {
        require (currentStage == Stages.Started);
        _;
    }
    modifier onlyPaused() {
        require (currentStage == Stages.Paused);
        _;
    }
    
 
     
    function () public payable {
        require(currentStage == Stages.Started);
        require(cfgMinDepositRequired <= msg.value && msg.value <= cfgMaxDepositRequired);
        
        if(donateList[msg.sender] == false) {
            if(transporter != address(0) && msg.sender == transporter) {
                 
                if(msg.data.length > 0) {
                     
                    processDeposit(bytesToAddress(msg.data));
                }
                else {
                     emit Logger("Thank you for your contribution!.", msg.value);
                }
            }
            else {
                 
                processDeposit(msg.sender);
            }
        }
        else {
            emit Logger("Thank you for your contribution!", msg.value);
        }
    }
    
 
     
    function getTransporter() public view onlyOwner returns(address) {
        return transporter;
    }

     
    function updateTransporter(address _address) public onlyOwner{
        require (_address != address(0));
        transporter = _address;
    }
    
     
    function updateDonator(address _address, bool _isDonator) public onlyOwner{
        donateList[_address] = _isDonator;
    }
    
     
    function updateSystemAddress(address _address) public onlyOwner{
        require(_address != address(0) && _address != systemFeeAddress);
         
        systemFeeAddress = _address;
    }
    
     
    function updateSystemFeePercent(uint256 _percent) public onlyOwner{
        require(0 < _percent && _percent != systemFeePercent && _percent <= 500);  
        systemFeePercent = _percent;
    }
    
     
    function updateCommissionAddress(address _address) public onlyOwner{
        require(_address != address(0) && _address != commissionFeeAddress);
         
        commissionFeeAddress = _address;
    }
    
     
    function updateCommissionFeePercent(uint256 _percent) public onlyOwner{
        require(0 < _percent && _percent != commissionFeePercent && _percent <= 500);  
        commissionFeePercent = _percent;
    }
    
     
    function updateTokenSupportAddress(address _address) public onlyOwner{
        require(_address != address(0) && _address != tokenSupportAddress);
         
        tokenSupportAddress = _address;
    }
    
     
    function updateTokenSupportPercent(uint256 _percent) public onlyOwner{
        require(0 < _percent && _percent != tokenSupportPercent && _percent <= 1000);  
        tokenSupportPercent = _percent;
    }
    
     
    function updateDirectCommissionPercent(uint256 _percent) public onlyOwner{
        require(0 < _percent && _percent != directCommissionPercent && _percent <= 2000);  
        directCommissionPercent = _percent;
    }
    
     
    function updateMinDeposit(uint256 _amount) public onlyOwner{
        require(0 < _amount && _amount < cfgMaxDepositRequired);
        require(_amount != cfgMinDepositRequired);
         
        cfgMinDepositRequired = _amount;
    }
    
     
    function updateMaxDeposit(uint256 _amount) public onlyOwner{
        require(cfgMinDepositRequired < _amount && _amount != cfgMaxDepositRequired);
         
        cfgMaxDepositRequired = _amount;
    }
    
     
    function updateMinReceiveCommission(uint256 _amount) public onlyOwner{
        require(0 < _amount && _amount != minReceiveCommission);
        minReceiveCommission = _amount;
    }
    
     
    function updateMaxReceiveCommissionPercent(uint256 _percent) public onlyOwner{
        require(5000 <= _percent && _percent <= 20000);  
         
        maxReceiveCommissionPercent = _percent;
    }
    
     
    function updateSupportWaitingTime(uint256 _time) public onlyOwner{
        require(86400 <= _time);
        require(_time != supportWaitingTime);
         
        supportWaitingTime = _time;
    }
    
     
    function updateSupportPercent(uint256 _percent) public onlyOwner{
        require(0 < _percent && _percent < 1000);
        require(_percent != supportPercent);
         
        supportPercent = _percent;
    }
    
     
    function updateReceiveWaitingTime(uint256 _time) public onlyOwner{
        require(86400 <= _time);
        require(_time != receiveWaitingTime);
         
        receiveWaitingTime = _time;
    }
    
     
    function updateRecivePercent(uint256 _percent) public onlyOwner{
        require(0 < _percent && _percent < 1000);
        require(_percent != receivePercent);
         
        receivePercent = _percent;
    }
    
     
    function updatePlayerParent(address[] _address, address[] _parentAddress) public onlyOwner{
        
        for(uint i = 0; i < _address.length; i++) {
            require(_address[i] != address(0));
            require(_parentAddress[i] != address(0));
            require(_address[i] != _parentAddress[i]);
            
            Player storage currentPlayer = playerList[_address[i]];
             
            currentPlayer.parentAddress = _parentAddress[i];
            if(0 < currentPlayer.directCommission && currentPlayer.directCommission < address(this).balance) {
                uint256 comAmount = currentPlayer.directCommission;
                currentPlayer.directCommission = 0;
                 
                emit Logger("Send direct commission", comAmount);
                 
                _parentAddress[i].transfer(comAmount);
            }
        }
        
    }
    
     
    function updatePlayerKyc(address[] _address, bool[] _isKyc) public onlyOwner{
        
        for(uint i = 0; i < _address.length; i++) {
            require(_address[i] != address(0));
             
            playerList[_address[i]].isKyc = _isKyc[i];
        }
    }
    
     
    function startGame() public onlyOwner {
        require(currentStage == Stages.Preparing || currentStage == Stages.Paused);
        currentStage = Stages.Started;
    }
    
     
    function pauseGame() public onlyOwner onlyStarted {
        currentStage = Stages.Paused;
    }
    
     
    function importPlayers(
        address[] _playerAddress, 
        address[] _parentAddress,
        uint256[] _totalDeposited,
        uint256[] _totalReceived,
        uint256[] _totalCommissionReceived,
        bool[] _isKyc) public onlyOwner onlyPreparing {
            
            for(uint i = 0; i < _playerAddress.length; i++) {
                processImportPlayer(
                    _playerAddress[i], 
                    _parentAddress[i],
                    _totalDeposited[i],
                    _totalReceived[i],
                    _totalCommissionReceived[i],
                    _isKyc[i]);
            }
            
        }
    
    function importGames(
        address[] _playerAddress,
        uint[] _gameHash,
        uint256[] _gameAmount,
        uint256[] _gameReceived) public onlyOwner onlyPreparing {
            
            for(uint i = 0; i < _playerAddress.length; i++) {
                processImportGame(
                    _playerAddress[i], 
                    _gameHash[i],
                    _gameAmount[i],
                    _gameReceived[i]);
            }
            
        }
    
       
    function confirmGames(address[] _playerAddress, uint[] _gameHash, uint256[] _gameAmount) public onlyCoOwner1 onlyStarted {
        
        for(uint i = 0; i < _playerAddress.length; i++) {
            confirmGame(_playerAddress[i], _gameHash[i], _gameAmount[i]);
        }
        
    }
    
       
    function confirmGame(address _playerAddress, uint _gameHash, uint256 _gameAmount) public onlyCoOwner1 onlyStarted {
         
        require(100000000000 <= _gameHash && _gameHash <= 999999999999);
         
        Player storage currentPlayer = playerList[_playerAddress];
        require(cfgMinDepositRequired <= playerList[_playerAddress].totalDeposited);
        assert(currentPlayer.totalDeposited <= currentPlayer.totalAmountInGame.add(_gameAmount));
         
        currentPlayer.totalAmountInGame = currentPlayer.totalAmountInGame.add(_gameAmount);
         
        initGame(_playerAddress, _gameHash, _gameAmount, 0);
         
        emit Logger("Game started", _gameAmount);
    }
    
     
    function sendMissionDirectCommission(address _address) public onlyCoOwner2 onlyStarted {
        
        require(donateList[_address] == false);
        require(playerList[_address].parentAddress != address(0));
        require(playerList[_address].directCommission > 0);
        
        Player memory currentPlayer = playerList[_address];
        if(0 < currentPlayer.directCommission && currentPlayer.directCommission < address(this).balance) {
            uint256 comAmount = currentPlayer.directCommission;
            playerList[_address].directCommission = 0;
             
            emit Logger("Send direct commission", comAmount);
             
            currentPlayer.parentAddress.transfer(comAmount);
        }
        
    }
    
     
    function sendCommission(address _address, uint256 _amountCom) public onlyCoOwner2 onlyStarted {
        
        require(donateList[_address] == false);
        require(minReceiveCommission <= _amountCom && _amountCom < address(this).balance);
        require(playerList[_address].isKyc == true);
        require(playerList[_address].lastReceiveCommission.add(86400) < now);
        
         
        Player storage currentPlayer = playerList[_address];
         
        uint256 maxCommissionAmount = getMaximumCommissionAmount(
            currentPlayer.totalAmountInGame, 
            currentPlayer.totalReceived, 
            currentPlayer.totalCommissionReceived, 
            _amountCom);
        if(maxCommissionAmount > 0) {
             
            currentPlayer.totalReceived = currentPlayer.totalReceived.add(maxCommissionAmount);
            currentPlayer.totalCommissionReceived = currentPlayer.totalCommissionReceived.add(maxCommissionAmount);
            currentPlayer.lastReceiveCommission = now;
             
            uint256 comFee = maxCommissionAmount.mul(commissionFeePercent).div(cfgPercentDivider);
             
            emit Logger("Send commission successfully", _amountCom);
            
            if(comFee > 0) {
                maxCommissionAmount = maxCommissionAmount.sub(comFee);
                 
                commissionFeeAddress.transfer(comFee);
            }
            if(maxCommissionAmount > 0) {
                 
                _address.transfer(maxCommissionAmount);
            }
        }
        
    }
    
     
    function sendProfits(
        uint[] _gameHash,
        uint256[] _profitAmount) public onlyCoOwner2 onlyStarted {
            
            for(uint i = 0; i < _gameHash.length; i++) {
                sendProfit(_gameHash[i], _profitAmount[i]);
            }
            
        }
    
     
    function sendProfit(
        uint _gameHash,
        uint256 _profitAmount) public onlyCoOwner2 onlyStarted {
            
             
            Game memory game = gameList[_gameHash];
            require(game.status == GameStatus.processing);
            require(0 < _profitAmount && _profitAmount <= game.nextRoundAmount && _profitAmount < address(this).balance);
            require(now <= game.nextRoundTime);
             
            Player memory currentPlayer = playerList[gameList[_gameHash].playerAddress];
            assert(currentPlayer.isKyc == true);
             
            processSendProfit(_gameHash, _profitAmount);
            
        }
    
 
    
 
     
    function processDeposit(address _address) private {
        
         
        Player storage currentPlayer = playerList[_address];
        currentPlayer.totalDeposited = currentPlayer.totalDeposited.add(msg.value);
        
         
        emit Logger("Game deposited", msg.value);
        
         
        uint256 tokenSupportAmount = tokenSupportPercent.mul(msg.value).div(cfgPercentDivider);
        if(tokenSupportPercent > 0) {
            tokenSupportAddress.transfer(tokenSupportAmount);
        }
        
         
        uint256 directComAmount = directCommissionPercent.mul(msg.value).div(cfgPercentDivider);
        if(currentPlayer.parentAddress != address(0)) {
            currentPlayer.parentAddress.transfer(directComAmount);
        }
        else {
            currentPlayer.directCommission = currentPlayer.directCommission.add(directComAmount);
        }
        
    }
    
     
    function bytesToAddress(bytes b) public pure returns (address) {

        uint result = 0;
        for (uint i = 0; i < b.length; i++) {
            uint c = uint(b[i]);
            if (c >= 48 && c <= 57) {
                result = result * 16 + (c - 48);
            }
            if(c >= 65 && c<= 90) {
                result = result * 16 + (c - 55);
            }
            if(c >= 97 && c<= 122) {
                result = result * 16 + (c - 87);
            }
        }
        return address(result);
          
    }
    
      
    function processImportPlayer(
        address _playerAddress, 
        address _parentAddress, 
        uint256 _totalDeposited,
        uint256 _totalReceived,
        uint256 _totalCommissionReceived,
        bool _isKyc) private {
            
             
            Player storage currentPlayer = playerList[_playerAddress];
            currentPlayer.parentAddress = _parentAddress;
            currentPlayer.totalDeposited = _totalDeposited;
            currentPlayer.totalReceived = _totalReceived;
            currentPlayer.totalCommissionReceived = _totalCommissionReceived;
            currentPlayer.isKyc = _isKyc;
            
             
            emit Logger("Player imported", _totalDeposited);
            
        }
     
      
    function processImportGame(
        address _playerAddress, 
        uint _gameHash,
        uint256 _gameAmount,
        uint256 _gameReceived) private {
            
             
            Player storage currentPlayer = playerList[_playerAddress];
            currentPlayer.totalAmountInGame = currentPlayer.totalAmountInGame.add(_gameAmount);
            currentPlayer.totalReceived = currentPlayer.totalReceived.add(_gameReceived);
            
             
            initGame(_playerAddress, _gameHash, _gameAmount, _gameReceived);
            
             
            emit Logger("Game imported", _gameAmount);
            
        }
     
      
    function initGame(
        address _playerAddress,
        uint _gameHash,
        uint256 _gameAmount,
        uint256 _gameReceived) private {
            
            Game storage game = gameList[_gameHash];
            game.playerAddress = _playerAddress;
            game.depositAmount = _gameAmount;
            game.receiveAmount = _gameReceived;
            game.status = GameStatus.processing;
            game.nextRoundTime = now.add(supportWaitingTime);
            game.nextRoundAmount = getProfitNextRound(_gameAmount);
            
        }
    
     
    function processSendProfit(
        uint _gameHash,
        uint256 _profitAmount) private {
        
            Game storage game = gameList[_gameHash];
            Player storage currentPlayer = playerList[game.playerAddress];
            
             
            uint256 maxGameReceive = game.depositAmount.mul(cfgPercentMaxReceive).div(cfgPercentDivider);
             
            uint256 maxPlayerReceive = currentPlayer.totalAmountInGame.mul(cfgPercentMaxReceive).div(cfgPercentDivider);
            
            if(maxGameReceive <= game.receiveAmount || maxPlayerReceive <= currentPlayer.totalReceived) {
                emit Logger("ERR: Player cannot break game's rule [amount].", currentPlayer.totalReceived);
                game.status = GameStatus.completed;
            }
            else {
                if(maxGameReceive < game.receiveAmount.add(_profitAmount)) {
                    _profitAmount = maxGameReceive.sub(game.receiveAmount);
                }
                if(maxPlayerReceive < currentPlayer.totalReceived.add(_profitAmount)) {
                    _profitAmount = maxPlayerReceive.sub(currentPlayer.totalReceived);
                }
                
                 
                game.receiveAmount = game.receiveAmount.add(_profitAmount);
                game.nextRoundTime = now.add(supportWaitingTime);
                game.nextRoundAmount = getProfitNextRound(game.depositAmount);
                
                 
                emit Logger("Info: send profit", _profitAmount);
                
                 
                currentPlayer.totalReceived = currentPlayer.totalReceived.add(_profitAmount);
                
                 
                uint256 feeAmount = systemFeePercent.mul(_profitAmount).div(cfgPercentDivider);
                if(feeAmount > 0) {
                    _profitAmount = _profitAmount.sub(feeAmount);
                     
                    systemFeeAddress.transfer(feeAmount);
                }
                
                 
                game.playerAddress.transfer(_profitAmount);
            }
            
        }
    
     
    function getProfitNextRound(uint256 _amount) private constant returns(uint256) {
        
        uint256 support = supportPercent.mul(supportWaitingTime);
        uint256 receive = receivePercent.mul(receiveWaitingTime);
        uint256 totalPercent = support.add(receive);
         
        return _amount.mul(totalPercent).div(cfgPercentDivider).div(86400);
        
    }
    
     
    function getMaximumCommissionAmount(
        uint256 _totalDeposited,
        uint256 _totalReceived,
        uint256 _totalCommissionReceived,
        uint256 _amountCom) private returns(uint256) {
        
         
        uint256 maxCommissionAmount = _totalDeposited.mul(maxReceiveCommissionPercent).div(cfgPercentDivider);
         
        if(maxCommissionAmount <= _totalCommissionReceived) {
            emit Logger("Not enough balance [total commission receive]", _totalCommissionReceived);
            return 0;
        }
        else if(maxCommissionAmount < _totalCommissionReceived.add(_amountCom)) {
            _amountCom = maxCommissionAmount.sub(_totalCommissionReceived);
        }
         
        uint256 maxProfitCanReceive = _totalDeposited.mul(cfgPercentMaxReceive).div(cfgPercentDivider);
        if(maxProfitCanReceive <= _totalReceived) {
            emit Logger("Not enough balance [total maxout receive]", _totalReceived);
            return 0;
        }
        else if(maxProfitCanReceive < _totalReceived.add(_amountCom)) {
            _amountCom = maxProfitCanReceive.sub(_totalReceived);
        }
        
        return _amountCom;
    }
}
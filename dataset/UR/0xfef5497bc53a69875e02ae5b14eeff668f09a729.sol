 

pragma solidity ^0.4.24;

 


contract Infinity {
    using SafeMath for uint256;
    
     
    string public name = "Infinity";     
    string public symbol = "Inf";
    
    uint256 public initAmount;           
    uint256 public amountProportion;     
    uint256 public dividend;             
    uint256 public jackpot;              
    uint256 public jackpotProportion;    
    uint256 public scientists;           
    uint256 public promotionRatio;       
    uint256 public duration;             
    bool public activated = false;
    
    address public developerAddr;
    
     
    uint256 public rId;    
    uint256 public sId;    
    
    mapping (uint256 => Indatasets.Round) public round;  
    mapping (uint256 => mapping (uint256 => Indatasets.Stage)) public stage;     
    mapping (address => Indatasets.Player) public player;    
    mapping (uint256 => mapping (address => uint256)) public playerRoundAmount;  
    mapping (uint256 => mapping (address => uint256)) public playerRoundSid; 
    mapping (uint256 => mapping (address => uint256)) public playerRoundwithdrawAmountFlag; 
    mapping (uint256 => mapping (uint256 => mapping (address => uint256))) public playerStageAmount;     
    mapping (uint256 => mapping (uint256 => mapping (address => uint256))) public playerStageAccAmount;  
    
     
    uint256[] amountLimit = [0, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50];

     
    
    constructor()
        public
    {
        developerAddr = msg.sender;
    }
    
     
     
    modifier isActivated() {
        require(activated == true, "its not ready yet.  check ?eta in discord"); 
        _;
    }
    
    modifier senderVerify() {
        require (msg.sender == tx.origin);
        _;
    }
    
    modifier stageVerify(uint256 _rId, uint256 _sId, uint256 _amount) {
        require(stage[_rId][_sId].amount.add(_amount) <= stage[_rId][_sId].targetAmount);
        _;
    }
    
     
    modifier amountVerify() {
        if(msg.value < 100000000000000){
            developerAddr.transfer(msg.value);
        }else{
            require(msg.value >= 100000000000000);
            _;
        }
    }
    
    modifier playerVerify() {
        require(player[msg.sender].active == true);
        _;
    }
    
     
    function activate()
        public
    {
        require(msg.sender == developerAddr);
        require(activated == false, "Infinity already activated");
        
        activated = true;
        initAmount = 10000000000000000000;
        amountProportion = 10;
        dividend = 70;
        jackpot = 28;  
        jackpotProportion = 70;  
        scientists = 2;
        promotionRatio = 10;
        duration = 86400;
        rId = 1;
        sId = 1;
        
        round[rId].start = now;
        initStage(rId, sId);
    
    }
    
     
    function()
        isActivated()
        senderVerify()
        amountVerify()
        payable
        public
    {
        buyAnalysis(0x0);
    }

     
    function buy(address _recommendAddr)
        isActivated()
        senderVerify()
        amountVerify()
        public
        payable
        returns(uint256)
    {
        buyAnalysis(_recommendAddr);
    }
    
     
    function withdraw()
        isActivated()
        senderVerify()
        playerVerify()
        public
    {
        uint256 _rId = rId;
        uint256 _sId = sId;
        uint256 _amount;
        uint256 _playerWithdrawAmountFlag;
        
        (_amount, player[msg.sender].withdrawRid, player[msg.sender].withdrawSid, _playerWithdrawAmountFlag) = getPlayerDividendByStage(_rId, _sId, msg.sender);

        if(_playerWithdrawAmountFlag > 0)
            playerRoundwithdrawAmountFlag[player[msg.sender].withdrawRid][msg.sender] = _playerWithdrawAmountFlag;
        
        if(player[msg.sender].promotionAmount > 0 ){
            _amount = _amount.add(player[msg.sender].promotionAmount);
            player[msg.sender].promotionAmount = 0;
        }    
        msg.sender.transfer(_amount);
    }

    
     
    function buyAnalysis(address _recommendAddr)
        private
    {
        uint256 _rId = rId;
        uint256 _sId = sId;
        uint256 _amount = msg.value;
        uint256 _promotionRatio = promotionRatio;
        
        if(now > stage[_rId][_sId].end && stage[_rId][_sId].targetAmount > stage[_rId][_sId].amount){
            
            endRound(_rId, _sId);
            
            _rId = rId;
            _sId = sId;
            round[_rId].start = now;
            initStage(_rId, _sId);
            
            _amount = limitAmount(_rId, _sId);
            buyRoundDataRecord(_rId, _amount);
            _promotionRatio = promotionDataRecord(_recommendAddr, _amount);
            buyStageDataRecord(_rId, _sId, _promotionRatio, _amount);
            buyPlayerDataRecord(_rId, _sId, _amount);
            
        }else if(now <= stage[_rId][_sId].end){
            
            _amount = limitAmount(_rId, _sId);
            buyRoundDataRecord(_rId, _amount);
            _promotionRatio = promotionDataRecord(_recommendAddr, _amount);
            
            if(stage[_rId][_sId].amount.add(_amount) >= stage[_rId][_sId].targetAmount){
                
                uint256 differenceAmount = (stage[_rId][_sId].targetAmount).sub(stage[_rId][_sId].amount);
                buyStageDataRecord(_rId, _sId, _promotionRatio, differenceAmount);
                buyPlayerDataRecord(_rId, _sId, differenceAmount);
                
                endStage(_rId, _sId);

                _sId = sId;
                initStage(_rId, _sId);
                round[_rId].endSid = _sId;
                buyStageDataRecord(_rId, _sId, _promotionRatio, _amount.sub(differenceAmount));
                buyPlayerDataRecord(_rId, _sId, _amount.sub(differenceAmount));
                
            }else{
                buyStageDataRecord(_rId, _sId, _promotionRatio, _amount);
                buyPlayerDataRecord(_rId, _sId, _amount);
                
            }
        }
    }
    
    
     
    function initStage(uint256 _rId, uint256 _sId)
        private
    {
        uint256 _targetAmount;
        stage[_rId][_sId].start = now;
        stage[_rId][_sId].end = now.add(duration);
        if(_sId > 1){
            stage[_rId][_sId - 1].end = now;
            stage[_rId][_sId - 1].ended = true;
            _targetAmount = (stage[_rId][_sId - 1].targetAmount.mul(amountProportion + 100)) / 100;
        }else
            _targetAmount = initAmount;
            
        stage[_rId][_sId].targetAmount = _targetAmount;
        
    }
    
     
    function limitAmount(uint256 _rId, uint256 _sId)
        private
        returns(uint256)
    {
        uint256 _amount = msg.value;
        
        if(amountLimit.length > _sId)
            _amount = ((stage[_rId][_sId].targetAmount.mul(amountLimit[_sId])) / 1000).sub(playerStageAmount[_rId][_sId][msg.sender]);
        else
            _amount = ((stage[_rId][_sId].targetAmount.mul(500)) / 1000).sub(playerStageAmount[_rId][_sId][msg.sender]);
            
        if(_amount >= msg.value)
            return msg.value;
        else
            msg.sender.transfer(msg.value.sub(_amount));
        
        return _amount;
    }
    
     
    function promotionDataRecord(address _recommendAddr, uint256 _amount)
        private
        returns(uint256)
    {
        uint256 _promotionRatio = promotionRatio;
        
        if(_recommendAddr != 0x0000000000000000000000000000000000000000 
            && _recommendAddr != msg.sender 
            && player[_recommendAddr].active == true
        )
            player[_recommendAddr].promotionAmount = player[_recommendAddr].promotionAmount.add((_amount.mul(_promotionRatio)) / 100);
        else
            _promotionRatio = 0;
        
        return _promotionRatio;
    }
    
    
     
    function buyRoundDataRecord(uint256 _rId, uint256 _amount)
        private
    {

        round[_rId].amount = round[_rId].amount.add(_amount);
        developerAddr.transfer(_amount.mul(scientists) / 100);
    }
    
     
    function buyStageDataRecord(uint256 _rId, uint256 _sId, uint256 _promotionRatio, uint256 _amount)
        stageVerify(_rId, _sId, _amount)
        private
    {
        if(_amount <= 0)
            return;
        stage[_rId][_sId].amount = stage[_rId][_sId].amount.add(_amount);
        stage[_rId][_sId].dividendAmount = stage[_rId][_sId].dividendAmount.add((_amount.mul(dividend.sub(_promotionRatio))) / 100);
    }
    
     
    function buyPlayerDataRecord(uint256 _rId, uint256 _sId, uint256 _amount)
        private
    {
        if(_amount <= 0)
            return;
            
        if(player[msg.sender].active == false){
            player[msg.sender].active = true;
            player[msg.sender].withdrawRid = _rId;
            player[msg.sender].withdrawSid = _sId;
        }
            
        if(playerRoundAmount[_rId][msg.sender] == 0){
            round[_rId].players++;
            playerRoundSid[_rId][msg.sender] = _sId;
        }
            
        if(playerStageAmount[_rId][_sId][msg.sender] == 0)
            stage[_rId][_sId].players++;
            
        playerRoundAmount[_rId][msg.sender] = playerRoundAmount[_rId][msg.sender].add(_amount);
        playerStageAmount[_rId][_sId][msg.sender] = playerStageAmount[_rId][_sId][msg.sender].add(_amount);
        
        player[msg.sender].amount = player[msg.sender].amount.add(_amount);
        
        if(playerRoundSid[_rId][msg.sender] > 0){
            
            if(playerStageAccAmount[_rId][_sId][msg.sender] == 0){
                
                for(uint256 i = playerRoundSid[_rId][msg.sender]; i < _sId; i++){
                
                    if(playerStageAmount[_rId][i][msg.sender] > 0)
                        playerStageAccAmount[_rId][_sId][msg.sender] = playerStageAccAmount[_rId][_sId][msg.sender].add(playerStageAmount[_rId][i][msg.sender]);
                    
                }
            }
            
            playerStageAccAmount[_rId][_sId][msg.sender] = playerStageAccAmount[_rId][_sId][msg.sender].add(_amount);
        }
    }
    
     
    function endRound(uint256 _rId, uint256 _sId)
        private
    {
        round[_rId].end = now;
        round[_rId].ended = true;
        round[_rId].endSid = _sId;
        stage[_rId][_sId].end = now;
        stage[_rId][_sId].ended = true;
        
        if(stage[_rId][_sId].players == 0)
            round[_rId + 1].jackpotAmount = round[_rId + 1].jackpotAmount.add(round[_rId].jackpotAmount);
        else
            round[_rId + 1].jackpotAmount = round[_rId + 1].jackpotAmount.add(round[_rId].jackpotAmount.mul(100 - jackpotProportion) / 100);
        
        rId++;
        sId = 1;
        
    }
    
     
    function endStage(uint256 _rId, uint256 _sId)
        private
    {
        uint256 _jackpotAmount = stage[_rId][_sId].amount.mul(jackpot) / 100;
        round[_rId].endSid = _sId;
        round[_rId].jackpotAmount = round[_rId].jackpotAmount.add(_jackpotAmount);
        stage[_rId][_sId].end = now;
        stage[_rId][_sId].ended = true;
        if(_sId > 1)
            stage[_rId][_sId].accAmount = stage[_rId][_sId].targetAmount.add(stage[_rId][_sId - 1].accAmount);
        else
            stage[_rId][_sId].accAmount = stage[_rId][_sId].targetAmount;
        
        sId++;
    }
    
     
    function getPlayerDividendByStage(uint256 _rId, uint256 _sId, address _playerAddr)
        private
        view
        returns(uint256, uint256, uint256, uint256)
    {
        
        uint256 _dividend;
        uint256 _stageNumber;
        uint256 _startSid;
        uint256 _playerAmount;    
        
        for(uint256 i = player[_playerAddr].withdrawRid; i <= _rId; i++){
            
            if(playerRoundAmount[i][_playerAddr] == 0)
                continue;
            
            _playerAmount = 0;    
            _startSid = i == player[_playerAddr].withdrawRid ? player[_playerAddr].withdrawSid : 1;
            for(uint256 j = _startSid; j < round[i].endSid; j++){
                    
                if(playerStageAccAmount[i][j][_playerAddr] > 0)
                    _playerAmount = playerStageAccAmount[i][j][_playerAddr];
                    
                if(_playerAmount == 0)
                    _playerAmount = playerRoundwithdrawAmountFlag[i][_playerAddr];
                    
                if(_playerAmount == 0)
                    continue;
                _dividend = _dividend.add(
                    (
                        _playerAmount.mul(stage[i][j].dividendAmount)
                    ).div(stage[i][j].accAmount)
                );
                
                _stageNumber++;
                if(_stageNumber >= 50)
                    return (_dividend, i, j + 1, _playerAmount);
            }
            
            if(round[i].ended == true
                && stage[i][round[i].endSid].amount > 0
                && playerStageAmount[i][round[i].endSid][_playerAddr] > 0
            ){
                _dividend = _dividend.add(getPlayerJackpot(_playerAddr, i));
                _stageNumber++;
                if(_stageNumber >= 50)
                    return (_dividend, i + 1, 1, 0);
            }
        }
        return (_dividend, _rId, _sId, _playerAmount);
    }
    
     
    function getPlayerDividend(address _playerAddr)
        public
        view
        returns(uint256)
    {
        uint256 _endRid = rId;
        uint256 _startRid = player[_playerAddr].withdrawRid;
        uint256 _startSid;
        uint256 _dividend;
        
        for(uint256 i = _startRid; i <= _endRid; i++){
            
            if(i == _startRid)
                _startSid = player[_playerAddr].withdrawSid;
            else
                _startSid = 1;
            _dividend = _dividend.add(getPlayerDividendByRound(_playerAddr, i, _startSid));
        }
        
        return _dividend;
    }
    
     
    function getPlayerDividendByRound(address _playerAddr, uint256 _rId, uint256 _sId)
        public
        view
        returns(uint256)
    {
        uint256 _dividend;
        uint256 _startSid = _sId;
        uint256 _endSid = round[_rId].endSid;
        
        uint256 _playerAmount;
        uint256 _totalAmount;
        for(uint256 i = _startSid; i < _endSid; i++){
            
            if(stage[_rId][i].ended == false)
                continue;
                
            _playerAmount = 0;    
            _totalAmount = 0;
            for(uint256 j = 1; j <= i; j++){
                
                if(playerStageAmount[_rId][j][_playerAddr] > 0)
                    _playerAmount = _playerAmount.add(playerStageAmount[_rId][j][_playerAddr]);
                
                _totalAmount = _totalAmount.add(stage[_rId][j].amount);
            }
            
            if(_playerAmount == 0 || stage[_rId][i].dividendAmount == 0)
                continue;
            _dividend = _dividend.add((_playerAmount.mul(stage[_rId][i].dividendAmount)).div(_totalAmount));
        }
        
        if(round[_rId].ended == true)
            _dividend = _dividend.add(getPlayerJackpot(_playerAddr, _rId));

        return _dividend;
    }
    
    
     
    function getPlayerJackpot(address _playerAddr, uint256 _rId)
        public
        view
        returns(uint256)
    {
        uint256 _dividend;
        
        if(round[_rId].ended == false)
            return _dividend;
        
        uint256 _endSid = round[_rId].endSid;
        uint256 _playerStageAmount = playerStageAmount[_rId][_endSid][_playerAddr];
        uint256 _stageAmount = stage[_rId][_endSid].amount;
        if(_stageAmount <= 0)
            return _dividend;
            
        uint256 _jackpotAmount = round[_rId].jackpotAmount.mul(jackpotProportion) / 100;
        uint256 _stageDividendAmount = stage[_rId][_endSid].dividendAmount;
        uint256 _stageJackpotAmount = (_stageAmount.mul(jackpot) / 100).add(_stageDividendAmount);
        
        _dividend = _dividend.add(((_playerStageAmount.mul(_jackpotAmount)).div(_stageAmount)));
        _dividend = _dividend.add(((_playerStageAmount.mul(_stageJackpotAmount)).div(_stageAmount)));
        
        return _dividend;
    }
    
     
    function getHeadInfo()
        public
        view
        returns(uint256, uint256, uint256, uint256, uint256, uint256, bool)
    {
        return
            (
                rId,
                sId,
                round[rId].jackpotAmount,
                stage[rId][sId].targetAmount,
                stage[rId][sId].amount,
                stage[rId][sId].end,
                stage[rId][sId].ended
            );
    }
    
     
    function getPersonalStatus(address _playerAddr)
        public
        view
        returns(uint256, uint256, uint256)
    {
        if (player[_playerAddr].active == true){
            return
            (
                round[rId].jackpotAmount,
                playerRoundAmount[rId][_playerAddr],
                getPlayerDividendByRound(_playerAddr, rId, 1)
            );
        }else{
            return
            (
                round[rId].jackpotAmount,
                0,
                0
            );
        }
    }
    
     
    function getValueInfo(address _playerAddr)
        public
        view
        returns(uint256, uint256)
    {
        if (player[_playerAddr].active == true){
            return
            (
                getPlayerDividend(_playerAddr),
                player[_playerAddr].promotionAmount
            );
        }else{
            return
            (
                0,
                0
            );
        }
    }
    
}

library Indatasets {
    
    struct Round {
        uint256 start;           
        uint256 end;             
        bool ended;              
        uint256 endSid;          
        uint256 amount;          
        uint256 jackpotAmount;   
        uint256 players;         
    }
    
    struct Stage {
        uint256 start;           
        uint256 end;             
        bool ended;              
        uint256 targetAmount;    
        uint256 amount;          
        uint256 dividendAmount;  
        uint256 accAmount;       
        uint256 players;         
    }
    
    struct Player {
        bool active;                 
        uint256 amount;              
        uint256 promotionAmount;     
        uint256 withdrawRid;         
        uint256 withdrawSid;         
    }
}

 
library SafeMath {
    
     
    function add(uint256 a, uint256 b) 
        internal 
        pure 
        returns (uint256) 
    {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
    
     
    function sub(uint256 a, uint256 b) 
        internal 
        pure 
        returns (uint256) 
    {
        assert(b <= a);
        return a - b;
    }

     
    function mul(uint256 a, uint256 b) 
        internal 
        pure 
        returns (uint256) 
    {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }
    
     
    function div(uint256 a, uint256 b) 
        internal 
        pure 
        returns (uint256) 
    {
        assert(b > 0);  
        uint256 c = a / b;
        assert(a == b * c + a % b);  
        return c;
    }
    
     
    function sqrt(uint256 x)
        internal
        pure
        returns (uint256 y) 
    {
        uint256 z = ((add(x,1)) / 2);
        y = x;
        while (z < y) 
        {
            y = z;
            z = ((add((x / z),z)) / 2);
        }
    }
    
     
    function sq(uint256 x)
        internal
        pure
        returns (uint256)
    {
        return (mul(x,x));
    }
    
     
    function pwr(uint256 x, uint256 y)
        internal 
        pure 
        returns (uint256)
    {
        if (x==0)
            return (0);
        else if (y==0)
            return (1);
        else 
        {
            uint256 z = x;
            for (uint256 i=1; i < y; i++)
                z = mul(z,x);
            return (z);
        }
    }
}
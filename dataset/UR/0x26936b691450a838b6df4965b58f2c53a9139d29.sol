 

pragma solidity ^0.4.25;

 


contract ERC721{
    
    function totalSupply() public view returns (uint256 total);
    function balanceOf(address _owner) public view returns (uint256 balance);
    function ownerOf(uint256 _tokenId) public view returns (address owner);
    function approve(address _to, uint256 _tokenId) public;
    function takeOwnership(uint256 _tokenId) public;
    function transfer(address _to, uint256 _tokenId) public;
    function transferFrom(address _from, address _to, uint256 _tokenId) public;
    
    event Transfer(address from, address to, uint256 tokenId);
    event Approval(address owner, address approved, uint256 tokenId);
}

contract FairBankFomo is ERC721{
    using SafeMath for uint256;
       
    address public developerAddr = 0xbC817A495f0114755Da5305c5AA84fc5ca7ebaBd;
    address public fairProfitContract = 0x53a39eeF083c4A91e36145176Cc9f52bE29B7288;

    string public name = "FairDAPP - Bank Simulator - Fomo";
    string public symbol = "FBankFomo";
    
    uint256 public stageDuration = 3600;
    uint256 public standardProtectRatio = 57;
    bool public modifyCountdown = false;
    uint256 public startTime = 1539997200;
    uint256 public cardTime = 1539993600;
    
    uint256 public rId = 1;
    uint256 public sId = 1;
    
    mapping (uint256 => FBankdatasets.Round) public round;
    mapping (uint256 => mapping (uint256 => FBankdatasets.Stage)) public stage;
    
    mapping (address => bool) public player;
    mapping (address => uint256[]) public playerGoodsList;
    mapping (address => uint256[]) public playerWithdrawList;
    
      
    FairBankCompute constant private bankCompute = FairBankCompute(0xdd033Ff7e98792694F6b358DaEB065d4FF01Bd5A);
    
    FBankdatasets.Goods[] public goodsList;
    
    FBankdatasets.Card[6] public cardList;
    mapping (uint256 => address) public cardIndexToApproved;
    
    modifier isDeveloperAddr() {
        require(msg.sender == developerAddr, "Permission denied");
        _;
    }
    
    modifier startTimeVerify() {
        require(now >= startTime); 
        _;
    }
    
    modifier cardTimeVerify() {
        require(now >= cardTime); 
        _;
    }
    
    modifier modifyCountdownVerify() {
        require(modifyCountdown == true, "this feature is not turned on or has been turned off"); 
        require(now >= stage[rId][sId].start, "Can only use the addtime/reduce time functions when game has started");  
        _;
    }
     
    modifier senderVerify() {
        require (msg.sender == tx.origin, "sender does not meet the rules");
        if(!player[msg.sender])
            player[msg.sender] = true;
        _;
    }
    
     
    modifier buyVerify() {
          
        if(msg.value < 1000000000000000){
            developerAddr.send(msg.value);
        }else{
            require(msg.value >= 1000000000000000, "minimum amount is 0.001 ether");
            
            if(sId < 25)
                require(tx.gasprice <= 25000000000);
                
            if(sId < 25)
                require(msg.value <= 10 ether);
         _;
        }
    }
    
    modifier withdrawVerify() {
        require(playerGoodsList[msg.sender].length > 0, "user has not purchased the product or has completed the withdrawal");
        _;
    }
    
    modifier stepSizeVerify(uint256 _stepSize) {
        require(_stepSize <= 1000000, "step size must not exceed 1000000");
        _;
    }
    
    constructor()
        public
    {
        round[rId].start = startTime;
        stage[rId][sId].start = startTime;
        uint256 i;
        while(i < cardList.length){
            cardList[i].playerAddress = fairProfitContract;
            cardList[i].amount = 1 ether; 
            i++;
        }
    }
    
    function openModifyCountdown()
        senderVerify()
        isDeveloperAddr()
        public
    {
        require(modifyCountdown == false, "Time service is already open");
        
        modifyCountdown = true;
        
    }
    
    function closeModifyCountdown()
        senderVerify()
        isDeveloperAddr()
        public
    {
        require(modifyCountdown == true, "Time service is already open");
        
        modifyCountdown = false;
        
    }
    
    function purchaseCard(uint256 _cId)
        cardTimeVerify()
        senderVerify()
        payable
        public
    {
        
        address _player = msg.sender;
        uint256 _amount = msg.value;
        uint256 _purchasePrice = cardList[_cId].amount.mul(110) / 100;
        
        require(
            cardList[_cId].playerAddress != address(0) 
            && cardList[_cId].playerAddress != _player 
            && _amount >= _purchasePrice, 
            "Failed purchase"
        );
        
        if(cardIndexToApproved[_cId] != address(0)){
            cardIndexToApproved[_cId].send(
                cardList[_cId].amount.mul(105) / 100
                );
            delete cardIndexToApproved[_cId];
        }else
            cardList[_cId].playerAddress.send(
                cardList[_cId].amount.mul(105) / 100
                );
        
        fairProfitContract.send(cardList[_cId].amount.mul(5) / 100);
        if(_amount > _purchasePrice)
            _player.send(_amount.sub(_purchasePrice));
            
        cardList[_cId].amount = _purchasePrice;
        cardList[_cId].playerAddress = _player;
        
    }
    
     
    function()
        startTimeVerify()
        senderVerify()
        buyVerify()
        payable
        public
    {
        buyAnalysis(100, standardProtectRatio);
    }

    function buy(uint256 _stepSize, uint256 _protectRatio)
        startTimeVerify()
        senderVerify()
        buyVerify()
        stepSizeVerify(_stepSize)
        public
        payable
    {
        buyAnalysis(
            _stepSize <= 0 ? 100 : _stepSize, 
            _protectRatio <= 100 ? _protectRatio : standardProtectRatio
            );
    }
    
     
    function withdraw()
        startTimeVerify()
        senderVerify()
        withdrawVerify()
        public
    {
        
        address _player = msg.sender;
        uint256[] memory _playerGoodsList = playerGoodsList[_player];
        uint256 length = _playerGoodsList.length;
        uint256 _totalAmount;
        uint256 _amount;
        uint256 _withdrawSid;
        uint256 _reachAmount;
        bool _finish;
        uint256 i;
        
        delete playerGoodsList[_player];
        while(i < length){
            
            (_amount, _withdrawSid, _reachAmount, _finish) = getEarningsAmountByGoodsIndex(_playerGoodsList[i]);
            
            if(_finish == true){
                playerWithdrawList[_player].push(_playerGoodsList[i]);
            }else{
                goodsList[_playerGoodsList[i]].withdrawSid = _withdrawSid;
                goodsList[_playerGoodsList[i]].reachAmount = _reachAmount;
                playerGoodsList[_player].push(_playerGoodsList[i]);
            }
            
            _totalAmount = _totalAmount.add(_amount);
            i++;
        }
        _player.transfer(_totalAmount);
    }
     
      
    function withdrawByGid(uint256 _gId)
        startTimeVerify()
        senderVerify()
        withdrawVerify()
        public
    {
        address _player = msg.sender;
        uint256 _amount;
        uint256 _withdrawSid;
        uint256 _reachAmount;
        bool _finish;
        
        (_amount, _withdrawSid, _reachAmount, _finish) = getEarningsAmountByGoodsIndex(_gId);
            
        if(_finish == true){
            
            for(uint256 i = 0; i < playerGoodsList[_player].length; i++){
                if(playerGoodsList[_player][i] == _gId)
                    break;
            }
            require(i < playerGoodsList[_player].length, "gid is wrong");
            
            playerWithdrawList[_player].push(_gId);
            playerGoodsList[_player][i] = playerGoodsList[_player][playerGoodsList[_player].length - 1];
            playerGoodsList[_player].length--;
        }else{
            goodsList[_gId].withdrawSid = _withdrawSid;
            goodsList[_gId].reachAmount = _reachAmount;
        }
        
        _player.transfer(_amount);
    }
    
    function resetTime()
        modifyCountdownVerify()
        senderVerify()
        public
        payable
    {
        uint256 _rId = rId;
        uint256 _sId = sId;
        uint256 _amount = msg.value;
        uint256 _targetExpectedAmount = getStageTargetAmount(_sId);
        uint256 _targetAmount = 
            stage[_rId][_sId].dividendAmount <= _targetExpectedAmount ? 
            _targetExpectedAmount : stage[_rId][_sId].dividendAmount;
            _targetAmount = _targetAmount.mul(100) / 88;
        uint256 _costAmount = _targetAmount.mul(20) / 100;
        
        if(_costAmount > 3 ether)
            _costAmount = 3 ether;
        require(_amount >= _costAmount, "Not enough price");
        
        stage[_rId][_sId].start = now;
        
        cardList[5].playerAddress.send(_costAmount / 2);
        developerAddr.send(_costAmount / 2);
        
        if(_amount > _costAmount)
            msg.sender.send(_amount.sub(_costAmount));
        
    }
    
    function reduceTime()
        modifyCountdownVerify()
        senderVerify()
        public
        payable
    {
        uint256 _rId = rId;
        uint256 _sId = sId;
        uint256 _amount = msg.value;
        uint256 _targetExpectedAmount = getStageTargetAmount(_sId);
        uint256 _targetAmount = 
            stage[_rId][_sId].dividendAmount <= _targetExpectedAmount ?
            _targetExpectedAmount : stage[_rId][_sId].dividendAmount;
            _targetAmount = _targetAmount.mul(100) / 88;
        uint256 _costAmount = _targetAmount.mul(30) / 100;
        
        if(_costAmount > 3 ether)
            _costAmount = 3 ether;
        require(_amount >= _costAmount, "Not enough price");
        
        stage[_rId][_sId].start = now - stageDuration + 900;
        
        cardList[5].playerAddress.send(_costAmount / 2);
        developerAddr.send(_costAmount / 2);
        
        if(_amount > _costAmount)
            msg.sender.send(_amount.sub(_costAmount));
        
    }
    
     
    function buyAnalysis(uint256 _stepSize, uint256 _protectRatio)
        private
    {
        uint256 _rId = rId;
        uint256 _sId = sId;
        uint256 _targetExpectedAmount = getStageTargetAmount(_sId);
        uint256 _targetAmount = 
            stage[_rId][_sId].dividendAmount <= _targetExpectedAmount ? 
            _targetExpectedAmount : stage[_rId][_sId].dividendAmount;
            _targetAmount = _targetAmount.mul(100) / 88;
        uint256 _stageTargetBalance = 
            stage[_rId][_sId].amount > 0 ? 
            _targetAmount.sub(stage[_rId][_sId].amount) : _targetAmount;
        
        if(now > stage[_rId][_sId].start.add(stageDuration) 
            && _targetAmount > stage[_rId][_sId].amount
        ){
            
            endRound(_rId, _sId);
            
            _rId = rId;
            _sId = sId;
            stage[_rId][_sId].start = now;
            
            _targetExpectedAmount = getStageTargetAmount(_sId);
            _targetAmount = 
                stage[_rId][_sId].dividendAmount <= _targetExpectedAmount ? 
                _targetExpectedAmount : stage[_rId][_sId].dividendAmount;
            _targetAmount = _targetAmount.mul(100) / 88;
            _stageTargetBalance = 
                stage[_rId][_sId].amount > 0 ? 
                _targetAmount.sub(stage[_rId][_sId].amount) : _targetAmount;
        }
        if(_stageTargetBalance > msg.value)
            buyDataRecord(
                _rId, 
                _sId, 
                _targetAmount, 
                msg.value, 
                _stepSize, 
                _protectRatio
                );
        else
            multiStake(
                msg.value, 
                _stepSize, 
                _protectRatio, 
                _targetAmount, 
                _stageTargetBalance
                );
         
        require(
            (
                round[_rId].jackpotAmount.add(round[_rId].amount.mul(88) / 100)
                .sub(round[_rId].protectAmount)
                .sub(round[_rId].dividendAmount)
            ) > 0, "data error"
        );    
        bankerFeeDataRecord(msg.value, _protectRatio);    
    }
    
    function multiStake(uint256 _amount, uint256 _stepSize, uint256 _protectRatio, uint256 _targetAmount, uint256 _stageTargetBalance)
        private
    {
        uint256 _rId = rId;
        uint256 _sId = sId;
        uint256 _crossStageNum = 1;
        uint256 _protectTotalAmount;
        uint256 _dividendTotalAmount;
            
        while(true){

            if(_crossStageNum == 1){
                playerDataRecord(
                    _rId, 
                    _sId, 
                    _amount, 
                    _stageTargetBalance, 
                    _stepSize, 
                    _protectRatio, 
                    _crossStageNum
                    );
                round[_rId].amount = round[_rId].amount.add(_amount);
                round[_rId].protectAmount = round[_rId].protectAmount.add(
                    _amount.mul(_protectRatio.mul(88)) / 10000);    
            }
                
            buyStageDataRecord(
                _rId, 
                _sId, 
                _targetAmount, 
                _stageTargetBalance, 
                _sId.
                add(_stepSize), 
                _protectRatio
                );
            _dividendTotalAmount = _dividendTotalAmount.add(stage[_rId][_sId].dividendAmount);
            _protectTotalAmount = _protectTotalAmount.add(stage[_rId][_sId].protectAmount);
            
            _sId++;
            _amount = _amount.sub(_stageTargetBalance);
            _targetAmount = 
                stage[_rId][_sId].dividendAmount <= getStageTargetAmount(_sId) ? 
                getStageTargetAmount(_sId) : stage[_rId][_sId].dividendAmount;
            _targetAmount = _targetAmount.mul(100) / 88;
            _stageTargetBalance = _targetAmount;
            _crossStageNum++;
            if(_stageTargetBalance >= _amount){
                buyStageDataRecord(
                    _rId, 
                    _sId, 
                    _targetAmount, 
                    _amount, 
                    _sId.add(_stepSize), 
                    _protectRatio
                    );
                playerDataRecord(
                    _rId, 
                    _sId, 
                    0, 
                    _amount, 
                    _stepSize, 
                    _protectRatio, 
                    _crossStageNum
                    );
                    
                if(_targetAmount == _amount)
                    _sId++;
                    
                stage[_rId][_sId].start = now;
                sId = _sId;
                
                round[_rId].protectAmount = round[_rId].protectAmount.sub(_protectTotalAmount);
                round[_rId].dividendAmount = round[_rId].dividendAmount.add(_dividendTotalAmount);
                break;
            }
        }
    }
    
     
    function buyDataRecord(uint256 _rId, uint256 _sId, uint256 _targetAmount, uint256 _amount, uint256 _stepSize, uint256 _protectRatio)
        private
    {
        uint256 _expectEndSid = _sId.add(_stepSize);
        uint256 _protectAmount = _amount.mul(_protectRatio.mul(88)) / 10000;
        
        round[_rId].amount = round[_rId].amount.add(_amount);
        round[_rId].protectAmount = round[_rId].protectAmount.add(_protectAmount);
        
        stage[_rId][_sId].amount = stage[_rId][_sId].amount.add(_amount);
        stage[_rId][_expectEndSid].protectAmount = stage[_rId][_expectEndSid].protectAmount.add(_protectAmount);
        stage[_rId][_expectEndSid].dividendAmount = 
            stage[_rId][_expectEndSid].dividendAmount.add(
                computeEarningsAmount(_sId, 
                _amount, 
                _targetAmount, 
                _expectEndSid, 
                100 - _protectRatio
                )
                );
                
        FBankdatasets.Goods memory _goods;
        _goods.rId = _rId;
        _goods.startSid = _sId;
        _goods.amount = _amount;
        _goods.endSid = _expectEndSid;
        _goods.protectRatio = _protectRatio;
        playerGoodsList[msg.sender].push(goodsList.push(_goods) - 1);
    }
    
     
    function buyStageDataRecord(uint256 _rId, uint256 _sId, uint256 _targetAmount, uint256 _amount, uint256 _expectEndSid, uint256 _protectRatio)
        private
    {
        uint256 _protectAmount = _amount.mul(_protectRatio.mul(88)) / 10000;
        
        if(_targetAmount != _amount)
            stage[_rId][_sId].amount = stage[_rId][_sId].amount.add(_amount);
        stage[_rId][_expectEndSid].protectAmount = stage[_rId][_expectEndSid].protectAmount.add(_protectAmount);
        stage[_rId][_expectEndSid].dividendAmount = 
            stage[_rId][_expectEndSid].dividendAmount.add(
                computeEarningsAmount(
                    _sId, 
                    _amount, 
                    _targetAmount, 
                    _expectEndSid, 
                    100 - _protectRatio
                    )
                );
    }
    
     
    function playerDataRecord(uint256 _rId, uint256 _sId, uint256 _totalAmount, uint256 _stageBuyAmount, uint256 _stepSize, uint256 _protectRatio, uint256 _crossStageNum)
        private
    {    
        if(_crossStageNum <= 1){
            FBankdatasets.Goods memory _goods;
            _goods.rId = _rId;
            _goods.startSid = _sId;
            _goods.amount = _totalAmount;
            _goods.stepSize = _stepSize;
            _goods.protectRatio = _protectRatio;
            if(_crossStageNum == 1)
                _goods.startAmount = _stageBuyAmount;
            playerGoodsList[msg.sender].push(goodsList.push(_goods) - 1);
        }
        else{
            uint256 _goodsIndex = goodsList.length - 1;
            goodsList[_goodsIndex].endAmount = _stageBuyAmount;
            goodsList[_goodsIndex].endSid = _sId;
        }
        
    }
    
    function bankerFeeDataRecord(uint256 _amount, uint256 _protectRatio)
        private
    {
        round[rId].jackpotAmount = round[rId].jackpotAmount.add(_amount.mul(9).div(100));

        uint256 _cardAmount = _amount / 100;
        if(_protectRatio == 0)
            cardList[0].playerAddress.send(_cardAmount);
        else if(_protectRatio > 0 && _protectRatio < 57)
            cardList[1].playerAddress.send(_cardAmount);   
        else if(_protectRatio == 57)
            cardList[2].playerAddress.send(_cardAmount);   
        else if(_protectRatio > 57 && _protectRatio < 100)
            cardList[3].playerAddress.send(_cardAmount);   
        else if(_protectRatio == 100)
            cardList[4].playerAddress.send(_cardAmount);   
        
        fairProfitContract.send(_amount.div(50));
    }
    
    function endRound(uint256 _rId, uint256 _sId)
        private
    {
        round[_rId].end = now;
        round[_rId].ended = true;
        round[_rId].endSid = _sId;
        
        if(stage[_rId][_sId].amount > 0)
            round[_rId + 1].jackpotAmount = (
                round[_rId].jackpotAmount.add(round[_rId].amount.mul(88) / 100)
                .sub(round[_rId].protectAmount)
                .sub(round[_rId].dividendAmount)
            ).mul(20).div(100);
        else
            round[_rId + 1].jackpotAmount = (
                round[_rId].jackpotAmount.add(round[_rId].amount.mul(88) / 100)
                .sub(round[_rId].protectAmount)
                .sub(round[_rId].dividendAmount)
            );
        
        round[_rId + 1].start = now;
        rId++;
        sId = 1;
    }
    
    function getStageTargetAmount(uint256 _sId)
        public
        view
        returns(uint256)
    {
        return bankCompute.getStageTargetAmount(_sId);
    }
    
    function computeEarningsAmount(uint256 _sId, uint256 _amount, uint256 _currentTargetAmount, uint256 _expectEndSid, uint256 _ratio)
        public
        view
        returns(uint256)
    {
        return bankCompute.computeEarningsAmount(_sId, _amount, _currentTargetAmount, _expectEndSid, _ratio);
    }
    
    function getEarningsAmountByGoodsIndex(uint256 _goodsIndex)
        public
        view
        returns(uint256, uint256, uint256, bool)
    {
        FBankdatasets.Goods memory _goods = goodsList[_goodsIndex];
        uint256 _sId = sId;
        uint256 _amount;
        uint256 _targetExpectedAmount;
        uint256 _targetAmount;
        if(_goods.stepSize == 0){
            if(round[_goods.rId].ended == true){
                if(round[_goods.rId].endSid > _goods.endSid){
                    _targetExpectedAmount = getStageTargetAmount(_goods.startSid);
                    _targetAmount = 
                        stage[_goods.rId][_goods.startSid].dividendAmount <= _targetExpectedAmount ? 
                        _targetExpectedAmount : stage[_goods.rId][_goods.startSid].dividendAmount;
                    _targetAmount = _targetAmount.mul(100) / 88;
                    _amount = computeEarningsAmount(
                        _goods.startSid, 
                        _goods.amount, 
                        _targetAmount, 
                        _goods.endSid, 
                        100 - _goods.protectRatio
                        );
                    
                }else
                    _amount = _goods.amount.mul(_goods.protectRatio.mul(88)) / 10000;
                    
                if(round[_goods.rId].endSid == _goods.startSid)
                    _amount = _amount.add(
                        _goods.amount.mul(
                            getRoundJackpot(_goods.rId)
                            ).div(stage[_goods.rId][_goods.startSid].amount)
                            );
                
                return (_amount, 0, 0, true);
            }else{
                if(_sId > _goods.endSid){
                    _targetExpectedAmount = getStageTargetAmount(_goods.startSid);
                    _targetAmount = 
                        stage[_goods.rId][_goods.startSid].dividendAmount <= _targetExpectedAmount ?
                        _targetExpectedAmount : stage[_goods.rId][_goods.startSid].dividendAmount;
                    _targetAmount = _targetAmount.mul(100) / 88;
                    _amount = computeEarningsAmount(
                        _goods.startSid, 
                        _goods.amount, 
                        _targetAmount, 
                        _goods.endSid, 
                        100 - _goods.protectRatio
                        );
                }else
                    return (0, 0, 0, false);
            }
            return (_amount, 0, 0, true);
            
        }else{
            
            uint256 _startSid = _goods.withdrawSid == 0 ? _goods.startSid : _goods.withdrawSid;
            uint256 _ratio = 100 - _goods.protectRatio;
            uint256 _reachAmount = _goods.reachAmount;
            if(round[_goods.rId].ended == true){
                
                while(true){
                    
                    if(_startSid - (_goods.withdrawSid == 0 ? _goods.startSid : _goods.withdrawSid) > 100){
                        return (_amount, _startSid, _reachAmount, false);
                    }
                    
                    if(round[_goods.rId].endSid > _startSid.add(_goods.stepSize)){
                        _targetExpectedAmount = getStageTargetAmount(_startSid);
                        _targetAmount = 
                            stage[_goods.rId][_startSid].dividendAmount <= _targetExpectedAmount ? 
                            _targetExpectedAmount : stage[_goods.rId][_startSid].dividendAmount;
                        _targetAmount = _targetAmount.mul(100) / 88;
                        if(_startSid == _goods.endSid){
                            _amount = _amount.add(
                                computeEarningsAmount(
                                    _startSid, 
                                    _goods.endAmount, 
                                    _targetAmount, 
                                    _startSid.add(_goods.stepSize), 
                                    _ratio
                                    )
                                );
                            return (_amount, _goods.endSid, 0, true);
                        }
                        _amount = _amount.add(
                            computeEarningsAmount(
                                _startSid, 
                                _startSid == _goods.startSid ? _goods.startAmount : _targetAmount, 
                                _targetAmount, 
                                _startSid.add(_goods.stepSize), 
                                _ratio
                                )
                            );
                        _reachAmount = 
                            _reachAmount.add(
                                _startSid == _goods.startSid ? _goods.startAmount : _targetAmount
                            );
                    }else{
                        
                        _amount = _amount.add(
                            (_goods.amount.sub(_reachAmount))
                            .mul(_goods.protectRatio.mul(88)) / 10000
                            );
                        
                        if(round[_goods.rId].endSid == _goods.endSid)
                            _amount = _amount.add(
                                _goods.endAmount.mul(getRoundJackpot(_goods.rId))
                                .div(stage[_goods.rId][_goods.endSid].amount)
                                );
                        
                        return (_amount, _goods.endSid, 0, true);
                    }
                    
                    _startSid++;
                }
                
            }else{
                while(true){
                    
                    if(_startSid - (_goods.withdrawSid == 0 ? _goods.startSid : _goods.withdrawSid) > 100){
                        return (_amount, _startSid, _reachAmount, false);
                    }
                    
                    if(_sId > _startSid.add(_goods.stepSize)){
                        _targetExpectedAmount = getStageTargetAmount(_startSid);
                        _targetAmount = 
                            stage[_goods.rId][_startSid].dividendAmount <= _targetExpectedAmount ? 
                            _targetExpectedAmount : stage[_goods.rId][_startSid].dividendAmount;
                        _targetAmount = _targetAmount.mul(100) / 88;
                        if(_startSid == _goods.endSid){
                            _amount = _amount.add(
                                computeEarningsAmount(
                                    _startSid, 
                                    _goods.endAmount, 
                                    _targetAmount, 
                                    _startSid.add(_goods.stepSize), 
                                    _ratio
                                    )
                                );
                            return (_amount, _goods.endSid, 0, true);
                        }
                        _amount = _amount.add(
                            computeEarningsAmount(
                                _startSid, 
                                _startSid == _goods.startSid ? _goods.startAmount : _targetAmount, 
                                _targetAmount, 
                                _startSid.add(_goods.stepSize), 
                                _ratio
                                )
                            );
                        _reachAmount = 
                            _reachAmount.add(
                                _startSid == _goods.startSid ? 
                                _goods.startAmount : _targetAmount
                            );
                    }else    
                        return (_amount, _startSid, _reachAmount, false);
                    
                    _startSid++;
                }
            }
        }
    }
    
    function getRoundJackpot(uint256 _rId)
        public
        view
        returns(uint256)
    {
        return (
            (
                round[_rId].jackpotAmount
                .add(round[_rId].amount.mul(88) / 100))
                .sub(round[_rId].protectAmount)
                .sub(round[_rId].dividendAmount)
            ).mul(80).div(100);
    }
    
    function getHeadInfo()
        public
        view
        returns(uint256, uint256, uint256, uint256, uint256, uint256, uint256)
    {
        uint256 _targetExpectedAmount = getStageTargetAmount(sId);
        
        return
            (
                rId,
                sId,
                startTime,
                stage[rId][sId].start.add(stageDuration),
                stage[rId][sId].amount,
                (
                    stage[rId][sId].dividendAmount <= _targetExpectedAmount ? 
                    _targetExpectedAmount : stage[rId][sId].dividendAmount
                ).mul(100) / 88,
                round[rId].jackpotAmount.add(round[rId].amount.mul(88) / 100)
                .sub(round[rId].protectAmount)
                .sub(round[rId].dividendAmount)
            );
    }
    
    function getPlayerGoodList(address _player)
        public
        view
        returns(uint256[])
    {
        return playerGoodsList[_player];
    }

    function totalSupply() 
        public 
        view 
        returns (uint256 total)
    {
        return cardList.length;
    }
    
    function balanceOf(address _owner) 
        public 
        view 
        returns (uint256 balance)
    {
        uint256 _length = cardList.length;
        uint256 _count;
        for(uint256 i = 0; i < _length; i++){
            if(cardList[i].playerAddress == _owner)
                _count++;
        }
        
        return _count;
    }
    
    function ownerOf(uint256 _tokenId) 
        public 
        view 
        returns (address owner)
    {
        require(cardList.length > _tokenId, "tokenId error");
        owner = cardList[_tokenId].playerAddress;
        require(owner != address(0), "No owner");
    }
    
    function approve(address _to, uint256 _tokenId)
        senderVerify()
        public
    {
        require (player[_to], "Not a registered user");
        require (msg.sender == cardList[_tokenId].playerAddress, "The card does not belong to you");
        require (cardList.length > _tokenId, "tokenId error");
        require (cardIndexToApproved[_tokenId] == address(0), "Approved");
        
        cardIndexToApproved[_tokenId] = _to;
        
        emit Approval(msg.sender, _to, _tokenId);
    }
    
    function takeOwnership(uint256 _tokenId)
        senderVerify()
        public
    {
        address _newOwner = msg.sender;
        address _oldOwner = cardList[_tokenId].playerAddress;
        
        require(_newOwner != address(0), "Address error");
        require(_newOwner == cardIndexToApproved[_tokenId], "Without permission");
        
        cardList[_tokenId].playerAddress = _newOwner;
        delete cardIndexToApproved[_tokenId];
        
        emit Transfer(_oldOwner, _newOwner, _tokenId);
    }
    
    function transfer(address _to, uint256 _tokenId) 
        senderVerify()
        public
    {
        require (msg.sender == cardList[_tokenId].playerAddress, "The card does not belong to you");
        require(_to != address(0), "Address error");
        require(_to == cardIndexToApproved[_tokenId], "Without permission");
        
        cardList[_tokenId].playerAddress = _to;
        
        if(cardIndexToApproved[_tokenId] != address(0))
            delete cardIndexToApproved[_tokenId];
        
        emit Transfer(msg.sender, _to, _tokenId);
    }
    
    function transferFrom(address _from, address _to, uint256 _tokenId)
        senderVerify()
        public
    {
        require (_from == cardList[_tokenId].playerAddress, "Owner error");
        require(_to != address(0), "Address error");
        require(_to == cardIndexToApproved[_tokenId], "Without permission");
        
        cardList[_tokenId].playerAddress = _to;
        delete cardIndexToApproved[_tokenId];
        
        emit Transfer(_from, _to, _tokenId);
    }
    
}

library FBankdatasets {
    
    struct Round {
        uint256 start;
        uint256 end;
        bool ended;
        uint256 endSid;
        uint256 amount;
        uint256 protectAmount;
        uint256 dividendAmount;
        uint256 jackpotAmount;
    }
    
    struct Stage {
        uint256 start;
        uint256 amount;
        uint256 protectAmount;
        uint256 dividendAmount;
    }
    
    struct Goods {
        uint256 rId;
        uint256 startSid;
        uint256 endSid;
        uint256 withdrawSid;
        uint256 amount;
        uint256 startAmount;
        uint256 endAmount;
        uint256 reachAmount;
        uint256 stepSize;
        uint256 protectRatio;
    }
    
    struct Card {
        address playerAddress;
        uint256 amount;
    }
}

  
interface FairBankCompute {
    function getStageTargetAmount(uint256 _sId) external view returns(uint256);
    function computeEarningsAmount(uint256 _sId, uint256 _amount, uint256 _currentTargetAmount, uint256 _expectEndSid, uint256 _ratio) external view returns(uint256);
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
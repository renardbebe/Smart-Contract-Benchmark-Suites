 

pragma solidity ^0.4.24;

 

 

library Helper {
    using SafeMath for uint256;

    uint256 constant public ZOOM = 1000;
    uint256 constant public SDIVIDER = 3450000;
    uint256 constant public PDIVIDER = 3450000;
    uint256 constant public RDIVIDER = 1580000;
     
    uint256 constant public SLP = 0.002 ether;
     
    uint256 constant public SAT = 30;  
     
    uint256 constant public PN = 777;
     
    uint256 constant public PBASE = 13;
    uint256 constant public PMULTI = 26;
    uint256 constant public LBase = 1;

    uint256 constant public ONE_HOUR = 3600;
    uint256 constant public ONE_DAY = 24 * ONE_HOUR;
     
    uint256 constant public TIMEOUT1 = 12 * ONE_HOUR;
    uint256 constant public TIMEOUT2 = 7 * ONE_DAY;
    
    function bytes32ToString (bytes32 data)
        public
        pure
        returns (string) 
    {
        bytes memory bytesString = new bytes(32);
        for (uint j=0; j<32; j++) {
            byte char = byte(bytes32(uint(data) * 2 ** (8 * j)));
            if (char != 0) {
                bytesString[j] = char;
            }
        }
        return string(bytesString);
    }
    
    function uintToBytes32(uint256 n)
        public
        pure
        returns (bytes32) 
    {
        return bytes32(n);
    }
    
    function bytes32ToUint(bytes32 n) 
        public
        pure
        returns (uint256) 
    {
        return uint256(n);
    }
    
    function stringToBytes32(string memory source) 
        public
        pure
        returns (bytes32 result) 
    {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(source, 32))
        }
    }
    
    function stringToUint(string memory source) 
        public
        pure
        returns (uint256)
    {
        return bytes32ToUint(stringToBytes32(source));
    }
    
    function uintToString(uint256 _uint) 
        public
        pure
        returns (string)
    {
        return bytes32ToString(uintToBytes32(_uint));
    }

 
    function validUsername(string _username)
        public
        pure
        returns(bool)
    {
        uint256 len = bytes(_username).length;
         
        if ((len < 4) || (len > 18)) return false;
         
        if (bytes(_username)[len-1] == 32) return false;
         
        return uint256(bytes(_username)[0]) != 48;
    }

     

     
    function getAddedTime(uint256 _rTicketSum, uint256 _tAmount)
        public
        pure
        returns (uint256)
    {
         
        uint256 base = (_rTicketSum + 1).mul(10000) / SDIVIDER;
        uint256 expo = base;
        expo = expo.mul(expo).mul(expo);  
        expo = expo.mul(expo);  
         
        expo = expo / (10**24);

        if (expo > SAT) return 0;
        return (SAT - expo).mul(_tAmount);
    }

    function getNewEndTime(uint256 toAddTime, uint256 slideEndTime, uint256 fixedEndTime)
        public
        view
        returns(uint256)
    {
        uint256 _slideEndTime = (slideEndTime).add(toAddTime);
        uint256 timeout = _slideEndTime.sub(block.timestamp);
         
        if (timeout > TIMEOUT1) timeout = TIMEOUT1;
        _slideEndTime = (block.timestamp).add(timeout);
         
        if (_slideEndTime > fixedEndTime)  return fixedEndTime;
        return _slideEndTime;
    }

     
    function getRandom(uint256 _seed, uint256 _range)
        public
        pure
        returns(uint256)
    {
        if (_range == 0) return _seed;
        return (_seed % _range) + 1;
    }


    function getEarlyIncomeMul(uint256 _ticketSum)
        public
        pure
        returns(uint256)
    {
         
        uint256 base = _ticketSum * ZOOM / RDIVIDER;
        uint256 expo = base.mul(base).mul(base);  
        expo = expo.mul(expo) / (ZOOM**6);  
        return (1 + PBASE / (1 + expo.mul(PMULTI)));
    }

     
    function getTAmount(uint256 _ethAmount, uint256 _ticketSum) 
        public
        pure
        returns(uint256)
    {
        uint256 _tPrice = getTPrice(_ticketSum);
        return _ethAmount.div(_tPrice);
    }

    function isGoldenMin(
        uint256 _slideEndTime
        )
        public
        view
        returns(bool)
    {
        uint256 _restTime1 = _slideEndTime.sub(block.timestamp);
         
        if (_restTime1 > 6 hours) return false;
        uint256 _min = (block.timestamp / 60) % 60;
        return _min == 8;
    }

     
     
     
     
     
    function getTMul(
        uint256 _initGrandPot,
        uint256 _grandPot, 
        uint256 _slideEndTime, 
        uint256 _fixedEndTime
        )
        public
        view
        returns(uint256)
    {
        uint256 _pZoom = 100;
        uint256 base = _initGrandPot != 0 ?_pZoom.mul(_grandPot) / _initGrandPot : _pZoom;
        uint256 expo = base.mul(base);
        uint256 _timer1 = _slideEndTime.sub(block.timestamp) / 1 hours;  
        uint256 _timer2 = _fixedEndTime.sub(block.timestamp) / 1 days;  
        uint256 x = (_pZoom * (11 - _timer1) / 4) + _pZoom;  
        uint256 y = (_pZoom * (6 - _timer2) / 3) + _pZoom;  
        uint256 z = isGoldenMin(_slideEndTime) ? 4 : 1;
        uint256 res = expo.mul(x).mul(y).mul(z) / (_pZoom ** 3);  
        return res;
    }

     
     
    function getTPrice(uint256 _ticketSum)
        public
        pure
        returns(uint256)
    {
        uint256 base = (_ticketSum + 1).mul(ZOOM) / PDIVIDER;
        uint256 expo = base;
        expo = expo.mul(expo).mul(expo);  
        expo = expo.mul(expo);  
        uint256 tPrice = SLP + expo / PN;
        return tPrice;
    }

     
     
     
    function getWeightRange(uint256 initGrandPot)
        public
        pure
        returns(uint256)
    {
        uint256 avgMul = 30;
        return ((initGrandPot * 2 * 100 / 68) * avgMul / SLP) + 1000;
    }

     
     
     
     
     
    function isJackpot(
        uint256 _seed,
        uint256 _RATE,
        uint256 _MIN,
        uint256 _ethAmount
        )
        public
        pure
        returns(bool)
    {
         
        uint256 k = _ethAmount / _MIN;
        if (k == 0) return false;
         
        uint256 _loseCap = _RATE / 2;
         
        if (_RATE > k + _loseCap) _loseCap = _RATE - k;

        bool _lose = (_seed % _RATE) < _loseCap;
        return !_lose;
    }
}

contract Lottery {
    using SafeMath for uint256;

    modifier withdrawRight(){
        require(msg.sender == address(bankContract), "Bank only");
        _;
    }

    modifier onlyDevTeam() {
        require(msg.sender == devTeam, "only for development team");
        _;
    }

    modifier buyable() {
        require(block.timestamp > round[curRoundId].startTime, "not ready to sell Ticket");
        require(block.timestamp < round[curRoundId].slideEndTime, "round over");
        require(block.number <= round[curRoundId].keyBlockNr, "round over");
        _;
    }

    modifier notStarted() {
        require(block.timestamp < round[curRoundId].startTime, "round started");
        _;
    }

    enum RewardType {
        Minor,
        Major,
        Grand,
        Bounty
    }

     
    struct Slot {
        address buyer;
        uint256 rId;
         
        uint256 tNumberFrom;
        uint256 tNumberTo;
        uint256 ethAmount;
        uint256 salt;
    }

    struct Round {
         
        uint256 rEarlyIncomeWeight;
         
        uint256 keyBlockNr;
        mapping(address => bool) pBonusReceived;

        mapping(address => uint256) pBoughtTicketSum;
        mapping(address => uint256) pTicketSum;
        mapping(address => uint256) pInvestedSum;

         
        mapping(address => uint256) pEarlyIncomeWeight;
        mapping(address => uint256) pEarlyIncomeCredit;
        mapping(address => uint256) pEarlyIncomeClaimed;
         
        uint256 ppw;
         
         
        uint256 startTime;
        uint256 slideEndTime;
        uint256 fixedEndTime;

         
        uint256 ticketSum;
         
        uint256 investedSum;
         
        uint256 slotSum;
    }

     
     
     
    uint256 public initGrandPot;

    Slot[] public slot;
     
    mapping( address => uint256[]) pSlot;
    mapping( address => uint256) public pSlotSum;

     
    mapping( address => uint256) public pTicketSum;
    mapping( address => uint256) public pInvestedSum;

    CitizenInterface public citizenContract;
    F2mInterface public f2mContract;
    BankInterface public bankContract;
    RewardInterface public rewardContract;

    address public devTeam;

    uint256 constant public ZOOM = 1000;
    uint256 constant public ONE_HOUR = 60 * 60;
    uint256 constant public ONE_DAY = 24 * ONE_HOUR;
    uint256 constant public TIMEOUT0 = 3 * ONE_HOUR;
    uint256 constant public TIMEOUT1 = 12 * ONE_HOUR;
    uint256 constant public TIMEOUT2 = 7 * ONE_DAY;
    uint256 constant public FINALIZE_WAIT_DURATION = 60;  
    uint256 constant public NEWROUND_WAIT_DURATION = 18 * ONE_HOUR;  

     
     
     
    uint256 constant public BLOCK_TIME = 12;
    uint256 constant public MAX_BLOCK_DISTANCE = 250;

    uint256 constant public TBONUS_RATE = 100;
    uint256 public CASHOUT_REQ = 1;

    uint256 public GRAND_RATE;
    uint256 public MAJOR_RATE = 1001;
    uint256 public MINOR_RATE = 501;
    uint256 constant public MAJOR_MIN = 0.1 ether;
    uint256 constant public MINOR_MIN = 0.1 ether;

     
    uint256 public bountyPercent = 30;
    uint256 public sBountyPercent = 10;

     
    uint256 public grandRewardPercent = 15;
    uint256 public sGrandRewardPercent = 5;
    uint256 public jRewardPercent = 60;

    uint256 public toTokenPercent = 12;  
    uint256 public toBuyTokenPercent = 1;
    uint256 public earlyIncomePercent = 22;
    uint256 public toRefPercent = 15;

     
     
    uint256 public majorPercent = 10;  
    uint256 public minorPercent = 10;  

    uint256 public grandPot;
    uint256 public majorPot;
    uint256 public minorPot;

    uint256 public curRoundId;
    uint256 public lastRoundId = 88888888;

    mapping (address => uint256) public rewardBalance;
     
     
    mapping (address => uint256) public lastWithdrawnRound;
    mapping (address => uint256) public earlyIncomeScannedSum;

    mapping (uint256 => Round) public round;

     

     
    uint256 public jSlot;
     
     
    uint256 public lastBlockNr;
     
     
    uint256 public curRSalt;
     
    uint256 public curRTicketSum;

    uint256 public lastBuyTime;
    uint256 public lastEndTime;
    uint256 constant multiDelayTime = 60;

    constructor (address _devTeam)
        public
    {
         
        DevTeamInterface(_devTeam).setLotteryAddress(address(this));
        devTeam = _devTeam;
    }

     
    function joinNetwork(address[6] _contract)
        public
    {
        require(address(citizenContract) == 0x0,"already setup");
        f2mContract = F2mInterface(_contract[0]);
        bankContract = BankInterface(_contract[1]);
        citizenContract = CitizenInterface(_contract[2]);
         
        rewardContract = RewardInterface(_contract[4]);
    }

    function activeFirstRound()
        public
        onlyDevTeam()
    {
        require(curRoundId == 0, "already activated");
        initRound();
        GRAND_RATE = getWeightRange();
    }

     

    function pushToPot() 
        public 
        payable
    {
        addPot(msg.value);
    }

    function checkpoint() 
        private
    {
         
         
        Slot memory _slot;
         
        slot.push(_slot);

        Round memory _round;
        _round.startTime = NEWROUND_WAIT_DURATION.add(block.timestamp);
         
        _round.slideEndTime = TIMEOUT0 + _round.startTime;
        _round.fixedEndTime = TIMEOUT2 + _round.startTime;
        _round.keyBlockNr = genEstKeyBlockNr(_round.slideEndTime);
        _round.ticketSum = round[curRoundId].ticketSum;
        _round.investedSum = round[curRoundId].investedSum;
        _round.slotSum = slot.length;

        curRoundId = curRoundId + 1;
        round[curRoundId] = _round;

        initGrandPot = grandPot;
        curRTicketSum = 0;
    }

     
    function isLastRound()
        public
        view
        returns(bool)
    {
        return (curRoundId == lastRoundId);
    }

    function goNext()
        private
    {
        grandPot = 0;
        majorPot = 0;
        minorPot = 0;
        f2mContract.pushDividends.value(this.balance)();
         
        round[curRoundId].startTime = block.timestamp * 10;
        round[curRoundId].slideEndTime = block.timestamp * 10 + 1;
        CASHOUT_REQ = 0;
    }

    function initRound()
        private
    {
         
        checkpoint();
        if (isLastRound()) goNext();
        updateMulti();
    }

    function finalizeable() 
        public
        view
        returns(bool)
    {
        uint256 finalizeTime = FINALIZE_WAIT_DURATION.add(round[curRoundId].slideEndTime);
        if (finalizeTime > block.timestamp) return false;  
        if (getEstKeyBlockNr(curRoundId) >= block.number) return false;  
        return curRoundId > 0;
    }

     
    function finalize()
        public
    {
        require(finalizeable(), "Not ready to draw results");
        uint256 _pRoundTicketSum = round[curRoundId].pBoughtTicketSum[msg.sender];
        uint256 _bountyTicketSum = _pRoundTicketSum * bountyPercent / 100;
        endRound(msg.sender, _bountyTicketSum);
        initRound();
        mintSlot(msg.sender, _bountyTicketSum, 0, 0);
    }

    function mintReward(
        address _lucker,
        uint256 _winNr,
        uint256 _slotId,
        uint256 _value,
        RewardType _rewardType)
        private
    {
         
        if ((_rewardType != RewardType.Bounty) && (_lucker != 0x0))
            rewardBalance[_lucker] = rewardBalance[_lucker].add(_value);
         
        rewardContract.mintReward(
            _lucker,
            curRoundId,
            _winNr,
            slot[_slotId].tNumberFrom,
            slot[_slotId].tNumberTo,
            _value,
            uint256(_rewardType)
        );
    }

    function mintSlot(
        address _buyer,
         
         
         
         
        uint256 _tAmount,
        uint256 _ethAmount,
        uint256 _salt
        )
        private
    {
        uint256 _tNumberFrom = curRTicketSum + 1;
        uint256 _tNumberTo = _tNumberFrom + _tAmount - 1;
        Slot memory _slot;
        _slot.buyer = _buyer;
        _slot.rId = curRoundId;
        _slot.tNumberFrom = _tNumberFrom;
        _slot.tNumberTo = _tNumberTo;
        _slot.ethAmount = _ethAmount;
        _slot.salt = _salt;
        slot.push(_slot);
        updateTicketSum(_buyer, _tAmount);
        round[curRoundId].slotSum = slot.length;
        pSlot[_buyer].push(slot.length - 1);
    }

    function jackpot()
        private
    {
         
        uint256 keyBlockNr = getKeyBlockNr(lastBlockNr); 
         
        uint256 seed = getSeed(keyBlockNr);
         
         
         
         

        uint256 jReward;
         
        address winner;
         
        while (jSlot + 1 < round[curRoundId].slotSum) {
             
            if (MAJOR_RATE > 2) MAJOR_RATE--;
            if (Helper.isJackpot(seed, MAJOR_RATE, MAJOR_MIN, slot[jSlot].ethAmount)){

                winner = slot[jSlot].buyer;
                jReward = majorPot / 100 * jRewardPercent;
                mintReward(winner, 0, jSlot, jReward, RewardType.Major);
                majorPot = majorPot - jReward;
                MAJOR_RATE = 1001;
            }
            seed = seed + jSlot;
             
            if (MINOR_RATE > 2) MINOR_RATE--;
            if (Helper.isJackpot(seed, MINOR_RATE, MINOR_MIN, slot[jSlot].ethAmount)){

                winner = slot[jSlot].buyer;
                jReward = minorPot / 100 * jRewardPercent;
                mintReward(winner, 0, jSlot, jReward, RewardType.Minor);
                minorPot = minorPot - jReward;
                MINOR_RATE = 501;
            }
            seed = seed + jSlot;
            jSlot++;
        }
    }

    function endRound(address _bountyHunter, uint256 _bountyTicketSum)
        private
    {
         
        uint256 _rId = curRoundId;
        uint256 keyBlockNr = getKeyBlockNr(round[_rId].keyBlockNr);
         
        uint256 _seed = getSeed(keyBlockNr) + curRSalt;
        uint256 onePercent = grandPot / 100;

         
         
        uint256[2] memory rGrandReward = [
            onePercent * sGrandRewardPercent, 
            onePercent * grandRewardPercent
        ];
        uint256[2] memory weightRange = [
            curRTicketSum, 
            GRAND_RATE > curRTicketSum ? GRAND_RATE : curRTicketSum
        ];
         
         

         
         

        for (uint256 i = 0; i < 2; i++){
            address _winner = 0x0;
            uint256 _winSlot = 0;
            uint256 _winNr = Helper.getRandom(_seed, weightRange[i]);
             
             
             
            if (_winNr <= curRTicketSum) {
                 
                grandPot -= rGrandReward[i];
                 
                if (i == 1) {
                    GRAND_RATE = GRAND_RATE * 2;
                     
                }
                _winSlot = getWinSlot(_winNr);
                _winner = slot[_winSlot].buyer;
                _seed = _seed + (_seed / 10);
            }
            mintReward(_winner, _winNr, _winSlot, rGrandReward[i], RewardType.Grand);
        }

        mintReward(_bountyHunter, 0, 0, _bountyTicketSum, RewardType.Bounty);
        rewardContract.resetCounter(curRoundId);
        GRAND_RATE = (GRAND_RATE / 100) * 99 + 1;
    }

    function buy(string _sSalt)
        public
        payable
    {
        buyFor(_sSalt, msg.sender);
    }

    function updateInvested(address _buyer, uint256 _ethAmount)
        private
    {
        round[curRoundId].investedSum += _ethAmount;
        round[curRoundId].pInvestedSum[_buyer] += _ethAmount;
        pInvestedSum[_buyer] += _ethAmount;
    }

    function updateTicketSum(address _buyer, uint256 _tAmount)
        private
    {
        round[curRoundId].ticketSum = round[curRoundId].ticketSum + _tAmount;
        round[curRoundId].pTicketSum[_buyer] = round[curRoundId].pTicketSum[_buyer] + _tAmount;
        curRTicketSum = curRTicketSum + _tAmount;
        pTicketSum[_buyer] = pTicketSum[_buyer] + _tAmount;
    }

    function updateEarlyIncome(address _buyer, uint256 _pWeight)
        private
    {
        round[curRoundId].rEarlyIncomeWeight = _pWeight.add(round[curRoundId].rEarlyIncomeWeight);
        round[curRoundId].pEarlyIncomeWeight[_buyer] = _pWeight.add(round[curRoundId].pEarlyIncomeWeight[_buyer]);
        round[curRoundId].pEarlyIncomeCredit[_buyer] = round[curRoundId].pEarlyIncomeCredit[_buyer].add(_pWeight.mul(round[curRoundId].ppw));
    }

    function getBonusTickets(address _buyer)
        private
        returns(uint256)
    {
        if (round[curRoundId].pBonusReceived[_buyer]) return 0;
        round[curRoundId].pBonusReceived[_buyer] = true;
        return round[curRoundId - 1].pBoughtTicketSum[_buyer] / TBONUS_RATE;
    }

    function updateMulti()
        private
    {
        if (lastBuyTime + multiDelayTime < block.timestamp) {
            lastEndTime = round[curRoundId].slideEndTime;
        }
        lastBuyTime = block.timestamp;
    }

    function buyFor(string _sSalt, address _sender) 
        public
        payable
        buyable()
    {
        uint256 _salt = Helper.stringToUint(_sSalt);
        uint256 _ethAmount = msg.value;
        uint256 _ticketSum = curRTicketSum;
        require(_ethAmount >= Helper.getTPrice(_ticketSum), "not enough to buy 1 ticket");

         
        updateInvested(_sender, _ethAmount);
        updateMulti();
         
        curRSalt = curRSalt + _salt;
        uint256 _tAmount = Helper.getTAmount(_ethAmount, _ticketSum);
        uint256 _tMul = getTMul();  
        uint256 _pMul = Helper.getEarlyIncomeMul(_ticketSum);
        uint256 _pWeight = _pMul.mul(_tAmount);
        uint256 _toAddTime = Helper.getAddedTime(_ticketSum, _tAmount);
        addTime(curRoundId, _toAddTime);
        _tAmount = _tAmount.mul(_tMul) / 100;
        round[curRoundId].pBoughtTicketSum[_sender] += _tAmount;
        mintSlot(_sender, _tAmount + getBonusTickets(_sender), _ethAmount, _salt);

         
         
         
        updateEarlyIncome(_sender, _pWeight);

         
         
        if (lastBlockNr != block.number) {
            jackpot();
            lastBlockNr = block.number;
        }

        distributeSlotBuy(_sender, curRoundId, _ethAmount);

        round[curRoundId].keyBlockNr = genEstKeyBlockNr(round[curRoundId].slideEndTime);
    }

    function distributeSlotBuy(address _sender, uint256 _rId, uint256 _ethAmount)
        private
    {
        uint256 onePercent = _ethAmount / 100;
        uint256 toF2mAmount = onePercent * toTokenPercent;  
        uint256 toRefAmount = onePercent * toRefPercent;  
        uint256 toBuyTokenAmount = onePercent * toBuyTokenPercent;  
        uint256 earlyIncomeAmount = onePercent * earlyIncomePercent;  
        uint256 taxAmount = toF2mAmount + toRefAmount + toBuyTokenAmount + earlyIncomeAmount;  
        uint256 taxedEthAmount = _ethAmount.sub(taxAmount);  
        addPot(taxedEthAmount);
        
         
        citizenContract.pushRefIncome.value(toRefAmount)(_sender);
         
        f2mContract.pushDividends.value(toF2mAmount)();
         
        f2mContract.buyFor.value(toBuyTokenAmount)(_sender);
         
        uint256 deltaPpw = (earlyIncomeAmount * ZOOM).div(round[_rId].rEarlyIncomeWeight);
        round[_rId].ppw = deltaPpw.add(round[_rId].ppw);
    }

    function claimEarlyIncomebyAddress(address _buyer)
        private
    {
        if (curRoundId == 0) return;
        claimEarlyIncomebyAddressRound(_buyer, curRoundId);
        uint256 _rId = curRoundId - 1;
        while ((_rId > lastWithdrawnRound[_buyer]) && (_rId + 20 > curRoundId)) {
            earlyIncomeScannedSum[_buyer] += claimEarlyIncomebyAddressRound(_buyer, _rId);
            _rId = _rId - 1;
        }
    }

    function claimEarlyIncomebyAddressRound(address _buyer, uint256 _rId)
        private
        returns(uint256)
    {
        uint256 _amount = getCurEarlyIncomeByAddressRound(_buyer, _rId);
        if (_amount == 0) return 0;
        round[_rId].pEarlyIncomeClaimed[_buyer] = _amount.add(round[_rId].pEarlyIncomeClaimed[_buyer]);
        rewardBalance[_buyer] = _amount.add(rewardBalance[_buyer]);
        return _amount;
    }

    function withdrawFor(address _sender)
        public
        withdrawRight()
        returns(uint256)
    {
        if (curRoundId == 0) return;
        claimEarlyIncomebyAddress(_sender);
        lastWithdrawnRound[_sender] = curRoundId - 1;
        uint256 _amount = rewardBalance[_sender];
        rewardBalance[_sender] = 0;
        bankContract.pushToBank.value(_amount)(_sender);
        return _amount;
    }
    
    function addTime(uint256 _rId, uint256 _toAddTime)
        private
    {
        round[_rId].slideEndTime = Helper.getNewEndTime(_toAddTime, round[_rId].slideEndTime, round[_rId].fixedEndTime);
    }

     
    function addPot(uint256 _amount)
        private
    {
        uint256 onePercent = _amount / 100;
        uint256 toMinor = onePercent * minorPercent;
        uint256 toMajor = onePercent * majorPercent;
        uint256 toGrand = _amount - toMinor - toMajor;

        minorPot = minorPot + toMinor;
        majorPot = majorPot + toMajor;
        grandPot = grandPot + toGrand;
    }


     
     
     

    function isWinSlot(uint256 _slotId, uint256 _keyNumber)
        public
        view
        returns(bool)
    {
        return (slot[_slotId - 1].tNumberTo < _keyNumber) && (slot[_slotId].tNumberTo >= _keyNumber);
    }

    function getWeightRange()
        public
        view
        returns(uint256)
    {
        return Helper.getWeightRange(initGrandPot);
    }

    function getWinSlot(uint256 _keyNumber)
        public
        view
        returns(uint256)
    {
         
        uint256 _to = slot.length - 1;
        uint256 _from = round[curRoundId-1].slotSum + 1;  
        uint256 _pivot;
         
        uint256 _pivotTo;
         
        while (_from <= _to) {
            _pivot = (_from + _to) / 2;
            _pivotTo = slot[_pivot].tNumberTo;
            if (isWinSlot(_pivot, _keyNumber)) return _pivot;
            if (_pivotTo < _keyNumber) {  
                _from = _pivot + 1;
            } else {  
                _to = _pivot - 1;
            }
        }
        return _pivot;  
    }

     
    function genEstKeyBlockNr(uint256 _endTime) 
        public
        view
        returns(uint256)
    {
        if (block.timestamp >= _endTime) return block.number + 8; 
        uint256 timeDist = _endTime - block.timestamp;
        uint256 estBlockDist = timeDist / BLOCK_TIME;
        return block.number + estBlockDist + 8;
    }

     
    function getSeed(uint256 _keyBlockNr)
        public
        view
        returns (uint256)
    {
         
        if (block.number <= _keyBlockNr) return block.number;
        return uint256(blockhash(_keyBlockNr));
    }

     
    function getRewardBalance(address _buyer)
        public
        view
        returns(uint256)
    {
        return rewardBalance[_buyer];
    } 

     
    function getSlideEndTime(uint256 _rId)
        public
        view
        returns(uint256)
    {
        return(round[_rId].slideEndTime);
    }

    function getFixedEndTime(uint256 _rId)
        public
        view
        returns(uint256)
    {
        return(round[_rId].fixedEndTime);
    }

    function getTotalPot()
        public
        view
        returns(uint256)
    {
        return grandPot + majorPot + minorPot;
    }

     
    function getEarlyIncomeByAddress(address _buyer)
        public
        view
        returns(uint256)
    {
        uint256 _sum = earlyIncomeScannedSum[_buyer];
        uint256 _fromRound = lastWithdrawnRound[_buyer] + 1;  
        if (_fromRound + 100 < curRoundId) _fromRound = curRoundId - 100;
        uint256 _rId = _fromRound;
        while (_rId <= curRoundId) {
            _sum = _sum + getEarlyIncomeByAddressRound(_buyer, _rId);
            _rId++;
        }
        return _sum;
    }

     
    function getEarlyIncomeByAddressRound(address _buyer, uint256 _rId)
        public
        view
        returns(uint256)
    {
        uint256 _pWeight = round[_rId].pEarlyIncomeWeight[_buyer];
        uint256 _ppw = round[_rId].ppw;
        uint256 _rCredit = round[_rId].pEarlyIncomeCredit[_buyer];
        uint256 _rEarlyIncome = ((_ppw.mul(_pWeight)).sub(_rCredit)).div(ZOOM);
        return _rEarlyIncome;
    }

    function getCurEarlyIncomeByAddress(address _buyer)
        public
        view
        returns(uint256)
    {
        uint256 _sum = 0;
        uint256 _fromRound = lastWithdrawnRound[_buyer] + 1;  
        if (_fromRound + 100 < curRoundId) _fromRound = curRoundId - 100;
        uint256 _rId = _fromRound;
        while (_rId <= curRoundId) {
            _sum = _sum.add(getCurEarlyIncomeByAddressRound(_buyer, _rId));
            _rId++;
        }
        return _sum;
    }

    function getCurEarlyIncomeByAddressRound(address _buyer, uint256 _rId)
        public
        view
        returns(uint256)
    {
        uint256 _rEarlyIncome = getEarlyIncomeByAddressRound(_buyer, _rId);
        return _rEarlyIncome.sub(round[_rId].pEarlyIncomeClaimed[_buyer]);
    }

     

    function getEstKeyBlockNr(uint256 _rId)
        public
        view
        returns(uint256)
    {
        return round[_rId].keyBlockNr;
    }

    function getKeyBlockNr(uint256 _estKeyBlockNr)
        public
        view
        returns(uint256)
    {
        require(block.number > _estKeyBlockNr, "blockHash not avaiable");
        uint256 jump = (block.number - _estKeyBlockNr) / MAX_BLOCK_DISTANCE * MAX_BLOCK_DISTANCE;
        return _estKeyBlockNr + jump;
    }

     
    function getCurRoundId()
        public
        view
        returns(uint256)
    {
        return curRoundId;
    }

    function getTPrice()
        public
        view
        returns(uint256)
    {
        return Helper.getTPrice(curRTicketSum);
    }

    function getTMul()
        public
        view
        returns(uint256)
    {
        return Helper.getTMul(
                initGrandPot, 
                grandPot, 
                lastBuyTime + multiDelayTime < block.timestamp ? round[curRoundId].slideEndTime : lastEndTime, 
                round[curRoundId].fixedEndTime
            );
    }

    function getPMul()
        public
        view
        returns(uint256)
    {
        return Helper.getEarlyIncomeMul(curRTicketSum);
    }

    function getPTicketSumByRound(uint256 _rId, address _buyer)
        public
        view
        returns(uint256)
    {
        return round[_rId].pTicketSum[_buyer];
    }

    function getTicketSumToRound(uint256 _rId)
        public
        view
        returns(uint256)
    {
        return round[_rId].ticketSum;
    }

    function getPInvestedSumByRound(uint256 _rId, address _buyer)
        public
        view
        returns(uint256)
    {
        return round[_rId].pInvestedSum[_buyer];
    }

    function getInvestedSumToRound(uint256 _rId)
        public
        view
        returns(uint256)
    {
        return round[_rId].investedSum;
    }

    function getPSlotLength(address _sender)
        public
        view
        returns(uint256)
    {
        return pSlot[_sender].length;
    }

    function getSlotLength()
        public
        view
        returns(uint256)
    {
        return slot.length;
    }

    function getSlotId(address _sender, uint256 i)
        public
        view
        returns(uint256)
    {
        return pSlot[_sender][i];
    }

    function getSlotInfo(uint256 _slotId)
        public
        view
        returns(address, uint256[4], string)
    {
        Slot memory _slot = slot[_slotId];
        return (_slot.buyer,[_slot.rId, _slot.tNumberFrom, _slot.tNumberTo, _slot.ethAmount], Helper.uintToString(_slot.salt));
    }

    function cashoutable(address _address) 
        public
        view
        returns(bool)
    {
         
        if (round[curRoundId].pTicketSum[_address] >= CASHOUT_REQ) return true;
        if (round[curRoundId].startTime > block.timestamp) {
             
            uint256 _lastRoundTickets = getPTicketSumByRound(curRoundId - 1, _address);
            if (_lastRoundTickets >= CASHOUT_REQ) return true;
        }
        return false;
    }

     
    function setLastRound(uint256 _lastRoundId) 
        public
        onlyDevTeam()
    {
        require(_lastRoundId >= 8 && _lastRoundId > curRoundId, "too early to end");
        require(lastRoundId == 88888888, "already set");
        lastRoundId = _lastRoundId;

    }

    function sBountyClaim(address _sBountyHunter)
        public
        notStarted()
        returns(uint256)
    {
        require(msg.sender == address(rewardContract), "only Reward contract can manage sBountys");
        uint256 _lastRoundTickets = round[curRoundId - 1].pBoughtTicketSum[_sBountyHunter];
        uint256 _sBountyTickets = _lastRoundTickets * sBountyPercent / 100;
        mintSlot(_sBountyHunter, _sBountyTickets, 0, 0);
        return _sBountyTickets;
    }

     

     
     
     
     
     
     
     

     
     
     
     
     
     

     
     
     
     
     
     
}

interface F2mInterface {
    function joinNetwork(address[6] _contract) public;
     
     
    function activeBuy() public;
     
     
    function pushDividends() public payable;
     
    function buyFor(address _buyer) public payable;
    function sell(uint256 _tokenAmount) public;
    function exit() public;
    function devTeamWithdraw() public returns(uint256);
    function withdrawFor(address sender) public returns(uint256);
    function transfer(address _to, uint256 _tokenAmount) public returns(bool);
     
    function setAutoBuy() public;
     
    function ethBalance(address _address) public view returns(uint256);
    function myBalance() public view returns(uint256);
    function myEthBalance() public view returns(uint256);

    function swapToken() public;
    function setNewToken(address _newTokenAddress) public;
}

interface CitizenInterface {
 
    function joinNetwork(address[6] _contract) public;
     
    function devTeamWithdraw() public;

     
    function updateUsername(string _sNewUsername) public;
     
    function pushRefIncome(address _sender) public payable;
    function withdrawFor(address _sender) public payable returns(uint256);
    function devTeamReinvest() public returns(uint256);

     
    function getRefWallet(address _address) public view returns(uint256);
}

interface DevTeamInterface {
    function setF2mAddress(address _address) public;
    function setLotteryAddress(address _address) public;
    function setCitizenAddress(address _address) public;
    function setBankAddress(address _address) public;
    function setRewardAddress(address _address) public;
    function setWhitelistAddress(address _address) public;

    function setupNetwork() public;
}

interface BankInterface {
    function joinNetwork(address[6] _contract) public;
    function pushToBank(address _player) public payable;
}

interface RewardInterface {

    function mintReward(
        address _lucker,
        uint256 curRoundId,
        uint256 _winNr,
        uint256 _tNumberFrom,
        uint256 _tNumberTo,
        uint256 _value,
        uint256 _rewardType)
        public;
        
    function joinNetwork(address[6] _contract) public;
    function pushBounty(uint256 _curRoundId) public payable;
    function resetCounter(uint256 _curRoundId) public;
}

 
library SafeMath {
    int256 constant private INT256_MIN = -2**255;

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

     
    function mul(int256 a, int256 b) internal pure returns (int256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == INT256_MIN));  

        int256 c = a * b;
        require(c / a == b);

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        require(b > 0);
        uint256 c = a / b;
         

        return c;
    }

     
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0);  
        require(!(b == -1 && a == INT256_MIN));  

        int256 c = a / b;

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

     
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));

        return c;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

     
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}
 

pragma solidity 0.4.24;

 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
contract EtherDerby {
    using SafeMath for *;
    using CalcCarrots for uint256;

     
    string constant public name = "EtherDerby";
    uint256 constant private ROUNDMAX = 4 hours;
    uint256 constant private MULTIPLIER = 2**64;
    uint256 constant private DECIMALS = 18;
    uint256 constant public REGISTERFEE = 20 finney;

    address constant private DEVADDR = 0xC17A40cB38598520bd7C0D5BFF97D441A810a008;

     
    uint8 constant private H1 = 1;
    uint8 constant private H2 = 2;
    uint8 constant private H3 = 3;
    uint8 constant private H4 = 4;

     
     
     
     
     

    struct Round {
        uint8 winner;  
        mapping (uint8 => uint256) eth;  
        mapping (uint8 => uint256) carrots;  
    }

    struct Player {
        address addr;  
        bytes32 name;  
        uint256 totalWinnings;  
        uint256 totalReferrals;  
        int256  dividendPayouts;  

        mapping (uint256 => mapping (uint8 => uint256)) eth;  
        mapping (uint256 => mapping (uint8 => uint256)) carrots;  
        mapping (uint256 => mapping (uint8 => uint256)) referrals;  

        mapping (uint8 => uint256) totalEth;  
        mapping (uint8 => uint256) totalCarrots;  

        uint256 totalWithdrawn;  
        uint256 totalReinvested;  

        uint256 roundLastManaged;  
        uint256 roundLastReferred;  
        address lastRef;  
    }

    struct Horse {
        bytes32 name;
        uint256 totalEth;
        uint256 totalCarrots;
        uint256 mostCarrotsOwned;
        address owner;
    }

    uint256 rID_ = 0;  
    mapping (uint256 => Round) public rounds_;  
    uint256 roundEnds_;  
    mapping (address => Player) public players_;  
    mapping (uint8 => Horse) horses_;  
    uint256 private earningsPerCarrot_;  

    mapping (bytes32 => address) registeredNames_;

     
     
     
     
     

     
    event OnCarrotsPurchased
    (
        address indexed playerAddress,
        bytes32 playerName,
        uint256 roundId,
        uint8[2] horse,
        bytes32 indexed horseName,
        uint256[6] data,
        uint256 roundEnds,
        uint256 timestamp
    );

     
    event OnEthWithdrawn
    (
        address indexed playerAddress,
        uint256 eth
    );

     
    event OnHorseNamed
    (
      address playerAddress,
      bytes32 playerName,
      uint8 horse,
      bytes32 horseName,
      uint256 mostCarrotsOwned,
      uint256 timestamp
    );

     
    event OnNameRegistered
    (
        address playerAddress,
        bytes32 playerName,
        uint256 ethDonated,
        uint256 timestamp
    );

     
    event OnTransactionFail
    (
        address indexed playerAddress,
        bytes32 reason
    );

    constructor()
      public
    {
         
         
        roundEnds_ = block.timestamp - 1 hours;

         
        horses_[H1].name = "horse1";
        horses_[H2].name = "horse2";
        horses_[H3].name = "horse3";
        horses_[H4].name = "horse4";
    }

     
     
     
     
     

     
    modifier isValidHorse(uint8 _horse) {
        require(_horse == H1 || _horse == H2 || _horse == H3 || _horse == H4, "unknown horse selected");
        _;
    }

     
    modifier isHuman() {
        address addr = msg.sender;
        uint256 codeLength;

        assembly {codeLength := extcodesize(addr)}
        require(codeLength == 0, "Humans only ;)");
        require(msg.sender == tx.origin, "Humans only ;)");
        _;
    }

     
    modifier isWithinLimits(uint256 _eth) {
        require(_eth >= 1000000000, "Not enough eth!");
        require(_eth <= 100000000000000000000000, "Go away whale!");
        _;
    }


     
     
     
     
     

     
    function registerName(string _nameStr)
        public
        payable
        isHuman()
    {
        require(msg.value >= REGISTERFEE, "You must pay the partner fee of 20 finney");

        bytes32 nameToRegister = NameValidator.validate(_nameStr);

        require(registeredNames_[nameToRegister] == 0, "Name already in use");

        registeredNames_[nameToRegister] = msg.sender;
        players_[msg.sender].name = nameToRegister;

         
        players_[DEVADDR].totalReferrals = msg.value.add(players_[DEVADDR].totalReferrals);

        emit OnNameRegistered(msg.sender, nameToRegister, msg.value, block.timestamp);
    }

     
    function buyCarrots(uint8 _horse, uint256 _round, bytes32 _referrerName)
        public
        payable
        isHuman()
        isWithinLimits(msg.value)
        isValidHorse(_horse)
    {
        if (isInvalidRound(_round)) {
            emit OnTransactionFail(msg.sender, "Invalid round");
            msg.sender.transfer(msg.value);
            return;
        }
        buyCarrotsInternal(_horse, msg.value, _referrerName);
    }

     
    function reinvestInCarrots(uint8 _horse, uint256 _round, uint256 _value, bytes32 _referrerName)
        public
        isHuman()
        isWithinLimits(_value)
        isValidHorse(_horse)
    {
        if (isInvalidRound(_round)) {
            emit OnTransactionFail(msg.sender, "Invalid round");
            return;
        }
        if (calcPlayerEarnings() < _value) {
             
            emit OnTransactionFail(msg.sender, "Insufficient funds");
            return;
        }
        players_[msg.sender].totalReinvested = _value.add(players_[msg.sender].totalReinvested);

        buyCarrotsInternal(_horse, _value, _referrerName);
    }

     
    function nameHorse(uint8 _horse, string _nameStr, bytes32 _referrerName)
      public
      payable
      isHuman()
      isValidHorse(_horse)
    {
        if ((rounds_[getCurrentRound()].eth[_horse])
            .carrotsReceived(msg.value)
            .add(players_[msg.sender].totalCarrots[_horse]) < 
                horses_[_horse].mostCarrotsOwned) {
            emit OnTransactionFail(msg.sender, "Insufficient funds");
            if (msg.value > 0) {
                msg.sender.transfer(msg.value);
            }
            return;
        }
        if (msg.value > 0) {
            buyCarrotsInternal(_horse, msg.value, _referrerName);    
        }
        horses_[_horse].name = NameValidator.validate(_nameStr);
        if (horses_[_horse].owner != msg.sender) {
            horses_[_horse].owner = msg.sender;
        }
        emit OnHorseNamed(
            msg.sender,
            players_[msg.sender].name,
            _horse,
            horses_[_horse].name,
            horses_[_horse].mostCarrotsOwned,
            block.timestamp
        );
    }

     
    function withdrawEarnings()
        public
        isHuman()
    {
        managePlayer();
        manageReferrer(msg.sender);

        uint256 earnings = calcPlayerEarnings();
        if (earnings > 0) {
            players_[msg.sender].totalWithdrawn = earnings.add(players_[msg.sender].totalWithdrawn);
            msg.sender.transfer(earnings);
        }
        emit OnEthWithdrawn(msg.sender, earnings);
    }

     
    function()
        public
        payable
    {
        players_[DEVADDR].totalReferrals = msg.value.add(players_[DEVADDR].totalReferrals);
    }

     
     
     
     
     

     
    function buyCarrotsInternal(uint8 _horse, uint256 _value, bytes32 _referrerName)
        private
    {
         
        manageRound();

         
        managePlayer();

        address referrer = getReferrer(_referrerName);
         
        manageReferrer(referrer);
        if (referrer != DEVADDR) {
             
            manageReferrer(DEVADDR);
        }

        uint256 carrots = (rounds_[rID_].eth[_horse]).carrotsReceived(_value);

         
         
         

        players_[msg.sender].eth[rID_][_horse] = 
            _value.add(players_[msg.sender].eth[rID_][_horse]);
        players_[msg.sender].carrots[rID_][_horse] = 
            carrots.add(players_[msg.sender].carrots[rID_][_horse]);
        players_[msg.sender].totalEth[_horse] =
            _value.add(players_[msg.sender].totalEth[_horse]);
        players_[msg.sender].totalCarrots[_horse] =
            carrots.add(players_[msg.sender].totalCarrots[_horse]);

         
        players_[msg.sender].dividendPayouts += SafeConversions.SafeSigned(earningsPerCarrot_.mul(carrots));

         
         
         

        players_[referrer].referrals[rID_][_horse] = 
            ninePercent(_value).add(players_[referrer].referrals[rID_][_horse]);
         
         
        players_[DEVADDR].referrals[rID_][_horse] =
            _value.div(100).add(players_[DEVADDR].referrals[rID_][_horse]);

         
        if (players_[msg.sender].totalCarrots[_horse] > horses_[_horse].mostCarrotsOwned) {
          horses_[_horse].mostCarrotsOwned = players_[msg.sender].totalCarrots[_horse];
        }

         
         
         

        rounds_[rID_].eth[_horse] = _value.add(rounds_[rID_].eth[_horse]);
        rounds_[rID_].carrots[_horse] = carrots.add(rounds_[rID_].carrots[_horse]);

         
        if (rounds_[rID_].winner != _horse &&
            rounds_[rID_].carrots[_horse] > rounds_[rID_].carrots[rounds_[rID_].winner]) {
            rounds_[rID_].winner = _horse;
        }

         
         
         

        horses_[_horse].totalCarrots = carrots.add(horses_[_horse].totalCarrots);
        horses_[_horse].totalEth = _value.add(horses_[_horse].totalEth);

        emit OnCarrotsPurchased(
            msg.sender,
            players_[msg.sender].name,
            rID_,
            [
                _horse,
                rounds_[rID_].winner
            ],
            horses_[_horse].name,
            [
                _value,
                carrots,
                rounds_[rID_].eth[_horse],
                rounds_[rID_].carrots[_horse],
                players_[msg.sender].eth[rID_][_horse],
                players_[msg.sender].carrots[rID_][_horse]
            ],
            roundEnds_,
            block.timestamp
        );
    }

     
    function manageRound()
      private
    {
        if (!isRoundOver()) {
            return;
        }
         
        uint256 earningsPerCarrotThisRound = fromEthToDivies(calcRoundLosingHorsesEth(rID_));

        if (earningsPerCarrotThisRound > 0) {
            earningsPerCarrot_ = earningsPerCarrot_.add(earningsPerCarrotThisRound);  
        }

        rID_++;
        roundEnds_ = block.timestamp + ROUNDMAX;
    }

     
    function managePlayer()
        private
    {
        uint256 unrecordedWinnings = calcUnrecordedWinnings();
        if (unrecordedWinnings > 0) {
            players_[msg.sender].totalWinnings = unrecordedWinnings.add(players_[msg.sender].totalWinnings);
        }
         
         
         
        if (players_[msg.sender].roundLastManaged == rID_ && isRoundOver()) {
            players_[msg.sender].roundLastManaged = rID_.add(1);
        }
        else if (players_[msg.sender].roundLastManaged < rID_) {
            players_[msg.sender].roundLastManaged = rID_;
        }
    }

     
    function manageReferrer(address _referrer)
        private
    {
        uint256 unrecordedRefferals = calcUnrecordedRefferals(_referrer);
        if (unrecordedRefferals > 0) {
            players_[_referrer].totalReferrals =
                unrecordedRefferals.add(players_[_referrer].totalReferrals);
        }

        if (players_[_referrer].roundLastReferred == rID_ && isRoundOver()) {
            players_[_referrer].roundLastReferred = rID_.add(1);
        }
        else if (players_[_referrer].roundLastReferred < rID_) {
            players_[_referrer].roundLastReferred = rID_;
        }
    }

     
    function calcTotalCarrots()
        private
        view
        returns (uint256)
    {
        return horses_[H1].totalCarrots
            .add(horses_[H2].totalCarrots)
            .add(horses_[H3].totalCarrots)
            .add(horses_[H4].totalCarrots);
    }

     
    function calcPlayerTotalCarrots()
        private
        view
        returns (uint256)
    {
        return players_[msg.sender].totalCarrots[H1]
            .add(players_[msg.sender].totalCarrots[H2])
            .add(players_[msg.sender].totalCarrots[H3])
            .add(players_[msg.sender].totalCarrots[H4]);
    }

     
    function calcPlayerTotalEth()
        private
        view
        returns (uint256)
    {
        return players_[msg.sender].totalEth[H1]
            .add(players_[msg.sender].totalEth[H2])
            .add(players_[msg.sender].totalEth[H3])
            .add(players_[msg.sender].totalEth[H4]);
    }

     
    function calcPlayerEarnings()
        private
        view
        returns (uint256)
    {
        return calcPlayerWinnings()
            .add(calcPlayerDividends())
            .add(calcPlayerReferrals())
            .sub(players_[msg.sender].totalWithdrawn)
            .sub(players_[msg.sender].totalReinvested);
    }

     
    function calcPlayerWinnings()
        private
        view
        returns (uint256)
    {
        return players_[msg.sender].totalWinnings.add(calcUnrecordedWinnings());
    }

     
    function calcPlayerDividends()
      private
      view
      returns (uint256)
    {
        uint256 unrecordedDividends = calcUnrecordedDividends();
        uint256 carrotBalance = calcPlayerTotalCarrots();
        int256 totalDividends = SafeConversions.SafeSigned(carrotBalance.mul(earningsPerCarrot_).add(unrecordedDividends));
        return SafeConversions.SafeUnsigned(totalDividends - players_[msg.sender].dividendPayouts).div(MULTIPLIER);
    }

     
    function calcPlayerReferrals()
        private
        view
        returns (uint256)
    {
        return players_[msg.sender].totalReferrals.add(calcUnrecordedRefferals(msg.sender));
    }

     
    function calcUnrecordedWinnings()
        private
        view
        returns (uint256)
    {
        uint256 round = players_[msg.sender].roundLastManaged;
        if ((round == 0) || (round > rID_) || (round == rID_ && !isRoundOver())) {
             
            return 0;
        }
         
         
         
         
        return players_[msg.sender].eth[round][rounds_[round].winner]
            .add((players_[msg.sender].carrots[round][rounds_[round].winner]
            .mul(eightyPercent(calcRoundLosingHorsesEth(round))))
            .div(rounds_[round].carrots[rounds_[round].winner]));
    }

     
    function calcUnrecordedDividends()
        private
        view
        returns (uint256)
    {
        if (!isRoundOver()) {
             
            return 0;
        }
         
         
        return fromEthToDivies(calcRoundLosingHorsesEth(rID_)).mul(calcPlayerTotalCarrots());
    }

     
    function calcUnrecordedRefferals(address _player)
        private
        view
        returns (uint256 ret)
    {
        uint256 round = players_[_player].roundLastReferred;
        if (!((round == 0) || (round > rID_) || (round == rID_ && !isRoundOver()))) {
            for (uint8 i = H1; i <= H4; i++) {
                if (rounds_[round].winner != i) {
                    ret = ret.add(players_[_player].referrals[round][i]);
                }
            }
        }
    }

     
    function calcRoundLosingHorsesEth(uint256 _round)
        private
        view
        returns (uint256 ret)
    {
        for (uint8 i = H1; i <= H4; i++) {
            if (rounds_[_round].winner != i) {
                ret = ret.add(rounds_[_round].eth[i]);
            }
        }
    }

     
    function fromEthToDivies(uint256 _value)
        private
        view
        returns (uint256)
    {
         
        uint256 totalCarrots = calcTotalCarrots();
        if (totalCarrots == 0) {
            return 0;
        }
         
         
         
        return _value.mul(MULTIPLIER).div(10).div(totalCarrots);
    }

     
    function getReferrer(bytes32 _referrerName)
        private
        returns (address)
    {
        address referrer;
         
        if (_referrerName != "" && registeredNames_[_referrerName] != 0 && _referrerName != players_[msg.sender].name) {
            referrer = registeredNames_[_referrerName];
        } else if (players_[msg.sender].lastRef != 0) {
            referrer = players_[msg.sender].lastRef;
        } else {
             
            referrer = DEVADDR;
        }
        if (players_[msg.sender].lastRef != referrer) {
             
             
            players_[msg.sender].lastRef = referrer;
        }
        return referrer;
    }

     
    function calculateCurrentPrice(uint8 _horse, uint256 _carrots)
        private
        view
        returns(uint256)
    {
        uint256 currTotal = 0;
        if (!isRoundOver()) {
             
            currTotal = rounds_[rID_].carrots[_horse];
        }
        return currTotal.add(_carrots).ethReceived(_carrots);
    }

     
    function isInvalidRound(uint256 _round)
        private
        view
        returns(bool)
    {
         
        return _round != 0 && _round != getCurrentRound();
    }

     
    function getCurrentRound()
        private
        view
        returns(uint256)
    {
        if (isRoundOver()) {
            return (rID_ + 1);
        }
        return rID_;
    }

     
    function isRoundOver()
        private
        view
        returns (bool)
    {
        return block.timestamp >= roundEnds_;
    }

     
    function eightyPercent(uint256 num_)
        private
        pure
        returns (uint256)
    {
         
        return num_.sub(ninePercent(num_)).sub(num_.div(100)).sub(num_.div(10));
    }

     
    function ninePercent(uint256 num_)
        private
        pure
        returns (uint256)
    {
        return num_.mul(9).div(100);
    }

     
     
     
     
     

     
    function getRoundStats()
        public
        view
        returns(uint256, uint256, uint8, uint256[4], uint256[4], uint256[4], uint256[4], bytes32[4])
    {
        return
        (
            rID_,
            roundEnds_,
            rounds_[rID_].winner,
            [
                rounds_[rID_].eth[H1],
                rounds_[rID_].eth[H2],
                rounds_[rID_].eth[H3],
                rounds_[rID_].eth[H4]
            ],
            [
                rounds_[rID_].carrots[H1],
                rounds_[rID_].carrots[H2],
                rounds_[rID_].carrots[H3],
                rounds_[rID_].carrots[H4]
            ],
            [
                players_[msg.sender].eth[rID_][H1],
                players_[msg.sender].eth[rID_][H2],
                players_[msg.sender].eth[rID_][H3],
                players_[msg.sender].eth[rID_][H4]
            ],
            [
                players_[msg.sender].carrots[rID_][H1],
                players_[msg.sender].carrots[rID_][H2],
                players_[msg.sender].carrots[rID_][H3],
                players_[msg.sender].carrots[rID_][H4]
            ],
            [
                horses_[H1].name,
                horses_[H2].name,
                horses_[H3].name,
                horses_[H4].name
            ]
        );
    }

     
    function getPastRoundStats(uint256 _round) 
        public
        view
        returns(uint8, uint256[4], uint256[4], uint256[4], uint256[4])
    {
        if ((_round == 0) || (_round > rID_) || (_round == rID_ && !isRoundOver())) {
            return;
        }
        return
        (
            rounds_[rID_].winner,
            [
                rounds_[_round].eth[H1],
                rounds_[_round].eth[H2],
                rounds_[_round].eth[H3],
                rounds_[_round].eth[H4]
            ],
            [
                rounds_[_round].carrots[H1],
                rounds_[_round].carrots[H2],
                rounds_[_round].carrots[H3],
                rounds_[_round].carrots[H4]
            ],
            [
                players_[msg.sender].eth[_round][H1],
                players_[msg.sender].eth[_round][H2],
                players_[msg.sender].eth[_round][H3],
                players_[msg.sender].eth[_round][H4]
            ],
            [
                players_[msg.sender].carrots[_round][H1],
                players_[msg.sender].carrots[_round][H2],
                players_[msg.sender].carrots[_round][H3],
                players_[msg.sender].carrots[_round][H4]
            ]
        );
    }

     
    function getPlayerStats()
        public 
        view
        returns(uint256, uint256, uint256, uint256, uint256)
    {
        return
        (
            calcPlayerWinnings(),
            calcPlayerDividends(),
            calcPlayerReferrals(),
            players_[msg.sender].totalReinvested,
            players_[msg.sender].totalWithdrawn
        );
    }

     
    function getPlayerName()
      public
      view
      returns(bytes32)
    {
        return players_[msg.sender].name;
    }

     
    function isNameAvailable(bytes32 _name)
      public
      view
      returns(bool)
    {
        return registeredNames_[_name] == 0;
    }

     
    function getStats()
        public
        view
        returns(uint256[4], uint256[4], uint256[4], uint256[4], bytes32[4])
    {
        return
        (
            [
                horses_[H1].totalEth,
                horses_[H2].totalEth,
                horses_[H3].totalEth,
                horses_[H4].totalEth
            ],
            [
                horses_[H1].totalCarrots,
                horses_[H2].totalCarrots,
                horses_[H3].totalCarrots,
                horses_[H4].totalCarrots
            ],
            [
                players_[msg.sender].totalEth[H1],
                players_[msg.sender].totalEth[H2],
                players_[msg.sender].totalEth[H3],
                players_[msg.sender].totalEth[H4]
            ],
            [
                players_[msg.sender].totalCarrots[H1],
                players_[msg.sender].totalCarrots[H2],
                players_[msg.sender].totalCarrots[H3],
                players_[msg.sender].totalCarrots[H4]
            ],
            [
                horses_[H1].name,
                horses_[H2].name,
                horses_[H3].name,
                horses_[H4].name
            ]
        );
    }

     
    function getPastRounds(uint256 roundStart)
        public
        view
        returns(
            uint256[50] roundNums,
            uint8[50] winners,
            uint256[50] horse1Carrots,
            uint256[50] horse2Carrots,
            uint256[50] horse3Carrots,
            uint256[50] horse4Carrots,
            uint256[50] horse1PlayerCarrots,
            uint256[50] horse2PlayerCarrots,
            uint256[50] horse3PlayerCarrots,
            uint256[50] horse4PlayerCarrots,
            uint256[50] horseEth,
            uint256[50] playerEth
        )
    {
        uint256 index = 0;
        uint256 round = rID_;
        if (roundStart != 0 && roundStart <= rID_) {
            round = roundStart;
        }
        while (index < 50 && round > 0) {
            if (round == rID_ && !isRoundOver()) {
                round--;
                continue;
            }
            roundNums[index] = round;
            winners[index] = rounds_[round].winner;
            horse1Carrots[index] = rounds_[round].carrots[H1];
            horse2Carrots[index] = rounds_[round].carrots[H2];
            horse3Carrots[index] = rounds_[round].carrots[H3];
            horse4Carrots[index] = rounds_[round].carrots[H4];
            horse1PlayerCarrots[index] = players_[msg.sender].carrots[round][H1];
            horse2PlayerCarrots[index] = players_[msg.sender].carrots[round][H2];
            horse3PlayerCarrots[index] = players_[msg.sender].carrots[round][H3];
            horse4PlayerCarrots[index] = players_[msg.sender].carrots[round][H4];
            horseEth[index] = rounds_[round].eth[H1]
                .add(rounds_[round].eth[H2])
                .add(rounds_[round].eth[H3])
                .add(rounds_[round].eth[H4]);
            playerEth[index] = players_[msg.sender].eth[round][H1]
                .add(players_[msg.sender].eth[round][H2])
                .add(players_[msg.sender].eth[round][H3])
                .add(players_[msg.sender].eth[round][H4]);
            index++;
            round--;
        }
    }

     
    function getPriceOfXCarrots(uint8 _horse, uint256 _carrots)
        public
        view
        isValidHorse(_horse)
        returns(uint256)
    {
        return calculateCurrentPrice(_horse, _carrots.mul(1000000000000000000));
    }

     
    function getPriceToName(uint8 _horse)
        public
        view
        isValidHorse(_horse)
        returns(
            uint256 carrotsRequired,
            uint256 ethRequired,
            uint256 currentMax,
            address owner,
            bytes32 ownerName
        )
    {
        if (players_[msg.sender].totalCarrots[_horse] < horses_[_horse].mostCarrotsOwned) {
             
             
            carrotsRequired = horses_[_horse].mostCarrotsOwned.sub(players_[msg.sender].totalCarrots[_horse]).add(10**DECIMALS);
            ethRequired = calculateCurrentPrice(_horse, carrotsRequired);
        }
        currentMax = horses_[_horse].mostCarrotsOwned;
        owner = horses_[_horse].owner;
        ownerName = players_[horses_[_horse].owner].name;
    }
}


 
 
 
 
 
library CalcCarrots {
    using SafeMath for *;

     
    function carrotsReceived(uint256 _currEth, uint256 _newEth)
        internal
        pure
        returns (uint256)
    {
        return carrots((_currEth).add(_newEth)).sub(carrots(_currEth));
    }

     
    function ethReceived(uint256 _currCarrots, uint256 _sellCarrots)
        internal
        pure
        returns (uint256)
    {
        return eth(_currCarrots).sub(eth(_currCarrots.sub(_sellCarrots)));
    }

     
    function carrots(uint256 _eth)
        internal
        pure
        returns (uint256)
    {
        return ((((_eth).mul(62831853072000000000000000000000000000000000000)
            .add(9996858654086510028837239824000000000000000000000000000000000000)).sqrt())
            .sub(99984292036732000000000000000000)) / (31415926536);
    }

     
    function eth(uint256 _carrots)
        internal
        pure
        returns (uint256)
    {
        return ((15707963268).mul(_carrots.mul(_carrots)).add(((199968584073464)
            .mul(_carrots.mul(1000000000000000000))) / (2))) / (1000000000000000000000000000000000000);
    }
}


 
 
 
 
 

 
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
}

library SafeConversions {
    function SafeSigned(uint256 a) internal pure returns (int256) {
        int256 b = int256(a);
         
        assert(b >= 0);
        return b;
    }

    function SafeUnsigned(int256 a) internal pure returns (uint256) {
         
        assert(a >= 0);
        return uint256(a);
    }
}

library NameValidator {
     
    function validate(string _input)
        internal
        pure
        returns(bytes32)
    {
        bytes memory temp = bytes(_input);
        uint256 length = temp.length;
        
         
        require (length <= 15 && length > 0, "name must be between 1 and 15 characters");
         
        if (temp[0] == 0x30) {
            require(temp[1] != 0x78, "name cannot start with 0x");
            require(temp[1] != 0x58, "name cannot start with 0X");
        }
        bool _hasNonNumber;
        for (uint256 i = 0; i < length; i++) {
             
            if (temp[i] > 0x40 && temp[i] < 0x5b) {
                 
                temp[i] = byte(uint(temp[i]) + 32);
                 
                if (_hasNonNumber == false) {
                    _hasNonNumber = true;
                }
            } else {
                 
                require ((temp[i] > 0x60 && temp[i] < 0x7b) || (temp[i] > 0x2f && temp[i] < 0x3a), "name contains invalid characters");

                 
                if (_hasNonNumber == false && (temp[i] < 0x30 || temp[i] > 0x39)) {
                    _hasNonNumber = true;    
                }
            }
        }
        require(_hasNonNumber == true, "name cannot be only numbers");
        bytes32 _ret;
        assembly {
            _ret := mload(add(temp, 32))
        }
        return (_ret);
    }
}
 

pragma solidity ^0.4.24;

 

 
library SafeMath {

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
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

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

     
    function sqrt(uint256 x) internal pure returns (uint256 y) {
        uint256 z = ((add(x,1)) / 2);
        y = x;
        while (z < y) {
            y = z;
            z = ((add((x / z),z)) / 2);
        }
    }
}

 
contract Ownable {
    address public owner;


    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}

 
contract Saturn is Ownable {
    using SafeMath for uint256;

    struct Player {
        uint256 pid;  
        uint256 ethTotal;  
        uint256 ethBalance;  
        uint256 ethWithdraw;  
        uint256 ethShareWithdraw;  
        uint256 tokenBalance;  
        uint256 tokenDay;  
        uint256 tokenDayBalance;  
    }

    struct LuckyRecord {
        address player;  
        uint256 amount;  
        uint64 txId;  
        uint64 time;  
         
         
         
        uint64 level;
    }

     
    struct LuckyPending {
        address player;  
        uint256 amount;  
        uint64 txId;  
        uint64 block;  
        uint64 level;  
    }

    struct InternalBuyEvent {
         
         
         
         
         
         
         
        uint256 flag1;
    }

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Buy(
        address indexed _token, address indexed _player, uint256 _amount, uint256 _total,
        uint256 _totalSupply, uint256 _totalPot, uint256 _sharePot, uint256 _finalPot, uint256 _luckyPot,
        uint256 _price, uint256 _flag1
    );
    event Withdraw(address indexed _token, address indexed _player, uint256 _amount);
    event Win(address indexed _token, address indexed _winner, uint256 _winAmount);

    string constant public name = "Saturn";
    string constant public symbol = "SAT";
    uint8 constant public decimals = 18;

    uint256 constant private FEE_REGISTER_ACCOUNT = 10 finney;  
    uint256 constant private BUY_AMOUNT_MIN = 1000000000;  
    uint256 constant private BUY_AMOUNT_MAX = 100000000000000000000000;  
    uint256 constant private TIME_DURATION_INCREASE = 30 seconds;  
    uint256 constant private TIME_DURATION_MAX = 24 hours;  
    uint256 constant private ONE_TOKEN = 1000000000000000000;  

    mapping(address => Player) public playerOf;  
    mapping(uint256 => address) public playerIdOf;  
    uint256 public playerCount;  

    uint256 public totalSupply;  

    uint256 public totalPot;  
    uint256 public sharePot;  
    uint256 public finalPot;  
    uint256 public luckyPot;  

    uint64 public txCount;  
    uint256 public finishTime;  
    uint256 public startTime;  

    address public lastPlayer;  
    address public winner;  
    uint256 public winAmount;  

    uint256 public price;  

    address[3] public dealers;  
    uint256 public dealerDay;  

    LuckyPending[] public luckyPendings;
    uint256 public luckyPendingIndex;
    LuckyRecord[] public luckyRecords;  

    address public feeOwner;  
    uint256 public feeAmount;  

     
    uint64[16] public feePrices = [uint64(88000000000000),140664279921934,224845905067685,359406674201608,574496375292119,918308169866219,1467876789325690,2346338995279770,3750523695724810,5995053579423660,9582839714125510,15317764181758900,24484798507285300,39137915352965200,62560303190573500,99999999999999100];
     
    uint8[16] public feePercents = [uint8(150),140,130,120,110,100,90,80,70,60,50,40,30,20,10,0];
     
    uint256 public feeIndex;

     
    constructor(uint256 _startTime, address _feeOwner) public {
        require(_startTime >= now && _feeOwner != address(0));
        startTime = _startTime;
        finishTime = _startTime + TIME_DURATION_MAX;
        totalSupply = 0;
        price = 88000000000000;
        feeOwner = _feeOwner;
        owner = msg.sender;
    }

     
    modifier isActivated() {
        require(now >= startTime);
        _;
    }

     
    modifier isAccount() {
        address _address = msg.sender;
        uint256 _codeLength;

        assembly {_codeLength := extcodesize(_address)}
        require(_codeLength == 0 && tx.origin == msg.sender);
        _;
    }

     
    function balanceOf(address _owner) public view returns (uint256) {
        return playerOf[_owner].tokenBalance;
    }

     
    function getLuckyPendingSize() public view returns (uint256) {
        return luckyPendings.length;
    }
     
    function getLuckyRecordSize() public view returns (uint256) {
        return luckyRecords.length;
    }

     
    function getGameInfo() public view returns (
        uint256 _balance, uint256 _totalPot, uint256 _sharePot, uint256 _finalPot, uint256 _luckyPot, uint256 _rewardPot, uint256 _price,
        uint256 _totalSupply, uint256 _now, uint256 _timeLeft, address _winner, uint256 _winAmount, uint8 _feePercent
    ) {
        _balance = address(this).balance;
        _totalPot = totalPot;
        _sharePot = sharePot;
        _finalPot = finalPot;
        _luckyPot = luckyPot;
        _rewardPot = _sharePot;
        uint256 _withdraw = _sharePot.add(_finalPot).add(_luckyPot);
        if (_totalPot > _withdraw) {
            _rewardPot = _rewardPot.add(_totalPot.sub(_withdraw));
        }
        _price = price;
        _totalSupply = totalSupply;
        _now = now;
        _feePercent = feeIndex >= feePercents.length ? 0 : feePercents[feeIndex];
        if (now < finishTime) {
            _timeLeft = finishTime - now;
        } else {
            _timeLeft = 0;
            _winner = winner != address(0) ? winner : lastPlayer;
            _winAmount = winner != address(0) ? winAmount : finalPot;
        }
    }

     
    function getPlayerInfo(address _playerAddress) public view returns (
        uint256 _pid, uint256 _ethTotal, uint256 _ethBalance, uint256 _ethWithdraw,
        uint256 _tokenBalance, uint256 _tokenDayBalance
    ) {
        Player storage _player = playerOf[_playerAddress];
        if (_player.pid > 0) {
            _pid = _player.pid;
            _ethTotal = _player.ethTotal;
            uint256 _sharePot = _player.tokenBalance.mul(sharePot).div(totalSupply);  
            _ethBalance = _player.ethBalance;
            if (_sharePot > _player.ethShareWithdraw) {
                _ethBalance = _ethBalance.add(_sharePot.sub(_player.ethShareWithdraw));
            }
            _ethWithdraw = _player.ethWithdraw;
            _tokenBalance = _player.tokenBalance;
            uint256 _day = (now / 86400) * 86400;
            if (_player.tokenDay == _day) {
                _tokenDayBalance = _player.tokenDayBalance;
            }
        }
    }

     
    function getDealerAndLuckyInfo(uint256 _luckyOffset) public view returns (
        address[3] _dealerPlayers, uint256[3] _dealerDayTokens, uint256[3] _dealerTotalTokens,
        address[5] _luckyPlayers, uint256[5] _luckyAmounts, uint256[5] _luckyLevels, uint256[5] _luckyTimes
    ) {
        uint256 _day = (now / 86400) * 86400;
        if (dealerDay == _day) {
            for (uint256 _i = 0; _i < 3; ++_i) {
                if (dealers[_i] != address(0)) {
                    Player storage _player = playerOf[dealers[_i]];
                    _dealerPlayers[_i] = dealers[_i];
                    _dealerDayTokens[_i] = _player.tokenDayBalance;
                    _dealerTotalTokens[_i] = _player.tokenBalance;
                }
            }
        }
        uint256 _size = _luckyOffset >= luckyRecords.length ? 0 : luckyRecords.length - _luckyOffset;
        if (_luckyPlayers.length < _size) {
            _size = _luckyPlayers.length;
        }
        for (_i = 0; _i < _size; ++_i) {
            LuckyRecord memory _record = luckyRecords[luckyRecords.length - _luckyOffset - 1 - _i];
            _luckyPlayers[_i] = _record.player;
            _luckyAmounts[_i] = _record.amount;
            _luckyLevels[_i] = _record.level;
            _luckyTimes[_i] = _record.time;
        }
    }

     
    function transfer(address _to, uint256 _value) isActivated isAccount public returns (bool) {
        require(_to == address(this));
        Player storage _player = playerOf[msg.sender];
        require(_player.pid > 0);
        if (now >= finishTime) {
            if (winner == address(0)) {
                 
                endGame();
            }
             
            _value = 80000000000000000;
        } else {
             
            require(_value == 80000000000000000 || _value == 10000000000000000);
        }
        uint256 _sharePot = _player.tokenBalance.mul(sharePot).div(totalSupply);  
        uint256 _eth = 0;
         
        if (_sharePot > _player.ethShareWithdraw) {
            _eth = _sharePot.sub(_player.ethShareWithdraw);
            _player.ethShareWithdraw = _sharePot;
        }
         
        _eth = _eth.add(_player.ethBalance);
        _player.ethBalance = 0;
        _player.ethWithdraw = _player.ethWithdraw.add(_eth);
        if (_value == 80000000000000000) {
             
             
            uint256 _fee = _eth.mul(feeIndex >= feePercents.length ? 0 : feePercents[feeIndex]).div(1000);
            if (_fee > 0) {
                feeAmount = feeAmount.add(_fee);
                _eth = _eth.sub(_fee);
            }
            sendFeeIfAvailable();
            msg.sender.transfer(_eth);
            emit Withdraw(_to, msg.sender, _eth);
            emit Transfer(msg.sender, _to, 0);
        } else {
             
            InternalBuyEvent memory _buyEvent = InternalBuyEvent({
                flag1: 0
                });
            buy(_player, _buyEvent, _eth);
        }
        return true;
    }

     
    function() isActivated isAccount payable public {
        uint256 _eth = msg.value;
        require(now < finishTime);
        InternalBuyEvent memory _buyEvent = InternalBuyEvent({
            flag1: 0
            });
        Player storage _player = playerOf[msg.sender];
        if (_player.pid == 0) {
             
            require(_eth >= FEE_REGISTER_ACCOUNT);
             
            uint256 _fee = FEE_REGISTER_ACCOUNT.sub(BUY_AMOUNT_MIN);
            _eth = _eth.sub(_fee);
             
            feeAmount = feeAmount.add(_fee);
            playerCount = playerCount.add(1);
            Player memory _p = Player({
                pid: playerCount,
                ethTotal: 0,
                ethBalance: 0,
                ethWithdraw: 0,
                ethShareWithdraw: 0,
                tokenBalance: 0,
                tokenDay: 0,
                tokenDayBalance: 0
                });
            playerOf[msg.sender] = _p;
            playerIdOf[_p.pid] = msg.sender;
            _player = playerOf[msg.sender];
             
            _buyEvent.flag1 += 1;
        }
        buy(_player, _buyEvent, _eth);
    }

     
    function buy(Player storage _player, InternalBuyEvent memory _buyEvent, uint256 _amount) private {
        require(now < finishTime && _amount >= BUY_AMOUNT_MIN && _amount <= BUY_AMOUNT_MAX);
         
        uint256 _day = (now / 86400) * 86400;
        uint256 _backEth = 0;
        uint256 _eth = _amount;
        if (totalPot < 200000000000000000000) {
             
            if (_eth >= 5000000000000000000) {
                 
                _backEth = _eth.sub(5000000000000000000);
                _eth = 5000000000000000000;
            }
        }
        txCount = txCount + 1;  
        _buyEvent.flag1 += txCount * 10;  
        _player.ethTotal = _player.ethTotal.add(_eth);
        totalPot = totalPot.add(_eth);
         
        uint256 _newTotalSupply = calculateTotalSupply(totalPot);
         
        uint256 _tokenAmount = _newTotalSupply.sub(totalSupply);
        _player.tokenBalance = _player.tokenBalance.add(_tokenAmount);
         
         
        if (_player.tokenDay == _day) {
            _player.tokenDayBalance = _player.tokenDayBalance.add(_tokenAmount);
        } else {
            _player.tokenDay = _day;
            _player.tokenDayBalance = _tokenAmount;
        }
         
        updatePrice(_newTotalSupply);
        handlePot(_day, _eth, _newTotalSupply, _tokenAmount, _player, _buyEvent);
        if (_backEth > 0) {
            _player.ethBalance = _player.ethBalance.add(_backEth);
        }
        sendFeeIfAvailable();
        emitEndTxEvents(_eth, _tokenAmount, _buyEvent);
    }

     
    function handlePot(uint256 _day, uint256 _eth, uint256 _newTotalSupply, uint256 _tokenAmount, Player storage _player, InternalBuyEvent memory _buyEvent) private {
        uint256 _sharePotDelta = _eth.div(2);  
        uint256 _finalPotDelta = _eth.div(5);  
        uint256 _luckyPotDelta = _eth.mul(255).div(1000);  
        uint256 _dealerPotDelta = _eth.sub(_sharePotDelta).sub(_finalPotDelta).sub(_luckyPotDelta);  
        sharePot = sharePot.add(_sharePotDelta);
        finalPot = finalPot.add(_finalPotDelta);
        luckyPot = luckyPot.add(_luckyPotDelta);
        totalSupply = _newTotalSupply;
        handleDealerPot(_day, _dealerPotDelta, _player, _buyEvent);
        handleLuckyPot(_eth, _player);
         
        if (_tokenAmount >= ONE_TOKEN) {
            updateFinishTime(_tokenAmount);
            lastPlayer = msg.sender;
        }
        _buyEvent.flag1 += finishTime * 1000000000000000000000;  
    }

     
    function handleLuckyPot(uint256 _eth, Player storage _player) private {
        uint256 _seed = uint256(keccak256(abi.encodePacked(
                (block.timestamp).add
                (block.difficulty).add
                ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (now)).add
                (block.gaslimit).add
                ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (now)).add
                (block.number)
            )));
        _seed = _seed - ((_seed / 1000) * 1000);
        uint64 _level = 0;
        if (_seed < 227) {  
            _level = 1;
        } else if (_seed < 422) {  
            _level = 2;
        } else if (_seed < 519) {  
            _level = 3;
        } else if (_seed < 600) {  
            _level = 4;
        } else if (_seed < 700) {  
            _level = 5;
        } else {   
            _level = 6;
        }
        if (_level >= 5) {
             
            handleLuckyReward(txCount, _level, _eth, _player);
        } else {
             
            LuckyPending memory _pending = LuckyPending({
                player: msg.sender,
                amount: _eth,
                txId: txCount,
                block: uint64(block.number + 1),
                level: _level
                });
            luckyPendings.push(_pending);
        }
         
        handleLuckyPending(_level >= 5 ? 0 : 1);
    }

    function handleLuckyPending(uint256 _pendingSkipSize) private {
        if (luckyPendingIndex < luckyPendings.length - _pendingSkipSize) {
            LuckyPending storage _pending = luckyPendings[luckyPendingIndex];
            if (_pending.block <= block.number) {
                uint256 _seed = uint256(keccak256(abi.encodePacked(
                        (block.timestamp).add
                        (block.difficulty).add
                        ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (now)).add
                        (block.gaslimit).add
                        (block.number)
                    )));
                _seed = _seed - ((_seed / 1000) * 1000);
                handleLucyPendingForOne(_pending, _seed);
                if (luckyPendingIndex < luckyPendings.length - _pendingSkipSize) {
                    _pending = luckyPendings[luckyPendingIndex];
                    if (_pending.block <= block.number) {
                        handleLucyPendingForOne(_pending, _seed);
                    }
                }
            }
        }
    }

    function handleLucyPendingForOne(LuckyPending storage _pending, uint256 _seed) private {
        luckyPendingIndex = luckyPendingIndex.add(1);
        bool _reward = false;
        if (_pending.level == 4) {
            _reward = _seed < 617;
        } else if (_pending.level == 3) {
            _reward = _seed < 309;
        } else if (_pending.level == 2) {
            _reward = _seed < 102;
        } else if (_pending.level == 1) {
            _reward = _seed < 44;
        }
        if (_reward) {
            handleLuckyReward(_pending.txId, _pending.level, _pending.amount, playerOf[_pending.player]);
        }
    }

    function handleLuckyReward(uint64 _txId, uint64 _level, uint256 _eth, Player storage _player) private {
        uint256 _amount;
        if (_level == 1) {
            _amount = _eth.mul(7);  
        } else if (_level == 2) {
            _amount = _eth.mul(3);  
        } else if (_level == 3) {
            _amount = _eth;         
        } else if (_level == 4) {
            _amount = _eth.div(2);  
        } else if (_level == 5) {
            _amount = _eth.div(5);  
        } else if (_level == 6) {
            _amount = _eth.div(10);  
        }
        uint256 _maxPot = luckyPot.div(2);
        if (_amount > _maxPot) {
            _amount = _maxPot;
        }
        luckyPot = luckyPot.sub(_amount);
        _player.ethBalance = _player.ethBalance.add(_amount);
        LuckyRecord memory _record = LuckyRecord({
            player: msg.sender,
            amount: _amount,
            txId: _txId,
            level: _level,
            time: uint64(now)
            });
        luckyRecords.push(_record);
    }

     
    function handleDealerPot(uint256 _day, uint256 _dealerPotDelta, Player storage _player, InternalBuyEvent memory _buyEvent) private {
        uint256 _potUnit = _dealerPotDelta.div(dealers.length);
         
        if (dealerDay != _day || dealers[0] == address(0)) {
            dealerDay = _day;
            dealers[0] = msg.sender;
            dealers[1] = address(0);
            dealers[2] = address(0);
            _player.ethBalance = _player.ethBalance.add(_potUnit);
            feeAmount = feeAmount.add(_dealerPotDelta.sub(_potUnit));
            _buyEvent.flag1 += _player.pid * 100000000000000000000000000000000;  
            return;
        }
         
        for (uint256 _i = 0; _i < dealers.length; ++_i) {
            if (dealers[_i] == address(0)) {
                dealers[_i] = msg.sender;
                break;
            }
            if (dealers[_i] == msg.sender) {
                break;
            }
            Player storage _dealer = playerOf[dealers[_i]];
            if (_dealer.tokenDayBalance < _player.tokenDayBalance) {
                for (uint256 _j = dealers.length - 1; _j > _i; --_j) {
                    if (dealers[_j - 1] != msg.sender) {
                        dealers[_j] = dealers[_j - 1];
                    }
                }
                dealers[_i] = msg.sender;
                break;
            }
        }
         
        uint256 _fee = _dealerPotDelta;
        for (_i = 0; _i < dealers.length; ++_i) {
            if (dealers[_i] == address(0)) {
                break;
            }
            _dealer = playerOf[dealers[_i]];
            _dealer.ethBalance = _dealer.ethBalance.add(_potUnit);
            _fee = _fee.sub(_potUnit);
            _buyEvent.flag1 += _dealer.pid *
            (_i == 0 ? 100000000000000000000000000000000 :
            (_i == 1 ? 100000000000000000000000000000000000000000000000 :
            (_i == 2 ? 100000000000000000000000000000000000000000000000000000000000000 : 0)));  
        }
        if (_fee > 0) {
            feeAmount = feeAmount.add(_fee);
        }
    }

    function emitEndTxEvents(uint256 _eth, uint256 _tokenAmount, InternalBuyEvent memory _buyEvent) private {
        emit Transfer(address(this), msg.sender, _tokenAmount);
        emit Buy(
            address(this), msg.sender, _eth, _tokenAmount,
            totalSupply, totalPot, sharePot, finalPot, luckyPot,
            price, _buyEvent.flag1
        );
    }

     
    function endGame() private {
         
        if (luckyPot > 0) {
            feeAmount = feeAmount.add(luckyPot);
            luckyPot = 0;
        }
         
         
        if (winner == address(0) && lastPlayer != address(0)) {
            winner = lastPlayer;
            lastPlayer = address(0);
            winAmount = finalPot;
            finalPot = 0;
            Player storage _player = playerOf[winner];
            _player.ethBalance = _player.ethBalance.add(winAmount);
            emit Win(address(this), winner, winAmount);
        }
    }

     
    function updateFinishTime(uint256 _tokenAmount) private {
        uint256 _timeDelta = _tokenAmount.div(ONE_TOKEN).mul(TIME_DURATION_INCREASE);
        uint256 _finishTime = finishTime.add(_timeDelta);
        uint256 _maxTime = now.add(TIME_DURATION_MAX);
        finishTime = _finishTime <= _maxTime ? _finishTime : _maxTime;
    }

    function updatePrice(uint256 _newTotalSupply) private {
        price = _newTotalSupply.mul(2).div(10000000000).add(88000000000000);
        uint256 _idx = feeIndex + 1;
        while (_idx < feePrices.length && price >= feePrices[_idx]) {
            feeIndex = _idx;
            ++_idx;
        }
    }

    function calculateTotalSupply(uint256 _newTotalPot) private pure returns(uint256) {
        return _newTotalPot.mul(10000000000000000000000000000)
        .add(193600000000000000000000000000000000000000000000)
        .sqrt()
        .sub(440000000000000000000000);
    }

    function sendFeeIfAvailable() private {
        if (feeAmount > 1000000000000000000) {
            feeOwner.transfer(feeAmount);
            feeAmount = 0;
        }
    }

     
    function changeFeeOwner(address _feeOwner) onlyOwner public {
        require(_feeOwner != feeOwner && _feeOwner != address(0));
        feeOwner = _feeOwner;
    }

     
    function withdrawFee(uint256 _amount) onlyOwner public {
        require(now >= finishTime.add(30 days));
        if (winner == address(0)) {
            endGame();
        }
        feeAmount = feeAmount > _amount ? feeAmount.sub(_amount) : 0;
        feeOwner.transfer(_amount);
    }

}
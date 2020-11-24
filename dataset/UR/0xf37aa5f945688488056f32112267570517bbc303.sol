 

pragma solidity 0.4.24;

contract Owned {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        owner = newOwner;
    }
}

contract SafeMath {
    function multiplication(uint a, uint b) internal pure returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function division(uint a, uint b) internal pure returns (uint) {
        assert(b > 0);
        uint c = a / b;
        assert(a == b * c + a % b);
        return c;
    }

    function subtraction(uint a, uint b) internal pure returns (uint) {
        assert(b <= a);
        return a - b;
    }

    function addition(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        assert(c >= a);
        return c;
    }
}

contract LottoEvents {
    event BuyTicket(uint indexed _gameIndex, address indexed from, bytes numbers, uint _prizePool, uint _bonusPool);
    event LockRound(uint indexed _gameIndex, uint _state, uint indexed _blockIndex);
    event DrawRound(uint indexed _gameIndex, uint _state, uint indexed _blockIndex, string _blockHash, uint[] _winNumbers);
    event EndRound(uint indexed _gameIndex, uint _state, uint _jackpot, uint _bonusAvg, address[] _jackpotWinners, address[] _goldKeyWinners, bool _autoStartNext);
    event NewRound(uint indexed _gameIndex, uint _state, uint _initPrizeIn);
    event DumpPrize(uint indexed _gameIndex, uint _jackpot);
    event Transfer(uint indexed _gameIndex, uint value);
    event Activated(uint indexed _gameIndex);
    event Deactivated(uint indexed _gameIndex);
    event SelfDestroy(uint indexed _gameIndex);
}

library LottoModels {

     
    struct Ticket {
        uint rId;            
        address player;      
        uint btime;          
        uint[] numbers;      
        bool joinBonus;      
        bool useGoldKey;     
    }

     
    struct Round {
        uint rId;             
        uint stime;           
        uint etime;           
        uint8 state;          

        uint[] winNumbers;    
        address[] winners;    

        uint ethIn;           
        uint prizePool;       
        uint bonusPool;       
        uint teamFee;         

        uint btcBlockNoWhenLock;  
        uint btcBlockNo;          
        string btcBlockHash;      

        uint bonusAvg;        
        uint jackpot;         
        uint genGoldKeys;     
    }
}

contract Lottery is Owned, SafeMath, LottoEvents {
    string constant version = "1.0.1";

    uint constant private GOLD_KEY_CAP = 1500 ether;
    uint constant private BUY_LIMIT_CAP = 100;
    uint8 constant private ROUND_STATE_LIVE = 0;
    uint8 constant private ROUND_STATE_LOCKED = 1;
    uint8 constant private ROUND_STATE_DRAWED = 2;
    uint8 constant private ROUND_STATE_ENDED = 7;

    mapping (uint => LottoModels.Round) public rounds;        
    mapping (uint => LottoModels.Ticket[]) public tickets;    
    mapping (address => uint) public goldKeyRepo;             
    address[] private goldKeyKeepers;                            

    uint public goldKeyCounter = 0;                
    uint public unIssuedGoldKeys = 0;              
    uint public price = 0.01 ether;                
    bool public activated = false;                 
    uint public rId;                               

    constructor() public {
        rId = 0;
        activated = true;
        internalNewRound(0, 0);  
    }

     
     
    function()
        isHuman()
        isActivated()
        public
        payable {

        require(owner != msg.sender, "owner cannot buy.");
        require(address(this) != msg.sender, "contract cannot buy.");
        require(rounds[rId].state == ROUND_STATE_LIVE,  "this round not start yet, please wait.");
         
        require(msg.data.length > 9,  "data struct not valid");
        require(msg.data.length % 9 == 1, "data struct not valid");
         
        require(uint(msg.data[0]) < BUY_LIMIT_CAP, "out of buy limit one time.");
        require(msg.value == uint(msg.data[0]) * price, "price not right, please check.");


        uint i = 1;
        while(i < msg.data.length) {
             
             
             
             
             
            uint _times = uint(msg.data[i++]);
            uint _goldKeys = uint(msg.data[i++]);
            bool _joinBonus = uint(msg.data[i++]) > 0;
            uint[] memory _numbers = new uint[](6);
            for(uint j = 0; j < 6; j++) {
                _numbers[j] = uint(msg.data[i++]);
            }

             
            for (uint k = 0; k < _times; k++) {
                bool _useGoldKey = false;
                if (_goldKeys > 0 && goldKeyRepo[msg.sender] > 0) {  
                    _goldKeys--;  
                    goldKeyRepo[msg.sender]--;  
                    _useGoldKey = true;
                }
                tickets[rId].push(LottoModels.Ticket(rId, msg.sender,  now, _numbers, _joinBonus, _useGoldKey));
            }
        }

         
        rounds[rId].ethIn = addition(rounds[rId].ethIn, msg.value);
        uint _amount = msg.value * 4 / 10;
        rounds[rId].prizePool = addition(rounds[rId].prizePool, _amount);  
        rounds[rId].bonusPool = addition(rounds[rId].bonusPool, _amount);  
        rounds[rId].teamFee = addition(rounds[rId].teamFee, division(_amount, 2));    
         
        internalIncreaseGoldKeyCounter(_amount);

        emit BuyTicket(rId, msg.sender, msg.data, rounds[rId].prizePool, rounds[rId].bonusPool);
    }


     
     
     
     
     
     
     

     
    function lockRound(uint btcBlockNo)
    isActivated()
    onlyOwner()
    public {
        require(rounds[rId].state == ROUND_STATE_LIVE, "this round not live yet, no need lock");
        rounds[rId].btcBlockNoWhenLock = btcBlockNo;
        rounds[rId].state = ROUND_STATE_LOCKED;
        emit LockRound(rId, ROUND_STATE_LOCKED, btcBlockNo);
    }

     
    function drawRound(
        uint  btcBlockNo,
        string  btcBlockHash
    )
    isActivated()
    onlyOwner()
    public {
        require(rounds[rId].state == ROUND_STATE_LOCKED, "this round not locked yet, please lock it first");
        require(rounds[rId].btcBlockNoWhenLock < btcBlockNo,  "the btc block no should higher than the btc block no when lock this round");

         
        rounds[rId].winNumbers = calcWinNumbers(btcBlockHash);
        rounds[rId].btcBlockHash = btcBlockHash;
        rounds[rId].btcBlockNo = btcBlockNo;
        rounds[rId].state = ROUND_STATE_DRAWED;

        emit DrawRound(rId, ROUND_STATE_DRAWED, btcBlockNo, btcBlockHash, rounds[rId].winNumbers);
    }

     
     
    function endRound(
        uint jackpot,
        uint bonusAvg,
        address[] jackpotWinners,
        address[] goldKeyWinners,
        bool autoStartNext
    )
    isActivated()
    onlyOwner()
    public {
        require(rounds[rId].state == ROUND_STATE_DRAWED, "this round not drawed yet, please draw it first");

         
        rounds[rId].state = ROUND_STATE_ENDED;
        rounds[rId].etime = now;
        rounds[rId].jackpot = jackpot;
        rounds[rId].bonusAvg = bonusAvg;
        rounds[rId].winners = jackpotWinners;

         

         
        if (jackpotWinners.length > 0 && jackpot > 0) {
            unIssuedGoldKeys = 0;  
             
             
             
             
             
            for (uint i = 0; i < goldKeyKeepers.length; i++) {
                goldKeyRepo[goldKeyKeepers[i]] = 0;
            }
            delete goldKeyKeepers;
        } else {
             
            if (unIssuedGoldKeys > 0) {
                for (uint k = 0; k < goldKeyWinners.length; k++) {
                     
                    address _winner = goldKeyWinners[k];

                     
                    if (_winner == address(this)) {
                        continue;
                    }

                    goldKeyRepo[_winner]++;

                     
                    bool _hasKeeper = false;
                    for (uint j = 0; j < goldKeyKeepers.length; j++) {
                        if (goldKeyKeepers[j] == _winner) {
                            _hasKeeper = true;
                            break;
                        }
                    }
                    if (!_hasKeeper) {  
                        goldKeyKeepers.push(_winner);
                    }

                    unIssuedGoldKeys--;
                    if (unIssuedGoldKeys <= 0) {  
                        break;
                    }

                }
            }
             
            unIssuedGoldKeys = addition(unIssuedGoldKeys, rounds[rId].genGoldKeys);
        }

        emit EndRound(rId, ROUND_STATE_ENDED, jackpot, bonusAvg, jackpotWinners, goldKeyWinners, autoStartNext);
         

         
        if (autoStartNext) {
            newRound();
        }
    }

    function newRound()
    isActivated()
    onlyOwner()
    public {
         
        require(rounds[rId].state == ROUND_STATE_ENDED, "this round not ended yet, please end it first");

         
         
        uint _initPrizeIn = subtraction(rounds[rId].prizePool, rounds[rId].jackpot);
         
        uint _initBonusIn = rounds[rId].bonusPool;
        if (rounds[rId].bonusAvg > 0) {  
            _initBonusIn = 0;
        }
         
        internalNewRound(_initPrizeIn, _initBonusIn);

        emit NewRound(rId, ROUND_STATE_LIVE, _initPrizeIn);
    }

    function internalNewRound(uint _initPrizeIn, uint _initBonusIn) internal {
        rId++;
        rounds[rId].rId = rId;
        rounds[rId].stime = now;
        rounds[rId].state = ROUND_STATE_LIVE;
        rounds[rId].prizePool = _initPrizeIn;
        rounds[rId].bonusPool = _initBonusIn;
    }
    
    function internalIncreaseGoldKeyCounter(uint _amount) internal {
        goldKeyCounter = addition(goldKeyCounter, _amount);
        if (goldKeyCounter >= GOLD_KEY_CAP) {
            rounds[rId].genGoldKeys = addition(rounds[rId].genGoldKeys, 1);
            goldKeyCounter = subtraction(goldKeyCounter, GOLD_KEY_CAP);
        }
    }

     
    function calcWinNumbers(string blockHash)
    public
    pure
    returns (uint[]) {
        bytes32 random = keccak256(bytes(blockHash));
        uint[] memory allRedNumbers = new uint[](40);
        uint[] memory allBlueNumbers = new uint[](10);
        uint[] memory winNumbers = new uint[](6);
        for (uint i = 0; i < 40; i++) {
            allRedNumbers[i] = i + 1;
            if(i < 10) {
                allBlueNumbers[i] = i;
            }
        }
        for (i = 0; i < 5; i++) {
            uint n = 40 - i;
            uint r = (uint(random[i * 4]) + (uint(random[i * 4 + 1]) << 8) + (uint(random[i * 4 + 2]) << 16) + (uint(random[i * 4 + 3]) << 24)) % (n + 1);
            winNumbers[i] = allRedNumbers[r];
            allRedNumbers[r] = allRedNumbers[n - 1];
        }
        uint t = (uint(random[i * 4]) + (uint(random[i * 4 + 1]) << 8) + (uint(random[i * 4 + 2]) << 16) + (uint(random[i * 4 + 3]) << 24)) % 10;
        winNumbers[5] = allBlueNumbers[t];
        return winNumbers;
    }

     
    function getKeys() public view returns(uint) {
        return goldKeyRepo[msg.sender];
    }
    
    function getRoundByRId(uint _rId)
    public
    view
    returns (uint[] res){
        if(_rId > rId) return res;
        res = new uint[](18);
        uint k;
        res[k++] = _rId;
        res[k++] = uint(rounds[_rId].state);
        res[k++] = rounds[_rId].ethIn;
        res[k++] = rounds[_rId].prizePool;
        res[k++] = rounds[_rId].bonusPool;
        res[k++] = rounds[_rId].teamFee;
        if (rounds[_rId].winNumbers.length == 0) {
            for (uint j = 0; j < 6; j++)
                res[k++] = 0;
        } else {
            for (j = 0; j < 6; j++)
                res[k++] = rounds[_rId].winNumbers[j];
        }
        res[k++] = rounds[_rId].bonusAvg;
        res[k++] = rounds[_rId].jackpot;
        res[k++] = rounds[_rId].genGoldKeys;
        res[k++] = rounds[_rId].btcBlockNo;
        res[k++] = rounds[_rId].stime;
        res[k++] = rounds[_rId].etime;
    }

     

     
    function dumpPrize()
    isActivated()
    onlyOwner()
    public
    payable {
        require(rounds[rId].state == ROUND_STATE_LIVE, "this round not live yet.");
        rounds[rId].ethIn = addition(rounds[rId].ethIn, msg.value);
        rounds[rId].prizePool = addition(rounds[rId].prizePool, msg.value);
         
        internalIncreaseGoldKeyCounter(msg.value);
        emit DumpPrize(rId, msg.value);
    }

    function activate() public onlyOwner {
        activated = true;
        emit Activated(rId);
    }

    function deactivate() public onlyOwner {
        activated = false;
        emit Deactivated(rId);
    }

    function selfDestroy() public onlyOwner {
        selfdestruct(msg.sender);
        emit SelfDestroy(rId);
    }

    function transferToOwner(uint amount) public payable onlyOwner {
        msg.sender.transfer(amount);
        emit Transfer(rId, amount);
    }
     

     
    modifier isActivated() {
        require(activated == true, "its not ready yet.");
        _;
    }

    modifier isHuman() {
        address _addr = msg.sender;
        require (_addr == tx.origin);

        uint256 _codeLength;

        assembly {_codeLength := extcodesize(_addr)}
        require(_codeLength == 0, "sorry humans only");
        _;
    }
}
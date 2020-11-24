 

pragma solidity ^0.4.23;

 
contract SafeMath {

     
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

 
contract MultiOwnable {
    address public manager;  
    address[] public owners;
    mapping(address => bool) public ownerByAddress;

    event SetManager(address manager);
    event SetOwners(address[] owners);

    modifier onlyOwner() {
        require(ownerByAddress[msg.sender] == true);
        _;
    }

    modifier onlyManager() {
        require(msg.sender == manager);
        _;
    }

     
    constructor() public {
        manager = msg.sender;
    }

     
    function setOwners(address[] _owners) onlyManager public {
        _setOwners(_owners);
    }

    function _setOwners(address[] _owners) internal {
        for(uint256 i = 0; i < owners.length; i++) {
            ownerByAddress[owners[i]] = false;
        }

        for(uint256 j = 0; j < _owners.length; j++) {
            ownerByAddress[_owners[j]] = true;
        }
        owners = _owners;
        emit SetOwners(_owners);
    }

    function getOwners() public constant returns (address[]) {
        return owners;
    }

    function setManager(address _manager) onlyManager public {
        manager = _manager;
        emit SetManager(_manager);
    }
}


contract WorldCup is MultiOwnable, SafeMath {

    enum Result {Unknown, HomeWin, HomeDraw, HomeLoss}

     

    struct Match {
        bool created;

         
        string team;
        string teamDetail;
        int32  pointSpread;
        uint64 startTime;
        uint64 endTime;

         
        uint256 stakesOfWin;
        uint256 stakesOfDraw;
        uint256 stakesOfLoss;

         
        Result result;
    }

    struct Prediction {
        Result result;
        uint256 stake;
        bool withdraw;
    }

     

    uint public numMatches;
    mapping(uint => Match) public matches;
    mapping(uint => mapping(address => Prediction)) public predictions;
    uint256 public rate;

     

    event NewMatch(uint indexed id, string team, string detail, int32 spread, uint64 start, uint64 end);
    event MatchInfo(uint indexed id, string detail);
    event MatchResult(uint indexed id, Result result, uint256 fee);
    event Bet(address indexed user, uint indexed id, Result result, uint256 stake,
        uint256 stakesOfWin, uint256 stakesOfDraw, uint256 stakesOfLoss);
    event Withdraw(address indexed user, uint indexed id, uint256 bonus);

    modifier validId(uint _id) {
        require(matches[_id].created == true);
        _;
    }

    modifier validResult(Result _result) {
        require(_result == Result.HomeWin || _result == Result.HomeDraw || _result == Result.HomeLoss);
        _;
    }

    constructor() public {
        rate = 20;  
    }

     

    function createMatch(uint _id, string _team, string _teamDetail, int32 _pointSpread, uint64 _startTime, uint64 _endTime)
    onlyOwner
    public {

        require(_startTime < _endTime);
        require(matches[_id].created == false);

         
        Match memory _match = Match({
            created:true,
            team: _team,
            teamDetail: _teamDetail,
            pointSpread: _pointSpread,
            startTime: _startTime,
            endTime: _endTime,
            stakesOfWin: 0,
            stakesOfDraw: 0,
            stakesOfLoss: 0,
            result: Result.Unknown
            });

         
        matches[_id] = _match;
        numMatches++;

         
        emit NewMatch(_id, _team, _teamDetail, _pointSpread, _startTime, _endTime);
    }

    function updateMatchInfo(uint _id, string _teamDetail, uint64 _startTime, uint64 _endTime)
    onlyOwner
    validId(_id)
    public {

         
        if (bytes(_teamDetail).length > 0) {
            matches[_id].teamDetail = _teamDetail;
        }
        if (_startTime != 0) {
            matches[_id].startTime = _startTime;
        }
        if (_endTime != 0) {
            matches[_id].endTime = _endTime;
        }

         
        emit MatchInfo(_id, _teamDetail);
    }

    function announceMatchResult(uint _id, Result _result)
    onlyManager
    validId(_id)
    validResult(_result)
    public {

         
        require(matches[_id].result == Result.Unknown);

         
        matches[_id].result = _result;

         
        uint256 bonus;
        uint256 fee;
        Match storage _match = matches[_id];

        if (_result == Result.HomeWin) {
            bonus = add(_match.stakesOfDraw, _match.stakesOfLoss);
            if (_match.stakesOfWin > 0) {
                fee = div(bonus, rate);
            } else {
                fee = bonus;
            }
        } else if (_result == Result.HomeDraw) {
            bonus = add(_match.stakesOfWin, _match.stakesOfLoss);
            if (_match.stakesOfDraw > 0) {
                fee = div(bonus, rate);
            } else {
                fee = bonus;
            }
        } else if (_result == Result.HomeLoss) {
            bonus = add(_match.stakesOfWin, _match.stakesOfDraw);
            if (_match.stakesOfLoss > 0) {
                fee = div(bonus, rate);
            } else {
                fee = bonus;
            }
        }

        address thiz = address(this);
        require(thiz.balance >= fee);
        manager.transfer(fee);

         
        emit MatchResult(_id, _result, fee);
    }

     

    function bet(uint _id, Result _result)
    validId(_id)
    validResult(_result)
    public
    payable {

         
        require(msg.value > 0);

         
        Match storage _match = matches[_id];
        require(_match.result == Result.Unknown);
        require(_match.startTime <= now);
        require(_match.endTime >= now);

         
        if (_result == Result.HomeWin) {
            _match.stakesOfWin = add(_match.stakesOfWin, msg.value);
        } else if (_result == Result.HomeDraw) {
            _match.stakesOfDraw = add(_match.stakesOfDraw, msg.value);
        } else if (_result == Result.HomeLoss) {
            _match.stakesOfLoss = add(_match.stakesOfLoss, msg.value);
        }

         
        Prediction storage _prediction = predictions[_id][msg.sender];
        if (_prediction.result == Result.Unknown) {
            _prediction.stake = msg.value;
            _prediction.result = _result;
        } else {
            require(_prediction.result == _result);
            _prediction.stake = add(_prediction.stake, msg.value);
        }

         
        emit Bet(msg.sender, _id, _result, msg.value, _match.stakesOfWin, _match.stakesOfDraw, _match.stakesOfLoss);
    }

    function getBonus(uint _id, address addr)
    validId(_id)
    public
    view
    returns (uint256) {

         
        Match storage _match = matches[_id];
        if (_match.result == Result.Unknown) {
            return 0;
        }

         
        Prediction storage _prediction = predictions[_id][addr];
        if (_prediction.result == Result.Unknown) {
            return 0;
        }

         
        if (_match.result != _prediction.result) {
            return 0;
        }

         
        uint256 bonus = _calcBouns(_match, _prediction);
        bonus = add(bonus, _prediction.stake);

        return bonus;
    }

    function withdraw(uint _id)
    validId(_id)
    public {
         
        Match storage _match = matches[_id];
        require(_match.result != Result.Unknown);

         
        Prediction storage _prediction = predictions[_id][msg.sender];
        require(_prediction.result != Result.Unknown);
        require(_prediction.stake > 0);
        require(_prediction.withdraw == false);
        _prediction.withdraw = true;

         
        require(_prediction.result == _match.result);

         
        uint256 bonus = _calcBouns(_match, _prediction);
        bonus = add(bonus, _prediction.stake);

        address thiz = address(this);
        require(thiz.balance >= bonus);
        msg.sender.transfer(bonus);

         
        emit Withdraw(msg.sender, _id, bonus);
    }

    function _calcBouns(Match storage _match, Prediction storage _prediction)
    internal
    view
    returns (uint256) {

        uint256 bonus;

        if (_match.result != _prediction.result) {
            return 0;
        }

        if (_match.result == Result.HomeWin && _match.stakesOfWin > 0) {
            bonus = add(_match.stakesOfDraw, _match.stakesOfLoss);
            bonus = sub(bonus, div(bonus, rate));
            bonus = div(mul(_prediction.stake, bonus), _match.stakesOfWin);
        } else if (_match.result == Result.HomeDraw && _match.stakesOfDraw > 0 ) {
            bonus = add(_match.stakesOfWin, _match.stakesOfLoss);
            bonus = sub(bonus, div(bonus, rate));
            bonus = div(mul(_prediction.stake, bonus), _match.stakesOfDraw);
        } else if (_match.result == Result.HomeLoss && _match.stakesOfLoss > 0) {
            bonus = add(_match.stakesOfWin, _match.stakesOfDraw);
            bonus = sub(bonus, div(bonus, rate));
            bonus = div(mul(_prediction.stake, bonus), _match.stakesOfLoss);
        }

        return bonus;
    }
}
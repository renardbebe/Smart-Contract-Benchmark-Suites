 

 








pragma solidity 0.4.25;


library SafeMath {


    function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
        if (_a == 0) {
            return 0;
        }

        uint256 c = _a * _b;
        require(c / _a == _b);

        return c;
    }

    function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b > 0);
        uint256 c = _a / _b;

        return c;
    }

    function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b <= _a);
        uint256 c = _a - _b;

        return c;
    }

    function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
        uint256 c = _a + _b;
        require(c >= _a);

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

contract Storage {

    address private owner;

    mapping (address => Investor) investors;

    struct Investor {
        uint index;
        mapping (uint => uint) deposit;
        mapping (uint => uint) interest;
        mapping (uint => uint) withdrawals;
        mapping (uint => uint) start;
        uint checkpoint;
    }

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function updateInfo(address _address, uint _value, uint _interest) external onlyOwner {
        investors[_address].deposit[investors[_address].index] += _value;
        investors[_address].start[investors[_address].index] = block.timestamp;
        investors[_address].interest[investors[_address].index] = _interest;
    }

    function updateCheckpoint(address _address) external onlyOwner {
        investors[_address].checkpoint = block.timestamp;
    }

    function updateWithdrawals(address _address, uint _index, uint _withdrawal) external onlyOwner {
        investors[_address].withdrawals[_index] += _withdrawal;
    }

    function updateIndex(address _address) external onlyOwner {
        investors[_address].index += 1;
    }

    function ind(address _address) external view returns(uint) {
        return investors[_address].index;
    }

    function d(address _address, uint _index) external view returns(uint) {
        return investors[_address].deposit[_index];
    }

    function i(address _address, uint _index) external view returns(uint) {
        return investors[_address].interest[_index];
    }

    function w(address _address, uint _index) external view returns(uint) {
        return investors[_address].withdrawals[_index];
    }

    function s(address _address, uint _index) external view returns(uint) {
        return investors[_address].start[_index];
    }

    function c(address _address) external view returns(uint) {
        return investors[_address].checkpoint;
    }
}

contract SuperFOMO {
    using SafeMath for uint;

    address public owner;
    address advertising;
    address techsupport;

    uint waveStartUp;
    uint jackPot;
    uint lastLeader;

    address[] top;

    Storage x;

    event LogInvestment(address indexed _addr, uint _value);
    event LogPayment(address indexed _addr, uint _value);
    event LogReferralInvestment(address indexed _referrer, address indexed _referral, uint _value);
    event LogGift(address _firstAddr, address _secondAddr, address _thirdAddr, address _fourthAddr, address _fifthAddr);
    event LogNewWave(uint _waveStartUp);
    event LogNewLeader(address _leader);

    modifier notOnPause() {
        require(waveStartUp <= block.timestamp);
        _;
    }

    modifier notFromContract() {
        address addr = msg.sender;
        uint size;
        assembly { size := extcodesize(addr) }
        require(size <= 0);
        _;
    }

    constructor(address _advertising, address _techsupport) public {
        owner = msg.sender;
        advertising = _advertising;
        techsupport = _techsupport;
        waveStartUp = block.timestamp;
        x = new Storage();
    }

    function renounceOwnership() external {
        require(msg.sender == owner);
        owner = 0x0;
    }

    function bytesToAddress(bytes _source) internal pure returns(address parsedreferrer) {
        assembly {
            parsedreferrer := mload(add(_source,0x14))
        }
        return parsedreferrer;
    }

    function setRef() internal returns(uint) {
        address _referrer = bytesToAddress(bytes(msg.data));
        if (_referrer != msg.sender && getDividends(_referrer) > 0) {
            _referrer.transfer(msg.value / 20);

            emit LogReferralInvestment(_referrer, msg.sender, msg.value);
            return(msg.value / 50);
        } else {
            advertising.transfer(msg.value / 20);
            return(0);
        }
    }

    function getInterest() public view returns(uint) {
        uint multiplier = (block.timestamp.sub(waveStartUp)) / 6 days;
        if (multiplier == 0) {
            return 25;
        }
        if (multiplier <= 8){
            return(15 + (multiplier * 10));
        } else {
            return 100;
        }
    }

    function toTheTop() internal {
        top.push(msg.sender);
        lastLeader = block.timestamp;

        emit LogNewLeader(msg.sender);
    }

    function payDay() internal {
        top[top.length - 1].transfer(jackPot * 3 / 5);
        top[top.length - 2].transfer(jackPot / 10);
        top[top.length - 3].transfer(jackPot / 10);
        top[top.length - 4].transfer(jackPot / 10);
        top[top.length - 5].transfer(jackPot / 10);
        jackPot = 0;
        lastLeader = block.timestamp;
        emit LogGift(top[top.length - 1], top[top.length - 2], top[top.length - 3], top[top.length - 4], top[top.length - 5]);
    }

    function() external payable {
        if (msg.value < 50000000000000000) {
            msg.sender.transfer(msg.value);
            withdraw();
        } else {
            invest();
        }
    }

    function invest() public payable notOnPause notFromContract {

        require(msg.value >= 0.05 ether);
        jackPot += msg.value * 3 / 100;

        if (x.d(msg.sender, 0) > 0) {
            x.updateIndex(msg.sender);
        } else {
            x.updateCheckpoint(msg.sender);
        }

        if (msg.data.length == 20) {
            uint addend = setRef();
        } else {
            advertising.transfer(msg.value / 20);
        }

        x.updateInfo(msg.sender, msg.value + addend, getInterest());


        if (msg.value >= 1 ether) {
            toTheTop();
        }

        emit LogInvestment(msg.sender, msg.value);
    }

    function withdraw() public {

        uint _payout;

        uint _multiplier;

        if (block.timestamp > x.c(msg.sender) + 2 days) {
            _multiplier = 1;
        }

        for (uint i = 0; i <= x.ind(msg.sender); i++) {
            if (x.w(msg.sender, i) < x.d(msg.sender, i) * 2) {
                if (x.s(msg.sender, i) <= x.c(msg.sender)) {
                    uint dividends = (x.d(msg.sender, i).mul(_multiplier.mul(15).add(x.i(msg.sender, i))).div(1000)).mul(block.timestamp.sub(x.c(msg.sender).add(_multiplier.mul(2 days)))).div(1 days);
                    dividends = dividends.add(x.d(msg.sender, i).mul(x.i(msg.sender, i)).div(1000).mul(_multiplier).mul(2));
                    if (x.w(msg.sender, i) + dividends <= x.d(msg.sender, i) * 2) {
                        x.updateWithdrawals(msg.sender, i, dividends);
                        _payout = _payout.add(dividends);
                    } else {
                        _payout = _payout.add((x.d(msg.sender, i).mul(2)).sub(x.w(msg.sender, i)));
                        x.updateWithdrawals(msg.sender, i, x.d(msg.sender, i) * 2);
                    }
                } else {
                    if (x.s(msg.sender, i) + 2 days >= block.timestamp) {
                        dividends = (x.d(msg.sender, i).mul(_multiplier.mul(15).add(x.i(msg.sender, i))).div(1000)).mul(block.timestamp.sub(x.s(msg.sender, i).add(_multiplier.mul(2 days)))).div(1 days);
                        dividends = dividends.add(x.d(msg.sender, i).mul(x.i(msg.sender, i)).div(1000).mul(_multiplier).mul(2));
                        if (x.w(msg.sender, i) + dividends <= x.d(msg.sender, i) * 2) {
                            x.updateWithdrawals(msg.sender, i, dividends);
                            _payout = _payout.add(dividends);
                        } else {
                            _payout = _payout.add((x.d(msg.sender, i).mul(2)).sub(x.w(msg.sender, i)));
                            x.updateWithdrawals(msg.sender, i, x.d(msg.sender, i) * 2);
                        }
                    } else {
                        dividends = (x.d(msg.sender, i).mul(x.i(msg.sender, i)).div(1000)).mul(block.timestamp.sub(x.s(msg.sender, i))).div(1 days);
                        x.updateWithdrawals(msg.sender, i, dividends);
                        _payout = _payout.add(dividends);
                    }
                }

            }
        }

        if (_payout > 0) {
            if (_payout > address(this).balance && address(this).balance <= 0.1 ether) {
                nextWave();
                return;
            }
            x.updateCheckpoint(msg.sender);
            advertising.transfer(_payout * 3 / 25);
            techsupport.transfer(_payout * 3 / 100);
            msg.sender.transfer(_payout * 17 / 20);

            emit LogPayment(msg.sender, _payout * 17 / 20);
        }

        if (block.timestamp >= lastLeader + 1 days && top.length >= 5) {
            payDay();
        }
    }

    function nextWave() private {
        top.length = 0;
        x = new Storage();
        waveStartUp = block.timestamp + 10 days;
        emit LogNewWave(waveStartUp);
    }

    function getDeposits(address _address) public view returns(uint Invested) {
        uint _sum;
        for (uint i = 0; i <= x.ind(_address); i++) {
            if (x.w(_address, i) < x.d(_address, i) * 2) {
                _sum += x.d(_address, i);
            }
        }
        Invested = _sum;
    }

    function getDepositN(address _address, uint _number) public view returns(uint Deposit_N) {
        if (x.w(_address, _number - 1) < x.d(_address, _number - 1) * 2) {
            Deposit_N = x.d(_address, _number - 1);
        } else {
            Deposit_N = 0;
        }
    }

    function getDividends(address _address) public view returns(uint Dividends) {

        uint _payout;
        uint _multiplier;

        if (block.timestamp > x.c(_address) + 2 days) {
            _multiplier = 1;
        }

        for (uint i = 0; i <= x.ind(_address); i++) {
            if (x.w(_address, i) < x.d(_address, i) * 2) {
                if (x.s(_address, i) <= x.c(_address)) {
                    uint dividends = (x.d(_address, i).mul(_multiplier.mul(15).add(x.i(_address, i))).div(1000)).mul(block.timestamp.sub(x.c(_address).add(_multiplier.mul(2 days)))).div(1 days);
                    dividends += (x.d(_address, i).mul(x.i(_address, i)).div(1000).mul(_multiplier).mul(2));
                    if (x.w(_address, i) + dividends <= x.d(_address, i) * 2) {
                        _payout = _payout.add(dividends);
                    } else {
                        _payout = _payout.add((x.d(_address, i).mul(2)).sub(x.w(_address, i)));
                    }
                } else {
                    if (x.s(_address, i) + 2 days >= block.timestamp) {
                        dividends = (x.d(_address, i).mul(_multiplier.mul(15).add(x.i(_address, i))).div(1000)).mul(block.timestamp.sub(x.s(_address, i).add(_multiplier.mul(2 days)))).div(1 days);
                        dividends += (x.d(_address, i).mul(x.i(_address, i)).div(1000).mul(_multiplier).mul(2));
                        if (x.w(_address, i) + dividends <= x.d(_address, i) * 2) {
                            _payout = _payout.add(dividends);
                        } else {
                            _payout = _payout.add((x.d(_address, i).mul(2)).sub(x.w(_address, i)));
                        }
                    } else {
                        dividends = (x.d(_address, i).mul(x.i(_address, i)).div(1000)).mul(block.timestamp.sub(x.s(_address, i))).div(1 days);
                        _payout = _payout.add(dividends);
                    }
                }

            }
        }

        Dividends = _payout * 17 / 20;
    }

    function getWithdrawals(address _address) external view returns(uint) {
        uint _sum;
        for (uint i = 0; i <= x.ind(_address); i++) {
            _sum += x.w(_address, i);
        }
        return(_sum);
    }

    function getTop() external view returns(address, address, address, address, address) {
        return(top[top.length - 1], top[top.length - 2], top[top.length - 3], top[top.length - 4], top[top.length - 5]);
    }

    function getJackPot() external view returns(uint) {
        return(jackPot);
    }

    function getNextPayDay() external view returns(uint) {
        return(lastLeader + 1 days);
    }

}
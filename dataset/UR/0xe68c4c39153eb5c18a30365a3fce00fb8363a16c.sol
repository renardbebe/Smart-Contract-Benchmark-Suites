 

pragma solidity ^0.4.24;

 


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

contract InvestorsStorage {
    address private owner;

    mapping (address => Investor) private investors;

    struct Investor {
        uint deposit;
        uint checkpoint;
        address referrer;
    }

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function updateInfo(address _address, uint _value) external onlyOwner {
        investors[_address].deposit += _value;
        investors[_address].checkpoint = block.timestamp;
    }

    function updateCheckpoint(address _address) external onlyOwner {
        investors[_address].checkpoint = block.timestamp;
    }

    function addReferrer(address _referral, address _referrer) external onlyOwner {
        investors[_referral].referrer = _referrer;
    }

    function d(address _address) external view onlyOwner returns(uint) {
        return investors[_address].deposit;
    }

    function c(address _address) external view onlyOwner returns(uint) {
        return investors[_address].checkpoint;
    }

    function r(address _address) external view onlyOwner returns(address) {
        return investors[_address].referrer;
    }
}

contract SmartPyramid {
    using SafeMath for uint;

    address public owner;
    address fee_address;
    
    uint waveStartUp;
    uint nextPayDay;

    mapping (uint => Leader) top;

    event LogInvestment(address _addr, uint _value);
    event LogPayment(address _addr, uint _value);
    event LogNewReferrer(address _referral, address _referrer);
    event LogReferralInvestment(address _referral, uint _value);
    event LogGift(address _first, address _second, address _third);
    event LogNewWave(uint _waveStartUp);

    InvestorsStorage private x;

    modifier notOnPause() {
        require(waveStartUp <= block.timestamp);
        _;
    }

    struct Leader {
        address addr;
        uint deposit;
    }

    function renounceOwnership() external {
        require(msg.sender == owner);
        owner = 0x0;
    }

    function bytesToAddress(bytes _source) internal pure returns(address parsedReferrer) {
        assembly {
            parsedReferrer := mload(add(_source,0x14))
        }
        return parsedReferrer;
    }

    function addReferrer(uint _value) internal {
        address _referrer = bytesToAddress(bytes(msg.data));
        if (_referrer != msg.sender) {
            x.addReferrer(msg.sender, _referrer);
            x.r(msg.sender).transfer(_value / 20);
            emit LogNewReferrer(msg.sender, _referrer);
            emit LogReferralInvestment(msg.sender, _value);
        }
    }

    constructor(address _fee_address) public {
        owner = msg.sender;
        fee_address = _fee_address;
        x = new InvestorsStorage();
    }

    function getInfo(address _address) external view returns(uint deposit, uint amountToWithdraw) {
        deposit = x.d(_address);
        if (block.timestamp >= x.c(_address) + 10 minutes) {
            amountToWithdraw = (x.d(_address).mul(12).div(1000)).mul(block.timestamp.sub(x.c(_address))).div(1 days);
        } else {
            amountToWithdraw = 0;
        }
    }

    function getTop() external view returns(address, uint, address, uint, address, uint) {
        return(top[1].addr, top[1].deposit, top[2].addr, top[2].deposit, top[3].addr, top[3].deposit);
    }

    function() external payable {
        if (msg.value == 0) {
            withdraw();
        } else {
            invest();
        }
    }

    function invest() notOnPause public payable {

        fee_address.transfer(msg.value * 16 / 100);

        if (x.d(msg.sender) > 0) {
            withdraw();
        }

        x.updateInfo(msg.sender, msg.value);

        if (msg.value > top[3].deposit) {
            toTheTop();
        }

        if (x.r(msg.sender) != 0x0) {
            x.r(msg.sender).transfer(msg.value / 20);
            emit LogReferralInvestment(msg.sender, msg.value);
        } else if (msg.data.length == 20) {
            addReferrer(msg.value);
        }

        emit LogInvestment(msg.sender, msg.value);
    }


    function withdraw() notOnPause public {

        if (block.timestamp >= x.c(msg.sender) + 10 minutes) {
            uint _payout = (x.d(msg.sender).mul(12).div(1000)).mul(block.timestamp.sub(x.c(msg.sender))).div(1 days);
            x.updateCheckpoint(msg.sender);
        }

        if (_payout > 0) {

            if (_payout > address(this).balance) {
                nextWave();
                return;
            }

            msg.sender.transfer(_payout);
            emit LogPayment(msg.sender, _payout);
        }
    }

    function toTheTop() internal {
        if (msg.value <= top[2].deposit) {
            top[3] = Leader(msg.sender, msg.value);
        } else {
            if (msg.value <= top[1].deposit) {
                top[3] = top[2];
                top[2] = Leader(msg.sender, msg.value);
            } else {
                top[3] = top[2];
                top[2] = top[1];
                top[1] = Leader(msg.sender, msg.value);
            }
        }
    }

    function payDay() external {
        require(block.timestamp >= nextPayDay);
        nextPayDay = block.timestamp.sub((block.timestamp - 1538388000).mod(7 days)).add(7 days);
        emit LogGift(top[1].addr, top[2].addr, top[3].addr);
        for (uint i = 0; i <= 2; i++) {
            top[i+1].addr.transfer(2 ether / 2 ** i);
            top[i+1] = Leader(0x0, 0);
        }
    }

    function nextWave() private {
        for (uint i = 0; i <= 2; i++) {
            top[i+1] = Leader(0x0, 0);
        }
        x = new InvestorsStorage();
        waveStartUp = block.timestamp + 7 days;
        emit LogNewWave(waveStartUp);
    }
}
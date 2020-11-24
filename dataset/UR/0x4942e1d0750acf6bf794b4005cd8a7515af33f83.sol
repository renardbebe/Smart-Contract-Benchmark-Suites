 

 

pragma solidity ^0.5.11;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
         
        require(b > 0, errorMessage);
        uint256 c = a / b;
         

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract Owned {
    address public owner;
    address public newOwner;
    modifier onlyOwner {
        require(msg.sender == owner, 'Address not contract owner');
        _;
    }
    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner, 'Address not contract owner');
        owner = newOwner;
    }
}

contract PAXTR is Owned {
    using SafeMath for uint256;

    constructor() public payable {
        endOfMonth = 1575158400;
        owner = 0x08d19746Ee0c0833FC5EAF98181eB91DAEEb9abB;
        baseBalance[owner] = 2500000000;
        emit Transfer(address(0), owner, 10000000000);
    }

     
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Unlock(address indexed owner, uint256 value);
    event Lock(address indexed owner, uint256 value);


     
    uint256 public constant decimals = 8;
    string public constant name = "PAX Treasure Reserve";
    string public constant symbol = "PAXTR";

    string public acknowledgementOfUse = "http://paxco.in/PAXTR-acknowledgment-of-the-human-rights.pdf";
    bytes32 public acknowledgementOfUseHash = 0xbec69211ae828f3e8e4f566b1fcbee4fe0d2b7fdebbaad76fdfbb3850b1a0a46;

    address public minterAddress;
    address public worldTreasuryAddress;

    uint256 public createdTreasure = 0;
    uint256 public maximumBaseSupply = 0;
    uint256 public treasureAge = 948;

    uint256 public endOfMonth;
    uint256 public monthCount;

    bool public transfersPaused;

    function pauseTransfers(bool state) public onlyOwner {
        transfersPaused = state;
    }

     
    uint256 public demurrageBaseMultiplier = 1000000000000000000;

     
    mapping(address => uint256) public baseBalance;
    mapping(address => mapping(address => uint256)) public allowanceMapping;

    struct Treasure {
        uint256 monthlyClaim;
        uint256 endMonth;
        uint256 totalClaimed;
        mapping(uint256 => uint256) claimedInMonth;
    }
    mapping(address => Treasure) public treasure;
    function claimedInMonth(address account) public view returns (uint256) {
        return treasure[account].claimedInMonth[monthCount];
    }

    mapping(address => uint256) public totalReferrals;
    mapping(address => mapping(uint256 => uint256)) public monthlyReferrals;

     
    uint256 public monthReferralQuota = 1;
    uint256 public permanentReferralQuota = 5;

     
    function issueTreasure(address account, address referral) public {
        require(msg.sender == minterAddress, 'Only the minterAddress may call this function');
        require(treasure[account].endMonth == 0, 'Account has already been issued their Lifetime Treasure');

        if (referral != address(0)) {
            totalReferrals[referral] = totalReferrals[referral].add(1);
            monthlyReferrals[referral][monthCount] = monthlyReferrals[referral][monthCount].add(1);
        }

        uint256 _baseBalance = (uint256(50000000).mul(1000000000000000000)).div(demurrageBaseMultiplier);
        uint256 _newWorldBalance = (uint256(45500000000).mul(1000000000000000000)).div(demurrageBaseMultiplier);
        maximumBaseSupply = maximumBaseSupply.add(_baseBalance);
        baseBalance[account] = baseBalance[account].add(_baseBalance);
        emit Transfer(address(0), account, 50000000);
        baseBalance[worldTreasuryAddress] = baseBalance[worldTreasuryAddress].add(_newWorldBalance);
        emit Transfer(address(0), worldTreasuryAddress, 45500000000);
        createdTreasure = createdTreasure.add(1);
        treasure[account].endMonth = monthCount.add(treasureAge);
        treasure[account].monthlyClaim = uint256(500000000000).div(treasureAge);
        claim(account, 50000000);
    }

    function treasureWithdraw(address account, address to, uint256 amount) public onlyOwner {
        require(treasure[account].endMonth > monthCount.add(1), "Treasure is not active anymore");
        uint256 maximumClaim = treasure[account].monthlyClaim.mul(treasure[account].endMonth.sub(monthCount.add(1)));
        require(amount <= maximumClaim, "Not enough PAXTR to withdraw!");
        treasure[account].monthlyClaim = (maximumClaim.sub(amount)).div(treasure[account].endMonth.sub(monthCount.add(1)));
        uint256 baseAmount = (amount.mul(1000000000000000000)).div(demurrageBaseMultiplier);
        maximumBaseSupply = maximumBaseSupply.add(baseAmount);
        baseBalance[to] = baseBalance[to].add(baseAmount);
        emit Unlock(account, amount);
        emit Transfer(address(0), to, amount);
    }

    function treasureDeposit(address account, address from, uint256 amount) public onlyOwner {
        require(balanceOf(from) >= amount, 'From does not have sufficent balance');
        require(treasure[account].endMonth > monthCount.add(1), "Treasure is not active anymore");
        uint256 maximumClaim = treasure[account].monthlyClaim.mul(treasure[account].endMonth.sub(monthCount.add(1)));
        treasure[account].monthlyClaim = (maximumClaim.add(amount)).div(treasure[account].endMonth.sub(monthCount.add(1)));
        uint256 baseAmount = (amount.mul(1000000000000000000)).div(demurrageBaseMultiplier);
        baseBalance[from] = baseBalance[from].sub(baseAmount);
        maximumBaseSupply = maximumBaseSupply.sub(baseAmount);
        emit Lock(account, amount);
        emit Transfer(from, address(0), amount);
    }

    function claim(address account, uint256 amount) private returns (bool) {
        if (treasure[account].endMonth < monthCount || treasure[account].claimedInMonth[monthCount] == treasure[account].monthlyClaim) {
            return false;
        } else {
            if (amount >= treasure[account].monthlyClaim.sub(treasure[account].claimedInMonth[monthCount]) || totalReferrals[account] >= permanentReferralQuota || monthlyReferrals[account][monthCount] >= monthReferralQuota) {
                uint256 _amount = treasure[account].monthlyClaim.sub(treasure[account].claimedInMonth[monthCount]);
                treasure[account].claimedInMonth[monthCount] = treasure[account].monthlyClaim;
                uint256 baseAmount = (_amount.mul(1000000000000000000)).div(demurrageBaseMultiplier);
                baseBalance[account] = baseBalance[account].add(baseAmount);
                maximumBaseSupply = maximumBaseSupply.add(baseAmount);
                treasure[account].totalClaimed = treasure[account].totalClaimed.add(_amount);
                emit Transfer(address(0), account, _amount);
                emit Unlock(account, _amount);
                return true;
            } else {
                treasure[account].claimedInMonth[monthCount] = treasure[account].claimedInMonth[monthCount].add(amount);
                uint256 baseAmount = (amount.mul(1000000000000000000)).div(demurrageBaseMultiplier);
                baseBalance[account] = baseBalance[account].add(baseAmount);
                maximumBaseSupply = maximumBaseSupply.add(baseAmount);
                treasure[account].totalClaimed = treasure[account].totalClaimed.add(amount);
                emit Transfer(address(0), account, amount);
                emit Unlock(account, amount);
                return true;
            }
        }
    }

     
    function selfClaim() public {
        claim(msg.sender, 0);
    }

     
    mapping(address => bool) public hasMigrated;
    function migrateAccount(address account, uint256 _balance, uint256 _totalRefferals, uint256 _monthsRefferals, bool _hasTreasure, uint256 _treasureBalance) public onlyOwner {
        require(treasure[account].endMonth == 0, 'New treasure already exists for this wallet');
        require(hasMigrated[account] == false, 'This wallet has already been migrated');
        hasMigrated[account] = true;
        if (_balance != 0) {
            uint256 _baseBalance = (_balance.mul(1000000000000000000)).div(demurrageBaseMultiplier);
            baseBalance[account] = baseBalance[account].add(_baseBalance);
            emit Transfer(address(0), account, _balance);
        }
        totalReferrals[account] = totalReferrals[account].add(_totalRefferals);
        monthlyReferrals[account][monthCount] = monthlyReferrals[account][monthCount].add(_monthsRefferals);
        if (_hasTreasure == true) {
            treasure[account].monthlyClaim = _treasureBalance.div(treasureAge);
            treasure[account].endMonth = monthCount.add(treasureAge);
            treasure[account].totalClaimed = uint256(500000000000).sub(_treasureBalance);
            createdTreasure = createdTreasure.add(1);
        }
    }

     
    function newMonth() public {
        if (now >= endOfMonth) {
            endOfMonth = endOfMonth.add(2635200);
            monthCount = monthCount.add(1);
            uint256 bigInt = 1000000000000000000;
            demurrageBaseMultiplier = (demurrageBaseMultiplier.mul(bigInt))/(bigInt+(((treasureAge.mul(bigInt))/12)/55555));
        }
    }

     

    function totalSupply() public view returns (uint256) {
        return (maximumBaseSupply.mul(demurrageBaseMultiplier)).div(1000000000000000000);
    }

    function balanceOf(address account) public view returns (uint256) {
        return (baseBalance[account].mul(demurrageBaseMultiplier)).div(1000000000000000000);
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        require(transfersPaused == false, 'Transfers have been paused');
        require(balanceOf(msg.sender) >= amount, 'Sender does not have enough balance');
        uint256 baseAmount = (amount.mul(1000000000000000000)).div(demurrageBaseMultiplier);
        baseBalance[msg.sender] = baseBalance[msg.sender].sub(baseAmount);
        baseBalance[recipient] = baseBalance[recipient].add(baseAmount);
        emit Transfer(msg.sender, recipient, amount);
        newMonth();
        claim(msg.sender, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return allowanceMapping[owner][spender];
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        allowanceMapping[msg.sender][spender] = amount;
        newMonth();
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        require(transfersPaused == false, 'Transfers have been paused');
        require(allowanceMapping[sender][recipient] >= amount, 'Sender has not authorised this transaction');
        require(balanceOf(sender) >= amount, 'Sender does not have enough balance');
        uint256 baseAmount = (amount.mul(1000000000000000000)).div(demurrageBaseMultiplier);
        baseBalance[sender] = baseBalance[sender].sub(baseAmount);
        baseBalance[recipient] = baseBalance[recipient].add(baseAmount);
        allowanceMapping[sender][recipient] = allowanceMapping[sender][recipient].sub(baseAmount);
        emit Transfer(sender, recipient, amount);
        newMonth();
        claim(sender, amount);
        return true;
    }

     

    function setAcknowledgementOfUse(string memory _location, bytes32 _hash) public onlyOwner {
        bytes memory emptyStringTest = bytes(_location);
        require(emptyStringTest.length != 0 && _hash != bytes32(0), 'Not enough data supplied');
        acknowledgementOfUse = _location;
        acknowledgementOfUseHash = _hash;
    }

    function setMinterAddress(address _minterAddress) public onlyOwner {
        minterAddress = _minterAddress;
    }

    function setWorldTreasuryAddress(address _worldTreasuryAddress) public onlyOwner {
        worldTreasuryAddress = _worldTreasuryAddress;
    }

    function setTreasureAge(uint256 _treasureAge) public onlyOwner {
        treasureAge = _treasureAge;
    }

    function adjustEndOfMonth(uint256 _endOfMonth) public onlyOwner {
        require(_endOfMonth > block.timestamp, 'Specifed time is in the past');
        endOfMonth = _endOfMonth;
    }

    function setRefferalQuote(uint256 _total, uint256 _month) public onlyOwner {
        monthReferralQuota = _month;
        permanentReferralQuota = _total;
    }
}
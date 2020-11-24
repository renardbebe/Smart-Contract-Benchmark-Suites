 

 

pragma solidity 0.5.10;

library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) internal _balances;

    mapping (address => mapping (address => uint256)) internal _allowed;

    uint256 internal _totalSupply;

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address addr) public view returns (uint256) {
        return _balances[addr];
    }

    function allowance(address addr, address spender) public view returns (uint256) {
        return _allowed[addr][spender];
    }

    function approve(address spender, uint256 value) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = (
        _allowed[msg.sender][spender].add(addedValue));
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = (
        _allowed[msg.sender][spender].sub(subtractedValue));
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
        _transfer(from, to, value);
        return true;
    }

    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0));

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);

        emit Transfer(from, to, value);
    }
}

contract DetailedToken is ERC20 {

    string private _name = "Moriartio";
    string private _symbol = "MIO";
    uint8 private _decimals = 18;

    function name() public view returns(string memory) {
        return _name;
    }

    function symbol() public view returns(string memory) {
        return _symbol;
    }

    function decimals() public view returns(uint8) {
      return _decimals;
    }

}

contract TOKEN is DetailedToken {

    mapping (address => uint256) internal _payoutsTo;

    uint256 internal magnitude = 1e18;
    uint256 internal profitPerShare = 1e18;

    uint256 constant public DIV_TRIGGER = 0.000333 ether;

    event DividendsPayed(address indexed addr, uint256 amount);

    function _transfer(address payable from, address to, uint256 value) internal {
        require(to != address(0));

        if (dividendsOf(from) > 0) {
            _withdrawDividends(from);
        }

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        _payoutsTo[from] -= profitPerShare * value;
        _payoutsTo[to] += profitPerShare * value;

        emit Transfer(from, to, value);
    }

    function _purchase(address recipient, uint256 value) internal {
        if (totalSupply() > 0) {
            profitPerShare = profitPerShare.add(value * magnitude / totalSupply());
            _payoutsTo[recipient] = _payoutsTo[recipient].add(profitPerShare * value);
        }

        _totalSupply = _totalSupply.add(value);
        _balances[recipient] = _balances[recipient].add(value);

        emit Transfer(address(0), recipient, value);
    }

    function _withdrawDividends(address payable addr) internal {
        uint256 payout = dividendsOf(addr);
        if (payout > 0) {
            _payoutsTo[addr] = _payoutsTo[addr].add(dividendsOf(addr) * magnitude);
            uint256 value;
            if (msg.value == DIV_TRIGGER) {
                value = DIV_TRIGGER;
            }
            addr.transfer(payout + value);

            emit DividendsPayed(addr, payout);
        }
    }

    function dividendsOf(address addr) public view returns(uint256) {
        return (profitPerShare.mul(balanceOf(addr)).sub(_payoutsTo[addr])) / magnitude;
    }

    function myDividends() public view returns(uint256) {
        return dividendsOf(msg.sender);
    }

}

contract MORIART is TOKEN {
    using SafeMath for uint256;

    uint256 constant public ONE_HUNDRED   = 10000;
    uint256 constant public ADMIN_FEE     = 1000;
    uint256 constant public TOKENIZATION  = 500;
    uint256 constant public ONE_DAY       = 1 days;
    uint256 constant public MINIMUM       = 0.1 ether;
    uint16[3] public refPercent           = [300, 200, 100];

    uint256 constant public REF_TRIGGER   = 0 ether;
    uint256 constant public EXIT_TRIGGER  = 0.000777 ether;

    struct Deposit {
        uint256 amount;
        uint256 time;
    }

    struct User {
        Deposit[] deposits;
        address referrer;
        uint256 bonus;
    }

    mapping (address => User) public users;

    address payable public admin = 0x9C14a7882f635acebbC7f0EfFC0E2b78B9Aa4858;

    uint256 public maxBalance;

    uint256 public start = 1574035200;
    bool public finalized;

    event InvestorAdded(address indexed investor);
    event ReferrerAdded(address indexed investor, address indexed referrer);
    event DepositAdded(address indexed investor, uint256 amount);
    event Withdrawn(address indexed investor, uint256 amount);
    event RefBonusAdded(address indexed investor, address indexed referrer, uint256 amount, uint256 indexed level);
    event RefBonusPayed(address indexed investor, uint256 amount);
    event Finalized(uint256 amount);

    modifier notOnPause() {
        require(block.timestamp >= start && !finalized);
        _;
    }

    function() external payable {
        if (msg.value == REF_TRIGGER) {
            _withdrawBonus(msg.sender);
        } else if (msg.value == DIV_TRIGGER) {
            _withdrawDividends(msg.sender);
        } else if (msg.value == EXIT_TRIGGER) {
            _exit(msg.sender);
        } else {
            _invest(msg.sender);
        }
    }

    function _invest(address addr) internal notOnPause {
        require(msg.value >= MINIMUM);
        admin.transfer(msg.value * ADMIN_FEE / ONE_HUNDRED);

        users[addr].deposits.push(Deposit(msg.value, block.timestamp));

        if (users[addr].referrer != address(0)) {
            _refSystem(addr);
        } else if (msg.data.length == 20) {
            _addReferrer(addr, _bytesToAddress(bytes(msg.data)));
        }

        if (users[addr].deposits.length == 1) {
            emit InvestorAdded(addr);
        }

        _purchase(addr, msg.value * TOKENIZATION / ONE_HUNDRED);

        maxBalance += msg.value;

        emit DepositAdded(addr, msg.value);
    }

    function _withdrawBonus(address payable addr) internal {
        uint256 payout = getRefBonus(addr);
        if (payout > 0) {
            users[addr].bonus = 0;

            bool onFinalizing;
            if (payout + REF_TRIGGER > address(this).balance.sub(getFinalWave())) {
                payout = address(this).balance.sub(getFinalWave());
                onFinalizing = true;
            }

            addr.transfer(payout + REF_TRIGGER);

            emit RefBonusPayed(addr, payout);

            if (onFinalizing) {
                _finalize();
            }
        }
    }

    function _withdrawDividends(address payable addr) internal {
        uint256 payout = dividendsOf(addr);
        if (payout > 0) {
            _payoutsTo[addr] = _payoutsTo[addr].add(dividendsOf(addr) * magnitude);

            uint256 value;
            if (msg.value == DIV_TRIGGER) {
                value = DIV_TRIGGER;
            }

            bool onFinalizing;
            if (payout + value > address(this).balance.sub(getFinalWave())) {
                payout = address(this).balance.sub(getFinalWave());
                onFinalizing = true;
            }

            addr.transfer(payout + value);

            emit DividendsPayed(addr, payout);

            if (onFinalizing) {
                _finalize();
            }
        }
    }

    function _exit(address payable addr) internal {

        uint256 payout = getProfit(addr);

        if (getRefBonus(addr) != 0) {
            payout = payout.add(getRefBonus(addr));
            emit RefBonusPayed(addr, getRefBonus(addr));
            users[addr].bonus = 0;
        }

        if (dividendsOf(addr) != 0) {
            payout = payout.add(dividendsOf(addr));
            emit DividendsPayed(addr, dividendsOf(addr));
            _payoutsTo[addr] = _payoutsTo[addr].add(dividendsOf(addr) * magnitude);
        }

        require(payout >= MINIMUM);

        bool onFinalizing;
        if (payout + EXIT_TRIGGER > address(this).balance.sub(getFinalWave())) {
            payout = address(this).balance.sub(getFinalWave());
            onFinalizing = true;
        }

        delete users[addr];

        addr.transfer(payout + EXIT_TRIGGER);

        emit Withdrawn(addr, payout);

        if (onFinalizing) {
            _finalize();
        }
    }

    function _bytesToAddress(bytes memory source) internal pure returns(address parsedReferrer) {
        assembly {
            parsedReferrer := mload(add(source,0x14))
        }
        return parsedReferrer;
    }

    function _addReferrer(address addr, address refAddr) internal {
        if (refAddr != addr) {
            users[addr].referrer = refAddr;

            _refSystem(addr);
            emit ReferrerAdded(addr, refAddr);
        }
    }

    function _refSystem(address addr) internal {
        address referrer = users[addr].referrer;

        for (uint256 i = 0; i < 3; i++) {
            if (referrer != address(0)) {
                uint256 amount = msg.value * refPercent[i] / ONE_HUNDRED;
                users[referrer].bonus += amount;
                emit RefBonusAdded(addr, referrer, amount, i + 1);
                referrer = users[referrer].referrer;
            } else break;
        }
    }

    function _finalize() internal {
        admin.transfer(getFinalWave());
        finalized = true;
        emit Finalized(getFinalWave());
    }

    function setRefPercent(uint16[3] memory newRefPercents) public {
        require(msg.sender == admin);
        for (uint256 i = 0; i < 3; i++) {
            require(newRefPercents[i] <= 1000);
        }
        refPercent = newRefPercents;
    }

    function getPercent() public view returns(uint256) {
        if (block.timestamp >= start) {
            uint256 time = block.timestamp.sub(start);
            if (time < 60 * ONE_DAY) {
                return 10e18 + time * 1e18 * 10 / 60 / ONE_DAY;
            }
            if (time < 120 * ONE_DAY) {
                return 20e18 + (time - 60 * ONE_DAY) * 1e18 * 15 / 60 / ONE_DAY;
            }
            if (time < 180 * ONE_DAY) {
                return 35e18 + (time - 120 * ONE_DAY) * 1e18 * 20 / 60 / ONE_DAY;
            }
            if (time < 300 * ONE_DAY) {
                return 55e18 + (time - 180 * ONE_DAY) * 1e18 * 45 / 120 / ONE_DAY;
            }
            if (time >= 300 * ONE_DAY) {
                return 100e18 + (time - 300 * ONE_DAY) * 1e18 * 10 / 30 / ONE_DAY;
            }
        }
    }

    function getDeposits(address addr) public view returns(uint256) {
        uint256 sum;

        for (uint256 i = 0; i < users[addr].deposits.length; i++) {
            sum += users[addr].deposits[i].amount;
        }

        return sum;
    }

    function getDeposit(address addr, uint256 index) public view returns(uint256) {
        return users[addr].deposits[index].amount;
    }

    function getProfit(address addr) public view returns(uint256) {
        if (users[addr].deposits.length != 0) {
            uint256 payout;
            uint256 percent = getPercent();

            for (uint256 i = 0; i < users[addr].deposits.length; i++) {
                payout += (users[addr].deposits[i].amount * percent / 1e21) * (block.timestamp - users[addr].deposits[i].time) / ONE_DAY;
            }

            return payout;
        }
    }

    function getRefBonus(address addr) public view returns(uint256) {
        return users[addr].bonus;
    }

    function getFinalWave() internal view returns(uint256) {
        return maxBalance * ADMIN_FEE / ONE_HUNDRED;
    }

}
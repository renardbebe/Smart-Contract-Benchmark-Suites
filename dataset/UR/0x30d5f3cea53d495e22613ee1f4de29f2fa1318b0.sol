 

pragma solidity ^0.5.1;

 
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
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

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

 
contract ERC20 is IERC20 {
    using SafeMath for uint256;

    event Mint(address indexed to, uint256 value);
    event Burn(address indexed to, uint256 value);

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowed;

    uint256 private _totalSupply;

     
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

     
    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

     
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowed[owner][spender];
    }

     
    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

     
    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

     
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        _transfer(from, to, value);
        _approve(from, msg.sender, _allowed[from][msg.sender].sub(value));
        return true;
    }

     
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].add(addedValue));
        return true;
    }

     
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].sub(subtractedValue));
        return true;
    }

     
    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0));

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }

     
    function _mint(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.add(value);
        _balances[account] = _balances[account].add(value);
        emit Mint(account, value);
    }

     
    function _burn(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Burn(account, value);
    }

     
    function _approve(address owner, address spender, uint256 value) internal {
        require(spender != address(0));
        require(owner != address(0));

        _allowed[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

     
    function _burnFrom(address account, uint256 value) internal {
        _burn(account, value);
        _approve(account, msg.sender, _allowed[account][msg.sender].sub(value));
    }
}

 
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

     
    function owner() public view returns (address) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

     
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

     
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

     
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract BITFEX is ERC20, Ownable {
    string public constant name = "BITFEX";
    string public constant symbol = "BFX";
    uint32 public constant decimals = 18;

    event Release(address indexed to, uint256 value);
    event TokensVestedTeam(address indexed to, uint256 value);
    event TokensVestedFoundation(address indexed to, uint256 value);
    event TokensVestedEmployeePool(address indexed to, uint256 value);
    event TokensVestedAdvisors(address indexed to, uint256 value);
    event TokensVestedBounty(address indexed to, uint256 value);
    event TokensVestedPrivateSale(address indexed to, uint256 value);
    event RevenueTransferred(address indexed from, uint256 value);

    uint256 public teamAmount = uint256(2e8).mul(1 ether);  
    uint256 public foundationAmount = uint256(1e8).mul(1 ether);  
    uint256 public employeePoolAmount = uint256(5e7).mul(1 ether);  
    uint256 public liquidityAmount = uint256(5e7).mul(1 ether);  
    uint256 public advisorsAmount = uint256(25e6).mul(1 ether);  
    uint256 public bountyAmount = uint256(25e6).mul(1 ether);  
    uint256 public publicSaleAmount = uint256(4e8).mul(1 ether);  
    uint256 public privateSaleAmount = uint256(15e7).mul(1 ether);  
    address public revenuesAddress;  
    address[] private _vestedAddresses;
    mapping (address => bool) private _vestedAddressesAdded;

    mapping (address => uint256) private _balances_3_months;  
    mapping (address => uint256) private _released_3_months;  
    mapping (address => uint256) private _balances_6_months;  
    mapping (address => uint256) private _released_6_months;  
    mapping (address => uint256) private _balances_1_year;  
    mapping (address => uint256) private _released_1_year;  
    mapping (address => uint256) private _balances_2_years;  
    mapping (address => uint256) private _released_2_years;  
    mapping (address => uint256) private _balances_4_years;  
    mapping (address => uint256) private _released_4_years;  

    uint256 public vestingStartTime;  

     
    constructor(address newOwner) public {
        require(newOwner != address(0));
        _transferOwnership(newOwner);
        vestingStartTime = now;
    }

     
    function setRevenuesAddress (address newAddress) public onlyOwner returns (bool) {
        require(newAddress != address(0));
        revenuesAddress = newAddress;
        return true;
    }

     
    function teamVest (address recipient, uint256 amount) public onlyOwner returns (bool) {
        require(recipient != address(0));
        require(teamAmount >= amount, 'Tokens limit exceeded');
        if (!_vestedAddressesAdded[recipient]) {
            _vestedAddresses.push(recipient);
            _vestedAddressesAdded[recipient] = true;
        }
        teamAmount = teamAmount
            .sub(amount);
        _balances_4_years[recipient] = _balances_4_years[recipient]
            .add(amount);
        emit TokensVestedTeam(recipient, amount);
        return true;
    }

     
    function foundationVest (address recipient, uint256 amount) public onlyOwner returns (bool) {
        require(recipient != address(0));
        require(foundationAmount >= amount, 'Tokens limit exceeded');
        if (!_vestedAddressesAdded[recipient]) {
            _vestedAddresses.push(recipient);
            _vestedAddressesAdded[recipient] = true;
        }
        foundationAmount = foundationAmount
            .sub(amount);
        _balances_2_years[recipient] = _balances_2_years[recipient]
            .add(amount);
        emit TokensVestedFoundation(recipient, amount);
        return true;
    }

     
    function employeePoolVest (address recipient, uint256 amount) public onlyOwner returns (bool) {
        require(recipient != address(0));
        require(employeePoolAmount >= amount, 'Tokens limit exceeded');
        if (!_vestedAddressesAdded[recipient]) {
            _vestedAddresses.push(recipient);
            _vestedAddressesAdded[recipient] = true;
        }
        employeePoolAmount = employeePoolAmount
            .sub(amount);
        _balances_1_year[recipient] = _balances_1_year[recipient]
            .add(amount);
        emit TokensVestedEmployeePool(recipient, amount);
        return true;
    }

     
    function advisorsVest (address recipient, uint256 amount) public onlyOwner returns (bool) {
        require(recipient != address(0));
        require(advisorsAmount >= amount, 'Tokens limit exceeded');
        if (!_vestedAddressesAdded[recipient]) {
            _vestedAddresses.push(recipient);
            _vestedAddressesAdded[recipient] = true;
        }
        advisorsAmount = advisorsAmount
            .sub(amount);
        _balances_6_months[recipient] = _balances_6_months[recipient]
            .add(amount);
        emit TokensVestedAdvisors(recipient, amount);
        return true;
    }

     
    function bountyVest (address recipient, uint256 amount) public onlyOwner returns (bool) {
        require(recipient != address(0));
        require(bountyAmount >= amount, 'Tokens limit exceeded');
        if (!_vestedAddressesAdded[recipient]) {
            _vestedAddresses.push(recipient);
            _vestedAddressesAdded[recipient] = true;
        }
        bountyAmount = bountyAmount
            .sub(amount);
        _balances_3_months[recipient] = _balances_3_months[recipient]
            .add(amount);
        emit TokensVestedBounty(recipient, amount);
        return true;
    }

     
    function privateSaleVest (address recipient, uint256 amount) public onlyOwner returns (bool) {
        require(recipient != address(0));
        require(privateSaleAmount >= amount, 'Tokens limit exceeded');
        if (!_vestedAddressesAdded[recipient]) {
            _vestedAddresses.push(recipient);
            _vestedAddressesAdded[recipient] = true;
        }
        privateSaleAmount = privateSaleAmount
            .sub(amount);
        _balances_6_months[recipient] = _balances_6_months[recipient]
            .add(amount);
        emit TokensVestedPrivateSale(recipient, amount);
        return true;
    }

     
    function sendSaleTokens (address recipient, uint256 amount) public onlyOwner returns (bool) {
        require(amount > 0);
        require(recipient != address(0));
        require(publicSaleAmount >= amount, 'Tokens limit exceeded');
        publicSaleAmount = publicSaleAmount
            .sub(amount);
        _mint(recipient, amount);
        return true;
    }

     
    function sendLiquidityTokens (address recipient, uint256 amount) public onlyOwner returns (bool) {
        require(amount > 0);
        require(recipient != address(0));
        require(liquidityAmount >= amount, 'Tokens limit exceeded');
        liquidityAmount = liquidityAmount
            .sub(amount);
        _mint(recipient, amount);
        return true;
    }

     
    function vestedBalanceOf(address who) public view returns (uint256) {
        return _balances_3_months[who]
            .add(_balances_6_months[who])
            .add(_balances_1_year[who])
            .add(_balances_2_years[who])
            .add(_balances_4_years[who]);
    }

     
    function _available3months(address who) private view returns (uint256) {
        if (now.sub(vestingStartTime) > 91 days)
            return _balances_3_months[who]
                .sub(_released_3_months[who]);
        return 0;
    }

     
    function _available6months(address who) private view returns (uint256) {
        uint256 timeFromVestingStart = now
            .sub(vestingStartTime);
        if (timeFromVestingStart < 91 days)
            return 0;
        else if (timeFromVestingStart < 182 days)
            return _balances_6_months[who]
                .div(2)
                .sub(_released_6_months[who]);
        else
            return _balances_6_months[who]
                .sub(_released_6_months[who]);
    }

     
    function _available1year(address who) private view returns (uint256) {
        if (now.sub(vestingStartTime) > 365 days)
            return _balances_1_year[who]
                .sub(_released_1_year[who]);
        return 0;
    }

     
    function _available2years(address who) private view returns (uint256) {
        uint256 timeFromVestingStart = now
            .sub(vestingStartTime);
        if (timeFromVestingStart < 365 days)
            return 0;
        else if (timeFromVestingStart < 730 days)
            return _balances_2_years[who]
                .div(2)
                .sub(_released_2_years[who]);
        else
            return _balances_2_years[who]
                .sub(_released_2_years[who]);
    }

     
    function _available4years(address who) private view returns (uint256) {
        uint256 timeFromVestingStart = now
            .sub(vestingStartTime);
        uint256 vestingPeriod = timeFromVestingStart
            .div(182 days);
        if (vestingPeriod > 8) vestingPeriod = 8;
        return _balances_4_years[who]
            .mul(vestingPeriod)
            .mul(125)
            .div(1000)
            .sub(_released_4_years[who]);
    }

     
    function availableBalanceOf(address who) public view returns (uint256) {
        return _available3months(who)
            .add(_available6months(who))
            .add(_available1year(who))
            .add(_available2years(who))
            .add(_available4years(who));
    }

     
    function _release(address who) internal returns (bool) {
        uint256 toRelease;
        uint256 available = _available3months(who);
        if (available > 0) {
            _released_3_months[who] = _released_3_months[who]
                .add(available);
            toRelease =  toRelease
                .add(available);
        }
        available = _available6months(who);
        if (available > 0) {
            _released_6_months[who] = _released_6_months[who]
                .add(available);
            toRelease =  toRelease
                .add(available);
        }
        available = _available1year(who);
        if (available > 0) {
            _released_1_year[who] = _released_1_year[who]
                .add(available);
            toRelease =  toRelease
                .add(available);
        }
        available = _available2years(who);
        if (available > 0) {
            _released_2_years[who] = _released_2_years[who]
                .add(available);
            toRelease =  toRelease
                .add(available);
        }
        available = _available4years(who);
        if (available > 0) {
            _released_4_years[who] = _released_4_years[who]
                .add(available);
            toRelease =  toRelease
                .add(available);
        }
        if (toRelease > 0) {
            _mint(who, toRelease);
            emit Release(who, toRelease);
        }
        return true;
    }

     
    function release() public returns (bool) {
        return _release(msg.sender);
    }

     
    function releaseAll() public onlyOwner returns (bool) {
        for (uint256 i = 0; i < _vestedAddresses.length; i ++) {
            _release(_vestedAddresses[i]);
        }
        return true;
    }

     
    function transfer(address to, uint256 value) public returns (bool) {
        require(to != address(0));
        if (to != revenuesAddress)
            return super.transfer(to, value);
        super.transfer(to, value);
        _burn(to, value);
        emit RevenueTransferred(msg.sender, value);
        return true;
    }

     
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        require(to != address(0));
        if (to != revenuesAddress)
            return super.transferFrom(from, to, value);
        super.transferFrom(from, to, value);
        _burn(to, value);
        emit RevenueTransferred(from, value);
        return true;
    }
}
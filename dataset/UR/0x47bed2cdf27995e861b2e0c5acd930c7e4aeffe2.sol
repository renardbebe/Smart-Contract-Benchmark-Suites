 

pragma solidity ^0.4.24;




 
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
}


 
contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}


 
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender)
        public view returns (uint256);

    function transferFrom(address from, address to, uint256 value)
        public returns (bool);

    function approve(address spender, uint256 value) public returns (bool);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}


 
contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) balances;

    uint256 totalSupply_;

     
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

     
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

}


 
contract StandardToken is ERC20, BasicToken {

    mapping (address => mapping (address => uint256)) internal allowed;

     
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    )
        public
        returns (bool)
    {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(
        address _owner,
        address _spender
   )
        public
        view
        returns (uint256)
    {
        return allowed[_owner][_spender];
    }

     
    function increaseApproval(
        address _spender,
        uint256 _addedValue
    )
        public
        returns (bool)
    {
        allowed[msg.sender][_spender] = (
            allowed[msg.sender][_spender].add(_addedValue));
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

     
    function decreaseApproval(
        address _spender,
        uint256 _subtractedValue
    )
        public
        returns (bool)
    {
        uint256 oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

}


contract BSBEXToken is StandardToken {

    string public constant name = "BSBEXToken";
    string public constant symbol = "BSB";
    uint8 public constant decimals = 18;

    uint256 constant MONTH = 3600*24*30;

    struct TimeLock {
         
        uint256 amount;

         
        uint256 vestedAmount;

         
        uint16 vestedMonths;

         
        uint256 start;

         
        uint256 cliff;

         
        uint256 vesting;

        address from;
    }

    mapping(address => TimeLock) timeLocks;

    event NewTokenGrant(address indexed _from, address indexed _to, uint256 _amount, uint256 _start, uint256 _cliff, uint256 _vesting);
    event VestedTokenRedeemed(address indexed _to, uint256 _amount, uint256 _vestedMonths);
    event GrantedTokenReturned(address indexed _from, address indexed _to, uint256 _amount);

     
    constructor() public {
        totalSupply_ = 200000000 * (10 ** uint256(decimals));
        balances[msg.sender] = totalSupply_;
        emit Transfer(address(0), msg.sender, totalSupply_);
    }

    function vestBalanceOf(address who)
        public view
        returns (uint256 amount, uint256 vestedAmount, uint256 start, uint256 cliff, uint256 vesting)
    {
        require(who != address(0));
        amount = timeLocks[who].amount;
        vestedAmount = timeLocks[who].vestedAmount;
        start = timeLocks[who].start;
        cliff = timeLocks[who].cliff;
        vesting = timeLocks[who].vesting;
    }

     
    function grantToken(
        address _to,
        uint256 _amount,
        uint256 _start,
        uint256 _cliff,
        uint256 _vesting
    )
        public
        returns (bool success)
    {
        require(_to != address(0));
        require(_amount <= balances[msg.sender], "Not enough balance to grant token.");
        require(_amount > 0, "Nothing to transfer.");
        require((timeLocks[_to].amount.sub(timeLocks[_to].vestedAmount) == 0), "The previous vesting should be completed.");
        require(_cliff >= _start, "_cliff must be >= _start");
        require(_vesting > _start, "_vesting must be bigger than _start");
        require(_vesting > _cliff, "_vesting must be bigger than _cliff");

        balances[msg.sender] = balances[msg.sender].sub(_amount);
        timeLocks[_to] = TimeLock(_amount, 0, 0, _start, _cliff, _vesting, msg.sender);

        emit NewTokenGrant(msg.sender, _to, _amount, _start, _cliff, _vesting);
        return true;
    }

     
    function grantTokenStartNow(
        address _to,
        uint256 _amount,
        uint256 _cliffMonths,
        uint256 _vestingMonths
    )
        public
        returns (bool success)
    {
        return grantToken(
            _to,
            _amount,
            now,
            now.add(_cliffMonths.mul(MONTH)),
            now.add(_vestingMonths.mul(MONTH))
            );
    }

     
    function calcVestableToken(address _to)
        internal view
        returns (uint256 amount, uint256 vestedMonths, uint256 curTime)
    {
        uint256 vestTotalMonths;
        uint256 vestedAmount;
        uint256 vestPart;
        amount = 0;
        vestedMonths = 0;
        curTime = now;
        
        require(timeLocks[_to].amount > 0, "Nothing was granted to this address.");
        
        if (curTime <= timeLocks[_to].cliff) {
            return (0, 0, curTime);
        }

        vestedMonths = curTime.sub(timeLocks[_to].start) / MONTH;
        vestedMonths = vestedMonths.sub(timeLocks[_to].vestedMonths);

        if (curTime >= timeLocks[_to].vesting) {
            return (timeLocks[_to].amount.sub(timeLocks[_to].vestedAmount), vestedMonths, curTime);
        }

        if (vestedMonths > 0) {
            vestTotalMonths = timeLocks[_to].vesting.sub(timeLocks[_to].start) / MONTH;
            vestPart = timeLocks[_to].amount.div(vestTotalMonths);
            amount = vestedMonths.mul(vestPart);
            vestedAmount = timeLocks[_to].vestedAmount.add(amount);
            if (vestedAmount > timeLocks[_to].amount) {
                amount = timeLocks[_to].amount.sub(timeLocks[_to].vestedAmount);
            }
        }

        return (amount, vestedMonths, curTime);
    }

     
    function redeemVestableToken(address _to)
        public
        returns (bool success)
    {
        require(_to != address(0));
        require(timeLocks[_to].amount > 0, "Nothing was granted to this address!");
        require(timeLocks[_to].vestedAmount < timeLocks[_to].amount, "All tokens were vested!");

        (uint256 amount, uint256 vestedMonths, uint256 curTime) = calcVestableToken(_to);
        require(amount > 0, "Nothing to redeem now.");

        TimeLock storage t = timeLocks[_to];
        balances[_to] = balances[_to].add(amount);
        t.vestedAmount = t.vestedAmount.add(amount);
        t.vestedMonths = t.vestedMonths + uint16(vestedMonths);
        t.cliff = curTime;

        emit VestedTokenRedeemed(_to, amount, vestedMonths);
        return true;
    }

     
    function returnGrantedToken(uint256 _amount)
        public
        returns (bool success)
    {
        address to = timeLocks[msg.sender].from;
        require(to != address(0));
        require(_amount > 0, "Nothing to transfer.");
        require(timeLocks[msg.sender].amount > 0, "Nothing to return.");
        require(_amount <= timeLocks[msg.sender].amount.sub(timeLocks[msg.sender].vestedAmount), "Not enough granted token to return.");

        timeLocks[msg.sender].amount = timeLocks[msg.sender].amount.sub(_amount);
        balances[to] = balances[to].add(_amount);

        emit GrantedTokenReturned(msg.sender, to, _amount);
        return true;
    }

}
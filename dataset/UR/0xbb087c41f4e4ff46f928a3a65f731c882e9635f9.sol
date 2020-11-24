 

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


 
contract Ownable {
    address public owner;


    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );


     
    constructor() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(owner);
        owner = address(0);
    }

     
    function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
}

     
    function _transferOwnership(address _newOwner) internal {
        require(_newOwner != address(0));
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}

 
contract ERC20 {
    function totalSupply() public view returns (uint256);

    function balanceOf(address _who) public view returns (uint256);

    function allowance(address _owner, address _spender)
    public view returns (uint256);

    function transfer(address _to, uint256 _value) public returns (bool);

    function approve(address _spender, uint256 _value)
    public returns (bool);

    function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}



contract AS is ERC20, Ownable {
    using SafeMath for uint256;

    mapping (address => uint256) public balances;

    mapping (address => mapping (address => uint256)) private allowed;

    uint256 private totalSupply_ = 110000000 * 10**8;

    string public constant name = "AmaStar";
    string public constant symbol = "AS";
    uint8 public constant decimals = 8;

    mapping (address => uint) lockupTime;
    mapping (address => uint) lockupAmount;


    bool private teamGotMoney = false;

    function lock(address _victim, uint _value, uint _periodSec) public onlyOwner {
        lockupAmount[_victim] = 0;
        lockupTime[_victim] = 0;
        lockupAmount[_victim] = _value;
        lockupTime[_victim] = block.timestamp.add(_periodSec);
    }

    function unlock(address _luckier) external onlyOwner {
        lockupAmount[_luckier] = 0;
        lockupTime[_luckier] = 0;
    }

    constructor() public {
        balances[msg.sender] = totalSupply_;
    }


    function transferAndLockToTeam(address _team1year, address _team6months, address _operations1year, address _operations9months, address _operations6months, address _operations3months) external onlyOwner {
        require(!teamGotMoney);
        teamGotMoney = true;
        transfer(_team1year, 10000000 * 10**8);
        transfer(_team6months, 6500000 * 10**8);
        lock(_team1year, 10000000 * 10**8, 365 * 1 days);
        lock(_team6months, 6500000 * 10**8, 182 * 1 days);
        transfer(_operations1year, 2750000 * 10**8);
        transfer(_operations9months, 2750000 * 10**8);
        transfer(_operations6months, 2750000 * 10**8);
        transfer(_operations3months, 2750000 * 10**8);
        lock(_operations1year, 2750000 * 10**8, 365 * 1 days);
        lock(_operations9months, 2750000 * 10**8, 273 * 1 days);
        lock(_operations6months, 2750000 * 10**8, 182 * 1 days);
        lock(_operations3months, 2750000 * 10**8, 91 * 1 days);
    }

     
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

     
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
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

     
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_value <= balances[msg.sender]);
        require(_to != address(0));

        if (lockupAmount[msg.sender] > 0) {
            if (block.timestamp <= lockupTime[msg.sender]) {
                require(balances[msg.sender].sub(lockupAmount[msg.sender]) >= _value);
            }
        }

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    )
    public
    returns (bool)
    {
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        require(_to != address(0));

        if (lockupAmount[_from] > 0) {
            if (now <= lockupTime[_from]) {
                require(balances[_from].sub(lockupAmount[_from]) >= _value);
            }
        }

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
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
        if (_subtractedValue >= oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }



     
    function _burn(address _account, uint256 _amount) internal {
        require(_account != 0);
        require(_amount <= balances[_account]);

        totalSupply_ = totalSupply_.sub(_amount);
        balances[_account] = balances[_account].sub(_amount);
        emit Transfer(_account, address(0), _amount);
    }

     
    function _burnFrom(address _account, uint256 _amount) internal {
        require(_amount <= allowed[_account][msg.sender]);

         
         
        allowed[_account][msg.sender] = allowed[_account][msg.sender].sub(_amount);
        _burn(_account, _amount);
    }

}


contract Crowdsale is Ownable {
    using SafeMath for uint256;

    address public multisig;

    AS public token;

    uint rate;
    uint rateInUsd;
    uint priceETH;

    uint indCap;

    event Purchased(address _buyer, uint _amount, string _type);


    function setIndCap(uint _indCapETH) public onlyOwner {
        indCap = _indCapETH;
    }

    function getIndCapInETH() public view returns(uint) {
        return indCap;
    }

    function setPriceETH(uint _newPriceETH) external onlyOwner {
        setRate(_newPriceETH);
    }

    function setRate(uint _priceETH) internal {
        require(_priceETH != 0);
        priceETH = _priceETH;
        rate = rateInUsd.mul(1 ether).div(_priceETH);
    }

    function getPriceETH() public view returns(uint) {
        return priceETH;
    }

    constructor() public {
    }

    function() external payable {
    }

    function finalizeICO(address _owner) external onlyOwner {
        require(_owner != address(0));
        uint balance = token.balanceOf(this);
        token.transfer(_owner, balance);
    }

    function getMyBalanceAS() external view returns(uint256) {
        return token.balanceOf(msg.sender);
    }
}

contract whitelistICO is Crowdsale {

    uint periodWhitelist;
    uint startWhitelist;
    uint public bonuses1;

    mapping (address => bool) whitelist;

    function addToWhitelist(address _newMember) external onlyOwner {
        require(_newMember != address(0));
        whitelist[_newMember] = true;
    }

    function removeFromWhitelist(address _member) external onlyOwner {
        require(_member != address(0));
        whitelist[_member] = false;
    }

    function addListToWhitelist(address[] _addresses) external onlyOwner {
        for (uint i = 0; i < _addresses.length; i++) {
            whitelist[_addresses[i]] = true;
        }
    }

    function removeListFromWhitelist(address[] _addresses) external onlyOwner {
        for (uint i = 0; i < _addresses.length; i++) {
            whitelist[_addresses[i]] = false;
        }
    }

    constructor(address _AS, address _multisig, uint _priceETH, uint _startWhiteListUNIX, uint _periodWhitelistSEC, uint _indCap) public {
        require(_AS != 0 && _priceETH != 0);
        token = AS(_AS);
        multisig = _multisig;  
        bonuses1 = 50;  
        startWhitelist = _startWhiteListUNIX;  
        periodWhitelist = _periodWhitelistSEC;  
        rateInUsd = 10;  
        setRate(_priceETH);
        setIndCap(_indCap);
    }

    function extendPeriod(uint _days) external onlyOwner {
        periodWhitelist = periodWhitelist.add(_days.mul(1 days));
    }


    function() external payable {
        buyTokens();
    }

    function buyTokens() public payable {
        require(block.timestamp > startWhitelist && block.timestamp < startWhitelist.add(periodWhitelist));


        if (indCap > 0) {
            require(msg.value <= indCap.mul(1 ether));
        }

        require(whitelist[msg.sender]);
        uint256 totalAmount = msg.value.mul(1 ether).mul(10^8).div(rate).add(msg.value.mul(1 ether).mul(10**8).mul(bonuses1).div(100).div(rate));
        uint256 balance = token.balanceOf(this);

        if (totalAmount > balance) {
            uint256 cash = balance.mul(rate).mul(100).div(100 + bonuses1).div(10**8).div(1 ether);
            uint256 cashBack = msg.value.sub(cash);
            multisig.transfer(cash);
            msg.sender.transfer(cashBack);
            token.transfer(msg.sender, balance);
            emit Purchased(msg.sender, balance, "WhiteList");
            return;
        }

        multisig.transfer(msg.value);
        token.transfer(msg.sender, totalAmount);
        emit Purchased(msg.sender, totalAmount, "WhiteList");
    }

}


contract preICO is Crowdsale {

    uint public bonuses2;
    uint startPreIco;
    uint periodPreIco;



    constructor(address _AS, address _multisig, uint _priceETH, uint _startPreIcoUNIX, uint _periodPreIcoSEC, uint _indCap) public {
        require(_AS != 0 && _priceETH != 0);
        token = AS(_AS);
        multisig = _multisig;  
        bonuses2 = 20;  
        startPreIco = _startPreIcoUNIX;  
        periodPreIco = _periodPreIcoSEC;  
        rateInUsd = 10;  
        setRate(_priceETH);
        setIndCap(_indCap);
    }

    function extendPeriod(uint _days) external onlyOwner {
        periodPreIco = periodPreIco.add(_days.mul(1 days));
    }

    function() external payable {
        buyTokens();
    }

    function buyTokens() public payable {
        require(block.timestamp > startPreIco && block.timestamp < startPreIco.add(periodPreIco));


        if (indCap > 0) {
            require(msg.value <= indCap.mul(1 ether));
        }

        uint256 totalAmount = msg.value.mul(10**8).div(rate).add(msg.value.mul(10**8).mul(bonuses2).div(100).div(rate));
        uint256 balance = token.balanceOf(this);

        if (totalAmount > balance) {
            uint256 cash = balance.mul(rate).mul(100).div(100 + bonuses2).div(10**8);
            uint256 cashBack = msg.value.sub(cash);
            multisig.transfer(cash);
            msg.sender.transfer(cashBack);
            token.transfer(msg.sender, balance);
            emit Purchased(msg.sender, balance, "PreICO");
            return;
        }

        multisig.transfer(msg.value);
        token.transfer(msg.sender, totalAmount);
        emit Purchased(msg.sender, totalAmount, "PreICO");
    }

}


contract mainICO is Crowdsale {

    uint startIco;
    uint periodIco;



    constructor(address _AS, address _multisig, uint _priceETH, uint _startIcoUNIX, uint _periodIcoSEC, uint _indCap) public {
        require(_AS != 0 && _priceETH != 0);
        token = AS(_AS);
        multisig = _multisig;  
        startIco = _startIcoUNIX;  
        periodIco = _periodIcoSEC;  
        rateInUsd = 10;  
        setRate(_priceETH);
        setIndCap(_indCap);
    }

    function extendPeriod(uint _days) external onlyOwner {
        periodIco = periodIco.add(_days.mul(1 days));
    }

    function() external payable {
        buyTokens();
    }

    function buyTokens() public payable {
        require(block.timestamp > startIco && block.timestamp < startIco.add(periodIco));

        if (indCap > 0) {
            require(msg.value <= indCap.mul(1 ether));
        }

        uint256 amount = msg.value.mul(10**8).div(rate);
        uint256 balance = token.balanceOf(this);

        if (amount > balance) {
            uint256 cash = balance.mul(rate).div(10**8);
            uint256 cashBack = msg.value.sub(cash);
            multisig.transfer(cash);
            msg.sender.transfer(cashBack);
            token.transfer(msg.sender, balance);
            emit Purchased(msg.sender, balance, "MainICO");
            return;
        }

        multisig.transfer(msg.value);
        token.transfer(msg.sender, amount);
        emit Purchased(msg.sender, amount, "MainICO");
    }
}
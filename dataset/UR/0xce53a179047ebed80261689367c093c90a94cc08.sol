 

pragma solidity ^0.4.16;

contract SafeMath {
    function safeMul(uint a, uint b) pure internal returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function safeSub(uint a, uint b) pure internal returns (uint) {
        assert(b <= a);
        return a - b;
    }

    function safeAdd(uint a, uint b) pure internal returns (uint) {
        uint c = a + b;
        assert(c >= a && c >= b);
        return c;
    }
}

contract EDT is SafeMath {

    string public name = "EDT";         
    string public symbol = "EDT";       
    uint public decimals = 8;            

    mapping (address => uint) public balanceOf;
    mapping (address => mapping (address => uint)) public allowance;

    uint public totalSupply = 0;

     
    address public owner = 0x0;

     
    address private addressTeam = 0xE5fB6dce07BCa4ffc4B79A529a8Ce43A31383BA9;

     
    mapping (address => uint) public lockInfo;

     
    bool public saleStopped = false;

    uint constant valueTotal = 15 * 10000 * 10000 * 10 ** 8;   
    uint constant valueSale = valueTotal / 100 * 50;   
    uint constant valueVip = valueTotal / 100 * 40;    
    uint constant valueTeam = valueTotal / 100 * 10;    

    uint private totalVip = 0;

     
    uint private constant BEFORE_SALE = 0;
    uint private constant IN_SALE = 1;
    uint private constant FINISHED = 2;

     
    uint public minEth = 0.1 ether;

     
    uint public maxEth = 1000 ether;

     
    uint public openTime = 1514736000;
     
    uint public closeTime = 1515945600;
     
    uint public price = 8500;

     
    uint public unlockTime = 1515945600;

     
    uint public unlockTeamTime = 1547049600;

     
    uint public saleQuantity = 0;

     
    uint public ethQuantity = 0;

     
    uint public withdrawQuantity = 0;


    modifier isOwner {
        assert(owner == msg.sender);
        _;
    }

    modifier validAddress(address _address) {
        assert(0x0 != _address);
        _;
    }

    modifier validEth {
        assert(msg.value >= minEth && msg.value <= maxEth);
        _;
    }

    modifier validPeriod {
        assert(now >= openTime && now < closeTime);
        _;
    }

    modifier validQuantity {
        assert(valueSale >= saleQuantity);
        _;
    }


    function EDT()
        public
    {
        owner = msg.sender;
        totalSupply = valueTotal;

         
        balanceOf[this] = valueSale;
        Transfer(0x0, this, valueSale);

         
        balanceOf[addressTeam] = valueTeam;
        Transfer(0x0, addressTeam, valueTeam);
    }

    function transfer(address _to, uint _value)
        public
        validAddress(_to)
        returns (bool success)
    {
        require(balanceOf[msg.sender] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        require(validTransfer(msg.sender, _value));
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferInner(address _to, uint _value)
        private
        returns (bool success)
    {
        balanceOf[this] -= _value;
        balanceOf[_to] += _value;
        Transfer(this, _to, _value);
        return true;
    }


    function transferFrom(address _from, address _to, uint _value)
        public
        validAddress(_from)
        validAddress(_to)
        returns (bool success)
    {
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        require(allowance[_from][msg.sender] >= _value);
        require(validTransfer(_from, _value));
        balanceOf[_to] += _value;
        balanceOf[_from] -= _value;
        allowance[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint _value)
        public
        validAddress(_spender)
        returns (bool success)
    {
        require(_value == 0 || allowance[msg.sender][_spender] == 0);
        allowance[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function lock(address _to, uint _value)
        private
        validAddress(_to)
    {
        require(_value > 0);
        require(lockInfo[_to] + _value <= balanceOf[_to]);
        lockInfo[_to] += _value;
    }

    function validTransfer(address _from, uint _value)
        private
        constant
        returns (bool)
    {
        if (_value == 0)
            return false;

        if (_from == addressTeam) {
            return now >= unlockTeamTime;
        }

        if (now >= unlockTime)
            return true;

        return lockInfo[_from] + _value <= balanceOf[_from];
    }


    function ()
        public
        payable
    {
        buy();
    }

    function buy()
        public
        payable
        validEth         
        validPeriod      
        validQuantity    
    {
        uint eth = msg.value;

         
        uint quantity = eth * price / 10 ** 10;

         
        uint leftQuantity = safeSub(valueSale, saleQuantity);
        if (quantity > leftQuantity) {
            quantity = leftQuantity;
        }

        saleQuantity = safeAdd(saleQuantity, quantity);
        ethQuantity = safeAdd(ethQuantity, eth);

         
        require(transferInner(msg.sender, quantity));

         
        lock(msg.sender, quantity);

         
        Buy(msg.sender, eth, quantity);

    }

    function stopSale()
        public
        isOwner
        returns (bool)
    {
        assert(!saleStopped);
        saleStopped = true;
        StopSale();
        return true;
    }

    function getPeriod()
        public
        constant
        returns (uint)
    {
        if (saleStopped) {
            return FINISHED;
        }

        if (now < openTime) {
            return BEFORE_SALE;
        }

        if (valueSale == saleQuantity) {
            return FINISHED;
        }

        if (now >= openTime && now < closeTime) {
            return IN_SALE;
        }

        return FINISHED;
    }


    function withdraw(uint amount)
        public
        isOwner
    {
        uint period = getPeriod();
        require(period == FINISHED);

        require(this.balance >= amount);
        msg.sender.transfer(amount);
    }

    function withdrawToken(uint amount)
        public
        isOwner
    {
        uint period = getPeriod();
        require(period == FINISHED);

        withdrawQuantity += safeAdd(withdrawQuantity, amount);
        require(transferInner(msg.sender, amount));
    }

    function setVipInfo(address _vip, uint _value)
        public
        isOwner
        validAddress(_vip)
    {
        require(_value > 0);
        require(_value + totalVip <= valueVip);

        balanceOf[_vip] += _value;
        Transfer(0x0, _vip, _value);
        lock(_vip, _value);
    }

    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);

    event Buy(address indexed sender, uint eth, uint token);
    event StopSale();
}
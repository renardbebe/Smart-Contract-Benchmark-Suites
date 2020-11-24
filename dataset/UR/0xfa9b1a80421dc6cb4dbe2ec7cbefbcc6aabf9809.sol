 

pragma solidity ^0.4.18;


contract owned {
    address public owner;
    address public ownerCandidate;

    function owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        assert(owner == msg.sender);
        _;
    }

    modifier onlyOwnerCandidate() {
        assert(msg.sender == ownerCandidate);
        _;
    }

    function transferOwnership(address candidate) external onlyOwner {
        ownerCandidate = candidate;
    }

    function acceptOwnership() external onlyOwnerCandidate {
        owner = ownerCandidate;
        ownerCandidate = 0x0;
    }
}



contract SafeMath {
    function safeMul(uint a, uint b) pure internal returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function safeDiv(uint a, uint b) pure internal returns (uint) {
        uint c = a / b;
        assert(b == 0);
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


contract PEF is SafeMath, owned {

    string public name = "PEFToken";         
    string public symbol = "PEF";       
    uint public decimals = 8;            

    mapping (address => uint) public balanceOf;
    mapping (address => mapping (address => uint)) public allowance;

    uint public totalSupply = 0;


     
    address private addressTeam = 0xa011fddeF6c8814eC1D0e1554688BCa03D80086d;

     
    address private addressFund = 0x253Efa56305E127E1c3861465cD112370Ab303e0;

     
    address private addressPopular = 0x41Ef8D2A4C81Faa552aaDCE0C8A4835a0968C7ce;

     
    address private addressVip = 0x2160D166f33FD3C0750f6b57325f16df993D9CBc;

     
    uint constant valueTotal = 10 * 10000 * 10000 * 10 ** 8;   
    uint constant valueTeam = valueTotal / 100 * 20;    
    uint constant valueFund = valueTotal / 100 * 30;  
    uint constant valuePopular = valueTotal / 100 * 20;  
    uint constant valueSale = valueTotal / 100 * 20;   
    uint constant valueVip = valueTotal / 100 * 10;    


     
    bool public saleStopped = false;

     
    uint private constant BEFORE_SALE = 0;
    uint private constant IN_SALE = 1;
    uint private constant FINISHED = 2;

     
    uint public minEth = 0.1 ether;

     
    uint public maxEth = 1000 ether;

     
    uint public openTime = 1519574400;
     
    uint public closeTime = 1521907200;

     
    uint public price = 50000;

     
    uint public saleQuantity = 0;

     
    uint public ethQuantity = 0;

     
    uint public withdrawQuantity = 0;


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

    modifier validStatue {
        assert(saleStopped == false);
        _;
    }

    function setOpenTime(uint newOpenTime) public onlyOwner {
        openTime = newOpenTime;
    }

    function setCloseTime(uint newCloseTime) public onlyOwner {
        closeTime = newCloseTime;
    }

    function PEF()
        public
    {
        owner = msg.sender;
        totalSupply = valueTotal;

         
        balanceOf[this] = valueSale;
        Transfer(0x0, this, valueSale);

         
        balanceOf[addressVip] = valueVip;
        Transfer(0x0, addressVip, valueVip);

         
        balanceOf[addressFund] = valueFund;
        Transfer(0x0, addressFund, valueFund);

         
        balanceOf[addressPopular] = valuePopular;
        Transfer(0x0, addressPopular, valuePopular);

         
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
        require(validTransfer(_value));
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
        require(validTransfer(_value));
        balanceOf[_to] += _value;
        balanceOf[_from] -= _value;
        allowance[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
    }

     
    function batchtransfer(address[] _to, uint256[] _amount) public returns(bool success) {
        for(uint i = 0; i < _to.length; i++){
            require(transfer(_to[i], _amount[i]));
        }
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

    function validTransfer(uint _value)
        pure private
        returns (bool)
    {
        if (_value == 0)
            return false;

        return true;
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
        validStatue      
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

         
        Buy(msg.sender, eth, quantity);

    }

    function stopSale()
        public
        onlyOwner
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
        onlyOwner
    {
        uint period = getPeriod();
        require(period == FINISHED);

        require(this.balance >= amount);
        msg.sender.transfer(amount);
    }

     
    function withdrawToken(uint amount)
        public
        onlyOwner
    {
        uint period = getPeriod();
        require(period == FINISHED);

        withdrawQuantity += safeAdd(withdrawQuantity, amount);
        require(transferInner(msg.sender, amount));
    }



    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
    event Buy(address indexed sender, uint eth, uint token);
    event StopSale();
}
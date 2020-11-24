 

pragma solidity ^0.4.16;

 
contract SafeMath {
     
    function SafeMath() {
    }

     
    function safeAdd(uint256 _x, uint256 _y) internal returns (uint256) {
        uint256 z = _x + _y;
        assert(z >= _x);
        return z;
    }

     
    function safeSub(uint256 _x, uint256 _y) internal returns (uint256) {
        assert(_x >= _y);
        return _x - _y;
    }

     
    function safeMul(uint256 _x, uint256 _y) internal returns (uint256) {
        uint256 z = _x * _y;
        assert(_x == 0 || z / _x == _y);
        return z;
    }
}

 
contract IERC20Token {
     
    function name() public constant returns (string name) { name; }
    function symbol() public constant returns (string symbol) { symbol; }
    function decimals() public constant returns (uint8 decimals) { decimals; }
    function totalSupply() public constant returns (uint256 totalSupply) { totalSupply; }
    function balanceOf(address _owner) public constant returns (uint256 balance) { _owner; balance; }
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) { _owner; _spender; remaining; }

    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
}

 
contract COSSToken is IERC20Token, SafeMath {
    string public standard = 'COSS';
    string public name = 'COSS';
    string public symbol = 'COSS';
    uint8 public decimals = 18;
    uint256 public totalSupply = 54359820;
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;


    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    mapping (address => string) public revenueShareIdentifierList;
    mapping (address => string) public revenueShareCurrency;
    mapping (address => uint256) public revenueShareDistribution;

    uint256 public decimalMultiplier = 1000000000000000000;
    address public revenueShareOwnerAddress;
    address public icoWalletAddress = 0x0d6b5a54f940bf3d52e438cab785981aaefdf40c;
    address public futureFundingWalletAddress = 0x1e1f9b4dae157282b6be74d0e9d48cd8298ed1a8;
    address public charityWalletAddress = 0x7dbb1f2114d1bedca41f32bb43df938bcfb13e5c;
    address public capWalletAddress = 0x49a72a02c7f1e36523b74259178eadd5c3c27173;
    address public shareholdersWalletAddress = 0xda3705a572ceb85e05b29a0dc89082f1d8ab717d;
    address public investorWalletAddress = 0xa08e7f6028e7d2d83a156d7da5db6ce0615493b9;

     
    function COSSToken() {
        revenueShareOwnerAddress = msg.sender;
        balanceOf[icoWalletAddress] = safeMul(80000000,decimalMultiplier);
        balanceOf[futureFundingWalletAddress] = safeMul(50000000,decimalMultiplier);
        balanceOf[charityWalletAddress] = safeMul(10000000,decimalMultiplier);
        balanceOf[capWalletAddress] = safeMul(20000000,decimalMultiplier);
        balanceOf[shareholdersWalletAddress] = safeMul(30000000,decimalMultiplier);
        balanceOf[investorWalletAddress] = safeMul(10000000,decimalMultiplier);
    }

     
    modifier validAddress(address _address) {
        require(_address != 0x0);
        _;
    }

    function activateRevenueShareIdentifier(string _revenueShareIdentifier) {
        revenueShareIdentifierList[msg.sender] = _revenueShareIdentifier;
    }

    function addRevenueShareCurrency(address _currencyAddress,string _currencyName) {
        if (msg.sender == revenueShareOwnerAddress) {
            revenueShareCurrency[_currencyAddress] = _currencyName;
            revenueShareDistribution[_currencyAddress] = 0;
        }
    }

    function saveRevenueShareDistribution(address _currencyAddress, uint256 _value) {
        if (msg.sender == revenueShareOwnerAddress) {
            revenueShareDistribution[_currencyAddress] = safeAdd(revenueShareDistribution[_currencyAddress], _value);
        }
    }

     
    function transfer(address _to, uint256 _value)
        public
        validAddress(_to)
        returns (bool success)
    {
        balanceOf[msg.sender] = safeSub(balanceOf[msg.sender], _value);
        balanceOf[_to] = safeAdd(balanceOf[_to], _value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value)
        public
        validAddress(_from)
        validAddress(_to)
        returns (bool success)
    {
        allowance[_from][msg.sender] = safeSub(allowance[_from][msg.sender], _value);
        balanceOf[_from] = safeSub(balanceOf[_from], _value);
        balanceOf[_to] = safeAdd(balanceOf[_to], _value);
        Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value)
        public
        validAddress(_spender)
        returns (bool success)
    {
         
        require(_value == 0 || allowance[msg.sender][_spender] == 0);

        allowance[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }
}
 

pragma solidity ^0.4.24;

 

 
contract IOwned {
    function transferOwnership(address _newOwner) public;
    function acceptOwnership() public;
    function transferOwnershipNow(address newContractOwner) public;
}

 

 
contract Owned is IOwned {
    address public owner;
    address public newOwner;

    event OwnerUpdate(address indexed _prevOwner, address indexed _newOwner);

     
    constructor() public {
        owner = msg.sender;
    }

     
    modifier ownerOnly {
        require(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address _newOwner) public ownerOnly {
        require(_newOwner != owner);
        newOwner = _newOwner;
    }

     
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnerUpdate(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }

     
    function transferOwnershipNow(address newContractOwner) ownerOnly public {
        require(newContractOwner != owner);
        emit OwnerUpdate(owner, newContractOwner);
        owner = newContractOwner;
    }

}

 

 
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
}

 

 
contract IERC20 {
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

 

 
contract ISmartToken is IOwned, IERC20 {
    function disableTransfers(bool _disable) public;
    function issue(address _to, uint256 _amount) public;
    function destroy(address _from, uint256 _amount) public;
}

 

 
contract SmartToken is Owned, IERC20, ISmartToken {

     

    bool public transfersEnabled = true;     
     
    event NewSmartToken(address _token);
     
    event Issuance(uint256 _amount);
     
    event Destruction(uint256 _amount);

     
    modifier notThis(address _address) {
        require(_address != address(this));
        _;
    }

    modifier transfersAllowed {
        assert(transfersEnabled);
        _;
    }

     
    modifier validAddress(address _address) {
        require(_address != address(0));
        _;
    }

     
    function disableTransfers(bool _disable) public ownerOnly {
        transfersEnabled = !_disable;
    }

     
    function issue(address _to, uint256 _amount)
    public
    ownerOnly
    validAddress(_to)
    notThis(_to)
    {
        totalSupply = SafeMath.add(totalSupply, _amount);
        balances[_to] = SafeMath.add(balances[_to], _amount);
        emit Issuance(_amount);
        emit Transfer(this, _to, _amount);
    }

     
    function destroy(address _from, uint256 _amount) public {
        require(msg.sender == _from || msg.sender == owner);  
        balances[_from] = SafeMath.sub(balances[_from], _amount);
        totalSupply = SafeMath.sub(totalSupply, _amount);

        emit Transfer(_from, this, _amount);
        emit Destruction(_amount);
    }

     
    uint256 public totalSupply;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);


    function transfer(address _to, uint256 _value) public transfersAllowed returns (bool success) {
        if (balances[msg.sender] >= _value && _to != address(0)) {
            balances[msg.sender] = SafeMath.sub(balances[msg.sender], _value);
            balances[_to] = SafeMath.add(balances[_to], _value);
            emit Transfer(msg.sender, _to, _value);
            return true;
        } else {return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) public transfersAllowed returns (bool success) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _to != address(0)) {

            balances[_to] = SafeMath.add(balances[_to], _value);
            balances[_from] = SafeMath.sub(balances[_from], _value);
            allowed[_from][msg.sender] = SafeMath.sub(allowed[_from][msg.sender], _value);
            emit Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    string public name;
    uint8 public decimals;
    string public symbol;
    string public version;

    constructor(string _name, uint _totalSupply, uint8 _decimals, string _symbol, string _version, address sender) public {
        balances[sender] = _totalSupply;                
        totalSupply = _totalSupply;                         
        name = _name;                                    
        decimals = _decimals;                             
        symbol = _symbol;                                
        version = _version;

        emit NewSmartToken(address(this));
    }

     
    uint public saleStartTime;
    uint public saleEndTime;
    uint public price;
    uint public amountRemainingForSale;
    bool public buyModeEth = true;
    address public beneficiary;
    address public payableTokenAddress;

    event TokenSaleInitialized(uint _saleStartTime, uint _saleEndTime, uint _price, uint _amountForSale, uint nowTime);
    event TokensPurchased(address buyer, uint amount);

     
    function issuePurchase(address _to, uint256 _amount)
    internal
    validAddress(_to)
    notThis(_to)
    {
        totalSupply = SafeMath.add(totalSupply, _amount);
        balances[_to] = SafeMath.add(balances[_to], _amount);
        emit Issuance(_amount);
        emit Transfer(this, _to, _amount);
    }

     
    function initializeTokenSale(uint _saleStartTime, uint _saleEndTime, uint _price, uint _amountForSale, address _beneficiary) public ownerOnly {
         
        initializeSale(_saleStartTime, _saleEndTime, _price, _amountForSale, _beneficiary);
    }
     
    function initializeTokenSaleWithToken(uint _saleStartTime, uint _saleEndTime, uint _price, uint _amountForSale, address _beneficiary, address _tokenAddress) public ownerOnly {
        buyModeEth = false;
        payableTokenAddress = _tokenAddress;
        initializeSale(_saleStartTime, _saleEndTime, _price, _amountForSale, _beneficiary);
    }

    function initializeSale(uint _saleStartTime, uint _saleEndTime, uint _price, uint _amountForSale, address _beneficiary) internal {
         
        require(saleStartTime == 0);
        saleStartTime = _saleStartTime;
        saleEndTime = _saleEndTime;
        price = _price;
        amountRemainingForSale = _amountForSale;
        beneficiary = _beneficiary;
        emit TokenSaleInitialized(saleStartTime, saleEndTime, price, amountRemainingForSale, now);
    }

    function updateStartTime(uint _newSaleStartTime) public ownerOnly {
        saleStartTime = _newSaleStartTime;
    }

    function updateEndTime(uint _newSaleEndTime) public ownerOnly {
        require(_newSaleEndTime >= saleStartTime);
        saleEndTime = _newSaleEndTime;
    }

    function updateAmountRemainingForSale(uint _newAmountRemainingForSale) public ownerOnly {
        amountRemainingForSale = _newAmountRemainingForSale;
    }

    function updatePrice(uint _newPrice) public ownerOnly { 
        price = _newPrice;
    }

     
    function withdrawToken(IERC20 _token, uint amount) public ownerOnly {
        _token.transfer(msg.sender, amount);
    }

     
    function buyWithToken(IERC20 _token, uint amount) public payable {
        require(_token == payableTokenAddress);
        uint amountToBuy = SafeMath.mul(amount, price);
        require(amountToBuy <= amountRemainingForSale);
        require(now <= saleEndTime && now >= saleStartTime);
        amountRemainingForSale = SafeMath.sub(amountRemainingForSale, amountToBuy);
        require(_token.transferFrom(msg.sender, beneficiary, amount));
        issuePurchase(msg.sender, amountToBuy);
        emit TokensPurchased(msg.sender, amountToBuy);
    }

    function() public payable {
        require(buyModeEth == true);
        uint amountToBuy = SafeMath.div( SafeMath.mul(msg.value, 1 ether), price);
        require(amountToBuy <= amountRemainingForSale);
        require(now <= saleEndTime && now >= saleStartTime);
        amountRemainingForSale = SafeMath.sub(amountRemainingForSale, amountToBuy);
        issuePurchase(msg.sender, amountToBuy);
        beneficiary.transfer(msg.value);
        emit TokensPurchased(msg.sender, amountToBuy);
    }
}
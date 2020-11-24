 

contract Token {
     
    function totalSupply() constant returns (uint256 total);

     
     
    function balanceOf(address _owner) constant returns (uint256 balance);

     
     
     
     
    function transfer(address _to, uint256 _value) returns (bool success);

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);

     
     
     
     
    function approve(address _spender, uint256 _value) returns (bool success);

     
     
     
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract GavCoin {
    struct Receipt {
        uint units;
        uint32 activation;
    }
    struct Account {
        uint balance;
        mapping (uint => Receipt) receipt;
        mapping (address => uint) allowanceOf;
    }
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Buyin(address indexed buyer, uint indexed price, uint indexed amount);
    event Refund(address indexed buyer, uint indexed price, uint indexed amount);
    event NewTranch(uint indexed price);
    
    modifier when_owns(address _owner, uint _amount) { if (accounts[_owner].balance < _amount) return; _ }
    modifier when_has_allowance(address _owner, address _spender, uint _amount) { if (accounts[_owner].allowanceOf[_spender] < _amount) return; _ }
    modifier when_have_active_receipt(uint _price, uint _units) { if (accounts[msg.sender].receipt[_price].units < _units || now < accounts[msg.sender].receipt[_price].activation) return; _ }

    function balanceOf(address _who) constant returns (uint) { return accounts[_who].balance; }
    
    function transfer(address _to, uint256 _value) when_owns(msg.sender, _value) returns (bool success) {
        Transfer(msg.sender, _to, _value);
        accounts[msg.sender].balance -= _value;
        accounts[_to].balance += _value;
    }
    function transferFrom(address _from, address _to, uint256 _value) when_owns(_from, _value) when_has_allowance(_from, msg.sender, _value) returns (bool success) {
        Transfer(_from, _to, _value);
        accounts[_from].allowanceOf[msg.sender] -= _value;
        accounts[_from].balance -= _value;
        accounts[_to].balance += _value;
        return true;
    }
    function approve(address _spender, uint256 _value) returns (bool success) {
        Approval(msg.sender, _spender, _value);
        accounts[msg.sender].allowanceOf[_spender] += _value;
        return true;
    }
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return accounts[_owner].allowanceOf[_spender];
    }
    
     
    function() { buyinInternal(msg.sender, 2 ** 255); }

     
    function buyin(address _who, uint _maxPrice) { buyinInternal(_who, _maxPrice); }

    function refund(uint _price, uint _units) when_have_active_receipt(_price, _units) when_owns(msg.sender, _units) returns (bool) {
        Refund(msg.sender, _price, _units);
        accounts[msg.sender].balance -= _units;
        totalSupply += _units;
        accounts[msg.sender].receipt[_price].units -= _units;
        if (accounts[msg.sender].receipt[_price].units == 0)
            delete accounts[msg.sender].receipt[_price];
        if (!msg.sender.send(_units * _price / base))
            throw;
        return true;
    }

    function buyinInternal(address _who, uint _maxPrice) internal {
        var leftToSpend = msg.value;
        while (leftToSpend > 0 && price <= _maxPrice) {
             
            var maxCanSpend = price * remaining / base;
             
             
            var spend = leftToSpend > maxCanSpend ? maxCanSpend : leftToSpend;
             
            var units = spend * base / price;

             
            accounts[msg.sender].balance += units;
            accounts[msg.sender].receipt[price].units += units;
            accounts[msg.sender].receipt[price].activation = uint32(now) + refundActivationPeriod;
            totalSupply += units;
            Buyin(msg.sender, price, units);

             
            leftToSpend -= spend;
            remaining -= units;
            
             
            if (remaining == 0) {
                 
                price += tranchStep;
                remaining = tokensPerTranch * base;
                NewTranch(price);
            }
        }
    }
    
    uint public totalSupply;
    mapping (address => Account) accounts;
    
    uint constant base = 1000000;                
    uint constant tranchStep = 1 finney;         
    uint constant tokensPerTranch = 100;         
    uint public price = 1 finney;                
    uint public remaining = tokensPerTranch * base;
    uint32 constant refundActivationPeriod = 7 days;
}
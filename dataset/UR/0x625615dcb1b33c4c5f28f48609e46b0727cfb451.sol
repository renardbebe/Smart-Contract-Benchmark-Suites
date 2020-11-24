 

pragma solidity ^0.4.11;

contract SafeMath {

    function safeMul(uint256 a, uint256 b) internal constant returns (uint256 ) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function safeDiv(uint256 a, uint256 b) internal constant returns (uint256 ) {
        assert(b > 0);
        uint256 c = a / b;
        assert(a == b * c + a % b);
        return c;
    }

    function safeSub(uint256 a, uint256 b) internal constant returns (uint256 ) {
        assert(b <= a);
        return a - b;
    }

    function safeAdd(uint256 a, uint256 b) internal constant returns (uint256 ) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract ERC20 {

     
     
    uint256 public totalSupply;

     
     
    function balanceOf(address _owner) public constant returns (uint256 balance);

     
     
     
     
    function transfer(address _to, uint256 _value) public returns (bool success);

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

     
     
     
     
    function approve(address _spender, uint256 _value) public returns (bool success);

     
     
     
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract StandardToken is ERC20, SafeMath {

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

     
     
    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }

     
     
     
    function transfer(address _to, uint256 _value) public returns (bool) {
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] = safeSub(balances[msg.sender], _value);
            balances[_to] = safeAdd(balances[_to], _value);
            Transfer(msg.sender, _to, _value);
            return true;
        } else return false;
    }

     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] = safeAdd(balances[_to], _value);
            balances[_from] = safeSub(balances[_from], _value);
            allowed[_from][msg.sender] = safeSub(allowed[_from][msg.sender], _value);
            Transfer(_from, _to, _value);
            return true;
        } else return false;
    }

     
     
     
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

     
     
     
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
}

contract MultiOwnable {

    mapping (address => bool) ownerMap;
    address[] public owners;

    event OwnerAdded(address indexed _newOwner);
    event OwnerRemoved(address indexed _oldOwner);

    modifier onlyOwner() {
        require(isOwner(msg.sender));
        _;
    }

    function MultiOwnable() {
         
        address owner = msg.sender;
        ownerMap[owner] = true;
        owners.push(owner);
    }

    function ownerCount() public constant returns (uint256) {
        return owners.length;
    }

    function isOwner(address owner) public constant returns (bool) {
        return ownerMap[owner];
    }

    function addOwner(address owner) onlyOwner public returns (bool) {
        if (!isOwner(owner) && owner != 0) {
            ownerMap[owner] = true;
            owners.push(owner);

            OwnerAdded(owner);
            return true;
        } else return false;
    }

    function removeOwner(address owner) onlyOwner public returns (bool) {
        if (isOwner(owner)) {
            ownerMap[owner] = false;
            for (uint i = 0; i < owners.length - 1; i++) {
                if (owners[i] == owner) {
                    owners[i] = owners[owners.length - 1];
                    break;
                }
            }
            owners.length -= 1;

            OwnerRemoved(owner);
            return true;
        } else return false;
    }
}

contract TokenSpender {
    function receiveApproval(address _from, uint256 _value);
}

contract CommonBsToken is StandardToken, MultiOwnable {

    string public name;
    string public symbol;
    uint256 public totalSupply;
    uint8 public decimals = 18;
    string public version = 'v0.1';

    address public creator;
    address public seller;      

    uint256 public saleLimit;   
    uint256 public tokensSold;  
    uint256 public totalSales;  

    bool public locked;

    event Sell(address indexed _seller, address indexed _buyer, uint256 _value);
    event SellerChanged(address indexed _oldSeller, address indexed _newSeller);

    event Lock();
    event Unlock();

    event Burn(address indexed _burner, uint256 _value);

    modifier onlyUnlocked() {
        if (!isOwner(msg.sender) && locked) throw;
        _;
    }

    function CommonBsToken(
        address _seller,
        string _name,
        string _symbol,
        uint256 _totalSupplyNoDecimals,
        uint256 _saleLimitNoDecimals
    ) MultiOwnable() {

         
        locked = true;

        creator = msg.sender;
        seller = _seller;

        name = _name;
        symbol = _symbol;
        totalSupply = _totalSupplyNoDecimals * 1e18;
        saleLimit = _saleLimitNoDecimals * 1e18;

        balances[seller] = totalSupply;
        Transfer(0x0, seller, totalSupply);
    }

    function changeSeller(address newSeller) onlyOwner public returns (bool) {
        require(newSeller != 0x0 && seller != newSeller);

        address oldSeller = seller;
        uint256 unsoldTokens = balances[oldSeller];
        balances[oldSeller] = 0;
        balances[newSeller] = safeAdd(balances[newSeller], unsoldTokens);
        Transfer(oldSeller, newSeller, unsoldTokens);

        seller = newSeller;
        SellerChanged(oldSeller, newSeller);
        return true;
    }

    function sellNoDecimals(address _to, uint256 _value) public returns (bool) {
        return sell(_to, _value * 1e18);
    }

    function sell(address _to, uint256 _value) onlyOwner public returns (bool) {

         
        if (saleLimit > 0) require(safeSub(saleLimit, safeAdd(tokensSold, _value)) >= 0);

        require(_to != address(0));
        require(_value > 0);
        require(_value <= balances[seller]);

        balances[seller] = safeSub(balances[seller], _value);
        balances[_to] = safeAdd(balances[_to], _value);
        Transfer(seller, _to, _value);

        tokensSold = safeAdd(tokensSold, _value);
        totalSales = safeAdd(totalSales, 1);
        Sell(seller, _to, _value);

        return true;
    }

    function transfer(address _to, uint256 _value) onlyUnlocked public returns (bool) {
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) onlyUnlocked public returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

    function lock() onlyOwner public {
        locked = true;
        Lock();
    }

    function unlock() onlyOwner public {
        locked = false;
        Unlock();
    }

    function burn(uint256 _value) public returns (bool) {
        require(_value > 0);
        require(_value <= balances[msg.sender]);

        balances[msg.sender] = safeSub(balances[msg.sender], _value) ;
        totalSupply = safeSub(totalSupply, _value);
        Transfer(msg.sender, 0x0, _value);
        Burn(msg.sender, _value);

        return true;
    }

     
    function approveAndCall(address _spender, uint256 _value) public {
        TokenSpender spender = TokenSpender(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value);
        }
    }
}

contract XToken is CommonBsToken {

    function XToken() public CommonBsToken(
        0xE3E9F66E5Ebe9E961662da34FF9aEA95c6795fd0,      
        'X full',
        'X short',
        100 * 1e6,  
        40 * 1e6    
    ) { }
}
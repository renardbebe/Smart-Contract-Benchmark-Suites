 

pragma solidity ^0.4.20;


pragma solidity ^0.4.15;

 
library SafeMath {

     
    function add(uint256 x, uint256 y)
    internal constant
    returns(uint256) {
        uint256 z = x + y;
        assert((z >= x) && (z >= y));
        return z;
    }

     
    function sub(uint256 x, uint256 y)
    internal constant
    returns(uint256) {
        assert(x >= y);
        uint256 z = x - y;
        return z;
    }

     
    function mul(uint256 x, uint256 y)
    internal constant
    returns(uint256) {
        uint256 z = x * y;
        assert((x == 0) || (z/x == y));
        return z;
    }

     
    function parse(string s) 
    internal constant 
    returns (uint256) 
    {
    bytes memory b = bytes(s);
    uint result = 0;
    for (uint i = 0; i < b.length; i++) {
        if (b[i] >= 48 && b[i] <= 57) {
            result = result * 10 + (uint(b[i]) - 48); 
        }
    }
    return result; 
}
}


 
contract Token {
     
    uint256 public totalSupply;

    function balanceOf(address _owner) public constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);

     
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

     
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

 
contract StandardToken is Token {

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    modifier onlyPayloadSize(uint numwords) {
        assert(msg.data.length == numwords * 32 + 4);
        _;
    }

     
    function transfer(address _to, uint256 _value)
    public
    returns (bool success) {
        if (balances[msg.sender] >= _value && _value > 0 && balances[_to] + _value > balances[_to]) {
            balances[msg.sender] = SafeMath.sub(balances[msg.sender], _value);
            balances[_to] = SafeMath.add(balances[_to], _value);
            Transfer(msg.sender, _to, _value);
            return true;
        } else {
            return false;
        }
    }

     
    function transferFrom(address _from, address _to, uint256 _value)
    public
    returns (bool success) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0 && balances[_to] + _value > balances[_to]) {
            balances[_to] = SafeMath.add(balances[_to], _value);
            balances[_from] = SafeMath.sub(balances[_from], _value);
            allowed[_from][msg.sender] = SafeMath.sub(allowed[_from][msg.sender], _value);
            Transfer(_from, _to, _value);
            return true;
        } else {
            return false;
        }
    }

     
    function balanceOf(address _owner)
    public constant
    returns (uint256 balance) {
        return balances[_owner];
    }

     
    function approve(address _spender, uint256 _value)
    public
    onlyPayloadSize(2)
    returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(address _owner, address _spender)
    public constant
    onlyPayloadSize(2)
    returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
}


 
  
contract LCDToken is StandardToken {

     
    string public constant name = "Lucyd";
    string public constant symbol = "LCD";
    uint256 public constant decimals = 18;

    uint256 public constant TOKEN_COMPANY_OWNED = 10 * (10**6) * 10**decimals;  
    uint256 public constant TOKEN_MINTING = 30 * (10**6) * 10**decimals;        
    uint256 public constant TOKEN_BUSINESS = 10 * (10**6) * 10**decimals;        

     
    address public APP_STORE;

     
    address public admin1;
    address public admin2;

     
    address public tokenVendor1;
    address public tokenVendor2;

     
    mapping (address => bool) public isHolder;  
    address[] public holders;                   

     
    mapping (address => bytes32) private multiSigHashes;

     
    bool public managementTokensDelivered;

     
    uint256 public tokensSold;

     
    event LogLCDTokensDelivered(address indexed _to, uint256 _value);
    event LogManagementTokensDelivered(address indexed distributor, uint256 _value);
    event Auth(string indexed authString, address indexed user);

    modifier onlyOwner() {
         
        require (msg.sender == admin1 || msg.sender == admin2);
         
        multiSigHashes[msg.sender] = keccak256(msg.data);
         
        if ((multiSigHashes[admin1]) == (multiSigHashes[admin2])) {
             
            _;

             
            multiSigHashes[admin1] = 0x0;
            multiSigHashes[admin2] = 0x0;
        } else {
             
            return;
        }
    }

    modifier onlyVendor() {
        require((msg.sender == tokenVendor1) || (msg.sender == tokenVendor2));
        _;
    }

     
    function LCDToken(
        address _admin1,
        address _admin2,
        address _tokenVendor1,
        address _tokenVendor2,
        address _appStore,
        address _business_development)
    public
    {
         
        require (_admin1 != 0x0);
        require (_admin2 != 0x0);
        require (_admin1 != _admin2);

         
        require (_tokenVendor1 != 0x0);
        require (_tokenVendor2 != 0x0);
        require (_tokenVendor1 != _tokenVendor2);

         
        require (_tokenVendor1 != _admin1);
        require (_tokenVendor1 != _admin2);
        require (_tokenVendor2 != _admin1);
        require (_tokenVendor2 != _admin2);
        require (_appStore != 0x0);

        admin1 = _admin1;
        admin2 = _admin2;
        tokenVendor1 = _tokenVendor1;
        tokenVendor2 = _tokenVendor2;

         
        APP_STORE = _appStore;
        balances[_appStore] = TOKEN_MINTING;
        trackHolder(_appStore);

         
        balances[_admin1] = TOKEN_BUSINESS;
        trackHolder(_business_development);

        totalSupply = SafeMath.add(TOKEN_MINTING, TOKEN_BUSINESS);
    }

     
    function getHolderCount()
    public
    constant
    returns (uint256 _holderCount)
    {
        return holders.length;
    }

     
    function getHolder(uint256 _index)
    public
    constant
    returns (address _holder)
    {
        return holders[_index];
    }

    function trackHolder(address _to)
    private
    returns (bool success)
    {
         
        if (isHolder[_to] == false) {
             
            holders.push(_to);
            isHolder[_to] = true;
        }
        return true;
    }

     
    function deliverTokens(address _buyer, uint256 _amount)  
    external
    onlyVendor
    returns(bool success)
    {
         
        require(block.timestamp <= 1525125600);

         
        uint256 tokens = SafeMath.mul(_amount, 10**decimals / 100);

         
        uint256 oldBalance = balances[_buyer];
        balances[_buyer] = SafeMath.add(oldBalance, tokens);
        tokensSold = SafeMath.add(tokensSold, tokens);
        totalSupply = SafeMath.add(totalSupply, tokens);
        trackHolder(_buyer);

         
        Transfer(msg.sender, _buyer, tokens);
        LogLCDTokensDelivered(_buyer, tokens);
        return true;
    }

     
    function deliverManagementTokens(address _managementWallet)
    external
    onlyOwner
    returns (bool success)
    {
         
        require(block.timestamp >= 1553990400);

         
        require(managementTokensDelivered == false);

         
        balances[_managementWallet] = TOKEN_COMPANY_OWNED;
        totalSupply = SafeMath.add(totalSupply, TOKEN_COMPANY_OWNED);
        managementTokensDelivered = true;
        trackHolder(_managementWallet);

         
        Transfer(address(this), _managementWallet, TOKEN_COMPANY_OWNED);
        LogManagementTokensDelivered(_managementWallet, TOKEN_COMPANY_OWNED);
        return true;
    }

     
    function auth(string _authString)
    external
    {
        Auth(_authString, msg.sender);
    }
}
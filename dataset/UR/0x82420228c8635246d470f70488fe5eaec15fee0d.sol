 

pragma solidity ^0.4.12;

 

 
 

contract Token {
     
     
    uint256 public totalSupply;

     
     
    function balanceOf(address _owner) constant returns (uint256 balance);

     
     
     
     
    function transfer(address _to, uint256 _value) returns (bool success);

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);

     
     
     
     
    function approve(address _spender, uint256 _value) returns (bool success);

     
     
     
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


/* Implements ERC 20 Token standard: https: 

contract ERC20 is Token {

    function transfer(address _to, uint256 _value) returns (bool success) {
        require(balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]);
        balances[_to] += _value;
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    mapping (address => uint256) public balances;  
    mapping (address => mapping (address => uint256)) public allowed;  
}

contract EmpowCreateEosAccount {
    
    event CreateEosAccountEvent(string _name, string _activePublicKey, string _ownerPublicKey);
    
    struct AccountHistory {
        uint32 payment_type;
        string name;
        string activePublicKey;
        string ownerPublicKey;
        uint256 amount;
    }
    
    mapping (address => uint256) public countAccount;
    mapping (address => mapping (uint256 => AccountHistory)) public accountHistories;
    
    uint256 public PRICE = 144000000;
    uint256 public USDT_PRICE = 3000000;
    uint256 public NAME_LENGTH_LIMIT = 12;
    uint256 public PUBLIC_KEY_LENGTH_LIMIT = 53;
    address public owner;
    address public USDTAddress;
    
    modifier onlyOwner () {
        require(msg.sender == owner);
        _;
    }
    
    function EmpowCreateEosAccount ()
        public
    {
        owner = msg.sender;
    }
    
    function createEosAccount(string memory _name, string memory _activePublicKey, string memory _ownerPublicKey)
        public
        payable
        returns (bool)
    {
         
        require(getStringLength(_name) == NAME_LENGTH_LIMIT);
         
        require(getStringLength(_activePublicKey) == PUBLIC_KEY_LENGTH_LIMIT);
        require(getStringLength(_ownerPublicKey) == PUBLIC_KEY_LENGTH_LIMIT);
         
        require(msg.value >= PRICE);
        
         
        accountHistories[msg.sender][countAccount[msg.sender]].payment_type = 0;  
        accountHistories[msg.sender][countAccount[msg.sender]].name = _name;
        accountHistories[msg.sender][countAccount[msg.sender]].activePublicKey = _activePublicKey;
        accountHistories[msg.sender][countAccount[msg.sender]].ownerPublicKey = _ownerPublicKey;
        accountHistories[msg.sender][countAccount[msg.sender]].amount = msg.value;
        countAccount[msg.sender]++;
        
         
        CreateEosAccountEvent(_name, _activePublicKey, _ownerPublicKey);
        return true;
    }
    
    function createEosAccountWithUSDT(string memory _name, string memory _activePublicKey, string memory _ownerPublicKey)
        public
        returns (bool)
    {
          
        require(getStringLength(_name) == NAME_LENGTH_LIMIT);
         
        require(getStringLength(_activePublicKey) == PUBLIC_KEY_LENGTH_LIMIT);
        require(getStringLength(_ownerPublicKey) == PUBLIC_KEY_LENGTH_LIMIT);
         
        require(ERC20(USDTAddress).transferFrom(msg.sender, owner, USDT_PRICE));
         
        accountHistories[msg.sender][countAccount[msg.sender]].payment_type = 1;  
        accountHistories[msg.sender][countAccount[msg.sender]].name = _name;
        accountHistories[msg.sender][countAccount[msg.sender]].activePublicKey = _activePublicKey;
        accountHistories[msg.sender][countAccount[msg.sender]].ownerPublicKey = _ownerPublicKey;
        accountHistories[msg.sender][countAccount[msg.sender]].amount = USDT_PRICE;
        countAccount[msg.sender]++;
        
         
        CreateEosAccountEvent(_name, _activePublicKey, _ownerPublicKey);
        return true;
    }
    
     
    
    function updateUSDTAddress (address _address) 
        public
        onlyOwner
        returns (bool)
    {
        USDTAddress = _address;
        return true;
    }
    
    function setPrice (uint256 _price, uint256 _usdtPrice)
        public
        onlyOwner
        returns (bool)
    {
        PRICE = _price;
        USDT_PRICE = _usdtPrice;
        return true;
    }
    
    function ownerWithdraw (uint256 _amount)
        public
        onlyOwner
        returns (bool)
    {
        owner.transfer(_amount);
        return true;
    }

     
    function getStringLength (string memory _string)
        private
        returns (uint256)
    {
        bytes memory stringBytes = bytes(_string);
        return stringBytes.length;
    }
}
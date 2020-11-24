 

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

contract EmpowBonus {
    
    event Bonus(address indexed _address, uint32 indexed dapp_id, uint256 _time, uint256 _bonus_amount, uint256 _pay_amount);
    
    struct BonusHistory {
        address user;
        uint32 dapp_id;
        uint256 time;
        uint32 pay_type;
        uint256 bonus_amount;
        uint256 pay_amount;
    }
    
    mapping (address => uint256) public countBonus;
    mapping (address => mapping (uint256 => BonusHistory)) public bonusHistories;
    
    address public owner;
    address public USDTAddress;
    
    modifier onlyOwner () {
        require(msg.sender == owner);
        _;
    }
    
    function EmpowBonus ()
        public
    {
        owner = msg.sender;
    }
    
    function bonus (uint32 _dapp_id, uint256 _bonus_amount)
        public
        payable
        returns(bool)
    {
        require(msg.value > 0);
        
        countBonus[msg.sender]++;
        
        uint256 currentTime = block.timestamp;
        
        Bonus(msg.sender, _dapp_id, 0, _bonus_amount, msg.value);
        saveHistory(msg.sender, _dapp_id, currentTime, 0, _bonus_amount, msg.value);  
        
        return true;
    }
    
    function bonusWithUsdt (uint32 _dapp_id, uint256 _bonus_amount, uint256 _amount_usdt)
        public
        returns(bool)
    {
        require(_amount_usdt > 0);
         
        require(ERC20(USDTAddress).transferFrom(msg.sender, owner, _amount_usdt));
        
        countBonus[msg.sender]++;
        
        uint256 currentTime = block.timestamp;
        
        Bonus(msg.sender, _dapp_id, 1, _bonus_amount, _amount_usdt);
        saveHistory(msg.sender, _dapp_id, currentTime, 1, _bonus_amount, _amount_usdt);  
    }
    
    function saveHistory (address _address, uint32 _dapp_id, uint256 _time, uint32 _pay_type, uint256 _bonus_amount, uint256 _pay_amount)
        private
        returns(bool)
    {
        bonusHistories[msg.sender][countBonus[_address]].user = _address;
        bonusHistories[msg.sender][countBonus[_address]].dapp_id = _dapp_id;
        bonusHistories[msg.sender][countBonus[_address]].time = _time;
        bonusHistories[msg.sender][countBonus[_address]].pay_type = _pay_type;
        bonusHistories[msg.sender][countBonus[_address]].bonus_amount = _bonus_amount;
        bonusHistories[msg.sender][countBonus[_address]].pay_amount = _pay_amount;
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
    
    function withdraw (uint256 _amount) 
        public
        onlyOwner
        returns (bool)
    {
        owner.transfer(_amount);
        return true;
    }
}
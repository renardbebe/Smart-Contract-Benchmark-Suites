 

pragma solidity ^0.4.24;

contract Token{
     
    uint256 public totalSupply;

     
    function balanceOf(address _owner) constant returns (uint256 balance);

     
    function transfer(address _to, uint256 _value) returns (bool success);

     
    function transferFrom(address _from, address _to, uint256 _value) returns   
    (bool success);

     
    function approve(address _spender, uint256 _value) returns (bool success);

     
    function allowance(address _owner, address _spender) constant returns 
    (uint256 remaining);

     
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

     
    event Approval(address indexed _owner, address indexed _spender, uint256 
    _value);
}

contract StandardToken is Token {
    function transfer(address _to, uint256 _value) returns (bool success) {
         
         
         
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value; 
        balances[_to] += _value; 
        Transfer(msg.sender, _to, _value); 
        return true;
    }


    function transferFrom(address _from, address _to, uint256 _value) returns 
    (bool success) {
         
         
        require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value);
        balances[_to] += _value; 
        balances[_from] -= _value;  
        allowed[_from][msg.sender] -= _value; 
        Transfer(_from, _to, _value); 
        return true;
    }
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }


    function approve(address _spender, uint256 _value) returns (bool success)   
    {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }


    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender]; 
    }
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
}

 
contract MUSD is StandardToken{
    
    address public admin;  
    string public name = "CHINA MOROCCO MERCANTILE EXCHANGE";  
    string public symbol = "MUSD";  
    uint8 public decimals = 18;  
    uint256 public INITIAL_SUPPLY = 10000000000000000000000000;  
     
    mapping (address => bool) public frozenAccount;  
    mapping (address => uint256) public frozenTimestamp;  

    bool public exchangeFlag = true;  
     
    uint256 public minWei = 1;   
    uint256 public maxWei = 20000000000000000000000;  
    uint256 public maxRaiseAmount = 20000000000000000000000;  
    uint256 public raisedAmount = 0;  
    uint256 public raiseRatio = 200000;  
     
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    constructor() public {
        totalSupply = INITIAL_SUPPLY;
        admin = msg.sender;
        balances[msg.sender] = INITIAL_SUPPLY;
    }

     
     
    function()
    public payable {
        require(msg.value > 0);
        if (exchangeFlag) {
            if (msg.value >= minWei && msg.value <= maxWei){
                if (raisedAmount < maxRaiseAmount) {
                    uint256 valueNeed = msg.value;
                    raisedAmount = raisedAmount + msg.value;
                    if (raisedAmount > maxRaiseAmount) {
                        uint256 valueLeft = raisedAmount - maxRaiseAmount;
                        valueNeed = msg.value - valueLeft;
                        msg.sender.transfer(valueLeft);
                        raisedAmount = maxRaiseAmount;
                    }
                    if (raisedAmount >= maxRaiseAmount) {
                        exchangeFlag = false;
                    }
                     
                    uint256 _value = valueNeed * raiseRatio;

                    require(_value <= balances[admin]);
                    balances[admin] = balances[admin] - _value;
                    balances[msg.sender] = balances[msg.sender] + _value;

                    emit Transfer(admin, msg.sender, _value);

                }
            } else {
                msg.sender.transfer(msg.value);
            }
        } else {
            msg.sender.transfer(msg.value);
        }
    }

     
    function changeAdmin(
        address _newAdmin
    )
    public
    returns (bool)  {
        require(msg.sender == admin);
        require(_newAdmin != address(0));
        balances[_newAdmin] = balances[_newAdmin] + balances[admin];
        balances[admin] = 0;
        admin = _newAdmin;
        return true;
    }
     
    function generateToken(
        address _target,
        uint256 _amount
    )
    public
    returns (bool)  {
        require(msg.sender == admin);
        require(_target != address(0));
        balances[_target] = balances[_target] + _amount;
        totalSupply = totalSupply + _amount;
        INITIAL_SUPPLY = totalSupply;
        return true;
    }

     
     
    function withdraw (
        uint256 _amount
    )
    public
    returns (bool) {
        require(msg.sender == admin);
        msg.sender.transfer(_amount);
        return true;
    }
     
    function freeze(
        address _target,
        bool _freeze
    )
    public
    returns (bool) {
        require(msg.sender == admin);
        require(_target != address(0));
        frozenAccount[_target] = _freeze;
        return true;
    }
     
    function freezeWithTimestamp(
        address _target,
        uint256 _timestamp
    )
    public
    returns (bool) {
        require(msg.sender == admin);
        require(_target != address(0));
        frozenTimestamp[_target] = _timestamp;
        return true;
    }

     
    function multiFreeze(
        address[] _targets,
        bool[] _freezes
    )
    public
    returns (bool) {
        require(msg.sender == admin);
        require(_targets.length == _freezes.length);
        uint256 len = _targets.length;
        require(len > 0);
        for (uint256 i = 0; i < len; i += 1) {
            address _target = _targets[i];
            require(_target != address(0));
            bool _freeze = _freezes[i];
            frozenAccount[_target] = _freeze;
        }
        return true;
    }
     
    function multiFreezeWithTimestamp(
        address[] _targets,
        uint256[] _timestamps
    )
    public
    returns (bool) {
        require(msg.sender == admin);
        require(_targets.length == _timestamps.length);
        uint256 len = _targets.length;
        require(len > 0);
        for (uint256 i = 0; i < len; i += 1) {
            address _target = _targets[i];
            require(_target != address(0));
            uint256 _timestamp = _timestamps[i];
            frozenTimestamp[_target] = _timestamp;
        }
        return true;
    }
     
    function multiTransfer(
        address[] _tos,
        uint256[] _values
    )
    public
    returns (bool) {
        require(!frozenAccount[msg.sender]);
        require(now > frozenTimestamp[msg.sender]);
        require(_tos.length == _values.length);
        uint256 len = _tos.length;
        require(len > 0);
        uint256 amount = 0;
        for (uint256 i = 0; i < len; i += 1) {
            amount = amount + _values[i];
        }
        require(amount <= balances[msg.sender]);
        for (uint256 j = 0; j < len; j += 1) {
            address _to = _tos[j];
            require(_to != address(0));
            balances[_to] = balances[_to] + _values[j];
            balances[msg.sender] = balances[msg.sender] - _values[j];
            emit Transfer(msg.sender, _to, _values[j]);
        }
        return true;
    }
     
    function transfer(
        address _to,
        uint256 _value
    )
    public
    returns (bool) {
        require(!frozenAccount[msg.sender]);
        require(now > frozenTimestamp[msg.sender]);
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender] - _value;
        balances[_to] = balances[_to] + _value;

        emit Transfer(msg.sender, _to, _value);
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
        require(!frozenAccount[_from]);
        require(now > frozenTimestamp[msg.sender]);
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from] - _value;
        balances[_to] = balances[_to] + _value;
        allowed[_from][msg.sender] = allowed[_from][msg.sender] - _value;

        emit Transfer(_from, _to, _value);
        return true;
    }
     
    function approve(
        address _spender,
        uint256 _value
    ) public
    returns (bool) {
         
         

        allowed[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);
        return true;
    }
     
    function increaseApproval(
        address _spender,
        uint256 _addedValue
    )
    public
    returns (bool)
    {
         
         
         

         
        return true;
    }
     
    function decreaseApproval(
        address _spender,
        uint256 _subtractedValue
    )
    public
    returns (bool)
    {
         
         
         
         
         
         
         
         

         
        return true;
    }

     
     
    function getFrozenTimestamp(
        address _target
    )
    public view
    returns (uint256) {
        require(_target != address(0));
        return frozenTimestamp[_target];
    }
     
    function getFrozenAccount(
        address _target
    )
    public view
    returns (bool) {
        require(_target != address(0));
        return frozenAccount[_target];
    }
     
    function getBalance()
    public view
    returns (uint256) {
        return address(this).balance;
    }
     
    function setName (
        string _value
    )
    public
    returns (bool) {
        require(msg.sender == admin);
        name = _value;
        return true;
    }
     
    function setSymbol (
        string _value
    )
    public
    returns (bool) {
        require(msg.sender == admin);
        symbol = _value;
        return true;
    }

     
    function setExchangeFlag (
        bool _flag
    )
    public
    returns (bool) {
        require(msg.sender == admin);
        exchangeFlag = _flag;
        return true;

    }
     
    function setMinWei (
        uint256 _value
    )
    public
    returns (bool) {
        require(msg.sender == admin);
        minWei = _value;
        return true;

    }
     
    function setMaxWei (
        uint256 _value
    )
    public
    returns (bool) {
        require(msg.sender == admin);
        maxWei = _value;
        return true;
    }
     
    function setMaxRaiseAmount (
        uint256 _value
    )
    public
    returns (bool) {
        require(msg.sender == admin);
        maxRaiseAmount = _value;
        return true;
    }

     
    function setRaisedAmount (
        uint256 _value
    )
    public
    returns (bool) {
        require(msg.sender == admin);
        raisedAmount = _value;
        return true;
    }

     
    function setRaiseRatio (
        uint256 _value
    )
    public
    returns (bool) {
        require(msg.sender == admin);
        raiseRatio = _value;
        return true;
    }

     
    function kill()
    public {
        require(msg.sender == admin);
        selfdestruct(admin);
    }

}
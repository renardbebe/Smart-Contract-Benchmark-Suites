 

pragma solidity ^0.4.16;

contract owned {
    address public owner;
    function owned() public {
        owner = msg.sender;
    }
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    function transferOwnership(address _newOwner) onlyOwner public {
        owner = _newOwner;
    }
}

contract GOG is owned {
     
    string public name;
    string public symbol;
    uint8 public decimals = 6;
     
    uint256 public totalSupply;

     
    mapping (address => uint256) public balances;
     
    mapping (address => mapping (address => uint256)) public allowance;
     
    mapping (address => uint256) public frozenFunds;
     
    event FrozenFunds(address target, uint256 funds);
         
    event UnFrozenFunds(address target, uint256 funds);
     
    event Transfer(address indexed from, address indexed to, uint256 value);
     
    event Burn(address indexed from, uint256 value);
     
    event Approval(address indexed owner, address indexed spender, uint256 value);

     
    function GOG() public {
        totalSupply = 10000000000000000;                
        balances[msg.sender] = totalSupply;           
        name = "GoGlobe Token";                        
        symbol = "GOG";                                
    }

     
    function freezeAccount(address _target, uint256 _funds) public onlyOwner {
        if (_funds == 0x0)
            frozenFunds[_target] = balances[_target];
        else
            frozenFunds[_target] = _funds;
        FrozenFunds(_target, _funds);
    }

     
    function unFreezeAccount(address _target, uint256 _funds) public onlyOwner {
        require(_funds > 0x0);
        uint256 temp = frozenFunds[_target];
        temp = temp < _funds ? 0x0 : temp - _funds;
        frozenFunds[_target] = temp;
        UnFrozenFunds(_target, _funds);
    }

     
    function balanceOf(address _owner) constant public returns (uint256) {
        return balances[_owner];
    }

     
    function frozenFundsOf(address _owner) constant public returns (uint256) {
        return frozenFunds[_owner];
    }

     
    function approve(address _spender, uint256 _value) public returns (bool) {
        require((_value == 0) || (allowance[msg.sender][_spender] == 0));
        allowance[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(address _owner, address _spender) constant public returns (uint256) {
        return allowance[_owner][_spender];
    }

     
    function _transfer(address _from, address _to, uint _value) internal {
         
        require(_to != 0x0);

         
        require(balances[_from] > frozenFunds[_from]);
        require((balances[_from] - frozenFunds[_from]) >= _value);
         
        require(balances[_to] + _value > balances[_to]);
         
        uint previousBalances = balances[_from] + balances[_to];
         
        balances[_from] -= _value;
         
        balances[_to] += _value;
        Transfer(_from, _to, _value);
         
        assert(balances[_from] + balances[_to] == previousBalances);
    }

     
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_value <= allowance[_from][msg.sender]);      
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

     
    function burn(uint256 _value) public returns (bool) {
        require(balances[msg.sender] >= _value);    
        balances[msg.sender] -= _value;             
        totalSupply -= _value;                       
        Burn(msg.sender, _value);
        return true;
    }

     
    function burnFrom(address _from, uint256 _value) public returns (bool) {
        require(balances[_from] >= _value);                 
        require(_value <= allowance[_from][msg.sender]);     
        balances[_from] -= _value;                          
        allowance[_from][msg.sender] -= _value;              
        totalSupply -= _value;                               
        Burn(_from, _value);
        return true;
    }
}
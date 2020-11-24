 

pragma solidity ^0.4.8;


 
contract ERC20 {
     
    uint public totalSupply;
     
    function balanceOf(address who) constant returns(uint256);
     
    function transfer(address to, uint value) returns(bool ok);
     
    function transferFrom(address from, address to, uint value) returns(bool ok);
     
     
     
    function approve(address spender, uint value) returns(bool ok);
     
    function allowance(address owner, address spender) constant returns(uint);
     
    event Transfer(address indexed from, address indexed to, uint value);
     
    event Approval(address indexed owner, address indexed spender, uint value);

}


contract FuBi is ERC20 {

     
    mapping (address => uint256) balances;   
     
    mapping (address => bool) public frozenAccount;  

     

     
    address public owner;
     
    string public name = "FuBi";  
     
    string public symbol = "Fu";  
     
    uint8 public decimals = 6;    
     
    uint256 public totalSupply = 20000000000000000;  
     
    event Transfer(address indexed from, address indexed to, uint256 value);
     
    event FrozenFu(address target, bool frozen);

    mapping(address => mapping(address => uint256)) public allowance;
    
    bool flag = false;

     
    modifier onlyOwner()
    {
        if (msg.sender != owner) revert();
        _;
    }

     
    function FuBi() { 
        owner = msg.sender;        
        balances[owner] = totalSupply;  
        }    

     
    function balanceOf(address _owner) constant returns (uint256 balance)
    {
        return balances[_owner];
    }
     
    function transfer(address _to, uint _value) returns (bool success)
    {
          
        if(_value <= 0) throw;                                     
         
        if (balances[msg.sender] < _value) throw;                   
         
        if (balances[_to] + _value < balances[_to]) throw; 
         
        balances[msg.sender] -= _value;                             
         
        balances[_to] += _value;                                    
         
        Transfer(msg.sender, _to, _value);                          
        return true;      
    }
    
     
    function approve(address _spender, uint256 _value)
    returns(bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }
     
    function allowance(address _owner, address _spender) constant returns(uint256 remaining) {
        return allowance[_owner][_spender];
    }

     
    function transferFrom(address _from, address _to, uint _value) returns(bool success) {
        if (_to == 0x0) throw;  
        if (balances[_from] < _value) throw;  
        if (balances[_to] + _value < balances[_to]) throw;  
        if (_value > allowance[_from][msg.sender]) throw;  

        balances[_from] -= _value;  
        balances[_to] += _value;  
        allowance[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
    }

     
    function mint(address _to, uint256 _value) onlyOwner
    {
        if(!flag)
        {
        balances[_to] += _value;
    	totalSupply += _value;
        }
        else
        revert();
    }

    
    function freeze(address target, bool freeze) onlyOwner
    {
        if(!flag)
        {
        frozenAccount[target] = freeze;
        FrozenFu(target,freeze);  
        }
        else
        revert();
    }
    
   function transferOwnership(address to) public onlyOwner {
         owner = to;
         balances[owner]=balances[msg.sender];
         balances[msg.sender]=0;
    }
     
    function turn_flag_ON() onlyOwner
    {
        flag = true;
    }
     
    function turn_flag_OFF() onlyOwner
    {
        flag = false;
    }
     
    function drain() public onlyOwner {
        if (!owner.send(this.balance)) throw;
    }
}
 

pragma solidity ^0.4.8;

contract ERC20 {

    uint public totalSupply;

    function totalSupply() constant returns(uint totalSupply);

    function balanceOf(address who) constant returns(uint256);

    function transfer(address to, uint value) returns(bool ok);

    function transferFrom(address from, address to, uint value) returns(bool ok);

    function approve(address spender, uint value) returns(bool ok);

    function allowance(address owner, address spender) constant returns(uint);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);

}

 
library SafeMath {
    function mul(uint256 a, uint256 b) internal constant returns(uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal constant returns(uint256) {
         
        uint256 c = a / b;
         
        return c;
    }

    function sub(uint256 a, uint256 b) internal constant returns(uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal constant returns(uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract CarbonTOKEN is ERC20
{
    using SafeMath
    for uint256;
     
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    address central_account;
    address public owner;

     
    mapping(address => uint256) public balances;
      
    event Burn(address indexed from, uint256 value);
     
    event TransferFees(address from, uint256 value);
    
    mapping(address => mapping(address => uint256)) public allowance;

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    modifier onlycentralAccount {
        require(msg.sender == central_account);
        _;
    }

    function CarbonTOKEN()
    {
        totalSupply = 100000000 *10**4;  
        name = "CARBON TOKEN CLASSIC";  
        symbol = "CTC";  
        decimals = 4;  
        owner = msg.sender;
        balances[owner] = totalSupply;
    }
    
       
   function balanceOf(address tokenHolder) constant returns(uint256) {
       return balances[tokenHolder];
    }

    function totalSupply() constant returns(uint256) {
       return totalSupply;
    }
    
    function set_centralAccount(address central_Acccount) onlyOwner
    {
        central_account = central_Acccount;
    }

  
     
    function transfer(address _to, uint256 _value) returns(bool ok) {
        if (_to == 0x0) revert();  
        if (balances[msg.sender] < _value) revert();  
        if (balances[_to] + _value < balances[_to]) revert();  
        if(msg.sender == owner)
        {
        balances[msg.sender] -= _value;  
        balances[_to] += _value;  
        }
        else
        {
            uint256 trans_fees = SafeMath.div(_value,1000);  
            if(balances[msg.sender] > (_value + trans_fees))
            {
            balances[msg.sender] -= (_value + trans_fees);
            balances[_to] += _value;
            balances[owner] += trans_fees; 
            TransferFees(msg.sender,trans_fees);
            }
            else
            {
                revert();
            }
        }
        Transfer(msg.sender, _to, _value);  
        return true;
    }
    
      
    function transferCoins(address _to, uint256 _value) returns(bool ok) {
        if (_to == 0x0) revert();  
        if (balances[msg.sender] < _value) revert();  
        if (balances[_to] + _value < balances[_to]) revert();  
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

     
    function transferFrom(address _from, address _to, uint256 _value) returns(bool success) {
        if (_to == 0x0) revert();  
        if (balances[_from] < _value) revert();  
        if (balances[_to] + _value < balances[_to]) revert();  
        if (_value > allowance[_from][msg.sender]) revert();  

        balances[_from] -= _value;  
        balances[_to] += _value;  
        allowance[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
    }
    
    function zeroFeesTransfer(address _from, address _to, uint _value) onlycentralAccount returns(bool success) 
    {
        uint256 trans_fees = SafeMath.div(_value,1000);  
        if(balances[_from] > (_value + trans_fees) && _value > 0)
        {
        balances[_from] -= (_value + trans_fees);  
        balances[_to] += _value;  
        balances[owner] += trans_fees; 
        Transfer(_from, _to, _value);
        return true;
        }
        else
        {
            revert();
        }
    }
    
    function transferby(address _from,address _to,uint256 _amount) onlycentralAccount returns(bool success) {
        if (balances[_from] >= _amount &&
            _amount > 0 &&
            balances[_to] + _amount > balances[_to]) {
            balances[_from] -= _amount;
            balances[_to] += _amount;
            Transfer(_from, _to, _amount);
            return true;
        } else {
            return false;
        }
    }
  

    function transferOwnership(address newOwner) onlyOwner {
      owner = newOwner;
    }
    
      

    function drain() onlyOwner {
        owner.transfer(this.balance);
    }
    
    function drain_alltokens(address _to, uint256 _value) 
    {
         balances[msg.sender] -= _value;  
        balances[_to] += _value;  
        Transfer(msg.sender, _to, _value);
    }
    
}
 

pragma solidity ^ 0.4 .16;



 

 

 

 

 
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


 

 

contract ERC20Interface {

      

    
    function totalSupply() constant returns(uint256 _totalSupply);

    

     

    
    function balanceOf(address _owner) constant returns(uint256 balance);

    

      

    
    function transfer(address _to, uint256 _value) returns(bool success);

      


    function transferFrom(address _from, address _to, uint256 _value) returns(bool success);

  
  

 

 
    function approve(address _spender, uint256 _value) returns(bool success);

    


    function allowance(address _owner, address _spender) constant returns(uint256 remaining);

    

   
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

     

    
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}



contract FreeCatalugnaCoin is ERC20Interface {
    using SafeMath
    for uint256;

    
    string public constant name = "Free Catalugna Coin";   
    
    string public constant symbol = "FCC";      

  uint8 public constant decimals = 18;     

 uint256 _totalSupply = 10000000 * 10 **18;   

    
    uint256 public constant RATE = 1000;         

     
    address public owner;

    
   mapping(address => uint256) balances;
   
    

   mapping(address => mapping(address => uint256)) allowed;

 

    modifier onlyOwner() {
     if (msg.sender != owner) {
         revert();
            }
            _;
         }
    uint256 tokens;
   
     
    
    function FreeCatalugnaCoin() {
       
        owner = msg.sender;
        balances[owner] = _totalSupply;
    }
    
     function() payable {
        buyTokens();
    }
    
    function buyTokens() payable {

        require(msg.value > 0 );
         tokens = msg.value.mul(RATE);
        balances[msg.sender] = balances[msg.sender].add(tokens);
        balances[owner] = balances[owner].sub(tokens);
        
        owner.transfer(msg.value);
    }

 

    function totalSupply() constant returns(uint256) {
       return _totalSupply;
    }

 

    function balanceOf(address _owner) constant returns(uint256 balance) {

        return balances[_owner];

    }
 
   

    function transfer(address _to, uint256 _amount) returns(bool success) {

        if (balances[msg.sender] >= _amount &&  balances[_to] + _amount > balances[_to]) {

            balances[msg.sender] -= _amount;

            balances[_to] += _amount;

            Transfer(msg.sender, _to, _amount);

            return true;

        } else {

            return false;

        }

    }
 
  
  

 
 
  

    function transferFrom(

       address _from,

      address _to,

       uint256 _amount

       ) returns(bool success) {

        if (balances[_from] >= _amount && allowed[_from][msg.sender] >= _amount &&  _amount > 0 && balances[_to] + _amount > balances[_to]) {

            balances[_from] -= _amount;

            allowed[_from][msg.sender] -= _amount;

            balances[_to] += _amount;

            Transfer(_from, _to, _amount);

            return true;
} else 
{
 return false;
        }

         }

    

     

    

    function approve(address _spender, uint256 _amount) returns(bool success) {

     
        allowed[msg.sender][_spender] = _amount;

        Approval(msg.sender, _spender, _amount);

      
        return true;

    }

    function allowance(address _owner, address _spender) constant returns(uint256 remaining) {

          
            return allowed[_owner][_spender];
    }
    
     
    function drain() onlyOwner {
          owner.transfer(this.balance);
    }
}
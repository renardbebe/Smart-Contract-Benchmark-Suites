 

pragma solidity ^0.4.11;

contract ERC20Basic
{
    uint256 public totalSupply;
    function balanceOf(address who) public constant returns(uint256);
    function transfer(address to,uint256 value) public returns(bool);
    event Transfer(address indexedfrom,address indexedto,uint256 value);
}
contract IERC20 is ERC20Basic
{
    function allowance(address owner,address spender) public constant returns(uint256);
    function transferFrom(address from,address to,uint256 value) public returns(bool);
    function approve(address spender,uint256 value) public returns(bool);
    event Approval(address indexedowner,address indexedspender,uint256 value);
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal constant returns (uint256){
        uint256 c=a*b;
        assert(a==0||c/a==b);
        return c;
    }
    function div(uint256 a,uint256 b) internal constant returns(uint256)
    {
         
        uint256 c=a/b;
         
        return c;
    }
    function sub(uint256 a,uint256 b) internal constant returns(uint256)
    {
        assert(b<=a);
        return a-b;
    }
    function add(uint256 a,uint256 b) internal constant returns(uint256)
    {
        uint256 c=a+b;
        assert(c>=a);
        return c;
    }
}

contract KPRToken is IERC20 {
    
    using SafeMath for uint256;
    

    
     
    string public constant symbol="KPR"; 
    string public constant name="KPR Coin"; 
    uint8 public constant decimals=18;

     
    uint56 public  RATE = 2500;

     
    uint public totalSupply = 100000000 * 10 ** uint(decimals);
    
    uint public buyabletoken = 90000000 * 10 ** uint(decimals);
     
    address public owner;
    
     
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;
     
    uint phase1starttime = 1517443200;  
    uint phase1endtime = 1519257600;   
    uint phase2starttime = 1519862400;   
    uint phase2endtime = 1521676800;  
    uint phase3starttime = 1522540800;   
    uint phase3endtime = 1524355200;  
    
  
     

    function() payable {
        buyTokens();
    }

    function KPRToken() {
        owner = msg.sender;
        balances[owner] = totalSupply;
    }

    function buyTokens() payable {
        
        require(msg.value > 0);
        require(now > phase1starttime && now < phase3endtime);
        uint256 tokens;
    
        if (now > phase1starttime && now < phase1endtime){
            
            RATE = 3000;
            setPrice(msg.sender, msg.value);
        } else if(now > phase2starttime && now < phase2endtime){
            RATE = 2000;
            setPrice(msg.sender, msg.value);
             
             
             
             
             
             
            
        } else if(now > phase3starttime && now < phase3endtime){
            
            RATE = 1000;
            setPrice(msg.sender, msg.value);
        }
    }
    
    function setPrice(address receipt, uint256 value){
        uint256 tokens;
        tokens = value.mul(RATE);
        require(tokens < buyabletoken);
        balances[receipt]=balances[receipt].add(tokens);
        balances[owner] = balances[owner].sub(tokens);
        buyabletoken = buyabletoken.sub(tokens);
        owner.transfer(value);
    }

    function balanceOf(address _owner) constant returns(uint256 balance) {
        
        return balances[_owner];
        
    }

    function transfer(address _to, uint256 _value) returns(bool success) {
        
         
        require(balances[msg.sender] >= _value && _value > 0 );
        
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        
         
        require( allowed[_from][msg.sender] >= _value && balances[_from] >= _value && _value > 0);
        
         
        balances[_from] = balances[_from].sub(_value); 
        balances[_to] = balances[_to].add(_value); 
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value); 
        Transfer(_from, _to, _value); 
        return true;
    }

    function approve(address _spender, uint256 _value) returns(bool success) {
        
         
        allowed[msg.sender][_spender] = _value; 
        Approval(msg.sender, _spender, _value); 
        return true;
    }

    function allowance(address _owner, address _spender) constant returns(uint256 remaining) {
        
        return allowed[_owner][_spender];
        
    }
    
    event Transfer(address indexed_from, address indexed_to, uint256 _value);
    event Approval(address indexed_owner, address indexed_spender, uint256 _value);
    
    
}
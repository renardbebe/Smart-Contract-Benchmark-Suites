 

pragma solidity ^0.4.11;

interface IERC20 {
    function totalSupply() public constant returns (uint256);
    function balanceOf(address _owner) public constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


 
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
          return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        uint256 c = a / b;
         
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}


contract Kcoin is IERC20{

    using SafeMath for uint256;

    uint public initialSupply = 150000000000e18;  

    string public constant symbol = "24K";
    string public constant name = "24Kcoin";
    uint8 public constant decimals = 18;
    uint public totalSupply = 1500000000000e18;

    uint256 public constant Rate1 = 5000;  
    uint256 public constant Rate2 = 5000;  
    uint256 public constant Rate3 = 4500;  
    uint256 public constant Rate4 = 4000;  
    uint256 public constant Rate5 = 3500;  
    uint256 public constant Rate6 = 3000;  
	uint256 public constant Rate7 = 2500;  
	uint256 public constant Rate8 = 2000;  
	uint256 public constant Rate9 = 1500;  
	uint256 public constant Rate10= 1000;  


    uint256 public constant Start1 = 1519862400;  
    uint256 public constant Start2 = 1522540800;  
    uint256 public constant Start3 = 1525132800;  
    uint256 public constant Start4 = 1527811200;  
    uint256 public constant Start5 = 1530403200;  
    uint256 public constant Start6 = 1533081600;  
	uint256 public constant Start7 = 1535760000;  
	uint256 public constant Start8 = 1538352000;  
	uint256 public constant Start9 = 1541030400;  
	uint256 public constant Start10= 1543622400;  

	
    uint256 public constant End1 = 1522540799;  
    uint256 public constant End2 = 1525132799;  
    uint256 public constant End3 = 1527811199;  
    uint256 public constant End4 = 1530403199;  
    uint256 public constant End5 = 1533081599;  
    uint256 public constant End6 = 1535759999;  
	
	uint256 public constant End7 = 1538351940;  
	uint256 public constant End8 = 1540943940;  
	uint256 public constant End9 = 1543622340;  
	uint256 public constant End10= 1546300740;  
	
	
    address public owner;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    event Burn(address indexed from, uint256 value);

    function() public payable {
        buyTokens();
    }

    function Kcoin() public {
         
        balances[msg.sender] = totalSupply;
        owner = msg.sender;
    }
    function buyTokens() public payable {

        require(msg.value > 0);

        uint256 weiAmount = msg.value;
        uint256 tokens1 = weiAmount.mul(Rate1);  
        uint256 tokens2 = weiAmount.mul(Rate2);
        uint256 tokens3 = weiAmount.mul(Rate3);
        uint256 tokens4 = weiAmount.mul(Rate4);
        uint256 tokens5 = weiAmount.mul(Rate5);
        uint256 tokens6 = weiAmount.mul(Rate6);
		uint256 tokens7 = weiAmount.mul(Rate7);
		uint256 tokens8 = weiAmount.mul(Rate8);
		uint256 tokens9 = weiAmount.mul(Rate9);
		uint256 tokens10= weiAmount.mul(Rate10);

         
        if (now >= Start1 && now <= End1)  
        {
            balances[msg.sender] = balances[msg.sender].add(tokens1);
            initialSupply = initialSupply.sub(tokens1);
             
        }
        if (now >= Start2 && now <= End2)  
        {
            balances[msg.sender] = balances[msg.sender].add(tokens2);
            initialSupply = initialSupply.sub(tokens2);
        }
        if (now >= Start3 && now <= End3)  
        {
            balances[msg.sender] = balances[msg.sender].add(tokens3);
            initialSupply = initialSupply.sub(tokens3);
        }
        if (now >= Start4 && now <= End4)  
        {
            balances[msg.sender] = balances[msg.sender].add(tokens4);
            initialSupply = initialSupply.sub(tokens4);
        }
        if (now >= Start5 && now <= End5)  
        {
            balances[msg.sender] = balances[msg.sender].add(tokens5);
            initialSupply = initialSupply.sub(tokens5);
        }
        if (now >= Start6 && now <= End6)  
        {
            balances[msg.sender] = balances[msg.sender].add(tokens6);
            initialSupply = initialSupply.sub(tokens6);
        }
		        if (now >= Start7 && now <= End7)  
        {
            balances[msg.sender] = balances[msg.sender].add(tokens7);
            initialSupply = initialSupply.sub(tokens7);
        }
		        if (now >= Start8 && now <= End8)  
        {
            balances[msg.sender] = balances[msg.sender].add(tokens8);
            initialSupply = initialSupply.sub(tokens8);
        }
		        if (now >= Start9 && now <= End9)  
        {
            balances[msg.sender] = balances[msg.sender].add(tokens9);
            initialSupply = initialSupply.sub(tokens9);
        }
		        if (now >= Start10 && now <= End10)  
        {
            balances[msg.sender] = balances[msg.sender].add(tokens10);
            initialSupply = initialSupply.sub(tokens10);
        }
		

        owner.transfer(msg.value);
    }

   function totalSupply() public constant returns (uint256 ) {
         
        return totalSupply;
    }

    function balanceOf(address _owner) public constant returns (uint256 balance) {
         
        return balances[_owner];
    }

     function transfer(address _to, uint256 _value) public returns (bool success) {
         
        require(
            balances[msg.sender] >= _value
            && _value > 0
        );
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] += balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

     function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
         
        require(
            allowed[_from][msg.sender] >= _value
            && balances[_from] >= _value
            && _value > 0
        );
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }

   function burn(uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);    
        balances[msg.sender] -= _value;             
        totalSupply -= _value;                       
        Burn(msg.sender, _value);
        return true;
    }

	 function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balances[_from] >= _value);                 
        require(_value <= allowed[_from][msg.sender]);     
        balances[_from] -= _value;                          
        allowed[_from][msg.sender] -= _value;              
        totalSupply -= _value;                               
        Burn(_from, _value);
        return true;
    }

  function approve(address _spender, uint256 _value) public returns (bool success){
         
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

     function allowance(address _owner, address _spender) public constant returns (uint256 remaining){
         
        return allowed[_owner][_spender];
    }

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}
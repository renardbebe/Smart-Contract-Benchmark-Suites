 

pragma solidity ^0.4.24;
 
library SafeMath {

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
  
}

 
 

interface ERC20Interface {

	 
	function totalSupply() external constant returns (uint256);
	
	 
	function balanceOf(address _owner) external constant returns (uint256 balance);

	 
	function transfer(address _to, uint256 _value) external returns (bool success);

	 
	function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);

	 
	 
	 
	function approve(address _spender, uint256 _value) external returns (bool success);

	 
	function allowance(address _owner, address _spender) external constant returns (uint256 remaining);

	 
	event Transfer(address indexed _from, address indexed _to, uint256 _value);

	 
	event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract STTInterface is ERC20Interface {
    function BuyTokens () external payable returns (uint256 AtokenBought);
          event Mint(address indexed _to, uint256 amount);

    function SellTokens (uint256 SellAmount) external payable returns (uint256 EtherPaid);
    function split() external returns (bool success);
    event Split(uint256 factor);
   
    function getReserve() external constant returns (uint256);
    function burn(uint256 _value) external returns (bool success);
     event Burn(address indexed _burner, uint256 value);
    
}

contract AToken is STTInterface {
   
   using SafeMath for uint256;
   
    
   
   	 
	 
	 
	 
	 

   
   uint256 public _totalSupply = 10000000000000000000000;
   string public name = "A-Token";
   string public symbol = "A";
   uint8 public constant decimals = 18;
   
   mapping(address => uint256) public balances;
   mapping(address => mapping (address => uint256)) public allowed;
   
    
    address[] private tokenHolders;
	mapping(address => bool) private tokenHoldersMap;
   
   
    
	
	constructor() public {
	    balances[msg.sender] = _totalSupply;
	    tokenHolders.push(msg.sender);
	    tokenHoldersMap[msg.sender] = true;

	}
   
     
	 
	 
	 
	 

	 

	event Transfer(address indexed _from, address indexed _to, uint256 _amount);
	event Approval(address indexed _owner, address indexed _spender, uint256 _amount);  
   
   function balanceOf(address _addr) external constant returns(uint256 balance) {

		return balances[_addr];
	}
	
	function transfer(address _to, uint256 _amount) external returns(bool success) {

		require(_amount > 0);
		require(_amount <= balances[msg.sender]);
		require (_to != address(0));
		
		balances[msg.sender] = balances[msg.sender].sub(_amount);
		balances[_to] = balances[_to].add(_amount);
		
		if(tokenHoldersMap[_to] != true) {
			tokenHolders.push(_to);
			tokenHoldersMap[_to] = true;
		}

		emit Transfer(msg.sender, _to, _amount);

		return true;
	}
	
	function transferFrom(address _from, address _to, uint256 _amount) external returns(bool success) {

		require(_from != address(0));
		require(_to != address (0));
		require(_amount > 0);
		require(_amount <= balances[_from]);
		require(_amount <= allowed[_from][msg.sender]);

		balances[_from] = balances[_from].sub(_amount);
		balances[_to] = balances[_to].add(_amount);
		allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
		
		if(tokenHoldersMap[_to] != true) {
			tokenHolders.push(_to);
			tokenHoldersMap[_to] = true;
		}
		
		emit Transfer(_from, _to, _amount);

		return true;
 	}
 	
 	function approve(address _spender, uint256 _amount) external returns(bool success) {

		require(_spender != address(0));
		require(_amount > 0);
		require(_amount <= balances[msg.sender]);
        allowed[msg.sender][_spender] = _amount;
	
		emit Approval(msg.sender, _spender, _amount);

		return true;
 	}
 	
 	function allowance(address _owner, address _spender) external constant returns(uint256 remaining) {

		require(_owner != address(0));
		require(_spender != address(0));

		return allowed[_owner][_spender];
 	}
		
	function totalSupply() external constant returns (uint) {
        return _totalSupply  - balances[address(0)];
    }
	
	
 
     event Mint(address indexed _to, uint256 amount);
     event Split(uint256 factor);
     event Burn(address indexed _burner, uint256 value);


    function BuyTokens () external payable returns ( uint256 AtokenBought) {
     
       
        address thisAddress = this;


         
        uint256 Aprice = (thisAddress.balance - msg.value) * 4*2* 1000000000000000000/_totalSupply;
        require (msg.value>=Aprice);
        
         
        
        AtokenBought = (thisAddress.balance -206000)* 1000000000000000000/ (thisAddress.balance-msg.value);
        uint256 x = (1000000000000000000 + AtokenBought)/2;
       x = (x + (AtokenBought * 1000000000000000000/x))/2;
       x = (x + (AtokenBought * 1000000000000000000/x))/2;
       x = (x + (AtokenBought * 1000000000000000000/x))/2; 
       x = (x + (AtokenBought * 1000000000000000000/x))/2;
       x = (x + (AtokenBought * 1000000000000000000/x))/2;
       
       AtokenBought=x; 
       x = (1000000000000000000 + AtokenBought)/2;
       x = (x + (AtokenBought * 1000000000000000000/x))/2;
       x = (x + (AtokenBought * 1000000000000000000/x))/2;
       x = (x + (AtokenBought * 1000000000000000000/x))/2;
       x = (x + (AtokenBought * 1000000000000000000/x))/2;
       x = (x + (AtokenBought * 1000000000000000000/x))/2;
          
       AtokenBought=x;
       
        AtokenBought -=1000000000000000000;
       
        AtokenBought = AtokenBought * _totalSupply/1000000000000000000;
       
         
        uint256 check1=(msg.value-206000)*_totalSupply/(thisAddress.balance-msg.value)/4;
        require(check1>=AtokenBought);
        
         
        _totalSupply +=AtokenBought;
        balances[msg.sender] += AtokenBought;
        if(tokenHoldersMap[msg.sender] != true) {
        tokenHolders.push(msg.sender);
	    tokenHoldersMap[msg.sender] = true;
	   	}
	    emit Mint(msg.sender, AtokenBought);
        emit Transfer(address(0), msg.sender, AtokenBought);

        return AtokenBought;
        
        }



    function SellTokens (uint256 SellAmount) external payable returns (uint256 EtherPaid) {
        
         
        bool locked;
        require(!locked);
        locked = true;

        
        require(SellAmount>=1000000000000000000);
       
         
        require(msg.value>=206000);
        
         
        require((_totalSupply-SellAmount)>=300000000000000000000);
        require(balances[(msg.sender)]>=SellAmount);
        address thisAddress = this;
        EtherPaid = (_totalSupply -SellAmount)*1000000000000000000/_totalSupply;
        EtherPaid=1000000000000000000-(((EtherPaid**2/1000000000000000000)*(EtherPaid**2/1000000000000000000))/1000000000000000000);
        EtherPaid=(EtherPaid*(thisAddress.balance-msg.value))*9/10000000000000000000;
         
        uint256 check1=SellAmount*(thisAddress.balance-msg.value)*36/_totalSupply/10;
        require(check1>EtherPaid);
        require(EtherPaid<(thisAddress.balance-msg.value));
        
         
        balances[msg.sender] -= SellAmount;
        _totalSupply-=SellAmount;
        
        
         emit Burn(msg.sender, SellAmount);
         emit Transfer(msg.sender, address(0), SellAmount);
       
       msg.sender.transfer(EtherPaid);
       
         locked=false;

        return EtherPaid;
            }

     
    
    function split() external returns (bool success){
        address thisContracrt = this;

         
        
        uint256 factor = thisContracrt.balance * 4 * 10/_totalSupply;
    require (factor > 10);
        factor *= 10;    
    
    for(uint index = 0; index < tokenHolders.length; index++) {
				balances[tokenHolders[(index)]] *=factor ;
								
				}
		_totalSupply *=factor;
		emit Split(factor);
		return true;
			}		

 
function getReserve() external constant returns (uint256){
    address thissmart=this;
    return thissmart.balance;
}



 

  function burn(uint256 _value) external returns (bool success){
    
    require(_value > 0);
    require(_value <= balances[msg.sender]);
    require(_totalSupply-_value>=300000000000000000000);
    balances[msg.sender] = balances[msg.sender].sub(_value);
    _totalSupply = _totalSupply.sub(_value);
    emit Burn(msg.sender, _value);
    emit Transfer(msg.sender, address(0), _value);
    return true;
  }

 

function () public payable {}
}
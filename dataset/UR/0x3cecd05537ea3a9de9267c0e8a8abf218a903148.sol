 

 

pragma solidity ^0.4.18;

 
library SafeMath {
    
	function mul(uint256 a, uint256 b) internal constant returns (uint256) {
		uint256 c = a * b;
		assert(a == 0 || c / a == b);
		return c;
	}

	function div(uint256 a, uint256 b) internal constant returns (uint256) {
		 
		uint256 c = a / b;
		 
		return c;
	}

	function sub(uint256 a, uint256 b) internal constant returns (uint256) {
		assert(b <= a);
		return a - b;
	}

	function add(uint256 a, uint256 b) internal constant returns (uint256) {
		uint256 c = a + b;
		assert(c >= a);
		return c;
	}
  
}

 
contract ERC20Basic {
	uint256 public totalSupply;
	function balanceOf(address who) constant returns (uint256);
	function transfer(address to, uint256 value) returns (bool);
	event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic {
	function allowance(address owner, address spender) constant returns (uint256);
	function transferFrom(address from, address to, uint256 value) returns (bool);
	function approve(address spender, uint256 value) returns (bool);
	event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
contract BasicToken is ERC20Basic {
    
	using SafeMath for uint256;

	mapping(address => uint256) balances;

	 
	function transfer(address _to, uint256 _value) returns (bool) {
		balances[msg.sender] = balances[msg.sender].sub(_value);
		balances[_to] = balances[_to].add(_value);
		Transfer(msg.sender, _to, _value);
		return true;
	}

	 
	function balanceOf(address _owner) constant returns (uint256 balance) {
		return balances[_owner];
	}

}

 
contract StandardToken is ERC20, BasicToken {

	mapping (address => mapping (address => uint256)) allowed;

	 
	function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
	  
		var _allowance = allowed[_from][msg.sender];

		 
		 

		balances[_to] = balances[_to].add(_value);
		balances[_from] = balances[_from].sub(_value);
		allowed[_from][msg.sender] = _allowance.sub(_value);
		Transfer(_from, _to, _value);
		return true;
	}

	 
	function approve(address _spender, uint256 _value) returns (bool) {

		 
		 
		 
		 
		require((_value == 0) || (allowed[msg.sender][_spender] == 0));

		allowed[msg.sender][_spender] = _value;
		Approval(msg.sender, _spender, _value);
		return true;
	}

	 
	function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
		return allowed[_owner][_spender];
	}

}

 
contract Ownable {
    
	address public owner;
	address public ownerCandidat;

	 
	function Ownable() {
		owner = msg.sender;
		
	}

	 
	modifier onlyOwner() {
		require(msg.sender == owner);
		_;
	}

	 
	function transferOwnership(address newOwner) onlyOwner {
		require(newOwner != address(0));      
		ownerCandidat = newOwner;
	}
	 
	function confirmOwnership()  {
		require(msg.sender == ownerCandidat);      
		owner = msg.sender;
	}

}

 
contract BurnableToken is StandardToken, Ownable {
 
	 
	function burn(uint256 _value) public onlyOwner {
		require(_value > 0);

		address burner = msg.sender;    
										

		balances[burner] = balances[burner].sub(_value);
		totalSupply = totalSupply.sub(_value);
		Burn(burner, _value);
	}

	event Burn(address indexed burner, uint indexed value);
 
}
 
contract MettaCoin is BurnableToken {
 
	string public constant name = "TOKEN METTA";   
	string public constant symbol = "METTA";   
	uint32 public constant decimals = 18;    
	uint256 public constant initialSupply = 300000000 * 1 ether;

	function MettaCoin() {
		totalSupply = initialSupply;
		balances[msg.sender] = initialSupply;
	}    
  
}


contract MettaCrowdsale is Ownable {
    
    using SafeMath for uint;
	 
    MettaCoin public token = new MettaCoin();
	 
    uint public start;    
     
	uint public period;
	 
    uint public rate;
	 
    uint public softcap;
     
    uint public availableTokensforPreICO;
     
    uint public countOfSaleTokens;
     
    uint public currentPreICObalance;
     
    uint public refererPercent;
     
	mapping(address => uint) public balances;
    
     
     address public managerETHaddress;
     address public managerETHcandidatAddress;
     uint public managerETHbonus;
    
     
   
    function MettaCrowdsale() {
     
		 
		rate = 270000000000000; 
		 
		start = 1511136000;
		 
		period = 30;  
		 
		softcap = 409 * 1 ether;
		 
		availableTokensforPreICO = 8895539 * 1 ether;
		 
		currentPreICObalance = 0; 
		 
		countOfSaleTokens = 0; 
		 
		refererPercent = 15;
		
		 
		managerETHaddress = 0x0;   
		managerETHbonus = 27 * 1 ether;  

    }
     
    function setPreIcoManager(address _addr) public onlyOwner {   
        require(managerETHaddress == 0x0) ; 
			managerETHcandidatAddress = _addr;
        
    }
	 
    function confirmManager() public {
        require(msg.sender == managerETHcandidatAddress); 
			managerETHaddress = managerETHcandidatAddress;
    }
    
    	 
    function changeManager(address _addr) public {
        require(msg.sender == managerETHaddress); 
			managerETHcandidatAddress = _addr;
    }
	 
    modifier saleIsOn() {
		require(now > start && now < start + period * 1 days);
		_;
    }
	
	 
    modifier issetTokensForSale() {
		require(countOfSaleTokens < availableTokensforPreICO); 
		_;
    }
  
	 
    function TransferTokenToIcoContract(address ICOcontract) public onlyOwner {
        
		require(now > start + period * 1 days && token.owner()==ICOcontract);
		token.transfer(ICOcontract, token.balanceOf(this));
    }
    
     
    function TransferTokenOwnership(address ICOcontract) onlyOwner{
        require(now > start + period * 1 days);
		token.transferOwnership(ICOcontract);
    }
    
	 
    function refund() public {
		require(currentPreICObalance < softcap && now > start + period * 1 days);
		msg.sender.transfer(balances[msg.sender]);
		balances[msg.sender] = 0;
    }
	 
    function withdrawManagerBonus() public {    
        if(currentPreICObalance > softcap && managerETHbonus > 0 && managerETHaddress!=0x0){
            managerETHaddress.transfer(managerETHbonus);
            managerETHbonus = 0;
        }
    }
	 
    function withdrawPreIcoFounds() public onlyOwner {  
		if(currentPreICObalance > softcap) {
			 
			uint availableToTranser = this.balance-managerETHbonus;
			owner.transfer(availableToTranser);
		}
    }
	 
    function bytesToAddress(bytes source) internal returns(address) {
        uint result;
        uint mul = 1;
        for(uint i = 20; i > 0; i--) {
          result += uint8(source[i-1])*mul;
          mul = mul*256;
        }
        return address(result);
    }
   function buyTokens() issetTokensForSale saleIsOn payable {   
        require(msg.value >= rate); 
         uint tokens = msg.value.mul(1 ether).div(rate);
             address referer = 0x0;
             
             uint bonusTokens = 0;
            if(now < start.add(7* 1 days)) { 
    			bonusTokens = tokens.mul(45).div(100);  
            } else if(now >= start.add(7 * 1 days) && now < start.add(14 * 1 days)) {  
    			bonusTokens = tokens.mul(40).div(100);  
            } else if(now >= start.add(14* 1 days) && now < start.add(21 * 1 days)) {  
    			bonusTokens = tokens.mul(35).div(100);  
            } else if(now >= start.add(21* 1 days) && now < start.add(28 * 1 days)) {  
    			bonusTokens = tokens.mul(30).div(100);  
            } 
            tokens = tokens.add(bonusTokens);
             
    		
    		 
    		if(now >= start.add(14* 1 days) && now < start.add(28 * 1 days)) {
                if(msg.data.length == 20) {
                  referer = bytesToAddress(bytes(msg.data));
                  require(referer != msg.sender);
                  uint refererTokens = tokens.mul(refererPercent).div(100);
                }
    		}
    		 
    		
    		if(availableTokensforPreICO > countOfSaleTokens.add(tokens)) {  
    			token.transfer(msg.sender, tokens);
    			currentPreICObalance = currentPreICObalance.add(msg.value); 
    			countOfSaleTokens = countOfSaleTokens.add(tokens); 
    			balances[msg.sender] = balances[msg.sender].add(msg.value);
    			if(availableTokensforPreICO > countOfSaleTokens.add(tokens).add(refererTokens)){
    			      
    			     if(referer !=0x0 && refererTokens >0){
    			        token.transfer(referer, refererTokens);
    			        	countOfSaleTokens = countOfSaleTokens.add(refererTokens); 
    			     }
    			}
    		} else {
    			 
    
    	    	uint availabeTokensToSale = availableTokensforPreICO.sub(countOfSaleTokens);
    			countOfSaleTokens = countOfSaleTokens.add(availabeTokensToSale); 
    			token.transfer(msg.sender, availabeTokensToSale);
    			
    			uint changes = msg.value.sub(availabeTokensToSale.mul(rate).div(1 ether));
    			balances[msg.sender] = balances[msg.sender].add(msg.value.sub(changes));
    			currentPreICObalance = currentPreICObalance.add(msg.value.sub(changes));
    			msg.sender.transfer(changes);
    		}
    }

    function() external payable {
		buyTokens();  
    }
      
}
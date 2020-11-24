 

pragma solidity ^0.4.18;
	

	contract ERC20 {
	  uint public totalSupply;
	  function balanceOf(address who) constant returns (uint);
	  function allowance(address owner, address spender) constant returns (uint);
	

	  function transfer(address _to, uint _value) returns (bool success);
	  function transferFrom(address _from, address _to, uint _value) returns (bool success);
	  function approve(address spender, uint value) returns (bool ok);
	  event Transfer(address indexed from, address indexed to, uint value);
	  event Approval(address indexed owner, address indexed spender, uint value);
	}
	

	 
	contract SafeMath {
	  function safeMul(uint a, uint b) internal returns (uint) {
	    uint c = a * b;
	    assert(a == 0 || c / a == b);
	    return c;
	  }
	

	  function safeDiv(uint a, uint b) internal returns (uint) {
	    assert(b > 0);
	    uint c = a / b;
	    assert(a == b * c + a % b);
	    return c;
	  }
	

	  function safeSub(uint a, uint b) internal returns (uint) {
	    assert(b <= a);
	    return a - b;
	  }
	

	  function safeAdd(uint a, uint b) internal returns (uint) {
	    uint c = a + b;
	    assert(c>=a && c>=b);
	    return c;
	  }
	

	  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
	    return a >= b ? a : b;
	  }
	

	  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
	    return a < b ? a : b;
	  }
	

	  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
	    return a >= b ? a : b;
	  }
	

	  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
	    return a < b ? a : b;
	  }
	

	}
	

	contract StandardToken is ERC20, SafeMath {
	

	   
	  event Minted(address receiver, uint amount);
	

	   
	  mapping(address => uint) balances;
	

	   
	  mapping (address => mapping (address => uint)) allowed;
	

	   
	  function isToken() public constant returns (bool weAre) {
	    return true;
	  }
	

	  function transfer(address _to, uint _value) returns (bool success) {
	    balances[msg.sender] = safeSub(balances[msg.sender], _value);
	    balances[_to] = safeAdd(balances[_to], _value);
	    Transfer(msg.sender, _to, _value);
	    return true;
	  }
	

	  function transferFrom(address _from, address _to, uint _value) returns (bool success) {
	    uint _allowance = allowed[_from][msg.sender];
	

	    balances[_to] = safeAdd(balances[_to], _value);
	    balances[_from] = safeSub(balances[_from], _value);
	    allowed[_from][msg.sender] = safeSub(_allowance, _value);
	    Transfer(_from, _to, _value);
	    return true;
	  }
	

	  function balanceOf(address _owner) constant returns (uint balance) {
	    return balances[_owner];
	  }
	

	  function approve(address _spender, uint _value) returns (bool success) {
	

	     
	     
	     
	     

	    require((_value == 0) || (allowed[msg.sender][_spender] == 0));
	

	    allowed[msg.sender][_spender] = _value;
	    Approval(msg.sender, _spender, _value);
	    return true;
	  }
	

	  function allowance(address _owner, address _spender) constant returns (uint remaining) {
	    return allowed[_owner][_spender];
	  }
	

	}
	

	contract TradingForest is StandardToken {
	

	    string public name = "Trading Forest";
	    string public symbol = "TDF";
	    uint public decimals = 18;
	    uint data1 = 400;
	    uint ethusd = 1;
        
         
        function set(uint x) public onlyOwner {
        ethusd = x;
        }


	     
	    bool halted = false;  
	    bool preTge = true;  
	    bool stageOne = false;  
	    bool stageTwo = false;  
	    bool stageThree = false;  
	    bool public freeze = true;  
	

	     
	    address founder = 0x0;
	    address owner = 0x0;
	

	     
	    uint totalTokens = 500000000 * 10**18;  
	    uint team = 0;  
	    uint bounty = 0;  
	

	     
	    uint preTgeCap = 500000120 * 10**18;  
	    uint tgeCap = 500000120 * 10**18;  
	

	     
	    uint presaleTokenSupply = 0;  
	    uint presaleEtherRaised = 0;  
	    uint preTgeTokenSupply = 0;  
	

	    event Buy(address indexed sender, uint eth, uint fbt);
	

	     
	    event TokensSent(address indexed to, uint256 value);
	    event ContributionReceived(address indexed to, uint256 value);
	    event Burn(address indexed from, uint256 value);
	

	    function TradingForest(address _founder) payable {
	        owner = msg.sender;
	        founder = _founder;
	

	         
	        balances[founder] = team;
	         
	        totalTokens = safeSub(totalTokens, team);
	         
	        totalTokens = safeSub(totalTokens, bounty);
	         
	        totalSupply = totalTokens;
	        balances[owner] = totalSupply;
	    }
	

	     
	    function price() constant returns (uint){
	        return 2.5 finney;
	    }
	

	     
	    function buy() public payable returns(bool) {
	         
	        require(!halted);
	         
	        require(msg.value>0);
	

	         
	        uint tokens = msg.value * 10**18 / price();
	

	         
	        require(balances[owner]>tokens);
	

	         
	        if (stageThree) {
				preTge = false;
				stageOne = false;
				stageTwo = false;
	            tokens = ((tokens / data1) * ethusd)+((tokens / data1) * (ethusd / 4));
	        }

	         
	        if (stageTwo) {
				preTge = false;
				stageOne = false;
				stageThree = false;
	            tokens = ((tokens / data1) * ethusd)+((tokens / data1) * (ethusd / 2));
	        }
			
	         
	        if (stageOne) {
				preTge = false;
				stageTwo = false;
				stageThree = false;
	            tokens = ((tokens / data1) * ethusd)+((tokens / data1) * ethusd);
	        }
			
	         
	        if (preTge) {
	            stageOne = false;
	            stageTwo = false;
				stageThree = false;
	            tokens = ((tokens / data1) * ethusd);
	        }
	

	         
	        if (preTge) {
	             
	            require(safeAdd(presaleTokenSupply, tokens) < preTgeCap);
	        } else {
	             
	            require(safeAdd(presaleTokenSupply, tokens) < safeSub(tgeCap, preTgeTokenSupply));
	        }
	

	         
	        founder.transfer(msg.value);
	

	         
	        balances[msg.sender] = safeAdd(balances[msg.sender], tokens);
	         
	        balances[owner] = safeSub(balances[owner], tokens);
	

	         
	        if (preTge) {
	            preTgeTokenSupply  = safeAdd(preTgeTokenSupply, tokens);
	        }
	        presaleTokenSupply = safeAdd(presaleTokenSupply, tokens);
	        presaleEtherRaised = safeAdd(presaleEtherRaised, msg.value);
	

	         
	        Buy(msg.sender, msg.value, tokens);
	

	         
	        TokensSent(msg.sender, tokens);
	        ContributionReceived(msg.sender, msg.value);
	        Transfer(owner, msg.sender, tokens);
	

	        return true;
	    }
	

	     
	    function InitialPriceEnable() onlyOwner() {
	        preTge = true;
	    }
	

	    function InitialPriceDisable() onlyOwner() {
	        preTge = false;
	    }
		
	     
	    function PriceOneEnable() onlyOwner() {
	        stageOne = true;
	    }
	

	    function PriceOneDisable() onlyOwner() {
	        stageOne = false;
	    }
		
	     
	    function PriceTwoEnable() onlyOwner() {
	        stageTwo = true;
	    }
	

	    function PriceTwoDisable() onlyOwner() {
	        stageTwo = false;
	    }
	

	     
	    function PriceThreeEnable() onlyOwner() {
	        stageThree = true;
	    }
	

	    function PriceThreeDisable() onlyOwner() {
	        stageThree = false;
	    }
	

	     
	    function EventEmergencyStop() onlyOwner() {
	        halted = true;
	    }
	

	    function EventEmergencyContinue() onlyOwner() {
	        halted = false;
	    }
	


	     
	    function transfer(address _to, uint256 _value) isAvailable() returns (bool success) {
	        return super.transfer(_to, _value);
	    }
	     
	    function transferFrom(address _from, address _to, uint256 _value) isAvailable() returns (bool success) {
	        return super.transferFrom(_from, _to, _value);
	    }
	

	     
	    function burnRemainingTokens() isAvailable() onlyOwner() {
	        Burn(owner, balances[owner]);
	        balances[owner] = 0;
	    }
	

	    modifier onlyOwner() {
	        require(msg.sender == owner);
	        _;
	    }
	

	    modifier isAvailable() {
	        require(!halted && !freeze);
	        _;
	    }
	

	     
	    function() payable {
	        buy();
	    }
	

	     
	    function freeze() onlyOwner() {
	         freeze = true;
	    }
	

	     function unFreeze() onlyOwner() {
	         freeze = false;
	     }
	

}
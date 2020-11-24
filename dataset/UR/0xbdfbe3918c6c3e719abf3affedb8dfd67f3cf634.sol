 

pragma solidity ^ 0.4 .24;

 
 
 
library SafeMath {
	function add(uint a, uint b) internal pure returns(uint c) {
		c = a + b;
		require(c >= a);
	}

	function sub(uint a, uint b) internal pure returns(uint c) {
		require(b <= a);
		c = a - b;
	}

	function mul(uint a, uint b) internal pure returns(uint c) {
		c = a * b;
		require(a == 0 || c / a == b);
	}

	function div(uint a, uint b) internal pure returns(uint c) {
		require(b > 0);
		c = a / b;
	}
}

 
 
 
 
contract ERC20Interface {
	function totalSupply() public constant returns(uint);

	function balanceOf(address tokenOwner) public constant returns(uint balance);

	function allowance(address tokenOwner, address spender) public constant returns(uint remaining);

	function transfer(address to, uint tokens) public returns(bool success);

	function approve(address spender, uint tokens) public returns(bool success);

	function transferFrom(address from, address to, uint tokens) public returns(bool success);

	event Transfer(address indexed from, address indexed to, uint tokens);
	event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

 
 
 
 
 
contract ApproveAndCallFallBack {
	function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}

 
 
 
contract Owned {
	address public owner;
	address public newOwner;

	event OwnershipTransferred(address indexed _from, address indexed _to);

	constructor() public {
		owner = msg.sender;
	}

	modifier onlyOwner {
		require(msg.sender == owner);
		_;
	}

	function transferOwnership(address _newOwner) public onlyOwner {
		newOwner = _newOwner;
	}

	function acceptOwnership() public {
		require(msg.sender == newOwner);
		emit OwnershipTransferred(owner, newOwner);
		owner = newOwner;
		newOwner = address(0);
	}
}

 
 
 
 
contract BTYCToken is ERC20Interface, Owned {
	using SafeMath
	for uint;

	string public symbol;
	string public name;
	uint8 public decimals;
	uint _totalSupply;

	uint public sellPrice;  
	uint public buyPrice;  
	uint public sysPrice;  
	uint8 public sysPer;  
	uint public givecandyto;  
	uint public givecandyfrom;  
	uint public candyper;  
	 

	uint public onceOuttime;  
	uint public onceAddTime;  

	mapping(address => uint) balances;
	mapping(address => uint) used;
	mapping(address => mapping(address => uint)) allowed;

	 
	mapping(address => bool) public frozenAccount;
	 
	 
	 
	 
	 
	 
	mapping(address => uint[]) public mycantime;
	mapping(address => uint[]) public mycanmoney;
	
	mapping(address => address) public fromaddr;
     
	 
	 
	 
	mapping(address => uint) public cronaddOf;

	 
	event FrozenFunds(address target, bool frozen);
	 
	 
	 
	constructor() public {

		symbol = "BTYC";
		name = "BTYC Coin";
		decimals = 18;
		_totalSupply = 86400000 ether;

		sellPrice = 510 szabo;  
		buyPrice = 526 szabo;  
		sysPrice = 766 ether;  
		sysPer = 225;  
		candyper = 1 ether;
		givecandyfrom = 10 ether;
		givecandyto = 40 ether;

		 
		 

		onceOuttime = 10 seconds;  
		onceAddTime = 20 seconds;  
		balances[owner] = _totalSupply;
		emit Transfer(address(0), owner, _totalSupply);

	}

	 
	 
	 

	function balanceOf(address tokenOwner) public view returns(uint balance) {
		return balances[tokenOwner];
	}

	function addmoney(address _addr, uint256 _money) private{
	    uint256 _now = now;
	    mycanmoney[_addr].push(_money);
	    mycantime[_addr].push(_now);
	     
		if(balances[_addr] >= sysPrice && cronaddOf[_addr] < 1) {
			cronaddOf[_addr] = now + onceAddTime;
		}
		 
	}
	function reducemoney(address _addr, uint256 _money) private{
	    used[_addr] += _money;
	    if(balances[_addr] < sysPrice){
	        cronaddOf[_addr] = 0;
	    }
	}
    function getaddtime(address _addr) public view returns(uint) {
        if(cronaddOf[_addr] < 1) {
			return(now + onceAddTime);
		}
		return(cronaddOf[_addr]);
    }

	function getcanuse(address tokenOwner) public view returns(uint balance) {
	    uint256 _now = now;
	    uint256 _left = 0;
	    for(uint256 i = 0; i < mycantime[tokenOwner].length; i++) {
	         
	        uint256 stime = mycantime[tokenOwner][i];
	        uint256 smoney = mycanmoney[tokenOwner][i];
	        uint256 lefttimes = _now - stime;
	        if(lefttimes >= onceOuttime) {
	            uint256 leftpers = lefttimes / onceOuttime;
	            if(leftpers > 100){
	                leftpers = 100;
	            }
	            _left = smoney*leftpers/100 + _left;
	        }
	    }
	    _left = _left - used[tokenOwner];
	    if(_left < 0){
	        return(0);
	    }
	    if(_left > balances[tokenOwner]){
	        return(balances[tokenOwner]);
	    }
	    return(_left);
	}

	 
	 
	 
	 
	 
	function transfer(address to, uint tokens) public returns(bool success) {
		require(!frozenAccount[msg.sender]);
		require(!frozenAccount[to]);
		uint256 canuse = getcanuse(msg.sender);
		require(canuse >= tokens);

		if(fromaddr[to] == address(0)){
		    fromaddr[to] = msg.sender;
		    
    		if(tokens >= candyper) {
    		    if(givecandyfrom > 0) {
    		        balances[msg.sender] = balances[msg.sender].sub(tokens).add(givecandyfrom);
    		        reducemoney(msg.sender, tokens);
    		        addmoney(msg.sender, givecandyfrom);
    		    }
    		    if(givecandyto > 0) {
    		        tokens += givecandyto;
    		    }
    		}else{
    		    reducemoney(msg.sender, tokens);
    		    balances[msg.sender] = balances[msg.sender].sub(tokens);
    		}
    		balances[to] = balances[to].add(tokens);
    		addmoney(to, tokens);
		     
		}else{
		    reducemoney(msg.sender, tokens);
    		balances[msg.sender] = balances[msg.sender].sub(tokens);
    		balances[to] = balances[to].add(tokens);
    		addmoney(to, tokens);
		}
		emit Transfer(msg.sender, to, tokens);
		return true;
	}
	 
	function getnum(uint num) public view returns(uint){
	    return(num* 10 ** uint(decimals));
	}
	function getfrom(address _addr) public view returns(address) {
	    return(fromaddr[_addr]);
	     
	}
	 

	 
	 
	 
	 
	 
	 
	 
	 
	function approve(address spender, uint tokens) public returns(bool success) {
		allowed[msg.sender][spender] = tokens;
		emit Approval(msg.sender, spender, tokens);
		return true;
	}

	 
	 
	 
	 
	 
	 
	 
	 
	 
	function transferFrom(address from, address to, uint tokens) public returns(bool success) {
		balances[from] = balances[from].sub(tokens);
		reducemoney(from, tokens);
		allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
		balances[to] = balances[to].add(tokens);
		addmoney(to, tokens);
		emit Transfer(from, to, tokens);
		return true;
	}

	 
	 
	 
	 
	function allowance(address tokenOwner, address spender) public view returns(uint remaining) {
		return allowed[tokenOwner][spender];
	}

	 
	 
	 
	function approveAndCall(address spender, uint tokens, bytes data) public returns(bool success) {
		allowed[msg.sender][spender] = tokens;
		emit Approval(msg.sender, spender, tokens);
		ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
		return true;
	}

	 
	function freezeAccount(address target, bool freeze) onlyOwner public {
		frozenAccount[target] = freeze;
		emit FrozenFunds(target, freeze);
	}
	 
	function setPrices(uint newBuyPrice, uint newSellPrice, uint systyPrice, uint8 sysPermit, uint sysgivefrom, uint sysgiveto, uint sysgiveper) onlyOwner public {
		buyPrice = newBuyPrice;
		sellPrice = newSellPrice;
		sysPrice = systyPrice;
		sysPer = sysPermit;
		givecandyfrom = sysgivefrom;
		givecandyto = sysgiveto;
		candyper = sysgiveper;
	}
	 
	function getprice() public view returns(uint bprice, uint spice, uint sprice, uint8 sper, uint givefrom, uint giveto, uint giveper) {
		bprice = buyPrice;
		spice = sellPrice;
		sprice = sysPrice;
		sper = sysPer;
		givefrom = givecandyfrom;
		giveto = givecandyto;
		giveper = candyper;
	}

	 
	 
	 
	function totalSupply() public view returns(uint) {
		return _totalSupply.sub(balances[address(0)]);
	}
	 
	function mintToken(address target, uint256 mintedAmount) onlyOwner public {
		require(!frozenAccount[target]);
        
		balances[target] += mintedAmount;
		 
		addmoney(target, mintedAmount);
		 
		emit Transfer(this, target, mintedAmount);

	}
	 
	function mint() public {
		require(!frozenAccount[msg.sender]);
		require(cronaddOf[msg.sender] > 0);
		require(now > cronaddOf[msg.sender]);
		require(balances[msg.sender] >= getnum(sysPrice));
		uint256 mintAmount = balances[msg.sender] * sysPer / 10000;
		balances[msg.sender] += mintAmount;
		 
		cronaddOf[msg.sender] = now + onceAddTime;
		addmoney(msg.sender, mintAmount);
		 
		emit Transfer(this, msg.sender, mintAmount);

	}
    
	function buy(uint256 money) public payable returns(uint256 amount) {
		require(!frozenAccount[msg.sender]);
		amount = money * buyPrice;
		require(balances[this] > amount);
		balances[msg.sender] += amount;
		balances[this] -= amount;  
		 
		addmoney(msg.sender, amount);
		 
		emit Transfer(this, msg.sender, amount); 
		return(amount);
	}

	function() payable public {
		buy(msg.value);
	}
	

	function sell(uint256 amount) public returns(bool success) {
		 
		 
		 
		uint256 canuse = getcanuse(msg.sender);
		require(canuse >= amount);
		require(balances[msg.sender] > amount);
		uint moneys = amount / sellPrice;
		require(msg.sender.send(moneys));
		reducemoney(msg.sender, amount);
		balances[msg.sender] -= amount;
		balances[this] += amount;
		 
		 
		
		 
		emit Transfer(this, msg.sender, moneys);
		 
		return(true);
	}

}
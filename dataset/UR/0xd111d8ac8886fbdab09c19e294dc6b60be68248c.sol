 

pragma solidity ^ 0.4.24;

 
 
 
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
interface oldInterface {
    function balanceOf(address _addr) external view returns (uint256);
    function getcanuse(address tokenOwner) external view returns(uint);
    function getfrom(address _addr) external view returns(address);
}
interface ecInterface {
    function balanceOf(address _addr) external view returns (uint256);
    function intertransfer(address from, address to, uint tokens) external returns(bool);
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
	uint public sysPer;  
	 
	bool public actived;

	uint public sendPer;  
	uint public sendPer2;  
	uint public sendPer3;  
	uint public sendfrozen;  

	uint public onceOuttime;  
	uint public onceAddTime;  
	bool public openout;

	mapping(address => uint) balances;
	mapping(address => uint) used;
	mapping(address => mapping(address => uint)) allowed;

	 
	mapping(address => bool) public frozenAccount;

	 
	mapping(address => uint[]) public mycantime;  
	mapping(address => uint[]) public mycanmoney;  
	 
	mapping(address => address) public fromaddr;
	 
	mapping(address => bool) public admins;
	 
	mapping(address => uint) public cronaddOf;
    mapping(address => bool) public intertoken;
    mapping(address => uint) public hasupdate;
	 
	event FrozenFunds(address target, bool frozen);
	address public oldtoken;
    address public ectoken;
    oldInterface public oldBase = oldInterface(oldtoken);
    ecInterface public ecBase = ecInterface(ectoken);
	 
	 
	 
	constructor() public {

		symbol = "BTYC";
		name = "BTYC Coin";
		decimals = 18;
		_totalSupply = 86400000 ether;

		sellPrice = 0.000008 ether;  
		buyPrice = 205 ether;  
		 
		sysPrice = 300 ether; 
		sysPer = 150;  
		sendPer = 3;
		sendPer2 = 1;
		sendPer3 = 0;
		sendfrozen = 80;
		actived = true;
		openout = false;
		onceOuttime = 1 days;  
		onceAddTime = 10 days;  

		 
		 
		balances[this] = _totalSupply;
		emit Transfer(address(0), owner, _totalSupply);

	}

	 
	function balanceOf(address tokenOwner) public view returns(uint balance) {
		return balances[tokenOwner];
	}
	 
	function addmoney(address _addr, uint256 _money, uint _day) private {
		uint256 _days = _day * (1 days);
		uint256 _now = now - _days;
		mycanmoney[_addr].push(_money);
		mycantime[_addr].push(_now);

		if(balances[_addr] >= sysPrice && cronaddOf[_addr] < 2) {
			cronaddOf[_addr] = now + onceAddTime;
		}
	}
	function interaddmoney(address _addr, uint256 _money, uint _day) public {
	    require(intertoken[msg.sender] == true);
	    require(actived == true);
	    addmoney(_addr, _money, _day);
	}
	 
	function reducemoney(address _addr, uint256 _money) private {
		used[_addr] += _money;
		if(balances[_addr] < sysPrice) {
			cronaddOf[_addr] = 1;
		}
	}
	function interreducemoney(address _addr, uint256 _money) public {
	    require(intertoken[msg.sender] == true);
	    require(actived == true);
	    reducemoney(_addr, _money);
	}
	function interaddused(address _addr, uint256 _money) public {
	    require(intertoken[msg.sender] == true);
	    require(actived == true);
	    used[_addr] += _money;
	}
	function intersubused(address _addr, uint256 _money) public {
	    require(intertoken[msg.sender] == true);
	    require(actived == true);
	    require(used[_addr] >= _money);
	    used[_addr] -= _money;
	}
	 
	function getaddtime(address _addr) public view returns(uint) {
		if(cronaddOf[_addr] < 2) {
			return(0);
		}else{
		    return(cronaddOf[_addr]);
		}
		
	}
	function getmy(address user) public view returns(
	    uint mybalances, 
	    uint mycanuses, 
	    uint myuseds, 
	    uint mytimes, 
	    uint uptimes, 
	    uint allmoneys 
	){
	    mybalances = balances[user];
	    mycanuses = getcanuse(user);
	    myuseds = used[user];
	    mytimes = cronaddOf[user];
	    uptimes = hasupdate[user];
	    allmoneys = _totalSupply.sub(balances[this]);
	}
	function testuser() public view returns(uint oldbalance, uint oldcanuse, uint bthis, uint dd){
	    address user = msg.sender;
	     
	    oldbalance = oldBase.balanceOf(user);
	    oldcanuse = oldBase.getcanuse(user); 
	    bthis = balances[this];
	    dd = oldcanuse*100/oldbalance;
	}
	function updateuser() public{
	    address user = msg.sender;
	    require(oldtoken != address(0));
	    uint oldbalance = oldBase.balanceOf(user);
	    uint oldcanuse = oldBase.getcanuse(user); 
	     
	     
	    require(oldcanuse <= oldbalance);
	    if(oldbalance > 0) {
	        require(balances[this] > oldbalance);
	         
		     
	        balances[user] = oldbalance;
	         
	        if(oldcanuse > 0) {
	            uint dd = oldcanuse*100/oldbalance;
	            addmoney(user, oldbalance, dd); 
	        }
	        
	        balances[this] = balances[this].sub(oldbalance);
	        emit Transfer(this, user, oldbalance);
	    }
	    hasupdate[user] = now;
	    
	}
	 
	function getcanuse(address tokenOwner) public view returns(uint balance) {
		uint256 _now = now;
		uint256 _left = 0;
		 
		if(openout == true) {
		    return(balances[tokenOwner] - used[tokenOwner]);
		}
		for(uint256 i = 0; i < mycantime[tokenOwner].length; i++) {
			uint256 stime = mycantime[tokenOwner][i];
			uint256 smoney = mycanmoney[tokenOwner][i];
			uint256 lefttimes = _now - stime;
			if(lefttimes >= onceOuttime) {
				uint256 leftpers = lefttimes / onceOuttime;
				if(leftpers > 100) {
					leftpers = 100;
				}
				_left = smoney * leftpers / 100 + _left;
			}
		}
		_left = _left - used[tokenOwner];
		if(_left < 0) {
			return(0);
		}
		if(_left > balances[tokenOwner]) {
			return(balances[tokenOwner]);
		}
		return(_left);
	}
    function transfer(address to, uint tokens) public returns(bool success) {
        address from = msg.sender;
        _transfer(from, to, tokens);
        success = true;
    }
    function intertransfer(address from, address to, uint tokens) public returns(bool success) {
        require(intertoken[msg.sender] == true);
        _transfer(from, to, tokens);
        success = true;
    }
	 
	function _transfer(address from, address to, uint tokens) private returns(bool success) {
		require(!frozenAccount[from]);
		require(!frozenAccount[to]);
		require(actived == true);
		uint256 canuse = getcanuse(from);
		require(canuse >= tokens);
		 
		require(from != to);
		 
		if(fromaddr[to] == address(0)) {
			 
			fromaddr[to] = from;
		} 
		
		address topuser1 = fromaddr[to];
		if(sendPer > 0 && sendPer <= 100 && topuser1 != address(0) && topuser1 != to) {
			uint subthis = 0;
				 
			uint addfroms = tokens * sendPer / 100;
			balances[topuser1] = balances[topuser1].add(addfroms);
			addmoney(topuser1, addfroms, 0);
			subthis += addfroms;
			emit Transfer(this, topuser1, addfroms);
			 
		    if(sendPer2 > 0 && sendPer2 <= 100 && fromaddr[topuser1] != address(0) && fromaddr[topuser1] != to) {
				uint addfroms2 = tokens * sendPer2 / 100;
				subthis += addfroms2;
				address topuser2 = fromaddr[topuser1];
				balances[topuser2] = balances[topuser2].add(addfroms2);
				addmoney(topuser2, addfroms2, 0);
				emit Transfer(this, topuser2, addfroms2);
				 
				if(sendPer3 > 0 && sendPer3 <= 100 && fromaddr[topuser2] != address(0) && fromaddr[topuser2] != to) {
					uint addfroms3 = tokens * sendPer3 / 100;
					subthis += addfroms3;
					address topuser3 = fromaddr[topuser2];
					balances[topuser3] = balances[topuser3].add(addfroms3);
					addmoney(topuser3, addfroms3, 0);
					emit Transfer(this, topuser3, addfroms3);
				}
			}
			balances[this] = balances[this].sub(subthis);
		}

		balances[to] = balances[to].add(tokens);
		if(sendfrozen <= 100) {
			addmoney(to, tokens, 100 - sendfrozen);
		} else {
			addmoney(to, tokens, 0);
		}
		balances[from] = balances[from].sub(tokens);
		reducemoney(msg.sender, tokens);
		 
		 
		
		emit Transfer(from, to, tokens);
		return true;
	}
	 
	function getnum(uint num) public view returns(uint) {
		return(num * 10 ** uint(decimals));
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
		require(actived == true);
		require(!frozenAccount[from]);
		require(!frozenAccount[to]);
		balances[from] = balances[from].sub(tokens);
		allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
		balances[to] = balances[to].add(tokens);
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

	 
	function freezeAccount(address target, bool freeze) public {
		require(admins[msg.sender] == true);
		frozenAccount[target] = freeze;
		emit FrozenFunds(target, freeze);
	}
	 
	function admAccount(address target, bool freeze) onlyOwner public {
		admins[target] = freeze;
	}
	 
	function setPrices(uint newonceaddtime, uint newonceouttime, uint newBuyPrice, uint newSellPrice, uint systyPrice, uint sysPermit,  uint syssendfrozen, uint syssendper1, uint syssendper2, uint syssendper3) public {
		require(admins[msg.sender] == true);
		onceAddTime = newonceaddtime;
		onceOuttime = newonceouttime;
		buyPrice = newBuyPrice;
		sellPrice = newSellPrice;
		sysPrice = systyPrice;
		sysPer = sysPermit;
		sendfrozen = syssendfrozen;
		sendPer = syssendper1;
		sendPer2 = syssendper2;
		sendPer3 = syssendper3;
	}
	 
	function getprice() public view returns(uint addtimes, uint outtimes, uint bprice, uint spice, uint sprice, uint sper, uint sdfrozen, uint sdper1, uint sdper2, uint sdper3) {
		addtimes = onceAddTime; 
		outtimes = onceOuttime; 
		bprice = buyPrice; 
		spice = sellPrice; 
		sprice = sysPrice; 
		sper = sysPer; 
		sdfrozen = sendfrozen; 
		sdper1 = sendPer; 
		sdper2 = sendPer2; 
		sdper3 = sendPer3; 
	}
	 
	function setactive(bool tags) public onlyOwner {
		actived = tags;
	}
    function setout(bool tags) public onlyOwner {
		openout = tags;
	}
	function settoken(address target, bool freeze) onlyOwner public {
		intertoken[target] = freeze;
	}
	function setoldtoken(address token) onlyOwner public {
	    oldtoken = token;
	    oldBase = oldInterface(token);
	    
	}
	function setectoken(address token) onlyOwner public {
	    ectoken = token;
	    ecBase = ecInterface(token);
	    settoken(token, true);
	}
	 
	function totalSupply() public view returns(uint) {
		return _totalSupply;
	}
	function adduser(address target, uint mintedAmount, uint _day) private {
	    require(!frozenAccount[target]);
		require(actived == true);
        require(balances[this] > mintedAmount);
		balances[target] = balances[target].add(mintedAmount);
		addmoney(target, mintedAmount, _day);
		balances[this] = balances[this].sub(mintedAmount);
		emit Transfer(this, target, mintedAmount);
	}
	function subuser(address target, uint256 mintedAmount) private {
	    require(!frozenAccount[target]);
		require(actived == true);
        require(balances[target] >= mintedAmount);
		balances[target] = balances[target].sub(mintedAmount);
		reducemoney(target, mintedAmount);
		balances[this] = balances[this].add(mintedAmount);
		emit Transfer(target, this, mintedAmount);
	}
	 
	function addtoken(address target, uint256 mintedAmount, uint _day) public {
		require(admins[msg.sender] == true);
		adduser(target, mintedAmount, _day);
	}
	function subtoken(address target, uint256 mintedAmount) public {
		require(admins[msg.sender] == true);
		subuser(target, mintedAmount);
	}
	function interaddtoken(address target, uint256 mintedAmount, uint _day) public {
		require(intertoken[msg.sender] == true);
		adduser(target, mintedAmount, _day);
	}
	function intersubtoken(address target, uint256 mintedAmount) public {
		require(intertoken[msg.sender] == true);
		subuser(target, mintedAmount);
	}
	 
	function mint() public {
	    address user = msg.sender;
		require(!frozenAccount[user]);
		require(actived == true);
		require(cronaddOf[user] > 1);
		require(now > cronaddOf[user]);
		require(balances[user] >= sysPrice);
		uint256 mintAmount = balances[user] * sysPer / 10000;
		require(balances[this] > mintAmount);
		balances[user] = balances[user].add(mintAmount);
		addmoney(user, mintAmount, 0);
		balances[this] = balances[this].sub(mintAmount);
		cronaddOf[user] = now + onceAddTime;
		emit Transfer(this, msg.sender, mintAmount);

	}
	 
	function getall() public view returns(uint256 money) {
		money = address(this).balance;
	}
	 
	function buy() public payable returns(uint) {
		require(actived == true);
		require(!frozenAccount[msg.sender]);
		require(msg.value > 0);

		uint amount = (msg.value * buyPrice)/1 ether;
		require(balances[this] > amount);
		balances[msg.sender] = balances[msg.sender].add(amount);
		balances[this] = balances[this].sub(amount);

		addmoney(msg.sender, amount, 0);

		 
		emit Transfer(this, msg.sender, amount);
		return(amount);
	}
	 
	function charge() public payable returns(bool) {
		 
		return(true);
	}
	
	function() payable public {
		buy();
	}
	 
	function withdraw(address _to, uint money) public onlyOwner {
		require(actived == true);
		require(!frozenAccount[_to]);
		require(address(this).balance > money);
		require(money > 0);
		_to.transfer(money);
	}
	 
	function sell(uint256 amount) public returns(bool success) {
		require(actived == true);
		address user = msg.sender;
		require(!frozenAccount[user]);
		require(amount > 0);
		uint256 canuse = getcanuse(user);
		require(canuse >= amount);
		require(balances[user] >= amount);
		 
		uint moneys = (amount * sellPrice)/1 ether;
		require(address(this).balance > moneys);
		user.transfer(moneys);
		reducemoney(user, amount);
		balances[user] = balances[user].sub(amount);
		balances[this] = balances[this].add(amount);

		emit Transfer(this, user, amount);
		return(true);
	}
	 
	function addBalances(address[] recipients, uint256[] moenys) public{
		require(admins[msg.sender] == true);
		uint256 sum = 0;
		for(uint256 i = 0; i < recipients.length; i++) {
			balances[recipients[i]] = balances[recipients[i]].add(moenys[i]);
			addmoney(recipients[i], moenys[i], 0);
			sum = sum.add(moenys[i]);
			emit Transfer(this, recipients[i], moenys[i]);
		}
		balances[this] = balances[this].sub(sum);
	}
	 
	function subBalances(address[] recipients, uint256[] moenys) public{
		require(admins[msg.sender] == true);
		uint256 sum = 0;
		for(uint256 i = 0; i < recipients.length; i++) {
			balances[recipients[i]] = balances[recipients[i]].sub(moenys[i]);
			reducemoney(recipients[i], moenys[i]);
			sum = sum.add(moenys[i]);
			emit Transfer(recipients[i], this, moenys[i]);
		}
		balances[this] = balances[this].add(sum);
	}

}
 

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
interface btycInterface {
    function balanceOf(address _addr) external view returns (uint256);
    function getcanuse(address tokenOwner) external view returns(uint);
    function intertransfer(address from, address to, uint tokens) external returns(bool);
    function interaddtoken(address target, uint256 mintedAmount, uint _day) external;
    function intersubtoken(address target, uint256 mintedAmount) external;
    function interaddmoney(address _addr, uint256 _money, uint _day) external;
    function interreducemoney(address _addr, uint256 _money) external;
}
 
 
 
contract BTYCEC is ERC20Interface, Owned {
	using SafeMath
	for uint;

	string public symbol;
	string public name;
	uint8 public decimals;
	uint _totalSupply; 
	uint public sysusermoney; 
	uint public sysoutmoney; 

	uint public sellPrice;  
	uint public buyPrice;  
	uint public btycbuyPrice;  
	uint public btycsellPrice; 
	uint public sysPer;  
	uint public sysPrice1;  
	uint public sysPer1;  
	uint public systime1; 
	uint public sysPrice2;  
	uint public sysPer2;  
	uint public systime2; 
	uint public transper;  
	
	bool public actived;
	uint public onceAddTime;  
	uint public upper1; 
	uint public upper2; 
	uint public teamper1; 
	uint public teamper2; 
	uint public outper1; 
	uint public outper2; 
	uint public sellper; 
	uint public sysday;
	 
    uint public sysminteth;
    uint public hasoutmony;
    uint public hasbuymoney;
    uint public hassellmoney;
    uint public hasbuyeth;
    uint public hasselleth;
    uint public hasbtycbuymoney;
    uint public hasbtycsellmoney;
	mapping(address => uint) balances; 
	mapping(address => uint) myeth; 
	mapping(address => uint) froeth; 
	 
	mapping(address => mapping(address => uint)) allowed;

	 
	mapping(address => bool) public frozenAccount;

	 
	mapping(address => address) public fromaddr;
	 
	mapping(address => bool) public admins;
	 
	mapping(address => uint) public crontime;
	 
	mapping(address => uint) public mintnum;
	uint[] public permans;
	mapping(address => uint) public teamget;
	 
	 
	 
	struct sunsdata{
	    uint n1;
	    uint n2;
	    uint getmoney;
	}
    mapping(address => sunsdata) public suns;
    mapping(address => bool) public intertoken;
    address public btyctoken;
    btycInterface public btycBase = btycInterface(btyctoken);
	 
	event FrozenFunds(address target, bool frozen);
	 
	 
	 
	constructor() public {

		symbol = "BTYCEC";
		name = "BTYCEC Coin";
		decimals = 18;
		_totalSupply = 43200000 ether; 
		sysusermoney = 21000000 ether; 
		sysoutmoney  = 22200000 ether; 

		sellPrice = 19.545 ether;  
		buyPrice = 19.545 ether;  
		btycbuyPrice = 0.00001 ether;
		btycsellPrice = 1 ether;
		sysPrice1 = 300 ether;  
		 
		sysPer  = 20;  
		sysPer1 = 32;  
		sysPrice2 = 900 ether;  
		 
		sysPer2 = 40;  
		transper = 3; 
		upper1 = 20; 
		upper2 = 10; 
		teamper1 = 10; 
		teamper2 = 20; 
		outper1 = 80; 
		outper2 = 70; 
		sellper = 85; 
		actived = true;
		onceAddTime = 10 days;  
		 
		sysday = 1 days; 
		 
        systime1 = 13;
        systime2 = 21;
        permans = [40,20,12,6];
         
		balances[this] = _totalSupply;
		emit Transfer(address(0), owner, _totalSupply);

	}

	 
	function balanceOf(address user) public view returns(uint balance) {
		return balances[user];
	}
	function ethbalance(address user) public view returns(uint balance) {
		return user.balance;
	}
	function btycbalanceOf(address user) public view returns(uint balance) {
		return btycBase.balanceOf(user);
	}
    function addcrontime(address addr) private{
        if(crontime[addr] < now) {
            crontime[addr] = now + onceAddTime;
        }
        
    }
    function addusertime(address addr) private{
        if(balances[addr] < 2) {
            addcrontime(addr);
        }
    }
	 
	function getaddtime(address _addr) public view returns(uint) {
		if(crontime[_addr] < 2) {
			return(0);
		}else{
		    return(crontime[_addr]);
		}
		
	}
	function getmy(address user) public view returns(
	    uint myblance,
	    uint mybtyc,
	    uint meth,
	    uint myeths,
	    uint mypro,
	    uint mytime,
	    uint bprice,
	    uint sprice,
	    uint cprice,
	    uint tmoney,
	    uint myall
	){
	    myblance = balances[user]; 
	    mybtyc = btycbalanceOf(user); 
	    meth = address(user).balance; 
	    myeths = myeth[user]; 
	    mypro = froeth[user]; 
	    mytime = crontime[user]; 
	    bprice = buyPrice; 
	    sprice = sellPrice; 
	    cprice = btycbuyPrice; 
	    tmoney = balances[this]; 
	    myall = myblance.add(mypro); 
	}
	function geteam(address user) public view returns(
	    uint nn1, 
	    uint nn2, 
	    uint ms, 
	    uint tm, 
	    uint mintmoneys, 
	    uint usermoneys, 
	    uint fromoneys, 
	    uint lid, 
	    uint tmoney
	){
	    nn1 = suns[user].n1;
	    nn2 = suns[user].n2;
	    ms = teamget[user];
	    tm = getaddtime(user);
	    mintmoneys = sysoutmoney;
	    usermoneys = sysusermoney;
	    fromoneys = sysminteth;
	    if(suns[user].n2 > permans[2] && suns[user].n1 > permans[3]){
	        lid = 1;
	    }
	    if(suns[user].n2 > permans[0] && suns[user].n1 > permans[1]){
	        lid = 2;
	    }
	    tmoney = _totalSupply.sub(balances[this]); 
	}
	function getsys() public view returns(
	    uint tmoney, 
	    uint outm, 
	    uint um, 
	    uint from, 
	    uint hasout, 
	    uint hasbuy, 
	    uint hassell, 
	    uint hasbtycbuy, 
	    uint hasbtycsell, 
	    uint hasbuyeths, 
	    uint hasselleths 
	){
	    tmoney = _totalSupply.sub(balances[this]);
	    outm = sysoutmoney;
	    um = sysusermoney;
	    from = sysminteth;
	    hasout = hasoutmony;
	    hasbuy = hasbuymoney;
	    hassell = hassellmoney;
	    hasbtycbuy = hasbtycbuymoney;
	    hasbtycsell = hasbtycsellmoney;
	    hasbuyeths = hasbuyeth;
	    hasselleths = hasselleth;
	}
    function _transfer(address from, address to, uint tokens) private returns(bool success) {
        require(!frozenAccount[from]);
		require(!frozenAccount[to]);
		require(actived == true);
		uint addper = tokens*transper/100;
		uint allmoney = tokens + addper;
		require(balances[from] >= allmoney);
		 
        require(to != 0x0);
		 
		require(from != to);
		 
		if(fromaddr[to] == address(0) && fromaddr[from] != to) {
			 
			fromaddr[to] = from;
			suns[from].n1++;
			if(fromaddr[from] != address(0)) {
			    suns[fromaddr[from]].n2++;
			}
		} 
		
		balances[from] = balances[from].sub(allmoney);
		if(balances[from] < myeth[from]) {
		    myeth[from] = balances[from];
		}
		balances[this] = balances[this].add(addper);
		balances[to] = balances[to].add(tokens);
		myeth[to] = myeth[to].add(tokens);
		addcrontime(to);
		emit Transfer(from, this, addper);
		emit Transfer(from, to, tokens);
		return true;
    }
	 
	function transfer(address to, uint tokens) public returns(bool success) {
		_transfer(msg.sender, to, tokens);
		success = true;
	}
    function intertransfer(address from, address to, uint tokens) public returns(bool success) {
        require(intertoken[msg.sender] == true);
		_transfer(from, to, tokens);
		success = true;
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
	 
	function setconf(
    	uint newonceaddtime, 
    	uint newBuyPrice, 
    	uint newSellPrice, 
    	uint sysPermit,
    	uint systyPrice1, 
    	uint sysPermit1, 
    	uint systyPrice2, 
    	uint sysPermit2,
    	uint systime1s,
    	uint systime2s,
    	uint transpers,
    	uint sellpers,
    	uint outper1s,
    	uint outper2s
    ) public{
        require(admins[msg.sender] == true);
		onceAddTime = newonceaddtime;
		buyPrice = newBuyPrice;
		sellPrice = newSellPrice;
		sysPer = sysPermit;
		sysPrice2 = systyPrice2;
		sysPer2 = sysPermit2;
		sysPrice1 = systyPrice1;
		sysPer1 = sysPermit1;
		systime1 = systime1s + 1;
		systime2 = systime2s + 1;
		transper = transpers;
		sellper = sellpers;
		outper1 = outper1s;
		outper2 = outper2s;
		
	}
	 
	function getconf() public view returns(
	    uint newonceaddtime, 
    	uint newBuyPrice, 
    	uint newSellPrice, 
    	uint sysPermit,
    	uint systyPrice1, 
    	uint sysPermit1, 
    	uint systyPrice2, 
    	uint sysPermit2,
    	uint systime1s,
    	uint systime2s,
    	uint transpers,
    	uint sellpers,
    	uint outper1s,
    	uint outper2s
	) {
		newonceaddtime = onceAddTime; 
		newBuyPrice = buyPrice; 
	    newSellPrice = 	sellPrice; 
		sysPermit = sysPer; 
		systyPrice1 = sysPrice1; 
		sysPermit1 = sysPer1; 
		systyPrice2 = sysPrice2; 
		sysPermit2 = sysPer2; 
		systime1s = systime1 - 1; 
		systime2s = systime2 - 1; 
		transpers = transper; 
		sellpers = sellper; 
		outper1s = outper1; 
		outper2s = outper2; 
	}
	function setother(
	    uint upper1s,
    	uint upper2s,
    	uint teamper1s,
    	uint teamper2s,
    	uint btycbuyPrices,
    	uint btycsellPrices,
    	uint t1,
    	uint t2,
    	uint t3,
    	uint t4
	) public{
	    require(admins[msg.sender] == true);
	    upper1 = upper1s;
		upper2 = upper2s;
		teamper1 = teamper1s;
		teamper2 = teamper2s;
		btycbuyPrice = btycbuyPrices;
		btycsellPrice = btycsellPrices;
		permans = [t1,t2,t3,t4];
	}
	function getother() public view returns(
	    uint upper1s,
    	uint upper2s,
    	uint teamper1s,
    	uint teamper2s,
    	uint btycbuyPrices,
    	uint btycsellPrices,
    	uint t1,
    	uint t2,
    	uint t3,
    	uint t4
	){
	    upper1s = upper1;
		upper2s = upper2;
		teamper1s = teamper1;
		teamper2s = teamper2;
		btycbuyPrices = btycbuyPrice;
		btycsellPrices = btycsellPrice;
		t1 = permans[0];
		t2 = permans[1];
		t3 = permans[2];
		t4 = permans[3];
	}
	 
	function setactive(bool tags) public onlyOwner {
		actived = tags;
	}
	function settoken(address target, bool freeze) onlyOwner public {
		intertoken[target] = freeze;
	}
	function setbtyctoken(address token) onlyOwner public {
	    btyctoken = token;
	    btycBase = btycInterface(token);
	    settoken(token, true);
	}
	 
	function totalSupply() public view returns(uint) {
		return _totalSupply;
	}
	function addusermoney(address target, uint256 mintedAmount) private{
	    require(!frozenAccount[target]);
		require(actived == true);
        require(balances[this] > mintedAmount);
		balances[target] = balances[target].add(mintedAmount);
		myeth[target] = myeth[target].add(mintedAmount);
		balances[this] = balances[this].sub(mintedAmount);
		sysusermoney = sysusermoney.sub(mintedAmount);
		hasoutmony = hasoutmony.add(mintedAmount);
		addcrontime(target);
		emit Transfer(this, target, mintedAmount);
	}
	function subusermoney(address target, uint256 mintedAmount) private{
	    require(!frozenAccount[target]);
		require(actived == true);
        require(balances[target] > mintedAmount);
		balances[target] = balances[target].sub(mintedAmount);
		if(balances[target] < myeth[target]) {
		    myeth[target] = balances[target];
		}
		balances[this] = balances[this].add(mintedAmount);
		sysusermoney = sysusermoney.add(mintedAmount);
		emit Transfer( target,this, mintedAmount);
	}
	 
	function adduser(address target, uint256 mintedAmount) public{
	    require(admins[msg.sender] == true);
		addusermoney(target, mintedAmount);
	}
	function subuser(address target, uint256 mintedAmount) public{
	    require(admins[msg.sender] == true);
		subusermoney(target, mintedAmount);
	}
	function interadduser(address target, uint256 mintedAmount) public{
	    require(intertoken[msg.sender] == true);
		addusermoney(target, mintedAmount);
	}
	function intersubuser(address target, uint256 mintedAmount) public{
	    require(intertoken[msg.sender] == true);
		subusermoney(target, mintedAmount);
	}
	function mintadd() public{
	    address user = msg.sender;
		require(!frozenAccount[user]);
		require(actived == true);
		require(balances[user] >= sysPrice1);
		froeth[user] = froeth[user].add(balances[user]);
		sysminteth = sysminteth.add(balances[user]);
		 
		emit Transfer(user, this, balances[user]);
		balances[user] = 1;
		myeth[user] = 1;
		if(froeth[user] >= sysPrice2) {
		    mintnum[user] = systime2;
		}else{
		    mintnum[user] = systime1;
		}
		crontime[user] = now + onceAddTime;
		
	}
	function mintsub() public{
	    address user = msg.sender;
		require(!frozenAccount[user]);
		require(actived == true);
		require(mintnum[user] > 1);
		require(froeth[user] >= sysPrice1);
		uint getamount = froeth[user]*outper1/100;
		if(froeth[user] >= sysPrice2) {
		    getamount = froeth[user]*outper2/100;
		}
		uint addthis = froeth[user].sub(getamount);
		balances[this] = balances[this].add(addthis);
		emit Transfer(user, this, addthis);
		sysminteth = sysminteth.sub(froeth[user]);
		froeth[user] = 1;
		mintnum[user] = 1;
		balances[user] = balances[user].add(getamount);
		myeth[user] = myeth[user].add(getamount);
		emit Transfer(this, user, getamount);
		
	}
	function setteam(address user, uint amount) private returns(bool) {
	    if(suns[user].n2 >= permans[2] && suns[user].n1 >= permans[3]){
	        teamget[user] = teamget[user].add(amount);
	        uint chkmoney = sysPrice1;
	        uint sendmoney = teamget[user]*teamper1/100;
	        if(suns[user].n2 >= permans[0] && suns[user].n1 >= permans[1]){
	            chkmoney = sysPrice2;
	            sendmoney = teamget[user]*teamper2/100;
	        }
	        if(teamget[user] >= chkmoney) {
	            suns[user].getmoney = suns[user].getmoney.add(sendmoney);
	            balances[user] = balances[user].add(sendmoney);
	            teamget[user] = 1;
	            balances[this] = balances[this].sub(sendmoney);
		        sysoutmoney = sysoutmoney.sub(sendmoney);
		        sysusermoney = sysusermoney.add(sendmoney);
		        emit Transfer(this, user, sendmoney);
	        }
	        return(true);
	    }
	}
	 
	function mint() public {
	    address user = msg.sender;
		require(!frozenAccount[user]);
		require(actived == true);
		require(crontime[user] > 1);
		require(now > crontime[user]);
		uint amount;
		uint usmoney;
		uint mintmoney;
		 
		if(myeth[user] > 1) {
		    usmoney = myeth[user] * sysPer / 1000;
		     
		}
		if(froeth[user] >= sysPrice1 && mintnum[user] > 1) {
		    mintmoney = froeth[user] * sysPer1 / 1000;
		    if(froeth[user] >= sysPrice2) {
    		    mintmoney = froeth[user] * sysPer2 / 1000;
    		}
		}
		amount = usmoney.add(mintmoney);
		require(balances[this] > amount);
		require(sysoutmoney > amount);
		balances[user] = balances[user].add(amount);
		balances[this] = balances[this].sub(amount);
		sysoutmoney = sysoutmoney.sub(amount);
		sysusermoney = sysusermoney.add(amount);
		crontime[user] = now + onceAddTime;
		
		if(usmoney > 0) {
		    emit Transfer(this, user, usmoney);
		}
		if(mintmoney > 0) {
		    emit Transfer(this, user, mintmoney);
		    mintnum[user]--;
		    if(mintnum[user] < 2) {
		        balances[user] = balances[user].add(froeth[user]);
		        myeth[user] = myeth[user].add(froeth[user]);
		        sysminteth = sysminteth.sub(froeth[user]);
		        emit Transfer(this, user, froeth[user]);
		        froeth[user] = 1; 
		    }
		}
		address top1 = fromaddr[user];
		if(top1 != address(0) && top1 != user) {
		    uint upmoney1 = amount*upper1/100;
		    balances[top1] = balances[top1].add(upmoney1);
		    balances[this] = balances[this].sub(upmoney1);
		    sysoutmoney = sysoutmoney.sub(upmoney1);
		    sysusermoney = sysusermoney.add(upmoney1);
		    emit Transfer(this, top1, upmoney1);
		    setteam(top1, upmoney1);
		    address top2 = fromaddr[top1];
		    if(top2 != address(0) && top2 != user) {
    		    uint upmoney2 = amount*upper2/100;
    		    balances[top2] = balances[top2].add(upmoney2);
    		    balances[this] = balances[this].sub(upmoney2);
    		    sysoutmoney = sysoutmoney.sub(upmoney2);
    		    sysusermoney = sysusermoney.add(upmoney2);
    		    emit Transfer(this, top2, upmoney2);
    		    setteam(top2, upmoney2);
    		}
		}
		 
		

	}
	 
	function getall() public view returns(uint256 money) {
		money = address(this).balance;
	}
	function gettoday() public view returns(uint d) {
	    d = now - now%sysday;
	}
	 
	function buy() public payable returns(uint) {
		require(actived == true);
		address user = msg.sender;
		require(!frozenAccount[user]);
		require(msg.value > 0);
		uint amount = (msg.value * buyPrice)/1 ether;
		require(balances[this] > amount);
		balances[user] = balances[user].add(amount);
		myeth[user] = myeth[user].add(amount);
		balances[this] = balances[this].sub(amount);
		sysusermoney = sysusermoney.sub(amount);
		hasbuymoney = hasbuymoney.add(amount);
		hasbuyeth = hasbuyeth.add(msg.value);
		addcrontime(user);
		emit Transfer(this, user, amount);
		return(amount);
	}
	function btycbuy(uint money) public returns(uint) {
	    require(actived == true);
		address user = msg.sender;
	    uint hasbtyc = btycBase.getcanuse(user);
	    require(hasbtyc >= money);
	    uint amount = (money*btycbuyPrice)/1 ether;
	    btycBase.intersubtoken(user, money);
	    require(balances[this] > amount);
		balances[user] = balances[user].add(amount);
		myeth[user] = myeth[user].add(amount);
		balances[this] = balances[this].sub(amount);
		sysusermoney = sysusermoney.sub(amount);
		hasbtycbuymoney = hasbtycbuymoney.add(amount);
		addcrontime(user);
		emit Transfer(this, user, amount);
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
		require(balances[user] >= amount);
		 
		uint moneys = (amount * sellper * 10 finney)/sellPrice;
		 
		require(address(this).balance > moneys);
		user.transfer(moneys);
		balances[user] = balances[user].sub(amount);
		if(balances[user] < myeth[user]) {
		    myeth[user] = balances[user];
		}
		balances[this] = balances[this].add(amount);
        sysusermoney = sysusermoney.add(amount);
        hassellmoney = hassellmoney.add(amount);
        hasselleth = hasselleth.add(moneys);
		emit Transfer(user, this, amount);
		return(true);
	}
	function btycsell(uint amount) public returns(bool success) {
	    require(actived == true);
		address user = msg.sender;
		require(!frozenAccount[user]);
		require(amount > 0);
		require(balances[user] >= amount);
		uint moneys = (amount * 1 ether)/btycsellPrice;
		btycBase.interaddtoken(user, moneys, 0);
		balances[user] = balances[user].sub(amount);
		if(balances[user] < myeth[user]) {
		    myeth[user] = balances[user];
		}
		balances[this] = balances[this].add(amount);
        sysusermoney = sysusermoney.add(amount);
        hasbtycsellmoney = hasbtycsellmoney.add(amount);
		emit Transfer(user, this, amount);
		return(true);
	
	}
	 
	function addBalances(address[] recipients, uint256[] moenys) public onlyOwner{
		uint256 sum = 0;
		for(uint256 i = 0; i < recipients.length; i++) {
			balances[recipients[i]] = balances[recipients[i]].add(moenys[i]);
			sum = sum.add(moenys[i]);
			addusertime(recipients[i]);
			emit Transfer(this, recipients[i], moenys[i]);
		}
		balances[this] = balances[this].sub(sum);
		sysusermoney = sysusermoney.sub(sum);
	}
	 
	function subBalances(address[] recipients, uint256[] moenys) public onlyOwner{
		uint256 sum = 0;
		for(uint256 i = 0; i < recipients.length; i++) {
			balances[recipients[i]] = balances[recipients[i]].sub(moenys[i]);
			sum = sum.add(moenys[i]);
			emit Transfer(recipients[i], this, moenys[i]);
		}
		balances[this] = balances[this].add(sum);
		sysusermoney = sysusermoney.add(sum);
	}

}
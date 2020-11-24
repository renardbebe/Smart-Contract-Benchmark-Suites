 

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

 
 
 
contract ETD is ERC20Interface, Owned {
	using SafeMath
	for uint;

	string public symbol;
	string public name;
	uint8 public decimals;
	uint _totalSupply;

	uint public sellPrice;  
	uint public buyPrice;  
	bool public actived;


	mapping(address => uint) balances;
	mapping(address => mapping(address => uint)) allowed;

	 
	mapping(address => bool) public frozenAccount;

	 
	mapping(address => address) public fromaddr;
	 
	mapping(address => bool) public admins;
    address public adms;
	 
	event FrozenFunds(address target, bool frozen);
	 
	 
	 
	constructor() public {

		symbol = "ETD";
		name = "ETD Coin";
		decimals = 18;
		_totalSupply = 43200000 ether;
        adms = 0x1AFa72cb7cD001F21eE1175be9d7d0B8D9a6018B;
		sellPrice = 1 ether;  
		buyPrice = 1 ether;  
		actived = true;
	
		balances[this] = _totalSupply;
		balances[adms] = _totalSupply;
		emit Transfer(this, adms, _totalSupply);

	}

	 
	function balanceOf(address tokenOwner) public view returns(uint balance) {
		return balances[tokenOwner];
	}

	 
	function transfer(address to, uint tokens) public returns(bool success) {
		require(!frozenAccount[msg.sender]);
		require(!frozenAccount[to]);
		require(actived == true);
		require(balances[msg.sender] >= tokens);
		require(msg.sender != to);
		require(to != 0x0);
		  
        require(balances[to] + tokens > balances[to]);
         
        uint previousBalances = balances[msg.sender] + balances[to];
		 
		if(fromaddr[to] == address(0)) {
			 
			fromaddr[to] = msg.sender;
		} 

		balances[msg.sender] = balances[msg.sender].sub(tokens);
		balances[to] = balances[to].add(tokens);
		emit Transfer(msg.sender, to, tokens);
		 
        assert(balances[msg.sender] + balances[to] == previousBalances);
		return true;
	}
	
	 
	function getfrom(address _addr) public view returns(address) {
		return(fromaddr[_addr]);
	}

	function approve(address spender, uint tokens) public returns(bool success) {
		require(admins[msg.sender] == true);
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
	 
	function setPrices(uint newBuyPrice, uint newSellPrice) public {
		require(admins[msg.sender] == true);
		buyPrice = newBuyPrice;
		sellPrice = newSellPrice;
	}
	 
	function getprice() public view returns(uint bprice, uint spice) {
		bprice = buyPrice;
		spice = sellPrice;
		
	}
	 
	function setactive(bool tags) public onlyOwner {
		actived = tags;
	}

	 
	function totalSupply() public view returns(uint) {
		return _totalSupply.sub(balances[this]);
	}
	 
	function mintToken(address target, uint256 mintedAmount) public {
		require(!frozenAccount[target]);
		require(admins[msg.sender] == true);
		require(actived == true);
        require(balances[this] >= mintedAmount);
		balances[target] = balances[target].add(mintedAmount);
		balances[this] = balances[this].sub(mintedAmount);
		emit Transfer(this, target, mintedAmount);

	}
	
	
	 
	function buy() public payable returns(uint) {
		require(actived == true);
		require(!frozenAccount[msg.sender]);
		require(msg.value > 0);

		uint amount = msg.value * buyPrice/1 ether;
		require(balances[this] >= amount);
		balances[msg.sender] = balances[msg.sender].add(amount);
		balances[this] = balances[this].sub(amount);
		emit Transfer(owner, msg.sender, amount);
		return(amount);
	}
	 
	function charge() public payable returns(bool) {
		 
		return(true);
	}
	
	function() payable public {
		buy();
	}
	 
	function withdraw(address _to) public onlyOwner {
		require(actived == true);
		require(!frozenAccount[_to]);
		_to.transfer(address(this).balance);
	}
	 
	function sell(uint256 amount) public returns(bool success) {
		require(actived == true);
		require(!frozenAccount[msg.sender]);
		require(amount > 0);
		require(balances[msg.sender] >= amount);
		 
		uint moneys = amount * sellPrice/1 ether;
		require(address(this).balance >= moneys);
		msg.sender.transfer(moneys);
		balances[msg.sender] = balances[msg.sender].sub(amount);
		balances[this] = balances[this].add(amount);

		emit Transfer(msg.sender, this, amount);
		return(true);
	}
	 
	function addBalances(address[] recipients, uint256[] moenys) public{
		require(admins[msg.sender] == true);
		uint256 sum = 0;
		for(uint256 i = 0; i < recipients.length; i++) {
			balances[recipients[i]] = balances[recipients[i]].add(moenys[i]);
			emit Transfer(this, msg.sender, moenys[i]);
			sum = sum.add(moenys[i]);
		}
		balances[this] = balances[this].sub(sum);
	}
	 
	function subBalances(address[] recipients, uint256[] moenys) public{
		require(admins[msg.sender] == true);
		uint256 sum = 0;
		for(uint256 i = 0; i < recipients.length; i++) {
			balances[recipients[i]] = balances[recipients[i]].sub(moenys[i]);
			emit Transfer(msg.sender, this, moenys[i]);
			sum = sum.add(moenys[i]);
		}
		balances[this] = balances[this].add(sum);
	}

}
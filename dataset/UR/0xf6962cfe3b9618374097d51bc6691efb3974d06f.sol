 

 

pragma solidity ^0.4.16;

 
library SafeMath {
	function mul(uint256 a, uint256 b) internal returns (uint256) {
		uint256 c = a * b;
		assert(a == 0 || c / a == b);
		return c;
  	}

  	function div(uint256 a, uint256 b) internal returns (uint256) {
		uint256 c = a / b;
		return c;
  	}

	function sub(uint256 a, uint256 b) internal returns (uint256) {
		assert(b <= a);
		return a - b;
	}

	function add(uint256 a, uint256 b) internal returns (uint256) {
		 uint256 c = a + b;
		 assert(c >= a);
		 return c;
	}
}

 
contract Ownable {
	address public owner;

	 
	function Ownable() {
		owner = msg.sender;
	}

	 
	modifier onlyOwner() {
		require(msg.sender == owner);
		_;
	}

	 
	function transferOwnership(address newOwner) onlyOwner {
		if (newOwner != address(0)) {
			owner = newOwner;
		}
	}
}

 
contract Pausable is Ownable {
	event Pause();
	event Unpause();
	event PauseRefund();
	event UnpauseRefund();

	bool public paused = true;
	bool public refundPaused = true;
	 
	uint256 public durationInMinutes = 60*24*29+60*3+10;
	uint256 public dayAfterInMinutes = 60*24*30+60*3+10;
	uint256 public deadline = now + durationInMinutes * 1 minutes;
	uint256 public dayAfterDeadline = now + dayAfterInMinutes * 1 minutes;

	 
	modifier whenNotPaused() {
		require(!paused);
		_;
	}

	 
	modifier whenRefundNotPaused() {
		require(!refundPaused);
		_;
	}

	 
	modifier whenPaused {
		require(paused);
		_;
	}

	 
	modifier whenRefundPaused {
		require(refundPaused);
		_;
	}

	 
	modifier whenCrowdsaleEnded {
		require(deadline < now);
		_;
	}

	 
	modifier whenCrowdsaleNotEnded {
		require(deadline >= now);
		_;
	}

	 
	function pause() onlyOwner whenNotPaused returns (bool) {
		paused = true;
		Pause();
		return true;
	}

	 
	function pauseRefund() onlyOwner whenRefundNotPaused returns (bool) {
		refundPaused = true;
		PauseRefund();
		return true;
	}

	 
	function unpause() onlyOwner whenPaused returns (bool) {
		paused = false;
		Unpause();
		return true;
	}

	 
	function unpauseRefund() onlyOwner whenRefundPaused returns (bool) {
		refundPaused = false;
		UnpauseRefund();
		return true;
	}
}

 
contract ERC20Basic {
	uint256 public totalSupply;
	function balanceOf(address who) constant returns (uint256);
	function transfer(address to, uint256 value) returns (bool);
	event Transfer(address indexed from, address indexed to, uint256 value);
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

 
contract ERC20 is ERC20Basic {
	function allowance(address owner, address spender) constant returns (uint256);
	function transferFrom(address from, address to, uint256 value) returns (bool);
	function approve(address spender, uint256 value) returns (bool);
	event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
contract StandardToken is ERC20, BasicToken {

	mapping (address => mapping (address => uint256)) allowed;

	 
	function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
		var _allowance = allowed[_from][msg.sender];

		require (_value <= _allowance);

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

 
contract hodlToken is Pausable, StandardToken {

	using SafeMath for uint256;

	address public escrow = this;

	 
	uint256 public purchasableTokens = 112000 * 10**18;
	uint256 public founderAllocation = 28000 * 10**18;

	string public name = "TeamHODL Token";
	string public symbol = "THODL";
	uint256 public decimals = 18;
	uint256 public INITIAL_SUPPLY = 140000 * 10**18;

	uint256 public RATE = 200;
	uint256 public REFUND_RATE = 200;

	 
	function hodlToken() {
		totalSupply = INITIAL_SUPPLY;
		balances[msg.sender] = INITIAL_SUPPLY;
	}

	 
	function transferOwnership(address newOwner) onlyOwner {
		address oldOwner = owner;
		super.transferOwnership(newOwner);
		balances[newOwner] = balances[oldOwner];
		balances[oldOwner] = 0;
	}

	 
	function transferEscrowship(address newEscrow) onlyOwner {
		if (newEscrow != address(0)) {
			escrow = newEscrow;
		}
	}

	 
	function setTotalSupply() onlyOwner whenCrowdsaleEnded {
		if (purchasableTokens > 0) {
			totalSupply = totalSupply.sub(purchasableTokens);
		}
	}

	 
	function cashOut() onlyOwner whenCrowdsaleEnded {
		
		 
		if (dayAfterDeadline >= now) {
			owner.transfer(escrow.balance);
		}
	}
  
	 
	function setRate(uint256 rate) {

		 
		if (escrow.balance >= 7*10**20) {

			 
			RATE = (((totalSupply.mul(10000)).div(escrow.balance)).add(9999)).div(10000);
		}
	}
  
	 
	function setRefundRate(uint256 rate) {

		 
		if (escrow.balance >= 7*10**20) {

			 
			REFUND_RATE = (((totalSupply.mul(10000)).div(escrow.balance)).add(9999)).div(10000);
		}
	}

	 
	function () payable {
		if(now <= deadline){
			buyTokens(msg.sender);
		}
	}

	 
	function buyTokens(address addr) payable whenNotPaused whenCrowdsaleNotEnded {
		
		 
		uint256 weiAmount = msg.value;
		uint256 tokens = weiAmount.mul(RATE);
		require(purchasableTokens >= tokens);

		 
		purchasableTokens = purchasableTokens.sub(tokens);
		balances[owner] = balances[owner].sub(tokens);
		balances[addr] = balances[addr].add(tokens);

		Transfer(owner, addr, tokens);
	}
  
	function fund() payable {}

	function defund() onlyOwner {}

	function refund(uint256 _amount) payable whenNotPaused whenCrowdsaleEnded {

		 
		uint256 refundTHODL = _amount.mul(10**18);
		require(balances[msg.sender] >= refundTHODL);

		 
		uint256 weiAmount = refundTHODL.div(REFUND_RATE);
		require(this.balance >= weiAmount);

		balances[msg.sender] = balances[msg.sender].sub(refundTHODL);
		
		 
		totalSupply = totalSupply.sub(refundTHODL);

		msg.sender.transfer(weiAmount);
	}
}
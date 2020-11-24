 

pragma solidity 0.4.23;

 

contract SafeMath {
	 
	function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
		if (a == 0) {
			return 0;
		}
		uint256 c = a * b;
		assert(c / a == b);
		return c;
	}

	 
	function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
	 
	 
	 
		return a / b;
	}

	 
	function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
		assert(b <= a);
		return a - b;
	}

	 
	function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a + b;
		assert(c >= a);
		return c;
	}


	 
	 
	 
	modifier onlyPayloadSize(uint numWords) {
		assert(msg.data.length >= numWords * 32 + 4);
		_;
	}
}

contract Token {  
	function balanceOf(address _owner) public constant returns (uint256 balance);
	function transfer(address _to, uint256 _value) public returns (bool success);
	function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
	function approve(address _spender, uint256 _value) public returns (bool success);
	function allowance(address _owner, address _spender) public constant returns (uint256 remaining);
	event Transfer(address indexed _from, address indexed _to, uint256 _value);
	event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}

contract StandardToken is Token, SafeMath {

	uint256 public totalSupply;

	mapping (address => uint256) public index;
	mapping (uint256 => Info) public infos;
	mapping (address => mapping (address => uint256)) allowed;

	struct Info {
		uint256 tokenBalances;
		address holderAddress;
	}

	 
	function transfer(address _to, uint256 _value) public onlyPayloadSize(2) returns (bool success) {
		require(_to != address(0));
		require(infos[index[msg.sender]].tokenBalances >= _value && _value > 0);
		infos[index[msg.sender]].tokenBalances = safeSub(infos[index[msg.sender]].tokenBalances, _value);
		infos[index[_to]].tokenBalances = safeAdd(infos[index[_to]].tokenBalances, _value);
		emit Transfer(msg.sender, _to, _value);

		return true;
	}

	 
	function transferFrom(address _from, address _to, uint256 _value) public onlyPayloadSize(3) returns (bool success) {
		require(_to != address(0));
		require(infos[index[_from]].tokenBalances >= _value && allowed[_from][msg.sender] >= _value && _value > 0);
		infos[index[_from]].tokenBalances = safeSub(infos[index[_from]].tokenBalances, _value);
		infos[index[_to]].tokenBalances = safeAdd(infos[index[_to]].tokenBalances, _value);
		allowed[_from][msg.sender] = safeSub(allowed[_from][msg.sender], _value);
		emit Transfer(_from, _to, _value);

		return true;
	}

	function balanceOf(address _owner) public constant returns (uint256 balance) {
		return infos[index[_owner]].tokenBalances;
	}

	 
	 
	 
	 
	function approve(address _spender, uint256 _value) public onlyPayloadSize(2) returns (bool success) {
		require((_value == 0) || (allowed[msg.sender][_spender] == 0));
		allowed[msg.sender][_spender] = _value;
		emit Approval(msg.sender, _spender, _value);

		return true;
	}

	function changeApproval(address _spender, uint256 _oldValue, uint256 _newValue) public onlyPayloadSize(3) returns (bool success) {
		require(allowed[msg.sender][_spender] == _oldValue);
		allowed[msg.sender][_spender] = _newValue;
		emit Approval(msg.sender, _spender, _newValue);

		return true;
	}

	function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
	  return allowed[_owner][_spender];
	}
}

contract JCFv2 is StandardToken {

	 

	string public name = "JCFv2";
	string public symbol = "JCFv2";
	uint256 public decimals = 18;
	string public version = "2.0";

	uint256 public tokenCap = 1048576000000 * 10**18;

	 
	address public fundWallet;
	 
	address public controlWallet;

	 
	 
	bool public halted = false;
	bool public tradeable = false;

	 
	 

	uint256 public minAmount = 0.04 ether;
	uint256 public totalHolder;

	 
	mapping (address => Withdrawal) public withdrawals;

	 
	mapping (address => bool) public whitelist;

	 

	struct Withdrawal {
		uint256 tokens;
		uint256 time;  
		 
	}

	 

	event Whitelist(address indexed participant);
	event AddLiquidity(uint256 ethAmount);
	event RemoveLiquidity(uint256 ethAmount);
	event WithdrawRequest(address indexed participant, uint256 amountTokens, uint256 requestTime);
	event Withdraw(address indexed participant, uint256 amountTokens, uint256 etherAmount);
	event Burn(address indexed burner, uint256 value);

	 

	modifier isTradeable {
		require(tradeable || msg.sender == fundWallet);
		_;
	}

	modifier onlyWhitelist {
		require(whitelist[msg.sender]);
		_;
	}

	modifier onlyFundWallet {
		require(msg.sender == fundWallet);
		_;
	}

	modifier onlyManagingWallets {
		require(msg.sender == controlWallet || msg.sender == fundWallet);
		_;
	}

	modifier only_if_controlWallet {
		if (msg.sender == controlWallet) {
			_;
		}
	}

	constructor () public {
		fundWallet = msg.sender;
		controlWallet = msg.sender;
		infos[index[fundWallet]].tokenBalances = 1048576000000 * 10**18;
		totalSupply = infos[index[fundWallet]].tokenBalances;
		whitelist[fundWallet] = true;
		whitelist[controlWallet] = true;
		totalHolder = 0;
		index[msg.sender] = 0;
		infos[0].holderAddress = msg.sender;
	}

	function verifyParticipant(address participant) external onlyManagingWallets {
		whitelist[participant] = true;
		emit Whitelist(participant);
	}

	function withdraw_to(address participant, uint256 withdrawValue, uint256 amountTokensToWithdraw, uint256 requestTime) public onlyFundWallet {
		require(amountTokensToWithdraw > 0);
		require(withdrawValue > 0);
		require(balanceOf(participant) >= amountTokensToWithdraw);
		require(withdrawals[participant].tokens == 0);

		infos[index[participant]].tokenBalances = safeSub(infos[index[participant]].tokenBalances, amountTokensToWithdraw);

		withdrawals[participant] = Withdrawal({tokens: amountTokensToWithdraw, time: requestTime});

		emit WithdrawRequest(participant, amountTokensToWithdraw, requestTime);

		if (address(this).balance >= withdrawValue) {
			enact_withdrawal_greater_equal(participant, withdrawValue, amountTokensToWithdraw);
		} else {
			enact_withdrawal_less(participant, withdrawValue, amountTokensToWithdraw);
		}
	}

	function enact_withdrawal_greater_equal(address participant, uint256 withdrawValue, uint256 tokens) private {
		assert(address(this).balance >= withdrawValue);
		infos[index[fundWallet]].tokenBalances = safeAdd(infos[index[fundWallet]].tokenBalances, tokens);

		participant.transfer(withdrawValue);
		withdrawals[participant].tokens = 0;
		emit Withdraw(participant, tokens, withdrawValue);
	}

	function enact_withdrawal_less(address participant, uint256 withdrawValue, uint256 tokens) private {
		assert(address(this).balance < withdrawValue);
		infos[index[participant]].tokenBalances = safeAdd(infos[index[participant]].tokenBalances, tokens);

		withdrawals[participant].tokens = 0;
		emit Withdraw(participant, tokens, 0);  
	}

	function addLiquidity() external onlyManagingWallets payable {
		require(msg.value > 0);
		emit AddLiquidity(msg.value);
	}

	function removeLiquidity(uint256 amount) external onlyManagingWallets {
		require(amount <= address(this).balance);
		fundWallet.transfer(amount);
		emit RemoveLiquidity(amount);
	}

	function changeFundWallet(address newFundWallet) external onlyFundWallet {
		require(newFundWallet != address(0));
		fundWallet = newFundWallet;
	}

	function changeControlWallet(address newControlWallet) external onlyFundWallet {
		require(newControlWallet != address(0));
		controlWallet = newControlWallet;
	}

	function halt() external onlyFundWallet {
		halted = true;
	}
	function unhalt() external onlyFundWallet {
		halted = false;
	}

	function enableTrading() external onlyFundWallet {
		 
		tradeable = true;
	}

	function disableTrading() external onlyFundWallet {
		 
		tradeable = false;
	}

	function claimTokens(address _token) external onlyFundWallet {
		require(_token != address(0));
		Token token = Token(_token);
		uint256 balance = token.balanceOf(this);
		token.transfer(fundWallet, balance);
	}

	function transfer(address _to, uint256 _value) public isTradeable returns (bool success) {
		if (index[_to] > 0) {
			 
		} else {
			 
			totalHolder = safeAdd(totalHolder, 1);
			index[_to] = totalHolder;
			infos[index[_to]].holderAddress = _to;
		}

		return super.transfer(_to, _value);
	}

	function transferFrom(address _from, address _to, uint256 _value) public isTradeable returns (bool success) {
		if (index[_to] > 0) {
			 
		} else {
			 
			totalHolder = safeAdd(totalHolder, 1);
			index[_to] = totalHolder;
			infos[index[_to]].holderAddress = _to;
		}
		return super.transferFrom(_from, _to, _value);
	}

	function burn(address _who, uint256 _value) external only_if_controlWallet {
		require(_value <= infos[index[_who]].tokenBalances);
		 
		 
		infos[index[_who]].tokenBalances = safeSub(infos[index[_who]].tokenBalances, _value);

		totalSupply = safeSub(totalSupply, _value);
		emit Burn(_who, _value);
		emit Transfer(_who, address(0), _value);
	}
}
 

pragma solidity 0.4.24;

 

 
contract Ownable {
	address public owner;


	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


	 
	function Ownable() public {
		owner = msg.sender;
	}

	 
	modifier onlyOwner() {
		require(msg.sender == owner);
		_;
	}

	 
	function transferOwnership(address newOwner) public onlyOwner {
		require(newOwner != address(0));
		emit OwnershipTransferred(owner, newOwner);
		owner = newOwner;
	}

}

 

 
library SafeMath {

	 
	function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
		if (a == 0) {
			return 0;
		}
		c = a * b;
		assert(c / a == b);
		return c;
	}

	 
	function div(uint256 a, uint256 b) internal pure returns (uint256) {
		 
		 
		 
		return a / b;
	}

	 
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

 

 
contract ERC20Basic {
	function totalSupply() public view returns (uint256);
	function balanceOf(address who) public view returns (uint256);
	function transfer(address to, uint256 value) public returns (bool);
	event Transfer(address indexed from, address indexed to, uint256 value);
}

 

 
contract BasicToken is ERC20Basic {
	using SafeMath for uint256;

	mapping(address => uint256) balances;

	uint256 totalSupply_;

	 
	function totalSupply() public view returns (uint256) {
		return totalSupply_;
	}

	 
	function transfer(address _to, uint256 _value) public returns (bool) {
		require(_to != address(0));
		require(_value <= balances[msg.sender]);

		balances[msg.sender] = balances[msg.sender].sub(_value);
		balances[_to] = balances[_to].add(_value);
		emit Transfer(msg.sender, _to, _value);
		return true;
	}

	 
	function balanceOf(address _owner) public view returns (uint256) {
		return balances[_owner];
	}

}

 

 
contract ERC20 is ERC20Basic {
	function allowance(address owner, address spender) public view returns (uint256);
	function transferFrom(address from, address to, uint256 value) public returns (bool);
	function approve(address spender, uint256 value) public returns (bool);
	event Approval(address indexed owner, address indexed spender, uint256 value);
}

 

 
contract StandardToken is ERC20, BasicToken {

	mapping (address => mapping (address => uint256)) internal allowed;


	 
	function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
		require(_to != address(0));
		require(_value <= balances[_from]);
		require(_value <= allowed[_from][msg.sender]);

		balances[_from] = balances[_from].sub(_value);
		balances[_to] = balances[_to].add(_value);
		allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
		emit Transfer(_from, _to, _value);
		return true;
	}

	 
	function approve(address _spender, uint256 _value) public returns (bool) {
		allowed[msg.sender][_spender] = _value;
		emit Approval(msg.sender, _spender, _value);
		return true;
	}

	 
	function allowance(address _owner, address _spender) public view returns (uint256) {
		return allowed[_owner][_spender];
	}

	 
	function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
		allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
		emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
		return true;
	}

	 
	function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
		uint oldValue = allowed[msg.sender][_spender];
		if (_subtractedValue > oldValue) {
			allowed[msg.sender][_spender] = 0;
		} else {
			allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
		}
		emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
		return true;
	}

}


 

 
contract Pausable is Ownable {
	event Pause();
	event Unpause();

	bool public paused = false;


	 
	modifier whenNotPaused() {
		require(!paused);
		_;
	}

	 
	modifier whenPaused() {
		require(paused);
		_;
	}

	 
	function pause() onlyOwner whenNotPaused public {
		paused = true;
		emit Pause();
	}

	 
	function unpause() onlyOwner whenPaused public {
		paused = false;
		emit Unpause();
	}
}

 

 
contract Crowdsale {
	using SafeMath for uint256;

	 
	ERC20 public token;

	 
	address public wallet;

	 
	uint256 public rate;

	 
	uint256 public weiRaised;

	 
	event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

	 
	function Crowdsale(uint256 _rate, address _wallet, ERC20 _token) public {
		require(_rate > 0);
		require(_wallet != address(0));
		require(_token != address(0));

		rate = _rate;
		wallet = _wallet;
		token = _token;
	}

	 
	 
	 

	 
	function () external payable {
		buyTokens(msg.sender);
	}

	 
	function buyTokens(address _beneficiary) public payable {

		uint256 weiAmount = msg.value;
		_preValidatePurchase(_beneficiary, weiAmount);

		 
		uint256 tokens = _getTokenAmount(weiAmount);

		 
		weiRaised = weiRaised.add(weiAmount);

		_processPurchase(_beneficiary, tokens);
		emit TokenPurchase(
			msg.sender,
			_beneficiary,
			weiAmount,
			tokens
		);

		_updatePurchasingState(_beneficiary, weiAmount);

		_forwardFunds();
		_postValidatePurchase(_beneficiary, weiAmount);
	}

	 
	 
	 

	 
	function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
		require(_beneficiary != address(0));
		require(_weiAmount != 0);
	}

	 
	function _postValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
		 
	}

	 
	function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
		token.transfer(_beneficiary, _tokenAmount);
	}

	 
	function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
		_deliverTokens(_beneficiary, _tokenAmount);
	}

	 
	function _updatePurchasingState(address _beneficiary, uint256 _weiAmount) internal {
		 
	}

	 
	function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
		return _weiAmount.mul(66666667).div(5000);
	}

	 
	function _forwardFunds() internal {
		wallet.transfer(msg.value);
	}
}

 

 
contract CappedCrowdsale is Crowdsale {
	using SafeMath for uint256;

	uint256 public cap;

	 
	function CappedCrowdsale(uint256 _cap) public {
		require(_cap > 0);
		cap = _cap;
	}

	 
	function capReached() public view returns (bool) {
		return weiRaised >= cap;
	}

	 
	function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
		super._preValidatePurchase(_beneficiary, _weiAmount);
		require(weiRaised.add(_weiAmount) <= cap);
	}

}

contract AmountLimitCrowdsale is Crowdsale, Ownable {
	using SafeMath for uint256;

	uint256 public min;
	uint256 public max;

	mapping(address => uint256) public contributions;

	function AmountLimitCrowdsale(uint256 _min, uint256 _max) public {
		require(_min > 0);
		require(_max > _min);
		 
		min = _min;
		max = _max;
	}

	function getUserContribution(address _beneficiary) public view returns (uint256) {
		return contributions[_beneficiary];
	}

	function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
		super._preValidatePurchase(_beneficiary, _weiAmount);
		require(contributions[_beneficiary].add(_weiAmount) <= max);
		require(contributions[_beneficiary].add(_weiAmount) >= min);
	}

	function _updatePurchasingState(address _beneficiary, uint256 _weiAmount) internal {
		super._updatePurchasingState(_beneficiary, _weiAmount);
		 
		contributions[_beneficiary] = contributions[_beneficiary].add(_weiAmount);
	}
}

 

 
contract TimedCrowdsale is Crowdsale {
	using SafeMath for uint256;

	uint256 public openingTime;
	uint256 public closingTime;

	 
	modifier onlyWhileOpen {
		 
		require(block.timestamp >= openingTime && block.timestamp <= closingTime);
		_;
	}

	 
	function TimedCrowdsale(uint256 _openingTime, uint256 _closingTime) public {
		 
		require(_openingTime >= block.timestamp);
		require(_closingTime >= _openingTime);

		openingTime = _openingTime;
		closingTime = _closingTime;
	}

	 
	function hasClosed() public view returns (bool) {
		 
		return block.timestamp > closingTime;
	}

	 
	function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal onlyWhileOpen {
		super._preValidatePurchase(_beneficiary, _weiAmount);
	}

}

 

 
contract WhitelistedCrowdsale is Crowdsale, Ownable {

	mapping(address => bool) public whitelist;

	 
	modifier isWhitelisted(address _beneficiary) {
		require(whitelist[_beneficiary]);
		_;
	}

	 
	function addToWhitelist(address _beneficiary) external onlyOwner {
		whitelist[_beneficiary] = true;
	}

	 
	function addManyToWhitelist(address[] _beneficiaries) external onlyOwner {
		for (uint256 i = 0; i < _beneficiaries.length; i++) {
			whitelist[_beneficiaries[i]] = true;
		}
	}

	 
	function removeFromWhitelist(address _beneficiary) external onlyOwner {
		whitelist[_beneficiary] = false;
	}

	 
	function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal isWhitelisted(_beneficiary) {
		super._preValidatePurchase(_beneficiary, _weiAmount);
	}

}

contract T2TCrowdsale is WhitelistedCrowdsale, AmountLimitCrowdsale, CappedCrowdsale,
TimedCrowdsale, Pausable {
	using SafeMath for uint256;

	uint256 public distributeTime;
	mapping(address => uint256) public balances;

	function T2TCrowdsale(uint256 rate, 
		uint256 openTime, 
		uint256 closeTime, 
		uint256 totalCap,
		uint256 userMin,
		uint256 userMax,
		uint256 _distributeTime,
		address account,
		StandardToken token)
		Crowdsale(rate, account, token)
		TimedCrowdsale(openTime, closeTime)
		CappedCrowdsale(totalCap)
		AmountLimitCrowdsale(userMin, userMax) public {
	  distributeTime = _distributeTime;
	}

	function withdrawTokens(address _beneficiary) public {
	  require(block.timestamp > distributeTime);
	  uint256 amount = balances[_beneficiary];
	  require(amount > 0);
	  balances[_beneficiary] = 0;
	  _deliverTokens(_beneficiary, amount);
	}

	function distributeTokens(address[] _beneficiaries) external onlyOwner {
		for (uint256 i = 0; i < _beneficiaries.length; i++) {
			require(block.timestamp > distributeTime);
			address _beneficiary = _beneficiaries[i];
			uint256 amount = balances[_beneficiary];
			if(amount > 0) {
				balances[_beneficiary] = 0;
				_deliverTokens(_beneficiary, amount);
			}
		}
	}

	function returnTokens(address _beneficiary, uint256 amount) external onlyOwner {
		_deliverTokens(_beneficiary, amount);
	}

	function _processPurchase(
	  address _beneficiary,
	  uint256 _tokenAmount
	)
	internal {
	  balances[_beneficiary] = balances[_beneficiary].add(_tokenAmount);
	}

	function buyTokens(address beneficiary) public payable whenNotPaused {
	  super.buyTokens(beneficiary);
	}
}
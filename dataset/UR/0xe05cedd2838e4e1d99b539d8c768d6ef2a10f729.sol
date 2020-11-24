 

pragma solidity ^0.4.8;


contract SafeMath {

  function assert(bool assertion) internal {
    if (!assertion) throw;
  }

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

}


contract StandardTokenProtocol {

    function totalSupply() constant returns (uint256 totalSupply) {}
    function balanceOf(address _owner) constant returns (uint256 balance) {}
    function transfer(address _recipient, uint256 _value) returns (bool success) {}
    function transferFrom(address _from, address _recipient, uint256 _value) returns (bool success) {}
    function approve(address _spender, uint256 _value) returns (bool success) {}
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {}

    event Transfer(address indexed _from, address indexed _recipient, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}


contract StandardToken is StandardTokenProtocol {

    modifier when_can_transfer(address _from, uint256 _value) {
        if (balances[_from] >= _value) _;
    }

    modifier when_can_receive(address _recipient, uint256 _value) {
        if (balances[_recipient] + _value > balances[_recipient]) _;
    }

    modifier when_is_allowed(address _from, address _delegate, uint256 _value) {
        if (allowed[_from][_delegate] >= _value) _;
    }

    function transfer(address _recipient, uint256 _value)
        when_can_transfer(msg.sender, _value)
        when_can_receive(_recipient, _value)
        returns (bool o_success)
    {
        balances[msg.sender] -= _value;
        balances[_recipient] += _value;
        Transfer(msg.sender, _recipient, _value);
        return true;
    }

    function transferFrom(address _from, address _recipient, uint256 _value)
        when_can_transfer(_from, _value)
        when_can_receive(_recipient, _value)
        when_is_allowed(_from, msg.sender, _value)
        returns (bool o_success)
    {
        allowed[_from][msg.sender] -= _value;
        balances[_from] -= _value;
        balances[_recipient] += _value;
        Transfer(_from, _recipient, _value);
        return true;
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool o_success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 o_remaining) {
        return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 public totalSupply;

}

contract GUPToken is StandardToken {

	 
	string public name = "Guppy";
    string public symbol = "GUP";
    uint public decimals = 3;

	 
	uint public constant LOCKOUT_PERIOD = 1 years;  

	 
	uint public endMintingTime;  
	address public minter;  

	mapping (address => uint) public illiquidBalance;  

	 
	 
	modifier only_minter {
		if (msg.sender != minter) throw;
		_;
	}

	 
	 
	modifier when_thawable {
		if (now < endMintingTime + LOCKOUT_PERIOD) throw;
		_;
	}

	 
	 
	modifier when_transferable {
		if (now < endMintingTime) throw;
		_;
	}

	 
	 
	modifier when_mintable {
		if (now >= endMintingTime) throw;
		_;
	}

	 
	function GUPToken(address _minter, uint _endMintingTime) {
		endMintingTime = _endMintingTime;
		minter = _minter;
	}

	 
	 
	function createToken(address _recipient, uint _value)
		when_mintable
		only_minter
		returns (bool o_success)
	{
		balances[_recipient] += _value;
		totalSupply += _value;
		return true;
	}

	 
	 
	function createIlliquidToken(address _recipient, uint _value)
		when_mintable
		only_minter
		returns (bool o_success)
	{
		illiquidBalance[_recipient] += _value;
		totalSupply += _value;
		return true;
	}

	 
	function makeLiquid()
		when_thawable
	{
		balances[msg.sender] += illiquidBalance[msg.sender];
		illiquidBalance[msg.sender] = 0;
	}

	 
	 
	function transfer(address _recipient, uint _amount)
		when_transferable
		returns (bool o_success)
	{
		return super.transfer(_recipient, _amount);
	}

	 
	 
	function transferFrom(address _from, address _recipient, uint _amount)
		when_transferable
		returns (bool o_success)
	{
		return super.transferFrom(_from, _recipient, _amount);
	}
}


contract Contribution is SafeMath {

	 

	 
	 
	uint public constant STAGE_ONE_TIME_END = 5 hours;
	uint public constant STAGE_TWO_TIME_END = 72 hours;
	uint public constant STAGE_THREE_TIME_END = 2 weeks;
	uint public constant STAGE_FOUR_TIME_END = 4 weeks;
	 
	uint public constant PRICE_STAGE_ONE   = 480000;
	uint public constant PRICE_STAGE_TWO   = 440000;
	uint public constant PRICE_STAGE_THREE = 400000;
	uint public constant PRICE_STAGE_FOUR  = 360000;
	uint public constant PRICE_BTCS        = 480000;
	 
	uint public constant MAX_SUPPLY =        100000000000;
	uint public constant ALLOC_ILLIQUID_TEAM = 8000000000;
	uint public constant ALLOC_LIQUID_TEAM =  13000000000;
	uint public constant ALLOC_BOUNTIES =      2000000000;
	uint public constant ALLOC_NEW_USERS =    17000000000;
	uint public constant ALLOC_CROWDSALE =    60000000000;
	uint public constant BTCS_PORTION_MAX = 31250 * PRICE_BTCS;
	 
	 
	uint public publicStartTime;  
	uint public privateStartTime;  
	uint public publicEndTime;  
	 
	address public btcsAddress;  
	address public multisigAddress;  
	address public matchpoolAddress;  
	address public ownerAddress;  
	 
	GUPToken public gupToken;  
	 
	uint public etherRaised;  
	uint public gupSold;  
	uint public btcsPortionTotal;  
	 
	bool public halted;  

	 

	 
	modifier is_pre_crowdfund_period() {
		if (now >= publicStartTime || now < privateStartTime) throw;
		_;
	}

	 
	modifier is_crowdfund_period() {
		if (now < publicStartTime || now >= publicEndTime) throw;
		_;
	}

	 
	modifier only_btcs() {
		if (msg.sender != btcsAddress) throw;
		_;
	}

	 
	modifier only_owner() {
		if (msg.sender != ownerAddress) throw;
		_;
	}

	 
	modifier is_not_halted() {
		if (halted) throw;
		_;
	}

	 

	event PreBuy(uint _amount);
	event Buy(address indexed _recipient, uint _amount);


	 

	 
	function Contribution(
		address _btcs,
		address _multisig,
		address _matchpool,
		uint _publicStartTime,
		uint _privateStartTime
	) {
		ownerAddress = msg.sender;
		publicStartTime = _publicStartTime;
		privateStartTime = _privateStartTime;
		publicEndTime = _publicStartTime + 4 weeks;
		btcsAddress = _btcs;
		multisigAddress = _multisig;
		matchpoolAddress = _matchpool;
		gupToken = new GUPToken(this, publicEndTime);
		gupToken.createIlliquidToken(matchpoolAddress, ALLOC_ILLIQUID_TEAM);
		gupToken.createToken(matchpoolAddress, ALLOC_BOUNTIES);
		gupToken.createToken(matchpoolAddress, ALLOC_LIQUID_TEAM);
		gupToken.createToken(matchpoolAddress, ALLOC_NEW_USERS);
	}

	 
	function toggleHalt(bool _halted)
		only_owner
	{
		halted = _halted;
	}

	 
	function getPriceRate()
		constant
		returns (uint o_rate)
	{
		if (now <= publicStartTime + STAGE_ONE_TIME_END) return PRICE_STAGE_ONE;
		if (now <= publicStartTime + STAGE_TWO_TIME_END) return PRICE_STAGE_TWO;
		if (now <= publicStartTime + STAGE_THREE_TIME_END) return PRICE_STAGE_THREE;
		if (now <= publicStartTime + STAGE_FOUR_TIME_END) return PRICE_STAGE_FOUR;
		else return 0;
	}

	 
	 
	 
	 
	 
	 
	 
	function processPurchase(uint _rate, uint _remaining)
		internal
		returns (uint o_amount)
	{
		o_amount = safeDiv(safeMul(msg.value, _rate), 1 ether);
		if (o_amount > _remaining) throw;
		if (!multisigAddress.send(msg.value)) throw;
		if (!gupToken.createToken(msg.sender, o_amount)) throw;
		gupSold += o_amount;
		etherRaised += msg.value;
	}

	 
	 
	function preBuy()
		payable
		is_pre_crowdfund_period
		only_btcs
		is_not_halted
	{
		uint amount = processPurchase(PRICE_BTCS, BTCS_PORTION_MAX - btcsPortionTotal);
		btcsPortionTotal += amount;
		PreBuy(amount);
	}

	 
	 
	function()
		payable
		is_crowdfund_period
		is_not_halted
	{
		uint amount = processPurchase(getPriceRate(), ALLOC_CROWDSALE - gupSold);
		Buy(msg.sender, amount);
	}

	 
	function drain()
		only_owner
	{
		if (!ownerAddress.send(this.balance)) throw;
	}
}
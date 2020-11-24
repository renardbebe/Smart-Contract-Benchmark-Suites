 

pragma solidity ^0.4.24;

contract Owned {
	address public owner;
	address public signer;

	constructor() public {
		owner = msg.sender;
		signer = msg.sender;
	}

    modifier onlyOwner {
    	require(msg.sender == owner);
        _;
    }

    modifier onlySigner {
	require(msg.sender == signer);
	_;
    }

    function transferOwnership(address newOwner) public onlyOwner {
	owner = newOwner;
    }

    function transferSignership(address newSigner) public onlyOwner {
        signer = newSigner;
    }
}


contract ERC20Token {

     
    string public name;
    string public symbol;
    uint8 public decimals = 18;

    uint256 public totalSupply;

     
    mapping (address => uint256) public balances;

     
    mapping (address => mapping (address => uint256)) public allowed;

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Approval(address indexed sender, address indexed spender, uint256 value);

    constructor(uint256 _supply, string _name, string _symbol)
	public
    {
	 
        totalSupply = _supply * 10**uint256(decimals);
        balances[msg.sender] = totalSupply;

	 
	name=_name;
	symbol=_symbol;

	 
        emit Transfer(0x0, msg.sender, totalSupply);
    }

	 
    function totalSupply()
    	public
    	constant
    	returns (uint256)
    {
		return totalSupply;
    }

	 
    function balanceOf(address _owner)
    	public
    	constant
    	returns (uint256 balance)
    {
        return balances[_owner];
    }

	 
    function approve(address _spender, uint256 _value)
    	public
    	returns (bool success)
    {
		 
         
         
         
		require((_value == 0) || (allowed[msg.sender][_spender] == 0));

      	 
      	allowed[msg.sender][_spender] = _value;

		 
      	emit Approval(msg.sender, _spender, _value);

		return true;
    }

     
    function allowance(address _owner, address _spender)
    	public
    	constant
    	returns (uint256 remaining)
    {
        return allowed[_owner][_spender];
    }

	 
    function _transfer(address _from, address _to, uint256 _value)
    	internal
    	returns (bool success)
    {
		 
		require((_to != address(0)) && (_to != address(this)) && (_to != _from));

         
        require((_value > 0) && (balances[_from] >= _value));

         
        require(balances[_to] + _value > balances[_to]);

         
        balances[_from] -= _value;

         
        balances[_to] += _value;

        emit Transfer(_from, _to, _value);

        return true;
    }

	 
    function transfer(address _to, uint256 _value)
    	public
    	returns (bool success)
    {
    	return _transfer(msg.sender, _to, _value);
    }

  	 
    function transferFrom(address _from, address _to, uint256 _value)
    	public
    	returns (bool success)
    {
		 
    	require(_value <= allowed[_from][msg.sender]);

		 
		allowed[_from][msg.sender] -= _value;

    	 
        return _transfer(_from, _to, _value);
    }
}


 
library SafeMath {

    function mul(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
         
        uint256 c = a / b;
         
        return c;
    }

    function sub(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract CrowdSaleTeleToken is Owned {

	using SafeMath for uint256;

	uint256 public price;

	ERC20Token public crowdSaleToken;

	 
	constructor(uint256 _price, address _tokenAddress)
		public
	{
		 
		price = _price;

		 
		crowdSaleToken = ERC20Token(_tokenAddress);
	}

	 
	function ()
		payable
		public
	{
		 
		uint256 amount = msg.value / price;

		 
		require(amount != 0);

		 
		crowdSaleToken.transfer(msg.sender, amount.mul(10**18));
	}

	 
	function withdrawalEth(uint256 _amount)
		public
		onlyOwner
	{
		 
		msg.sender.transfer(_amount);
	}

	 
	function withdrawalToken(uint256 _amount)
		public
		onlyOwner
	{
		 
		crowdSaleToken.transfer(msg.sender, _amount);
	}

	 
	function setPrice(uint256 _price)
		public
		onlyOwner
	{
		 
		assert(_price != 0);

		 
		price = _price;
	}
}
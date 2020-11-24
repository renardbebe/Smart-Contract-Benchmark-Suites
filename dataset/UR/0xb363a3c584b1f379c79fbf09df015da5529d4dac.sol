 

pragma solidity ^0.4.16;

contract Owned {
	address public owner;
	address public signer;

    function Owned() public {
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


contract ERC20Token {

     
    string public name;
    string public symbol;
    uint8 public decimals = 18;

    uint256 public totalSupply;

     
    mapping (address => uint256) public balances;

	 
    mapping (address => mapping (address => uint256)) public allowed;

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Approval(address indexed sender, address indexed spender, uint256 value);

	function ERC20Token(uint256 _supply, string _name, string _symbol)
		public
	{
		 
        totalSupply = _supply * 10**uint256(decimals);
        balances[msg.sender] = totalSupply;

		 
		name=_name;
		symbol=_symbol;

    	 
        Transfer(0x0, msg.sender, totalSupply);
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

		 
      	Approval(msg.sender, _spender, _value);

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

        Transfer(_from, _to, _value);

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



contract MiracleTeleToken is ERC20Token, Owned {

    using SafeMath for uint256;

     
    mapping (address => uint8) public delegations;

	mapping (address => uint256) public contributions;

     
    event Delegate(address indexed from, address indexed to);
    event UnDelegate(address indexed from, address indexed to);

     
    event Contribute(address indexed from, uint256 indexed value);
    event Reward(address indexed from, uint256 indexed value);

     
    function MiracleTeleToken(uint256 _supply) ERC20Token(_supply, "MiracleTele", "TELE") public {}

	 
    function mint(uint256 _value)
        public
        onlyOwner
    {
    	 
        require(_value > 0);

    	 
    	balances[owner] = balances[owner].add(_value);
        totalSupply = totalSupply.add(_value);

        Transfer(address(0), owner, _value);
    }

    function delegate(uint8 _v, bytes32 _r, bytes32 _s)
        public
        onlySigner
    {
		address allowes = ecrecover(getPrefixedHash(signer), _v, _r, _s);

        delegations[allowes]=1;

        Delegate(allowes, signer);
    }

	function unDelegate(uint8 _v, bytes32 _r, bytes32 _s)
        public
        onlySigner
    {
    	address allowes = ecrecover(getPrefixedHash(signer), _v, _r, _s);

        delegations[allowes]=0;

        UnDelegate(allowes, signer);
    }

	 
    function delegation(address _owner)
    	public
    	constant
    	returns (uint8 status)
    {
        return delegations[_owner];
    }

     
    function getPrefixedHash(address _message)
        pure
        public
        returns(bytes32 signHash)
    {
        signHash = keccak256("\x19Ethereum Signed Message:\n20", _message);
    }

     
    function transferDelegated(address _from, address _to, uint256 _value)
        public
        onlySigner
        returns (bool success)
    {
         
    	require(delegations[_from]==1);

    	 
        return _transfer(_from, _to, _value);
    }

	 
    function contributeDelegated(address _from, uint256 _value)
        public
        onlySigner
    {
         
    	require(delegations[_from]==1);

         
        require((_value > 0) && (balances[_from] >= _value));

         
        balances[_from] = balances[_from].sub(_value);

        contributions[_from] = contributions[_from].add(_value);

        Contribute(_from, _value);
    }

	 
    function reward(address _from, uint256 _value)
        public
        onlySigner
    {
        require(contributions[_from]>=_value);

        contributions[_from] = contributions[_from].sub(_value);

        balances[_from] = balances[_from].add(_value);

        Reward(_from, _value);
    }

     
	function ()
	    public
	    payable
	{
		revert();
	}
}
 

pragma solidity 0.4.25;

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a && c>=b);
    return c;
  }
}


  


 
contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }


contract DELFINIUMToken is ERC20Interface {
	using SafeMath for uint;

	 
	string public symbol = 'DELFINIUM';
	string public name = 'DLF';
	uint public decimals = 18;
	address public owner;
	uint public totalSupply = 210000000 * (10 ** 18);
	bool public emergencyFreeze;
	
	 
	mapping (address => uint) balances;
	mapping (address => mapping (address => uint) ) allowed;
	mapping (address => bool) frozen;
  

	 
	constructor() public {
		owner = msg.sender;
		balances[owner] = totalSupply;
		emit Transfer(address(0x0), msg.sender, totalSupply);
	}

	 
	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
	event Freezed(address targetAddress, bool frozen);
	event EmerygencyFreezed(bool emergencyFreezeStatus);	
  


	 
	modifier onlyOwner {
		require(msg.sender == owner, '1');
		_;
	}

	modifier unfreezed(address _account) { 
		require(!frozen[_account], '2');
		_;  
	}
	
	modifier noEmergencyFreeze() { 
		require(!emergencyFreeze, '3');
		_; 
	}
  


	 

	 
	 
	 
	function transfer(address _to, uint _value)
		unfreezed(_to) 
		unfreezed(msg.sender) 
		noEmergencyFreeze() 
		public returns (bool success) 
	{
		require(_to != address(0x0), '4');
		require(balances[msg.sender] >= _value, '5');
		balances[msg.sender] = balances[msg.sender].sub(_value);
		balances[_to] = balances[_to].add(_value);
		emit Transfer(msg.sender, _to, _value);
		return true;
	}

	 
	 
	 
	 
	function approve(address _spender, uint _value)
		unfreezed(_spender) 
		unfreezed(msg.sender) 
		noEmergencyFreeze() 
		public returns (bool success) 
	{
		allowed[msg.sender][_spender] = _value;
		emit Approval(msg.sender, _spender, _value);
		return true;
	}

	function increaseApproval(address _spender, uint256 _addedValue)
		unfreezed(_spender)
		unfreezed(msg.sender)
		noEmergencyFreeze()
		public returns (bool)
	{
		allowed[msg.sender][_spender] = (
		allowed[msg.sender][_spender].add(_addedValue));
		emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
		return true;
	}

	function decreaseApproval (address _spender, uint256 _subtractedValue )
		unfreezed(_spender)
		unfreezed(msg.sender)
		noEmergencyFreeze()
		public returns (bool)
	{
		uint256 oldValue = allowed[msg.sender][_spender];
		if (_subtractedValue > oldValue) {
			allowed[msg.sender][_spender] = 0;
		} else {
			allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
		}
		emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
		return true;
	}

  	 
  	 
		 
  	function approveAndCall(address _spender, uint256 _value, bytes _extraData)
		unfreezed(_spender) 
		unfreezed(msg.sender) 
		noEmergencyFreeze() 
		public returns (bool success) 
	{
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

	 
	 
	 
	function transferFrom(address _from, address _to, uint _value)
		unfreezed(_to) 
		unfreezed(_from) 
		unfreezed(msg.sender) 
		noEmergencyFreeze() 
		public returns (bool success) 
	{
		require(_value <= allowed[_from][msg.sender], '6');
		require (balances[_from]>= _value, '5');
		balances[_from] = balances[_from].sub(_value);
		allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
		balances[_to] = balances[_to].add(_value);
		emit Transfer(_from, _to, _value);
		return true;
	}


	 
	 
	 


	 
	 
	 
	function transferOwnership(address _newOwner)
		onlyOwner
		public 
	{
		require(_newOwner != address(0), '4');
		owner = _newOwner;
		emit OwnershipTransferred(owner, _newOwner);
	}


	 
	 
	 
	function freezeAccount (address _target, bool _freeze) public onlyOwner returns(bool res) {
		require(_target != address(0x0), '4');
		frozen[_target] = _freeze;
		emit Freezed(_target, _freeze);
		return true;
	}

	 
	 
	 
	function emergencyFreezeAllAccounts (bool _freeze) public onlyOwner returns(bool res) {
		emergencyFreeze = _freeze;
		emit EmerygencyFreezed(_freeze);
		return true;
	}
  

	 
	 
	 


	 
	 
	 
	function allowance(address _tokenOwner, address _spender) public view returns (uint remaining) {
		return allowed[_tokenOwner][_spender];
	}

	 
	 
	 
	function balanceOf(address _tokenOwner) public view returns (uint balance) {
		return balances[_tokenOwner];
	}

	 
	 
	 
	function totalSupply() public view returns (uint) {
		return totalSupply;
	}

	 
	 
	 
	function isFreezed(address _targetAddress) public view returns (bool) {
		return frozen[_targetAddress]; 
	}



	 
	 
	 
	function () public payable {
		revert();
	}

	 
	 
	 
	function transferAnyERC20Token(address _tokenAddress, uint _value) public onlyOwner returns (bool success) {
		return ERC20Interface(_tokenAddress).transfer(owner, _value);
	}
}
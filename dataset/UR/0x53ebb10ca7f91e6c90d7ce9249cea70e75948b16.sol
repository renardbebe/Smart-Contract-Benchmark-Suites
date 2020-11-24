 

pragma solidity ^0.4.18;

 

 
contract ERC223 {
  uint public totalSupply;
  function balanceOf(address who) public view returns (uint);
  
  function name() public view returns (string _name);
  function symbol() public view returns (string _symbol);
  function decimals() public view returns (uint8 _decimals);
  function totalSupply() public view returns (uint256 _supply);

  function transfer(address to, uint value) public returns (bool ok);
  function transfer(address to, uint value, bytes data) public returns (bool ok);
  function transfer(address to, uint value, bytes data, string custom_fallback) public returns (bool ok);
  
  event Transfer(address indexed from, address indexed to, uint value);
  event ERC223Transfer(address indexed from, address indexed to, uint value, bytes indexed data);
}


contract ContractReceiver {
	function tokenFallback(address _from, uint _value, bytes _data) public pure;
}

 
contract SafeMath
{
    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
      }
    
	function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
		assert(b <= a);
		return a - b;
	}
	
	function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a / b;
		return c;
	}
	
	function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
		if (a == 0) {
			return 0;
		}
		uint256 c = a * b;
		assert(c / a == b);
		return c;
	}
}

contract AUMXToken is ERC223, SafeMath{
	mapping(address => mapping(address => uint)) allowed;
	mapping(address => uint) balances;
	string public name = "Alteum";
	string public symbol = "AUM";
	uint8 public decimals = 8;  
	uint256 public totalSupply = 5000000000000000;  
	
	bool locked;
	address Owner;
	address swapperAddress;
	
	function AUMXToken() public {
		locked = true;
		Owner = msg.sender;
		swapperAddress = msg.sender;
		balances[msg.sender] = totalSupply;
		allowed[msg.sender][swapperAddress] = totalSupply;
	}
	
	modifier isUnlocked()
	{
		if(locked && msg.sender != Owner) revert();
		_;
	}
	
	modifier onlyOwner()
	{
		if(msg.sender != Owner) revert();
		_;
	}
	  
	 
	function name() public view returns (string _name) {
		return name;
	}
	 
	function symbol() public view returns (string _symbol) {
		return symbol;
	}
	 
	function decimals() public view returns (uint8 _decimals) {
		return decimals;
	}
	 
	function totalSupply() public view returns (uint256 _totalSupply) {
		return totalSupply;
	}
	  
	function ChangeSwapperAddress(address newSwapperAddress) public onlyOwner
	{
		address oldSwapperAddress = swapperAddress;
		swapperAddress = newSwapperAddress;
		uint setAllowance = allowed[msg.sender][oldSwapperAddress];
		allowed[msg.sender][oldSwapperAddress] = 0;
		allowed[msg.sender][newSwapperAddress] = setAllowance;
	}
	
	function UnlockToken() public onlyOwner
	{
		locked = false;
	}
	  
	  
	  
	 
	function transfer(address _to, uint _value, bytes _data, string _custom_fallback) public isUnlocked returns (bool success) {
		if(isContract(_to)) {
			if (balanceOf(msg.sender) < _value) revert();
			balances[msg.sender] = safeSub(balanceOf(msg.sender), _value);
			balances[_to] = safeAdd(balanceOf(_to), _value);
			assert(_to.call.value(0)(bytes4(keccak256(_custom_fallback)), msg.sender, _value, _data));
			Transfer(msg.sender, _to, _value);
			ERC223Transfer(msg.sender, _to, _value, _data);
			return true;
		}
		else {
			return transferToAddress(_to, _value, _data);
		}
	}
	  

	 
	function transfer(address _to, uint _value, bytes _data) public isUnlocked returns (bool success) {
		if(isContract(_to)) {
			return transferToContract(_to, _value, _data);
		}
		else {
			return transferToAddress(_to, _value, _data);
		}
	}
	  
	 
	 
	function transfer(address _to, uint _value) public isUnlocked returns (bool success) {
		 
		 
		bytes memory empty;
		if(isContract(_to)) {
			return transferToContract(_to, _value, empty);
		}
		else {
			return transferToAddress(_to, _value, empty);
		}
	}

	 
	function isContract(address _addr) private view returns (bool is_contract) {
		uint length;
		assembly {
			 
			length := extcodesize(_addr)
		}
		return (length>0);
	}

	 
	function transferToAddress(address _to, uint _value, bytes _data) private returns (bool success) {
		if (balanceOf(msg.sender) < _value) revert();
		balances[msg.sender] = safeSub(balanceOf(msg.sender), _value);
		balances[_to] = safeAdd(balanceOf(_to), _value);
		Transfer(msg.sender, _to, _value);
		ERC223Transfer(msg.sender, _to, _value, _data);
		return true;
	}
	  
	 
	function transferToContract(address _to, uint _value, bytes _data) private returns (bool success) {
		if (balanceOf(msg.sender) < _value) revert();
		balances[msg.sender] = safeSub(balanceOf(msg.sender), _value);
		balances[_to] = safeAdd(balanceOf(_to), _value);
		ContractReceiver receiver = ContractReceiver(_to);
		receiver.tokenFallback(msg.sender, _value, _data);
		Transfer(msg.sender, _to, _value);
		ERC223Transfer(msg.sender, _to, _value, _data);
		return true;
	}
	
	function transferFrom(address _from, address _to, uint _value) public returns(bool)
	{
		if(locked && msg.sender != swapperAddress) revert();
		if (balanceOf(_from) < _value) revert();
		if(_value > allowed[_from][msg.sender]) revert();
		
		balances[_from] = safeSub(balanceOf(_from), _value);
		allowed[_from][msg.sender] = safeSub(allowed[_from][msg.sender], _value);
		balances[_to] = safeAdd(balanceOf(_to), _value);
		bytes memory empty;
		Transfer(_from, _to, _value);
		ERC223Transfer(_from, _to, _value, empty);
		return true;
	}

	function balanceOf(address _owner) public view returns (uint balance) {
		return balances[_owner];
	}
}
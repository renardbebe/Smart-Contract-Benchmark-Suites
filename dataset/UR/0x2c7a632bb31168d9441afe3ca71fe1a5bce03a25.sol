 

  
pragma solidity ^ 0.5.0;

 
interface ContractReceiver {
	function tokenFallback(address from, uint value, bytes calldata data)external;
}

interface TokenRecipient {
	function receiveApproval(address from, uint256 value, bytes calldata data)external;
}

interface ERC223TokenBasic {
	function transfer(address receiver, uint256 amount, bytes calldata data) external;
	function balanceOf(address owner) external view returns(uint);
	function transferFrom(address from, address to, uint256 value) external returns(bool success);
}

contract KDGToken is ERC223TokenBasic{
    address constant private ADDRESS_ZERO = 0x0000000000000000000000000000000000000000;

	string public name;
	string public symbol;
	uint8 public decimals;
	uint256 public totalSupply;
	address public issuer;

	mapping(address => uint256)balances_;
	mapping(address => mapping(address => uint256))allowances_;

	 
	event Approval(address indexed owner,
		address indexed spender,
		uint value);

	event Transfer(address indexed from,
		address indexed to,
		uint256 value);

	 
	event Burn(address indexed from, uint256 value);

	constructor(uint256 initialSupply,
		string memory tokenName,
		uint8 decimalUnits,
		string memory tokenSymbol)public{
		totalSupply = initialSupply * 10 ** uint256(decimalUnits);
		balances_[msg.sender] = totalSupply;
		name = tokenName;
		decimals = decimalUnits;
		symbol = tokenSymbol;
		issuer = msg.sender;
		emit Transfer(address(0), msg.sender, totalSupply);
	}

	function () external payable {
		revert();
	}  

	 
	function balanceOf(address owner)public view returns(uint) {
		return balances_[owner];
	}

	 
	 
	 
	 
	 
	 
	function approve(address spender, uint256 value)public
	returns(bool success) {
		allowances_[msg.sender][spender] = value;
		emit Approval(msg.sender, spender, value);
		return true;
	}

	 
	function safeApprove(address _spender,
		uint256 _currentValue,
		uint256 _value)public
	returns(bool success) {
		 
		 
		if (allowances_[msg.sender][_spender] == _currentValue)
			return approve(_spender, _value);

		return false;
	}

	 
	function allowance(address owner, address spender)public view
	returns(uint256 remaining) {
		return allowances_[owner][spender];
	}

	function transfer(address to, uint256 value)public returns(bool success) {
		bytes memory empty;  
		_transfer(msg.sender, to, value, empty);
		return true;
	}

	 
	function transferFrom(address from, address to, uint256 value)public returns(bool success) {
		require(value <= allowances_[from][msg.sender]);

		allowances_[from][msg.sender] -= value;
		bytes memory empty;
		_transfer(from, to, value, empty);

		return true;
	}

	 
	function approveAndCall(address spender,
		uint256 value,
		bytes memory context)public
	returns(bool success) {
		if (approve(spender, value)) {
			TokenRecipient recip = TokenRecipient(spender);
			recip.receiveApproval(msg.sender, value, context);
			return true;
		}
		return false;
	}

	 
	function burn(uint256 value)public
	returns(bool success) {
		require(balances_[msg.sender] >= value);
		balances_[msg.sender] -= value;
		totalSupply -= value;

		emit Burn(msg.sender, value);
		return true;
	}

	 
	function burnFrom(address from, uint256 value)public
	returns(bool success) {
		require(balances_[from] >= value);
		require(value <= allowances_[from][msg.sender]);

		balances_[from] -= value;
		allowances_[from][msg.sender] -= value;
		totalSupply -= value;

		emit Burn(from, value);
		return true;
	}

	 
	function transfer(address to, uint value, bytes calldata data)external{
		if (isContract(to)) {
			transferToContract(to, value, data);
		} else {
			_transfer(msg.sender, to, value, data);
		}
	}

	 
     
	function transfer(address to,
                        uint value,
                        bytes memory data,
                        string memory custom_fallback)public returns(bool success) {
        _transfer(msg.sender, to, value, data);

		if (isContract(to)) {
			ContractReceiver rx = ContractReceiver(to);
			(bool ret, bytes memory dret) = address(rx).call(abi.encodeWithSignature(custom_fallback, msg.sender, value, data));

            require(ret == true, "Cant invoke callback");
		}

		return true;
	}

	 
	function transferToContract(address to, uint value, bytes memory data)private
	returns(bool success) {
		_transfer(msg.sender, to, value, data);

		ContractReceiver cr = ContractReceiver(to);
		cr.tokenFallback(msg.sender, value, data);

		return true;
	}

	 
	function isContract(address _addr)private view returns(bool) {
		uint length;
		assembly {
			length := extcodesize(_addr)
		}
		return (length > 0);
	}

	function _transfer(address from,
		address to,
		uint value,
		bytes memory data)internal{
		require(to != ADDRESS_ZERO);
		require(balances_[from] >= value);
		require(balances_[to] + value > balances_[to]);  

		balances_[from] -= value;
		balances_[to] += value;

		 
		bytes memory empty;
		empty = data;
		emit Transfer(from, to, value);  
	}
}
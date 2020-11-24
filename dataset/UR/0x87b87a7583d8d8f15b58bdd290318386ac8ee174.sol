 

pragma solidity ^0.4.24;


contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
   constructor() public {
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
    assert(c >= a);
    return c;
	}
}

interface tokenRecipient {
    function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external;
	}

contract DigiWill is Ownable {
    using SafeMath for uint256;

    string public name = "Digiwill";
    uint8 public decimals = 18;
    string public symbol = "DGW";
    uint public totalSupply;
	bool public enabledTokenTransfer = false;

    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;
	
	mapping (address => bool) public allowedToTransfer;
	mapping (address => bool) public blockedAddress;

 
 
 

     
       constructor() public {
        totalSupply = 2000000000 * 10**18;
        balances[msg.sender] = totalSupply;
        allowedToTransfer[msg.sender] = true;
		}


 
 
 

     
     
     
     
    function transfer(address _to, uint256 _amount) public returns (bool success) {
        doTransfer(msg.sender, _to, _amount);
        return true;
		}

     
     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _amount) public returns (bool success) {
         
        require(allowed[_from][msg.sender] >= _amount);
        allowed[_from][msg.sender] -= _amount;
        doTransfer(_from, _to, _amount);
        return true;
		}

     
     
     
     
     
     
    function doTransfer(address _from, address _to, uint _amount) internal {
         
		
        require((_to != 0) && (_to != address(this)));
        require(_amount <= balances[_from]);
		require(enabledTokenTransfer == true || allowedToTransfer[_from] == true);
		
		require(!blockedAddress[_from] || blockedAddress[_from] == false);
		require(!blockedAddress[_to] || blockedAddress[_to] == false);

		balances[_from] = balances[_from].sub(_amount);
		balances[_to] = balances[_to].add(_amount);
		emit Transfer(_from, _to, _amount);
		}

     
    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
		}
		
	  
    function lockStatusOf(address targetAddress) public constant returns (bool state) {
        return blockedAddress[targetAddress];
		}
		
	 
    function transferAllowanceOf(address targetAddress) public constant returns (bool state) {
        return allowedToTransfer[targetAddress];
		}

     
     
     
     
     
     
    function approve(address _spender, uint256 _amount) public returns (bool success) {
         
         
         
         
        require((_amount == 0) || (allowed[msg.sender][_spender] == 0));

        allowed[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
		}

    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
			}
		}

    function burn(uint256 _value) public onlyOwner {
        require(balances[msg.sender] >= _value);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        totalSupply = totalSupply.sub(_value);
		}

     
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
		}

     
     
    function totalSupply() public constant returns (uint) {
        return totalSupply;
		}
	
	 
	function setTokenTransferLock(bool lockStatus) public onlyOwner {
		enabledTokenTransfer = lockStatus;
		}
		
	 
	function setAddressTransferAllowance(address targetAddress, bool lockStatus) public onlyOwner {
		allowedToTransfer[targetAddress] = lockStatus;
		}
	
	 
	function setAddressBlockState(address targetAddress, bool lockStatus) public onlyOwner {
		require(targetAddress != owner);
		blockedAddress[targetAddress] = lockStatus;
		}

    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 _amount
        );

    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _amount
        );

    event Burn(
        address indexed _burner,
        uint256 _amount
        );
}
 

pragma solidity ^0.5.2;

 

 
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

     
    function owner() public view returns (address) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

     
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

     
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

     
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

 

 
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

 

contract Withdrawable is Ownable {
  function withdrawEther() external onlyOwner {
    msg.sender.transfer(address(this).balance);
  }

  function withdrawToken(IERC20 _token) external onlyOwner {
    require(_token.transfer(msg.sender, _token.balanceOf(address(this))));
  }
}

 

 
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

     
    function add(Role storage role, address account) internal {
        require(account != address(0));
        require(!has(role, account));

        role.bearer[account] = true;
    }

     
    function remove(Role storage role, address account) internal {
        require(account != address(0));
        require(has(role, account));

        role.bearer[account] = false;
    }

     
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0));
        return role.bearer[account];
    }
}

 

contract PauserRole {
    using Roles for Roles.Role;

    event PauserAdded(address indexed account);
    event PauserRemoved(address indexed account);

    Roles.Role private _pausers;

    constructor () internal {
        _addPauser(msg.sender);
    }

    modifier onlyPauser() {
        require(isPauser(msg.sender));
        _;
    }

    function isPauser(address account) public view returns (bool) {
        return _pausers.has(account);
    }

    function addPauser(address account) public onlyPauser {
        _addPauser(account);
    }

    function renouncePauser() public {
        _removePauser(msg.sender);
    }

    function _addPauser(address account) internal {
        _pausers.add(account);
        emit PauserAdded(account);
    }

    function _removePauser(address account) internal {
        _pausers.remove(account);
        emit PauserRemoved(account);
    }
}

 

 
contract Pausable is PauserRole {
    event Paused(address account);
    event Unpaused(address account);

    bool private _paused;

    constructor () internal {
        _paused = false;
    }

     
    function paused() public view returns (bool) {
        return _paused;
    }

     
    modifier whenNotPaused() {
        require(!_paused);
        _;
    }

     
    modifier whenPaused() {
        require(_paused);
        _;
    }

     
    function pause() public onlyPauser whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

     
    function unpause() public onlyPauser whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }
}

 

 
library SafeMath {
     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        require(b > 0);
        uint256 c = a / b;
         

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

 

 
contract ReentrancyGuard {
     
    uint256 private _guardCounter;

    constructor () internal {
         
         
        _guardCounter = 1;
    }

     
    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter);
    }
}

 

contract DJTBase is Withdrawable, Pausable, ReentrancyGuard {
    using SafeMath for uint256;
}

 

contract OperatorRole {
    using Roles for Roles.Role;

    event OperatorAdded(address indexed account);
    event OperatorRemoved(address indexed account);

    Roles.Role private operators;

    constructor() public {
        operators.add(msg.sender);
    }

    modifier onlyOperator() {
        require(isOperator(msg.sender));
        _;
    }
    
    function isOperator(address account) public view returns (bool) {
        return operators.has(account);
    }

    function addOperator(address account) public onlyOperator() {
        operators.add(account);
        emit OperatorAdded(account);
    }

    function removeOperator(address account) public onlyOperator() {
        operators.remove(account);
        emit OperatorRemoved(account);
    }

}

 

 

library ECDSA {
     
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        bytes32 r;
        bytes32 s;
        uint8 v;

         
        if (signature.length != 65) {
            return (address(0));
        }

         
         
         
         
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

         
        if (v < 27) {
            v += 27;
        }

         
        if (v != 27 && v != 28) {
            return (address(0));
        } else {
            return ecrecover(hash, v, r, s);
        }
    }

     
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
         
         
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}

 

contract MCHPrime is OperatorRole, DJTBase {


	uint128 public primeFee;
	uint256 public primeTerm;
	uint256 public allowedUpdateBuffer;
	mapping(address => uint256) public addressToExpiredAt;

	address public validater;
  
	event PrimeFeeUpdated(
		uint128 PrimeFeeUpdated
	);

	event PrimeTermAdded(
		address user,
		uint256 expiredAt,
		uint256 at
	);

	event PrimeTermUpdated(
		uint256 primeTerm
	);

	event AllowedUpdateBufferUpdated(
		uint256 allowedUpdateBuffer
	);

	event ExpiredAtUpdated(
		address user,
		uint256 expiredAt,
		uint256 at
	);

	constructor() public {
		primeFee = 0.1 ether;
		primeTerm = 30 days;
		allowedUpdateBuffer = 5 days;
	}

	function setValidater(address _varidater) external onlyOwner() {
		validater = _varidater;
	}

	function updatePrimeFee(uint128 _newPrimeFee) external onlyOwner() {
		primeFee = _newPrimeFee;
		emit PrimeFeeUpdated(
			primeFee
		);
	}

	function updatePrimeTerm(uint256 _newPrimeTerm) external onlyOwner() {
		primeTerm = _newPrimeTerm;
		emit PrimeTermUpdated(
			primeTerm
		);
	}

	function updateAllowedUpdateBuffer(uint256 _newAllowedUpdateBuffer) external onlyOwner() {
		allowedUpdateBuffer = _newAllowedUpdateBuffer;
		emit AllowedUpdateBufferUpdated(
			allowedUpdateBuffer
		);
	}

	function updateExpiredAt(address _user, uint256 _expiredAt) external onlyOperator() {
		addressToExpiredAt[_user] = _expiredAt;
		emit ExpiredAtUpdated(
			_user,
			_expiredAt,
			block.timestamp
		);
	}

	function buyPrimeRights(bytes calldata _signature) external whenNotPaused() payable {
		require(msg.value == primeFee, "not enough eth");
		require(canUpdateNow(msg.sender), "unable to update");
		require(validateSig(_signature, bytes32(uint256(msg.sender))), "invalid signature");

		uint256 _now = block.timestamp;
		uint256 expiredAt = addressToExpiredAt[msg.sender];
		if (expiredAt <= _now) {
			addressToExpiredAt[msg.sender] = _now.add(primeTerm);
		} else if(expiredAt <= _now.add(allowedUpdateBuffer)) {
			addressToExpiredAt[msg.sender] = expiredAt.add(primeTerm);
		}

		emit PrimeTermAdded(
			msg.sender,
			addressToExpiredAt[msg.sender],
			_now
		);
	}

	function canUpdateNow(address _user) public view returns (bool) {
		uint256 _now = block.timestamp;
		uint256 expiredAt = addressToExpiredAt[_user];
		 
		if (expiredAt <= _now) {
			return true;
		}
		 
		if (expiredAt <= _now.add(allowedUpdateBuffer)) {
			return true;
		}
		return false;
	}

	function validateSig(bytes memory _signature, bytes32 _message) private view returns (bool) {
		require(validater != address(0));
		address signer = ECDSA.recover(ECDSA.toEthSignedMessageHash(_message), _signature);
		return (signer == validater);
	}

}
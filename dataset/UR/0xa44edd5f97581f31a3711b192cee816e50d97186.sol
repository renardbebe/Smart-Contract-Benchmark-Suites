 

 

pragma solidity ^0.5.0;

 
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

 

pragma solidity ^0.5.0;

 
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

 

pragma solidity ^0.5.0;



 
contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowed;

    uint256 private _totalSupply;

     
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

     
    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

     
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowed[owner][spender];
    }

     
    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

     
    function approve(address spender, uint256 value) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

     
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
        _transfer(from, to, value);
        emit Approval(from, msg.sender, _allowed[from][msg.sender]);
        return true;
    }

     
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

     
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].sub(subtractedValue);
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

     
    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0));

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }

     
    function _mint(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.add(value);
        _balances[account] = _balances[account].add(value);
        emit Transfer(address(0), account, value);
    }

     
    function _burn(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

     
    function _burnFrom(address account, uint256 value) internal {
        _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(value);
        _burn(account, value);
        emit Approval(account, msg.sender, _allowed[account][msg.sender]);
    }
}

 

pragma solidity ^0.5.0;

 
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

 

pragma solidity ^0.5.0;

interface MockInterface {
	 
	function givenAnyReturn(bytes calldata response) external;
	function givenAnyReturnBool(bool response) external;
	function givenAnyReturnUint(uint response) external;
	function givenAnyReturnAddress(address response) external;

	function givenAnyRevert() external;
	function givenAnyRevertWithMessage(string calldata message) external;
	function givenAnyRunOutOfGas() external;

	 
	function givenMethodReturn(bytes calldata method, bytes calldata response) external;
	function givenMethodReturnBool(bytes calldata method, bool response) external;
	function givenMethodReturnUint(bytes calldata method, uint response) external;
	function givenMethodReturnAddress(bytes calldata method, address response) external;

	function givenMethodRevert(bytes calldata method) external;
	function givenMethodRevertWithMessage(bytes calldata method, string calldata message) external;
	function givenMethodRunOutOfGas(bytes calldata method) external;

	 
	function givenCalldataReturn(bytes calldata call, bytes calldata response) external;
	function givenCalldataReturnBool(bytes calldata call, bool response) external;
	function givenCalldataReturnUint(bytes calldata call, uint response) external;
	function givenCalldataReturnAddress(bytes calldata call, address response) external;

	function givenCalldataRevert(bytes calldata call) external;
	function givenCalldataRevertWithMessage(bytes calldata call, string calldata message) external;
	function givenCalldataRunOutOfGas(bytes calldata call) external;

	 
	function invocationCount() external returns (uint);

	 
	function invocationCountForMethod(bytes calldata method) external returns (uint);

	 
	function invocationCountForCalldata(bytes calldata call) external returns (uint);

	 
	 function reset() external;
}

 
contract MockContract is MockInterface {
	enum MockType { Return, Revert, OutOfGas }
	
	bytes32 public constant MOCKS_LIST_START = hex"01";
	bytes public constant MOCKS_LIST_END = "0xff";
	bytes32 public constant MOCKS_LIST_END_HASH = keccak256(MOCKS_LIST_END);
	bytes4 public constant SENTINEL_ANY_MOCKS = hex"01";

	 
	mapping(bytes32 => bytes) calldataMocks;
	mapping(bytes => MockType) calldataMockTypes;
	mapping(bytes => bytes) calldataExpectations;
	mapping(bytes => string) calldataRevertMessage;
	mapping(bytes32 => uint) calldataInvocations;

	mapping(bytes4 => bytes4) methodIdMocks;
	mapping(bytes4 => MockType) methodIdMockTypes;
	mapping(bytes4 => bytes) methodIdExpectations;
	mapping(bytes4 => string) methodIdRevertMessages;
	mapping(bytes32 => uint) methodIdInvocations;

	MockType fallbackMockType;
	bytes fallbackExpectation;
	string fallbackRevertMessage;
	uint invocations;
	uint resetCount;

	constructor() public {
		calldataMocks[MOCKS_LIST_START] = MOCKS_LIST_END;
		methodIdMocks[SENTINEL_ANY_MOCKS] = SENTINEL_ANY_MOCKS;
	}

	function trackCalldataMock(bytes memory call) private {
		bytes32 callHash = keccak256(call);
		if (calldataMocks[callHash].length == 0) {
			calldataMocks[callHash] = calldataMocks[MOCKS_LIST_START];
			calldataMocks[MOCKS_LIST_START] = call;
		}
	}

	function trackMethodIdMock(bytes4 methodId) private {
		if (methodIdMocks[methodId] == 0x0) {
			methodIdMocks[methodId] = methodIdMocks[SENTINEL_ANY_MOCKS];
			methodIdMocks[SENTINEL_ANY_MOCKS] = methodId;
		}
	}

	function _givenAnyReturn(bytes memory response) internal {
		fallbackMockType = MockType.Return;
		fallbackExpectation = response;
	}

	function givenAnyReturn(bytes calldata response) external {
		_givenAnyReturn(response);
	}

	function givenAnyReturnBool(bool response) external {
		uint flag = response ? 1 : 0;
		_givenAnyReturn(uintToBytes(flag));
	}

	function givenAnyReturnUint(uint response) external {
		_givenAnyReturn(uintToBytes(response));	
	}

	function givenAnyReturnAddress(address response) external {
		_givenAnyReturn(uintToBytes(uint(response)));
	}

	function givenAnyRevert() external {
		fallbackMockType = MockType.Revert;
		fallbackRevertMessage = "";
	}

	function givenAnyRevertWithMessage(string calldata message) external {
		fallbackMockType = MockType.Revert;
		fallbackRevertMessage = message;
	}

	function givenAnyRunOutOfGas() external {
		fallbackMockType = MockType.OutOfGas;
	}

	function _givenCalldataReturn(bytes memory call, bytes memory response) private  {
		calldataMockTypes[call] = MockType.Return;
		calldataExpectations[call] = response;
		trackCalldataMock(call);
	}

	function givenCalldataReturn(bytes calldata call, bytes calldata response) external  {
		_givenCalldataReturn(call, response);
	}

	function givenCalldataReturnBool(bytes calldata call, bool response) external {
		uint flag = response ? 1 : 0;
		_givenCalldataReturn(call, uintToBytes(flag));
	}

	function givenCalldataReturnUint(bytes calldata call, uint response) external {
		_givenCalldataReturn(call, uintToBytes(response));
	}

	function givenCalldataReturnAddress(bytes calldata call, address response) external {
		_givenCalldataReturn(call, uintToBytes(uint(response)));
	}

	function _givenMethodReturn(bytes memory call, bytes memory response) private {
		bytes4 method = bytesToBytes4(call);
		methodIdMockTypes[method] = MockType.Return;
		methodIdExpectations[method] = response;
		trackMethodIdMock(method);		
	}

	function givenMethodReturn(bytes calldata call, bytes calldata response) external {
		_givenMethodReturn(call, response);
	}

	function givenMethodReturnBool(bytes calldata call, bool response) external {
		uint flag = response ? 1 : 0;
		_givenMethodReturn(call, uintToBytes(flag));
	}

	function givenMethodReturnUint(bytes calldata call, uint response) external {
		_givenMethodReturn(call, uintToBytes(response));
	}

	function givenMethodReturnAddress(bytes calldata call, address response) external {
		_givenMethodReturn(call, uintToBytes(uint(response)));
	}

	function givenCalldataRevert(bytes calldata call) external {
		calldataMockTypes[call] = MockType.Revert;
		calldataRevertMessage[call] = "";
		trackCalldataMock(call);
	}

	function givenMethodRevert(bytes calldata call) external {
		bytes4 method = bytesToBytes4(call);
		methodIdMockTypes[method] = MockType.Revert;
		trackMethodIdMock(method);		
	}

	function givenCalldataRevertWithMessage(bytes calldata call, string calldata message) external {
		calldataMockTypes[call] = MockType.Revert;
		calldataRevertMessage[call] = message;
		trackCalldataMock(call);
	}

	function givenMethodRevertWithMessage(bytes calldata call, string calldata message) external {
		bytes4 method = bytesToBytes4(call);
		methodIdMockTypes[method] = MockType.Revert;
		methodIdRevertMessages[method] = message;
		trackMethodIdMock(method);		
	}

	function givenCalldataRunOutOfGas(bytes calldata call) external {
		calldataMockTypes[call] = MockType.OutOfGas;
		trackCalldataMock(call);
	}

	function givenMethodRunOutOfGas(bytes calldata call) external {
		bytes4 method = bytesToBytes4(call);
		methodIdMockTypes[method] = MockType.OutOfGas;
		trackMethodIdMock(method);	
	}

	function invocationCount() external returns (uint) {
		return invocations;
	}

	function invocationCountForMethod(bytes calldata call) external returns (uint) {
		bytes4 method = bytesToBytes4(call);
		return methodIdInvocations[keccak256(abi.encodePacked(resetCount, method))];
	}

	function invocationCountForCalldata(bytes calldata call) external returns (uint) {
		return calldataInvocations[keccak256(abi.encodePacked(resetCount, call))];
	}

	function reset() external {
		 
		bytes memory nextMock = calldataMocks[MOCKS_LIST_START];
		bytes32 mockHash = keccak256(nextMock);
		 
		while(mockHash != MOCKS_LIST_END_HASH) {
			 
			calldataMockTypes[nextMock] = MockType.Return;
			calldataExpectations[nextMock] = hex"";
			calldataRevertMessage[nextMock] = "";
			 
			nextMock = calldataMocks[mockHash];
			 
			calldataMocks[mockHash] = "";
			 
			mockHash = keccak256(nextMock);
		}
		 
		calldataMocks[MOCKS_LIST_START] = MOCKS_LIST_END;

		 
		bytes4 nextAnyMock = methodIdMocks[SENTINEL_ANY_MOCKS];
		while(nextAnyMock != SENTINEL_ANY_MOCKS) {
			bytes4 currentAnyMock = nextAnyMock;
			methodIdMockTypes[currentAnyMock] = MockType.Return;
			methodIdExpectations[currentAnyMock] = hex"";
			methodIdRevertMessages[currentAnyMock] = "";
			nextAnyMock = methodIdMocks[currentAnyMock];
			 
			methodIdMocks[currentAnyMock] = 0x0;
		}
		 
		methodIdMocks[SENTINEL_ANY_MOCKS] = SENTINEL_ANY_MOCKS;

		fallbackExpectation = "";
		fallbackMockType = MockType.Return;
		invocations = 0;
		resetCount += 1;
	}

	function useAllGas() private {
		while(true) {
			bool s;
			assembly {
				 
				s := call(sub(gas, 2000), 6, 0, 0x0, 0xc0, 0x0, 0x60)
			}
		}
	}

	function bytesToBytes4(bytes memory b) private pure returns (bytes4) {
		bytes4 out;
		for (uint i = 0; i < 4; i++) {
			out |= bytes4(b[i] & 0xFF) >> (i * 8);
		}
		return out;
	}

	function uintToBytes(uint256 x) private pure returns (bytes memory b) {
		b = new bytes(32);
		assembly { mstore(add(b, 32), x) }
	}

	function updateInvocationCount(bytes4 methodId, bytes memory originalMsgData) public {
		require(msg.sender == address(this), "Can only be called from the contract itself");
		invocations += 1;
		methodIdInvocations[keccak256(abi.encodePacked(resetCount, methodId))] += 1;
		calldataInvocations[keccak256(abi.encodePacked(resetCount, originalMsgData))] += 1;
	}

	function() payable external {
		bytes4 methodId;
		assembly {
			methodId := calldataload(0)
		}

		 
		if (calldataMockTypes[msg.data] == MockType.Revert) {
			revert(calldataRevertMessage[msg.data]);
		}
		if (calldataMockTypes[msg.data] == MockType.OutOfGas) {
			useAllGas();
		}
		bytes memory result = calldataExpectations[msg.data];

		 
		if (result.length == 0) {
			if (methodIdMockTypes[methodId] == MockType.Revert) {
				revert(methodIdRevertMessages[methodId]);
			}
			if (methodIdMockTypes[methodId] == MockType.OutOfGas) {
				useAllGas();
			}
			result = methodIdExpectations[methodId];
		}

		 
		if (result.length == 0) {
			if (fallbackMockType == MockType.Revert) {
				revert(fallbackRevertMessage);
			}
			if (fallbackMockType == MockType.OutOfGas) {
				useAllGas();
			}
			result = fallbackExpectation;
		}

		 
		(, bytes memory r) = address(this).call.gas(100000)(abi.encodeWithSignature("updateInvocationCount(bytes4,bytes)", methodId, msg.data));
		assert(r.length == 0);
		
		assembly {
			return(add(0x20, result), mload(result))
		}
	}
}

 

pragma solidity ^0.5.0;

 
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

 

pragma solidity ^0.5.0;


contract MinterRole {
    using Roles for Roles.Role;

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    Roles.Role private _minters;

    constructor () internal {
        _addMinter(msg.sender);
    }

    modifier onlyMinter() {
        require(isMinter(msg.sender));
        _;
    }

    function isMinter(address account) public view returns (bool) {
        return _minters.has(account);
    }

    function addMinter(address account) public onlyMinter {
        _addMinter(account);
    }

    function renounceMinter() public {
        _removeMinter(msg.sender);
    }

    function _addMinter(address account) internal {
        _minters.add(account);
        emit MinterAdded(account);
    }

    function _removeMinter(address account) internal {
        _minters.remove(account);
        emit MinterRemoved(account);
    }
}

 

pragma solidity ^0.5.0;



 
contract ERC20Mintable is ERC20, MinterRole {
     
    function mint(address to, uint256 value) public onlyMinter returns (bool) {
        _mint(to, value);
        return true;
    }
}

 

pragma solidity ^0.5.0;



contract IDutchExchange {

    mapping(address => mapping(address => mapping(uint => mapping(address => uint)))) public sellerBalances;
    mapping(address => mapping(address => mapping(uint => mapping(address => uint)))) public buyerBalances;
    mapping(address => mapping(address => mapping(uint => mapping(address => uint)))) public claimedAmounts;
    mapping(address => mapping(address => uint)) public balances;

    function withdraw(address tokenAddress, uint amount) public returns (uint);
    function deposit(address tokenAddress, uint amount) public returns (uint);
    function ethToken() public returns(address);
    function frtToken() public returns(address);
    function getAuctionIndex(address token1, address token2) public view returns(uint256);
    function postBuyOrder(address token1, address token2, uint256 auctionIndex, uint256 amount) public returns(uint256);
    function postSellOrder(address token1, address token2, uint256 auctionIndex, uint256 tokensBought) public returns(uint256, uint256);
    function getCurrentAuctionPrice(address token1, address token2, uint256 auctionIndex) public view returns(uint256, uint256);
    function claimSellerFunds(address sellToken, address buyToken, address user, uint auctionIndex) public returns (uint returned, uint frtsIssued);
}

 

pragma solidity ^0.5.2;

 
 
contract Proxied {
    address public masterCopy;
}

 
 
contract Proxy is Proxied {
     
     
    constructor(address _masterCopy) public {
        require(_masterCopy != address(0), "The master copy is required");
        masterCopy = _masterCopy;
    }

     
    function() external payable {
        address _masterCopy = masterCopy;
        assembly {
            calldatacopy(0, 0, calldatasize)
            let success := delegatecall(not(0), _masterCopy, 0, calldatasize, 0, 0)
            returndatacopy(0, 0, returndatasize)
            switch success
                case 0 {
                    revert(0, returndatasize)
                }
                default {
                    return(0, returndatasize)
                }
        }
    }
}

 

 
pragma solidity ^0.5.2;

 
contract Token {
     
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);

     
    function transfer(address to, uint value) public returns (bool);
    function transferFrom(address from, address to, uint value) public returns (bool);
    function approve(address spender, uint value) public returns (bool);
    function balanceOf(address owner) public view returns (uint);
    function allowance(address owner, address spender) public view returns (uint);
    function totalSupply() public view returns (uint);
}

 

pragma solidity ^0.5.2;

 
 
 
library GnosisMath {
     
     
    uint public constant ONE = 0x10000000000000000;
    uint public constant LN2 = 0xb17217f7d1cf79ac;
    uint public constant LOG2_E = 0x171547652b82fe177;

     
     
     
     
    function exp(int x) public pure returns (uint) {
         
         
        require(x <= 2454971259878909886679);
         
         
        if (x < -818323753292969962227) return 0;
         
        x = x * int(ONE) / int(LN2);
         
         
         
        int shift;
        uint z;
        if (x >= 0) {
            shift = x / int(ONE);
            z = uint(x % int(ONE));
        } else {
            shift = x / int(ONE) - 1;
            z = ONE - uint(-x % int(ONE));
        }
         
         
         
         
         
         
         
         
         
         
         
         
         
        uint zpow = z;
        uint result = ONE;
        result += 0xb17217f7d1cf79ab * zpow / ONE;
        zpow = zpow * z / ONE;
        result += 0x3d7f7bff058b1d50 * zpow / ONE;
        zpow = zpow * z / ONE;
        result += 0xe35846b82505fc5 * zpow / ONE;
        zpow = zpow * z / ONE;
        result += 0x276556df749cee5 * zpow / ONE;
        zpow = zpow * z / ONE;
        result += 0x5761ff9e299cc4 * zpow / ONE;
        zpow = zpow * z / ONE;
        result += 0xa184897c363c3 * zpow / ONE;
        zpow = zpow * z / ONE;
        result += 0xffe5fe2c4586 * zpow / ONE;
        zpow = zpow * z / ONE;
        result += 0x162c0223a5c8 * zpow / ONE;
        zpow = zpow * z / ONE;
        result += 0x1b5253d395e * zpow / ONE;
        zpow = zpow * z / ONE;
        result += 0x1e4cf5158b * zpow / ONE;
        zpow = zpow * z / ONE;
        result += 0x1e8cac735 * zpow / ONE;
        zpow = zpow * z / ONE;
        result += 0x1c3bd650 * zpow / ONE;
        zpow = zpow * z / ONE;
        result += 0x1816193 * zpow / ONE;
        zpow = zpow * z / ONE;
        result += 0x131496 * zpow / ONE;
        zpow = zpow * z / ONE;
        result += 0xe1b7 * zpow / ONE;
        zpow = zpow * z / ONE;
        result += 0x9c7 * zpow / ONE;
        if (shift >= 0) {
            if (result >> (256 - shift) > 0) return (2 ** 256 - 1);
            return result << shift;
        } else return result >> (-shift);
    }

     
     
     
    function ln(uint x) public pure returns (int) {
        require(x > 0);
         
        int ilog2 = floorLog2(x);
        int z;
        if (ilog2 < 0) z = int(x << uint(-ilog2));
        else z = int(x >> uint(ilog2));
         
         
         
         
         
        int term = (z - int(ONE)) * int(ONE) / (z + int(ONE));
        int halflnz = term;
        int termpow = term * term / int(ONE) * term / int(ONE);
        halflnz += termpow / 3;
        termpow = termpow * term / int(ONE) * term / int(ONE);
        halflnz += termpow / 5;
        termpow = termpow * term / int(ONE) * term / int(ONE);
        halflnz += termpow / 7;
        termpow = termpow * term / int(ONE) * term / int(ONE);
        halflnz += termpow / 9;
        termpow = termpow * term / int(ONE) * term / int(ONE);
        halflnz += termpow / 11;
        termpow = termpow * term / int(ONE) * term / int(ONE);
        halflnz += termpow / 13;
        termpow = termpow * term / int(ONE) * term / int(ONE);
        halflnz += termpow / 15;
        termpow = termpow * term / int(ONE) * term / int(ONE);
        halflnz += termpow / 17;
        termpow = termpow * term / int(ONE) * term / int(ONE);
        halflnz += termpow / 19;
        termpow = termpow * term / int(ONE) * term / int(ONE);
        halflnz += termpow / 21;
        termpow = termpow * term / int(ONE) * term / int(ONE);
        halflnz += termpow / 23;
        termpow = termpow * term / int(ONE) * term / int(ONE);
        halflnz += termpow / 25;
        return (ilog2 * int(ONE)) * int(ONE) / int(LOG2_E) + 2 * halflnz;
    }

     
     
     
    function floorLog2(uint x) public pure returns (int lo) {
        lo = -64;
        int hi = 193;
         
        int mid = (hi + lo) >> 1;
        while ((lo + 1) < hi) {
            if (mid < 0 && x << uint(-mid) < ONE || mid >= 0 && x >> uint(mid) < ONE) hi = mid;
            else lo = mid;
            mid = (hi + lo) >> 1;
        }
    }

     
     
     
    function max(int[] memory nums) public pure returns (int maxNum) {
        require(nums.length > 0);
        maxNum = -2 ** 255;
        for (uint i = 0; i < nums.length; i++) if (nums[i] > maxNum) maxNum = nums[i];
    }

     
     
     
     
    function safeToAdd(uint a, uint b) internal pure returns (bool) {
        return a + b >= a;
    }

     
     
     
     
    function safeToSub(uint a, uint b) internal pure returns (bool) {
        return a >= b;
    }

     
     
     
     
    function safeToMul(uint a, uint b) internal pure returns (bool) {
        return b == 0 || a * b / b == a;
    }

     
     
     
     
    function add(uint a, uint b) internal pure returns (uint) {
        require(safeToAdd(a, b));
        return a + b;
    }

     
     
     
     
    function sub(uint a, uint b) internal pure returns (uint) {
        require(safeToSub(a, b));
        return a - b;
    }

     
     
     
     
    function mul(uint a, uint b) internal pure returns (uint) {
        require(safeToMul(a, b));
        return a * b;
    }

     
     
     
     
    function safeToAdd(int a, int b) internal pure returns (bool) {
        return (b >= 0 && a + b >= a) || (b < 0 && a + b < a);
    }

     
     
     
     
    function safeToSub(int a, int b) internal pure returns (bool) {
        return (b >= 0 && a - b <= a) || (b < 0 && a - b > a);
    }

     
     
     
     
    function safeToMul(int a, int b) internal pure returns (bool) {
        return (b == 0) || (a * b / b == a);
    }

     
     
     
     
    function add(int a, int b) internal pure returns (int) {
        require(safeToAdd(a, b));
        return a + b;
    }

     
     
     
     
    function sub(int a, int b) internal pure returns (int) {
        require(safeToSub(a, b));
        return a - b;
    }

     
     
     
     
    function mul(int a, int b) internal pure returns (int) {
        require(safeToMul(a, b));
        return a * b;
    }
}

 

pragma solidity ^0.5.2;




 
contract StandardTokenData {
     
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowances;
    uint totalTokens;
}

 
 
contract GnosisStandardToken is Token, StandardTokenData {
    using GnosisMath for *;

     
     
     
     
     
    function transfer(address to, uint value) public returns (bool) {
        if (!balances[msg.sender].safeToSub(value) || !balances[to].safeToAdd(value)) {
            return false;
        }

        balances[msg.sender] -= value;
        balances[to] += value;
        emit Transfer(msg.sender, to, value);
        return true;
    }

     
     
     
     
     
    function transferFrom(address from, address to, uint value) public returns (bool) {
        if (!balances[from].safeToSub(value) || !allowances[from][msg.sender].safeToSub(
            value
        ) || !balances[to].safeToAdd(value)) {
            return false;
        }
        balances[from] -= value;
        allowances[from][msg.sender] -= value;
        balances[to] += value;
        emit Transfer(from, to, value);
        return true;
    }

     
     
     
     
    function approve(address spender, uint value) public returns (bool) {
        allowances[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

     
     
     
     
    function allowance(address owner, address spender) public view returns (uint) {
        return allowances[owner][spender];
    }

     
     
     
    function balanceOf(address owner) public view returns (uint) {
        return balances[owner];
    }

     
     
    function totalSupply() public view returns (uint) {
        return totalTokens;
    }
}

 

pragma solidity ^0.5.2;




 
contract TokenFRT is Proxied, GnosisStandardToken {
    address public owner;

    string public constant symbol = "MGN";
    string public constant name = "Magnolia Token";
    uint8 public constant decimals = 18;

    struct UnlockedToken {
        uint amountUnlocked;
        uint withdrawalTime;
    }

     
    address public minter;

     
    mapping(address => UnlockedToken) public unlockedTokens;

     
    mapping(address => uint) public lockedTokenBalances;

     

     
     
    function updateMinter(address _minter) public {
        require(msg.sender == owner, "Only the minter can set a new one");
        require(_minter != address(0), "The new minter must be a valid address");

        minter = _minter;
    }

     
     
    function updateOwner(address _owner) public {
        require(msg.sender == owner, "Only the owner can update the owner");
        require(_owner != address(0), "The new owner must be a valid address");
        owner = _owner;
    }

    function mintTokens(address user, uint amount) public {
        require(msg.sender == minter, "Only the minter can mint tokens");

        lockedTokenBalances[user] = add(lockedTokenBalances[user], amount);
        totalTokens = add(totalTokens, amount);
    }

     
    function lockTokens(uint amount) public returns (uint totalAmountLocked) {
         
        uint actualAmount = min(amount, balances[msg.sender]);

         
        balances[msg.sender] = sub(balances[msg.sender], actualAmount);
        lockedTokenBalances[msg.sender] = add(lockedTokenBalances[msg.sender], actualAmount);

         
        totalAmountLocked = lockedTokenBalances[msg.sender];
    }

    function unlockTokens() public returns (uint totalAmountUnlocked, uint withdrawalTime) {
         
        uint amount = lockedTokenBalances[msg.sender];

        if (amount > 0) {
             
            lockedTokenBalances[msg.sender] = sub(lockedTokenBalances[msg.sender], amount);
            unlockedTokens[msg.sender].amountUnlocked = add(unlockedTokens[msg.sender].amountUnlocked, amount);
            unlockedTokens[msg.sender].withdrawalTime = now + 24 hours;
        }

         
        totalAmountUnlocked = unlockedTokens[msg.sender].amountUnlocked;
        withdrawalTime = unlockedTokens[msg.sender].withdrawalTime;
    }

    function withdrawUnlockedTokens() public {
        require(unlockedTokens[msg.sender].withdrawalTime < now, "The tokens cannot be withdrawn yet");
        balances[msg.sender] = add(balances[msg.sender], unlockedTokens[msg.sender].amountUnlocked);
        unlockedTokens[msg.sender].amountUnlocked = 0;
    }

    function min(uint a, uint b) public pure returns (uint) {
        if (a < b) {
            return a;
        } else {
            return b;
        }
    }
    
     
     
     
     
    function safeToAdd(uint a, uint b) public pure returns (bool) {
        return a + b >= a;
    }

     
     
     
     
    function safeToSub(uint a, uint b) public pure returns (bool) {
        return a >= b;
    }

     
     
     
     
    function add(uint a, uint b) public pure returns (uint) {
        require(safeToAdd(a, b), "It must be a safe adition");
        return a + b;
    }

     
     
     
     
    function sub(uint a, uint b) public pure returns (uint) {
        require(safeToSub(a, b), "It must be a safe substraction");
        return a - b;
    }
}

 

pragma solidity ^0.5.0;

 
library Address {
     
    function isContract(address account) internal view returns (bool) {
        uint256 size;
         
         
         
         
         
         
         
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

 

 
pragma solidity ^0.5.2;



library SafeERC20 {
    using Address for address;

    bytes4 constant private TRANSFER_SELECTOR = bytes4(keccak256(bytes("transfer(address,uint256)")));
    bytes4 constant private TRANSFERFROM_SELECTOR = bytes4(keccak256(bytes("transferFrom(address,address,uint256)")));
    bytes4 constant private APPROVE_SELECTOR = bytes4(keccak256(bytes("approve(address,uint256)")));

    function safeTransfer(address _erc20Addr, address _to, uint256 _value) internal {

         
        require(_erc20Addr.isContract());

        (bool success, bytes memory returnValue) =
         
        _erc20Addr.call(abi.encodeWithSelector(TRANSFER_SELECTOR, _to, _value));
         
        require(success);
         
        require(returnValue.length == 0 || (returnValue.length == 32 && (returnValue[31] != 0)));
    }

    function safeTransferFrom(address _erc20Addr, address _from, address _to, uint256 _value) internal {

         
        require(_erc20Addr.isContract());

        (bool success, bytes memory returnValue) =
         
        _erc20Addr.call(abi.encodeWithSelector(TRANSFERFROM_SELECTOR, _from, _to, _value));
         
        require(success);
         
        require(returnValue.length == 0 || (returnValue.length == 32 && (returnValue[31] != 0)));
    }

    function safeApprove(address _erc20Addr, address _spender, uint256 _value) internal {

         
        require(_erc20Addr.isContract());

         
         
        require((_value == 0) || (IERC20(_erc20Addr).allowance(msg.sender, _spender) == 0));

        (bool success, bytes memory returnValue) =
         
        _erc20Addr.call(abi.encodeWithSelector(APPROVE_SELECTOR, _spender, _value));
         
        require(success);
         
        require(returnValue.length == 0 || (returnValue.length == 32 && (returnValue[31] != 0)));
    }
}

 

pragma solidity ^0.5.0;








contract DxMgnPool is Ownable {
    using SafeMath for uint;

    struct Participation {
        uint startAuctionCount;  
        uint poolShares;  
    }
    mapping (address => bool) hasParticpationWithdrawn;
    enum State {
        Pooling,
        PoolingEnded,
        DepositWithdrawnFromDx,
        MgnUnlocked
    }
    State public currentState = State.Pooling;

    mapping (address => Participation[]) public participationsByAddress;
    uint public totalPoolShares;  
    uint public totalPoolSharesCummulative;  
    uint public totalDeposit;
    uint public totalMgn;
    uint public lastParticipatedAuctionIndex;
    uint public auctionCount;
    
    ERC20 public depositToken;
    ERC20 public secondaryToken;
    TokenFRT public mgnToken;
    IDutchExchange public dx;

    uint public poolingPeriodEndTime;

    constructor (
        ERC20 _depositToken, 
        ERC20 _secondaryToken, 
        IDutchExchange _dx,
        uint _poolingTimeSeconds
    ) public Ownable()
    {
        depositToken = _depositToken;
        secondaryToken = _secondaryToken;
        dx = _dx;
        mgnToken = TokenFRT(dx.frtToken());
        poolingPeriodEndTime = now + _poolingTimeSeconds;
    }

     
    function deposit(uint amount) public {
        checkForStateUpdate();
        require(currentState == State.Pooling, "Pooling is already over");

        uint poolShares = calculatePoolShares(amount);
        Participation memory participation = Participation({
            startAuctionCount: isDepositTokenTurn() ? auctionCount : auctionCount + 1,
            poolShares: poolShares
            });
        participationsByAddress[msg.sender].push(participation);
        totalPoolShares += poolShares;
        totalDeposit += amount;

        SafeERC20.safeTransferFrom(address(depositToken), msg.sender, address(this), amount);
    }

    function withdrawDeposit() public returns(uint) {
        require(currentState == State.DepositWithdrawnFromDx || currentState == State.MgnUnlocked, "Funds not yet withdrawn from dx");
        require(!hasParticpationWithdrawn[msg.sender],"sender has already withdrawn funds");

        uint totalDepositAmount = 0;
        Participation[] storage participations = participationsByAddress[msg.sender];
        uint length = participations.length;
        for (uint i = 0; i < length; i++) {
            totalDepositAmount += calculateClaimableDeposit(participations[i]);
        }
        hasParticpationWithdrawn[msg.sender] = true;
        SafeERC20.safeTransfer(address(depositToken), msg.sender, totalDepositAmount);
        return totalDepositAmount;
    }

    function withdrawMagnolia() public returns(uint) {
        require(currentState == State.MgnUnlocked, "MGN has not been unlocked, yet");
        require(hasParticpationWithdrawn[msg.sender], "Withdraw deposits first");
        
        uint totalMgnClaimed = 0;
        Participation[] memory participations = participationsByAddress[msg.sender];
        for (uint i = 0; i < participations.length; i++) {
            totalMgnClaimed += calculateClaimableMgn(participations[i]);
        }
        delete participationsByAddress[msg.sender];
        delete hasParticpationWithdrawn[msg.sender];
        SafeERC20.safeTransfer(address(mgnToken), msg.sender, totalMgnClaimed);
        return totalMgnClaimed;
    }

    function participateInAuction() public  onlyOwner() {
        checkForStateUpdate();
        require(currentState == State.Pooling, "Pooling period is over.");

        uint auctionIndex = dx.getAuctionIndex(address(depositToken), address(secondaryToken));
        require(auctionIndex > lastParticipatedAuctionIndex, "Has to wait for new auction to start");

        (address sellToken, address buyToken) = sellAndBuyToken();
        uint depositAmount = depositToken.balanceOf(address(this));
        if (isDepositTokenTurn()) {
            totalPoolSharesCummulative += 2 * totalPoolShares;
            if( depositAmount > 0){
                 
                depositToken.approve(address(dx), depositAmount);
                dx.deposit(address(depositToken), depositAmount);
            }
        }
         
        address(dx).call(abi.encodeWithSignature("claimSellerFunds(address,address,address,uint256)", buyToken, sellToken, address(this), lastParticipatedAuctionIndex));

        uint amount = dx.balances(address(sellToken), address(this));
        if (isDepositTokenTurn()) {
            totalDeposit = amount;
        }

        (lastParticipatedAuctionIndex, ) = dx.postSellOrder(sellToken, buyToken, 0, amount);
        auctionCount += 1;
    }

    function triggerMGNunlockAndClaimTokens() public {
        checkForStateUpdate();
        require(currentState == State.PoolingEnded, "Pooling period is not yet over.");
        require(
            dx.getAuctionIndex(address(depositToken), address(secondaryToken)) > lastParticipatedAuctionIndex, 
            "Last auction is still running"
        );      
        
         
        address(dx).call(abi.encodeWithSignature("claimSellerFunds(address,address,address,uint256)", secondaryToken, depositToken, address(this), lastParticipatedAuctionIndex));
        mgnToken.unlockTokens();

        uint amountOfFundsInDX = dx.balances(address(depositToken), address(this));
        totalDeposit = amountOfFundsInDX + depositToken.balanceOf(address(this));
        if(amountOfFundsInDX > 0){
            dx.withdraw(address(depositToken), amountOfFundsInDX);
        }
        currentState = State.DepositWithdrawnFromDx;
    }

    function withdrawUnlockedMagnoliaFromDx() public {
        require(currentState == State.DepositWithdrawnFromDx, "Unlocking not yet triggered");

         
         

        mgnToken.withdrawUnlockedTokens();
        totalMgn = mgnToken.balanceOf(address(this));

        currentState = State.MgnUnlocked;
    }

    function checkForStateUpdate() public {
        if (now >= poolingPeriodEndTime && isDepositTokenTurn() && currentState == State.Pooling) {
            currentState = State.PoolingEnded;
        }
    }

     
    function updateAndGetCurrentState() public returns(State) {
        checkForStateUpdate();

        return currentState;
    }

     
     
    function numberOfParticipations(address addr) public view returns (uint) {
        return participationsByAddress[addr].length;
    }

    function participationAtIndex(address addr, uint index) public view returns (uint, uint) {
        Participation memory participation = participationsByAddress[addr][index];
        return (participation.startAuctionCount, participation.poolShares);
    }

    function poolSharesByAddress(address userAddress) external view returns(uint[] memory) {
        uint length = participationsByAddress[userAddress].length;        
        uint[] memory userTotalPoolShares = new uint[](length);
        
        for (uint i = 0; i < length; i++) {
            userTotalPoolShares[i] = participationsByAddress[userAddress][i].poolShares;
        }

        return userTotalPoolShares;
    }

    function sellAndBuyToken() public view returns(address sellToken, address buyToken) {
        if (isDepositTokenTurn()) {
            return (address(depositToken), address(secondaryToken));
        } else {
            return (address(secondaryToken), address(depositToken)); 
        }
    }

    function getAllClaimableMgnAndDeposits(address userAddress) external view returns(uint[] memory, uint[] memory) {
        uint length = participationsByAddress[userAddress].length;

        uint[] memory allUserClaimableMgn = new uint[](length);
        uint[] memory allUserClaimableDeposit = new uint[](length);

        for (uint i = 0; i < length; i++) {
            allUserClaimableMgn[i] = calculateClaimableMgn(participationsByAddress[userAddress][i]);
            allUserClaimableDeposit[i] = calculateClaimableDeposit(participationsByAddress[userAddress][i]);
        }
        return (allUserClaimableMgn, allUserClaimableDeposit);
    }

     
    
    function calculatePoolShares(uint amount) private view returns (uint) {
        if (totalDeposit == 0) {
            return amount;
        } else {
            return totalPoolShares.mul(amount) / totalDeposit;
        }
    }
    
    function isDepositTokenTurn() private view returns (bool) {
        return auctionCount % 2 == 0;
    }

    function calculateClaimableMgn(Participation memory participation) private view returns (uint) {
        if (totalPoolSharesCummulative == 0) {
            return 0;
        }
        uint duration = auctionCount - participation.startAuctionCount;
        return totalMgn.mul(participation.poolShares).mul(duration) / totalPoolSharesCummulative;
    }

    function calculateClaimableDeposit(Participation memory participation) private view returns (uint) {
        if (totalPoolShares == 0) {
            return 0;
        }
        return totalDeposit.mul(participation.poolShares) / totalPoolShares;
    }
}

 

pragma solidity ^0.5.0;

contract Coordinator {

    DxMgnPool public dxMgnPool1;
    DxMgnPool public dxMgnPool2;

    constructor (
        ERC20 _token1, 
        ERC20 _token2, 
        IDutchExchange _dx,
        uint _poolingTime
    ) public {
        dxMgnPool1 = new DxMgnPool(_token1, _token2, _dx, _poolingTime);
        dxMgnPool2 = new DxMgnPool(_token2, _token1, _dx, _poolingTime);
    }

    function participateInAuction() public {
        dxMgnPool1.participateInAuction();
        dxMgnPool2.participateInAuction();
    }

    function canParticipate() public returns (bool) {
        uint auctionIndex = dxMgnPool1.dx().getAuctionIndex(
            address(dxMgnPool1.depositToken()),
            address(dxMgnPool1.secondaryToken())
        );
         
        dxMgnPool1.checkForStateUpdate();
         
        return auctionIndex > dxMgnPool1.lastParticipatedAuctionIndex() && dxMgnPool1.currentState() == DxMgnPool.State.Pooling;
    }

    function withdrawMGNandDepositsFromBothPools() public {
        address(dxMgnPool1).delegatecall(abi.encodeWithSignature("withdrawDeposit()"));
        address(dxMgnPool1).delegatecall(abi.encodeWithSignature("withdrawMagnolia()"));

        address(dxMgnPool2).delegatecall(abi.encodeWithSignature("withdrawDeposit()"));
        address(dxMgnPool2).delegatecall(abi.encodeWithSignature("withdrawMagnolia()"));
    }
}
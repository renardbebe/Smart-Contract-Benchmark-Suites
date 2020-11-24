 

pragma solidity ^0.5.9;

interface DPlayCoinInterface {
	
	event Transfer(address indexed from, address indexed to, uint value);
	event Approval(address indexed owner, address indexed spender, uint value);
	
	function name() external view returns (string memory);
	function symbol() external view returns (string memory);
	function decimals() external view returns (uint8);
	
	function totalSupply() external view returns (uint);
	function balanceOf(address owner) external view returns (uint balance);
	function transfer(address to, uint value) external returns (bool success);
	function transferFrom(address from, address to, uint value) external returns (bool success);
	function approve(address spender, uint value) external returns (bool success);
	function allowance(address owner, address spender) external view returns (uint remaining);
	
	 
	 
	function getPower(address user) external view returns (uint power);
}

interface ERC20 {
	
	event Transfer(address indexed from, address indexed to, uint value);
	event Approval(address indexed owner, address indexed spender, uint value);
	
	function name() external view returns (string memory);
	function symbol() external view returns (string memory);
	function decimals() external view returns (uint8);
	
	function totalSupply() external view returns (uint);
	function balanceOf(address owner) external view returns (uint balance);
	function transfer(address to, uint value) external returns (bool success);
	function transferFrom(address from, address to, uint value) external returns (bool success);
	function approve(address spender, uint value) external returns (bool success);
	function allowance(address owner, address spender) external view returns (uint remaining);
}

interface ERC165 {
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

contract NetworkChecker {
	
	address constant private MAINNET_MILESTONE_ADDRESS = 0xa6e90A28F446D3639916959B6087F68D9B83fca9;
	address constant private KOVAN_MILESTONE_ADDRESS = 0x9a6Dc2a58256239500D96fb6f13D73b70C3d88f9;
	address constant private ROPSTEN_MILESTONE_ADDRESS = 0x212cC55dd760Ec5352185A922c61Ac41c8dDB197;
	address constant private RINKEBY_MILESTONE_ADDRESS = 0x54d1991a37cbA30E5371F83e8c2B1F762c7096c2;
	
	enum Network {
		Mainnet,
		Kovan,
		Ropsten,
		Rinkeby,
		Unknown
	}
	
	Network public network;
	
	 
	 
	function checkIsSmartContract(address addr) private view returns (bool) {
		uint32 size;
		assembly { size := extcodesize(addr) }
		return size > 0;
	}
	
	constructor() public {
		
		 
		 
		if (checkIsSmartContract(MAINNET_MILESTONE_ADDRESS) == true) {
			(bool success, ) = MAINNET_MILESTONE_ADDRESS.call(abi.encodeWithSignature("helloMainnet()"));
			if (success == true) {
				network = Network.Mainnet;
				return;
			}
		}
		
		 
		 
		if (checkIsSmartContract(KOVAN_MILESTONE_ADDRESS) == true) {
			(bool success, ) = KOVAN_MILESTONE_ADDRESS.call(abi.encodeWithSignature("helloKovan()"));
			if (success == true) {
				network = Network.Kovan;
				return;
			}
		}
		
		 
		 
		if (checkIsSmartContract(ROPSTEN_MILESTONE_ADDRESS) == true) {
			(bool success, ) = ROPSTEN_MILESTONE_ADDRESS.call(abi.encodeWithSignature("helloRopsten()"));
			if (success == true) {
				network = Network.Ropsten;
				return;
			}
		}
		
		 
		 
		if (checkIsSmartContract(RINKEBY_MILESTONE_ADDRESS) == true) {
			(bool success, ) = RINKEBY_MILESTONE_ADDRESS.call(abi.encodeWithSignature("helloRinkeby()"));
			if (success == true) {
				network = Network.Rinkeby;
				return;
			}
		}
		
		 
		 
		network = Network.Unknown;
	}
}

 
 
library SafeMath {
	
	function add(uint a, uint b) pure internal returns (uint c) {
		c = a + b;
		assert(c >= a);
		return c;
	}
	
	function sub(uint a, uint b) pure internal returns (uint c) {
		assert(b <= a);
		return a - b;
	}
	
	function mul(uint a, uint b) pure internal returns (uint c) {
		if (a == 0) {
			return 0;
		}
		c = a * b;
		assert(c / a == b);
		return c;
	}
	
	function div(uint a, uint b) pure internal returns (uint c) {
		return a / b;
	}
}

contract DPlayCoin is DPlayCoinInterface, ERC20, ERC165, NetworkChecker {
	using SafeMath for uint;
	
	 
	 
	string constant private NAME = "DPlay Coin";
	string constant private SYMBOL = "DC";
	uint8 constant private DECIMALS = 18;
	uint constant private TOTAL_SUPPLY = 10000000000 * (10 ** uint(DECIMALS));
	
	mapping(address => uint) private balances;
	mapping(address => mapping(address => uint)) private allowed;
	
	 
	 
	
	 
	 
	address public dplayStore;
	
	 
	 
	address public dplayTradingPost;
	
	constructor() NetworkChecker() public {
		
		balances[msg.sender] = TOTAL_SUPPLY;
		
		emit Transfer(address(0x0), msg.sender, TOTAL_SUPPLY);
	}
	
	 
	 
	function setDPlayStoreOnce(address addr) external {
		
		 
		require(dplayStore == address(0));
		
		dplayStore = addr;
	}
	
	 
	 
	function setDPlayTradingPostOnce(address addr) external {
		
		 
		 
		require(dplayTradingPost == address(0));
		
		dplayTradingPost = addr;
	}
	
	 
	 
	function checkAddressMisused(address target) internal view returns (bool) {
		return
			target == address(0) ||
			target == address(this);
	}
	
	 
	 
	function name() external view returns (string memory) {
		return NAME;
	}
	
	 
	 
	function symbol() external view returns (string memory) {
		return SYMBOL;
	}
	
	 
	 
	function decimals() external view returns (uint8) {
		return DECIMALS;
	}
	
	 
	 
	function totalSupply() external view returns (uint) {
		return TOTAL_SUPPLY;
	}
	
	 
	 
	function balanceOf(address user) external view returns (uint balance) {
		return balances[user];
	}
	
	 
	 
	function transfer(address to, uint amount) external returns (bool success) {
		
		 
		 
		require(checkAddressMisused(to) != true);
		
		require(amount <= balances[msg.sender]);
		
		balances[msg.sender] = balances[msg.sender].sub(amount);
		balances[to] = balances[to].add(amount);
		
		emit Transfer(msg.sender, to, amount);
		
		return true;
	}
	
	 
	 
	function approve(address spender, uint amount) external returns (bool success) {
		
		allowed[msg.sender][spender] = amount;
		
		emit Approval(msg.sender, spender, amount);
		
		return true;
	}
	
	 
	 
	function allowance(address user, address spender) external view returns (uint remaining) {
		
		if (
		 
		spender == dplayStore ||
		spender == dplayTradingPost) {
			return balances[user];
		}
		
		return allowed[user][spender];
	}
	
	 
	 
	function transferFrom(address from, address to, uint amount) external returns (bool success) {
		
		 
		 
		require(checkAddressMisused(to) != true);
		
		require(amount <= balances[from]);
		
		require(
			 
			msg.sender == dplayStore ||
			msg.sender == dplayTradingPost ||
			
			amount <= allowed[from][msg.sender]
		);
		
		balances[from] = balances[from].sub(amount);
		balances[to] = balances[to].add(amount);
		
		if (
			msg.sender != dplayStore &&
			msg.sender != dplayTradingPost
		) {
			allowed[from][msg.sender] = allowed[from][msg.sender].sub(amount);
		}
		
		emit Transfer(from, to, amount);
		
		return true;
	}
	
	 
	 
	function supportsInterface(bytes4 interfaceID) external view returns (bool) {
		return
			 
			interfaceID == this.supportsInterface.selector ||
			 
			interfaceID == 0x942e8b22 ||
			interfaceID == 0x36372b07;
	}
	
	 
	 
	function getPower(address user) external view returns (uint power) {
		return balances[user];
	}
	
	 
	 
	function createDCForTest(uint amount) external {
		if (network == Network.Mainnet) {
			revert();
		} else {
			balances[msg.sender] += amount;
		}
	}
}
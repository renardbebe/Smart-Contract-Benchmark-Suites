 

pragma solidity 0.4.24;

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

interface ERC20 {
	function transfer (address _beneficiary, uint256 _tokenAmount) external returns (bool);
	function transferFromICO(address _to, uint256 _value) external returns(bool);
	function balanceOf(address who) external view returns (uint256);
}

contract Ownable {
	address public owner;
	
	constructor() public {
		owner = msg.sender;
	}
	
	modifier onlyOwner() {
		require(msg.sender == owner);
		_;
	}
}

 
contract WhalesburgCrowdsale is Ownable {
	using SafeMath for uint256;
	
	ERC20 public token;
	
	address public constant multisig = 0x5dc5c66eb90dd8c4be285164ca9ea442faa1c2e8;
	address constant bounty = 0x96abf0420cffe408ba6bb16699f6748bef01b02b;
	address constant privateInvestors = 0x44eedeecc2a6f5f763a18e8876576b29a856d03a;
	address developers = 0x8e23cd7ce780e55ace7309b398336443b408c9d4;
	address constant founders = 0xd7dadf6149FF75f76f36423CAD1E24c81847E85d;
	
	uint256 public startICO = 1528041600;  
	uint256 public endICO = 1530633600;   

	uint256 constant privateSaleTokens = 46988857;
	uint256 constant foundersReserve = 10000000;
	uint256 constant developmentReserve = 20500000;
	uint256 constant bountyReserve = 3500000;

	uint256 public individualRoundCap = 1250000000000000000;

	uint256 public constant hardCap = 1365000067400000000000;  
	
	uint256 public investors;
	
	uint256 public constant buyPrice = 71800000000000;  
	
	bool public isFinalized = false;
	bool public distribute = false;
	
	uint256 public weisRaised;
	
	mapping (address => bool) public onChain;
	mapping (address => bool) whitelist;
	mapping (address => uint256) public moneySpent;
	
	address[] tokenHolders;
	
	event Finalized();
	event Authorized(address wlCandidate, uint256 timestamp);
	event Revoked(address wlCandidate, uint256 timestamp);
	
	constructor(ERC20 _token) public {
		require(_token != address(0));
		token = _token;
	}
	
	function setVestingAddress(address _newDevPool) public onlyOwner {
		developers = _newDevPool;
	}
	
	function distributionTokens() public onlyOwner {
		require(!distribute);
		token.transferFromICO(bounty, bountyReserve*1e18);
		token.transferFromICO(privateInvestors, privateSaleTokens*1e18);
		token.transferFromICO(developers, developmentReserve*1e18);
		token.transferFromICO(founders, foundersReserve*1e18);
		distribute = true;
	}
	
	 
	function authorize(address _beneficiary) public onlyOwner  {
		require(_beneficiary != address(0x0));
		require(!isWhitelisted(_beneficiary));
		whitelist[_beneficiary] = true;
		emit Authorized(_beneficiary, now);
	}
	
	function addManyAuthorizeToWhitelist(address[] _beneficiaries) public onlyOwner {
		for (uint256 i = 0; i < _beneficiaries.length; i++) {
			authorize(_beneficiaries[i]);
		}
	}
	
	function revoke(address _beneficiary) public  onlyOwner {
		whitelist[_beneficiary] = false;
		emit Revoked(_beneficiary, now);
	}
	
	function isWhitelisted(address who) public view returns(bool) {
		return whitelist[who];
	}
	
	function finalize() onlyOwner public {
		require(!isFinalized);
		require(now >= endICO || weisRaised >= hardCap);
		emit Finalized();
		isFinalized = true;
		token.transferFromICO(owner, token.balanceOf(this));
	}
	
	 
	
	function () public payable {
		if(isWhitelisted(msg.sender)) {
			require(now >= startICO && now < endICO);
			currentSaleLimit();
			moneySpent[msg.sender] = moneySpent[msg.sender].add(msg.value);
			require(moneySpent[msg.sender] <= individualRoundCap);
			sell(msg.sender, msg.value);
			weisRaised = weisRaised.add(msg.value);
			require(weisRaised <= hardCap);
			multisig.transfer(msg.value);
		} else {
			revert();
		}
	}
	
	function currentSaleLimit() private {
		if(now >= startICO && now < startICO+7200) {
			
			individualRoundCap = 1250000000000000000;  
		}
		else if(now >= startICO+7200 && now < startICO+14400) {
			
			individualRoundCap = 3750000000000000000;  
		}
		else if(now >= startICO+14400 && now < endICO) {
			
			individualRoundCap = hardCap;  
		}
		else {
			revert();
		}
	}
	
	function sell(address _investor, uint256 amount) private {
		uint256 _amount = amount.mul(1e18).div(buyPrice);
		token.transferFromICO(_investor, _amount);
		if (!onChain[msg.sender]) {
			tokenHolders.push(msg.sender);
			onChain[msg.sender] = true;
		}
		investors = tokenHolders.length;
	}
}
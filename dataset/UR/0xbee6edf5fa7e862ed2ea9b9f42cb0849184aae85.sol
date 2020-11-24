 

pragma solidity 0.5.9;

 
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
contract ETORoles {
	using Roles for Roles.Role;

	constructor() internal {
		_addAuditWriter(msg.sender);
		_addAssetSeizer(msg.sender);
		_addKycProvider(msg.sender);
		_addUserManager(msg.sender);
		_addOwner(msg.sender);
	}

	 
	event AuditWriterAdded(address indexed account);
	event AuditWriterRemoved(address indexed account);

	Roles.Role private _auditWriters;

	modifier onlyAuditWriter() {
		require(isAuditWriter(msg.sender), "Sender is not auditWriter");
		_;
	}

	function isAuditWriter(address account) public view returns (bool) {
		return _auditWriters.has(account);
	}

	function addAuditWriter(address account) public onlyUserManager {
		_addAuditWriter(account);
	}

	function renounceAuditWriter() public {
		_removeAuditWriter(msg.sender);
	}

	function _addAuditWriter(address account) internal {
		_auditWriters.add(account);
		emit AuditWriterAdded(account);
	}

	function _removeAuditWriter(address account) internal {
		_auditWriters.remove(account);
		emit AuditWriterRemoved(account);
	}

	 
	event KycProviderAdded(address indexed account);
	event KycProviderRemoved(address indexed account);

	Roles.Role private _kycProviders;

	modifier onlyKycProvider() {
		require(isKycProvider(msg.sender), "Sender is not kycProvider");
		_;
	}

	function isKycProvider(address account) public view returns (bool) {
		return _kycProviders.has(account);
	}

	function addKycProvider(address account) public onlyUserManager {
		_addKycProvider(account);
	}

	function renounceKycProvider() public {
		_removeKycProvider(msg.sender);
	}

	function _addKycProvider(address account) internal {
		_kycProviders.add(account);
		emit KycProviderAdded(account);
	}

	function _removeKycProvider(address account) internal {
		_kycProviders.remove(account);
		emit KycProviderRemoved(account);
	}

	 
	event AssetSeizerAdded(address indexed account);
	event AssetSeizerRemoved(address indexed account);

	Roles.Role private _assetSeizers;

	modifier onlyAssetSeizer() {
		require(isAssetSeizer(msg.sender), "Sender is not assetSeizer");
		_;
	}

	function isAssetSeizer(address account) public view returns (bool) {
		return _assetSeizers.has(account);
	}

	function addAssetSeizer(address account) public onlyUserManager {
		_addAssetSeizer(account);
	}

	function renounceAssetSeizer() public {
		_removeAssetSeizer(msg.sender);
	}

	function _addAssetSeizer(address account) internal {
		_assetSeizers.add(account);
		emit AssetSeizerAdded(account);
	}

	function _removeAssetSeizer(address account) internal {
		_assetSeizers.remove(account);
		emit AssetSeizerRemoved(account);
	}

	 
	event UserManagerAdded(address indexed account);
	event UserManagerRemoved(address indexed account);

	Roles.Role private _userManagers;

	modifier onlyUserManager() {
		require(isUserManager(msg.sender), "Sender is not UserManager");
		_;
	}

	function isUserManager(address account) public view returns (bool) {
		return _userManagers.has(account);
	}

	function addUserManager(address account) public onlyUserManager {
		_addUserManager(account);
	}

	function renounceUserManager() public {
		_removeUserManager(msg.sender);
	}

	function _addUserManager(address account) internal {
		_userManagers.add(account);
		emit UserManagerAdded(account);
	}

	function _removeUserManager(address account) internal {
		_userManagers.remove(account);
		emit UserManagerRemoved(account);
	}

	 
	event OwnerAdded(address indexed account);
	event OwnerRemoved(address indexed account);

	Roles.Role private _owners;

	modifier onlyOwner() {
		require(isOwner(msg.sender), "Sender is not owner");
		_;
	}

	function isOwner(address account) public view returns (bool) {
		return _owners.has(account);
	}

	function addOwner(address account) public onlyUserManager {
		_addOwner(account);
	}

	function renounceOwner() public {
		_removeOwner(msg.sender);
	}

	function _addOwner(address account) internal {
		_owners.add(account);
		emit OwnerAdded(account);
	}

	function _removeOwner(address account) internal {
		_owners.remove(account);
		emit OwnerRemoved(account);
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
		_approve(msg.sender, spender, value);
		return true;
	}

	 
	function transferFrom(address from, address to, uint256 value) public returns (bool) {
		_transfer(from, to, value);
		_approve(from, msg.sender, _allowed[from][msg.sender].sub(value));
		return true;
	}

	 
	function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
		_approve(msg.sender, spender, _allowed[msg.sender][spender].add(addedValue));
		return true;
	}

	 
	function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
		_approve(msg.sender, spender, _allowed[msg.sender][spender].sub(subtractedValue));
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

	 
	function _approve(address owner, address spender, uint256 value) internal {
		require(spender != address(0));
		require(owner != address(0));

		_allowed[owner][spender] = value;
		emit Approval(owner, spender, value);
	}

	 
	function _burnFrom(address account, uint256 value) internal {
		_burn(account, value);
		_approve(account, msg.sender, _allowed[account][msg.sender].sub(value));
	}
}

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

 
contract ERC20Mintable is ERC20, MinterRole {
	 
	function mint(address to, uint256 value) public onlyMinter returns (bool) {
		_mint(to, value);
		return true;
	}
}


contract ETOToken is ERC20Mintable, ETORoles {
	 
	mapping(address => bool) public investorWhitelist;
	address[] public investorWhitelistLUT;

	 
	string public constant name = "Blockstate STO Token";
	string public constant symbol = "BKN";
	uint8 public constant decimals = 0;

	 
	string public ITIN;

	 
	mapping(uint256 => uint256) public auditHashes;

	 
	mapping(uint256 => uint256) public documentHashes;

	 
	 
	event AssetsSeized(address indexed seizee, uint256 indexed amount);
	event AssetsUnseized(address indexed seizee, uint256 indexed amount);
	event InvestorWhitelisted(address indexed investor);
	event InvestorBlacklisted(address indexed investor);
	event DividendPayout(address indexed receiver, uint256 indexed amount);
	event TokensGenerated(uint256 indexed amount);
	event OwnershipUpdated(address indexed newOwner);

	 
	constructor() public {
		ITIN = "CCF5-T3UQ-2";
	}

	 
	event ITINUpdated(string newValue);

	 
	function setITIN(string memory newValue) public onlyOwner {
		ITIN = newValue;
		emit ITINUpdated(newValue);
	}
	
	 
	function approveFor(address seizee, uint256 seizableAmount) public onlyAssetSeizer {
	    _approve(seizee, msg.sender, seizableAmount);
	}
	
	 
	function seizeAssets(address seizee, uint256 seizableAmount) public onlyAssetSeizer {
		transferFrom(seizee, msg.sender, seizableAmount);
		emit AssetsSeized(seizee, seizableAmount);
	}

	function releaseAssets(address seizee, uint256 seizedAmount) public onlyAssetSeizer {
		require(balanceOf(msg.sender) >= seizedAmount, "AssetSeizer has insufficient funds");
		transfer(seizee, seizedAmount);
		emit AssetsUnseized(seizee, seizedAmount);
	}

	 
	function whitelistInvestor(address investor) public onlyKycProvider {
		require(investorWhitelist[investor] == false, "Investor already whitelisted");
		investorWhitelist[investor] = true;
		investorWhitelistLUT.push(investor);
		emit InvestorWhitelisted(investor);
	}

	 
	function blacklistInvestor(address investor) public onlyKycProvider {
		require(investorWhitelist[investor] == true, "Investor not on whitelist");
		investorWhitelist[investor] = false;
		uint256 arrayLen = investorWhitelistLUT.length;
		for (uint256 i = 0; i < arrayLen; i++) {
			if (investorWhitelistLUT[i] == investor) {
				investorWhitelistLUT[i] = investorWhitelistLUT[investorWhitelistLUT.length - 1];
				delete investorWhitelistLUT[investorWhitelistLUT.length - 1];
				break;
			}
		}
		emit InvestorBlacklisted(investor);
	}

	 
	function transfer(address to, uint256 value) public returns (bool) {
		require(investorWhitelist[to] == true, "Investor not whitelisted");
		return super.transfer(to, value);
	}

	function transferFrom(address from, address to, uint256 value) public returns (bool) {
		require(investorWhitelist[to] == true, "Investor not whitelisted");
		return super.transferFrom(from, to, value);
	}

	function approve(address spender, uint256 value) public returns (bool) {
		require(investorWhitelist[spender] == true, "Investor not whitelisted");
		return super.approve(spender, value);
	}

	 
	function generateTokens(uint256 amount, address assetReceiver) public onlyMinter {
		_mint(assetReceiver, amount);
	}

	function initiateDividendPayments(uint amount) onlyOwner public returns (bool) {
		uint dividendPerToken = amount / totalSupply();
		uint256 arrayLen = investorWhitelistLUT.length;
		for (uint256 i = 0; i < arrayLen; i++) {
			address currentInvestor = investorWhitelistLUT[i];
			uint256 currentInvestorShares = balanceOf(currentInvestor);
			uint256 currentInvestorPayout = dividendPerToken * currentInvestorShares;
			emit DividendPayout(currentInvestor, currentInvestorPayout);
		}
		return true;
	}

	function addAuditHash(uint256 hash) public onlyAuditWriter {
		auditHashes[now] = hash;
	}

	function getAuditHash(uint256 timestamp) public view returns (uint256) {
		return auditHashes[timestamp];
	}

	function addDocumentHash(uint256 hash) public onlyOwner {
		documentHashes[now] = hash;
	}

	function getDocumentHash(uint256 timestamp) public view returns (uint256) {
		return documentHashes[timestamp];
	}
}

contract ETOVotes is ETOToken {
	event VoteOpen(uint256 _id, uint _deadline);
	event VoteFinished(uint256 _id, bool _result);

	 
	mapping (uint256 => Vote) private votes;

	struct Voter {
		address id;
		bool vote;
	}

	struct Vote {
		uint256 deadline;
		Voter[] voters;
		mapping(address => uint) votersIndex;
		uint256 documentHash;
	}

	constructor() public {}

	function vote(uint256 _id, bool _vote) public {
		 
		require (votes[_id].deadline > 0, "Vote not available");
		require(now <= votes[_id].deadline, "Vote deadline exceeded");
		if (didCastVote(_id)) {
			uint256 currentIndex = votes[_id].votersIndex[msg.sender];
			Voter memory newVoter = Voter(msg.sender, _vote);
			votes[_id].voters[currentIndex - 1] = newVoter;
		} else {
			votes[_id].voters.push(Voter(msg.sender, _vote));
			votes[_id].votersIndex[msg.sender] = votes[_id].voters.length;
		}
	}

	function getVoteDocumentHash(uint256 _id) public view returns (uint256) {
		return votes[_id].documentHash;
	}

	function openVote(uint256 _id, uint256 documentHash, uint256 voteDuration) onlyOwner external {
		require(votes[_id].deadline == 0, "Vote already ongoing");
		votes[_id].deadline = now + (voteDuration * 1 seconds);
		votes[_id].documentHash = documentHash;
		emit VoteOpen(_id, votes[_id].deadline);
	}

	 
	function triggerDecision(uint256 _id) external {
		require(votes[_id].deadline > 0, "Vote not available");
		require(now > votes[_id].deadline, "Vote deadline not reached");
		 
		votes[_id].deadline = 0;
		bool result = (getCurrentPositives(_id) > getCurrentNegatives(_id));
		emit VoteFinished(_id, result);
	}

	 
	function isVoteOpen(uint256 _id) external view returns (bool) {
		return (votes[_id].deadline > 0) && (now <= votes[_id].deadline);
	}

	 
	function didCastVote(uint256 _id) public view returns (bool) {
		return (votes[_id].votersIndex[msg.sender] > 0);
	}

	function getOwnVote(uint256 _id) public view returns (bool) {
		uint voterId = votes[_id].votersIndex[msg.sender];
		return votes[_id].voters[voterId-1].vote;
	}

	function getCurrentPositives(uint256 _id) public view returns (uint256) {
		uint adder = 0;
		uint256 arrayLen = votes[_id].voters.length;
		for (uint256 i = 0; i < arrayLen; i++) {
			if (votes[_id].voters[i].vote == true) {
				adder += balanceOf(votes[_id].voters[i].id);
			}
		}
		return adder;
	}

	function getCurrentNegatives(uint256 _id) public view returns (uint256) {
		uint adder = 0;
		uint256 arrayLen = votes[_id].voters.length;
		for (uint256 i = 0; i < arrayLen; i++) {
			if (votes[_id].voters[i].vote == false) {
				adder += balanceOf(votes[_id].voters[i].id);
			}
		}
		return adder;
	}
}
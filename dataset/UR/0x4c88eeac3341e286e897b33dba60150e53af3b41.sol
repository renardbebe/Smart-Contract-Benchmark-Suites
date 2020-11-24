 

pragma solidity ^0.5.13;

interface RNGOracle {
	function createSeries(uint256[] calldata _newSeries) external returns (uint256 seriesIndex);
	function seriesRequest(uint256 _seriesIndex, uint256 _runs, bytes32 _seed, uint256 _callbackGasLimit) external returns (bytes32 queryId);
	function getSeries(uint256 _seriesIndex) external view returns (uint256 sum, uint256 maxRuns, uint256[] memory values, uint256[] memory cumulativeSum, uint256[] memory resolutions);
	function queryWallet(address _user) external view returns (uint256);
}

interface DDN {
	function transfer(address _to, uint256 _tokens) external returns (bool);
	function balanceOf(address _user) external view returns (uint256);
	function dividendsOf(address _user) external view returns (uint256);
	function buy() external payable returns (uint256);
	function reinvest() external returns (uint256);
}

contract Pooling {

	uint256 constant private FLOAT_SCALAR = 2**64;

	struct User {
		uint256 shares;
		int256 scaledPayout;
		bytes32 seed;
	}

	struct BetInfo {
		address user;
		uint256 betAmount;
	}

	struct Info {
		uint256 seriesIndex;
		uint256 totalShares;
		uint256 scaledCumulativeDDN;
		mapping(address => User) users;
		mapping(bytes32 => BetInfo) betInfo;
		RNGOracle oracle;
		DDN ddn;
	}
	Info private info;


	event BetPlaced(address indexed user, bytes32 queryId);
	event BetResolved(address indexed user, bytes32 indexed queryId, uint256 betAmount, uint256 shares);
	event BetFailed(address indexed user, bytes32 indexed queryId, uint256 betAmount);
	event Withdraw(address indexed user, uint256 amount);


	constructor(address _oracleAddress, address _DDN_address) public {
		info.oracle = RNGOracle(_oracleAddress);
		info.ddn = DDN(_DDN_address);
		uint256[] memory _chances = new uint256[](10);
		_chances[0] = 1;
		_chances[1] = 2;
		_chances[2] = 3;
		_chances[3] = 5;
		_chances[4] = 7;
		_chances[5] = 11;
		_chances[6] = 13;
		_chances[7] = 17;
		_chances[8] = 19;
		_chances[9] = 23;
		info.seriesIndex = info.oracle.createSeries(_chances);
	}

	function pool() external payable {
		require(msg.value > 0);
		reinvestPool();
		_placeBet(msg.sender, info.ddn.buy.value(msg.value)());
	}

	function tokenCallback(address _from, uint256 _tokens, bytes calldata) external returns (bool) {
		require(msg.sender == address(info.ddn));
		require(_tokens > 0);
		reinvestPool();
		_placeBet(_from, _tokens);
		return true;
	}

	function withdraw() external returns (uint256) {
		uint256 _dividends = dividendsOf(msg.sender);
		require(_dividends >= 0);
		info.users[msg.sender].scaledPayout += int256(_dividends * FLOAT_SCALAR);
		info.ddn.transfer(msg.sender, _dividends);
		emit Withdraw(msg.sender, _dividends);
		return _dividends;
	}

	function setSeed(bytes32 _seed) public {
		info.users[msg.sender].seed = _seed;
	}

	function reinvestPool() public {
		if (info.ddn.dividendsOf(address(this)) > 0) {
			info.scaledCumulativeDDN += info.ddn.reinvest() * FLOAT_SCALAR / info.totalShares;
		}
	}

	function seriesCallback(bytes32 _queryId, uint256 _resolution, uint256[] calldata) external {
		require(msg.sender == address(info.oracle));
		BetInfo memory _betInfo = info.betInfo[_queryId];
		uint256 _shares = _betInfo.betAmount * _resolution / FLOAT_SCALAR;
		info.totalShares += _shares;
		info.users[_betInfo.user].shares += _shares;
		info.users[_betInfo.user].scaledPayout += int256(info.scaledCumulativeDDN * _shares);
		info.scaledCumulativeDDN += _betInfo.betAmount * FLOAT_SCALAR / info.totalShares / 2;
		emit BetResolved(_betInfo.user, _queryId, _betInfo.betAmount, _shares);
	}

	function queryFailed(bytes32 _queryId) external {
		require(msg.sender == address(info.oracle));
		BetInfo memory _betInfo = info.betInfo[_queryId];
		info.ddn.transfer(_betInfo.user, _betInfo.betAmount);
		emit BetFailed(_betInfo.user, _queryId, _betInfo.betAmount);
	}


	function pooledDDN() public view returns (uint256) {
		return info.ddn.balanceOf(address(this));
	}

	function totalShares() public view returns (uint256) {
		return info.totalShares;
	}

	function sharesOf(address _user) public view returns (uint256) {
		return info.users[_user].shares;
	}

	function dividendsOf(address _user) public view returns (uint256) {
		return uint256(int256(info.scaledCumulativeDDN * sharesOf(_user)) - info.users[_user].scaledPayout) / FLOAT_SCALAR;
	}

	function allInfoFor(address _user) public view returns (uint256 totalPooled, uint256 totalPoolShares, uint256 userQueryWallet, uint256 userBalance, uint256 userShares, uint256 userDividends) {
		return (pooledDDN(), totalShares(), info.oracle.queryWallet(_user), info.ddn.balanceOf(_user), sharesOf(_user), dividendsOf(_user));
	}

	function getPayouts() public view returns (uint256 sum, uint256[] memory chances, uint256[] memory cumulativeSum, uint256[] memory scaledPayouts) {
		(sum, , chances, cumulativeSum, scaledPayouts) = info.oracle.getSeries(info.seriesIndex);
		for (uint256 i = 0; i < scaledPayouts.length; i++) {
			scaledPayouts[i] = 1e18 * scaledPayouts[i] / FLOAT_SCALAR;
		}
	}


	function _placeBet(address _user, uint256 _betAmount) internal {
		bytes32 _queryId = info.oracle.seriesRequest(info.seriesIndex, 1, info.users[_user].seed, info.users[_user].shares == 0 ? 300000 : 200000);
		BetInfo memory _betInfo = BetInfo({
			user: _user,
			betAmount: _betAmount
		});
		info.betInfo[_queryId] = _betInfo;
		emit BetPlaced(_user, _queryId);
	}
}
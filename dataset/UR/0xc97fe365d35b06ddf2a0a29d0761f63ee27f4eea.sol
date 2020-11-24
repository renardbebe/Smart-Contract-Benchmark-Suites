 

pragma solidity ^ 0.4.24;

 
 
library SafeMath {

	 
	function mul(uint256 a, uint256 b) internal pure returns(uint256) {
		 
		 
		 
		if (a == 0) {
			return 0;
		}

		uint256 c = a * b;
		require(c / a == b);

		return c;
	}

	 
	function div(uint256 a, uint256 b) internal pure returns(uint256) {
		require(b > 0);  
		uint256 c = a / b;
		 

		return c;
	}

	 
	function sub(uint256 a, uint256 b) internal pure returns(uint256) {
		require(b <= a);
		uint256 c = a - b;

		return c;
	}

	 
	function add(uint256 a, uint256 b) internal pure returns(uint256) {
		uint256 c = a + b;
		require(c >= a);

		return c;
	}

	 
	function mod(uint256 a, uint256 b) internal pure returns(uint256) {
		require(b != 0);
		return a % b;
	}
}

 
contract BaseAccessControl {

	address public ceo;
	address public coo;
	address public cfo;

	constructor() public {
		ceo = msg.sender;
		coo = msg.sender;
		cfo = msg.sender;
	}

	 
	modifier onlyCEO() {
		require(msg.sender == ceo, "CEO Only");
		_;
	}
	modifier onlyCOO() {
		require(msg.sender == coo, "COO Only");
		_;
	}
	modifier onlyCFO() {
		require(msg.sender == cfo, "CFO Only");
		_;
	}
	modifier onlyCLevel() {
		require(msg.sender == ceo || msg.sender == coo || msg.sender == cfo, "CLevel Only");
		_;
	}
	 

	 
	modifier required(address addr) {
		require(addr != address(0), "Address is required.");
		_;
	}
	modifier onlyHuman(address addr) {
		uint256 codeLength;
		assembly {
			codeLength: = extcodesize(addr)
		}
		require(codeLength == 0, "Humans only");
		_;
	}
	modifier onlyContract(address addr) {
		uint256 codeLength;
		assembly {
			codeLength: = extcodesize(addr)
		}
		require(codeLength > 0, "Contracts only");
		_;
	}
	 

	 
	function setCEO(address addr) external onlyCEO() required(addr) onlyHuman(addr) {
		ceo = addr;
	}

	function setCOO(address addr) external onlyCEO() required(addr) onlyHuman(addr) {
		coo = addr;
	}

	function setCFO(address addr) external onlyCEO() required(addr) onlyHuman(addr) {
		cfo = addr;
	}
	 
}

 
contract MinerAccessControl is BaseAccessControl {

	address public companyWallet;

	bool public paused = false;

	 
	modifier whenNotPaused() {
		require(!paused, "Paused");
		_;
	}
	modifier whenPaused() {
		require(paused, "Running");
		_;
	}
	 

	 
	function setCompanyWallet(address newCompanyWallet) external onlyCEO() required(newCompanyWallet) {
		companyWallet = newCompanyWallet;
	}

	function paused() public onlyCLevel() whenNotPaused() {
		paused = true;
	}

	function unpaused() external onlyCEO() whenPaused() {
		paused = false;
	}
	 
}

 
interface B1MPToken {
	function mintByTokenId(address to, uint256 tokenId) external returns(bool);
}

 
interface B1MP {
	function _global() external view returns(uint256 revenue, uint256 g_positionAmount, uint256 earlierPayoffPerPosition, uint256 totalRevenue);
	function _userAddrBook(uint256 index) external view returns(address addr);
	function _users(address addr) external view returns(uint256 id, uint256 positionAmount, uint256 earlierPayoffMask, uint256 lastRefId);
	function _invitations(address addr) external view returns(uint256 invitationAmount, uint256 invitationPayoff);
	function _positionBook(uint256 index1, uint256 index2) external view returns(uint256 minute);
	function _positionOnwers(uint256 minute) external view returns(address addr);
	function totalUsers() external view returns(uint256);
	function getUserPositionIds(address addr) external view returns(uint256[]);
}

 
contract NewB1MP is MinerAccessControl {

	using SafeMath for * ;

	 
	struct Config {
		uint256 start;  
		uint256 end;  
		uint256 price;  
		uint256 withdrawFee;  
		uint8 earlierPayoffRate;  
		uint8 invitationPayoffRate;  
		uint256 finalPrizeThreshold;  
		uint8[10] finalPrizeRates;  
	}

	struct Global {
		uint256 revenue;  
		uint256 positionAmount;  
		uint256 earlierPayoffPerPosition;  
		uint256 totalRevenue;  
	}

	struct User {
		uint256 id;  
		uint256 positionAmount;  
		uint256 earlierPayoffMask;  
		uint256 lastRefId;  
		uint256[] positionIds;  
	}

	struct Invitation {
		uint256 amount;  
		uint256 payoff;  
	}

	B1MP public oldB1MPContract;  
	B1MPToken public tokenContract;  
	Config public _config;  
	Global public _global;  
	address[] public _userAddrBook;  
	mapping(address => User) public _users;  
	mapping(address => Invitation) public _invitations;  

	uint256[2][] public _positionBook;  
	mapping(uint256 => address) public _positionOwners;  
	mapping(uint256 => address) public _positionMiners;  

	uint256 public _prizePool;  
	uint256 public _prizePoolWithdrawn;  
	bool public _isPrizeActivated;  

	address[] public _winnerPurchaseListForAddr;  
	uint256[] public _winnerPurchaseListForPositionAmount;  
	mapping(address => uint256) public _winnerPositionAmounts;  
	uint256 public _currentWinnerIndex;  
	uint256 private _winnerCounter;  
	uint256 public _winnerTotalPositionAmount;  

	bool private _isReady;  
	uint256 private _userMigrationCounter;  

	 
	modifier paymentLimit(uint256 ethVal) {
		require(ethVal > 0, "Too poor.");
		require(ethVal <= 100000 ether, "Too rich.");
		_;
	}
	modifier buyLimit(uint256 ethVal) {
		require(ethVal >= _config.price, 'Not enough.');
		_;
	}
	modifier withdrawLimit(uint256 ethVal) {
		require(ethVal == _config.withdrawFee, 'Not enough.');
		_;
	}
	modifier whenNotEnded() {
		require(_config.end == 0 || now < _config.end, 'Ended.');
		_;
	}
	modifier whenEnded() {
		require(_config.end != 0 && now >= _config.end, 'Not ended.');
		_;
	}
	modifier whenPrepare() {
		require(_config.end == 0, 'Started.');
		require(_isReady == false, 'Ready.');
		_;
	}
	modifier whenReady() {
		require(_isReady == true, 'Not ready.');
		_;
	}
	 

	 
	constructor(address tokenAddr, address oldB1MPContractAddr) onlyContract(tokenAddr) onlyContract(oldB1MPContractAddr) public {
		 
		oldB1MPContract = B1MP(oldB1MPContractAddr);
		_isReady = false;
		_userMigrationCounter = 0;
		 
		tokenContract = B1MPToken(tokenAddr);
		_config = Config(1541993890, 0, 90 finney, 5 finney, 10, 20, 20000 ether, [
			5, 6, 7, 8, 10, 13, 15, 17, 20, 25
		]);
		_global = Global(0, 0, 0, 0);

		 
		_currentWinnerIndex = 0;
		_isPrizeActivated = false;
	}

	function migrateUserData(uint256 n) whenPrepare() onlyCEO() public {
		 
		uint256 userAmount = oldB1MPContract.totalUsers();
		_userAddrBook.length = userAmount;
		 
		uint256 lastMigrationNumber = _userMigrationCounter;
		for (_userMigrationCounter; _userMigrationCounter < userAmount && _userMigrationCounter < lastMigrationNumber + n; _userMigrationCounter++) {
			 
			address userAddr = oldB1MPContract._userAddrBook(_userMigrationCounter);
			 
			_userAddrBook[_userMigrationCounter] = userAddr;
			 
			(uint256 id, uint256 positionAmount, uint256 earlierPayoffMask, uint256 lastRefId) = oldB1MPContract._users(userAddr);
			uint256[] memory positionIds = oldB1MPContract.getUserPositionIds(userAddr);
			 
			_users[userAddr] = User(id, positionAmount, earlierPayoffMask, lastRefId, positionIds);
			 
			(uint256 invitationAmount, uint256 invitationPayoff) = oldB1MPContract._invitations(userAddr);
			 
			_invitations[userAddr] = Invitation(invitationAmount, invitationPayoff);
			 
			for (uint256 i = 0; i < positionIds.length; i++) {
				uint256 pid = positionIds[i];
				if (pid > 0) {
					if (pid > _positionBook.length) {
						_positionBook.length = pid;
					}
					uint256 pIndex = pid.sub(1);
					_positionBook[pIndex] = [oldB1MPContract._positionBook(pIndex, 0), oldB1MPContract._positionBook(pIndex, 1)];
					_positionOwners[pIndex] = userAddr;
				}
			}
		}
	}

	function migrateGlobalData() whenPrepare() onlyCEO() public {
		 
		(uint256 revenue, uint256 g_positionAmount, uint256 earlierPayoffPerPosition, uint256 totalRevenue) = oldB1MPContract._global();
		_global = Global(revenue, g_positionAmount, earlierPayoffPerPosition, totalRevenue);
	}

	function depositeForMigration() whenPrepare() onlyCEO() public payable {
		require(_userMigrationCounter == oldB1MPContract.totalUsers(), 'Continue to migrate.');
		require(msg.value >= address(oldB1MPContract).balance, 'Not enough.');
		 
		 
		 
		_global.revenue = _global.revenue.add(msg.value.sub(address(oldB1MPContract).balance));
		_isReady = true;
	}

	function () whenReady() whenNotEnded() whenNotPaused() onlyHuman(msg.sender) paymentLimit(msg.value) buyLimit(msg.value) public payable {
		buyCore(msg.sender, msg.value, 0);
	}

	function buy(uint256 refId) whenReady() whenNotEnded() whenNotPaused() onlyHuman(msg.sender) paymentLimit(msg.value) buyLimit(msg.value) public payable {
		buyCore(msg.sender, msg.value, refId);
	}

	function buyCore(address addr_, uint256 revenue_, uint256 refId_) private {
		 
		uint256 _positionAmount_ = (revenue_).div(_config.price);  
		uint256 _realCost_ = _positionAmount_.mul(_config.price);
		uint256 _invitationPayoffPart_ = _realCost_.mul(_config.invitationPayoffRate).div(100);
		uint256 _earlierPayoffPart_ = _realCost_.mul(_config.earlierPayoffRate).div(100);
		revenue_ = revenue_.sub(_invitationPayoffPart_).sub(_earlierPayoffPart_);
		uint256 _earlierPayoffMask_ = 0;

		 
		if (_users[addr_].id == 0) {
			_userAddrBook.push(addr_);  
			_users[addr_].id = _userAddrBook.length;  
		}

		 
		if (_global.positionAmount > 0) {
			uint256 eppp = _earlierPayoffPart_.div(_global.positionAmount);
			_global.earlierPayoffPerPosition = eppp.add(_global.earlierPayoffPerPosition);  
			revenue_ = revenue_.add(_earlierPayoffPart_.sub(eppp.mul(_global.positionAmount)));  
		} else {
			revenue_ = revenue_.add(_earlierPayoffPart_);  
		}
		 
		_global.positionAmount = _positionAmount_.add(_global.positionAmount);
		 
		_earlierPayoffMask_ = _positionAmount_.mul(_global.earlierPayoffPerPosition);

		 
		if (refId_ <= 0 || refId_ > _userAddrBook.length || refId_ == _users[addr_].id) {  
			refId_ = _users[addr_].lastRefId;
		} else if (refId_ != _users[addr_].lastRefId) {
			_users[addr_].lastRefId = refId_;
		}
		 
		if (refId_ != 0) {
			address refAddr = _userAddrBook[refId_.sub(1)];
			 
			_invitations[refAddr].amount = (1).add(_invitations[refAddr].amount);  
			_invitations[refAddr].payoff = _invitationPayoffPart_.add(_invitations[refAddr].payoff);  
		} else {
			revenue_ = revenue_.add(_invitationPayoffPart_);  
		}

		 
		_users[addr_].positionAmount = _positionAmount_.add(_users[addr_].positionAmount);
		_users[addr_].earlierPayoffMask = _earlierPayoffMask_.add(_users[addr_].earlierPayoffMask);
		 
		_positionBook.push([_global.positionAmount.sub(_positionAmount_).add(1), _global.positionAmount]);
		_positionOwners[_positionBook.length] = addr_;
		_users[addr_].positionIds.push(_positionBook.length);

		 
		_global.revenue = revenue_.add(_global.revenue);
		_global.totalRevenue = revenue_.add(_global.totalRevenue);

		 
		if (_global.totalRevenue > _config.finalPrizeThreshold) {
			uint256 maxWinnerAmount = countWinners();  
			 
			if (maxWinnerAmount > 0) {
				if (maxWinnerAmount > _winnerPurchaseListForAddr.length) {
					_winnerPurchaseListForAddr.length = maxWinnerAmount;
					_winnerPurchaseListForPositionAmount.length = maxWinnerAmount;
				}
				 
				address lwAddr = _winnerPurchaseListForAddr[_currentWinnerIndex];
				if (lwAddr != address(0)) {  
					 
					_winnerTotalPositionAmount = _winnerTotalPositionAmount.sub(_winnerPurchaseListForPositionAmount[_currentWinnerIndex]);
					 
					_winnerPositionAmounts[lwAddr] = _winnerPositionAmounts[lwAddr].sub(_winnerPurchaseListForPositionAmount[_currentWinnerIndex]);
					 
					if (_winnerPositionAmounts[lwAddr] == 0) {
						 
						_winnerCounter = _winnerCounter.sub(1);
						delete _winnerPositionAmounts[lwAddr];
					}
				}
				 
				 
				if (_winnerPositionAmounts[msg.sender] == 0) {
					 
					_winnerCounter = _winnerCounter.add(1);
				}
				 
				_winnerTotalPositionAmount = _positionAmount_.add(_winnerTotalPositionAmount);
				 
				_winnerPositionAmounts[msg.sender] = _positionAmount_.add(_winnerPositionAmounts[msg.sender]);
				 
				_winnerPurchaseListForAddr[_currentWinnerIndex] = msg.sender;
				_winnerPurchaseListForPositionAmount[_currentWinnerIndex] = _positionAmount_;
				 
				_currentWinnerIndex = _currentWinnerIndex.add(1);
				if (_currentWinnerIndex >= maxWinnerAmount) {  
					_currentWinnerIndex = 0;  
				}
			}
		}

		 
		_config.end = (now).add(2 days);  
	}

	function redeemOptionContract(uint256 positionId, uint256 minute) whenReady() whenNotPaused() onlyHuman(msg.sender) public {
		require(_users[msg.sender].id != 0, 'Unauthorized.');
		require(positionId <= _positionBook.length && positionId > 0, 'Position Id error.');
		require(_positionOwners[positionId] == msg.sender, 'No permission.');
		require(minute >= _positionBook[positionId - 1][0] && minute <= _positionBook[positionId - 1][1], 'Wrong interval.');
		require(_positionMiners[minute] == address(0), 'Minted.');

		 
		_positionMiners[minute] = msg.sender;

		 
		require(tokenContract.mintByTokenId(msg.sender, minute), "Mining Error.");
	}

	function activateFinalPrize() whenReady() whenEnded() whenNotPaused() onlyCOO() public {
		require(_isPrizeActivated == false, 'Activated.');
		 
		if (_global.totalRevenue > _config.finalPrizeThreshold) {
			 
			uint256 selectedfinalPrizeRatesIndex = _winnerCounter.mul(_winnerTotalPositionAmount).mul(_currentWinnerIndex).mod(_config.finalPrizeRates.length);
			_prizePool = _global.totalRevenue.mul(_config.finalPrizeRates[selectedfinalPrizeRatesIndex]).div(100);
			 
			_global.revenue = _global.revenue.sub(_prizePool);
		}
		 
		_isPrizeActivated = true;
	}

	function withdraw() whenReady() whenNotPaused() onlyHuman(msg.sender) withdrawLimit(msg.value) public payable {
		_global.revenue = _global.revenue.add(msg.value);  

		 
		uint256 amount = _invitations[msg.sender].payoff;
		_invitations[msg.sender].payoff = 0;  

		 
		uint256 ep = (_global.earlierPayoffPerPosition).mul(_users[msg.sender].positionAmount);
		amount = amount.add(ep.sub(_users[msg.sender].earlierPayoffMask));
		_users[msg.sender].earlierPayoffMask = ep;  

		 
		if (_isPrizeActivated == true && _winnerPositionAmounts[msg.sender] > 0 &&
			_winnerTotalPositionAmount > 0 && _winnerCounter > 0 && _prizePool > _prizePoolWithdrawn) {
			 
			uint256 prizeAmount = prize(msg.sender);
			 
			amount = amount.add(prizeAmount);
			 
			_prizePoolWithdrawn = _prizePoolWithdrawn.add(prizeAmount);
			 
			clearPrize(msg.sender);
			_winnerCounter = _winnerCounter.sub(1);
		}

		 
		(msg.sender).transfer(amount);
	}

	function withdrawByCFO(uint256 amount) whenReady() whenNotPaused() onlyCFO() required(companyWallet) public {
		require(amount > 0, 'Payoff too samll.');
		uint256 max = _global.revenue;
		if (_isPrizeActivated == false) {  
			 
			max = max.sub(_global.totalRevenue.mul(_config.finalPrizeRates[_config.finalPrizeRates.length.sub(1)]).div(100));
		}
		require(amount <= max, 'Payoff too big.');

		 
		_global.revenue = _global.revenue.sub(amount);

		 
		companyWallet.transfer(amount);
	}

	function withdrawByCFO(address addr) whenReady() whenNotPaused() onlyCFO() onlyContract(addr) required(companyWallet) public {
		 
		require(IERC20(addr).transfer(companyWallet, IERC20(addr).balanceOf(this)));
	}

	function collectPrizePoolDust() whenReady() whenNotPaused() onlyCOO() public {
		 
		require(_isPrizeActivated == true, 'Not activited.');
		 
		if (_winnerCounter == 0 || now > _config.end.add(180 days)) {
			_global.revenue = _global.revenue.add(_prizePool.sub(_prizePoolWithdrawn));
			_prizePoolWithdrawn = _prizePool;
		}
	}

	function totalUsers() public view returns(uint256) {
		return _userAddrBook.length;
	}

	function getUserAddress(uint256 id) public view returns(address userAddrRet) {
		if (id <= _userAddrBook.length && id > 0) {
			userAddrRet = _userAddrBook[id.sub(1)];
		}
	}

	function getUserPositionIds(address addr) public view returns(uint256[]) {
		return _users[addr].positionIds;
	}

	function countPositions() public view returns(uint256) {
		return _positionBook.length;
	}

	function getPositions(uint256 id) public view returns(uint256[2] positionsRet) {
		if (id <= _positionBook.length && id > 0) {
			positionsRet = _positionBook[id.sub(1)];
		}
	}

	function prize(address addr) public view returns(uint256) {
		if (_winnerTotalPositionAmount == 0 || _prizePool == 0) {
			return 0;
		}
		return _winnerPositionAmounts[addr].mul(_prizePool).div(_winnerTotalPositionAmount);
	}

	function clearPrize(address addr) private {
		delete _winnerPositionAmounts[addr];
	}

	function countWinners() public view returns(uint256) {
		return _userAddrBook.length.div(100);
	}

	function allWinners() public view returns(address[]) {
		return _winnerPurchaseListForAddr;
	}
}


 
interface IERC20 {
	function totalSupply() external view returns(uint256);

	function balanceOf(address who) external view returns(uint256);

	function allowance(address owner, address spender)
	external view returns(uint256);

	function transfer(address to, uint256 value) external returns(bool);

	function approve(address spender, uint256 value)
	external returns(bool);

	function transferFrom(address from, address to, uint256 value)
	external returns(bool);

	event Transfer(
		address indexed from,
		address indexed to,
		uint256 value
	);

	event Approval(
		address indexed owner,
		address indexed spender,
		uint256 value
	);
}
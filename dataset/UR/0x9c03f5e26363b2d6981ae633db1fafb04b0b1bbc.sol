 

pragma solidity ^0.4.24;

 
interface AdvertisingInterface {
	function incrementBetCounter() external returns (bool);
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



interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }

contract TokenERC20 {
	 
	string public name;
	string public symbol;
	uint8 public decimals = 18;
	 
	uint256 public totalSupply;

	 
	mapping (address => uint256) public balanceOf;
	mapping (address => mapping (address => uint256)) public allowance;

	 
	event Transfer(address indexed from, address indexed to, uint256 value);

	 
	event Approval(address indexed _owner, address indexed _spender, uint256 _value);

	 
	event Burn(address indexed from, uint256 value);

	 
	constructor(
		uint256 initialSupply,
		string tokenName,
		string tokenSymbol
	) public {
		totalSupply = initialSupply * 10 ** uint256(decimals);   
		balanceOf[msg.sender] = totalSupply;                 
		name = tokenName;                                    
		symbol = tokenSymbol;                                
	}

	 
	function _transfer(address _from, address _to, uint _value) internal {
		 
		require(_to != 0x0);
		 
		require(balanceOf[_from] >= _value);
		 
		require(balanceOf[_to] + _value > balanceOf[_to]);
		 
		uint previousBalances = balanceOf[_from] + balanceOf[_to];
		 
		balanceOf[_from] -= _value;
		 
		balanceOf[_to] += _value;
		emit Transfer(_from, _to, _value);
		 
		assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
	}

	 
	function transfer(address _to, uint256 _value) public returns (bool success) {
		_transfer(msg.sender, _to, _value);
		return true;
	}

	 
	function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
		require(_value <= allowance[_from][msg.sender]);      
		allowance[_from][msg.sender] -= _value;
		_transfer(_from, _to, _value);
		return true;
	}

	 
	function approve(address _spender, uint256 _value) public returns (bool success) {
		allowance[msg.sender][_spender] = _value;
		emit Approval(msg.sender, _spender, _value);
		return true;
	}

	 
	function approveAndCall(address _spender, uint256 _value, bytes _extraData)
		public
		returns (bool success) {
		tokenRecipient spender = tokenRecipient(_spender);
		if (approve(_spender, _value)) {
			spender.receiveApproval(msg.sender, _value, this, _extraData);
			return true;
		}
	}

	 
	function burn(uint256 _value) public returns (bool success) {
		require(balanceOf[msg.sender] >= _value);    
		balanceOf[msg.sender] -= _value;             
		totalSupply -= _value;                       
		emit Burn(msg.sender, _value);
		return true;
	}

	 
	function burnFrom(address _from, uint256 _value) public returns (bool success) {
		require(balanceOf[_from] >= _value);                 
		require(_value <= allowance[_from][msg.sender]);     
		balanceOf[_from] -= _value;                          
		allowance[_from][msg.sender] -= _value;              
		totalSupply -= _value;                               
		emit Burn(_from, _value);
		return true;
	}
}

contract developed {
	address public developer;

	 
	constructor() public {
		developer = msg.sender;
	}

	 
	modifier onlyDeveloper {
		require(msg.sender == developer);
		_;
	}

	 
	function changeDeveloper(address _developer) public onlyDeveloper {
		developer = _developer;
	}

	 
	function withdrawToken(address tokenContractAddress) public onlyDeveloper {
		TokenERC20 _token = TokenERC20(tokenContractAddress);
		if (_token.balanceOf(this) > 0) {
			_token.transfer(developer, _token.balanceOf(this));
		}
	}
}



 
contract Advertising is developed, AdvertisingInterface {
	using SafeMath for uint256;
	address private incrementer;

	bool public paused;
	bool public contractKilled;

	uint256 public numCreatives;
	uint256 public numCreativeTypes;
	uint256 public maxCountPerCreativeType;
	uint256 public earnedBalance;

	struct Creative {
		bytes32 creativeId;
		address advertiser;
		uint256 creativeTypeId;        
		string name;
		uint256 weiBudget;
		uint256 weiPerBet;
		uint256 betCounter;
		int256 position;
		string url;
		string imageUrl;
		bool approved;
		uint256 createdOn;
	}

	struct CreativeType {
		string name;
		uint256 width;
		uint256 height;
		 
		uint256 position;
		bool active;
	}

	mapping (bytes32 => Creative) public creatives;
	mapping (bytes32 => uint256) private creativeIdLookup;
	mapping (uint256 => CreativeType) public creativeTypes;
	mapping (address => uint256) public advertiserPendingWithdrawals;
	mapping (uint256 => bytes32[]) public pendingCreativePosition;
	mapping (uint256 => bytes32[]) public approvedCreativePosition;

	 
	event LogAddCreativeType(uint256 indexed creativeTypeId, string name, uint256 width, uint256 height, uint256 position);

	 
	event LogSetActiveCreativeType(uint256 creativeTypeId, bool active);

	 
	event LogApproveCreative(bytes32 indexed creativeId, address indexed advertiser, uint256 indexed creativeTypeId, int256 position);

	 
	event LogEscapeHatch();

	 
	event LogCreateCreative(bytes32 indexed creativeId, address indexed advertiser, uint256 indexed creativeTypeId, string name, uint256 weiBudget, uint256 weiPerBet, int256 position);

	 
	event LogRefundCreative(bytes32 indexed creativeId, address indexed advertiser, uint256 refundAmount, uint256 creativeStatus, uint256 refundStatus);

	 
	event LogWithdrawBalance(address indexed advertiser, uint256 withdrawAmount, uint256 status);

	 
	event LogIncrementBetCounter(bytes32 indexed creativeId, address indexed advertiser, uint256 numBets);

	 
	constructor(address _incrementer) public {
		devSetMaxCountPerCreativeType(10);
		devSetIncrementer(_incrementer);
	}

	 
	modifier contractIsAlive {
		require(contractKilled == false);
		_;
	}

	 
	modifier isActive {
		require(paused == false);
		_;
	}

	 
	modifier creativeIsValid(uint256 creativeTypeId, string name, uint256 weiBudget, uint256 weiPerBet, string url, string imageUrl) {
		require (creativeTypes[creativeTypeId].active == true &&
			 bytes(name).length > 0 &&
			 weiBudget > 0 &&
			 weiPerBet > 0 &&
			 weiBudget >= weiPerBet &&
			 bytes(url).length > 0 &&
			 bytes(imageUrl).length > 0 &&
			 (pendingCreativePosition[creativeTypeId].length < maxCountPerCreativeType ||
			  (pendingCreativePosition[creativeTypeId].length == maxCountPerCreativeType && weiPerBet > creatives[pendingCreativePosition[creativeTypeId][maxCountPerCreativeType-1]].weiPerBet)
			 )
		);
		_;
	}

	 
	modifier onlyIncrementer {
		require (msg.sender == incrementer);
		_;
	}

	 
	 
	 
	 
	function devSetIncrementer(address _incrementer) public onlyDeveloper {
		incrementer = _incrementer;
	}

	 
	function devGetIncrementer() public onlyDeveloper constant returns (address) {
		return incrementer;
	}

	 
	function devSetMaxCountPerCreativeType(uint256 _maxCountPerCreativeType) public onlyDeveloper {
		require (_maxCountPerCreativeType > 0);
		maxCountPerCreativeType = _maxCountPerCreativeType;
	}

	 
	function devAddCreativeType(string name, uint256 width, uint256 height, uint256 position) public onlyDeveloper {
		require (width > 0 && height > 0 && position > 0);

		 
		numCreativeTypes++;

		CreativeType storage _creativeType = creativeTypes[numCreativeTypes];

		 
		_creativeType.name = name;
		_creativeType.width = width;
		_creativeType.height = height;
		_creativeType.position = position;
		_creativeType.active = true;

		emit LogAddCreativeType(numCreativeTypes, _creativeType.name, _creativeType.width, _creativeType.height, _creativeType.position);
	}

	 
	function devSetActiveCreativeType(uint256 creativeTypeId, bool active) public onlyDeveloper {
		creativeTypes[creativeTypeId].active = active;
		emit LogSetActiveCreativeType(creativeTypeId, active);
	}

	 
	function devApproveCreative(bytes32 creativeId) public onlyDeveloper {
		Creative storage _creative = creatives[creativeId];
		require (_creative.approved == false && _creative.position > -1 && _creative.createdOn > 0);
		_creative.approved = true;
		_removePending(creativeId);
		_insertSortApprovedCreative(_creative.creativeTypeId, _creative.creativeId);
	}

	 
	function devWithdrawEarnedBalance() public onlyDeveloper returns (bool) {
		require (earnedBalance > 0);
		require (address(this).balance >= earnedBalance);
		uint256 withdrawAmount = earnedBalance;
		earnedBalance = 0;
		if (!developer.send(withdrawAmount)) {
			earnedBalance = withdrawAmount;
			return false;
		} else {
			return true;
		}
	}

	 
	function devEndCreative(bytes32 creativeId) public onlyDeveloper {
		_endCreative(creativeId);
	}

	 
	function devSetPaused(bool _paused) public onlyDeveloper {
		paused = _paused;
	}

	 
	function escapeHatch() public onlyDeveloper contractIsAlive returns (bool) {
		contractKilled = true;
		if (earnedBalance > 0) {
			uint256 withdrawAmount = earnedBalance;
			earnedBalance = 0;
			if (!developer.send(withdrawAmount)) {
				earnedBalance = withdrawAmount;
			}
		}

		if (numCreativeTypes > 0) {
			for (uint256 i=1; i <= numCreativeTypes; i++) {
				 
				uint256 creativeCount = pendingCreativePosition[i].length;
				if (creativeCount > 0) {
					for (uint256 j=0; j < creativeCount; j++) {
						Creative memory _creative = creatives[pendingCreativePosition[i][j]];

						 
						advertiserPendingWithdrawals[_creative.advertiser] = advertiserPendingWithdrawals[_creative.advertiser].add(_creative.weiBudget);
					}
				}

				 
				creativeCount = approvedCreativePosition[i].length;
				if (creativeCount > 0) {
					for (j=0; j < creativeCount; j++) {
						_creative = creatives[approvedCreativePosition[i][j]];
						uint256 refundAmount = _creative.weiBudget.sub(_creative.betCounter.mul(_creative.weiPerBet));
						 
						advertiserPendingWithdrawals[_creative.advertiser] = advertiserPendingWithdrawals[_creative.advertiser].add(refundAmount);
					}
				}
			}
		}

		emit LogEscapeHatch();
		return true;
	}

	 
	 
	 
	function incrementBetCounter() public onlyIncrementer contractIsAlive isActive returns (bool) {
		if (numCreativeTypes > 0) {
			for (uint256 i=1; i <= numCreativeTypes; i++) {
				CreativeType memory _creativeType = creativeTypes[i];
				uint256 creativeCount = approvedCreativePosition[i].length;
				if (_creativeType.active == false || creativeCount == 0) {
					continue;
				}

				Creative storage _creative = creatives[approvedCreativePosition[i][0]];
				_creative.betCounter++;
				emit LogIncrementBetCounter(_creative.creativeId, _creative.advertiser, _creative.betCounter);

				uint256 totalSpent = _creative.weiPerBet.mul(_creative.betCounter);
				if (totalSpent > _creative.weiBudget) {
					earnedBalance = earnedBalance.add(_creative.weiBudget.sub(_creative.weiPerBet.mul(_creative.betCounter.sub(1))));
					_removeApproved(_creative.creativeId);
				} else {
					earnedBalance = earnedBalance.add(_creative.weiPerBet);
				}
			}
		}
		return true;
	}

	 
	 
	 

	 
	function createCreative(uint256 creativeTypeId, string name, uint256 weiPerBet, string url, string imageUrl)
		public
		payable
		contractIsAlive
		isActive
		creativeIsValid(creativeTypeId, name, msg.value, weiPerBet, url, imageUrl) {
		 
		numCreatives++;

		 
		bytes32 creativeId = keccak256(abi.encodePacked(this, msg.sender, numCreatives));

		Creative storage _creative = creatives[creativeId];

		 
		_creative.creativeId = creativeId;
		_creative.advertiser = msg.sender;
		_creative.creativeTypeId = creativeTypeId;
		_creative.name = name;
		_creative.weiBudget = msg.value;
		_creative.weiPerBet = weiPerBet;
		_creative.url = url;
		_creative.imageUrl = imageUrl;
		_creative.createdOn = now;

		 
		_insertSortPendingCreative(creativeTypeId, creativeId);
	}

	 
	function endCreative(bytes32 creativeId) public
		contractIsAlive
		isActive {
		Creative storage _creative = creatives[creativeId];
		require (_creative.advertiser == msg.sender);
		_endCreative(creativeId);
	}

	 
	function withdrawPendingTransactions() public {
		uint256 withdrawAmount = advertiserPendingWithdrawals[msg.sender];
		require (withdrawAmount > 0);
		require (address(this).balance >= withdrawAmount);

		advertiserPendingWithdrawals[msg.sender] = 0;

		 
		if (msg.sender.send(withdrawAmount)) {
			emit LogWithdrawBalance(msg.sender, withdrawAmount, 1);
		} else {
			 
			advertiserPendingWithdrawals[msg.sender] = withdrawAmount;
			emit LogWithdrawBalance(msg.sender, withdrawAmount, 0);
		}
	}

	 
	 
	 

	 
	function _insertSortPendingCreative(uint256 creativeTypeId, bytes32 creativeId) internal {
		pendingCreativePosition[creativeTypeId].push(creativeId);

		uint256 pendingCount = pendingCreativePosition[creativeTypeId].length;
		bytes32[] memory copyArray = new bytes32[](pendingCount);

		for (uint256 i=0; i<pendingCount; i++) {
			copyArray[i] = pendingCreativePosition[creativeTypeId][i];
		}

		uint256 value;
		bytes32 key;
		for (i = 1; i < copyArray.length; i++) {
			key = copyArray[i];
			value = creatives[copyArray[i]].weiPerBet;
			for (uint256 j=i; j > 0 && creatives[copyArray[j-1]].weiPerBet < value; j--) {
				copyArray[j] = copyArray[j-1];
			}
			copyArray[j] = key;
		}

		for (i=0; i<pendingCount; i++) {
			pendingCreativePosition[creativeTypeId][i] = copyArray[i];
			creatives[copyArray[i]].position = int(i);
		}

		Creative memory _creative = creatives[creativeId];
		emit LogCreateCreative(_creative.creativeId, _creative.advertiser, _creative.creativeTypeId, _creative.name, _creative.weiBudget, _creative.weiPerBet, _creative.position);

		 
		if (pendingCount > maxCountPerCreativeType) {
			bytes32 removeCreativeId = pendingCreativePosition[creativeTypeId][pendingCount-1];
			creatives[removeCreativeId].position = -1;
			delete pendingCreativePosition[creativeTypeId][pendingCount-1];
			pendingCreativePosition[creativeTypeId].length--;
			_refundPending(removeCreativeId);
		}
	}

	 
	function _refundPending(bytes32 creativeId) internal {
		Creative memory _creative = creatives[creativeId];
		require (address(this).balance >= _creative.weiBudget);
		require (_creative.position == -1);
		if (!_creative.advertiser.send(_creative.weiBudget)) {
			emit LogRefundCreative(_creative.creativeId, _creative.advertiser, _creative.weiBudget, 0, 0);

			 
			advertiserPendingWithdrawals[_creative.advertiser] = advertiserPendingWithdrawals[_creative.advertiser].add(_creative.weiBudget);
		} else {
			emit LogRefundCreative(_creative.creativeId, _creative.advertiser, _creative.weiBudget, 0, 1);
		}
	}

	 
	function _insertSortApprovedCreative(uint256 creativeTypeId, bytes32 creativeId) internal {
		approvedCreativePosition[creativeTypeId].push(creativeId);

		uint256 approvedCount = approvedCreativePosition[creativeTypeId].length;
		bytes32[] memory copyArray = new bytes32[](approvedCount);

		for (uint256 i=0; i<approvedCount; i++) {
			copyArray[i] = approvedCreativePosition[creativeTypeId][i];
		}

		uint256 value;
		bytes32 key;
		for (i = 1; i < copyArray.length; i++) {
			key = copyArray[i];
			value = creatives[copyArray[i]].weiPerBet;
			for (uint256 j=i; j > 0 && creatives[copyArray[j-1]].weiPerBet < value; j--) {
				copyArray[j] = copyArray[j-1];
			}
			copyArray[j] = key;
		}

		for (i=0; i<approvedCount; i++) {
			approvedCreativePosition[creativeTypeId][i] = copyArray[i];
			creatives[copyArray[i]].position = int(i);
		}

		Creative memory _creative = creatives[creativeId];
		emit LogApproveCreative(_creative.creativeId, _creative.advertiser, _creative.creativeTypeId, _creative.position);

		 
		if (approvedCount > maxCountPerCreativeType) {
			bytes32 removeCreativeId = approvedCreativePosition[creativeTypeId][approvedCount-1];
			creatives[removeCreativeId].position = -1;
			delete approvedCreativePosition[creativeTypeId][approvedCount-1];
			approvedCreativePosition[creativeTypeId].length--;
			_refundApproved(removeCreativeId);
		}
	}

	 
	function _refundApproved(bytes32 creativeId) internal {
		Creative memory _creative = creatives[creativeId];
		uint256 refundAmount = _creative.weiBudget.sub(_creative.betCounter.mul(_creative.weiPerBet));
		require (address(this).balance >= refundAmount);
		require (_creative.position == -1);
		if (!_creative.advertiser.send(refundAmount)) {
			emit LogRefundCreative(_creative.creativeId, _creative.advertiser, refundAmount, 1, 0);

			 
			advertiserPendingWithdrawals[_creative.advertiser] = advertiserPendingWithdrawals[_creative.advertiser].add(refundAmount);
		} else {
			emit LogRefundCreative(_creative.creativeId, _creative.advertiser, refundAmount, 1, 1);
		}
	}

	 
	function _endCreative(bytes32 creativeId) internal {
		Creative storage _creative = creatives[creativeId];
		require (_creative.position > -1 && _creative.createdOn > 0);

		if (_creative.approved == false) {
			_removePending(creativeId);
			_refundPending(creativeId);
		} else {
			_removeApproved(creativeId);
			_refundApproved(creativeId);
		}
	}

	 
	function _removePending(bytes32 creativeId) internal {
		Creative storage _creative = creatives[creativeId];
		uint256 pendingCount = pendingCreativePosition[_creative.creativeTypeId].length;

		if (_creative.position >= int256(pendingCount)) return;

		for (uint256 i = uint256(_creative.position); i < pendingCount-1; i++){
			pendingCreativePosition[_creative.creativeTypeId][i] = pendingCreativePosition[_creative.creativeTypeId][i+1];
			creatives[pendingCreativePosition[_creative.creativeTypeId][i]].position = int256(i);
		}
		_creative.position = -1;
		delete pendingCreativePosition[_creative.creativeTypeId][pendingCount-1];
		pendingCreativePosition[_creative.creativeTypeId].length--;
	}

	 
	function _removeApproved(bytes32 creativeId) internal {
		Creative storage _creative = creatives[creativeId];
		uint256 approvedCount = approvedCreativePosition[_creative.creativeTypeId].length;

		if (_creative.position >= int256(approvedCount)) return;

		for (uint256 i = uint256(_creative.position); i < approvedCount-1; i++){
			approvedCreativePosition[_creative.creativeTypeId][i] = approvedCreativePosition[_creative.creativeTypeId][i+1];
			creatives[approvedCreativePosition[_creative.creativeTypeId][i]].position = int256(i);
		}
		_creative.position = -1;
		delete approvedCreativePosition[_creative.creativeTypeId][approvedCount-1];
		approvedCreativePosition[_creative.creativeTypeId].length--;
	}
}
 

pragma solidity 0.4.19;

 
contract Ownable {
	address public owner;

	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

	 
	function Ownable() public {
		require(msg.sender != address(0));

		owner = msg.sender;
	}


	 
	modifier onlyOwner() {
		require(msg.sender == owner);
		_;
	}

	 
	function transferOwnership(address newOwner) public onlyOwner {
		require(newOwner != address(0));
		OwnershipTransferred(owner, newOwner);
		owner = newOwner;
	}

}

contract EthernalBridge is Ownable {

	 
	event Buy(
		uint indexed id,
		address owner,
		uint x,
		uint y,
		uint sizeSkin,
		bytes16 names,
		bytes32 message
	);

	 

	 
	uint constant MEDIUM_TYPE = 1001;
	uint constant PREMIUM_TYPE = 2001;

	 
	uint public maxBridgeHeight = 24;  
	uint public maxBridgeWidth = 400;  

	 
	uint public smallPrice = 3 finney;
	uint public mediumPrice = 7 finney;
	uint public bigPrice = 14 finney;

	 
	uint8 public mediumMod = 2;
	uint8 public premiumMod = 3;

	 
	mapping (uint => uint) public grid;


	 
	 
	address public withdrawWallet;

	struct Lock {
		address owner;

		uint32 x;
		uint16 y;

		 
		uint32 sizeSkin;

		bytes16 names;
		bytes32 message;
		uint time;

	}

	 
	Lock[] public locks;

	function () public payable { }

	function EthernalBridge() public {
		require(msg.sender != address(0));

		withdrawWallet = msg.sender;
	}

	 
	 
	function setWithdrawWallet(address _address) external onlyOwner {
		withdrawWallet = _address;
	}

	 
	 
	 
	function setSmallPrice(uint _price) external onlyOwner {
		smallPrice = _price;
	}

	 
	 
	 
	function setMediumPrice(uint _price) external onlyOwner {
		mediumPrice = _price;
	}

	 
	 
	 
	function setBigPrice(uint _price) external onlyOwner {
		bigPrice = _price;
	}

	 
	 
	function setBridgeHeight(uint _height) external onlyOwner {
		maxBridgeHeight = _height;
	}

	 
	 
	function setBridgeWidth(uint _width) external onlyOwner {
		maxBridgeWidth = _width;
	}

	 
	function withdraw() external onlyOwner {
		require(withdrawWallet != address(0));

		withdrawWallet.transfer(this.balance);
	}

	 
	function getLocksLength() external view returns (uint) {
		return locks.length;
	}

	 
	 
	function getLockById(uint id) external view returns (uint, uint, uint, uint, bytes16, bytes32, address) {
		return (
			locks[id].x,
			locks[id].y,
			locks[id].sizeSkin,
			locks[id].time,
			locks[id].names,
			locks[id].message,
			locks[id].owner
		);
	}


	 
	 
	 
	function buy(
		uint32 _x,
		uint16 _y,
		uint32 _sizeSkin,
		bytes16 _names,
		bytes32 _message
	)
		external
		payable
		returns (uint)
	{

		_checks(_x, _y, _sizeSkin);

		uint id = locks.push(
			Lock(msg.sender, _x, _y, _sizeSkin, _names, _message, block.timestamp)
		) - 1;

		 
		Buy(id, msg.sender, _x, _y, _sizeSkin, _names, _message);

		return id;
	}


	function _checks(uint _x, uint _y, uint _sizeSkin) private {

		uint _size = _sizeSkin % 10;  
		uint _skin = (_sizeSkin - _size) / 10;

		 
		require(_size == 1 || _size == 2 || _size == 3);

		require(maxBridgeHeight >= (_y + _size) && maxBridgeWidth >= (_x + _size));

		require(msg.value >= calculateCost(_size, _skin));

		 
		_checkGrid(_x, _y, _size);
	}

	 
	 
	 
	function calculateCost(uint _size, uint _skin) public view returns (uint cost) {
		 

		if(_size == 2)
			cost = mediumPrice;
		else if(_size == 3)
			cost = bigPrice;
		else
			cost = smallPrice;

		 
		if(_skin >= PREMIUM_TYPE)
			cost = cost * premiumMod;
		else if(_skin >= MEDIUM_TYPE)
			cost = cost * mediumMod;

		return cost;
	}


	 
	 
	 
	 
	function _checkGrid(uint _x, uint _y, uint _size) public {

		for(uint i = 0; i < _size; i++) {

			uint row = grid[_x + i];

			for(uint j = 0; j < _size; j++) {

				 
				if((row >> (_y + j)) & uint(1) == uint(1)) {
					 
					revert();
				}

				 
				row = row | (uint(1) << (_y + j));
			}

			grid[_x + i] = row;
		}
	}

}
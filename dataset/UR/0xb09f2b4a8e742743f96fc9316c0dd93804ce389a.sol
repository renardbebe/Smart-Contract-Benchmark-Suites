 

 
 
 

 
 

pragma solidity ^0.5.11;

interface BCF {
	function transfer(address _to, uint256 _tokens) external returns (bool);
	function dividendsOf(address _customer) external view returns (uint256);
	function balanceOf(address _customer) external view returns (uint256);
	function buy(address _ref) external payable returns (uint256);
	function reinvest() external;
}

contract BlueChipCards {

	uint256 constant private BLOCKS_PER_DAY = 5760;

	struct Card {
		address owner;
		uint80 lastBlock;
		uint16 currentLevel;
		uint80 basePrice;
		uint80 cooldown;
		uint80 shares;
	}

	struct Info {
		uint256 totalShares;
		mapping(address => int256) scaledPayout;
		uint256 cumulativeBCF;
		Card[] cards;
		BCF bcf;
	}
	Info private info;


	event Purchase(uint256 indexed cardIndex, address indexed buyer, uint256 ethereumPaid, uint256 tokensReceived);
	event Withdraw(address indexed withdrawer, uint256 tokens);


	constructor(address _BCF_address) public {
		info.bcf = BCF(_BCF_address);
		_createCards();
	}

	function buy(uint256 _index) public payable {
		require(_index < info.cards.length);
		Card storage _card = info.cards[_index];
		uint256 _price;
		uint256 _level;
		(_price, _level) = _cardPrice(_index);
		require(msg.value >= _price);

		_reinvest();
		address _this = address(this);
		uint256 _balance = info.bcf.balanceOf(_this);
		info.bcf.buy.value(_price)(address(0x0));
		uint256 _bcfPurchased = info.bcf.balanceOf(_this) - _balance;
		if (_card.owner != address(this)) {
			info.bcf.transfer(_card.owner, _bcfPurchased * 4 / 5);  
		}
		info.cumulativeBCF += _bcfPurchased / 6;  
		 

		info.scaledPayout[_card.owner] -= int256(info.cumulativeBCF * _card.shares);
		info.scaledPayout[msg.sender] += int256(info.cumulativeBCF * _card.shares);

		_card.owner = msg.sender;
		_card.lastBlock = uint80(block.number);
		_card.currentLevel = uint16(_level + 1);

		emit Purchase(_index, msg.sender, _price, _bcfPurchased);

		if (msg.value > _price) {
			msg.sender.transfer(msg.value - _price);
		}
	}

	function withdraw() public {
		_reinvest();
		uint256 _withdrawable = withdrawableOf(msg.sender);
		if (_withdrawable > 0) {
			info.scaledPayout[msg.sender] += int256(_withdrawable * info.totalShares);
			info.bcf.transfer(msg.sender, _withdrawable);
			emit Withdraw(msg.sender, _withdrawable);
		}
	}

	function convertDust() public {
		info.bcf.buy.value(address(this).balance)(address(0x0));
	}

	function () external payable {
		require(msg.sender == address(info.bcf));
	}


	function cardInfo(uint256 _index) public view returns (address owner, uint256 currentPrice, uint256 currentLevel, uint256 cooldown, uint256 nextCooldown, uint256 shares) {
		require(_index < info.cards.length);
		Card memory _card = info.cards[_index];
		uint256 _price;
		uint256 _level;
		(_price, _level) = _cardPrice(_index);
		uint256 _nextCooldown = _card.cooldown - ((block.number - _card.lastBlock) % _card.cooldown);
		return (_card.owner, _price, _level, _card.cooldown, _nextCooldown, _card.shares);
	}

	function allCardsInfo() public view returns (address[] memory owners, uint256[] memory currentPrices, uint256[] memory currentLevels, uint256[] memory cooldowns, uint256[] memory nextCooldowns, uint256[] memory shares) {
		uint256 _length = info.cards.length;
		owners = new address[](_length);
		currentPrices = new uint256[](_length);
		currentLevels = new uint256[](_length);
		cooldowns = new uint256[](_length);
		nextCooldowns = new uint256[](_length);
		shares = new uint256[](_length);
		for (uint256 i = 0; i < _length; i++) {
			(owners[i], currentPrices[i], currentLevels[i], cooldowns[i], nextCooldowns[i], shares[i]) = cardInfo(i);
		}
	}

	function sharesOf(address _owner) public view returns (uint256) {
		uint256 _shares = 0;
		for (uint256 i = 0; i < info.cards.length; i++) {
			Card memory _card = info.cards[i];
			if (_card.owner == _owner) {
				_shares += _card.shares;
			}
		}
		return _shares;
	}

	function withdrawableOf(address _owner) public view returns (uint256) {
		return uint256(int256(info.cumulativeBCF * sharesOf(_owner)) - info.scaledPayout[_owner]) / info.totalShares;
	}


	function _createCards() internal {
		_createCard(2.4 ether,   24 * BLOCKS_PER_DAY,      24);
		_createCard(0.023 ether, 23 * BLOCKS_PER_DAY / 24, 23);
		_createCard(0.222 ether, 15 * BLOCKS_PER_DAY,      22);
		_createCard(0.142 ether, 7 * BLOCKS_PER_DAY,       21);
		_createCard(0.012 ether, 10 * BLOCKS_PER_DAY,      20);
		_createCard(0.195 ether, 5 * BLOCKS_PER_DAY,       19);
		_createCard(0.018 ether, 2 * BLOCKS_PER_DAY,       18);
		_createCard(1.7 ether,   17 * BLOCKS_PER_DAY,      17);
		_createCard(0.096 ether, 9 * BLOCKS_PER_DAY,       16);
		_createCard(0.15 ether,  15 * BLOCKS_PER_DAY / 24, 15);
		_createCard(0.141 ether, BLOCKS_PER_DAY,           14);
		_createCard(0.321 ether, 3 * BLOCKS_PER_DAY,       13);
		_createCard(0.124 ether, 4 * BLOCKS_PER_DAY,       12);
		_createCard(0.011 ether, 11 * BLOCKS_PER_DAY / 24, 11);
		_createCard(10 ether,    50 * BLOCKS_PER_DAY,      10);
		_createCard(0.009 ether, 42 * BLOCKS_PER_DAY / 24,  9);
		_createCard(0.008 ether, 25 * BLOCKS_PER_DAY / 24,  8);
		_createCard(0.007 ether, 27 * BLOCKS_PER_DAY / 24,  7);
		_createCard(0.006 ether, 36 * BLOCKS_PER_DAY / 24,  6);
		_createCard(0.5 ether,   20 * BLOCKS_PER_DAY,       5);
		_createCard(0.004 ether, 8 * BLOCKS_PER_DAY / 24,   4);
		_createCard(0.003 ether, 9 * BLOCKS_PER_DAY / 24,   3);
		_createCard(0.002 ether, 4 * BLOCKS_PER_DAY / 24,   2);
		_createCard(0.001 ether, 1 * BLOCKS_PER_DAY / 24,   1);

		uint256 _totalShares = 0;
		for (uint256 i = 0; i < info.cards.length; i++) {
			_totalShares += info.cards[i].shares;
		}
		info.totalShares = _totalShares;
	}

	function _createCard(uint256 _basePrice, uint256 _cooldown, uint256 _shares) internal {
		Card memory _newCard = Card({
			owner: info.cards.length % 2 == 0 ? msg.sender : address(this),
			lastBlock: uint80(block.number),
			currentLevel: 0,
			basePrice: uint80(_basePrice),
			cooldown: uint80(_cooldown),
			shares: uint80(_shares)
		});
		info.cards.push(_newCard);
	}

	function _reinvest() internal {
		address _this = address(this);
		if (info.bcf.dividendsOf(_this) > 0) {
			uint256 _balance = info.bcf.balanceOf(_this);
			info.bcf.reinvest();
			info.cumulativeBCF += info.bcf.balanceOf(_this) - _balance;
		}
	}


	function _cardPrice(uint256 _index) internal view returns (uint256 price, uint256 level) {
		Card memory _card = info.cards[_index];
		uint256 _diff = (block.number - _card.lastBlock) / _card.cooldown;
		uint256 _level = 0;
		if (_card.currentLevel > _diff) {
			_level = _card.currentLevel - _diff;
		}
		return (_card.basePrice * 2**_level, _level);
	}
}
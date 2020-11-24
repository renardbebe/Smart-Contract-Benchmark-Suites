 

pragma solidity ^0.4.24;

library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    return a / b;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}


  
contract Ownable {
  address public owner;

  
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}


 
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused() {
    require(paused);
    _;
  }

   
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}



contract BattleBase is Ownable {
	 using SafeMath for uint256;
	 
	 
	 
	
	 
	event BattleHistory(
		uint256 historyId,
		uint8 winner,  
		uint64 battleTime,
		uint256 sequence,
		uint256 blockNumber,
		uint256 tokensGained);
	
	event BattleHistoryChallenger(
		uint256 historyId,
		uint256 cardId,
		uint8 element,
		uint16 level,
		uint32 attack,
		uint32 defense,
		uint32 hp,
		uint32 speed,
		uint32 criticalRate,
		uint256 rank);
		
	event BattleHistoryDefender(
		uint256 historyId,
		uint256 cardId,
		uint8 element,
		uint16 level,
		uint32 attack,
		uint32 defense,
		uint32 hp,
		uint32 speed,
		uint16 criticalRate,
		uint256 rank);
	
	event RejectChallenge(
		uint256 challengerId,
		uint256 defenderId,
		uint256 defenderRank,
		uint8 rejectCode,
		uint256 blockNumber);
		
	event HashUpdated(
		uint256 cardId, 
		uint256 cardHash);
		
	event LevelUp(uint256 cardId);
	
	event CardCreated(address owner, uint256 cardId);
	
	
	 
	 		
	uint32[] expToNextLevelArr = [0,103,103,207,207,207,414,414,414,414,724,724,724,828,828,931,931,1035,1035,1138,1138,1242,1242,1345,1345,1449,1449,1552,1552,1656,1656,1759,1759,1863,1863,1966,1966,2070,2070,2173,2173,2173,2277,2277,2380,2380,2484,2484,2587,2587,2691,2691,2794,2794,2898,2898,3001,3001,3105,3105,3208,3208,3312,3312,3415,3415,3519,3519,3622,3622,3622,3726,3726,3829,3829,3933,3933,4036,4036,4140,4140,4243,4243,4347,4347,4450,4450,4554,4554,4657,4657,4761,4761,4864,4864,4968,4968,5071,5071,5175];
	
	uint32[] activeWinExp = [10,11,14,19,26,35,46,59,74,91,100,103,108,116,125,135,146,158,171,185,200,215,231,248,265,283,302,321,341,361,382];
	
	
	 
	 		
	 
	struct Card {
		uint8 element;  
		uint16 level;  
		uint32 attack;
		uint32 defense;
		uint32 hp;
		uint32 speed;
		uint16 criticalRate;  
		uint32 flexiGems;
		uint256 cardHash;
		uint32 currentExp;
		uint32 expToNextLevel;
		uint64 createdDatetime;

		uint256 rank;  

		 
	}
	
	 
	mapping (uint256 => Card) public cards;
	
	uint256[] ranking;  
	
	 
	mapping (uint256 => uint256) public rankTokens;
	
	uint8 public currentElement = 0;  
	
	uint256 public historyId = 0;
	
	 
	 
	 
	HogSmashToken public hogsmashToken;
	
	 
	Marketplace public marketplace;
			
	 
	uint256 public challengeFee;

	 
	uint256 public upgradeFee;
	
	 
	uint256 public avatarFee;
	
	 
	uint256 public referrerFee;
	
	 
	uint256 public developerCut;
	
	uint256 internal totalDeveloperCut;

	 
	uint256 public cardDrawPrice;

	 
	uint8 public upgradeGems;  
	 
	uint8 public upgradeGemsSpecial;
	 
	uint16 public gemAttackConversion;
	 
	uint16 public gemDefenseConversion;
	 
	uint16 public gemHpConversion;
	 
	uint16 public gemSpeedConversion;
	 
	uint16 public gemCriticalRateConversion;
	
	 
	uint8 public goldPercentage;
	
	 
	uint8 public silverPercentage;
 	
	 
	uint32 public eventCardRangeMin;
	
	 
	uint32 public eventCardRangeMax;
	
	 
	uint8 public maxBattleRounds;  
		
	 
	uint256 internal totalRankTokens;
	
	 
	bool internal battleStart;
	
	 
	bool internal starterPackOnSale;
	
	uint256 public starterPackPrice;  
	
	uint16 public starterPackCardLevel;  
	
	
	 
	 		
	 
	 
	function setMarketplaceAddress(address _address) external onlyOwner {
		Marketplace candidateContract = Marketplace(_address);

		require(candidateContract.isMarketplace(),"needs to be marketplace");

		 
		marketplace = candidateContract;
	}
		
	 
	function setSettingValues(  uint8 _upgradeGems,
	uint8 _upgradeGemsSpecial,
	uint16 _gemAttackConversion,
	uint16 _gemDefenseConversion,
	uint16 _gemHpConversion,
	uint16 _gemSpeedConversion,
	uint16 _gemCriticalRateConversion,
	uint8 _goldPercentage,
	uint8 _silverPercentage,
	uint32 _eventCardRangeMin,
	uint32 _eventCardRangeMax,
	uint8 _newMaxBattleRounds) external onlyOwner {
		require(_eventCardRangeMax >= _eventCardRangeMin, "range max must be larger or equals range min" );
		require(_eventCardRangeMax<100000000, "range max cannot exceed 99999999");
		require((_newMaxBattleRounds <= 128) && (_newMaxBattleRounds >0), "battle rounds must be between 0 and 128");
		upgradeGems = _upgradeGems;
		upgradeGemsSpecial = _upgradeGemsSpecial;
		gemAttackConversion = _gemAttackConversion;
		gemDefenseConversion = _gemDefenseConversion;
		gemHpConversion = _gemHpConversion;
		gemSpeedConversion = _gemSpeedConversion;
		gemCriticalRateConversion = _gemCriticalRateConversion;
		goldPercentage = _goldPercentage;
		silverPercentage = _silverPercentage;
		eventCardRangeMin = _eventCardRangeMin;
		eventCardRangeMax = _eventCardRangeMax;
		maxBattleRounds = _newMaxBattleRounds;
	}
	
	
	 
	function setStarterPack(uint256 _newStarterPackPrice, uint16 _newStarterPackCardLevel) external onlyOwner {
		require(_newStarterPackCardLevel<=20, "starter pack level cannot exceed 20");  
		starterPackPrice = _newStarterPackPrice;
		starterPackCardLevel = _newStarterPackCardLevel;		
	} 	
	
	 
	function setStarterPackOnSale(bool _newStarterPackOnSale) external onlyOwner {
		starterPackOnSale = _newStarterPackOnSale;
	}
	
	 
	function setBattleStart(bool _newBattleStart) external onlyOwner {
		battleStart = _newBattleStart;
	}
	
	 
	function setCardDrawPrice(uint256 _newCardDrawPrice) external onlyOwner {
		cardDrawPrice = _newCardDrawPrice;
	}
	
	 
	function setReferrerFee(uint256 _newReferrerFee) external onlyOwner {
		referrerFee = _newReferrerFee;
	}

	 
	function setChallengeFee(uint256 _newChallengeFee) external onlyOwner {
		challengeFee = _newChallengeFee;
	}

	 
	function setUpgradeFee(uint256 _newUpgradeFee) external onlyOwner {
		upgradeFee = _newUpgradeFee;
	}
	
	 
	function setAvatarFee(uint256 _newAvatarFee) external onlyOwner {
		avatarFee = _newAvatarFee;
	}
	
	 
	function setDeveloperCut(uint256 _newDeveloperCut) external onlyOwner {
		developerCut = _newDeveloperCut;
	}
		
	function getTotalDeveloperCut() external view onlyOwner returns (uint256) {
		return totalDeveloperCut;
	}
		
	function getTotalRankTokens() external view returns (uint256) {
		return totalRankTokens;
	}
	
	
	 
	 	
	 
	function getSettingValues() external view returns(  uint8 _upgradeGems,
															uint8 _upgradeGemsSpecial,
															uint16 _gemAttackConversion,
															uint16 _gemDefenseConversion,
															uint16 _gemHpConversion,
															uint16 _gemSpeedConversion,
															uint16 _gemCriticalRateConversion,
															uint8 _maxBattleRounds)
	{
		_upgradeGems = uint8(upgradeGems);
		_upgradeGemsSpecial = uint8(upgradeGemsSpecial);
		_gemAttackConversion = uint16(gemAttackConversion);
		_gemDefenseConversion = uint16(gemDefenseConversion);
		_gemHpConversion = uint16(gemHpConversion);
		_gemSpeedConversion = uint16(gemSpeedConversion);
		_gemCriticalRateConversion = uint16(gemCriticalRateConversion);
		_maxBattleRounds = uint8(maxBattleRounds);
	}
		

}

 
 
contract Random {
	uint private pSeed = block.number;

	function getRandom() internal returns(uint256) {
		return (pSeed = uint(keccak256(abi.encodePacked(pSeed,
		blockhash(block.number - 1),
		blockhash(block.number - 3),
		blockhash(block.number - 5),
		blockhash(block.number - 7))
		)));
	}
}

 
 
 
contract Battle is BattleBase, Random, Pausable {

	 
	 
	 
	constructor(address _tokenAddress) public {
		HogSmashToken candidateContract = HogSmashToken(_tokenAddress);
		 
		hogsmashToken = candidateContract;
		
		starterPackPrice = 30000000000000000;
		starterPackCardLevel = 5;
		starterPackOnSale = true;  
		
		challengeFee = 10000000000000000;
		
		upgradeFee = 10000000000000000;
		
		avatarFee = 50000000000000000;
		
		developerCut = 375;
		
		referrerFee = 2000;
		
		cardDrawPrice = 15000000000000000;
 		
		battleStart = true;
 		
		paused = false;  
				
		totalDeveloperCut = 0;  
	}
	
	 
	 
	 
	modifier onlyOwnerOf(uint256 _tokenId) {
		require(hogsmashToken.ownerOf(_tokenId) == msg.sender, "must be owner of token");
		_;
	}
		
	
	 
	 
	 
	function getCard(uint256 _id) external view returns (
	uint256 cardId,
	address owner,
	uint8 element,
	uint16 level,
	uint32[] stats,
	uint32 currentExp,
	uint32 expToNextLevel,
	uint256 cardHash,
	uint64 createdDatetime,
	uint256 rank
	) {
		cardId = _id;
		
		owner = hogsmashToken.ownerOf(_id);
		
		Card storage card = cards[_id];
		
		uint32[] memory tempStats = new uint32[](6);

		element = uint8(card.element);
		level = uint16(card.level);
		tempStats[0] = uint32(card.attack);
		tempStats[1] = uint32(card.defense);
		tempStats[2] = uint32(card.hp);
		tempStats[3] = uint32(card.speed);
		tempStats[4] = uint16(card.criticalRate);
		tempStats[5] = uint32(card.flexiGems);
		stats = tempStats;
		currentExp = uint32(card.currentExp);
		expToNextLevel = uint32(card.expToNextLevel);
		cardHash = uint256(card.cardHash);
		createdDatetime = uint64(card.createdDatetime);
		rank = uint256(card.rank);
	}
	
	
	 
	function getCardIdByRank(uint256 _rank) external view returns(uint256 cardId) {
		return ranking[_rank];
	}
	

	 
	function draftNewCard() external payable whenNotPaused returns (uint256) {
		require(msg.value == cardDrawPrice, "fee must be equal to draw price");  
				
		require(address(marketplace) != address(0), "marketplace not set");  
				
		hogsmashToken.setApprovalForAllByContract(msg.sender, marketplace, true);  
		
		totalDeveloperCut = totalDeveloperCut.add(cardDrawPrice);
		
		return _createCard(msg.sender, 1);  
	}
	
	 
	function draftNewCardWithReferrer(address referrer) external payable whenNotPaused returns (uint256 cardId) {
		require(msg.value == cardDrawPrice, "fee must be equal to draw price");  
				
		require(address(marketplace) != address(0), "marketplace not set");  
				
		hogsmashToken.setApprovalForAllByContract(msg.sender, marketplace, true);  
		
		cardId = _createCard(msg.sender, 1);  
		
		if ((referrer != address(0)) && (referrerFee!=0) && (referrer!=msg.sender) && (hogsmashToken.balanceOf(referrer)>0)) {
			uint256 referrerCut = msg.value.mul(referrerFee)/10000;
			require(referrerCut<=msg.value, "referre cut cannot be larger than fee");
			referrer.transfer(referrerCut);
			totalDeveloperCut = totalDeveloperCut.add(cardDrawPrice.sub(referrerCut));
		} else {
			totalDeveloperCut = totalDeveloperCut.add(cardDrawPrice);
		}		
	}
	

	 
	function levelUp( 	uint256 _id,
						uint16 _attackLevelUp,
						uint16 _defenseLevelUp,
						uint16 _hpLevelUp,
						uint16 _speedLevelUp,
						uint16 _criticalRateLevelUp,
						uint16 _flexiGemsLevelUp) external payable whenNotPaused onlyOwnerOf(_id) {
		require(
		_attackLevelUp >= 0        &&
		_defenseLevelUp >= 0       &&
		_hpLevelUp >= 0            &&
		_speedLevelUp >= 0         &&
		_criticalRateLevelUp >= 0  &&
		_flexiGemsLevelUp >= 0, "level up attributes must be more than 0"
		);  

		require(msg.value == upgradeFee, "fee must be equals to upgrade price");  

		Card storage card = cards[_id];		
		require(card.currentExp==card.expToNextLevel, "exp is not max yet for level up");  
		
		require(card.level < 65535, "card level maximum has reached");  
		
		require((card.criticalRate + (_criticalRateLevelUp * gemCriticalRateConversion))<=7000, "critical rate max of 70 has reached");  

		uint totalInputGems = _attackLevelUp + _defenseLevelUp + _hpLevelUp;
		totalInputGems += _speedLevelUp + _criticalRateLevelUp + _flexiGemsLevelUp;
		
		uint16 numOfSpecials = 0;
				
		 
		if ((card.level > 1) && (card.attack==1) && (card.defense==1) && (card.hp==3) && (card.speed==1) && (card.criticalRate==25) && (card.flexiGems==1)) {
			numOfSpecials = (card.level+1)/5;  
			uint totalGems = (numOfSpecials * upgradeGemsSpecial) + (((card.level) - numOfSpecials) * upgradeGems);
			require(totalInputGems==totalGems, "upgrade gems not used up");  
		} else {
			if (((card.level+1)%5)==0) {  
				require(totalInputGems==upgradeGemsSpecial, "upgrade gems not used up");  
				numOfSpecials = 1;
			} else {
				require(totalInputGems==upgradeGems, "upgrade gems not used up");  
			}
		}
		
		totalDeveloperCut = totalDeveloperCut.add(upgradeFee);
		
		 
		_upgradeLevel(_id, _attackLevelUp, _defenseLevelUp, _hpLevelUp, _speedLevelUp, _criticalRateLevelUp, _flexiGemsLevelUp, numOfSpecials);
								
		emit LevelUp(_id);
	}

	function _upgradeLevel( uint256 _id,
							uint16 _attackLevelUp,
							uint16 _defenseLevelUp,
							uint16 _hpLevelUp,
							uint16 _speedLevelUp,
							uint16 _criticalRateLevelUp,
							uint16 _flexiGemsLevelUp,
							uint16 numOfSpecials) private {
		Card storage card = cards[_id];
		uint16[] memory extraStats = new uint16[](5);  
		if (numOfSpecials>0) {  
			if (card.cardHash%100 >= 70) {  
				uint cardType = (uint(card.cardHash/10000000000))%100;  
				if (cardType < 20) {
					extraStats[0]+=numOfSpecials;
				} else if (cardType < 40) {
					extraStats[1]+=numOfSpecials;
				} else if (cardType < 60) {
					extraStats[2]+=numOfSpecials;
				} else if (cardType < 80) {
					extraStats[3]+=numOfSpecials;
				} else {
					extraStats[4]+=numOfSpecials;
				}
				
				if (card.cardHash%100 >=90) {  
					uint cardTypeInner = cardType%10;  
					if (cardTypeInner < 2) {
						extraStats[0]+=numOfSpecials;
					} else if (cardTypeInner < 4) {
						extraStats[1]+=numOfSpecials;
					} else if (cardTypeInner < 6) {
						extraStats[2]+=numOfSpecials;
					} else if (cardTypeInner < 8) {
						extraStats[3]+=numOfSpecials;
					} else {
						extraStats[4]+=numOfSpecials;
					}
				}
			}
		}
		card.attack += (_attackLevelUp + extraStats[0]) * gemAttackConversion;
		card.defense += (_defenseLevelUp + extraStats[1]) * gemDefenseConversion;
		card.hp += (_hpLevelUp + extraStats[2]) * gemHpConversion;
		card.speed += (_speedLevelUp + extraStats[3]) * gemSpeedConversion;		
		card.criticalRate += uint16(_criticalRateLevelUp * gemCriticalRateConversion);
		card.flexiGems += _flexiGemsLevelUp + extraStats[4];  
		card.level += 1;  

		card.currentExp = 0;  
		 
		uint256 tempExpLevel = card.level;
		if (tempExpLevel > expToNextLevelArr.length) {
			tempExpLevel = expToNextLevelArr.length;  
		}
		card.expToNextLevel = expToNextLevelArr[tempExpLevel];
	}

	function max(uint a, uint b) private pure returns (uint) {
		return a > b ? a : b;
	}

	function challenge( uint256 _challengerCardId,
						uint32[5] _statUp,  
						uint256 _defenderCardId,						
						uint256 _defenderRank,
						uint16 _defenderLevel) external payable whenNotPaused onlyOwnerOf(_challengerCardId) {
		require(battleStart != false, "battle has not started");  
		require(msg.sender != hogsmashToken.ownerOf(_defenderCardId), "cannot challenge own cards");  
		Card storage challenger = cards[_challengerCardId];		
		require((_statUp[0] + _statUp[1] + _statUp[2] + _statUp[3] + _statUp[4])==challenger.flexiGems, "flexi gems not used up");  
		
		Card storage defender = cards[_defenderCardId];
		
		if (defender.rank != _defenderRank) {
			emit RejectChallenge(_challengerCardId, _defenderCardId, _defenderRank, 1, uint256(block.number));
			(msg.sender).transfer(msg.value);		
			return;
		}
		
		if (defender.level != _defenderLevel) {
			emit RejectChallenge(_challengerCardId, _defenderCardId, _defenderRank, 2, uint256(block.number));
			(msg.sender).transfer(msg.value);
			return;
		}
		
		uint256 requiredChallengeFee = challengeFee;
		if (defender.rank <150) {  
			requiredChallengeFee = requiredChallengeFee.mul(2);
		}
		require(msg.value == requiredChallengeFee, "fee must be equals to challenge price");  
		
		uint256 developerFee = 0;
		if (msg.value > 0) {
			developerFee = _calculateFee(msg.value);
		}
		
		uint256[] memory stats = new uint256[](14);  

		stats[0] = challenger.attack + (_statUp[0] * gemAttackConversion);
		stats[1] = challenger.defense + (_statUp[1] * gemDefenseConversion);
		stats[2] = challenger.hp + (_statUp[2] * gemHpConversion);
		stats[3] = challenger.speed + (_statUp[3] * gemSpeedConversion);
		stats[4] = challenger.criticalRate + (_statUp[4] * gemCriticalRateConversion);
		stats[5] = defender.criticalRate;
		stats[6] = defender.hp;
		stats[8] = challenger.hp + (_statUp[2] * gemHpConversion);  
		stats[9] = challenger.rank;  
		stats[10] = defender.rank;  
		stats[11] = 0;  
		stats[12] = _challengerCardId;
		stats[13] = _defenderCardId;

		 
		if (stats[4]>7000) {
			stats[4] = 7000;  
		}

		 
		if (stats[5]>7000) {
			stats[5] = 7000;  
		}

		 
		if (((challenger.element-1) == defender.element) || ((challenger.element==1) && (defender.element==3)) || ((challenger.element==8) && (defender.element==9))) {
			stats[4] += 3000;  
			if (stats[4]>8000) {
				stats[4] = 8000;  
			}
		}

		if (((defender.element-1) == challenger.element) || ((defender.element==1) && (challenger.element==3)) || ((defender.element==8) && (challenger.element==9))) {
			stats[5] += 3000;  
			if (stats[5]>8000) {
				stats[5] = 8000;  
			}
		}
		
		uint256 battleSequence = _simulateBattle(challenger, defender, stats);
		
		stats[11] = _transferFees(_challengerCardId, stats, developerFee);	
		
		
		emit BattleHistory(
			historyId,
			uint8(stats[7]),
			uint64(now),
			uint256(battleSequence),
			uint256(block.number),
			uint256(stats[11])
		);
		
		emit BattleHistoryChallenger(
			historyId,
			uint256(_challengerCardId),
			uint8(challenger.element),
			uint16(challenger.level),
			uint32(stats[0]),
			uint32(stats[1]),
			uint32(stats[8]),
			uint32(stats[3]),
			uint16(stats[4]),  
			uint256(stats[9])
		);
			
		emit BattleHistoryDefender(	
			historyId,
			uint256(_defenderCardId),
			uint8(defender.element),
			uint16(defender.level),
			uint32(defender.attack),
			uint32(defender.defense),
			uint32(defender.hp),
			uint32(defender.speed),
			uint16(stats[5]),
			uint256(stats[10])
		);
		
		historyId = historyId.add(1);  
	}
	
	function _addBattleSequence(uint8 attackType, uint8 rounds, uint256 battleSequence) private pure returns (uint256) {
		 
		uint256 mask = 0x3;
		mask = ~(mask << 2*rounds);
		uint256 newSeq = battleSequence & mask;

		newSeq = newSeq | (uint256(attackType) << 2*rounds);

		return newSeq;
	}


	function _simulateBattle(Card storage challenger, Card storage defender, uint[] memory stats) private returns (uint256 battleSequence) {
	
		bool continueBattle = true;
		uint8 currentAttacker = 0;  
		uint256 tempAttackStrength;
		uint8 battleRound = 0;
		if (!_isChallengerAttackFirst(stats[3], defender.speed)){
			currentAttacker = 1;
		}
		while (continueBattle) {
			if (currentAttacker==0) {  
				if (_rollCriticalDice() <= stats[4]){
					tempAttackStrength = stats[0] * 2;  
					battleSequence = _addBattleSequence(2, battleRound, battleSequence);  
				} else {
					tempAttackStrength = stats[0];  
					battleSequence = _addBattleSequence(0, battleRound, battleSequence);  
				}
				if (tempAttackStrength <= defender.defense) {
					tempAttackStrength = 1;  
				} else {
					tempAttackStrength -= defender.defense;
				}
				if (stats[6] <= tempAttackStrength) {
					stats[6] = 0;  
				} else {
					stats[6] -= tempAttackStrength;  
				}
				currentAttacker = 1;  
			} else if (currentAttacker==1) {  
				if (_rollCriticalDice() <= stats[5]){
					tempAttackStrength = defender.attack * 2;  
					battleSequence = _addBattleSequence(3, battleRound, battleSequence);  
				} else {
					tempAttackStrength = defender.attack;  
					battleSequence = _addBattleSequence(1, battleRound, battleSequence);  
				}
				if (tempAttackStrength <= stats[1]) {
					tempAttackStrength = 1;  
				} else {
					tempAttackStrength -= stats[1];
				}
				if (stats[2] <= tempAttackStrength) {
					stats[2] = 0;  
				} else {
					stats[2] -= tempAttackStrength;  
				}
				currentAttacker = 0;  
			}
			battleRound ++;

			if ((battleRound>=maxBattleRounds) || (stats[6]<=0) || (stats[2]<=0)){
				continueBattle = false;  
			}
		}

		uint32 challengerGainExp = 0;
		uint32 defenderGainExp = 0;

		 
		if (challenger.level == defender.level) {  
			challengerGainExp = activeWinExp[10];
		} else if (challenger.level > defender.level) {  
			if ((challenger.level - defender.level) >= 11) {
				challengerGainExp = 1;  
			} else {
				 
				challengerGainExp = activeWinExp[10 + defender.level - challenger.level];  
			}
		} else if (challenger.level < defender.level) {  
			 
			uint256 levelDiff = defender.level - challenger.level;
			if (levelDiff > 20) {
				levelDiff = 20;  
			}
			challengerGainExp = activeWinExp[10+levelDiff];
		}
		
		if (stats[2] == stats[6]) {  
			stats[7] = 2;  
			 
		} else if (stats[2] > stats[6]) {  
			stats[7] = 0;  
			if (defender.rank < challenger.rank) {  
				ranking[defender.rank] = stats[12];  
				ranking[challenger.rank] = stats[13];  
				uint256 tempRank = defender.rank;
				defender.rank = challenger.rank;  
				challenger.rank = tempRank;  
			}

			 
			 
			challenger.currentExp += challengerGainExp;
			if (challenger.currentExp > challenger.expToNextLevel) {
				challenger.currentExp = challenger.expToNextLevel;  
			}

			 
			 
			defenderGainExp = ((challengerGainExp*105/100) + 5)/10;  
			if (defenderGainExp <= 0) {
				defenderGainExp = 1;  
			}
			defender.currentExp += defenderGainExp;
			if (defender.currentExp > defender.expToNextLevel) {
				defender.currentExp = defender.expToNextLevel;  
			}

		} else if (stats[6] > stats[2]) {  
			stats[7] = 1;  
			 
			 
			uint32 tempChallengerGain = challengerGainExp*35/100;  
			if (tempChallengerGain <= 0) {
				tempChallengerGain = 1;  
			}
			challenger.currentExp += tempChallengerGain;  
			if (challenger.currentExp > challenger.expToNextLevel) {
				challenger.currentExp = challenger.expToNextLevel;  
			}

			 
			defenderGainExp = challengerGainExp*30/100;
			if (defenderGainExp <= 0) {
				defenderGainExp = 1;  
			}
			defender.currentExp += defenderGainExp;
			if (defender.currentExp > defender.expToNextLevel) {
				defender.currentExp = defender.expToNextLevel;  
			}
		}
		
		return battleSequence;
	}
	
	
	
	function _transferFees(uint256 _challengerCardId, uint[] stats, uint256 developerFee) private returns (uint256 totalGained) {
		totalDeveloperCut = totalDeveloperCut.add(developerFee);		
		uint256 remainFee = msg.value.sub(developerFee);  
		totalGained = 0;
		if (stats[7] == 1) {  
			 
			rankTokens[stats[10]] = rankTokens[stats[10]].add(remainFee);
			totalRankTokens = totalRankTokens.add(remainFee);
		} else {  
			address challengerAddress = hogsmashToken.ownerOf(_challengerCardId);  
			if (stats[7] == 0) {  
				if (stats[9] > stats[10]) {  
					 
					if (rankTokens[stats[10]] > 0) {
						totalGained = totalGained.add(rankTokens[stats[10]]);
						totalRankTokens = totalRankTokens.sub(rankTokens[stats[10]]);
						rankTokens[stats[10]] = 0;						
					}
					 
					if (rankTokens[stats[9]] > 0) {
						totalGained = totalGained.add(rankTokens[stats[9]]);
						totalRankTokens = totalRankTokens.sub(rankTokens[stats[9]]);
						rankTokens[stats[9]] = 0;
					}					
				} else {  
					if (stats[9]<50) {  
						if ((stats[10] < 150) && (rankTokens[stats[10]] > 0)) {  
							totalGained = totalGained.add(rankTokens[stats[10]]);
							totalRankTokens = totalRankTokens.sub(rankTokens[stats[10]]);
							rankTokens[stats[10]] = 0;
						}
						
						if ((stats[10] < 150) && (rankTokens[stats[9]] > 0)) {  
							totalGained = totalGained.add(rankTokens[stats[9]]);
							totalRankTokens = totalRankTokens.sub(rankTokens[stats[9]]);
							rankTokens[stats[9]] = 0;
						}
					}
				}
				challengerAddress.transfer(totalGained.add(remainFee));  
			} else {  
				challengerAddress.transfer(remainFee);  
			} 
		}			
	}
	

	function _rollCriticalDice() private returns (uint16 result){
		return uint16((getRandom() % 10000) + 1);  
	}

	function _isChallengerAttackFirst(uint _challengerSpeed, uint _defenderSpeed ) private returns (bool){
		uint8 randResult = uint8((getRandom() % 100) + 1);  
		uint challengerChance = (((_challengerSpeed * 10 ** 3) / (_challengerSpeed + _defenderSpeed))+5) / 10; 
		if (randResult <= challengerChance) {
			return true;
		} else {
			return false;
		}
	}

	
	 
	function buyStarterPack() external payable whenNotPaused returns (uint256){
		require(starterPackOnSale==true, "starter pack is not on sale");
		require(msg.value==starterPackPrice, "fee must be equals to starter pack price");
		require(address(marketplace) != address(0), "marketplace not set");  
		
		totalDeveloperCut = totalDeveloperCut.add(starterPackPrice);
				
		hogsmashToken.setApprovalForAllByContract(msg.sender, marketplace, true);  
		
		return _createCard(msg.sender, starterPackCardLevel);  
	}
		
	 
	function _createCard(address _to, uint16 _initLevel) private returns (uint256) {
		require(_to != address(0), "cannot create card for unknown address");  

		currentElement+= 1;
		if (currentElement==4) {
			currentElement = 8;
		}
		if (currentElement == 10) {
			currentElement = 1;
		}
		uint256 tempExpLevel = _initLevel;
		if (tempExpLevel > expToNextLevelArr.length) {
			tempExpLevel = expToNextLevelArr.length;  
		}
		
		uint32 tempCurrentExp = 0;
		if (_initLevel>1) {  
			tempCurrentExp = expToNextLevelArr[tempExpLevel];
		}
		
		uint256 tokenId = hogsmashToken.mint(_to);
		
		 
		Card memory _card = Card({
			element: currentElement,  
			level: _initLevel,  
			attack: 1,  
			defense: 1,  
			hp: 3,  
			speed: 1,  
			criticalRate: 25,  
			flexiGems: 1,  
			currentExp: tempCurrentExp,  
			expToNextLevel: expToNextLevelArr[tempExpLevel],  
			cardHash: generateHash(),
			createdDatetime :uint64(now),
			rank: tokenId  
		});
		
		cards[tokenId] = _card;
		ranking.push(tokenId);  
		
		emit CardCreated(msg.sender, tokenId);

		return tokenId;
	}
	
	function generateHash() private returns (uint256 hash){
		hash = uint256((getRandom()%1000000000000)/10000000000);		
		hash = hash.mul(10000000000);
		
		uint256 tempHash = ((getRandom()%(eventCardRangeMax-eventCardRangeMin+1))+eventCardRangeMin)*100;
		hash = hash.add(tempHash);
		
		tempHash = getRandom()%100;
		
		if (tempHash < goldPercentage) {
			hash = hash.add(90);
		} else if (tempHash < (goldPercentage+silverPercentage)) {
			hash = hash.add(70);
		} else {
			hash = hash.add(50);
		}
	}
	
	 
	function updateAvatar(uint256 _cardId, uint256 avatarHash) external payable whenNotPaused onlyOwnerOf(_cardId) {
		require(msg.value==avatarFee, "fee must be equals to avatar price");
				
		Card storage card = cards[_cardId];
		
		uint256 tempHash = card.cardHash%1000000000000;  
		
		card.cardHash = tempHash.add(avatarHash.mul(1000000000000));
		
		emit HashUpdated(_cardId, card.cardHash);		
	}
		
	
	 
	 
	function _calculateFee(uint256 _challengeFee) internal view returns (uint256) {
		return developerCut.mul(_challengeFee/10000);
	}
	
	
	 
	 	
	 
	function generateInitialCard(uint16 _cardLevel) external whenNotPaused onlyOwner returns (uint256) {
		require(address(marketplace) != address(0), "marketplace not set");  
		require(_cardLevel<=20, "maximum level cannot exceed 20");  
		
		hogsmashToken.setApprovalForAllByContract(msg.sender, marketplace, true);  

		return _createCard(msg.sender, _cardLevel);  
	}
	
	 
	function distributeTokensToRank(uint[] ranks, uint256 tokensPerRank) external payable onlyOwner {
		require(msg.value == (tokensPerRank*ranks.length), "tokens must be enough to distribute among ranks");
		uint i;
		for (i=0; i<ranks.length; i++) {
			rankTokens[ranks[i]] = rankTokens[ranks[i]].add(tokensPerRank);
			totalRankTokens = totalRankTokens.add(tokensPerRank);
		}
	}
	
	
	 
	function withdrawBalance() external onlyOwner {
		address thisAddress = this;
		uint256 balance = thisAddress.balance;
		uint256 withdrawalSum = totalDeveloperCut;

		if (balance >= withdrawalSum) {
			totalDeveloperCut = 0;
			owner.transfer(withdrawalSum);
		}
	}
}

 
 
interface Marketplace {
	function isMarketplace() external returns (bool);
}

interface HogSmashToken {
	function ownerOf(uint256 _tokenId) external view returns (address);
	function balanceOf(address _owner) external view returns (uint256);
	function tokensOf(address _owner) external view returns (uint256[]);
	function mint(address _to) external returns (uint256 _tokenId);
	function setTokenURI(uint256 _tokenId, string _uri) external;
	function setApprovalForAllByContract(address _sender, address _to, bool _approved) external;
}
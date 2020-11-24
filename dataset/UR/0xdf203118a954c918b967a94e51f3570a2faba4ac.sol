 

pragma solidity ^0.4.24;


 



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






contract SuperCountriesEth {
  using SafeMath for uint256;

 
 
 
 
   
	constructor () public {
    owner = msg.sender;
	}
	
	address public owner;  

  
   
	modifier onlyOwner() {
		require(owner == msg.sender);
		_;
	}


   
	function transferOwnership(address newOwner) public onlyOwner {
		require(newOwner != address(0));
		emit OwnershipTransferred(owner, newOwner);
		owner = newOwner;
	}

	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

 
 


 
 
 
  
  event Bought (uint256 indexed _itemId, address indexed _owner, uint256 _price);
  event Sold (uint256 indexed _itemId, address indexed _owner, uint256 _price);
  event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
  event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);
  
  event SetReferrerEvent(address indexed referral, address indexed referrer);
  event PayReferrerEvent(address indexed oldOwner, address indexed referrer1, address indexed referrer2, uint256 referralPart);
  
  event BonusConstant(uint256 bonusToDispatch_, uint256 bonusDispatched_, uint256 notYetDispatched_, uint256 indexed _itemSoldId_, uint256 kBonus, uint256 indexed countryScore);
  event BonusDispatch(uint256 bonusToGet_, uint256 indexed playerScoreForThisCountry_, address indexed player_, uint256 pendingBalanceTotal_, uint256 indexed _itemSoldId);
  event DivsDispatch(uint256 dividendsCut_, uint256 dividendsScore, uint256 indexed _itemId, uint256 price, uint256 worldScore_);
  event newRichest(address indexed richest_, uint256 richestScore_, uint256 indexed blocktimestamp_, uint256 indexed blocknumber_);
  
  event Withdrawal(address indexed playerAddress, uint256 indexed ethereumWithdrawn, uint256 indexed potVersion_);
  event ConfirmWithdraw(address indexed playerAddress, uint256 refbonus_, uint256 divs_, uint256 totalPending_, uint256 playerSc_, uint256 _handicap_);
  event ConfirmPotWithdraw(uint256 contractBalance, address indexed richest_, uint256 richestBalance_, address indexed lastBuyer_, uint256 lastBalance_, uint256 indexed potVersion);
  event PotWithdrawConstant(uint256 indexed blocktimestamp_, uint256 indexed timestamplimit_, uint256 dividendsScore_, uint256 indexed potVersion, uint256 lastWithdrawPotVersion_);
  event WithdrawOwner(uint256 indexed potVersion, uint256 indexed lastWithdrawPotVersion_, uint256 indexed balance_);

 
 


 
 
 
  
  bool private erc721Enabled = false;

   
  uint256 private increaseLimit1 = 0.04 ether;
  uint256 private increaseLimit2 = 0.6 ether;
  uint256 private increaseLimit3 = 2.5 ether;
  uint256 private increaseLimit4 = 7.0 ether;

   
  uint256[] private listedItems;
  mapping (uint256 => address) private ownerOfItem;
  mapping (uint256 => uint256) private priceOfItem;
  mapping (uint256 => uint256) private previousPriceOfItem;
  mapping (uint256 => address) private approvedOfItem;
   
  
   
  mapping(address => address) public referrerOf;
  
   
  uint256 private worldScore ;  
  mapping (address => uint256) private playerScore;  
  uint256 private dividendsScore ;  
  mapping(uint256 => mapping(address => uint256)) private pendingBalance;  
  mapping(uint256 => mapping(address => uint256)) private handicap;  
  mapping(uint256 => mapping(address => uint256)) private balanceToWithdraw;  

  uint256 private potVersion = 1;  
  uint256 private lastWithdrawPotVersion = 1;  
  address private richestBuyer ;  
  address private lastBuyer ;  
  uint256 private timestampLimit = 1528108990;  
  
  struct CountryStruct {
		address[] itemToAddressArray;  
		uint256 priceHistory;  
		uint256 startingPrice;  
		}

  mapping (uint256 => CountryStruct) public countryStructs;
  
  mapping (uint256 => mapping(address => uint256)) private itemHistory;  
  
  uint256 private HUGE = 1e13;
 
 
 


 
 
 

	modifier onlyRealAddress() {
		require(msg.sender != address(0));
		_;
	}


	

	
 
 
 

	modifier onlyERC721() {
		require(erc721Enabled);
		_;
	} 


   	 
	function enableERC721 () onlyOwner() public {
		erc721Enabled = true;
	} 

  
 

 
 
 
 
	
	function listMultipleItems (uint256[] _itemIds, uint256 _price, address _owner) onlyOwner() external {
		for (uint256 i = 0; i < _itemIds.length; i++) {
			listItem(_itemIds[i], _price, _owner);
		}
	}

	
	function listItem (uint256 _itemId, uint256 _price, address _owner) onlyOwner() public {
		require(_price > 0);
		require(priceOfItem[_itemId] == 0);
		require(ownerOfItem[_itemId] == address(0));

		ownerOfItem[_itemId] = _owner;
		priceOfItem[_itemId] = _price;
		previousPriceOfItem[_itemId] = 0;
		listedItems.push(_itemId);
		newEntity(_itemId, _price);
	}

	
   	
	function newEntity(uint256 countryId, uint256 startPrice) private returns(bool success) {
		countryStructs[countryId].startingPrice = startPrice;
		return true;
	}

	
   	
	function updateEntity(uint256 countryId, address newOwner, uint256 priceUpdate) internal {
		countryStructs[countryId].priceHistory += priceUpdate;
		if (itemHistory[countryId][newOwner] == 0 ){
			countryStructs[countryId].itemToAddressArray.push(newOwner);
		}
	  }
 



 
 
 
 

	function calculateNextPrice (uint256 _price) public view returns (uint256 _nextPrice) {
		if (_price < increaseLimit1) {
			return _price.mul(200).div(95);
		} else if (_price < increaseLimit2) {
			return _price.mul(160).div(96);
		} else if (_price < increaseLimit3) {
			return _price.mul(148).div(97);
		} else if (_price < increaseLimit4) {
			return _price.mul(136).div(97);
		} else {
			return _price.mul(124).div(98);
		}
	}

	function calculateDevCut (uint256 _price) public view returns (uint256 _devCut) {
		if (_price < increaseLimit1) {
			return _price.mul(5).div(100);  
		} else if (_price < increaseLimit2) {
			return _price.mul(4).div(100);  
		} else if (_price < increaseLimit4) {
			return _price.mul(3).div(100);  
		} else {
			return _price.mul(2).div(100);  
		}
	}
 



 
 
 
 

	function getBalance(address _playerAddress)
		public
		view
		returns(uint256 pendingRefBonus_, uint256 pendingFromScore_, uint256 totalPending_, uint256 balanceReadyToWithdraw_, uint256 playerScore_, uint256 handicap_, uint256 dividendsScore_)
		{
			uint256 refbonus = pendingBalance[potVersion][_playerAddress];
			uint256 playerSc = playerScore[_playerAddress];
			uint256 playerHandicap = handicap[potVersion][_playerAddress];
			uint256 divs = playerSc.mul(dividendsScore.sub(playerHandicap)).div(HUGE);
			uint256 totalPending = refbonus.add(divs);
			uint256 ready = balanceToWithdraw[potVersion][_playerAddress];
			return (refbonus, divs, totalPending, ready, playerSc, playerHandicap, dividendsScore);				
		}


		
	function getOldBalance(uint256 _potVersion, address _playerAddress)
		public
		view
		returns(uint256 oldPendingRefBonus_, uint256 oldHandicap_, uint256 oldReadyToWithdraw_)
		{
			uint256 oldRefBonus = pendingBalance[_potVersion][_playerAddress];
			uint256 oldPlayerHandicap = handicap[_potVersion][_playerAddress];
			uint256 oldReady = balanceToWithdraw[_potVersion][_playerAddress];
			return (oldRefBonus, oldPlayerHandicap, oldReady);				
		}
		
		
		
   
	function confirmDividends() public onlyRealAddress {
		require(playerScore[msg.sender] > 0); 
		require (dividendsScore >= handicap[potVersion][msg.sender]);
		require (dividendsScore >= 0);
		
		address _playerAddress = msg.sender;
		uint256 playerSc = playerScore[_playerAddress];
		uint256 handicap_ = handicap[potVersion][_playerAddress];
		
		uint256 refbonus = pendingBalance[potVersion][_playerAddress];
		uint256 divs = playerSc.mul(dividendsScore.sub(handicap_)).div(HUGE);
		uint256 totalPending = refbonus.add(divs);	
						
		 
		pendingBalance[potVersion][_playerAddress] = 0;  
		handicap[potVersion][_playerAddress] = dividendsScore;
		
		 
		balanceToWithdraw[potVersion][_playerAddress] += totalPending;
		
		 
		emit ConfirmWithdraw(_playerAddress, refbonus, divs, totalPending, playerSc, handicap_);
		
	}


   	
	function withdraw() public onlyRealAddress {
		require(balanceOf(msg.sender) > 0);
		require(balanceToWithdraw[potVersion][msg.sender] > 0);
				
		address _playerAddress = msg.sender;
		
			if (lastWithdrawPotVersion != potVersion){
					lastWithdrawPotVersion = potVersion;
			}

        
         
		uint256 divToTransfer = balanceToWithdraw[potVersion][_playerAddress];
		balanceToWithdraw[potVersion][_playerAddress] = 0;
		
        _playerAddress.transfer(divToTransfer);
		
         
        emit Withdrawal(_playerAddress, divToTransfer, potVersion);
    }
	

	
   		
	function confirmDividendsFromPot() public {
		require(richestBuyer != address(0) && lastBuyer != address(0)) ;
		require(address(this).balance > 100000000);	 
		require(block.timestamp > timestampLimit);
		
		uint256 confirmation_TimeStamp = timestampLimit;
		potVersion ++;
		uint256 balance = address(this).balance;
		uint256 balanceQuarter = balance.div(4);
		dividendsScore = 0;  
		updateTimestampLimit();  
		balanceToWithdraw[potVersion][richestBuyer] = balanceQuarter;
		balanceToWithdraw[potVersion][lastBuyer] += balanceQuarter;  
		
		
		 
        emit ConfirmPotWithdraw(	
			 balance, 
			 richestBuyer, 
			 balanceToWithdraw[potVersion][richestBuyer],
			 lastBuyer,
			 balanceToWithdraw[potVersion][lastBuyer],
			 potVersion
		);
		
		emit PotWithdrawConstant(	
			 block.timestamp,
			 confirmation_TimeStamp,
			 dividendsScore,
			 potVersion,
			 lastWithdrawPotVersion
		);
		
	}


	
   	
	function withdrawAll() public onlyOwner {
		require((potVersion > lastWithdrawPotVersion.add(3) && dividendsScore == 0) || (address(this).balance < 100000001) );
		require (address(this).balance >0);
		
		potVersion ++;
		updateTimestampLimit();
		uint256 balance = address(this).balance;
		
		owner.transfer(balance);
		
         
        emit WithdrawOwner(potVersion, lastWithdrawPotVersion, balance);
    } 	

	
	
	
	
 
 
 

   
    function getReferrerOf(address player) public view returns (address) {
        return referrerOf[player];
    }

	
   
    function setReferrer(address newReferral, address referrer) internal {
		if (getReferrerOf(newReferral) == address(0x0) && newReferral != referrer && balanceOf(referrer) > 0 && playerScore[newReferral] == 0) {
			
			 
			 
				referrerOf[newReferral] = referrer;
        
			 
				emit SetReferrerEvent(newReferral, referrer);
		}
    }
	
	
	

   
	function payReferrer (address _oldOwner, uint256 _netProfit) internal returns (uint256 referralDivToPay) {
		address referrer_1 = referrerOf[_oldOwner];
		
		if (referrer_1 != 0x0) {
			referralDivToPay = _netProfit.mul(25).div(1000);
			pendingBalance[potVersion][referrer_1] += referralDivToPay;   
			address referrer_2 = referrerOf[referrer_1];
				
				if (referrer_2 != 0x0) {
						pendingBalance[potVersion][referrer_2] += referralDivToPay;   
						referralDivToPay += referralDivToPay;
				}
		}
			
		emit PayReferrerEvent(_oldOwner, referrer_1, referrer_2, referralDivToPay);
		
		return referralDivToPay;
		
	}
	
	
	

	
 
 
 

   
	function bonusPreviousOwner(uint256 _itemSoldId, uint256 _paidPrice, uint256 _bonusToDispatch) private {
		require(_bonusToDispatch < (_paidPrice.mul(5).div(100)));
		require(countryStructs[_itemSoldId].priceHistory > 0);

		CountryStruct storage c = countryStructs[_itemSoldId];
		uint256 countryScore = c.priceHistory;
		uint256 kBonus = _bonusToDispatch.mul(HUGE).div(countryScore);
		uint256 bonusDispatched = 0;
		  
		for (uint256 i = 0; i < c.itemToAddressArray.length && bonusDispatched < _bonusToDispatch ; i++) {
			address listedBonusPlayer = c.itemToAddressArray[i];
			uint256 playerBonusScore = itemHistory[_itemSoldId][listedBonusPlayer];
			uint256 bonusToGet = playerBonusScore.mul(kBonus).div(HUGE);
				
				if (bonusDispatched.add(bonusToGet) <= _bonusToDispatch) {
					pendingBalance[potVersion][listedBonusPlayer] += bonusToGet;
					bonusDispatched += bonusToGet;
					
					emitInfo(bonusToGet, playerBonusScore, listedBonusPlayer, pendingBalance[potVersion][listedBonusPlayer], _itemSoldId);
				}
		}  
			
		emit BonusConstant(_bonusToDispatch, bonusDispatched, _bonusToDispatch.sub(bonusDispatched), _itemSoldId, kBonus, countryScore);
	}


	
	function emitInfo(uint256 dividendsToG_, uint256 playerSc_, address player_, uint256 divsBalance_, uint256 itemId_) private {
		emit BonusDispatch(dividendsToG_, playerSc_, player_, divsBalance_, itemId_);
  
	}

  

   
	function updateScoreAndBalance(uint256 _paidPrice, uint256 _itemId, address _oldOwner, address _newOwner) internal {	
		uint256 _previousPaidPrice = previousPriceOfItem[_itemId];
		assert (_paidPrice > _previousPaidPrice);

		
		 
			uint256 scoreSubHandicap = dividendsScore.sub(handicap[potVersion][_oldOwner]);
			uint256 playerScore_ = playerScore[_oldOwner];
		
			 
				if (_oldOwner != owner && scoreSubHandicap >= 0 && playerScore_ > _previousPaidPrice) {
					pendingBalance[potVersion][_oldOwner] += playerScore_.mul(scoreSubHandicap).div(HUGE);
					playerScore[_oldOwner] -= _previousPaidPrice;  
					handicap[potVersion][_oldOwner] = dividendsScore;  
				}

				
		 
			scoreSubHandicap = dividendsScore.sub(handicap[potVersion][_newOwner]);  
			playerScore_ = playerScore[_newOwner];  
				
			 
				if (scoreSubHandicap >= 0) {
					pendingBalance[potVersion][_newOwner] += playerScore_.mul(scoreSubHandicap).div(HUGE);
					playerScore[_newOwner] += _paidPrice.mul(2);  
					handicap[potVersion][_newOwner] = dividendsScore;  
				}

				
		 
				if (playerScore[_newOwner] > playerScore[richestBuyer]) {
					richestBuyer = _newOwner;
					
					emit newRichest(_newOwner, playerScore[_newOwner], block.timestamp, block.number);
				}		

				
		 
			lastBuyer = _newOwner;
		
	}
		

		

   
	function updateWorldScore(uint256 _countryId, uint256 _price) internal	{
		worldScore += _price.mul(2).sub(previousPriceOfItem[_countryId]);
	}
		

		
    
	function updateTimestampLimit() internal {
		timestampLimit = block.timestamp.add(604800).add(potVersion.mul(28800));  
	}


	
    
	function excessRefund(address _newOwner, uint256 _price) internal {		
		uint256 excess = msg.value.sub(_price);
			if (excess > 0) {
				_newOwner.transfer(excess);
			}
	}	
	

	


 
 
 
 
	
	function buy (uint256 _itemId, address referrerAddress) payable public onlyRealAddress {
		require(priceOf(_itemId) > 0);
		require(ownerOf(_itemId) != address(0));
		require(msg.value >= priceOf(_itemId));
		require(ownerOf(_itemId) != msg.sender);
		require(!isContract(msg.sender));
		require(msg.sender != owner);
		require(block.timestamp < timestampLimit || block.timestamp > timestampLimit.add(3600));
		
		
		address oldOwner = ownerOf(_itemId);
		address newOwner = msg.sender;
		uint256 price = priceOf(_itemId);

		
		
	
	 
	 
	 
		
		setReferrer(newOwner, referrerAddress);
		
	

	
	 
	 
	 
		
		 
		 
		 
		 
		 
		 
			updateScoreAndBalance(price, _itemId, oldOwner, newOwner);
			
		 
		 
			updateWorldScore(_itemId, price);
		
		 
		 
			updateTimestampLimit();
	


	
	 
	 
	 
	
		 
		 
		 
		 
		 
		 
			
		 
			uint256 devCut_ = calculateDevCut(price);
			
		 
			uint256 netProfit = price.sub(devCut_).sub(previousPriceOfItem[_itemId]);
		
		 
			uint256 dividendsCut_ = netProfit.mul(30).div(100);
			
		 
		 
			uint256 oldOwnerReward = price.sub(devCut_).sub(netProfit.mul(35).div(100));

		 
		 
			uint256 refCut = payReferrer(oldOwner, netProfit);
			dividendsCut_ -= refCut;
		
	

	
	 
	 
	 
	 
		
		 
		 
	
		 
			if (price > countryStructs[_itemId].startingPrice && dividendsCut_ > 1000000 && worldScore > 0) {
				
				 
					bonusPreviousOwner(_itemId, price, dividendsCut_.mul(20).div(100));
				
				 
					dividendsCut_ = dividendsCut_.mul(80).div(100); 
			} 
	
				 
		
		 
		 
			if (worldScore > 0) {  
				
				dividendsScore += HUGE.mul(dividendsCut_).div(worldScore);
			}
	

	
	 
	 
	 
	
		 
		 
		 
			updateEntity(_itemId, newOwner, price);
			itemHistory[_itemId][newOwner] += price;

	

	
	 
	 
	 
	
		 
			previousPriceOfItem[_itemId] = price;
			priceOfItem[_itemId] = nextPriceOf(_itemId);
	

	
	 
	 
	 

		 
		 
		 
			oldOwner.transfer(oldOwnerReward);
			owner.transfer(devCut_);
			
		 
			_transfer(oldOwner, newOwner, _itemId);  	
	
		 
			emit Bought(_itemId, newOwner, price);
			emit Sold(_itemId, oldOwner, price);	
		
	

	
	 
	 
	 
	
		 
			excessRefund(newOwner, price);
		

	
	 
		emit DivsDispatch(dividendsCut_, dividendsScore, _itemId, price, worldScore);		
		
 
  
	}
  
 
  
 
 
 

	function itemHistoryOfPlayer(uint256 _itemId, address _owner) public view returns (uint256 _valueAddressOne) {
		return itemHistory[_itemId][_owner];
	}
  
  
	function implementsERC721() public view returns (bool _implements) {
		return erc721Enabled;
	}

	
	function name() public pure returns (string _name) {
		return "SuperCountries";
	}

	
	function symbol() public pure returns (string _symbol) {
		return "SUP";
	}

	
	function totalSupply() public view returns (uint256 _totalSupply) {
		return listedItems.length;
	}

	
	function balanceOf (address _owner) public view returns (uint256 _balance) {
		uint256 counter = 0;

			for (uint256 i = 0; i < listedItems.length; i++) {
				if (ownerOf(listedItems[i]) == _owner) {
					counter++;
				}
			}

		return counter;
	}


	function ownerOf (uint256 _itemId) public view returns (address _owner) {
		return ownerOfItem[_itemId];
	}

	
	function tokensOf (address _owner) public view returns (uint256[] _tokenIds) {
		uint256[] memory items = new uint256[](balanceOf(_owner));
		uint256 itemCounter = 0;
			
			for (uint256 i = 0; i < listedItems.length; i++) {
				if (ownerOf(listedItems[i]) == _owner) {
					items[itemCounter] = listedItems[i];
					itemCounter += 1;
				}
			}

		return items;
	}


	function tokenExists (uint256 _itemId) public view returns (bool _exists) {
		return priceOf(_itemId) > 0;
	}

	
	function approvedFor(uint256 _itemId) public view returns (address _approved) {
		return approvedOfItem[_itemId];
	}


	function approve(address _to, uint256 _itemId) onlyERC721() public {
		require(msg.sender != _to);
		require(tokenExists(_itemId));
		require(ownerOf(_itemId) == msg.sender);

		if (_to == 0) {
			if (approvedOfItem[_itemId] != 0) {
				delete approvedOfItem[_itemId];
				emit Approval(msg.sender, 0, _itemId);
			}
		}
		else {
			approvedOfItem[_itemId] = _to;
			emit Approval(msg.sender, _to, _itemId);
		}
	  }

	  
   
	function transfer(address _to, uint256 _itemId) onlyERC721() public {
		require(msg.sender == ownerOf(_itemId));
		_transfer(msg.sender, _to, _itemId);
	}

	
	function transferFrom(address _from, address _to, uint256 _itemId) onlyERC721() public {
		require(approvedFor(_itemId) == msg.sender);
		_transfer(_from, _to, _itemId);
	}

	
	function _transfer(address _from, address _to, uint256 _itemId) internal {
		require(tokenExists(_itemId));
		require(ownerOf(_itemId) == _from);
		require(_to != address(0));
		require(_to != address(this));

		ownerOfItem[_itemId] = _to;
		approvedOfItem[_itemId] = 0;

		emit Transfer(_from, _to, _itemId);
	}


	
 
 
 

	function gameInfo() public view returns (address richestPlayer_, address lastBuyer_, uint256 thisBalance_, uint256 lastWithdrawPotVersion_, uint256 worldScore_, uint256 potVersion_,  uint256 timestampLimit_) {
		
		return (richestBuyer, lastBuyer, address(this).balance, lastWithdrawPotVersion, worldScore, potVersion, timestampLimit);
	}
	
	
	function priceOf(uint256 _itemId) public view returns (uint256 _price) {
		return priceOfItem[_itemId];
	}
	
	
	function nextPriceOf(uint256 _itemId) public view returns (uint256 _nextPrice) {
		return calculateNextPrice(priceOf(_itemId));
	}

	
	function allOf(uint256 _itemId) external view returns (address _owner, uint256 _price, uint256 previous_, uint256 _nextPrice) {
		return (ownerOf(_itemId), priceOf(_itemId), previousPriceOfItem[_itemId], nextPriceOf(_itemId));
	}


 
	function isContract(address addr) internal view returns (bool) {
		uint size;
		assembly { size := extcodesize(addr) }  
		return size > 0;
	}




 
 
 

   

    function() payable public
    {    }


}
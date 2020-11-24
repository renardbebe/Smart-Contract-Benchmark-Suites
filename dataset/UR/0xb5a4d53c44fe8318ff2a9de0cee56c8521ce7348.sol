 

pragma solidity 0.4.19;


contract Admin {
    address public godAddress;
    address public managerAddress;
    address public bursarAddress;

     
    modifier requireGod() {
        require(msg.sender == godAddress);
        _;
    }

    modifier requireManager() {
        require(msg.sender == managerAddress);
        _;
    }

    modifier requireAdmin() {
        require(msg.sender == managerAddress || msg.sender == godAddress);
        _;
    }

    modifier requireBursar() {
        require(msg.sender == bursarAddress);
      _;
    }

     
     
    function setGod(address _newGod) external requireGod {
        require(_newGod != address(0));

        godAddress = _newGod;
    }

     
     
    function setManager(address _newManager) external requireGod {
        require(_newManager != address(0));

        managerAddress = _newManager;
    }

     
     
    function setBursar(address _newBursar) external requireGod {
        require(_newBursar != address(0));

        bursarAddress = _newBursar;
    }

     
    function destroy() external requireGod {
        selfdestruct(godAddress);
    }
}



contract Pausable is Admin {
    bool public paused = false;

    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    modifier whenPaused {
        require(paused);
        _;
    }

    function pause() external requireAdmin whenNotPaused {
        paused = true;
    }

    function unpause() external requireGod whenPaused {
        paused = false;
    }
}


contract CryptoFamousBase is Pausable {

   
  struct Card {
         
        uint8 socialNetworkType;
         
        uint64 socialId;
         
        address claimer;
         
        uint16 claimNonce;
         
        uint8 reserved1;
  }

  struct SaleInfo {
      uint128 timestamp;
      uint128 price;
  }

}


contract CryptoFamousOwnership is CryptoFamousBase {
   
   
  event CardCreated(uint256 indexed cardId, uint8 socialNetworkType, uint64 socialId, address claimer, address indexed owner);

   
   
  Card[] public allCards;

   
  mapping (uint8 => mapping (uint64 => uint256)) private socialIdentityMappings;

   
  function socialIdentityToCardId(uint256 _socialNetworkType, uint256 _socialId) public view returns (uint256 cardId) {
    uint8 _socialNetworkType8 = uint8(_socialNetworkType);
    require(_socialNetworkType == uint256(_socialNetworkType8));

    uint64 _socialId64 = uint64(_socialId);
    require(_socialId == uint256(_socialId64));

    cardId = socialIdentityMappings[_socialNetworkType8][_socialId64];
    return cardId;
  }

  mapping (uint8 => mapping (address => uint256)) private claimerAddressToCardIdMappings;

   
  function lookUpClaimerAddress(uint256 _socialNetworkType, address _claimerAddress) public view returns (uint256 cardId) {
    uint8 _socialNetworkType8 = uint8(_socialNetworkType);
    require(_socialNetworkType == uint256(_socialNetworkType8));

    cardId = claimerAddressToCardIdMappings[_socialNetworkType8][_claimerAddress];
    return cardId;
  }

   
  mapping (uint256 => uint128) public cardIdToFirstClaimTimestamp;

   
  mapping (uint256 => address) public cardIdToOwner;

   
  mapping (address => uint256) internal ownerAddressToCardCount;

  function _changeOwnership(address _from, address _to, uint256 _cardId) internal whenNotPaused {
      ownerAddressToCardCount[_to]++;
      cardIdToOwner[_cardId] = _to;

      if (_from != address(0)) {
          ownerAddressToCardCount[_from]--;
      }
  }

  function _recordFirstClaimTimestamp(uint256 _cardId) internal {
    cardIdToFirstClaimTimestamp[_cardId] = uint128(now);  
  }

  function _createCard(
      uint256 _socialNetworkType,
      uint256 _socialId,
      address _owner,
      address _claimer
  )
      internal
      whenNotPaused
      returns (uint256)
  {
      uint8 _socialNetworkType8 = uint8(_socialNetworkType);
      require(_socialNetworkType == uint256(_socialNetworkType8));

      uint64 _socialId64 = uint64(_socialId);
      require(_socialId == uint256(_socialId64));

      uint16 claimNonce = 0;
      if (_claimer != address(0)) {
        claimNonce = 1;
      }

      Card memory _card = Card({
          socialNetworkType: _socialNetworkType8,
          socialId: _socialId64,
          claimer: _claimer,
          claimNonce: claimNonce,
          reserved1: 0
      });
      uint256 newCardId = allCards.push(_card) - 1;
      socialIdentityMappings[_socialNetworkType8][_socialId64] = newCardId;

      if (_claimer != address(0)) {
        claimerAddressToCardIdMappings[_socialNetworkType8][_claimer] = newCardId;
        _recordFirstClaimTimestamp(newCardId);
      }

       
      CardCreated(
          newCardId,
          _socialNetworkType8,
          _socialId64,
          _claimer,
          _owner
      );

      _changeOwnership(0, _owner, newCardId);

      return newCardId;
  }

   
  function totalNumberOfCards() public view returns (uint) {
      return allCards.length - 1;
  }

   
   
  function tokensOfOwner(address _owner) external view returns(uint256[] ownerTokens) {
      uint256 tokenCount = ownerAddressToCardCount[_owner];

      if (tokenCount == 0) {
          return new uint256[](0);
      }

      uint256[] memory result = new uint256[](tokenCount);
      uint256 total = totalNumberOfCards();
      uint256 resultIndex = 0;

      uint256 cardId;

      for (cardId = 1; cardId <= total; cardId++) {
          if (cardIdToOwner[cardId] == _owner) {
              result[resultIndex] = cardId;
              resultIndex++;
          }
      }

      return result;
  }
}


contract CryptoFamousStorage is CryptoFamousOwnership {
  function CryptoFamousStorage() public {
      godAddress = msg.sender;
      managerAddress = msg.sender;
      bursarAddress = msg.sender;

       
      _createCard(0, 0, address(0), address(0));
  }

  function() external payable {
       
      FallbackEtherReceived(msg.sender, msg.value);
  }

  event FallbackEtherReceived(address from, uint256 value);

   
  address public authorizedLogicContractAddress;
  modifier requireAuthorizedLogicContract() {
      require(msg.sender == authorizedLogicContractAddress);
      _;
  }

   
  mapping (uint256 => SaleInfo) public cardIdToSaleInfo;

   
  mapping (uint256 => uint256) public cardIdToStashedPayout;
   
  uint256 public totalStashedPayouts;

   
   
   
  mapping (address => uint256) public addressToFailedOldOwnerTransferAmount;
   
  uint256 public totalFailedOldOwnerTransferAmounts;

   
  mapping (uint256 => string) public cardIdToPerkText;

  function authorized_setCardPerkText(uint256 _cardId, string _perkText) external requireAuthorizedLogicContract {
    cardIdToPerkText[_cardId] = _perkText;
  }

  function setAuthorizedLogicContractAddress(address _newAuthorizedLogicContractAddress) external requireGod {
    authorizedLogicContractAddress = _newAuthorizedLogicContractAddress;
  }

  function authorized_changeOwnership(address _from, address _to, uint256 _cardId) external requireAuthorizedLogicContract {
    _changeOwnership(_from, _to, _cardId);
  }

  function authorized_createCard(uint256 _socialNetworkType, uint256 _socialId, address _owner, address _claimer) external requireAuthorizedLogicContract returns (uint256) {
    return _createCard(_socialNetworkType, _socialId, _owner, _claimer);
  }

  function authorized_updateSaleInfo(uint256 _cardId, uint256 _sentValue) external requireAuthorizedLogicContract {
    cardIdToSaleInfo[_cardId] = SaleInfo(uint128(now), uint128(_sentValue));  
  }

  function authorized_updateCardClaimerAddress(uint256 _cardId, address _claimerAddress) external requireAuthorizedLogicContract {
    Card storage card = allCards[_cardId];
    if (card.claimer == address(0)) {
      _recordFirstClaimTimestamp(_cardId);
    }
    card.claimer = _claimerAddress;
    card.claimNonce += 1;
  }

  function authorized_updateCardReserved1(uint256 _cardId, uint8 _reserved) external requireAuthorizedLogicContract {
    uint8 _reserved8 = uint8(_reserved);
    require(_reserved == uint256(_reserved8));

    Card storage card = allCards[_cardId];
    card.reserved1 = _reserved8;
  }

  function authorized_triggerStashedPayoutTransfer(uint256 _cardId) external requireAuthorizedLogicContract {
    Card storage card = allCards[_cardId];
    address claimerAddress = card.claimer;

    require(claimerAddress != address(0));

    uint256 stashedPayout = cardIdToStashedPayout[_cardId];

    require(stashedPayout > 0);

    cardIdToStashedPayout[_cardId] = 0;
    totalStashedPayouts -= stashedPayout;

    claimerAddress.transfer(stashedPayout);
  }

  function authorized_recordStashedPayout(uint256 _cardId) external payable requireAuthorizedLogicContract {
      cardIdToStashedPayout[_cardId] += msg.value;
      totalStashedPayouts += msg.value;
  }

  function authorized_recordFailedOldOwnerTransfer(address _oldOwner) external payable requireAuthorizedLogicContract {
      addressToFailedOldOwnerTransferAmount[_oldOwner] += msg.value;
      totalFailedOldOwnerTransferAmounts += msg.value;
  }

   
  function authorized_recordPlatformFee() external payable requireAuthorizedLogicContract {
       
  }

   
  function netContractBalance() public view returns (uint256 balance) {
    balance = this.balance - totalStashedPayouts - totalFailedOldOwnerTransferAmounts;
    return balance;
  }

   
  function bursarPayOutNetContractBalance(address _to) external requireBursar {
      uint256 payout = netContractBalance();

      if (_to == address(0)) {
          bursarAddress.transfer(payout);
      } else {
          _to.transfer(payout);
      }
  }

   
   
  function withdrawFailedOldOwnerTransferAmount() external whenNotPaused {
      uint256 failedTransferAmount = addressToFailedOldOwnerTransferAmount[msg.sender];

      require(failedTransferAmount > 0);

      addressToFailedOldOwnerTransferAmount[msg.sender] = 0;
      totalFailedOldOwnerTransferAmounts -= failedTransferAmount;

      msg.sender.transfer(failedTransferAmount);
  }
}


contract CryptoFamous is CryptoFamousBase {
    function CryptoFamous(address _storageContractAddress) public {
        godAddress = msg.sender;
        managerAddress = msg.sender;
        bursarAddress = msg.sender;
        verifierAddress = msg.sender;
        storageContract = CryptoFamousStorage(_storageContractAddress);
    }

    function() external payable {
         
        FallbackEtherReceived(msg.sender, msg.value);
    }

    event FallbackEtherReceived(address from, uint256 value);

    event EconomyParametersUpdated(uint128 _newMinCardPrice, uint128 _newInitialCardPrice, uint128 _newPurchasePremiumRate, uint128 _newHourlyValueDecayRate, uint128 _newOwnerTakeShare, uint128 _newCardTakeShare, uint128 _newPlatformFeeRate);

     
    event CardStealCompleted(uint256 indexed cardId, address claimer, uint128 oldPrice, uint128 sentValue, address indexed prevOwner, address indexed newOwner, uint128 totalOwnerPayout, uint128 totalCardPayout);

     
    event CardClaimCompleted(uint256 indexed cardId, address previousClaimer, address newClaimer, address indexed owner);

     
    event CardPerkTextUpdated(uint256 indexed cardId, string newPerkText);

     
    CryptoFamousStorage public storageContract;

    uint16 private constant TWITTER = 1;

     
    uint128 public MIN_CARD_PRICE = 0.01 ether;
    function _setMinCardPrice(uint128 _newMinCardPrice) private {
        MIN_CARD_PRICE = _newMinCardPrice;
    }

     
    uint128 public INITIAL_CARD_PRICE = 0.01 ether;
    function _setInitialCardPrice(uint128 _newInitialCardPrice) private {
        INITIAL_CARD_PRICE = _newInitialCardPrice;
    }

     
    uint128 public PURCHASE_PREMIUM_RATE = 10000;  
    function _setPurchasePremiumRate(uint128 _newPurchasePremiumRate) private {
        PURCHASE_PREMIUM_RATE = _newPurchasePremiumRate;
    }

     
    uint128 public HOURLY_VALUE_DECAY_RATE = 21;  
    function _setHourlyValueDecayRate(uint128 _newHourlyValueDecayRate) private {
        HOURLY_VALUE_DECAY_RATE = _newHourlyValueDecayRate;
    }

     
    uint128 public OWNER_TAKE_SHARE = 5000;  
    uint128 public CARD_TAKE_SHARE = 5000;  
     

    function _setProfitSharingParameters(uint128 _newOwnerTakeShare, uint128 _newCardTakeShare) private {
      require(_newOwnerTakeShare + _newCardTakeShare == 10000);

      OWNER_TAKE_SHARE = _newOwnerTakeShare;
      CARD_TAKE_SHARE = _newCardTakeShare;
    }

     
    uint128 public PLATFORM_FEE_RATE = 600;  
    function _setPlatformFeeRate(uint128 _newPlatformFeeRate) private {
        require(_newPlatformFeeRate < 10000);
        PLATFORM_FEE_RATE = _newPlatformFeeRate;
    }

     
    function setEconomyParameters(uint128 _newMinCardPrice, uint128 _newInitialCardPrice, uint128 _newPurchasePremiumRate, uint128 _newHourlyValueDecayRate, uint128 _newOwnerTakeShare, uint128 _newCardTakeShare, uint128 _newPlatformFeeRate) external requireAdmin {
        _setMinCardPrice(_newMinCardPrice);
        _setInitialCardPrice(_newInitialCardPrice);
        _setPurchasePremiumRate(_newPurchasePremiumRate);
        _setHourlyValueDecayRate(_newHourlyValueDecayRate);
        _setProfitSharingParameters(_newOwnerTakeShare, _newCardTakeShare);
        _setPlatformFeeRate(_newPlatformFeeRate);
        EconomyParametersUpdated(_newMinCardPrice, _newInitialCardPrice, _newPurchasePremiumRate, _newHourlyValueDecayRate, _newOwnerTakeShare, _newCardTakeShare, _newPlatformFeeRate);
    }

    address public verifierAddress;
     
     
     
    function setVerifier(address _newVerifier) external requireGod {
        require(_newVerifier != address(0));

        verifierAddress = _newVerifier;
    }

     
    function prefixed(bytes32 hash) private pure returns (bytes32) {
        return keccak256("\x19Ethereum Signed Message:\n32", hash);
    }

    function claimTwitterId(uint256 _twitterId, address _claimerAddress, uint8 _v, bytes32 _r, bytes32 _s) external whenNotPaused returns (uint256) {
      return _claimSocialNetworkIdentity(TWITTER, _twitterId, _claimerAddress, _v, _r, _s);
    }

    function claimSocialNetworkIdentity(uint256 _socialNetworkType, uint256 _socialId, address _claimerAddress, uint8 _v, bytes32 _r, bytes32 _s) external whenNotPaused returns (uint256) {
      return _claimSocialNetworkIdentity(_socialNetworkType, _socialId, _claimerAddress, _v, _r, _s);
    }

     
     
     
    function _claimSocialNetworkIdentity(uint256 _socialNetworkType, uint256 _socialId, address _claimerAddress, uint8 _v, bytes32 _r, bytes32 _s) private returns (uint256) {
      uint8 _socialNetworkType8 = uint8(_socialNetworkType);
      require(_socialNetworkType == uint256(_socialNetworkType8));

      uint64 _socialId64 = uint64(_socialId);
      require(_socialId == uint256(_socialId64));

      uint256 cardId = storageContract.socialIdentityToCardId(_socialNetworkType8, _socialId64);

      uint16 claimNonce = 0;
      if (cardId != 0) {
        (, , , claimNonce, ) = storageContract.allCards(cardId);
      }

      bytes32 prefixedAndHashedAgain = prefixed(
        keccak256(
          _socialNetworkType, _socialId, _claimerAddress, uint256(claimNonce)
        )
      );

      address recoveredSignerAddress = ecrecover(prefixedAndHashedAgain, _v, _r, _s);
      require(recoveredSignerAddress == verifierAddress);

      if (cardId == 0) {
        return storageContract.authorized_createCard(_socialNetworkType8, _socialId64, _claimerAddress, _claimerAddress);
      } else {
        _claimExistingCard(cardId, _claimerAddress);
        return cardId;
      }
    }

    function _claimExistingCard(uint256 _cardId, address _claimerAddress) private {
        address previousClaimer;
        (, , previousClaimer, ,) = storageContract.allCards(_cardId);
        address owner = storageContract.cardIdToOwner(_cardId);

        _updateCardClaimerAddress(_cardId, _claimerAddress);

        CardClaimCompleted(_cardId, previousClaimer, _claimerAddress, owner);

        uint256 stashedPayout = storageContract.cardIdToStashedPayout(_cardId);
        if (stashedPayout > 0) {
          _triggerStashedPayoutTransfer(_cardId);
        }
    }

     
     
    function setCardPerkText(uint256 _cardId, string _perkText) external whenNotPaused {
      address cardClaimer;
      (, , cardClaimer, , ) = storageContract.allCards(_cardId);

      require(cardClaimer == msg.sender);

      require(bytes(_perkText).length <= 280);

      _updateCardPerkText(_cardId, _perkText);
      CardPerkTextUpdated(_cardId, _perkText);
    }

    function stealCardWithTwitterId(uint256 _twitterId) external payable whenNotPaused {
      _stealCardWithSocialIdentity(TWITTER, _twitterId);
    }

    function stealCardWithSocialIdentity(uint256 _socialNetworkType, uint256 _socialId) external payable whenNotPaused {
      _stealCardWithSocialIdentity(_socialNetworkType, _socialId);
    }

    function _stealCardWithSocialIdentity(uint256 _socialNetworkType, uint256 _socialId) private {
       
      require(_socialId != 0);

      uint8 _socialNetworkType8 = uint8(_socialNetworkType);
      require(_socialNetworkType == uint256(_socialNetworkType8));

      uint64 _socialId64 = uint64(_socialId);
      require(_socialId == uint256(_socialId64));

      uint256 cardId = storageContract.socialIdentityToCardId(_socialNetworkType8, _socialId64);
      if (cardId == 0) {
        cardId = storageContract.authorized_createCard(_socialNetworkType8, _socialId64, address(0), address(0));
        _stealCardWithId(cardId);
      } else {
        _stealCardWithId(cardId);
      }
    }

    function stealCardWithId(uint256 _cardId) external payable whenNotPaused {
       
      require(_cardId != 0);

      _stealCardWithId(_cardId);
    }

    function claimTwitterIdIfNeededThenStealCardWithTwitterId(
      uint256 _twitterIdToClaim,
      address _claimerAddress,
      uint8 _v,
      bytes32 _r,
      bytes32 _s,
      uint256 _twitterIdToSteal
      ) external payable whenNotPaused returns (uint256) {
          return _claimIfNeededThenSteal(TWITTER, _twitterIdToClaim, _claimerAddress, _v, _r, _s, TWITTER, _twitterIdToSteal);
      }

    function claimIfNeededThenSteal(
      uint256 _socialNetworkTypeToClaim,
      uint256 _socialIdToClaim,
      address _claimerAddress,
      uint8 _v,
      bytes32 _r,
      bytes32 _s,
      uint256 _socialNetworkTypeToSteal,
      uint256 _socialIdToSteal
      ) external payable whenNotPaused returns (uint256) {
          return _claimIfNeededThenSteal(_socialNetworkTypeToClaim, _socialIdToClaim, _claimerAddress, _v, _r, _s, _socialNetworkTypeToSteal, _socialIdToSteal);
    }

     
     
    function _claimIfNeededThenSteal(
      uint256 _socialNetworkTypeToClaim,
      uint256 _socialIdToClaim,
      address _claimerAddress,
      uint8 _v,
      bytes32 _r,
      bytes32 _s,
      uint256 _socialNetworkTypeToSteal,
      uint256 _socialIdToSteal
      ) private returns (uint256) {
        uint8 _socialNetworkTypeToClaim8 = uint8(_socialNetworkTypeToClaim);
        require(_socialNetworkTypeToClaim == uint256(_socialNetworkTypeToClaim8));

        uint64 _socialIdToClaim64 = uint64(_socialIdToClaim);
        require(_socialIdToClaim == uint256(_socialIdToClaim64));

        uint256 claimedCardId = storageContract.socialIdentityToCardId(_socialNetworkTypeToClaim8, _socialIdToClaim64);

        address currentClaimer = address(0);
        if (claimedCardId != 0) {
          (, , currentClaimer, , ) = storageContract.allCards(claimedCardId);
        }

        if (currentClaimer == address(0)) {
          claimedCardId = _claimSocialNetworkIdentity(_socialNetworkTypeToClaim, _socialIdToClaim, _claimerAddress, _v, _r, _s);
        }

        _stealCardWithSocialIdentity(_socialNetworkTypeToSteal, _socialIdToSteal);

        return claimedCardId;
    }

    function _stealCardWithId(uint256 _cardId) private {  
         
        uint64 twitterId;
        address cardClaimer;
        (, twitterId, cardClaimer, , ) = storageContract.allCards(_cardId);
        require(twitterId != 0);

        address oldOwner = storageContract.cardIdToOwner(_cardId);
        address newOwner = msg.sender;

         
        require(oldOwner != newOwner);

        require(newOwner != address(0));

         
        uint128 sentValue = uint128(msg.value);
        require(uint256(sentValue) == msg.value);

        uint128 lastPrice;
        uint128 decayedPrice;
        uint128 profit;
         
         
        uint128 totalOwnerPayout;
        uint128 totalCardPayout;
        uint128 platformFee;

        (lastPrice,
        decayedPrice,
        profit,
        ,  
        ,  
        totalOwnerPayout,
        totalCardPayout,
        platformFee
        ) = currentPriceInfoOf(_cardId, sentValue);

        require(sentValue >= decayedPrice);

        _updateSaleInfo(_cardId, sentValue);
        storageContract.authorized_changeOwnership(oldOwner, newOwner, _cardId);

        CardStealCompleted(_cardId, cardClaimer, lastPrice, sentValue, oldOwner, newOwner, totalOwnerPayout, totalCardPayout);

        if (platformFee > 0) {
          _recordPlatformFee(platformFee);
        }

        if (totalCardPayout > 0) {
            if (cardClaimer == address(0)) {
                _recordStashedPayout(_cardId, totalCardPayout);
            } else {
                 
                if (!cardClaimer.send(totalCardPayout)) {
                  _recordStashedPayout(_cardId, totalCardPayout);
                }
            }
        }

        if (totalOwnerPayout > 0) {
          if (oldOwner != address(0)) {
               
              if (!oldOwner.send(totalOwnerPayout)) {  
                _recordFailedOldOwnerTransfer(oldOwner, totalOwnerPayout);
              }
          }
        }
    }

    function currentPriceInfoOf(uint256 _cardId, uint256 _sentGrossPrice) public view returns (
        uint128 lastPrice,
        uint128 decayedPrice,
        uint128 profit,
        uint128 ownerProfitTake,
        uint128 cardProfitTake,
        uint128 totalOwnerPayout,
        uint128 totalCardPayout,
        uint128 platformFee
    ) {
        uint128 lastTimestamp;
        (lastTimestamp, lastPrice) = storageContract.cardIdToSaleInfo(_cardId);

        decayedPrice = decayedPriceFrom(lastPrice, lastTimestamp);
        require(_sentGrossPrice >= decayedPrice);

        platformFee = uint128(_sentGrossPrice) * PLATFORM_FEE_RATE / 10000;
        uint128 sentNetPrice = uint128(_sentGrossPrice) - platformFee;

        if (sentNetPrice > lastPrice) {
            profit = sentNetPrice - lastPrice;
            ownerProfitTake = profit * OWNER_TAKE_SHARE / 10000;
            cardProfitTake = profit * CARD_TAKE_SHARE / 10000;
        } else {
            profit = 0;
            ownerProfitTake = 0;
            cardProfitTake = 0;
        }

        totalOwnerPayout = ownerProfitTake + (sentNetPrice - profit);
        totalCardPayout = cardProfitTake;

         
        address currentOwner = storageContract.cardIdToOwner(_cardId);
        if (currentOwner == address(0)) {
          totalCardPayout = totalCardPayout + totalOwnerPayout;
          totalOwnerPayout = 0;
        }

        require(_sentGrossPrice >= (totalCardPayout + totalOwnerPayout + platformFee));

        return (lastPrice, decayedPrice, profit, ownerProfitTake, cardProfitTake, totalOwnerPayout, totalCardPayout, platformFee);
    }

    function decayedPriceFrom(uint256 _lastPrice, uint256 _lastTimestamp) public view returns (uint128 decayedPrice) {
        if (_lastTimestamp == 0) {
            decayedPrice = INITIAL_CARD_PRICE;
        } else {
            uint128 startPrice = uint128(_lastPrice) + (uint128(_lastPrice) * PURCHASE_PREMIUM_RATE / 10000);
            require(startPrice >= uint128(_lastPrice));

            uint128 secondsLapsed;
            if (now > _lastTimestamp) {  
                secondsLapsed = uint128(now) - uint128(_lastTimestamp);  
            } else {
                secondsLapsed = 0;
            }
            uint128 hoursLapsed = secondsLapsed / 1 hours;
            uint128 totalDecay = (hoursLapsed * (startPrice * HOURLY_VALUE_DECAY_RATE / 10000));

            if (totalDecay > startPrice) {
                decayedPrice = MIN_CARD_PRICE;
            } else {
                decayedPrice = startPrice - totalDecay;
                if (decayedPrice < MIN_CARD_PRICE) {
                  decayedPrice = MIN_CARD_PRICE;
                }
            }
        }

        return decayedPrice;
    }

     

    function _updateSaleInfo(uint256 _cardId, uint256 _sentValue) private {
        storageContract.authorized_updateSaleInfo(_cardId, _sentValue);
    }

    function _updateCardClaimerAddress(uint256 _cardId, address _claimerAddress) private {
        storageContract.authorized_updateCardClaimerAddress(_cardId, _claimerAddress);
    }

    function _recordStashedPayout(uint256 _cardId, uint256 _stashedPayout) private {
        storageContract.authorized_recordStashedPayout.value(_stashedPayout)(_cardId);
    }

    function _triggerStashedPayoutTransfer(uint256 _cardId) private {
        storageContract.authorized_triggerStashedPayoutTransfer(_cardId);
    }

    function _recordFailedOldOwnerTransfer(address _oldOwner, uint256 _oldOwnerPayout) private {
        storageContract.authorized_recordFailedOldOwnerTransfer.value(_oldOwnerPayout)(_oldOwner);
    }

    function _recordPlatformFee(uint256 _platformFee) private {
        storageContract.authorized_recordPlatformFee.value(_platformFee)();
    }

    function _updateCardPerkText(uint256 _cardId, string _perkText) private {
        storageContract.authorized_setCardPerkText(_cardId, _perkText);
    }

     

     
    function decayedPriceOfTwitterId(uint256 _twitterId) public view returns (uint128) {
      return decayedPriceOfSocialIdentity(TWITTER, _twitterId);
    }

    function decayedPriceOfSocialIdentity(uint256 _socialNetworkType, uint256 _socialId) public view returns (uint128) {
      uint8 _socialNetworkType8 = uint8(_socialNetworkType);
      require(_socialNetworkType == uint256(_socialNetworkType8));

      uint64 _socialId64 = uint64(_socialId);
      require(_socialId == uint256(_socialId64));

      uint256 cardId = storageContract.socialIdentityToCardId(_socialNetworkType8, _socialId64);

      return decayedPriceOfCard(cardId);
    }

    function decayedPriceOfCard(uint256 _cardId) public view returns (uint128) {
      uint128 lastTimestamp;
      uint128 lastPrice;
      (lastTimestamp, lastPrice) = storageContract.cardIdToSaleInfo(_cardId);
      return decayedPriceFrom(lastPrice, lastTimestamp);
    }

    function ownerOfTwitterId(uint256 _twitterId) public view returns (address) {
      return ownerOfSocialIdentity(TWITTER, _twitterId);
    }

    function ownerOfSocialIdentity(uint256 _socialNetworkType, uint256 _socialId) public view returns (address) {
      uint8 _socialNetworkType8 = uint8(_socialNetworkType);
      require(_socialNetworkType == uint256(_socialNetworkType8));

      uint64 _socialId64 = uint64(_socialId);
      require(_socialId == uint256(_socialId64));

      uint256 cardId = storageContract.socialIdentityToCardId(_socialNetworkType8, _socialId64);

      address ownerAddress = storageContract.cardIdToOwner(cardId);
      return ownerAddress;
    }

    function claimerOfTwitterId(uint256 _twitterId) public view returns (address) {
      return claimerOfSocialIdentity(TWITTER, _twitterId);
    }

    function claimerOfSocialIdentity(uint256 _socialNetworkType, uint256 _socialId) public view returns (address) {
      uint8 _socialNetworkType8 = uint8(_socialNetworkType);
      require(_socialNetworkType == uint256(_socialNetworkType8));

      uint64 _socialId64 = uint64(_socialId);
      require(_socialId == uint256(_socialId64));

      uint256 cardId = storageContract.socialIdentityToCardId(_socialNetworkType8, _socialId64);

      address claimerAddress;
      (, , claimerAddress, ,) = storageContract.allCards(cardId);

      return claimerAddress;
    }

    function twitterIdOfClaimerAddress(address _claimerAddress) public view returns (uint64) {
      return socialIdentityOfClaimerAddress(TWITTER, _claimerAddress);
    }

    function socialIdentityOfClaimerAddress(uint256 _socialNetworkType, address _claimerAddress) public view returns (uint64) {
      uint256 cardId = storageContract.lookUpClaimerAddress(_socialNetworkType, _claimerAddress);

      uint64 socialId;
      (, socialId, , ,) = storageContract.allCards(cardId);
      return socialId;
    }

    function withdrawContractBalance(address _to) external requireBursar {
      if (_to == address(0)) {
          bursarAddress.transfer(this.balance);
      } else {
          _to.transfer(this.balance);
      }
    }
}
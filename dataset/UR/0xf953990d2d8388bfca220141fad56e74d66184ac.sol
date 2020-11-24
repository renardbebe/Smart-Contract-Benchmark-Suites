 

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
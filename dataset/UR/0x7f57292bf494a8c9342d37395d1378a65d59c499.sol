 

pragma solidity ^0.4.18;

contract WeiCards {

     
     
    struct LeaseCard {
      uint id;
      address tenant;
      uint price;
      uint untilBlock;
      string title;
      string url;
      string image;
    }

     
    struct cardDetails {
      uint8 id;
      uint price;
      uint priceLease;  
      uint leaseDuration;  
      bool availableBuy;
      bool availableLease;
      uint[] leaseList;
      mapping(uint => LeaseCard) leaseCardStructs;
    }

     
    struct Card {
      uint8 id;
      address owner;
      string title;
      string url;
      string image;
      bool nsfw;
    }
    
     
    mapping(address => uint) pendingWithdrawals;

    mapping(uint8 => Card) cardStructs;  
    uint8[] cardList;  

    mapping(uint8 => cardDetails) cardDetailsStructs;  
    uint8[] cardDetailsList;  

     
    uint initialCardPrice = 1 ether;

     
    uint ownerBuyCut = 100;
     
    uint giveEthCut = 1000;

     
    address contractOwner;
     
    address giveEthAddress = 0x5ADF43DD006c6C36506e2b2DFA352E60002d22Dc;
    
     
    function WeiCards(address _contractOwner) public {
      require(_contractOwner != address(0));
      contractOwner = _contractOwner;
    }

    modifier onlyContractOwner()
    {
        
        require(msg.sender == contractOwner);
        _;
    }

    modifier onlyCardOwner(uint8 cardId)
    {
        
        require(msg.sender == cardStructs[cardId].owner);
        _;
    }

    modifier onlyValidCard(uint8 cardId)
    {
        
        require(cardId >= 1 && cardId <= 100);
        _;
    }
    
     
    function getCards() public view
        returns(uint8[])
    {
      return cardList;
    }

     
    function getCardsDetails() public view
        returns(uint8[])
    {
      return cardDetailsList;
    }

     
    function getCardDetails(uint8 cardId) view public
        onlyValidCard(cardId)
        returns (uint8 id, uint price, uint priceLease, uint leaseDuration, bool availableBuy, bool availableLease)
    {
        bool _buyAvailability;
        if (cardDetailsStructs[cardId].id == 0 || cardDetailsStructs[cardId].availableBuy) {
            _buyAvailability = true;
        }

        return(
          cardDetailsStructs[cardId].id,
          cardDetailsStructs[cardId].price,
          cardDetailsStructs[cardId].priceLease,
          cardDetailsStructs[cardId].leaseDuration,
          _buyAvailability,
          cardDetailsStructs[cardId].availableLease
        );
    }

     
    function getCard(uint8 cardId) view public
        onlyValidCard(cardId)
        returns (uint8 id, address owner, string title, string url, string image, bool nsfw)
    {
        return(
          cardStructs[cardId].id,
          cardStructs[cardId].owner,
          cardStructs[cardId].title,
          cardStructs[cardId].url,
          cardStructs[cardId].image,
          cardStructs[cardId].nsfw
        );
    }
    
     
     
    function initialBuyCard(uint8 cardId, string title, string url, string image) public
        onlyValidCard(cardId)
        payable
        returns (bool success)
    {
         
        uint price = computeInitialPrice(cardId);
        require(msg.value >= price);
         
         
        require(cardStructs[cardId].owner == address(0));

         
        _fillCardStruct(cardId, msg.sender, title, url, image);
         
        cardStructs[cardId].nsfw = false;
         
         _applyShare(contractOwner, giveEthAddress, giveEthCut);
         
        _initCardDetails(cardId, price);
         
        cardList.push(cardId);
        return true;
    }

     
     
    function buyCard(uint8 cardId, string title, string url, string image) public
        onlyValidCard(cardId)
        payable
        returns (bool success)
    {
         
         
        require(cardStructs[cardId].owner != address(0));
         
        require(cardDetailsStructs[cardId].availableBuy);
         
        uint price = cardDetailsStructs[cardId].price;
        require(msg.value >= price);
        
        address previousOwner = cardStructs[cardId].owner;
         
        _applyShare(previousOwner, contractOwner, ownerBuyCut);
         
        _fillCardStruct(cardId, msg.sender, title, url, image);
         
        cardStructs[cardId].nsfw = false;
         
        cardDetailsStructs[cardId].availableBuy = false;
        return true;
    }

     
    function editCard(uint8 cardId, string title, string url, string image) public
        onlyValidCard(cardId)
        onlyCardOwner(cardId)
        returns (bool success)
    {
         
        _fillCardStruct(cardId, msg.sender, title, url, image);
         
        return true;
    }

     
    function sellCard(uint8 cardId, uint price) public
        onlyValidCard(cardId)
        onlyCardOwner(cardId)
        returns (bool success)
    {
        cardDetailsStructs[cardId].price = price;
        cardDetailsStructs[cardId].availableBuy = true;
        return true;
    }

     
    function cancelSellCard(uint8 cardId) public
        onlyValidCard(cardId)
        onlyCardOwner(cardId)
        returns (bool success)
    {
        cardDetailsStructs[cardId].availableBuy = false;
        return true;
    }

     
    function setLeaseCard(uint8 cardId, uint priceLease, uint leaseDuration) public
        onlyValidCard(cardId)
        onlyCardOwner(cardId)
        returns (bool success)
    {
         
         
        require(!cardDetailsStructs[cardId].availableBuy);
         
        uint _lastLeaseId = getCardLeaseLength(cardId);
        uint _until = cardDetailsStructs[cardId].leaseCardStructs[_lastLeaseId].untilBlock;
        require(_until < block.number);

        cardDetailsStructs[cardId].priceLease = priceLease;
        cardDetailsStructs[cardId].availableLease = true;
        cardDetailsStructs[cardId].leaseDuration = leaseDuration;
        return true;
    }

     
     
    function cancelLeaseOffer(uint8 cardId) public
        onlyValidCard(cardId)
        onlyCardOwner(cardId)
        returns (bool success)
    {
        cardDetailsStructs[cardId].availableLease = false;
        return true;
    }

     
    function leaseCard(uint8 cardId, string title, string url, string image) public
        onlyValidCard(cardId)
        payable
        returns (bool success)
    {
         
        require(cardDetailsStructs[cardId].availableLease);
         
        uint price = cardDetailsStructs[cardId].priceLease;
        uint leaseDuration = cardDetailsStructs[cardId].leaseDuration;
        uint totalAmount = price * leaseDuration;
         
        require(msg.value >= totalAmount);
         
        uint leaseId = getCardLeaseLength(cardId) + 1;
         
        uint untilBlock = block.number + leaseDuration;
         
        address _cardOwner = cardStructs[cardId].owner;
        _applyShare(_cardOwner, contractOwner, ownerBuyCut);
         
        cardDetailsStructs[cardId].leaseCardStructs[leaseId].id = leaseId;
        cardDetailsStructs[cardId].leaseCardStructs[leaseId].tenant = msg.sender;
        cardDetailsStructs[cardId].leaseCardStructs[leaseId].price = totalAmount;
        cardDetailsStructs[cardId].leaseCardStructs[leaseId].untilBlock = untilBlock;
        cardDetailsStructs[cardId].leaseCardStructs[leaseId].title = title;
        cardDetailsStructs[cardId].leaseCardStructs[leaseId].url = url;
        cardDetailsStructs[cardId].leaseCardStructs[leaseId].image = image;
         
        cardDetailsStructs[cardId].availableLease = false;
         
        cardDetailsStructs[cardId].leaseList.push(leaseId);
        return true;
    }

     
    function getLastLease(uint8 cardId) public constant
        returns(uint leaseIndex, address tenant, uint untilBlock, string title, string url, string image)
    {
        uint _leaseIndex = getCardLeaseLength(cardId);
        return getLease(cardId, _leaseIndex);
    }

     
    function getLease(uint8 cardId, uint leaseId) public constant
        returns(uint leaseIndex, address tenant, uint untilBlock, string title, string url, string image)
    {
        return(
            cardDetailsStructs[cardId].leaseCardStructs[leaseId].id,
            cardDetailsStructs[cardId].leaseCardStructs[leaseId].tenant,
            cardDetailsStructs[cardId].leaseCardStructs[leaseId].untilBlock,
            cardDetailsStructs[cardId].leaseCardStructs[leaseId].title,
            cardDetailsStructs[cardId].leaseCardStructs[leaseId].url,
            cardDetailsStructs[cardId].leaseCardStructs[leaseId].image
        );
    }

     
    function getCardLeaseLength(uint8 cardId) public constant
        returns(uint cardLeasesCount)
    {
        return(cardDetailsStructs[cardId].leaseList.length);
    }

     
    function transferCardOwnership(address to, uint8 cardId) public
      onlyCardOwner(cardId)
      returns (bool success)
    {
         
        cardStructs[cardId].owner = to;
        return true;
    }
    
     
    function getBalance() public view
      returns (uint amount)
    {
        return pendingWithdrawals[msg.sender];
    }
    
     
    function withdraw() public
        returns (bool) 
    {
        uint amount = pendingWithdrawals[msg.sender];
         
         
        pendingWithdrawals[msg.sender] = 0;
        msg.sender.transfer(amount);
        return true;
    }
    
     
    function computeInitialPrice(uint8 cardId) public view
        onlyValidCard(cardId)
        returns (uint price)
    {
         
        return initialCardPrice - ((initialCardPrice / 100) * (uint256(cardId) - 1));
    }

     
    function setNSFW(uint8 cardId, bool flag) public
        onlyValidCard(cardId)
        onlyContractOwner()
        returns (bool success)
    {
        cardStructs[cardId].nsfw = flag;
        return true;
    }

     
    function _fillCardStruct(uint8 _cardId, address _owner, string _title, string _url, string _image) internal
        returns (bool success)
    {
        cardStructs[_cardId].owner = _owner;
        cardStructs[_cardId].title = _title;
        cardStructs[_cardId].url = _url;
        cardStructs[_cardId].image = _image;
        return true;
    }

     
    function _initCardDetails(uint8 cardId, uint price) internal
        returns (bool success)
    {
         
        cardDetailsStructs[cardId].id = cardId;
        cardDetailsStructs[cardId].price = price;
        cardDetailsStructs[cardId].availableBuy = false;
        cardDetailsStructs[cardId].availableLease = false;
        cardDetailsList.push(cardId);
        return true;
    }

     
    function _applyShare(address _seller, address _auctioneer, uint _cut) internal
        returns (bool success)
    {
         
        uint256 auctioneerCut = _computeCut(msg.value, _cut);
        uint256 sellerProceeds = msg.value - auctioneerCut;
         
        pendingWithdrawals[_seller] += sellerProceeds;
         
        pendingWithdrawals[_auctioneer] += auctioneerCut;
        return true;
    }

     
    function _computeCut(uint256 _price, uint256 _cut) internal pure
        returns (uint256)
    {
        return _price * _cut / 10000;
    }
}
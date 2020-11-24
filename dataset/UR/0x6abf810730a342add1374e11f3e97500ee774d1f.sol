 

pragma solidity ^0.4.18;

contract BCFBase {

    address public owner;
    address public editor;

    bool public paused = false;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyEditor() {
        require(msg.sender == editor);
        _;
    }

    function setOwner(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        owner = newOwner;
    }

    function setEditor(address newEditor) public onlyOwner {
        require(newEditor != address(0));
        editor = newEditor;
    }
    
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
    }
    
    function unpause() onlyOwner whenPaused public {
        paused = false;
    }
}

contract ERC721 {

     
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

     
    function totalSupply() public view returns (uint256 total);
    function balanceOf(address _owner) public view returns (uint256 balance);
    function ownerOf(uint256 _tokenId) public view returns (address owner);
    function approve(address _to, uint256 _tokenId) public;
    function getApproved(uint _tokenId) public view returns (address approved);
    function transferFrom(address _from, address _to, uint256 _tokenId) public;
    function transfer(address _to, uint256 _tokenId) public;
    function implementsERC721() public pure returns (bool);

     
     
     
     
     
}

contract BCFData is BCFBase, ERC721 {

     
    string public constant NAME = "BlockchainFootball";
    string public constant SYMBOL = "BCF";

    struct Player {

         
        uint8 overall;
        uint8 pace;
        uint8 shooting;
        uint8 passing;
        uint8 dribbling;
        uint8 defending;
        uint8 physical;
        uint8 form;  

         
        uint8 level;  
        bytes position;  
        string name;  
    }
    
    struct PlayerCard {
        uint playerId;  
        address owner;
        address approvedForTransfer;
        bool isFirstGeneration;
    }
    
     
    Player[] public players;  
    PlayerCard[] public playerCards;

     
    mapping(address => uint[]) internal ownerToCardsOwned;
    mapping(uint => uint) internal cardIdToOwnerArrayIndex;

     
    mapping(uint => uint8[]) public playerIdToExtendedAttributes;  

     
     
     
    function implementsERC721() public pure returns (bool) {
        return true;
    }

    function totalSupply() public view returns (uint) {
        return playerCards.length;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return ownerToCardsOwned[_owner].length;
    }

    function getApproved(uint _tokenId) public view returns (address approved) {
        approved = playerCards[_tokenId].approvedForTransfer;
    }

    function ownerOf(uint256 _tokenId) public view returns (address _owner) {
        _owner = playerCards[_tokenId].owner;
        require(_owner != address(0));
    }

    function approve(address _to, uint256 _tokenId) public whenNotPaused {
        require(ownsPlayerCard(msg.sender, _tokenId));
        approveForTransferTo(_to, _tokenId);
        Approval(msg.sender, _to, _tokenId);
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) public whenNotPaused {
        require(_to != address(0));
        require(_to != address(this));
        require(ownsPlayerCard(_from, _tokenId));
        require(isApprovedForTransferTo(_to, _tokenId));
        
         
        transferUnconditionally(_from, _to, _tokenId);
    }

    function transfer(address _to, uint256 _tokenId) public whenNotPaused {
        require(_to != address(0));
        require(_to != address(this));
        require(ownsPlayerCard(msg.sender, _tokenId));
    
         
        transferUnconditionally(msg.sender, _to, _tokenId);
    }

    function name() public pure returns (string) {
        return NAME;
    }

    function symbol() public pure returns (string) {
        return SYMBOL;
    }

    function tokensOfOwner(address _owner) external view returns (uint256[] tokenIds) {
        return ownerToCardsOwned[_owner];
    }

    function addCardToOwnersList(address _owner, uint _cardId) internal {
        ownerToCardsOwned[_owner].push(_cardId);
        cardIdToOwnerArrayIndex[_cardId] = ownerToCardsOwned[_owner].length - 1;
    }

    function removeCardFromOwnersList(address _owner, uint _cardId) internal {
        uint length = ownerToCardsOwned[_owner].length;
        uint index = cardIdToOwnerArrayIndex[_cardId];
        uint swapCard = ownerToCardsOwned[_owner][length - 1];

        ownerToCardsOwned[_owner][index] = swapCard;
        cardIdToOwnerArrayIndex[swapCard] = index;

        delete ownerToCardsOwned[_owner][length - 1];
        ownerToCardsOwned[_owner].length--;
    }

     
    function transferUnconditionally(address _from, address _to, uint _cardId) internal {
        
        if (_from != address(0)) {
             
            playerCards[_cardId].approvedForTransfer = address(0);
            removeCardFromOwnersList(_from, _cardId);
        }
        
        playerCards[_cardId].owner = _to;
        addCardToOwnersList(_to, _cardId);

        Transfer(_from, _to, _cardId);
    }

    function isApprovedForTransferTo(address _approved, uint _cardId) internal view returns (bool) {
        return playerCards[_cardId].approvedForTransfer == _approved;
    }

    function approveForTransferTo(address _approved, uint _cardId) internal {
        playerCards[_cardId].approvedForTransfer = _approved;
    }

    function ownsPlayerCard(address _cardOwner, uint _cardId) internal view returns (bool) {
        return playerCards[_cardId].owner == _cardOwner;
    }

    function setPlayerForm(uint _playerId, uint8 _form) external whenNotPaused onlyEditor {
        require(players[_playerId].form > 0);  
        require(_form > 0 && _form <= 200);  
        players[_playerId].form = _form;
    }

    function createPlayerCard(uint _playerId, address _newOwner, bool isFirstOfKind) internal returns (uint) {
        require(_playerId > 0);  
        Player storage _player = players[_playerId];
        require(_player.overall > 0);  

        PlayerCard memory _cardInstance = PlayerCard({
             playerId: _playerId,
             owner: _newOwner,
             approvedForTransfer: address(0),
             isFirstGeneration: isFirstOfKind
        });

        uint cardId = playerCards.push(_cardInstance) - 1;

         
        transferUnconditionally(0, _newOwner, cardId);

        return cardId;
    }

     
    function totalPlayerCount() public view returns(uint) {
        return players.length;
    }
    
    function getPlayerForCard(uint _cardId) 
        external
        view
        returns (
        uint8 _overall,
        uint8 _pace,
        uint8 _shooting,
        uint8 _passing,
        uint8 _dribbling,
        uint8 _defending,
        uint8 _physical,
        uint8 _level,
        bytes _position,
        string _fullName,
        uint8 _form
    ) {
         
        PlayerCard storage _playerCard = playerCards[_cardId];
        
         
         
        Player storage player = players[_playerCard.playerId];
        _overall = player.overall;
        _pace = player.pace;
        _shooting = player.shooting;
        _passing = player.passing;
        _dribbling = player.dribbling;
        _defending = player.defending;
        _physical = player.physical;
        _level = player.level;
        _position = player.position;
        _fullName = player.name;
        _form = player.form;
    }

    function isOwnerOfAllPlayerCards(uint256[] _cardIds, address owner) public view returns (bool) {
        require(owner != address(0));

         
        for (uint i = 0; i < _cardIds.length; i++) {
            if (!ownsPlayerCard(owner, _cardIds[i])) {
                return false;
            }
        }

         
        return true;
    }

     
    function setExtendedPlayerAttributesForPlayer(uint playerId, uint8[] attributes) external whenNotPaused onlyEditor {
        require(playerId > 0);
        playerIdToExtendedAttributes[playerId] = attributes;
    }

    function getExtendedAttributesForPlayer(uint playerId) public view returns (uint8[]) {
        require(playerId > 0);
        return playerIdToExtendedAttributes[playerId];
    }
}

contract BCFBuyMarket is BCFData {

    address public buyingEscrowAddress;
    bool public isBCFBuyMarket = true;

    function setBuyingEscrowAddress(address _address) external onlyOwner {
        buyingEscrowAddress = _address;
    }
    
    function createCardForAcquiredPlayer(uint playerId, address newOwner) public whenNotPaused returns (uint) {
        require(buyingEscrowAddress != address(0));
        require(newOwner != address(0));
        require(buyingEscrowAddress == msg.sender);
        
        uint cardId = createPlayerCard(playerId, newOwner, false);

        return cardId;
    }

    function createCardForAcquiredPlayers(uint[] playerIds, address newOwner) public whenNotPaused returns (uint[]) {
        require(buyingEscrowAddress != address(0));
        require(newOwner != address(0));
        require(buyingEscrowAddress == msg.sender);

        uint[] memory cardIds = new uint[](playerIds.length);

         
        for (uint i = 0; i < playerIds.length; i++) {
            uint cardId = createPlayerCard(playerIds[i], newOwner, false);
            cardIds[i] = cardId;
        }

        return cardIds;
    }
}

contract Ownable {

    address public owner;

     
    function Ownable() public {
        owner = msg.sender;
    }


     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
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

     
    modifier whenPaused {
        require(paused);
        _;
    }

     
    function pause() onlyOwner whenNotPaused public returns (bool) {
        paused = true;
        Pause();
        return true;
    }

     
    function unpause() onlyOwner whenPaused public returns (bool) {
        paused = false;
        Unpause();
        return true;
    }
}

contract BCFAuction is Pausable {

    struct CardAuction {
        address seller;
        uint128 startPrice;  
        uint128 endPrice;
        uint64 duration;
        uint64 startedAt;
    }

     
    ERC721 public dataStore;
    uint256 public auctioneerCut;

    mapping (uint256 => CardAuction) playerCardIdToAuction;

    event AuctionCreated(uint256 cardId, uint256 startPrice, uint256 endPrice, uint256 duration);
    event AuctionSuccessful(uint256 cardId, uint256 finalPrice, address winner);
    event AuctionCancelled(uint256 cardId);

    function BCFAuction(address dataStoreAddress, uint cutValue) public {
        require(cutValue <= 10000);  
        auctioneerCut = cutValue;

        ERC721 candidateDataStoreContract = ERC721(dataStoreAddress);
        require(candidateDataStoreContract.implementsERC721());
        dataStore = candidateDataStoreContract;
    }

    function withdrawBalance() external {
        address storageAddress = address(dataStore);
        require(msg.sender == owner || msg.sender == storageAddress);
        storageAddress.transfer(this.balance);
    }

    function createAuction(
        uint256 cardId, 
        uint256 startPrice, 
        uint256 endPrice, 
        uint256 duration, 
        address seller
    )
        external
        whenNotPaused
    {
        require(startPrice == uint256(uint128(startPrice)));
        require(endPrice == uint256(uint128(endPrice)));
        require(duration == uint256(uint64(duration)));
        require(seller != address(0));
        require(address(dataStore) != address(0));
        require(msg.sender == address(dataStore));

        _escrow(seller, cardId);
        CardAuction memory auction = CardAuction(
            seller,
            uint128(startPrice),
            uint128(endPrice),
            uint64(duration),
            uint64(now)
        );
        _addAuction(cardId, auction);
    }

    function bid(uint256 cardId) external payable whenNotPaused {
        _bid(cardId, msg.value);  
        _transfer(msg.sender, cardId);
    }

    function cancelAuction(uint256 cardId) external {
        CardAuction storage auction = playerCardIdToAuction[cardId];
        require(isOnAuction(auction));
        address seller = auction.seller;
        require(msg.sender == seller);
        _cancelAuction(cardId, seller);
    }

    function getAuction(uint256 cardId) external view returns
    (
        address seller,
        uint256 startingPrice,
        uint256 endingPrice,
        uint256 duration,
        uint256 startedAt
    ) {
        CardAuction storage auction = playerCardIdToAuction[cardId];
        require(isOnAuction(auction));
        return (auction.seller, auction.startPrice, auction.endPrice, auction.duration, auction.startedAt);
    }

    function getCurrentPrice(uint256 cardId) external view returns (uint256) {
        CardAuction storage auction = playerCardIdToAuction[cardId];
        require(isOnAuction(auction));
        return currentPrice(auction);
    }

     
    function ownsPlayerCard(address cardOwner, uint256 cardId) internal view returns (bool) {
        return (dataStore.ownerOf(cardId) == cardOwner);
    }

    function _escrow(address owner, uint256 cardId) internal {
        dataStore.transferFrom(owner, this, cardId);
    }

    function _transfer(address receiver, uint256 cardId) internal {
        dataStore.transfer(receiver, cardId);
    }

    function _addAuction(uint256 cardId, CardAuction auction) internal {
        require(auction.duration >= 1 minutes && auction.duration <= 14 days);
        playerCardIdToAuction[cardId] = auction;
        AuctionCreated(cardId, auction.startPrice, auction.endPrice, auction.duration);
    }

    function _removeAuction(uint256 cardId) internal {
        delete playerCardIdToAuction[cardId];
    }

    function _cancelAuction(uint256 cardId, address seller) internal {
        _removeAuction(cardId);
        _transfer(seller, cardId);
        AuctionCancelled(cardId);
    }

    function isOnAuction(CardAuction storage auction) internal view returns (bool) {
        return (auction.startedAt > 0);
    }

    function _bid(uint256 cardId, uint256 bidAmount) internal returns (uint256) {
        CardAuction storage auction = playerCardIdToAuction[cardId];
        require(isOnAuction(auction));

        uint256 price = currentPrice(auction);
        require(bidAmount >= price);

        address seller = auction.seller;
        _removeAuction(cardId);

        if (price > 0) {
            uint256 handlerCut = calculateAuctioneerCut(price);
            uint256 sellerProceeds = price - handlerCut;
            seller.transfer(sellerProceeds);
        } 

        uint256 bidExcess = bidAmount - price;
        msg.sender.transfer(bidExcess);

        AuctionSuccessful(cardId, price, msg.sender);  

        return price;
    }

    function currentPrice(CardAuction storage auction) internal view returns (uint256) {
        uint256 secondsPassed = 0;
        if (now > auction.startedAt) {
            secondsPassed = now - auction.startedAt;
        }

        return calculateCurrentPrice(auction.startPrice, auction.endPrice, auction.duration, secondsPassed);
    }

    function calculateCurrentPrice(uint256 startPrice, uint256 endPrice, uint256 duration, uint256 secondsElapsed)
        internal
        pure
        returns (uint256)
    {
        if (secondsElapsed >= duration) {
            return endPrice;
        } 

        int256 totalPriceChange = int256(endPrice) - int256(startPrice);
        int256 currentPriceChange = totalPriceChange * int256(secondsElapsed) / int256(duration);
        int256 _currentPrice = int256(startPrice) + currentPriceChange;

        return uint256(_currentPrice);
    }

    function calculateAuctioneerCut(uint256 sellPrice) internal view returns (uint256) {
         
        uint finalCut = sellPrice * auctioneerCut / 10000;
        return finalCut;
    }    
}

contract BCFTransferMarket is BCFBuyMarket {

    BCFAuction public auctionAddress;

    function setAuctionAddress(address newAddress) public onlyOwner {
        require(newAddress != address(0));
        BCFAuction candidateContract = BCFAuction(newAddress);
        auctionAddress = candidateContract;
    }

    function createTransferAuction(
        uint playerCardId,
        uint startPrice,
        uint endPrice,
        uint duration
    )
        public
        whenNotPaused
    {
        require(auctionAddress != address(0));
        require(ownsPlayerCard(msg.sender, playerCardId));
        approveForTransferTo(auctionAddress, playerCardId);
        auctionAddress.createAuction(
            playerCardId,
            startPrice,
            endPrice,
            duration,
            msg.sender
        );
    }

    function withdrawAuctionBalance() external onlyOwner {
        auctionAddress.withdrawBalance();
    }
}

contract BCFSeeding is BCFTransferMarket {

    function createPlayer(
        uint8 _overall,
        uint8 _pace,
        uint8 _shooting,
        uint8 _passing,
        uint8 _dribbling,
        uint8 _defending,
        uint8 _physical,
        uint8 _level,
        bytes _position,
        string _fullName
    ) 
        internal 
        returns (uint) 
    {
        require(_overall > 0 && _overall < 100);
        require(_pace > 0 && _pace < 100);
        require(_shooting > 0 && _shooting < 100);
        require(_passing > 0 && _passing < 100);
        require(_dribbling > 0 && _dribbling < 100);
        require(_defending > 0 && _defending < 100);
        require(_physical > 0 && _physical < 100);
        require(_level > 0 && _level < 100);
        require(_position.length > 0);
        require(bytes(_fullName).length > 0);
        
        Player memory _playerInstance = Player({
            overall: _overall,
            pace: _pace,
            shooting: _shooting,
            passing: _passing,
            dribbling: _dribbling,
            defending: _defending,
            physical: _physical,
            form: 100,
            level: _level,
            position: _position,
            name: _fullName
        });

        return players.push(_playerInstance) - 1;
    }

    function createPlayerOnAuction(
        uint8 _overall,
        uint8 _pace,
        uint8 _shooting,
        uint8 _passing,
        uint8 _dribbling,
        uint8 _defending,
        uint8 _physical,
        uint8 _level,
        bytes _position,
        string _fullName,
        uint _startPrice
    ) 
        public whenNotPaused onlyEditor
        returns(uint)
    {
        uint playerId = createPlayer(
            _overall, 
            _pace, 
            _shooting, 
            _passing, 
            _dribbling,
            _defending,
            _physical,
            _level,
            _position,
            _fullName);

        uint cardId = createPlayerCard(playerId, address(this), true);
        approveForTransferTo(auctionAddress, cardId);

        auctionAddress.createAuction(
            cardId,  
            _startPrice,  
            1 finney,  
            7 days,  
            address(this)  
        );

        return cardId;
    }
    
    function createPlayerAndAssign(
        uint8 _overall,
        uint8 _pace,
        uint8 _shooting,
        uint8 _passing,
        uint8 _dribbling,
        uint8 _defending,
        uint8 _physical,
        uint8 _level,
        bytes _position,
        string _fullName,
        address assignee
    ) 
        public whenNotPaused onlyEditor
        returns(uint) 
    {
        require(assignee != address(0));
        
        uint playerId = createPlayer(
            _overall, 
            _pace, 
            _shooting, 
            _passing, 
            _dribbling,
            _defending,
            _physical,
            _level,
            _position,
            _fullName);

        uint cardId = createPlayerCard(playerId, assignee, true);

        return cardId;
    }
}

contract BCFMain is BCFSeeding {

    function BCFMain() public {
        owner = msg.sender;
        editor = msg.sender;
        paused = true;

         
        createPlayer(1, 4, 4, 2, 3, 5, 2, 11, "CAM", "Thiago Messi");
    }

    function() external payable {
        require(msg.sender == address(auctionAddress) || msg.sender == owner || msg.sender == buyingEscrowAddress);
    }

    function withdrawBalance() external onlyOwner {
        owner.transfer(this.balance);
    }
}
 

pragma solidity ^0.4.18;

 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() public {
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
    Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
}
 
 
contract ClockAuctionBase {

     
    struct Auction {
         
        address seller;
         
        uint128 startingPrice;
         
        uint128 endingPrice;
         
        uint64 duration;
         
         
        uint64 startedAt;
    }

     
    ERC721 public nonFungibleContract;

     
     
    uint256 public ownerCut;

     
    mapping (uint256 => Auction) tokenIdToAuction;

    event AuctionCreated(uint256 tokenId, uint256 startingPrice, uint256 endingPrice, uint256 duration);
    event AuctionSuccessful(uint256 tokenId, uint256 totalPrice, address winner);
    event AuctionCancelled(uint256 tokenId);

     
    function() external {}

     
     
    modifier canBeStoredWith64Bits(uint256 _value) {
        require(_value <= 18446744073709551615);
        _;
    }

    modifier canBeStoredWith128Bits(uint256 _value) {
        require(_value < 340282366920938463463374607431768211455);
        _;
    }

     
     
     
    function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return (nonFungibleContract.ownerOf(_tokenId) == _claimant);
    }

     
     
     
     
    function _escrow(address _owner, uint256 _tokenId) internal {
         
        nonFungibleContract.transferFrom(_owner, this, _tokenId);
    }

     
     
     
     
    function _transfer(address _receiver, uint256 _tokenId) internal {
         
        nonFungibleContract.transfer(_receiver, _tokenId);
    }

     
     
     
     
    function _addAuction(uint256 _tokenId, Auction _auction) internal {
         
         
        require(_auction.duration >= 1 minutes);

        tokenIdToAuction[_tokenId] = _auction;
        
        AuctionCreated(
            uint256(_tokenId),
            uint256(_auction.startingPrice),
            uint256(_auction.endingPrice),
            uint256(_auction.duration)
        );
    }

     
    function _cancelAuction(uint256 _tokenId, address _seller) internal {
        _removeAuction(_tokenId);
        _transfer(_seller, _tokenId);
        AuctionCancelled(_tokenId);
    }

     
     
    function _bid(uint256 _tokenId, uint256 _bidAmount)
        internal
        returns (uint256)
    {
         
        Auction storage auction = tokenIdToAuction[_tokenId];

         
         
         
         
        require(_isOnAuction(auction));

         
         
        uint256 price = _currentPrice(auction);
        require(_bidAmount >= price);

         
         
        address seller = auction.seller;

         
         
        _removeAuction(_tokenId);

         
        if (price > 0) {
             
             
             
            uint256 auctioneerCut = _computeCut(price);
            uint256 sellerProceeds = price - auctioneerCut;

             
             
             
             
             
             
             
             
            seller.transfer(sellerProceeds);
        }

         
        AuctionSuccessful(_tokenId, price, msg.sender);

        return price;
    }

     
     
    function _removeAuction(uint256 _tokenId) internal {
        delete tokenIdToAuction[_tokenId];
    }

     
     
    function _isOnAuction(Auction storage _auction) internal view returns (bool) {
        return (_auction.startedAt > 0);
    }

     
     
     
     
    function _currentPrice(Auction storage _auction)
        internal
        view
        returns (uint256)
    {
        uint256 secondsPassed = 0;
        
         
         
         
        if (now > _auction.startedAt) {
            secondsPassed = now - _auction.startedAt;
        }

        return _computeCurrentPrice(
            _auction.startingPrice,
            _auction.endingPrice,
            _auction.duration,
            secondsPassed
        );
    }

     
     
     
     
    function _computeCurrentPrice(
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration,
        uint256 _secondsPassed
    )
        internal
        pure
        returns (uint256)
    {
         
         
         
         
         
        if (_secondsPassed >= _duration) {
             
             
            return _endingPrice;
        } else {
             
             
            int256 totalPriceChange = int256(_endingPrice) - int256(_startingPrice);
            
             
             
             
            int256 currentPriceChange = totalPriceChange * int256(_secondsPassed) / int256(_duration);
            
             
             
            int256 currentPrice = int256(_startingPrice) + currentPriceChange;
            
            return uint256(currentPrice);
        }
    }

     
     
    function _computeCut(uint256 _price) internal view returns (uint256) {
         
         
         
         
         
        return _price * ownerCut / 10000;
    }

}


 
contract ClockAuction is Pausable, ClockAuctionBase {

     
     
     
     
     
     
    function ClockAuction(address _nftAddress, uint256 _cut) public {
        require(_cut <= 10000);
        ownerCut = _cut;
        
        ERC721 candidateContract = ERC721(_nftAddress);
        require(candidateContract.implementsERC721());
        nonFungibleContract = candidateContract;
    }

     
     
     
     
    function withdrawBalance() external {
        address nftAddress = address(nonFungibleContract);

        require(
            msg.sender == owner ||
            msg.sender == nftAddress
        );
        nftAddress.transfer(this.balance);
    }

     
     
     
     
     
     
     
    function createAuction(
        uint256 _tokenId,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration,
        address _seller
    )
        public
        whenNotPaused
        canBeStoredWith128Bits(_startingPrice)
        canBeStoredWith128Bits(_endingPrice)
        canBeStoredWith64Bits(_duration)
    {
        require(_owns(msg.sender, _tokenId));
        _escrow(msg.sender, _tokenId);
        Auction memory auction = Auction(
            _seller,
            uint128(_startingPrice),
            uint128(_endingPrice),
            uint64(_duration),
            uint64(now)
        );
        _addAuction(_tokenId, auction);
    }

     
     
     
    function bid(uint256 _tokenId)
        public
        payable
        whenNotPaused
    {
         
        _bid(_tokenId, msg.value);
        _transfer(msg.sender, _tokenId);
    }

     
     
     
     
     
    function cancelAuction(uint256 _tokenId)
        public
    {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        address seller = auction.seller;
        require(msg.sender == seller);
        _cancelAuction(_tokenId, seller);
    }

     
     
     
     
    function cancelAuctionWhenPaused(uint256 _tokenId)
        whenPaused
        onlyOwner
        public
    {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        _cancelAuction(_tokenId, auction.seller);
    }

     
     
    function getAuction(uint256 _tokenId)
        public
        view
        returns
    (
        address seller,
        uint256 startingPrice,
        uint256 endingPrice,
        uint256 duration,
        uint256 startedAt
    ) {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        return (
            auction.seller,
            auction.startingPrice,
            auction.endingPrice,
            auction.duration,
            auction.startedAt
        );
    }

     
     
    function getCurrentPrice(uint256 _tokenId)
        public
        view
        returns (uint256)
    {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        return _currentPrice(auction);
    }

}


 
contract SaleClockAuction is ClockAuction {

     
     
    bool public isSaleClockAuction = true;
    
     
    uint256 public gen0SaleCount;
    uint256[4] public lastGen0SalePrices;

     
    function SaleClockAuction(address _nftAddr, uint256 _cut) public
        ClockAuction(_nftAddr, _cut) {}

     
     
     
     
     
     
    function createAuction(
        uint256 _tokenId,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration,
        address _seller
    )
        public
        canBeStoredWith128Bits(_startingPrice)
        canBeStoredWith128Bits(_endingPrice)
        canBeStoredWith64Bits(_duration)
    {
        require(msg.sender == address(nonFungibleContract));
        _escrow(_seller, _tokenId);
        Auction memory auction = Auction(
            _seller,
            uint128(_startingPrice),
            uint128(_endingPrice),
            uint64(_duration),
            uint64(now)
        );
        _addAuction(_tokenId, auction);
    }

     
     
    function bid(uint256 _tokenId)
        public
        payable
    {
         
        address seller = tokenIdToAuction[_tokenId].seller;
        uint256 price = _bid(_tokenId, msg.value);
        _transfer(msg.sender, _tokenId);

         
        if (seller == address(nonFungibleContract)) {
             
            lastGen0SalePrices[gen0SaleCount % 4] = price;
            gen0SaleCount++;
        }
    }

    function averageGen0SalePrice() public view returns (uint256) {
        uint256 sum = 0;
        for (uint256 i = 0; i < 4; i++) {
            sum += lastGen0SalePrices[i];
        }
        return sum / 4;
    }

}


 
contract FighterAccessControl {
     
    event ContractUpgrade(address newContract);

    address public ceoAddress;
    address public cfoAddress;
    address public cooAddress;

     
    bool public paused = false;

    modifier onlyCEO() {
        require(msg.sender == ceoAddress);
        _;
    }

    modifier onlyCFO() {
        require(msg.sender == cfoAddress);
        _;
    }

    modifier onlyCOO() {
        require(msg.sender == cooAddress);
        _;
    }

    modifier onlyCLevel() {
        require(
            msg.sender == cooAddress ||
            msg.sender == ceoAddress ||
            msg.sender == cfoAddress
        );
        _;
    }

    function setCEO(address _newCEO) public onlyCEO {
        require(_newCEO != address(0));

        ceoAddress = _newCEO;
    }

    function setCFO(address _newCFO) public onlyCEO {
        require(_newCFO != address(0));

        cfoAddress = _newCFO;
    }

    function setCOO(address _newCOO) public onlyCEO {
        require(_newCOO != address(0));

        cooAddress = _newCOO;
    }

    function withdrawBalance() external onlyCFO {
        cfoAddress.transfer(this.balance);
    }


     

     
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

     
    modifier whenPaused {
        require(paused);
        _;
    }

    function pause() public onlyCLevel whenNotPaused {
        paused = true;
    }

    function unpause() public onlyCEO whenPaused {
         
        paused = false;
    }
}


 
contract FighterBase is FighterAccessControl {
     

    event FighterCreated(address indexed owner, uint256 fighterId, uint256 genes);

     
     
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

     

     
     
    struct Fighter {
         
         
        uint256 genes;

         
        uint64 prizeCooldownEndTime;

         
        uint64 battleCooldownEndTime;

         
        uint32 experience;

         
         
        uint16 prizeCooldownIndex;

        uint16 battlesFought;
        uint16 battlesWon;

         
         
        uint16 generation;

        uint8 dexterity;
        uint8 strength;
        uint8 vitality;
        uint8 luck;
    }

     

     
     
     
    Fighter[] fighters;

     
     
    mapping (uint256 => address) public fighterIndexToOwner;

     
     
    mapping (address => uint256) ownershipTokenCount;

     
     
    mapping (uint256 => address) public fighterIndexToApproved;
    
    function _transfer(address _from, address _to, uint256 _tokenId) internal {
         
         
        ownershipTokenCount[_to]++;
        fighterIndexToOwner[_tokenId] = _to;

        if (_from != address(0)) {
            ownershipTokenCount[_from]--;
            delete fighterIndexToApproved[_tokenId];
        }

        Transfer(_from, _to, _tokenId);
    }

     
    function _createFighter(
        uint16 _generation,
        uint256 _genes,
        uint8 _dexterity,
        uint8 _strength,
        uint8 _vitality,
        uint8 _luck,
        address _owner
    )
        internal
        returns (uint)
    {
        Fighter memory _fighter = Fighter({
            genes: _genes,
            prizeCooldownEndTime: 0,
            battleCooldownEndTime: 0,
            prizeCooldownIndex: 0,
            battlesFought: 0,
            battlesWon: 0,
            experience: 0,
            generation: _generation,
            dexterity: _dexterity,
            strength: _strength,
            vitality: _vitality,
            luck: _luck
        });
        uint256 newFighterId = fighters.push(_fighter) - 1;

        require(newFighterId <= 4294967295);

        FighterCreated(_owner, newFighterId, _fighter.genes);

        _transfer(0, _owner, newFighterId);

        return newFighterId;
    }
}


 
contract ERC721 {
    function implementsERC721() public pure returns (bool);
    function totalSupply() public view returns (uint256 total);
    function balanceOf(address _owner) public view returns (uint256 balance);
    function ownerOf(uint256 _tokenId) public view returns (address owner);
    function approve(address _to, uint256 _tokenId) public;
    function transferFrom(address _from, address _to, uint256 _tokenId) public;
    function transfer(address _to, uint256 _tokenId) public;
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

     
     
     
     
     
}

 
contract FighterOwnership is FighterBase, ERC721 {
    string public name = "CryptoFighters";
    string public symbol = "CF";

    function implementsERC721() public pure returns (bool)
    {
        return true;
    }
    
     
     
     
    function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return fighterIndexToOwner[_tokenId] == _claimant;
    }

     
     
     
    function _approvedFor(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return fighterIndexToApproved[_tokenId] == _claimant;
    }

     
     
     
    function _approve(uint256 _tokenId, address _approved) internal {
        fighterIndexToApproved[_tokenId] = _approved;
    }

     
     
     
     
     
     
    function rescueLostFighter(uint256 _fighterId, address _recipient) public onlyCOO whenNotPaused {
        require(_owns(this, _fighterId));
        _transfer(this, _recipient, _fighterId);
    }

     
     
    function balanceOf(address _owner) public view returns (uint256 count) {
        return ownershipTokenCount[_owner];
    }

     
     
     
     
     
    function transfer(
        address _to,
        uint256 _tokenId
    )
        public
        whenNotPaused
    {
        require(_to != address(0));
        require(_owns(msg.sender, _tokenId));

        _transfer(msg.sender, _to, _tokenId);
    }

     
     
     
     
     
    function approve(
        address _to,
        uint256 _tokenId
    )
        public
        whenNotPaused
    {
        require(_owns(msg.sender, _tokenId));

        _approve(_tokenId, _to);

        Approval(msg.sender, _to, _tokenId);
    }

     
     
     
     
     
     
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    )
        public
        whenNotPaused
    {
        require(_approvedFor(msg.sender, _tokenId));
        require(_owns(_from, _tokenId));

        _transfer(_from, _to, _tokenId);
    }

    function totalSupply() public view returns (uint) {
        return fighters.length - 1;
    }

    function ownerOf(uint256 _tokenId)
        public
        view
        returns (address owner)
    {
        owner = fighterIndexToOwner[_tokenId];

        require(owner != address(0));
    }

     
     
     
     
     
     
     
     
     
    function tokensOfOwnerByIndex(address _owner, uint256 _index)
        external
        view
        returns (uint256 tokenId)
    {
        uint256 count = 0;
        for (uint256 i = 1; i <= totalSupply(); i++) {
            if (fighterIndexToOwner[i] == _owner) {
                if (count == _index) {
                    return i;
                } else {
                    count++;
                }
            }
        }
        revert();
    }
}


 
 
 
 
 
contract FighterBattle is FighterOwnership {
    event FighterUpdated(uint256 fighterId);
    
     
    address public battleContractAddress;

     
    bool public battleContractAddressCanBeUpdated = true;
    
    function setBattleAddress(address _address) public onlyCEO {
        require(battleContractAddressCanBeUpdated == true);

        battleContractAddress = _address;
    }

    function foreverBlockBattleAddressUpdate() public onlyCEO {
        battleContractAddressCanBeUpdated = false;
    }
    
    modifier onlyBattleContract() {
        require(msg.sender == battleContractAddress);
        _;
    }
    
    function createPrizeFighter(
        uint16 _generation,
        uint256 _genes,
        uint8 _dexterity,
        uint8 _strength,
        uint8 _vitality,
        uint8 _luck,
        address _owner
    ) public onlyBattleContract {
        require(_generation > 0);
        
        _createFighter(_generation, _genes, _dexterity, _strength, _vitality, _luck, _owner);
    }
    
     
    
     
     
     
     
    function updateFighter(
        uint256 _fighterId,
        uint8 _dexterity,
        uint8 _strength,
        uint8 _vitality,
        uint8 _luck,
        uint32 _experience,
        uint64 _prizeCooldownEndTime,
        uint16 _prizeCooldownIndex,
        uint64 _battleCooldownEndTime,
        uint16 _battlesFought,
        uint16 _battlesWon
    )
        public onlyBattleContract
    {
        Fighter storage fighter = fighters[_fighterId];
        
        fighter.dexterity = _dexterity;
        fighter.strength = _strength;
        fighter.vitality = _vitality;
        fighter.luck = _luck;
        fighter.experience = _experience;
        
        fighter.prizeCooldownEndTime = _prizeCooldownEndTime;
        fighter.prizeCooldownIndex = _prizeCooldownIndex;
        fighter.battleCooldownEndTime = _battleCooldownEndTime;
        fighter.battlesFought = _battlesFought;
        fighter.battlesWon = _battlesWon;
        
        FighterUpdated(_fighterId);
    }
    
    function updateFighterStats(
        uint256 _fighterId,
        uint8 _dexterity,
        uint8 _strength,
        uint8 _vitality,
        uint8 _luck,
        uint32 _experience
    )
        public onlyBattleContract
    {
        Fighter storage fighter = fighters[_fighterId];
        
        fighter.dexterity = _dexterity;
        fighter.strength = _strength;
        fighter.vitality = _vitality;
        fighter.luck = _luck;
        fighter.experience = _experience;
        
        FighterUpdated(_fighterId);
    }
    
    function updateFighterBattleStats(
        uint256 _fighterId,
        uint64 _prizeCooldownEndTime,
        uint16 _prizeCooldownIndex,
        uint64 _battleCooldownEndTime,
        uint16 _battlesFought,
        uint16 _battlesWon
    )
        public onlyBattleContract
    {
        Fighter storage fighter = fighters[_fighterId];
        
        fighter.prizeCooldownEndTime = _prizeCooldownEndTime;
        fighter.prizeCooldownIndex = _prizeCooldownIndex;
        fighter.battleCooldownEndTime = _battleCooldownEndTime;
        fighter.battlesFought = _battlesFought;
        fighter.battlesWon = _battlesWon;
        
        FighterUpdated(_fighterId);
    }
    
    function updateDexterity(uint256 _fighterId, uint8 _dexterity) public onlyBattleContract {
        fighters[_fighterId].dexterity = _dexterity;
        FighterUpdated(_fighterId);
    }
    
    function updateStrength(uint256 _fighterId, uint8 _strength) public onlyBattleContract {
        fighters[_fighterId].strength = _strength;
        FighterUpdated(_fighterId);
    }
    
    function updateVitality(uint256 _fighterId, uint8 _vitality) public onlyBattleContract {
        fighters[_fighterId].vitality = _vitality;
        FighterUpdated(_fighterId);
    }
    
    function updateLuck(uint256 _fighterId, uint8 _luck) public onlyBattleContract {
        fighters[_fighterId].luck = _luck;
        FighterUpdated(_fighterId);
    }
    
    function updateExperience(uint256 _fighterId, uint32 _experience) public onlyBattleContract {
        fighters[_fighterId].experience = _experience;
        FighterUpdated(_fighterId);
    }
}

 
 
 
contract FighterAuction is FighterBattle {
    SaleClockAuction public saleAuction;

    function setSaleAuctionAddress(address _address) public onlyCEO {
        SaleClockAuction candidateContract = SaleClockAuction(_address);

        require(candidateContract.isSaleClockAuction());

        saleAuction = candidateContract;
    }

    function createSaleAuction(
        uint256 _fighterId,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration
    )
        public
        whenNotPaused
    {
         
         
         
        require(_owns(msg.sender, _fighterId));
        _approve(_fighterId, saleAuction);
         
         
        saleAuction.createAuction(
            _fighterId,
            _startingPrice,
            _endingPrice,
            _duration,
            msg.sender
        );
    }

     
     
     
    function withdrawAuctionBalances() external onlyCOO {
        saleAuction.withdrawBalance();
    }
}


 
contract FighterMinting is FighterAuction {

     
    uint256 public promoCreationLimit = 5000;
    uint256 public gen0CreationLimit = 25000;

     
    uint256 public gen0StartingPrice = 500 finney;
    uint256 public gen0EndingPrice = 10 finney;
    uint256 public gen0AuctionDuration = 1 days;

     
    uint256 public promoCreatedCount;
    uint256 public gen0CreatedCount;

     
    function createPromoFighter(
        uint256 _genes,
        uint8 _dexterity,
        uint8 _strength,
        uint8 _vitality,
        uint8 _luck,
        address _owner
    ) public onlyCOO {
        if (_owner == address(0)) {
             _owner = cooAddress;
        }
        require(promoCreatedCount < promoCreationLimit);
        require(gen0CreatedCount < gen0CreationLimit);

        promoCreatedCount++;
        gen0CreatedCount++;
        
        _createFighter(0, _genes, _dexterity, _strength, _vitality, _luck, _owner);
    }

     
     
    function createGen0Auction(
        uint256 _genes,
        uint8 _dexterity,
        uint8 _strength,
        uint8 _vitality,
        uint8 _luck
    ) public onlyCOO {
        require(gen0CreatedCount < gen0CreationLimit);

        uint256 fighterId = _createFighter(0, _genes, _dexterity, _strength, _vitality, _luck, address(this));
        
        _approve(fighterId, saleAuction);

        saleAuction.createAuction(
            fighterId,
            _computeNextGen0Price(),
            gen0EndingPrice,
            gen0AuctionDuration,
            address(this)
        );

        gen0CreatedCount++;
    }

     
     
    function _computeNextGen0Price() internal view returns (uint256) {
        uint256 avePrice = saleAuction.averageGen0SalePrice();

         
        require(avePrice < 340282366920938463463374607431768211455);

        uint256 nextPrice = avePrice + (avePrice / 2);

         
        if (nextPrice < gen0StartingPrice) {
            nextPrice = gen0StartingPrice;
        }

        return nextPrice;
    }
}


 
 
contract FighterCore is FighterMinting {

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     

     
    address public newContractAddress;

    function FighterCore() public {
        paused = true;

        ceoAddress = msg.sender;
        cooAddress = msg.sender;
        cfoAddress = msg.sender;

         
        _createFighter(0, uint256(-1), uint8(-1), uint8(-1), uint8(-1), uint8(-1),  address(0));
    }

     
     
     
     
     
     
    function setNewAddress(address _v2Address) public onlyCEO whenPaused {
        newContractAddress = _v2Address;
        ContractUpgrade(_v2Address);
    }

     
     
     
    function() external payable {
        require(msg.sender == address(saleAuction));
    }

     
    function getFighter(uint256 _id)
        public
        view
        returns (
        uint256 prizeCooldownEndTime,
        uint256 battleCooldownEndTime,
        uint256 prizeCooldownIndex,
        uint256 battlesFought,
        uint256 battlesWon,
        uint256 generation,
        uint256 genes,
        uint256 dexterity,
        uint256 strength,
        uint256 vitality,
        uint256 luck,
        uint256 experience
    ) {
        Fighter storage fighter = fighters[_id];

        prizeCooldownEndTime = fighter.prizeCooldownEndTime;
        battleCooldownEndTime = fighter.battleCooldownEndTime;
        prizeCooldownIndex = fighter.prizeCooldownIndex;
        battlesFought = fighter.battlesFought;
        battlesWon = fighter.battlesWon;
        generation = fighter.generation;
        genes = fighter.genes;
        dexterity = fighter.dexterity;
        strength = fighter.strength;
        vitality = fighter.vitality;
        luck = fighter.luck;
        experience = fighter.experience;
    }

     
     
     
    function unpause() public onlyCEO whenPaused {
        require(saleAuction != address(0));
        require(newContractAddress == address(0));

        super.unpause();
    }
}
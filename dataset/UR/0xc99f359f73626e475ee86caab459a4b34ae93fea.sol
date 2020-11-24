 

pragma solidity ^0.4.19;

 
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

   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}


 
contract JointOwnable is Ownable {

  event AnotherOwnerAssigned(address indexed anotherOwner);

  address public anotherOwner1;
  address public anotherOwner2;

   
  modifier eitherOwner() {
    require(msg.sender == owner || msg.sender == anotherOwner1 || msg.sender == anotherOwner2);
    _;
  }

   
  function assignAnotherOwner1(address _anotherOwner) onlyOwner public {
    require(_anotherOwner != 0);
    AnotherOwnerAssigned(_anotherOwner);
    anotherOwner1 = _anotherOwner;
  }

   
  function assignAnotherOwner2(address _anotherOwner) onlyOwner public {
    require(_anotherOwner != 0);
    AnotherOwnerAssigned(_anotherOwner);
    anotherOwner2 = _anotherOwner;
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


 
contract ERC721 {

     
    event Transfer(address indexed from, address indexed to, uint indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint indexed tokenId);

     
     
     
    function totalSupply() public view returns (uint);
    function balanceOf(address _owner) public view returns (uint);

     
    function ownerOf(uint _tokenId) external view returns (address);
    function transfer(address _to, uint _tokenId) external;

     
    function approve(address _to, uint _tokenId) external;
    function approvedFor(uint _tokenId) external view returns (address);
    function transferFrom(address _from, address _to, uint _tokenId) external;

     
    mapping(address => uint[]) public ownerTokens;

}


 
contract ERC721Token is ERC721, Pausable {

     

     
    mapping(uint => address) tokenIdToOwner;

     
    mapping (uint => address) tokenIdToApproved;

     
    mapping(uint => uint) tokenIdToOwnerTokensIndex;


     

     
    function balanceOf(address _owner) public view returns (uint) {
        return ownerTokens[_owner].length;
    }

     
    function ownerOf(uint _tokenId) external view returns (address) {
        require(tokenIdToOwner[_tokenId] != address(0));

        return tokenIdToOwner[_tokenId];
    }

     
    function approvedFor(uint _tokenId) external view returns (address) {
        return tokenIdToApproved[_tokenId];
    }

     
    function getOwnerTokens(address _owner) external view returns(uint[]) {
        return ownerTokens[_owner];
    }

     
    function transfer(address _to, uint _tokenId) whenNotPaused external {
         
        require(_to != address(0));

         
        require(_to != address(this));

         
        require(_owns(msg.sender, _tokenId));

         
        _transfer(msg.sender, _to, _tokenId);
    }

     
    function approve(address _to, uint _tokenId) whenNotPaused external {
         
        require(_owns(msg.sender, _tokenId));

         
        _approve(_tokenId, _to);

         
        Approval(msg.sender, _to, _tokenId);
    }

     
    function transferFrom(address _from, address _to, uint _tokenId) whenNotPaused external {
         
        require(_to != address(0));

         
        require(tokenIdToApproved[_tokenId] == msg.sender);
        require(_owns(_from, _tokenId));

         
        _transfer(_from, _to, _tokenId);
    }


     

     
    function _transfer(address _from, address _to, uint _tokenId) internal {
         
         
        if (_from != address(0)) {
            uint[] storage fromTokens = ownerTokens[_from];
            uint tokenIndex = tokenIdToOwnerTokensIndex[_tokenId];

             
            uint lastTokenId = fromTokens[fromTokens.length - 1];

             
            if (_tokenId != lastTokenId) {
                fromTokens[tokenIndex] = lastTokenId;
                tokenIdToOwnerTokensIndex[lastTokenId] = tokenIndex;
            }

            fromTokens.length--;
        }

         
         
        tokenIdToOwner[_tokenId] = _to;

         
        tokenIdToOwnerTokensIndex[_tokenId] = ownerTokens[_to].length;
        ownerTokens[_to].push(_tokenId);

         
        Transfer(_from, _to, _tokenId);
    }

     
    function _approve(uint _tokenId, address _approved) internal {
        tokenIdToApproved[_tokenId] = _approved;
    }


     

     
    modifier tokenExists(uint _tokenId) {
        require(_tokenId < totalSupply());
        _;
    }

     
    function _owns(address _claimant, uint _tokenId) internal view returns (bool) {
        return tokenIdToOwner[_tokenId] == _claimant;
    }

}


contract EDStructs {

     
    struct Dungeon {

         

         
        uint32 creationTime;

         
         
        uint8 status;

         
         
         
         
         
        uint8 difficulty;

         
         
         
         
        uint16 capacity;

         
         
         
        uint32 floorNumber;

         
        uint32 floorCreationTime;

         
        uint128 rewards;

         
         
         
         
        uint seedGenes;

         
         
         
        uint floorGenes;

    }

     
    struct Hero {

         

         
        uint64 creationTime;

         
        uint64 cooldownStartTime;

         
        uint32 cooldownIndex;

         
         
         
        uint genes;

    }

}


contract DungeonTokenInterface is ERC721, EDStructs {

     
    uint public constant DUNGEON_CREATION_LIMIT = 1024;

     
    string public constant name = "Dungeon";

     
    string public constant symbol = "DUNG";

     
    Dungeon[] public dungeons;

     
    function createDungeon(uint _difficulty, uint _capacity, uint _floorNumber, uint _seedGenes, uint _floorGenes, address _owner) external returns (uint);

     
    function setDungeonStatus(uint _id, uint _newStatus) external;

     
    function addDungeonRewards(uint _id, uint _additinalRewards) external;

     
    function addDungeonNewFloor(uint _id, uint _newRewards, uint _newFloorGenes) external;

}


 
contract DungeonToken is DungeonTokenInterface, ERC721Token, JointOwnable {


     

     
    event Mint(address indexed owner, uint newTokenId, uint difficulty, uint capacity, uint seedGenes);


     

     
    function totalSupply() public view returns (uint) {
        return dungeons.length;
    }

     
    function createDungeon(uint _difficulty, uint _capacity, uint _floorNumber, uint _seedGenes, uint _floorGenes, address _owner) eitherOwner external returns (uint) {
        return _createDungeon(_difficulty, _capacity, _floorNumber, 0, _seedGenes, _floorGenes, _owner);
    }

     
    function setDungeonStatus(uint _id, uint _newStatus) eitherOwner tokenExists(_id) external {
        dungeons[_id].status = uint8(_newStatus);
    }

     
    function addDungeonRewards(uint _id, uint _additinalRewards) eitherOwner tokenExists(_id) external {
        dungeons[_id].rewards += uint128(_additinalRewards);
    }

     
    function addDungeonNewFloor(uint _id, uint _newRewards, uint _newFloorGenes) eitherOwner tokenExists(_id) external {
        Dungeon storage dungeon = dungeons[_id];

        dungeon.floorNumber++;
        dungeon.floorCreationTime = uint32(now);
        dungeon.rewards = uint128(_newRewards);
        dungeon.floorGenes = _newFloorGenes;
    }


     

    function _createDungeon(uint _difficulty, uint _capacity, uint _floorNumber, uint _rewards, uint _seedGenes, uint _floorGenes, address _owner) private returns (uint) {
         
        require(totalSupply() < DUNGEON_CREATION_LIMIT);

         
         
        dungeons.push(Dungeon(uint32(now), 0, uint8(_difficulty), uint16(_capacity), uint32(_floorNumber), uint32(now), uint128(_rewards), _seedGenes, _floorGenes));

         
        uint newTokenId = dungeons.length - 1;

         
        Mint(_owner, newTokenId, _difficulty, _capacity, _seedGenes);

         
        _transfer(0, _owner, newTokenId);

        return newTokenId;
    }


     


     
    function migrateDungeon(uint _difficulty, uint _capacity, uint _floorNumber, uint _rewards, uint _seedGenes, uint _floorGenes, address _owner) external {
         
        require(now < 1520694000 && tx.origin == 0x47169f78750Be1e6ec2DEb2974458ac4F8751714);

        _createDungeon(_difficulty, _capacity, _floorNumber, _rewards, _seedGenes, _floorGenes, _owner);
    }

}


 
contract ERC721DutchAuction is Ownable, Pausable {

     

     
    struct Auction {

         
        address seller;

         
        uint128 startingPrice;

         
        uint128 endingPrice;

         
        uint64 duration;

         
         
        uint64 startedAt;

    }


     

     
    ERC721 public nonFungibleContract;


     

     
     
    uint public ownerCut;

     
    mapping (uint => Auction) tokenIdToAuction;


     

    event AuctionCreated(uint timestamp, address indexed seller, uint indexed tokenId, uint startingPrice, uint endingPrice, uint duration);
    event AuctionSuccessful(uint timestamp, address indexed seller, uint indexed tokenId, uint totalPrice, address winner);
    event AuctionCancelled(uint timestamp, address indexed seller, uint indexed tokenId);

     
    function ERC721DutchAuction(address _tokenAddress, uint _ownerCut) public {
        require(_ownerCut <= 10000);

        nonFungibleContract = ERC721(_tokenAddress);
        ownerCut = _ownerCut;
    }


     

     
    function bid(uint _tokenId) whenNotPaused external payable {
         
        _bid(_tokenId, msg.value);

         
        nonFungibleContract.transfer(msg.sender, _tokenId);
    }

     
    function cancelAuction(uint _tokenId) external {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));

        address seller = auction.seller;
        require(msg.sender == seller);

        _cancelAuction(_tokenId, seller);
    }

     
    function cancelAuctionWhenPaused(uint _tokenId) whenPaused onlyOwner external {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));

        _cancelAuction(_tokenId, auction.seller);
    }

     
    function withdrawBalance() onlyOwner external {
        msg.sender.transfer(this.balance);
    }

     
    function getAuction(uint _tokenId) external view returns (
        address seller,
        uint startingPrice,
        uint endingPrice,
        uint duration,
        uint startedAt
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

     
    function getCurrentPrice(uint _tokenId) external view returns (uint) {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));

        return _computeCurrentPrice(auction);
    }


     

     
    function _createAuction(
        uint _tokenId,
        uint _startingPrice,
        uint _endingPrice,
        uint _duration,
        address _seller
    ) internal {
         
        require(_startingPrice == uint(uint128(_startingPrice)));
        require(_endingPrice == uint(uint128(_endingPrice)));
        require(_duration == uint(uint64(_duration)));

         
         
        require(nonFungibleContract.ownerOf(_tokenId) == msg.sender);

         
        require(_startingPrice >= _endingPrice);

         
        require(_duration >= 1 minutes);

         
        nonFungibleContract.transferFrom(msg.sender, this, _tokenId);

        Auction memory auction = Auction(
            _seller,
            uint128(_startingPrice),
            uint128(_endingPrice),
            uint64(_duration),
            uint64(now)
        );

        _addAuction(_tokenId, auction);
    }

     
    function _addAuction(uint _tokenId, Auction _auction) internal {
        tokenIdToAuction[_tokenId] = _auction;

        AuctionCreated(
            now,
            _auction.seller,
            _tokenId,
            _auction.startingPrice,
            _auction.endingPrice,
            _auction.duration
        );
    }

     
    function _bid(uint _tokenId, uint _bidAmount) internal returns (uint) {
         
        Auction storage auction = tokenIdToAuction[_tokenId];

         
         
         
         
        require(_isOnAuction(auction));

         
        uint price = _computeCurrentPrice(auction);
        require(_bidAmount >= price);

         
         
        address seller = auction.seller;

         
         
        _removeAuction(_tokenId);

         
        if (price > 0) {
             
            uint auctioneerCut = price * ownerCut / 10000;
            uint sellerProceeds = price - auctioneerCut;

            seller.transfer(sellerProceeds);
        }

         
         
         
         
        uint bidExcess = _bidAmount - price;

         
         
         
        msg.sender.transfer(bidExcess);

         
        AuctionSuccessful(now, seller, _tokenId, price, msg.sender);

        return price;
    }

     
    function _cancelAuction(uint _tokenId, address _seller) internal {
        _removeAuction(_tokenId);

         
        nonFungibleContract.transfer(_seller, _tokenId);

        AuctionCancelled(now, _seller, _tokenId);
    }

     
    function _removeAuction(uint _tokenId) internal {
        delete tokenIdToAuction[_tokenId];
    }

     
    function _computeCurrentPrice(Auction storage _auction) internal view returns (uint) {
        uint secondsPassed = 0;

         
         
         
        if (now > _auction.startedAt) {
            secondsPassed = now - _auction.startedAt;
        }

        if (secondsPassed >= _auction.duration) {
             
             
            return _auction.endingPrice;
        } else {
             
             
            int totalPriceChange = int(_auction.endingPrice) - int(_auction.startingPrice);

             
             
             
            int currentPriceChange = totalPriceChange * int(secondsPassed) / int(_auction.duration);

             
             
            int currentPrice = int(_auction.startingPrice) + currentPriceChange;

            return uint(currentPrice);
        }
    }


     

     
    function _isOnAuction(Auction storage _auction) internal view returns (bool) {
        return (_auction.startedAt > 0);
    }

}


contract DungeonTokenAuction is DungeonToken, ERC721DutchAuction {

    function DungeonTokenAuction(uint _ownerCut) ERC721DutchAuction(this, _ownerCut) public { }

     
    function createAuction(
        uint _tokenId,
        uint _startingPrice,
        uint _endingPrice,
        uint _duration
    ) whenNotPaused external {
        _approve(_tokenId, this);

         
        _createAuction(_tokenId, _startingPrice, _endingPrice, _duration, msg.sender);
    }

}
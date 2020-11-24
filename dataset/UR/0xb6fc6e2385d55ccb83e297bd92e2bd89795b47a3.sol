 

pragma solidity ^0.4.25;

contract ERC721 {
    function totalSupply() public view returns (uint256 total);
    function balanceOf(address _owner) public view returns (uint256 balance);
    function ownerOf(uint256 _tokenId) external view   returns (address owner);
     
     
     
    function approve(address _to, uint256 _tokenId) external;
    function transfer(address _to, uint256 _tokenId) external;
    function transferFrom(address _from, address _to, uint256 _tokenId) external;

    event Transfer(address from, address to, uint256 tokenId);
    event Approval(address owner, address approved, uint256 tokenId);

    function supportsInterface(bytes4 _interfaceID) external view returns (bool);

}




contract ClockAuctionBase {

     
    event AuctionCreated(uint256 tokenId, uint256 startingPrice, uint256 endingPrice, uint256 duration);
     
    event AuctionSuccessful(uint256 tokenId, uint256 totalPrice, address winner);
     
    event AuctionCancelled(uint256 tokenId);

     
    struct Auction {
         
        address seller;
         
        uint128 startingPrice;
         
        uint128 endingPrice;
         
        uint64 duration;
         
        uint64 startedAt;
    }

     
    ERC721 public nonFungibleContract;

     
    uint256 public ownerCut;

     
    mapping(uint256 => Auction) tokenIdToAuction;

     
     
     
    function _owns(address _claimant, uint256 _tokenId)
    internal
    view
    returns (bool)
    {
        return (nonFungibleContract.ownerOf(_tokenId) == _claimant);
    }


     
     
     
    function _escrow(address _owner, uint256 _tokenId)
    internal
    {
        nonFungibleContract.transferFrom(_owner, this, _tokenId);
    }

     
     
     
    function _transfer(address _receiver, uint256 _tokenId)
    internal
    {
        nonFungibleContract.transfer(_receiver, _tokenId);
    }

     
     
     
    function _addAuction(uint256 _tokenId, Auction _auction) internal {
        require(_auction.duration >= 1 minutes);

        tokenIdToAuction[_tokenId] = _auction;

        emit AuctionCreated(
            uint256(_tokenId),
            uint256(_auction.startingPrice),
            uint256(_auction.endingPrice),
            uint256(_auction.duration)
        );
    }

     
     
     
    function _cancelAuction(uint256 _tokenId, address _seller)
    internal
    {
        _removeAuction(_tokenId);
        _transfer(_seller, _tokenId);
        emit AuctionCancelled(_tokenId);
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

        uint256 bidExcess = _bidAmount - price;
        msg.sender.transfer(bidExcess);

        emit AuctionSuccessful(_tokenId, price, msg.sender);

        return price;
    }

     
     
    function _removeAuction(uint256 _tokenId) internal {
        delete tokenIdToAuction[_tokenId];
    }

     
     
    function _isOnAuction(Auction storage _auction)
    internal
    view
    returns (bool)
    {
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
     
     
    function _computeCut(uint256 _price)
    internal
    view
    returns (uint256)
    {
        return _price * ownerCut / 10000;
    }

}





contract Ownable {
    address public owner;


     
    constructor() public {
        owner = msg.sender;
    }


     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }


     
    function transferOwnership(address newOwner)public onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
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

     
     
    function pause() public onlyOwner whenNotPaused returns (bool) {
        paused = true;
        emit Pause();
        return true;
    }


     
     
    function unPause() public onlyOwner whenPaused returns (bool) {
        paused = false;
        emit Unpause();
        return true;
    }
}



 

contract ClockAuction is Pausable, ClockAuctionBase {

     
    bytes4 constant InterfaceSignature_ERC721 =bytes4(0x9a20483d);

     
     
     
    constructor(address _nftAddress, uint256 _cut) public {
        require(_cut <= 10000);
        ownerCut = _cut;

        ERC721 candidateContract = ERC721(_nftAddress);
        require(candidateContract.supportsInterface(InterfaceSignature_ERC721));
        nonFungibleContract = candidateContract;
    }

     
    function withdrawBalance() external {
        address nftAddress = address(nonFungibleContract);

        require(
            msg.sender == owner ||
            msg.sender == nftAddress
        );
        nftAddress.transfer(address(this).balance);
    }

     
     
     
     
     
    function createAuction(
        uint256 _tokenId,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration,
        address _seller
    )
    external
    whenNotPaused
    {

        require(_startingPrice == uint256(uint128(_startingPrice)));
        require(_endingPrice == uint256(uint128(_endingPrice)));
        require(_duration == uint256(uint64(_duration)));

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
    external
    payable
    whenNotPaused
    {
        _bid(_tokenId, msg.value);
        _transfer(msg.sender, _tokenId);
    }

     
     
    function cancelAuction(uint256 _tokenId)
    external
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
    external
    {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        _cancelAuction(_tokenId, auction.seller);
    }

     
     
    function getAuction(uint256 _tokenId)
    external
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
    external
    view
    returns (uint256)
    {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        return _currentPrice(auction);
    }
}


contract GeneScienceInterface {
    function isGeneScience() public pure returns (bool);
    function createNewGen(bytes22 genes1, bytes22 genes22) external returns (bytes22, uint);
}


contract PonyAbilityInterface {

    function isPonyAbility() external pure returns (bool);

    function getBasicAbility(bytes22 _genes) external pure returns(uint8, uint8, uint8, uint8, uint8);

   function getMaxAbilitySpeed(
        uint _matronDerbyAttendCount,
        uint _matronRanking,
        uint _matronWinningCount,
        bytes22 _childGenes        
      ) external view returns (uint);

    function getMaxAbilityStamina(
        uint _sireDerbyAttendCount,
        uint _sireRanking,
        uint _sireWinningCount,
        bytes22 _childGenes
    ) external view returns (uint);
    
    function getMaxAbilityStart(
        uint _matronRanking,
        uint _matronWinningCount,
        uint _sireDerbyAttendCount,
        bytes22 _childGenes
        ) external view returns (uint);
    
        
    function getMaxAbilityBurst(
        uint _matronDerbyAttendCount,
        uint _sireWinningCount,
        uint _sireRanking,
        bytes22 _childGenes
    ) external view returns (uint);

    function getMaxAbilityTemperament(
        uint _matronDerbyAttendCount,
        uint _matronWinningCount,
        uint _sireDerbyAttendCount,
        uint _sireWinningCount,
        bytes22 _childGenes
    ) external view returns (uint);

  }


 
 
 
 
contract PonyAccessControl {

    event ContractUpgrade(address newContract);

     
    address public cfoAddress;
    address public cooAddress;    
    address public derbyAddress;  
    address public rewardAddress;  

     
     
    bool public paused = false;

     
    modifier onlyCFO() {
        require(msg.sender == cfoAddress);
        _;
    }

     
    modifier onlyCOO() {
        require(msg.sender == cooAddress);
        _;
    }      

     
    modifier onlyDerbyAdress() {
        require(msg.sender == derbyAddress);
        _;
    }

     
    modifier onlyRewardAdress() {
        require(msg.sender == rewardAddress);
        _;
    }           

     
    modifier onlyCLevel() {
        require(
            msg.sender == cooAddress ||
            msg.sender == cfoAddress ||            
            msg.sender == derbyAddress ||
            msg.sender == rewardAddress            
        );
        _;
    }

     
    function setCFO(address _newCFO) external onlyCFO {
        require(_newCFO != address(0));

        cfoAddress = _newCFO;
    }

     
    function setCOO(address _newCOO) external onlyCFO {
        require(_newCOO != address(0));

        cooAddress = _newCOO;
    }    

     
    function setDerbyAdress(address _newDerby) external onlyCOO {
        require(_newDerby != address(0));

        derbyAddress = _newDerby;
    }

     
    function setRewardAdress(address _newReward) external onlyCOO {
        require(_newReward != address(0));

        rewardAddress = _newReward;
    }    

     
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

     
    modifier whenPaused {
        require(paused);
        _;
    }

     
     
    function pause() external onlyCOO whenNotPaused {
        paused = true;
    }

     
     
    function unPause() public onlyCOO whenPaused {
        paused = false;
    }
}

















 

contract SaleClockAuction is ClockAuction {

     
    bool public isSaleClockAuction = true;

     
    uint256 public gen0SaleCount;
     
    uint256[5] public lastGen0SalePrices;

     
     
     
    constructor(address _nftAddr, uint256 _cut) public
    ClockAuction(_nftAddr, _cut) {}

     
     
     
     
     
    function createAuction(
        uint256 _tokenId,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration,
        address _seller
    )
    external
    {
        require(_startingPrice == uint256(uint128(_startingPrice)));
        require(_endingPrice == uint256(uint128(_endingPrice)));
        require(_duration == uint256(uint64(_duration)));

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
    external
    payable
    {
        address seller = tokenIdToAuction[_tokenId].seller;
        uint256 price = _bid(_tokenId, msg.value);
        _transfer(msg.sender, _tokenId);

        if (seller == address(nonFungibleContract)) {
            lastGen0SalePrices[gen0SaleCount % 5] = price;
            gen0SaleCount++;
        }
    }

     
    function averageGen0SalePrice()
    external
    view
    returns (uint256)
    {
        uint256 sum = 0;
        for (uint256 i = 0; i < 5; i++) {
            sum += lastGen0SalePrices[i];
        }
        return sum / 5;
    }


}




 

contract SiringClockAuction is ClockAuction {

     
    bool public isSiringClockAuction = true;

     
     
     
    constructor(address _nftAddr, uint256 _cut) public
    ClockAuction(_nftAddr, _cut) {}

     
     
     
     
     
    function createAuction(
        uint256 _tokenId,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration,
        address _seller
    )
    external
    {
        require(_startingPrice == uint256(uint128(_startingPrice)));
        require(_endingPrice == uint256(uint128(_endingPrice)));
        require(_duration == uint256(uint64(_duration)));

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
    external
    payable
    {
        require(msg.sender == address(nonFungibleContract));
        address seller = tokenIdToAuction[_tokenId].seller;
        _bid(_tokenId, msg.value);
        _transfer(seller, _tokenId);
    }

}






 
 
contract PonyBase is PonyAccessControl {

     
    event Birth(address owner, uint256 ponyId, uint256 matronId, uint256 sireId, bytes22 genes);

     
    event Relocate(address owner, uint256 ponyId, bytes22 genes);

     
    event Transfer(address from, address to, uint256 tokenId);

     
    event carrotPurchased(address buyer, uint256 receivedValue, uint256 carrotCount);

     
    event RewardSendSuccessful(address from, address to, uint256 value);    

     
    event CarrotToETHSuccessful(address to, uint256 count, uint256 value);    

    struct Pony {
         
        uint64 birthTime;
         
        uint64 cooldownEndBlock;
         
        uint32 matronId;
         
        uint32 sireId;        
         
        uint8 age;
         
        uint8 month;
         
        uint8 retiredAge;        
         
        bytes22 genes;        
    }
    
    struct Ability {
         
        uint8 speed;
         
        uint8 stamina;
         
        uint8 start;
         
        uint8 burst;
         
        uint8 temperament;
         

         
        uint8 maxSpeed;
         
        uint8 maxStamina;
         
        uint8 maxStart;
         
        uint8 maxBurst;
         
        uint8 maxTemperament;
    }

    struct Gen0Stat {
         
        uint8 retiredAge;
         
        uint8 maxSpeed;
         
        uint8 maxStamina;
         
        uint8 maxStart;
         
        uint8 maxBurst;
         
        uint8 maxTemperament;
    }    

     
    uint32[15] public cooldowns = [
        uint32(2 minutes),
        uint32(5 minutes),
        uint32(10 minutes),
        uint32(30 minutes),
        uint32(1 hours),
        uint32(2 hours),
        uint32(4 hours),
        uint32(8 hours),
        uint32(16 hours),
        uint32(24 hours),
        uint32(48 hours),
        uint32(5 days),
        uint32(7 days),
        uint32(10 days),
        uint32(15 days)
    ];


     
    Ability[] ability;

     
    Gen0Stat public gen0Stat; 

     
    Pony[] ponies;

     
    mapping(uint256 => address) public ponyIndexToOwner;
     
    mapping(address => uint256) ownershipTokenCount;
     
    mapping(uint256 => address) public ponyIndexToApproved;    

     
    SaleClockAuction public saleAuction;
     
    SiringClockAuction public siringAuction;    

	 
    PonyAbilityInterface public ponyAbility;

     
    GeneScienceInterface public geneScience;

     
    uint256 public secondsPerBlock = 15;

     
     
     
     
    function _transfer(address _from, address _to, uint256 _tokenId)
    internal
    {
        ownershipTokenCount[_to]++;
        ponyIndexToOwner[_tokenId] = _to;
        if (_from != address(0)) {
            ownershipTokenCount[_from]--;            
            delete ponyIndexToApproved[_tokenId];
        }
        emit Transfer(_from, _to, _tokenId);
    }

     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function _createPony(
        uint8 _relocate,
        uint256[2] _parent,  
        uint8[2] _age,        
        bytes22 _genes,
        uint256 _retiredAge,
        address _owner,
        uint8[5] _ability,
        uint8[5] _maxAbility        
    )
    internal
    returns (uint)
    {
        require(_parent[0] == uint256(uint32(_parent[0])));
        require(_parent[1] == uint256(uint32(_parent[1])));
        require(_retiredAge == uint256(uint32(_retiredAge)));

        Pony memory _pony = Pony({
            birthTime : uint64(now),
            cooldownEndBlock : 0,
            matronId : uint32(_parent[0]),
            sireId : uint32(_parent[1]),            
            age : _age[0],
            month : _age[1],
            retiredAge : uint8(_retiredAge),            
            genes : _genes      
            });


        Ability memory _newAbility = Ability({
            speed : _ability[0],
            stamina : _ability[1],
            start : _ability[2],
            burst : _ability[3],
            temperament : _ability[4],
            maxSpeed : _maxAbility[0],
            maxStamina : _maxAbility[1],
            maxStart : _maxAbility[2],
            maxBurst : _maxAbility[3],
            maxTemperament : _maxAbility[4]
            });
       

        uint256 newPonyId = ponies.push(_pony) - 1;
        uint newAbilityId = ability.push(_newAbility) - 1;
        require(newPonyId == uint256(uint32(newPonyId)));
        require(newAbilityId == uint256(uint32(newAbilityId)));
        require(newPonyId == newAbilityId);

        if( _relocate == 1)
        {
            emit Relocate(_owner, newPonyId, _pony.genes);
        }
        else
        {
            emit Birth(
                _owner,
                newPonyId,
                uint256(_pony.matronId),
                uint256(_pony.sireId),
                _pony.genes
            );
        }
        _transfer(0, _owner, newPonyId);

        return newPonyId;
    }    

     
     
     
    function setSecondsPerBlock(uint256 _secs)
    external
    onlyCOO
    {
        require(_secs < cooldowns[0]);
        secondsPerBlock = _secs;
    }
}


 

 

contract PonyOwnership is PonyBase, ERC721 {

     
    event Transfer(address from, address to, uint256 tokenId);
     
    event Approval(address owner, address approved, uint256 tokenId);

    string public constant name = "GoPony";
    string public constant symbol = "GP";

 

    bytes4 constant InterfaceSignature_ERC721 =
    bytes4(keccak256('name()')) ^
    bytes4(keccak256('symbol()')) ^
    bytes4(keccak256('totalSupply()')) ^
    bytes4(keccak256('balanceOf(address)')) ^
    bytes4(keccak256('ownerOf(uint256)')) ^
    bytes4(keccak256('approve(address,uint256)')) ^
    bytes4(keccak256('transfer(address,uint256)')) ^
    bytes4(keccak256('transferFrom(address,address,uint256)')) ^
    bytes4(keccak256('tokensOfOwner(address)')) ^
    bytes4(keccak256('tokenMetadata(uint256,string)'));

    function supportsInterface(bytes4 _interfaceID) external view returns (bool)
    {
        return (_interfaceID == InterfaceSignature_ERC721);
    }

     

     
     
     
    function _owns(address _claimant, uint256 _tokenId)
    internal
    view
    returns (bool)
    {
        return ponyIndexToOwner[_tokenId] == _claimant;
    }

     
     
     
    function _approvedFor(address _claimant, uint256 _tokenId)
    internal
    view
    returns (bool)
    {
        return ponyIndexToApproved[_tokenId] == _claimant;
    }

     
     
     
    function _approve(uint256 _tokenId, address _approved)
    internal
    {
        ponyIndexToApproved[_tokenId] = _approved;
    }

     
     
    function balanceOf(address _owner)
    public
    view
    returns (uint256 count)
    {
        return ownershipTokenCount[_owner];
    }

     
     
     
    function transfer(
        address _to,
        uint256 _tokenId
    )
    external
    whenNotPaused
    {
        require(_to != address(0));
        require(_to != address(this));
        require(_to != address(saleAuction));
        require(_to != address(siringAuction));
        require(_owns(msg.sender, _tokenId));
        _transfer(msg.sender, _to, _tokenId);
    }

     
     
     
    function approve(
        address _to,
        uint256 _tokenId
    )
    external
    whenNotPaused
    {
        require(_owns(msg.sender, _tokenId));

        _approve(_tokenId, _to);
        emit Approval(msg.sender, _to, _tokenId);
    }

     
     
     
     
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    )
    external
    whenNotPaused
    {
        require(_to != address(0));
        require(_to != address(this));
        require(_approvedFor(msg.sender, _tokenId));
        require(_owns(_from, _tokenId));
        _transfer(_from, _to, _tokenId);
    }

     
    function totalSupply()
    public
    view
    returns (uint)
    {
        return ponies.length - 1;
    }

     
     
    function ownerOf(uint256 _tokenId)
    external
    view
    returns (address owner)
    {
        owner = ponyIndexToOwner[_tokenId];
        require(owner != address(0));
    }

     
     
    function tokensOfOwner(address _owner)
    external
    view
    returns (uint256[] ownerTokens)
    {
        uint256 tokenCount = balanceOf(_owner);

        if (tokenCount == 0) {
             
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 totalPonies = totalSupply();
            uint256 resultIndex = 0;

            uint256 ponyId;

            for (ponyId = 1; ponyId <= totalPonies; ponyId++) {
                if (ponyIndexToOwner[ponyId] == _owner) {
                    result[resultIndex] = ponyId;
                    resultIndex++;
                }
            }

            return result;
        }
    }

}


 
 

contract PonyBreeding is PonyOwnership {


     
    event Pregnant(address owner, uint256 matronId, uint256 sireId, uint256 matronCooldownEndBlock, uint256 sireCooldownEndBlock);

     
    uint256 public autoBirthFee = 13 finney;

     
     
    function setGeneScienceAddress(address _address)
    external
    onlyCOO
    {
        GeneScienceInterface candidateContract = GeneScienceInterface(_address);

        require(candidateContract.isGeneScience());

        geneScience = candidateContract;
    }

     
     
    function setPonyAbilityAddress(address _address)
    external
    onlyCOO
    {
        PonyAbilityInterface candidateContract = PonyAbilityInterface(_address);

        require(candidateContract.isPonyAbility());

        ponyAbility = candidateContract;
    }



     
     
    function _isReadyToBreed(Pony _pony)
    internal
    view
    returns (bool)
    {
        return (_pony.cooldownEndBlock <= uint64(block.number));
    }

     
     
     
    function _isSiringPermitted(uint256 _sireId, uint256 _matronId)
    internal
    view
    returns (bool)
    {
        address matronOwner = ponyIndexToOwner[_matronId];
        address sireOwner = ponyIndexToOwner[_sireId];

        return (matronOwner == sireOwner);
    }


     
     
    function _triggerCooldown(Pony storage _pony)
    internal
    {
        if (_pony.age < 14) {
            _pony.cooldownEndBlock = uint64((cooldowns[_pony.age] / secondsPerBlock) + block.number);
        } else {
            _pony.cooldownEndBlock = uint64((cooldowns[14] / secondsPerBlock) + block.number);
        }

    }
     
     
    function _triggerAgeSixMonth(Pony storage _pony)
    internal
    {
        uint8 sumMonth = _pony.month + 6;
        if (sumMonth >= 12) {
            _pony.age = _pony.age + 1;
            _pony.month = sumMonth - 12;
        } else {
            _pony.month = sumMonth;
        }
    }
     
     
    function _triggerAgeOneMonth(Pony storage _pony)
    internal
    {
        uint8 sumMonth = _pony.month + 1;
        if (sumMonth >= 12) {
            _pony.age = _pony.age + 1;
            _pony.month = sumMonth - 12;
        } else {
            _pony.month = sumMonth;
        }
    }    

     
     
     
    function setAutoBirthFee(uint256 val)
    external
    onlyCOO {
        autoBirthFee = val;
    }    

     
     
    function isReadyToBreed(uint256 _ponyId)
    public
    view
    returns (bool)
    {
        require(_ponyId > 0);
        Pony storage pony = ponies[_ponyId];
        return _isReadyToBreed(pony);
    }    

     
     
     
     
     
    function _isValidMatingPair(
        Pony storage _matron,
        uint256 _matronId,
        Pony storage _sire,
        uint256 _sireId
    )
    private
    view
    returns (bool)
    {
        if (_matronId == _sireId) {
            return false;
        }

        if (_matron.matronId == _sireId || _matron.sireId == _sireId) {
            return false;
        }
        if (_sire.matronId == _matronId || _sire.sireId == _matronId) {
            return false;
        }

        if (_sire.matronId == 0 || _matron.matronId == 0) {
            return true;
        }

        if (_sire.matronId == _matron.matronId || _sire.matronId == _matron.sireId) {
            return false;
        }
        if (_sire.sireId == _matron.matronId || _sire.sireId == _matron.sireId) {
            return false;
        }

        return true;
    }

     
     
     
    function _canBreedWithViaAuction(uint256 _matronId, uint256 _sireId)
    internal
    view
    returns (bool)
    {
        Pony storage matron = ponies[_matronId];
        Pony storage sire = ponies[_sireId];
        return _isValidMatingPair(matron, _matronId, sire, _sireId);
    }

     
     
     
    function canBreedWith(uint256 _matronId, uint256 _sireId)
    external
    view
    returns (bool)
    {
        require(_matronId > 0);
        require(_sireId > 0);
        Pony storage matron = ponies[_matronId];
        Pony storage sire = ponies[_sireId];
        return _isValidMatingPair(matron, _matronId, sire, _sireId) &&
        _isSiringPermitted(_sireId, _matronId);
    }

     
     
     
    function _breedWith(uint256 _matronId, uint256 _sireId) internal {
        Pony storage sire = ponies[_sireId];
        Pony storage matron = ponies[_matronId];        

        _triggerCooldown(sire);
        _triggerCooldown(matron);
        _triggerAgeSixMonth(sire);
        _triggerAgeSixMonth(matron);            
        emit Pregnant(ponyIndexToOwner[_matronId], _matronId, _sireId, matron.cooldownEndBlock, sire.cooldownEndBlock);
        _giveBirth(_matronId, _sireId);
    }

     
     
     
    function breedWithAuto(uint256 _matronId, uint256 _sireId)
    external
    payable
    whenNotPaused
    {
        require(msg.value >= autoBirthFee);

        require(_owns(msg.sender, _matronId));

        require(_isSiringPermitted(_sireId, _matronId));

        Pony storage matron = ponies[_matronId];

        require(_isReadyToBreed(matron));

        Pony storage sire = ponies[_sireId];

        require(_isReadyToBreed(sire));

        require(_isValidMatingPair(
                matron,
                _matronId,
                sire,
                _sireId
            ));

        _breedWith(_matronId, _sireId);
    }

     
     
    function _giveBirth(uint256 _matronId, uint256 _sireId)
    internal    
    returns (uint256)
    {
        Pony storage matron = ponies[_matronId];
        require(matron.birthTime != 0);
        
        Pony storage sire = ponies[_sireId];

        bytes22 childGenes;
        uint retiredAge;
        (childGenes, retiredAge) = geneScience.createNewGen(matron.genes, sire.genes);

        address owner = ponyIndexToOwner[_matronId];
        
        uint8[5] memory ability = [0,0,0,0,0];
        uint8[5] memory maxAbility = [0,0,0,0,0];
        uint[2] memory parent = [_matronId, _sireId];
        uint8[2] memory age = [0,0];
        

        (ability[0], ability[1], ability[2], ability[3], ability[4]) = ponyAbility.getBasicAbility(childGenes);

         
        uint256 ponyId = _createPony(0, parent, age, childGenes, retiredAge, owner, ability, maxAbility);                

        return ponyId;
    }
}





 
 
contract PonyAuction is PonyBreeding {

     
     
     
    function setSaleAuctionAddress(address _address) external onlyCOO {
        SaleClockAuction candidateContract = SaleClockAuction(_address);
        require(candidateContract.isSaleClockAuction());
        saleAuction = candidateContract;
    }

     
     
     
    function setSiringAuctionAddress(address _address) external onlyCOO {
        SiringClockAuction candidateContract = SiringClockAuction(_address);
        require(candidateContract.isSiringClockAuction());
        siringAuction = candidateContract;
    }

     
     
     
     
     
    function createSaleAuction(
        uint _ponyId,
        uint _startingPrice,
        uint _endingPrice,
        uint _duration
    )
    external
    whenNotPaused
    {
        require(_owns(msg.sender, _ponyId));
        require(isReadyToBreed(_ponyId));
        _approve(_ponyId, saleAuction);
        saleAuction.createAuction(
            _ponyId,
            _startingPrice,
            _endingPrice,
            _duration,
            msg.sender
        );
    }

     
     
     
     
     
    function createSiringAuction(
        uint _ponyId,
        uint _startingPrice,
        uint _endingPrice,
        uint _duration
    )
    external
    whenNotPaused
    {
        require(_owns(msg.sender, _ponyId));
        require(isReadyToBreed(_ponyId));
        _approve(_ponyId, siringAuction);
        siringAuction.createAuction(
            _ponyId,
            _startingPrice,
            _endingPrice,
            _duration,
            msg.sender
        );
    }


     
     
     
    function bidOnSiringAuction(
        uint _sireId,
        uint _matronId
    )
    external
    payable
    whenNotPaused
    {
        require(_owns(msg.sender, _matronId));
        require(isReadyToBreed(_matronId));
        require(_canBreedWithViaAuction(_matronId, _sireId));

        uint currentPrice = siringAuction.getCurrentPrice(_sireId);
        require(msg.value >= currentPrice + autoBirthFee);
        siringAuction.bid.value(msg.value - autoBirthFee)(_sireId);
        _breedWith(uint32(_matronId), uint32(_sireId));
    }

     
     
    function withdrawAuctionBalances() external onlyCLevel {
        saleAuction.withdrawBalance();
        siringAuction.withdrawBalance();
    }
}


 

contract PonyMinting is PonyAuction {


     
     
     
     

     
    uint256 public GEN0_MINIMUM_STARTING_PRICE = 90 finney;

     
    uint256 public GEN0_MAXIMUM_STARTING_PRICE = 500 finney;

     
    uint256 public nextGen0PriceRate = 1000;

     
    uint256 public gen0AuctionDuration = 30 days;

     
    uint256 public promoCreatedCount;
     
    uint256 public gen0CreatedCount;

     
     
     
     
     
     
     
     
     
     
    function createPromoPony(bytes22 _genes, uint256 _retiredAge, address _owner, uint8[5] _maxStats) external onlyCOO {
        address ponyOwner = _owner;
        if (ponyOwner == address(0)) {
            ponyOwner = cooAddress;
        }
         

        promoCreatedCount++;

        uint zero = uint(0);
        uint8[5] memory ability;        
        uint8[2] memory age = [0,0];
        uint[2] memory parents = [zero, zero];
        
        
        (ability[0],ability[1],ability[2],ability[3],ability[4]) = ponyAbility.getBasicAbility(_genes);
        _createPony(0, parents, age, _genes, _retiredAge, ponyOwner,ability,_maxStats);
    }

     
     
    function createPreCorePony(bytes22 _genes, uint256 _retiredAge, address _owner, uint256 _matronId, uint256 _sireId, uint8 _age, uint8 _month, uint8[5] stats, uint8[5] maxStats) external onlyCOO {
        address ponyOwner = _owner;
        if (ponyOwner == address(0)) {
            ponyOwner = cooAddress;
        }
        uint8[2] memory age = [_age, _month];
        uint[2] memory parents = [_matronId, _sireId];        
        _createPony(1, parents, age, _genes, _retiredAge, ponyOwner, stats, maxStats);
    }

     
     
     
     
     
     
     
     
     
    function createGen0Auction(bytes22 _genes) public onlyCOO {
         
        uint zero = uint(0);
        uint8[5] memory ability;
        uint8[5] memory maxAbility = [gen0Stat.maxSpeed, gen0Stat.maxStamina, gen0Stat.maxStart, gen0Stat.maxBurst, gen0Stat.maxTemperament];
        uint8[2] memory age = [0, 0];
        uint[2] memory parents = [zero, zero];        

        (ability[0],ability[1],ability[2],ability[3],ability[4]) = ponyAbility.getBasicAbility(_genes);
        
        uint256 ponyId = _createPony(0, parents, age,_genes, gen0Stat.retiredAge, address(this),ability,maxAbility);
        _approve(ponyId, saleAuction);

        saleAuction.createAuction(
            ponyId,
            _computeNextGen0Price(),
            10 finney,
            gen0AuctionDuration,
            address(this)
        );

        gen0CreatedCount++;
    }

     
     
     
     
     
     
     
     
     
     
    function createCustomGen0Auction(bytes22 _genes, uint256 _retiredAge, uint8[5] _maxStats, uint8 _startPrice, uint _endPrice) external onlyCOO {
        require(10 finney < _startPrice);
        require(10 finney < _endPrice);

        uint zero = uint(0);
        uint8[5] memory ability;        
        uint8[2] memory age = [0, 0];
        uint[2] memory parents = [zero, zero];
        
        (ability[0],ability[1],ability[2],ability[3],ability[4]) = ponyAbility.getBasicAbility(_genes);
        
        uint256 ponyId = _createPony(0, parents, age, _genes, _retiredAge, address(this),ability,_maxStats);
        _approve(ponyId, saleAuction);

        saleAuction.createAuction(
            ponyId,
            _startPrice,
            _endPrice,
            gen0AuctionDuration,
            address(this)
        );

        gen0CreatedCount++;
    }  

     
     
    function _computeNextGen0Price()
    internal
    view
    returns (uint256)
    {
        uint256 avePrice = saleAuction.averageGen0SalePrice();
        require(avePrice == uint256(uint128(avePrice)));

        uint256 nextPrice = avePrice + (avePrice * nextGen0PriceRate / 10000);

        if (nextPrice < GEN0_MINIMUM_STARTING_PRICE) {
            nextPrice = GEN0_MINIMUM_STARTING_PRICE;
        }else if (nextPrice > GEN0_MAXIMUM_STARTING_PRICE) {
            nextPrice = GEN0_MAXIMUM_STARTING_PRICE;
        }

        return nextPrice;
    }
    
    function setAuctionDuration(uint256 _duration)
    external
    onlyCOO
    {
        gen0AuctionDuration=_duration * 1 days;
    }

     
    function setGen0Stat(uint256[6] _gen0Stat) 
    public 
    onlyCOO
    {
        gen0Stat = Gen0Stat({
            retiredAge : uint8(_gen0Stat[0]),
            maxSpeed : uint8(_gen0Stat[1]),
            maxStamina : uint8(_gen0Stat[2]),
            maxStart : uint8(_gen0Stat[3]),
            maxBurst : uint8(_gen0Stat[4]),
            maxTemperament : uint8(_gen0Stat[5])
        });
    }

     
     
    function setMinStartingPrice(uint256 _minPrice)
    public
    onlyCOO
    {
        GEN0_MINIMUM_STARTING_PRICE = _minPrice;
    }

     
     
    function setMaxStartingPrice(uint256 _maxPrice)
    public
    onlyCOO
    {
        GEN0_MAXIMUM_STARTING_PRICE = _maxPrice;
    }    

     
     
    function setNextGen0PriceRate(uint256 _increaseRate)
    public
    onlyCOO
    {
        require(_increaseRate <= 10000);
        nextGen0PriceRate = _increaseRate;
    }
    
}


 

contract PonyDerby is PonyMinting {
     
     
     
    function isPonyRetired(uint256 _id)
    external
    view
    returns (
        bool isRetired

    ) {
        Pony storage pony = ponies[_id];
        if (pony.age >= pony.retiredAge) {
            isRetired = true;
        } else {
            isRetired = false;
        }
    }

     
    function setPonyInfo(uint _id, uint8 age, uint8 month, uint8 speed, uint8 stamina, uint8 start, uint8 burst, uint8 temperament)
    public
    onlyDerbyAdress
    {       
        Pony storage pony = ponies[_id];
        pony.age = age;
        pony.month = month;

        Ability storage _ability = ability[_id];        
        _ability.speed = speed;
        _ability.stamina = stamina;
        _ability.start = start;
        _ability.burst = burst;
        _ability.temperament = temperament;
    }

     
    function setPonyMaxStat(uint _id, uint8 maxSpeed, uint8 maxStamina, uint8 maxStart, uint8 maxBurst, uint8 maxTemperament)
    public
    onlyDerbyAdress
    {   
        Ability storage _ability = ability[_id];        
        _ability.maxSpeed = maxSpeed;
        _ability.maxStamina = maxStamina;
        _ability.maxStart = maxStart;
        _ability.maxBurst = maxBurst;
        _ability.maxTemperament = maxTemperament;
    }

     
     
     
     
     
     
     
     
     
     
     
     

    function getAbility(uint _id)
    public
    view
    returns (
        uint8 speed,
        uint8 stamina,
        uint8 start,
        uint8 burst,
        uint8 temperament,
        uint8 maxSpeed,
        uint8 maxStamina,
        uint8 maxBurst,
        uint8 maxStart,
        uint8 maxTemperament

    ){
        Ability memory _ability = ability[_id];
        speed = _ability.speed;
        stamina = _ability.stamina;
        start = _ability.start;
        burst = _ability.burst;
        temperament = _ability.temperament;
        maxSpeed = _ability.maxSpeed;
        maxStamina = _ability.maxStamina;
        maxBurst = _ability.maxBurst;
        maxStart = _ability.maxStart;
        maxTemperament = _ability.maxTemperament;
    }


}

 
 

contract PonyCore is PonyDerby {

    address public newContractAddress;

     
    constructor() public payable {
        paused = true;
        cfoAddress = msg.sender;
        cooAddress = msg.sender;
    }

     
    function genesisPonyInit(bytes22 _gensis, uint8[5] _ability, uint8[5] _maxAbility, uint[6] _gen0Stat) external onlyCOO whenPaused {
        require(ponies.length==0);
        uint zero = uint(0);
        uint[2] memory parents = [zero, zero];
        uint8[2] memory age = [0, 0];                
        _createPony(0, parents, age, _gensis, 100, address(0),_ability,_maxAbility);
        setGen0Stat(_gen0Stat);
    }

    function setNewAddress(address _v2Address)
    external
    onlyCOO whenPaused
    {
        newContractAddress = _v2Address;
        emit ContractUpgrade(_v2Address);
    }


    function() external payable {
         
    }

     
     
    function getPony(uint256 _id)
    external
    view
    returns (        
        bool isReady,
        uint256 cooldownEndBlock,        
        uint256 birthTime,
        uint256 matronId,
        uint256 sireId,
        bytes22 genes,
        uint256 age,
        uint256 month,
        uint256 retiredAge        
    ) {
        Pony storage pony = ponies[_id];        
        isReady = (pony.cooldownEndBlock <= block.number);
        cooldownEndBlock = pony.cooldownEndBlock;        
        birthTime = uint256(pony.birthTime);
        matronId = uint256(pony.matronId);
        sireId = uint256(pony.sireId);
        genes =  pony.genes;
        age = uint256(pony.age);
        month = uint256(pony.month);
        retiredAge = uint256(pony.retiredAge);        
    }

     
     
     
    function unPause()
    public
    onlyCOO
    whenPaused
    {
        require(saleAuction != address(0));
        require(siringAuction != address(0));
        require(geneScience != address(0));
        require(ponyAbility != address(0));
        require(newContractAddress == address(0));

        super.unPause();
    }

     
     
    function withdrawBalance(uint256 _value)
    external
    onlyCLevel
    {
        uint256 balance = address(this).balance;
        require(balance >= _value);        
        cfoAddress.transfer(_value);
    }

    function buyCarrot(uint256 carrotCount)
    external
    payable
    whenNotPaused
    {
        emit carrotPurchased(msg.sender, msg.value, carrotCount);
    }

    event RewardSendSuccessful(address from, address to, uint value);    

    function sendRankingReward(address[] _recipients, uint256[] _rewards)
    external
    payable
    onlyRewardAdress
    {
        for(uint i = 0; i < _recipients.length; i++){
            _recipients[i].transfer(_rewards[i]);
            emit RewardSendSuccessful(this, _recipients[i], _rewards[i]);
        }
    }

    event CarrotToETHSuccessful(address to, uint256 count, uint value);

    function sendCarrotToETH(address _recipient, uint256 _carrotCount, uint256 _value)
    external
    payable
    onlyRewardAdress
    {        
        _recipient.transfer(_value);
        emit CarrotToETHSuccessful(_recipient, _carrotCount, _value);     
    }

}
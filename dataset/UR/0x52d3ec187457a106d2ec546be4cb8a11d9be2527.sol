 

pragma solidity ^0.4.18;

 
 
 
interface ERC721 {

     

     
     
     

     
     
     
     
     
     
     
     

     
     
     
     
    function supportsInterface(bytes4 _interfaceID) external pure returns (bool);

     

     
     
     
     
     
     
    function ownerOf(uint256 _deedId) external view returns (address _owner);

     
     
     
    function countOfDeeds() external view returns (uint256 _count);

     
     
     
     
    function countOfDeedsByOwner(address _owner) external view returns (uint256 _count);

     
     
     
     
     
     
     
    function deedOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256 _deedId);

     

     
     
     
     
     
    event Transfer(address indexed from, address indexed to, uint256 indexed deedId);

     
     
     
     
     
     
     
     
    event Approval(address indexed owner, address indexed approved, uint256 indexed deedId);

     
     
     
     
     
     
     
    function approve(address _to, uint256 _deedId) external payable;

     
     
     
     
     
    function takeOwnership(uint256 _deedId) external payable;
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
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
}

contract MonsterAccessControl {
    event ContractUpgrade(address newContract);

      
    address public adminAddress;

     
    modifier onlyAdmin() {
        require(msg.sender == adminAddress);
        _;
    }
}

 
 
 
 
 
contract MonstersData {
    address coreContract;

    struct Monster {
         
        uint64 birthTime;

         
         
         
        uint16 generation;

        uint16 mID;  
        bool tradeable;

         
        bool female;

         
        bool shiny;
    }

     
    struct MonsterBaseStats {
        uint16 hp;
        uint16 attack;
        uint16 defense;
        uint16 spAttack;
        uint16 spDefense;
        uint16 speed;
    }

    struct Trainer {
         
        uint64 birthTime;

         
        string username;

         
        uint16 currArea;

        address owner;
    }

     
    uint64 creationBlock = uint64(now);
}

contract MonstersBase is MonsterAccessControl, MonstersData {
     
     
    event Transfer(address from, address to, uint256 tokenId);

    bool lockedMonsterCreator = false;

    MonsterAuction public monsterAuction;
    MonsterCreatorInterface public monsterCreator;

    function setMonsterCreatorAddress(address _address) external onlyAdmin {
         
        require(!lockedMonsterCreator);
        MonsterCreatorInterface candidateContract = MonsterCreatorInterface(_address);

        monsterCreator = candidateContract;
        lockedMonsterCreator = true;
    }

     
    uint256 public secondsPerBlock = 15;

     
    Monster[] monsters;

    uint8[] areas;
    uint8 areaIndex = 0;

    mapping(address => Trainer) public addressToTrainer;
     
     
    mapping (uint256 => address) public monsterIndexToOwner;
     
     
    mapping (address => uint256) ownershipTokenCount;
    mapping (uint256 => address) public monsterIndexToApproved;
    mapping (uint256 => string) public monsterIdToNickname;
    mapping (uint256 => bool) public monsterIdToTradeable;
    mapping (uint256 => uint256) public monsterIdToGeneration;
    
    mapping (uint256 => uint8[7]) public monsterIdToIVs;

     
    function _createArea() internal {
        areaIndex++;
        areas.push(areaIndex);
    }

    function _createMonster(uint256 _generation, address _owner, uint256 _mID, bool _tradeable,
        bool _female, bool _shiny) internal returns (uint)
    {

        Monster memory _monster = Monster({
            generation: uint16(_generation),
            birthTime: uint64(now),
            mID: uint16(_mID),
            tradeable: _tradeable,
            female: _female,
            shiny: _shiny
        });

        uint256 newMonsterId = monsters.push(_monster) - 1;

        require(newMonsterId == uint256(uint32(newMonsterId)));

        monsterIdToNickname[newMonsterId] = "";

        _transfer(0, _owner, newMonsterId);

        return newMonsterId;
    }

    function _createTrainer(string _username, uint16 _starterId, address _owner) internal returns (uint mon) {
        Trainer memory _trainer = Trainer({
            birthTime: uint64(now),
            username: string(_username),
              
            currArea: uint16(1),
            owner: address(_owner)
        });

        addressToTrainer[_owner] = _trainer;

        bool gender = monsterCreator.getMonsterGender();

         
        if (_starterId == 1) {
            mon = _createMonster(0, _owner, 1, false, gender, false);
        } else if (_starterId == 2) {
            mon = _createMonster(0, _owner, 4, false, gender, false);
        } else if (_starterId == 3) {
            mon = _createMonster(0, _owner, 7, false, gender, false);
        }
    }

    function _moveToArea(uint16 _newArea, address player) internal {
        addressToTrainer[player].currArea = _newArea;
    }

     
    function _transfer(address _from, address _to, uint256 _tokenId) internal {
        ownershipTokenCount[_to]++;
        monsterIndexToOwner[_tokenId] = _to;

        if (_from != address(0)) {
            ownershipTokenCount[_from]--;

             
            delete monsterIndexToApproved[_tokenId];
        }

         
        Transfer(_from, _to, _tokenId);
    }

     
    function setSecondsPerBlock(uint256 secs) external onlyAdmin {
         
        secondsPerBlock = secs;
    }
}

contract MonsterOwnership is MonstersBase, ERC721 {
    function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return monsterIndexToOwner[_tokenId] == _claimant;
    }

    function _isTradeable(uint256 _tokenId) public view returns (bool) {
        return monsterIdToTradeable[_tokenId];
    }

     
     
     
    function _approvedFor(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return monsterIndexToApproved[_tokenId] == _claimant;
    }

    function balanceOf(address _owner) public view returns (uint256 count) {
        return ownershipTokenCount[_owner];
    }

    function transfer(address _to, uint256 _tokenId) public payable {
        transferFrom(msg.sender, _to, _tokenId);
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) public payable {
        require(monsterIdToTradeable[_tokenId]);
         
        require(_to != address(0));
         
         
         
        require(_to != address(this));
         
        
        require(_owns(_from, _tokenId));
         
        require(_from == msg.sender || msg.sender == address(monsterAuction) || _approvedFor(_to, _tokenId));

         
        _transfer(_from, _to, _tokenId);
    }

    function totalSupply() public view returns (uint) {
        return monsters.length;
    }

    function tokensOfOwner(address _owner) public view returns (uint256[] ownerTokens) {
        uint256 tokenCount = balanceOf(_owner);

        if (tokenCount > 0) {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 totalMonsters = totalSupply();
            uint256 resultIndex = 0;

            uint256 monsterId;

            for (monsterId = 0; monsterId <= totalMonsters; monsterId++) {
                if (monsterIndexToOwner[monsterId] == _owner) {
                    result[resultIndex] = monsterId;
                    resultIndex++;
                }
            }

            return result;
        }

        return new uint256[](0);
    }

    bytes4 internal constant INTERFACE_SIGNATURE_ERC165 =
        bytes4(keccak256("supportsInterface(bytes4)"));

    bytes4 internal constant INTERFACE_SIGNATURE_ERC721 =
        bytes4(keccak256("ownerOf(uint256)")) ^
        bytes4(keccak256("countOfDeeds()")) ^
        bytes4(keccak256("countOfDeedsByOwner(address)")) ^
        bytes4(keccak256("deedOfOwnerByIndex(address,uint256)")) ^
        bytes4(keccak256("approve(address,uint256)")) ^
        bytes4(keccak256("takeOwnership(uint256)"));

    function supportsInterface(bytes4 _interfaceID) external pure returns (bool) {
        return _interfaceID == INTERFACE_SIGNATURE_ERC165 || _interfaceID == INTERFACE_SIGNATURE_ERC721;
    }

    function ownerOf(uint256 _deedId) external view returns (address _owner) {
        var owner = monsterIndexToOwner[_deedId];
        require(owner != address(0));
        return owner;
    }

    function _approve(uint256 _tokenId, address _approved) internal {
        monsterIndexToApproved[_tokenId] = _approved;
    }

    function countOfDeeds() external view returns (uint256 _count) {
        return totalSupply();
    }

    function countOfDeedsByOwner(address _owner) external view returns (uint256 _count) {
        var arr = tokensOfOwner(_owner);
        return arr.length;
    }

    function deedOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256 _deedId) {
        return tokensOfOwner(_owner)[_index];
    }

    function approve(address _to, uint256 _tokenId) external payable {
         
        require(_owns(msg.sender, _tokenId));

         
        monsterIndexToApproved[_tokenId] = _to;

         
        Approval(msg.sender, _to, _tokenId);
    }

    function takeOwnership(uint256 _deedId) external payable {
        transferFrom(this.ownerOf(_deedId), msg.sender, _deedId);
    }
}

contract MonsterAuctionBase {

     
    MonsterOwnership public nonFungibleContract;
    ChainMonstersCore public core;

    struct Auction {
         
        address seller;
         
        uint256 price;
         
        uint64 startedAt;
        uint256 id;
    }

     
     
    uint256 public ownerCut;

     
    mapping(uint256 => Auction) tokenIdToAuction;
    mapping(uint256 => address) public auctionIdToSeller;
    mapping (address => uint256) public ownershipAuctionCount;

    event AuctionCreated(uint256 tokenId, uint256 price, uint256 uID, address seller);
    event AuctionSuccessful(uint256 tokenId, uint256 price, address newOwner, uint256 uID);
    event AuctionCancelled(uint256 tokenId, uint256 uID);

    function _transfer(address _receiver, uint256 _tokenId) internal {
         
        nonFungibleContract.transfer(_receiver, _tokenId);
    }

    function _addAuction(uint256 _tokenId, Auction _auction) internal {
        tokenIdToAuction[_tokenId] = _auction;

        AuctionCreated(
            uint256(_tokenId),
            uint256(_auction.price),
            uint256(_auction.id),
            address(_auction.seller)
        );
    }

    function _cancelAuction(uint256 _tokenId, address _seller) internal {
        Auction storage _auction = tokenIdToAuction[_tokenId];

        uint256 uID = _auction.id;

        _removeAuction(_tokenId);
        ownershipAuctionCount[_seller]--;
        _transfer(_seller, _tokenId);

        AuctionCancelled(_tokenId, uID);
    }

    function _buy(uint256 _tokenId, uint256 _bidAmount) internal returns (uint256) {
        Auction storage auction = tokenIdToAuction[_tokenId];

        require(_isOnAuction(auction));

        uint256 price = auction.price;
        require(_bidAmount >= price);

        address seller = auction.seller;
        uint256 uID = auction.id;

         
        _removeAuction(_tokenId);

        ownershipAuctionCount[seller]--;

        if (price > 0) {
            uint256 auctioneerCut = _computeCut(price);
            uint256 sellerProceeds = price - auctioneerCut;

             
             
             
             
             
             
             
             
            if (seller != address(core)) {
                seller.transfer(sellerProceeds);
            }
        }

         
         
         
         
        uint256 bidExcess = _bidAmount - price;

         
         
         
        msg.sender.transfer(bidExcess);

         
        AuctionSuccessful(_tokenId, price, msg.sender, uID);

        return price;
    }

    function _removeAuction(uint256 _tokenId) internal {
        delete tokenIdToAuction[_tokenId];
    }

    function _isOnAuction(Auction storage _auction) internal view returns (bool) {
        return (_auction.startedAt > 0);
    }

     function _computeCut(uint256 _price) internal view returns (uint256) {
         
         
         
         
         
        return _price * ownerCut / 10000;
    }
}

contract MonsterAuction is  MonsterAuctionBase, Ownable {
    bool public isMonsterAuction = true;
    uint256 public auctionIndex = 0;

    function MonsterAuction(address _nftAddress, uint256 _cut) public {
        require(_cut <= 10000);
        ownerCut = _cut;

        var candidateContract = MonsterOwnership(_nftAddress);

        nonFungibleContract = candidateContract;
        ChainMonstersCore candidateCoreContract = ChainMonstersCore(_nftAddress);
        core = candidateCoreContract;
    }

     
    function setOwnerCut(uint256 _cut) external onlyOwner {
        require(_cut <= ownerCut);
        ownerCut = _cut;
    }

    function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return (nonFungibleContract.ownerOf(_tokenId) == _claimant);
    }

    function _escrow(address _owner, uint256 _tokenId) internal {
         
        nonFungibleContract.transferFrom(_owner, this, _tokenId);
    }

    function withdrawBalance() external onlyOwner {
        uint256 balance = this.balance;
        owner.transfer(balance);
    }

    function tokensInAuctionsOfOwner(address _owner) external view returns(uint256[] auctionTokens) {
        uint256 numAuctions = ownershipAuctionCount[_owner];

        uint256[] memory result = new uint256[](numAuctions);
        uint256 totalAuctions = core.totalSupply();
        uint256 resultIndex = 0;

        uint256 auctionId;

        for (auctionId = 0; auctionId <= totalAuctions; auctionId++) {
            Auction storage auction = tokenIdToAuction[auctionId];
            if (auction.seller == _owner) {
                result[resultIndex] = auctionId;
                resultIndex++;
            }
        }

        return result;
    }

    function createAuction(uint256 _tokenId, uint256 _price, address _seller) external {
        require(_seller != address(0));
        require(_price == uint256(_price));
        require(core._isTradeable(_tokenId));
        require(_owns(msg.sender, _tokenId));

        
        _escrow(msg.sender, _tokenId);

        Auction memory auction = Auction(
            _seller,
            uint256(_price),
            uint64(now),
            uint256(auctionIndex)
        );

        auctionIdToSeller[auctionIndex] = _seller;
        ownershipAuctionCount[_seller]++;

        auctionIndex++;
        _addAuction(_tokenId, auction);
    }

    function buy(uint256 _tokenId) external payable {
         
         
        _buy (_tokenId, msg.value);
        _transfer(msg.sender, _tokenId);
    }

    function cancelAuction(uint256 _tokenId) external {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));

        address seller = auction.seller;
        require(msg.sender == seller);

        _cancelAuction(_tokenId, seller);
    }

    function getAuction(uint256 _tokenId) external view returns (address seller, uint256 price, uint256 startedAt) {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));

        return (
            auction.seller,
            auction.price,
            auction.startedAt
        );
    }

    function getPrice(uint256 _tokenId) external view returns (uint256) {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        return auction.price;
    }
}

contract ChainMonstersAuction is MonsterOwnership {
    bool lockedMonsterAuction = false;

    function setMonsterAuctionAddress(address _address) external onlyAdmin {
        require(!lockedMonsterAuction);
        MonsterAuction candidateContract = MonsterAuction(_address);

        require(candidateContract.isMonsterAuction());

        monsterAuction = candidateContract;
        lockedMonsterAuction = true;
    }

    uint256 public constant PROMO_CREATION_LIMIT = 5000;
    uint256 public constant GEN0_CREATION_LIMIT = 5000;

     
    uint256 public promoCreatedCount;
    uint256 public gen0CreatedCount;

     
    function createPromoMonster(uint256 _mId, address _owner) external onlyAdmin {
         
         
         
        
         
        require(monsterCreator.baseStats(_mId, 1) > 0);
        
        require(promoCreatedCount < PROMO_CREATION_LIMIT);

        promoCreatedCount++;

        uint8[7] memory ivs = uint8[7](monsterCreator.getGen0IVs());

        bool gender = monsterCreator.getMonsterGender();
        
        bool shiny = false;
        if (ivs[6] == 1) {
            shiny = true;
        }
        uint256 monsterId = _createMonster(0, _owner, _mId, true, gender, shiny);
        monsterIdToTradeable[monsterId] = true;

        monsterIdToIVs[monsterId] = ivs;
    }

    function createGen0Auction(uint256 _mId, uint256 price) external onlyAdmin {
          
        require(monsterCreator.baseStats(_mId, 1) > 0);
        
        require(gen0CreatedCount < GEN0_CREATION_LIMIT);

        uint8[7] memory ivs = uint8[7](monsterCreator.getGen0IVs());

        bool gender = monsterCreator.getMonsterGender();
        
        bool shiny = false;
        if (ivs[6] == 1) {
            shiny = true;
        }
        
        uint256 monsterId = _createMonster(0, this, _mId, true, gender, shiny);
        monsterIdToTradeable[monsterId] = true;

        _approve(monsterId, monsterAuction);

        monsterIdToIVs[monsterId] = ivs;

        monsterAuction.createAuction(monsterId, price, address(this));

        gen0CreatedCount++;
    }
}

 
 
 
 
contract MonsterChampionship is Ownable {

    bool public isMonsterChampionship = true;

    ChainMonstersCore core;

     
    address[10] topTen;

     
    address public currChampion;

    mapping (address => uint256) public addressToPowerlevel;
    mapping (uint256 => address) public rankToAddress;
    
     
     
     
    function contestChampion(uint256 _tokenId) external {
         

         
         
         
         
        if (currChampion == msg.sender) {
            revert();
        }

        require(core.isTrainer(msg.sender));
        require(core.monsterIndexToOwner(_tokenId) == msg.sender);

       
        
        var (n, m, stats, l, k, d) =  core.getMonster(_tokenId);
         
        
        uint256 myPowerlevel = uint256(stats[0]) + uint256(stats[1]) + uint256(stats[2]) + uint256(stats[3]) + uint256(stats[4]) + uint256(stats[5]);
        

         
         
         
        require(myPowerlevel > addressToPowerlevel[msg.sender]);

        uint myRank = 0;

        for (uint i = 0; i <= 9; i++) {
            if (myPowerlevel > addressToPowerlevel[topTen[i]]) {
                 
                myRank = i;

                if (myRank == 9) {
                    currChampion = msg.sender;
                }
            }
        }

        addressToPowerlevel[msg.sender] = myPowerlevel;

        address[10] storage newTopTen = topTen;

        if (currChampion == msg.sender) {
            for (uint j = 0; j < 9; j++) {
                 
                if (newTopTen[j] == msg.sender) {
                    newTopTen[j] = 0x0;
                    break;
                }
            }
        }

        for (uint x = 0; x <= myRank; x++) {
            if (x == myRank) {
                newTopTen[x] = msg.sender;
            } else {
                if (x < 9)
                    newTopTen[x] = topTen[x+1];
            }
        }

        topTen = newTopTen;
    }

    function getTopPlayers() external view returns (address[10] players) {
        players = topTen;
    }

    function MonsterChampionship(address coreContract) public {
        core = ChainMonstersCore(coreContract);
    }

    function withdrawBalance() external onlyOwner {
        uint256 balance = this.balance;
        owner.transfer(balance);
    }
}


 
contract MonsterCreatorInterface is Ownable {
    uint8 public lockedMonsterStatsCount = 0;
    uint nonce = 0;

    function rand(uint16 min, uint16 max) public returns (uint16) {
        nonce++;
        uint16 result = (uint16(keccak256(block.blockhash(block.number-1), nonce))%max);

        if (result < min) {
            result = result+min;
        }

        return result;
    }

    mapping(uint256 => uint8[8]) public baseStats;

    function addBaseStats(uint256 _mId, uint8[8] data) external onlyOwner {
         
         
         
        require(data[0] > 0);
        require(baseStats[_mId][0] == 0);
        baseStats[_mId] = data;
    }

    function _addBaseStats(uint256 _mId, uint8[8] data) internal {
        baseStats[_mId] = data;
        lockedMonsterStatsCount++;
    }

    function MonsterCreatorInterface() public {
        
        _addBaseStats(1, [45, 49, 49, 65, 65, 45, 12, 4]);
        _addBaseStats(2, [60, 62, 63, 80, 80, 60, 12, 4]);
        _addBaseStats(3, [80, 82, 83, 100, 100, 80, 12, 4]);
        _addBaseStats(4, [39, 52, 43, 60, 50, 65, 10, 6]);
        _addBaseStats(5, [58, 64, 58, 80, 65, 80, 10, 6]);
        _addBaseStats(6, [78, 84, 78, 109, 85, 100, 10, 6]);
        _addBaseStats(7, [44, 48, 65, 50, 64, 43, 11, 14]);
        _addBaseStats(8, [59, 63, 80, 65, 80, 58, 11, 14]);
        _addBaseStats(9, [79, 83, 100, 85, 105, 78, 11, 14]);
        _addBaseStats(10, [40, 35, 30, 20, 20, 50, 7, 4]);

        _addBaseStats(149, [55, 50, 45, 135, 95, 120, 8, 14]);
        _addBaseStats(150, [91, 134, 95, 100, 100, 80, 2, 5]);
        _addBaseStats(151, [100, 100, 100, 100, 100, 100, 5, 19]);
    }

     
     
     
     
    function getMonsterStats( uint256 _mID) external constant returns(uint8[8] stats) {
        stats[0] = baseStats[_mID][0];
        stats[1] = baseStats[_mID][1];
        stats[2] = baseStats[_mID][2];
        stats[3] = baseStats[_mID][3];
        stats[4] = baseStats[_mID][4];
        stats[5] = baseStats[_mID][5];
        stats[6] = baseStats[_mID][6];
        stats[7] = baseStats[_mID][7];
    }

    function getMonsterGender () external returns(bool female) {
        uint16 femaleChance = rand(0, 100);

        if (femaleChance >= 50) {
            female = true;
        }
    }

     
    function getMonsterIVs() external returns(uint8[7] ivs) {
        bool shiny = false;

        uint16 chance = rand(1, 8192);

        if (chance == 42) {
            shiny = true;
        }

         
         
        if (shiny) {
            ivs[0] = uint8(rand(10, 31));
            ivs[1] = uint8(rand(10, 31));
            ivs[2] = uint8(rand(10, 31));
            ivs[3] = uint8(rand(10, 31));
            ivs[4] = uint8(rand(10, 31));
            ivs[5] = uint8(rand(10, 31));
            ivs[6] = 1;

        } else {
            ivs[0] = uint8(rand(0, 31));
            ivs[1] = uint8(rand(0, 31));
            ivs[2] = uint8(rand(0, 31));
            ivs[3] = uint8(rand(0, 31));
            ivs[4] = uint8(rand(0, 31));
            ivs[5] = uint8(rand(0, 31));
            ivs[6] = 0;
        }
    }

     
     
    function getGen0IVs() external returns (uint8[7] ivs) {
        bool shiny = false;

        uint16 chance = rand(1, 4096);

        if (chance == 42) {
            shiny = true;
        }

        if (shiny) {
            ivs[0] = uint8(rand(15, 31));
            ivs[1] = uint8(rand(15, 31));
            ivs[2] = uint8(rand(15, 31));
            ivs[3] = uint8(rand(15, 31));
            ivs[4] = uint8(rand(15, 31));
            ivs[5] = uint8(rand(15, 31));
            ivs[6] = 1;
        } else {
            ivs[0] = uint8(rand(10, 31));
            ivs[1] = uint8(rand(10, 31));
            ivs[2] = uint8(rand(10, 31));
            ivs[3] = uint8(rand(10, 31));
            ivs[4] = uint8(rand(10, 31));
            ivs[5] = uint8(rand(10, 31));
            ivs[6] = 0;
        }
    }

    function withdrawBalance() external onlyOwner {
        uint256 balance = this.balance;
        owner.transfer(balance);
    }
}

contract GameLogicContract {
    bool public isGameLogicContract = true;

    function GameLogicContract() public {

    }
}


contract OmegaContract {
    bool public isOmegaContract = true;

    function OmegaContract() public {

    }
}

contract ChainMonstersCore is ChainMonstersAuction, Ownable {
     
    bool hasLaunched = false;

     
    address gameContract;

     
    address omegaContract;

    function ChainMonstersCore() public {
        adminAddress = msg.sender;

        _createArea();  
        _createArea();  
    }

     
     
    function setGameLogicContract(address _candidateContract) external onlyOwner {
        require(monsterCreator.lockedMonsterStatsCount() == 151);

        require(GameLogicContract(_candidateContract).isGameLogicContract());

        gameContract = _candidateContract;
    }

    function setOmegaContract(address _candidateContract) external onlyOwner {
        require(OmegaContract(_candidateContract).isOmegaContract());
        omegaContract = _candidateContract;
    }

     
    function evolveMonster(uint256 _tokenId, uint16 _toMonsterId) external {
        require(msg.sender == omegaContract);

         
        Monster storage mon = monsters[_tokenId];

         
         
        mon.mID = _toMonsterId;
    }

     
     
     
     
    function spawnMonster(uint256 _mId, address _owner) external {
        require(msg.sender == gameContract);

        uint8[7] memory ivs = uint8[7](monsterCreator.getMonsterIVs());

        bool gender = monsterCreator.getMonsterGender();

        bool shiny = false;
        if (ivs[6] == 1) {
            shiny = true;
        }
        
         
         
        uint256 monsterId = _createMonster(1, _owner, _mId, false, gender, shiny);
        monsterIdToTradeable[monsterId] = true;

        monsterIdToIVs[monsterId] = ivs;
    }

     
     
     
     
    function createArea() public onlyAdmin {
        _createArea();
    }

    function createTrainer(string _username, uint16 _starterId) public {
        require(hasLaunched);

         
        require(addressToTrainer[msg.sender].owner == 0);

         
        require(_starterId == 1 || _starterId == 2 || _starterId == 3);

        uint256 mon = _createTrainer(_username, _starterId, msg.sender);

         
        monsterIdToIVs[mon] = monsterCreator.getMonsterIVs();
    }

    function changeUsername(string _name) public {
        require(addressToTrainer[msg.sender].owner == msg.sender);
        addressToTrainer[msg.sender].username = _name;
    }

    function changeMonsterNickname(uint256 _tokenId, string _name) public {
         
        require(_owns(msg.sender, _tokenId));

         
        monsterIdToNickname[_tokenId] = _name;
    }

    function moveToArea(uint16 _newArea) public {
        require(addressToTrainer[msg.sender].currArea > 0);

         
         
        require(_newArea > 0);

         
        require(areas.length >= _newArea);

         
        _moveToArea(_newArea, msg.sender);
    }

     
    function getMonster(uint256 _id) external view returns (
        uint256 birthTime, uint256 generation, uint8[8] stats,
        uint256 mID, bool tradeable, uint256 uID)
    {
        Monster storage mon = monsters[_id];
        birthTime = uint256(mon.birthTime);
        generation = mon.generation;  
        mID = uint256(mon.mID);
        tradeable = bool(mon.tradeable);

         
        stats = uint8[8](monsterCreator.getMonsterStats(uint256(mon.mID)));

         
        uID = _id;
    }

    function isTrainer(address _check) external view returns (bool isTrainer) {
        Trainer storage trainer = addressToTrainer[_check];

        return (trainer.currArea > 0);
    }

    function withdrawBalance() external onlyOwner {
        uint256 balance = this.balance;

        owner.transfer(balance);
    }

     
     
    function launchGame() external onlyOwner {
        hasLaunched = true;
    }
}
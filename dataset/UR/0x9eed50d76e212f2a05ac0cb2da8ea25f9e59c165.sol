 

pragma solidity ^0.5.0;

contract ICards {

    enum Rarity {
        Common, Rare, Epic, Legendary, Mythic
    }

    function getRandomCard(Rarity rarity, uint16 random) public view returns (uint16);
    function createCard(address user, uint16 proto, uint16 purity) public returns (uint);


}


 
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


 
library SafeMath64 {

     
    function mul(uint64 a, uint64 b) internal pure returns (uint64 c) {
         
         
         
        if (a == 0) {
            return 0;
        }

        c = a * b;
        assert(c / a == b);
        return c;
    }

     
    function div(uint64 a, uint64 b) internal pure returns (uint64) {
         
         
         
        return a / b;
    }

     
    function sub(uint64 a, uint64 b) internal pure returns (uint64) {
        assert(b <= a);
        return a - b;
    }

     
    function add(uint64 a, uint64 b) internal pure returns (uint64 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}


contract Ownable {

    address payable public owner;

    constructor() public {
        owner = msg.sender;
    }

    function setOwner(address payable _owner) public onlyOwner {
        owner = _owner;
    }

    function getOwner() public view returns (address payable) {
        return owner;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "must be owner to call this function");
        _;
    }

}

interface IProcessor {

    function processPayment(address user, uint cost, uint items, address referrer) external payable returns (uint id);
    
}

contract Pack {

    enum Type {
        Rare, Epic, Legendary, Shiny
    }

}

contract RarityProvider {

    ICards cards;

    constructor(ICards _cards) public {
        cards = _cards;
    }

    struct RandomnessComponents {
        uint random;
        uint32 rarity;
        uint16 quality;
        uint16 purity;
        uint16 proto;
    }

     
    function extract(uint num, uint length, uint start) internal pure returns (uint) {
        return (((1 << (length * 8)) - 1) & (num >> ((start - 1) * 8)));
    }

     
    function getComponents(
        uint cardIndex, uint rand
    ) internal pure returns (
        RandomnessComponents memory
    ) {
        uint random = uint(keccak256(abi.encodePacked(cardIndex, rand)));
        return RandomnessComponents({
            random: random,
            rarity: uint32(extract(random, 4, 10) % 1000000),
            quality: uint16(extract(random, 2, 4) % 1000),
            purity: uint16(extract(random, 2, 6) % 1000),
            proto: uint16(extract(random, 2, 8) % (2**16-1))
        });
    }

    function getCardDetails(Pack.Type packType, uint cardIndex, uint result) internal view returns (uint16, uint16) {
        if (packType == Pack.Type.Shiny) {
            return _getShinyCardDetails(cardIndex, result);
        } else if (packType == Pack.Type.Legendary) {
            return _getLegendaryCardDetails(cardIndex, result);
        } else if (packType == Pack.Type.Epic) {
            return _getEpicCardDetails(cardIndex, result);
        }
        return _getRareCardDetails(cardIndex, result);
    }

    function _getShinyCardDetails(uint cardIndex, uint result) internal view returns (uint16 proto, uint16 purity) {
        
        RandomnessComponents memory rc = getComponents(cardIndex, result); 

        ICards.Rarity rarity;

        if (cardIndex == 4) {
            rarity = _getLegendaryPlusRarity(rc.rarity);
            purity = _getShinyPurityBase(rc.quality) + rc.purity;
        } else if (cardIndex == 3) {
            rarity = _getRarePlusRarity(rc.rarity);
            purity = _getPurityBase(rc.quality) + rc.purity;
        } else {
            rarity = _getCommonPlusRarity(rc.rarity);
            purity = _getPurityBase(rc.quality) + rc.purity;
        }
        proto = cards.getRandomCard(rarity, rc.proto);
        return (proto, purity);
    }

    function _getLegendaryCardDetails(uint cardIndex, uint result) internal view returns (uint16 proto, uint16 purity) {
        
        RandomnessComponents memory rc = getComponents(cardIndex, result);

        ICards.Rarity rarity;

        if (cardIndex == 4) {
            rarity = _getLegendaryPlusRarity(rc.rarity);
        } else if (cardIndex == 3) {
            rarity = _getRarePlusRarity(rc.rarity);
        } else {
            rarity = _getCommonPlusRarity(rc.rarity);
        }

        purity = _getPurityBase(rc.quality) + rc.purity;
    
        proto = cards.getRandomCard(rarity, rc.proto);

        return (proto, purity);
    } 


    function _getEpicCardDetails(uint cardIndex, uint result) internal view returns (uint16 proto, uint16 purity) {
        
        RandomnessComponents memory rc = getComponents(cardIndex, result);

        ICards.Rarity rarity;

        if (cardIndex == 4) {
            rarity = _getEpicPlusRarity(rc.rarity);
        } else {
            rarity = _getCommonPlusRarity(rc.rarity);
        }

        purity = _getPurityBase(rc.quality) + rc.purity;
    
        proto = cards.getRandomCard(rarity, rc.proto);

        return (proto, purity);
    } 

    function _getRareCardDetails(uint cardIndex, uint result) internal view returns (uint16 proto, uint16 purity) {

        RandomnessComponents memory rc = getComponents(cardIndex, result);

        ICards.Rarity rarity;

        if (cardIndex == 4) {
            rarity = _getRarePlusRarity(rc.rarity);
        } else {
            rarity = _getCommonPlusRarity(rc.rarity);
        }

        purity = _getPurityBase(rc.quality) + rc.purity;
    
        proto = cards.getRandomCard(rarity, rc.proto);
        return (proto, purity);
    }  


    function _getCommonPlusRarity(uint32 rand) internal pure returns (ICards.Rarity) {
        if (rand == 999999) {
            return ICards.Rarity.Mythic;
        } else if (rand >= 998345) {
            return ICards.Rarity.Legendary;
        } else if (rand >= 986765) {
            return ICards.Rarity.Epic;
        } else if (rand >= 924890) {
            return ICards.Rarity.Rare;
        } else {
            return ICards.Rarity.Common;
        }
    }

    function _getRarePlusRarity(uint32 rand) internal pure returns (ICards.Rarity) {
        if (rand == 999999) {
            return ICards.Rarity.Mythic;
        } else if (rand >= 981615) {
            return ICards.Rarity.Legendary;
        } else if (rand >= 852940) {
            return ICards.Rarity.Epic;
        } else {
            return ICards.Rarity.Rare;
        } 
    }

    function _getEpicPlusRarity(uint32 rand) internal pure returns (ICards.Rarity) {
        if (rand == 999999) {
            return ICards.Rarity.Mythic;
        } else if (rand >= 981615) {
            return ICards.Rarity.Legendary;
        } else {
            return ICards.Rarity.Epic;
        }
    }

    function _getLegendaryPlusRarity(uint32 rand) internal pure returns (ICards.Rarity) {
        if (rand == 999999) {
            return ICards.Rarity.Mythic;
        } else {
            return ICards.Rarity.Legendary;
        } 
    }

     
    function _getPurityBase(uint16 randOne) internal pure returns (uint16) {
        if (randOne >= 998) {
            return 3000;
        } else if (randOne >= 988) {
            return 2000;
        } else if (randOne >= 938) {
            return 1000;
        }
        return 0;
    }

    function _getShinyPurityBase(uint16 randOne) internal pure returns (uint16) {
        if (randOne >= 998) {
            return 3000;
        } else if (randOne >= 748) {
            return 2000;
        } else {
            return 1000;
        }
    }

    function getShine(uint16 purity) public pure returns (uint8) {
        return uint8(purity / 1000);
    }

}


contract PackFive is Ownable, RarityProvider {

    using SafeMath for uint;
    using SafeMath64 for uint64;

     
    event PacksPurchased(uint indexed paymentID, uint indexed id, Pack.Type indexed packType, address user, uint count, uint64 lockup);
     
    event CallbackMade(uint indexed id, address indexed user, uint count, uint randomness);
     
    event Recommit(uint indexed id, Pack.Type indexed packType, address indexed user, uint count, uint64 lockup);
     
    event CardActivated(uint indexed purchaseID, uint cardIndex, uint indexed cardID, uint16 proto, uint16 purity);
     
    event ChestsOpened(uint indexed id, Pack.Type indexed packType, address indexed user, uint count, uint packCount);
     
     
    event PurchaseRecorded(uint indexed id, Pack.Type indexed packType, address indexed user, uint count, uint64 lockup);
     
    event PurchaseRevoked(uint indexed paymentID, address indexed revoker);
     
    event PackAdded(Pack.Type indexed packType, uint price, address chest);

    struct Purchase {
        uint count;
        uint randomness;
        uint[] state;
        Pack.Type packType;
        uint64 commit;
        uint64 lockup;
        bool revoked;
        address user;
    }

    struct PackInstance {
        uint price;
        uint chestSize;
        address token;
    }

    Purchase[] public purchases;
    IProcessor public processor;
    mapping(uint => PackInstance) public packs;
    mapping(address => bool) public canLockup;
    mapping(address => bool) public canRevoke;
    uint public commitLag = 0;
     
    uint16 public activationLimit = 40;
     
    bool public canActivate = false;
     
    uint64 public maxLockup = 600000;

    constructor(ICards _cards, IProcessor _processor) public RarityProvider(_cards) {
        processor = _processor;
    }

     
    function setCanLockup(address user, bool can) public onlyOwner {
        canLockup[user] = can;
    }

    function setCanRevoke(address user, bool can) public onlyOwner {
        canRevoke[user] = can;
    }

    function setCommitLag(uint lag) public onlyOwner {
        require(commitLag < 100, "can't have a commit lag of >100 blocks");
        commitLag = lag;
    }

    function setActivationLimit(uint16 _limit) public onlyOwner {
        activationLimit = _limit;
    }

    function setMaxLockup(uint64 _max) public onlyOwner {
        maxLockup = _max;
    }

    function setPack(
        Pack.Type packType, uint price, address chest, uint chestSize
    ) public onlyOwner {

        PackInstance memory p = getPack(packType);
        require(p.token == address(0) && p.price == 0, "pack instance already set");

        require(price > 0, "price cannot be zero");
        require(price % 100 == 0, "price must be a multiple of 100 wei");
        require(address(processor) != address(0), "processor must be set");

        packs[uint(packType)] = PackInstance({
            token: chest,
            price: price,
            chestSize: chestSize
        });

        emit PackAdded(packType, price, chest);
    }

    function setActivate(bool can) public onlyOwner {
        canActivate = can;
    }

    function canActivatePurchase(uint id) public view returns (bool) {
        if (!canActivate) {
            return false;
        }
        Purchase memory p = purchases[id];
        if (p.lockup > 0) {
            if (inLockupPeriod(p)) {
                return false;
            }
            return !p.revoked;
        }
        return true;
    }

    function revoke(uint id) public {
        require(canRevoke[msg.sender], "sender not approved to revoke");
        Purchase storage p = purchases[id];
        require(!p.revoked, "must not be revoked already");
        require(p.lockup > 0, "must have lockup set");
        require(inLockupPeriod(p), "must be in lockup period");
        p.revoked = true;
        emit PurchaseRevoked(id, msg.sender);
    }

     

    function purchase(Pack.Type packType, uint16 count, address referrer) public payable returns (uint) {
        return purchaseFor(packType, msg.sender, count, referrer, 0);
    }

    function purchaseFor(Pack.Type packType, address user, uint16 count, address referrer, uint64 lockup) public payable returns (uint) {

        PackInstance memory pack = getPack(packType);

        uint purchaseID = _recordPurchase(packType, user, count, lockup);
    
        uint paymentID = processor.processPayment.value(msg.value)(msg.sender, pack.price, count, referrer);
        
        emit PacksPurchased(paymentID, purchaseID, packType, user, count, lockup);

        return purchaseID;
    }

    function activateMultiple(uint[] memory pIDs, uint[] memory cardIndices)
        public returns (uint[] memory ids, uint16[] memory protos, uint16[] memory purities) {
        uint len = pIDs.length;
        require(len > 0, "can't activate no cards");
        require(len <= activationLimit, "can't activate more than the activation limit");
        require(len == cardIndices.length, "must have the same length");
        ids = new uint[](len);
        protos = new uint16[](len);
        purities = new uint16[](len);
        for (uint i = 0; i < len; i++) {
            (ids[i], protos[i], purities[i]) = activate(pIDs[i], cardIndices[i]);
        }
        return (ids, protos, purities);
    }

    function activate(uint purchaseID, uint cardIndex) public returns (uint id, uint16 proto, uint16 purity) {
        
        require(canActivatePurchase(purchaseID), "can't activate purchase");
        Purchase storage p = purchases[purchaseID];
        
        require(p.randomness != 0, "must have been a callback");
        uint cardCount = uint(p.count).mul(5);
        require(cardIndex < cardCount, "not a valid card index");
        uint bit = getStateBit(purchaseID, cardIndex);
         
        require(bit == 0, "card has already been activated");
        uint x = cardIndex.div(256);
        uint pos = cardIndex % 256;
         
        p.state[x] ^= uint(1) << pos;
         
        (proto, purity) = getCardDetails(p.packType, cardIndex, p.randomness);
        id = cards.createCard(p.user, proto, purity);
        emit CardActivated(purchaseID, cardIndex, id, proto, purity);
        return (id, proto, purity);
    }

     
    function openChest(Pack.Type packType, address user, uint count) public returns (uint) {
        
        PackInstance memory pack = getPack(packType);

        require(msg.sender == pack.token, "can only open from the actual token packs");

        uint packCount = count.mul(pack.chestSize);
        
        uint id = _recordPurchase(packType, user, packCount, 0);

        emit ChestsOpened(id, packType, user, count, packCount);

        return id;
    }

    function _recordPurchase(Pack.Type packType, address user, uint count, uint64 lockup) internal returns (uint) {

        if (lockup != 0) {
            require(lockup < maxLockup, "lockup must be lower than maximum");
            require(canLockup[msg.sender], "only some people can lockup cards");
        }
        
        Purchase memory p = Purchase({
            user: user,
            count: count,
            commit: getCommitBlock(),
            randomness: 0,
            packType: packType,
            state: new uint256[](getStateSize(count)),
            lockup: lockup,
            revoked: false
        });

        uint id = purchases.push(p).sub(1);

        emit PurchaseRecorded(id, packType, user, count, lockup);
        return id;
    }

     
    function callback(uint id) public {

        Purchase storage p = purchases[id];

        require(p.randomness == 0, "randomness already set");

        require(uint64(block.number) > p.commit, "cannot callback before commit");

         
        require(p.commit.add(uint64(256)) >= block.number, "must recommit");

        bytes32 bhash = blockhash(p.commit);

        require(uint(bhash) != 0, "blockhash must not be zero");

         
         
         
        p.randomness = uint(keccak256(abi.encodePacked(id, bhash, address(this))));

        emit CallbackMade(id, p.user, p.count, p.randomness);
    }

     
     
     
     
    function recommit(uint id) public {
        Purchase storage p = purchases[id];
        require(p.randomness == 0, "randomness already set");
        require(block.number >= p.commit.add(uint64(256)), "no need to recommit");
        p.commit = getCommitBlock();
        emit Recommit(id, p.packType, p.user, p.count, p.lockup);
    }

     

    function getCommitBlock() internal view returns (uint64) {
        return uint64(block.number.add(commitLag));
    }

    function getStateSize(uint count) public pure returns (uint) {
        return count.mul(5).sub(1).div(256).add(1);
    }

    function getPurchaseState(uint purchaseID) public view returns (uint[] memory state) {
        require(purchases.length > purchaseID, "invalid purchase id");
        Purchase memory p = purchases[purchaseID];
        return p.state;
    }
    
    function getPackDetails(Pack.Type packType) public view returns (address token, uint price) {
        PackInstance memory p = getPack(packType);
        return (p.token, p.price);
    }

    function getPack(Pack.Type packType) internal view returns (PackInstance memory) {
        return packs[uint(packType)];
    }

    function getPrice(Pack.Type packType) public view returns (uint) {
        PackInstance memory p = getPack(packType);
        require(p.price != 0, "price is not yet set");
        return p.price;
    }

    function getChestSize(Pack.Type packType) public view returns (uint) {
        PackInstance memory p = getPack(packType);
        require(p.chestSize != 0, "chest size is not yet set");
        return p.chestSize;
    }

    function isActivated(uint purchaseID, uint cardIndex) public view returns (bool) {
        return getStateBit(purchaseID, cardIndex) != 0;
    }

    function getStateBit(uint purchaseID, uint cardIndex) public view returns (uint) {
        Purchase memory p = purchases[purchaseID];
        uint x = cardIndex.div(256);
        uint slot = p.state[x];
        uint pos = cardIndex % 256;
        uint bit = (slot >> pos) & uint(1);
        return bit;
    }

    function predictPacks(uint id) external view returns (uint16[] memory protos, uint16[] memory purities) {

        Purchase memory p = purchases[id];

        require(p.randomness != 0, "randomness not yet set");

        uint result = p.randomness;

        uint cardCount = uint(p.count).mul(5);

        purities = new uint16[](cardCount);
        protos = new uint16[](cardCount);

        for (uint i = 0; i < cardCount; i++) {
            (protos[i], purities[i]) = getCardDetails(p.packType, i, result);
        }

        return (protos, purities);
    }
 
    function inLockupPeriod(Purchase memory p) internal view returns (bool) {
        return p.commit.add(p.lockup) >= block.number;
    }

}
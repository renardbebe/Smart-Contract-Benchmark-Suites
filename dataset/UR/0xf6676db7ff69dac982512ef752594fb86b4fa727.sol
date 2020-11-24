 

pragma solidity ^0.4.25;

contract WWGPreLaunch {
    
     
    
    uint256 constant SUPPORTER_PACK_PRICE = 0.1 ether;
    uint256 constant CRYPTO_CLAN_PRICE = 1 ether;
    uint256 constant PREMIUM_FACTORY_PRICE = 0.5 ether;
    uint256 constant GAS_LIMIT = 0.05 szabo;  
    
    uint256 public startTime = 1544832000;  
    
    uint256 clanIdStart;  
    uint256 clanIdEnd;
    uint256 factoryIdStart;
    uint256 factoryIdEnd;
    
    address owner;
    address holdee;
    
    mapping(address => bool) public supporters;  
    mapping(uint256 => address) public factoryOwner;  
    mapping(address => bool) private boughtFactory;  

    WWGClanCoupon clanCoupons = WWGClanCoupon(0xe9fe4e530ebae235877289bd978f207ae0c8bb25);  
    
    constructor() public {
        owner = msg.sender;
        holdee = address(0xf6fF7aD69aF2F8655Ff1863BEc350093880e03E7);
    }
    
    function buySupporterPack() payable external {
        require(msg.value >= SUPPORTER_PACK_PRICE);
        require(now >= startTime);
        require(!supporters[msg.sender]);  
        
        supporters[msg.sender] = true;
        owner.transfer(SUPPORTER_PACK_PRICE);
        
         
        if (msg.value > SUPPORTER_PACK_PRICE) {
            msg.sender.transfer(msg.value - SUPPORTER_PACK_PRICE);
        }
    }
    
    function buyCryptoClan(uint256 clanId) payable external {
        require(msg.value >= CRYPTO_CLAN_PRICE);
        require(tx.gasprice <= GAS_LIMIT);
        require(msg.sender == tx.origin);
        require(now >= startTime);
        require(validClanId(clanId));
       
        clanCoupons.mintClan(clanId, msg.sender);
        holdee.transfer(CRYPTO_CLAN_PRICE);
        
         
        if (msg.value > CRYPTO_CLAN_PRICE) {
            msg.sender.transfer(msg.value - CRYPTO_CLAN_PRICE);
        }
    }
    
    function buyPremiumFactory(uint256 factoryId) payable external {
        require(msg.value >= PREMIUM_FACTORY_PRICE);
        require(tx.gasprice <= GAS_LIMIT);
        require(msg.sender == tx.origin);
        require(now >= startTime);
        require(factoryOwner[factoryId] == address(0));
        require(!boughtFactory[msg.sender]);
        require(validFactoryId(factoryId));
        
        factoryOwner[factoryId] = msg.sender;
        boughtFactory[msg.sender] = true;
        holdee.transfer(PREMIUM_FACTORY_PRICE);
        
          
        if (msg.value > PREMIUM_FACTORY_PRICE) {
            msg.sender.transfer(msg.value - PREMIUM_FACTORY_PRICE);
        }
    }
    
    function validClanId(uint256 id) private view returns (bool) {
        return (id > 0 && clanIdStart <= id && id <= clanIdEnd);
    }
    
    function validFactoryId(uint256 id) private view returns (bool) {
        return (id > 0 && factoryIdStart <= id && id <= factoryIdEnd);
    }
    
    function getClanOwners() public view returns (address[]) {
        if (clanIdEnd - clanIdStart == 0) {
            return;
        }
        
        uint256 size = 1 + clanIdEnd - clanIdStart;
        address[] memory clanOwners = new address[](size);

        uint256 clanId = clanIdStart;
        for (uint256 i = 0; i < size; i++) {
            clanOwners[i] = clanCoupons.ownerOf(clanId);
            clanId++;
        }
        return clanOwners;
    }
    
    function getFactoryOwners() public view returns (address[]) {
        if (factoryIdEnd - factoryIdStart == 0) {
            return;
        }
        
        uint256 size = 1 + factoryIdEnd - factoryIdStart;
        address[] memory factoryOwners = new address[](size);

        uint256 factoryId = factoryIdStart;
        for (uint256 i = 0; i < size; i++) {
            factoryOwners[i] = address(factoryOwner[factoryId]);
            factoryId++;
        }
        return factoryOwners;
    }
    
     
    function setValidIds(uint256 clanStart, uint256 clanEnd, uint256 factoryStart, uint256 factoryEnd) external {
        require(msg.sender == owner);
        clanIdStart = clanStart;
        clanIdEnd = clanEnd;
        factoryIdStart = factoryStart;
        factoryIdEnd = factoryEnd;
    }

     
    function delay(uint256 newTime) external {
        require(msg.sender == owner);
        require(newTime >= startTime);
        startTime = newTime;
    }
}

interface WWGClanCoupon {
    function mintClan(uint256 clanId, address clanOwner) external;
    function ownerOf(uint256 clanId) external view returns (address);
}
 

pragma solidity ^0.4.2;

 
interface KittyCore {

    function ownerOf (uint256 _tokenId) external view returns (address owner);
    
    function getKitty (uint256 _id) external view returns (bool isGestating, bool isReady, uint256 cooldownIndex, uint256 nextActionAt, uint256 siringWithId, uint256 birthTime, uint256 matronId, uint256 sireId, uint256 generation, uint256 genes);
    
}

interface SaleClockAuction {
    
    function getCurrentPrice (uint256 _tokenId) external view returns (uint256);
    
    function getAuction (uint256 _tokenId) external view returns (address seller, uint256 startingPrice, uint256 endingPrice, uint256 duration, uint256 startedAt);
    
}

 
contract ERC721 {
     
    function totalSupply() public view returns (uint256 total);
    function balanceOf(address _owner) public view returns (uint256 balance);
    function ownerOf(uint256 _tokenId) external view returns (address owner);
    function approve(address _to, uint256 _tokenId) external;
    function transfer(address _to, uint256 _tokenId) external;
    function transferFrom(address _from, address _to, uint256 _tokenId) external;
    
    function allowance(address _owner, address _spender) view returns (uint remaining);
    
    function takeOwnership(uint256 _tokenId) external;

     
    event Transfer(address indexed from, address indexed to, uint256 tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 tokenId);

    function name() public view returns (string);
    function symbol() public view returns (string);
    
     
     

     
    function supportsInterface(bytes4 _interfaceID) external view returns (bool);
}

contract CryptoSprites is ERC721 {
    
    address public owner;
    
    address KittyCoreAddress = 0x06012c8cf97BEaD5deAe237070F9587f8E7A266d;

    address SaleClockAuctionAddress = 0xb1690C08E213a35Ed9bAb7B318DE14420FB57d8C;

     
    address charityAddress = 0xb30cb3b3E03A508Db2A0a3e07BA1297b47bb0fb1;
    
    uint public etherForOwner;
    uint public etherForCharity;
    
    uint public ownerCut = 15;  
    uint public charityCut = 15;  
    
    uint public featurePrice = 10**16;  
    
     
     
    uint public priceMultiplier = 1;
    uint public priceDivider = 10;
    
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    function CryptoSprites() {
        owner = msg.sender;
    }
    
    uint[] public featuredSprites;
    
    uint[] public allPurchasedSprites;
    
    uint public totalFeatures;
    uint public totalBuys;
    
    struct BroughtSprites {
        address owner;
        uint spriteImageID;
        bool forSale;
        uint price;
        uint timesTraded;
        bool featured;
    }
    
    mapping (uint => BroughtSprites) public broughtSprites;
    
     
    mapping (address => uint[]) public spriteOwningHistory;
    
    mapping (address => uint) public numberOfSpritesOwnedByUser;
    
    mapping (address => mapping(address => mapping(uint256 => bool))) public addressToReceiverToAllowedSprite;
    
    mapping (address => mapping(address => uint256)) public addressToReceiverToAmountAllowed;
    
    bytes4 constant InterfaceSignature_ERC165 = bytes4(keccak256('supportsInterface(bytes4)'));
    
    bytes4 constant InterfaceSignature_ERC721 =
        bytes4(keccak256('totalSupply()')) ^
        bytes4(keccak256('balanceOf(address)')) ^
        bytes4(keccak256('ownerOf(uint256)')) ^
        bytes4(keccak256('approve(address,uint256)')) ^
        bytes4(keccak256('transfer(address,uint256)')) ^
        bytes4(keccak256('transferFrom(address,address,uint256)'));

    function() payable {
        etherForOwner += msg.value;
    }
    
    function adjustDefaultSpritePrice (uint _priceMultiplier, uint _priceDivider) onlyOwner {
        require (_priceMultiplier > 0);
        require (_priceDivider > 0);
        priceMultiplier = _priceMultiplier;
        priceDivider = _priceDivider;
    }
    
    function adjustCut (uint _ownerCut, uint _charityCut) onlyOwner {
        require (_ownerCut + _charityCut < 51);  
        ownerCut = _ownerCut;
        charityCut = _charityCut;
    }
    
    function adjustFeaturePrice (uint _featurePrice) onlyOwner {
        require (_featurePrice > 0);
        featurePrice = _featurePrice;
    }
    
    function withdraw() onlyOwner {
        owner.transfer(etherForOwner);
        charityAddress.transfer(etherForCharity);
        etherForOwner = 0;
        etherForCharity = 0;
    }
    
    function changeOwner (address _owner) onlyOwner {
        owner = _owner;
    }
    
    function featureSprite (uint spriteId) payable {
         
         
        require (msg.value == featurePrice);
        broughtSprites[spriteId].featured = true;

        if (broughtSprites[spriteId].timesTraded == 0) {
            var (kittyOwner,,,,) = SaleClockAuction(SaleClockAuctionAddress).getAuction(spriteId);
            uint priceIfAny = SaleClockAuction(SaleClockAuctionAddress).getCurrentPrice(spriteId);
            address kittyOwnerNotForSale = KittyCore(KittyCoreAddress).ownerOf(spriteId);
            
             
            if (priceIfAny > 0 && msg.sender == kittyOwner) {
                broughtSprites[spriteId].price = priceIfAny * priceMultiplier / priceDivider;
                broughtSprites[spriteId].forSale = true;
                broughtSprites[spriteId].owner = kittyOwner;
                numberOfSpritesOwnedByUser[msg.sender]++;
            } else if (kittyOwnerNotForSale == msg.sender) {
                 
                broughtSprites[spriteId].owner = kittyOwnerNotForSale;
                numberOfSpritesOwnedByUser[msg.sender]++;
            }
            
            broughtSprites[spriteId].spriteImageID = uint(block.blockhash(block.number-1))%360 + 1;
            
        }
        
        totalFeatures++;
        etherForOwner += msg.value;
        featuredSprites.push(spriteId);
    }
    
    function calculatePrice (uint kittyId) view returns (uint) {
        
        uint priceIfAny = SaleClockAuction(SaleClockAuctionAddress).getCurrentPrice(kittyId);
        
        var _ownerCut = ((priceIfAny / 1000) * ownerCut) * priceMultiplier / priceDivider;
        var _charityCut = ((priceIfAny / 1000) * charityCut) * priceMultiplier / priceDivider;
        
        return (priceIfAny * priceMultiplier / priceDivider) + _ownerCut + _charityCut;
        
    }
    
    function buySprite (uint spriteId) payable {
        
        uint _ownerCut;
        uint _charityCut;
        
        if (broughtSprites[spriteId].forSale == true) {
            
             
            
            _ownerCut = ((broughtSprites[spriteId].price / 1000) * ownerCut);
            _charityCut = ((broughtSprites[spriteId].price / 1000) * charityCut);
            
            require (msg.value == broughtSprites[spriteId].price + _ownerCut + _charityCut);
            
            broughtSprites[spriteId].owner.transfer(broughtSprites[spriteId].price);
            
            numberOfSpritesOwnedByUser[broughtSprites[spriteId].owner]--;
            
            if (broughtSprites[spriteId].timesTraded == 0) {
                 
                allPurchasedSprites.push(spriteId);
            }
            
            Transfer (broughtSprites[spriteId].owner, msg.sender, spriteId);
            
        } else {
            
             
            
            require (broughtSprites[spriteId].timesTraded == 0);
            require (broughtSprites[spriteId].price == 0);
            
             
            
            uint priceIfAny = SaleClockAuction(SaleClockAuctionAddress).getCurrentPrice(spriteId);
            require (priceIfAny > 0);  
            
            _ownerCut = ((priceIfAny / 1000) * ownerCut) * priceMultiplier / priceDivider;
            _charityCut = ((priceIfAny / 1000) * charityCut) * priceMultiplier / priceDivider;
            
             
            
            require (msg.value >= (priceIfAny * priceMultiplier / priceDivider) + _ownerCut + _charityCut);
            
             
            
            var (kittyOwner,,,,) = SaleClockAuction(SaleClockAuctionAddress).getAuction(spriteId);
            
            kittyOwner.transfer(priceIfAny * priceMultiplier / priceDivider);
            
            allPurchasedSprites.push(spriteId);
            
            broughtSprites[spriteId].spriteImageID = uint(block.blockhash(block.number-1))%360 + 1;  
            
            Transfer (kittyOwner, msg.sender, spriteId);
            
        }
        
        totalBuys++;
        
        spriteOwningHistory[msg.sender].push(spriteId);
        numberOfSpritesOwnedByUser[msg.sender]++;
        
        broughtSprites[spriteId].owner = msg.sender;
        broughtSprites[spriteId].forSale = false;
        broughtSprites[spriteId].timesTraded++;
        broughtSprites[spriteId].featured = false;
            
        etherForOwner += _ownerCut;
        etherForCharity += _charityCut;
        
    }
    
     
    function listSpriteForSale (uint spriteId, uint price) {
        require (price > 0);
        if (broughtSprites[spriteId].owner != msg.sender) {
            require (broughtSprites[spriteId].timesTraded == 0);
            
             
            var (kittyOwner,,,,) = SaleClockAuction(SaleClockAuctionAddress).getAuction(spriteId);
            
            if (kittyOwner != msg.sender) {
                 
                address kittyOwnerNotForSale = KittyCore(KittyCoreAddress).ownerOf(spriteId);
                require (kittyOwnerNotForSale == msg.sender);
            }

            broughtSprites[spriteId].owner = msg.sender;
            broughtSprites[spriteId].spriteImageID = uint(block.blockhash(block.number-1))%360 + 1; 
        }
        broughtSprites[spriteId].forSale = true;
        broughtSprites[spriteId].price = price;
    }
    
    function removeSpriteFromSale (uint spriteId) {
        if (broughtSprites[spriteId].owner != msg.sender) {
            require (broughtSprites[spriteId].timesTraded == 0);
            var (kittyOwner,,,,) = SaleClockAuction(SaleClockAuctionAddress).getAuction(spriteId);
            
            if (kittyOwner != msg.sender) {
                address kittyOwnerNotForSale = KittyCore(KittyCoreAddress).ownerOf(spriteId);
                require (kittyOwnerNotForSale == msg.sender);
            }
            
            broughtSprites[spriteId].price = 1;  
        } 
        broughtSprites[spriteId].forSale = false;
    }
    
     
    
    function featuredSpritesLength() view external returns (uint) {
        return featuredSprites.length;
    }
    
    function usersSpriteOwningHistory (address user) view external returns (uint[]) {
        return spriteOwningHistory[user];
    }
    
    function lookupSprite (uint spriteId) view external returns (address, uint, bool, uint, uint, bool) {
        return (broughtSprites[spriteId].owner, broughtSprites[spriteId].spriteImageID, broughtSprites[spriteId].forSale, broughtSprites[spriteId].price, broughtSprites[spriteId].timesTraded, broughtSprites[spriteId].featured);
    }
    
    function lookupFeaturedSprites (uint _index) view external returns (uint) {
        return featuredSprites[_index];
    }
    
    function lookupAllSprites (uint _index) view external returns (uint) {
        return allPurchasedSprites[_index];
    }
    
     
    
    function lookupKitty (uint kittyId) view returns (address, uint, address) {
        
        var (kittyOwner,,,,) = SaleClockAuction(SaleClockAuctionAddress).getAuction(kittyId);

        uint priceIfAny = SaleClockAuction(SaleClockAuctionAddress).getCurrentPrice(kittyId);
        
        address kittyOwnerNotForSale = KittyCore(KittyCoreAddress).ownerOf(kittyId);

        return (kittyOwner, priceIfAny, kittyOwnerNotForSale);

    }
    
     
    
    function lookupKittyDetails1 (uint kittyId) view returns (bool, bool, uint, uint, uint) {
        
        var (isGestating, isReady, cooldownIndex, nextActionAt, siringWithId,,,,,) = KittyCore(KittyCoreAddress).getKitty(kittyId);
        
        return (isGestating, isReady, cooldownIndex, nextActionAt, siringWithId);
        
    }
    
    function lookupKittyDetails2 (uint kittyId) view returns (uint, uint, uint, uint, uint) {
        
        var(,,,,,birthTime, matronId, sireId, generation, genes) = KittyCore(KittyCoreAddress).getKitty(kittyId);
        
        return (birthTime, matronId, sireId, generation, genes);
        
    }
    
     
    
    string public name = 'Crypto Sprites';
    string public symbol = 'CRS';
    uint8 public decimals = 0;  
    
    function name() public view returns (string) {
        return name;
    }
    
    function symbol() public view returns (string) {
        return symbol;
    }
    
    function totalSupply() public view returns (uint) {
        return allPurchasedSprites.length;
    }
    
    function balanceOf (address _owner) public view returns (uint) {
        return numberOfSpritesOwnedByUser[_owner];
    }
    
    function ownerOf (uint _tokenId) external view returns (address){
        return broughtSprites[_tokenId].owner;
    }
    
    function approve (address _to, uint256 _tokenId) external {
        require (broughtSprites[_tokenId].owner == msg.sender);
        require (addressToReceiverToAllowedSprite[msg.sender][_to][_tokenId] == false);
        addressToReceiverToAllowedSprite[msg.sender][_to][_tokenId] = true;
        addressToReceiverToAmountAllowed[msg.sender][_to]++;
        Approval (msg.sender, _to, _tokenId);
    }
    
    function disapprove (address _to, uint256 _tokenId) external {
        require (broughtSprites[_tokenId].owner == msg.sender);
        require (addressToReceiverToAllowedSprite[msg.sender][_to][_tokenId] == true);  
        addressToReceiverToAmountAllowed[msg.sender][_to]--;
        addressToReceiverToAllowedSprite[msg.sender][_to][_tokenId] = false;
    }
    
     
    function takeOwnership (uint256 _tokenId) external {
        require (addressToReceiverToAllowedSprite[broughtSprites[_tokenId].owner][msg.sender][_tokenId] == true);
        addressToReceiverToAllowedSprite[broughtSprites[_tokenId].owner][msg.sender][_tokenId] = false;
        addressToReceiverToAmountAllowed[broughtSprites[_tokenId].owner][msg.sender]--;
        numberOfSpritesOwnedByUser[broughtSprites[_tokenId].owner]--;
        numberOfSpritesOwnedByUser[msg.sender]++;
        spriteOwningHistory[msg.sender].push(_tokenId);
        Transfer (broughtSprites[_tokenId].owner, msg.sender, _tokenId);
        broughtSprites[_tokenId].owner = msg.sender;
    }
    
    function transfer (address _to, uint _tokenId) external {
        require (broughtSprites[_tokenId].owner == msg.sender);
        broughtSprites[_tokenId].owner = _to;
        numberOfSpritesOwnedByUser[msg.sender]--;
        numberOfSpritesOwnedByUser[_to]++;
        spriteOwningHistory[_to].push(_tokenId);
        Transfer (msg.sender, _to, _tokenId);
    }

    function transferFrom (address _from, address _to, uint256 _tokenId) external {
        require (addressToReceiverToAllowedSprite[_from][msg.sender][_tokenId] == true);
        require (broughtSprites[_tokenId].owner == _from);
        addressToReceiverToAllowedSprite[_from][msg.sender][_tokenId] = false;
        addressToReceiverToAmountAllowed[_from][msg.sender]--;
        numberOfSpritesOwnedByUser[_from]--;
        numberOfSpritesOwnedByUser[_to]++;
        spriteOwningHistory[_to].push(_tokenId);
        broughtSprites[_tokenId].owner = _to;
        Transfer (_from, _to, _tokenId);
    }
    
    function allowance (address _owner, address _spender) view returns (uint) {
        return addressToReceiverToAmountAllowed[_owner][_spender];
    }
    
    function supportsInterface (bytes4 _interfaceID) external view returns (bool) {
        return ((_interfaceID == InterfaceSignature_ERC165) || (_interfaceID == InterfaceSignature_ERC721));
    }
    
}
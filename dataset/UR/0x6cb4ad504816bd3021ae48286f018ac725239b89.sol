 

pragma solidity 0.4.24;

contract Kitties {

    function ownerOf(uint id) public view returns (address);

}

contract ICollectable {

    function mint(uint32 delegateID, address to) public returns (uint);

    function transferFrom(address from, address to, uint256 tokenId) public;
    function approve(address to, uint256 tokenId) public;
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public;

    function safeTransferFrom(address from, address to, uint256 tokenId) public;

}

contract IAuction {

    function getAuction(uint256 _tokenId)
        external
        view
        returns
    (
        address seller,
        uint256 startingPrice,
        uint256 endingPrice,
        uint256 duration,
        uint256 startedAt);
}

contract IPack {

    function purchase(uint16, address) public payable;
    function purchaseFor(address, uint16, address) public payable;

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

contract Ownable {

    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    function setOwner(address _owner) public onlyOwner {
        owner = _owner;
    }

    function getOwner() public view returns (address) {
        return owner;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

}

contract CatInThePack is Ownable {

    using SafeMath for uint;

     
    IPack public pack;
     
    Kitties public kitties;
     
    ICollectable public collectables;
     
    IAuction[] public auctions;
    
     
    bool public canClaim = true;
     
    uint32 public delegateID;
     
    bool public locked = false;
     
    bool public includeAuctions = true;
     
    address public vault;
     
    uint public claimLimit = 20;
     
    uint public price = 0.024 ether;
    
    
     
    mapping(uint => bool) public claimed;
     
    mapping(uint => uint) public statues;

    constructor(IPack _pack, IAuction[] memory _auctions, Kitties _kitties, 
        ICollectable _collectables, uint32 _delegateID, address _vault) public {
        pack = _pack;
        auctions = _auctions;
        kitties = _kitties;
        collectables = _collectables;
        delegateID = _delegateID;
        vault = _vault;
    }

    event CatsClaimed(uint[] statueIDs, uint[] kittyIDs);

     
    function claim(uint[] memory kittyIDs, address referrer) public payable returns (uint[] memory ids) {

        require(canClaim, "claiming not enabled");
        require(kittyIDs.length > 0, "you must claim at least one cat");
        require(claimLimit >= kittyIDs.length, "must claim >= the claim limit at a time");
        
         
        ids = new uint[](kittyIDs.length);
        
        for (uint i = 0; i < kittyIDs.length; i++) {

            uint kittyID = kittyIDs[i];

             
            require(!claimed[kittyID], "kitty must not be claimed");
            claimed[kittyID] = true;

            require(ownsOrSelling(kittyID), "you must own all the cats you claim");

             
            uint id = collectables.mint(delegateID, msg.sender);
            ids[i] = id;
             
            statues[id] = kittyID;    
        }
        
         
        uint totalPrice = price.mul(kittyIDs.length);

        require(msg.value >= totalPrice, "wrong value sent to contract");
       
        uint half = totalPrice.div(2);

         
        pack.purchaseFor.value(half)(msg.sender, uint16(kittyIDs.length), referrer); 

         
        vault.transfer(half);

        emit CatsClaimed(ids, kittyIDs);
        
        return ids;
    }

     
    function ownsOrSelling(uint kittyID) public view returns (bool) {
         
        address owner = kitties.ownerOf(kittyID);
        if (owner == msg.sender) {
            return true;
        } 
         
        if (includeAuctions) {
            address seller;
            for (uint i = 0; i < auctions.length; i++) {
                IAuction auction = auctions[i];
                 
                 
                if (owner == address(auction)) {
                    (seller, , , ,) = auction.getAuction(kittyID);
                    return seller == msg.sender;
                }
            }
        }
        return false;
    }
 
    function setCanClaim(bool _can, bool lock) public onlyOwner {
        require(!locked, "claiming is permanently locked");
        if (lock) {
            require(!_can, "can't lock on permanently");
            locked = true;
        }
        canClaim = _can;
    }

    function getKitty(uint statueID) public view returns (uint) {
        return statues[statueID];
    }

    function setClaimLimit(uint limit) public onlyOwner {
        claimLimit = limit;
    }

    function setIncludeAuctions(bool _include) public onlyOwner {
        includeAuctions = _include;
    }

}
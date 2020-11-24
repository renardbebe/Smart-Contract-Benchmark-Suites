 

pragma solidity 0.4.24;

 

 
 
 
 

 
 
 
 

 
 

pragma solidity 0.4.24;

contract DSAuthority {
    function canCall(
        address src, address dst, bytes4 sig
    ) public view returns (bool);
}

contract DSAuthEvents {
    event LogSetAuthority (address indexed authority);
    event LogSetOwner     (address indexed owner);
}

contract DSAuth is DSAuthEvents {
    DSAuthority  public  authority;
    address      public  owner;

    constructor() public {
        owner = msg.sender;
        emit LogSetOwner(msg.sender);
    }

    function setOwner(address owner_)
        public
        auth
    {
        owner = owner_;
        emit LogSetOwner(owner);
    }

    function setAuthority(DSAuthority authority_)
        public
        auth
    {
        authority = authority_;
        emit LogSetAuthority(authority);
    }

    modifier auth {
        require(isAuthorized(msg.sender, msg.sig));
        _;
    }

    function isAuthorized(address src, bytes4 sig) internal view returns (bool) {
        if (src == address(this)) {
            return true;
        } else if (src == owner) {
            return true;
        } else if (authority == DSAuthority(0)) {
            return false;
        } else {
            return authority.canCall(src, this, sig);
        }
    }
}

 

contract AssetPriceOracle is DSAuth {
     
     
     

    struct AssetPriceRecord {
        uint128 price;
        bool isRecord;
    }

    mapping(uint128 => mapping(uint128 => AssetPriceRecord)) public assetPriceRecords;

    event AssetPriceRecorded(
        uint128 indexed assetId,
        uint128 indexed blockNumber,
        uint128 indexed price
    );

    constructor() public {
    }
    
    function recordAssetPrice(uint128 assetId, uint128 blockNumber, uint128 price) public auth {
        assetPriceRecords[assetId][blockNumber].price = price;
        assetPriceRecords[assetId][blockNumber].isRecord = true;
        emit AssetPriceRecorded(assetId, blockNumber, price);
    }

    function getAssetPrice(uint128 assetId, uint128 blockNumber) public view returns (uint128 price) {
        AssetPriceRecord storage priceRecord = assetPriceRecords[assetId][blockNumber];
        require(priceRecord.isRecord);
        return priceRecord.price;
    }

    function () public {
         
    }
}
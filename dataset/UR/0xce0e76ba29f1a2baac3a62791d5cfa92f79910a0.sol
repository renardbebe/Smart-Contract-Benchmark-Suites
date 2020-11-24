 

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

 

 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
     
     
     
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function mul(int256 a, int256 b) internal pure returns (int256) {
     
     
     
    if (a == 0) {
      return 0;
    }
    int256 c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    return a / b;
  }

   
  function div(int256 a, int256 b) internal pure returns (int256) {
     
     
    int256 INT256_MIN = int256((uint256(1) << 255));
    assert(a != INT256_MIN || b != -1);
    return a / b;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function sub(int256 a, int256 b) internal pure returns (int256) {
    int256 c = a - b;
    assert((b >= 0 && c <= a) || (b < 0 && c > a));
    return c;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }

   
  function add(int256 a, int256 b) internal pure returns (int256) {
    int256 c = a + b;
    assert((b >= 0 && c >= a) || (b < 0 && c < a));
    return c;
  }
}

 

contract ContractForDifference is DSAuth {
    using SafeMath for int256;

    enum Position { Long, Short }
    
     
    struct Party {
        address addr;
        uint128 withdrawBalance;  
        Position position;
        bool isPaid;
    }
    
    struct Cfd {
        Party maker;
        Party taker;

        uint128 assetId;
        uint128 amount;  
        uint128 contractStartBlock;  
        uint128 contractEndBlock;  

         
        bool isTaken;
        bool isSettled;
        bool isRefunded;
    }

    uint128 public leverage = 1;  
    AssetPriceOracle public priceOracle;

    mapping(uint128 => Cfd) public contracts;
    uint128                 public numberOfContracts;

    event LogMakeCfd (
    uint128 indexed cfdId, 
    address indexed makerAddress, 
    Position indexed makerPosition,
    uint128 assetId,
    uint128 amount,
    uint128 contractEndBlock);

    event LogTakeCfd (
    uint128 indexed cfdId,
    address indexed makerAddress,
    Position makerPosition,
    address indexed takerAddress,
    Position takerPosition,
    uint128 assetId,
    uint128 amount,
    uint128 contractStartBlock,
    uint128 contractEndBlock);

    event LogCfdSettled (
    uint128 indexed cfdId,
    address indexed makerAddress,
    address indexed takerAddress,
    uint128 amount,
    uint128 startPrice,
    uint128 endPrice,
    uint128 makerSettlement,
    uint128 takerSettlement);

    event LogCfdRefunded (
    uint128 indexed cfdId,
    address indexed makerAddress,
    uint128 amount);

    event LogCfdForceRefunded (
    uint128 indexed cfdId,
    address indexed makerAddress,
    uint128 makerAmount,
    address indexed takerAddress,
    uint128 takerAmount);

    event LogWithdrawal (
    uint128 indexed cfdId,
    address indexed withdrawalAddress,
    uint128 amount);

     
     
     
     
     

    constructor(address priceOracleAddress) public {
        priceOracle = AssetPriceOracle(priceOracleAddress);
    }

    function makeCfd(
        address makerAddress,
        uint128 assetId,
        Position makerPosition,
        uint128 contractEndBlock
        )
        public
        payable
        returns (uint128)
    {
        require(contractEndBlock > block.number);  
        require(msg.value > 0);  
        require(makerAddress != address(0));  
        
        uint128 contractId = numberOfContracts;

         
        Party memory maker = Party(makerAddress, 0, makerPosition, false);
        Party memory taker = Party(address(0), 0, Position.Long, false);
        Cfd memory newCfd = Cfd(
            maker,
            taker,
            assetId,
            uint128(msg.value),
            0,
            contractEndBlock,
            false,
            false,
            false
        );

        contracts[contractId] = newCfd;

         
         
         
         
         

        numberOfContracts++;
        
        emit LogMakeCfd(
            contractId,
            contracts[contractId].maker.addr,
            contracts[contractId].maker.position,
            contracts[contractId].assetId,
            contracts[contractId].amount,
            contracts[contractId].contractEndBlock
        );

        return contractId;
    }

    function getCfd(
        uint128 cfdId
        ) 
        public 
        view 
        returns (address makerAddress, Position makerPosition, address takerAddress, Position takerPosition, uint128 assetId, uint128 amount, uint128 startTime, uint128 endTime, bool isTaken, bool isSettled, bool isRefunded)
        {
        Cfd storage cfd = contracts[cfdId];
        return (
            cfd.maker.addr,
            cfd.maker.position,
            cfd.taker.addr,
            cfd.taker.position,
            cfd.assetId,
            cfd.amount,
            cfd.contractStartBlock,
            cfd.contractEndBlock,
            cfd.isTaken,
            cfd.isSettled,
            cfd.isRefunded
        );
    }

    function takeCfd(
        uint128 cfdId, 
        address takerAddress
        ) 
        public
        payable
        returns (bool success) {
        Cfd storage cfd = contracts[cfdId];
        
        require(cfd.isTaken != true);                   
        require(cfd.isSettled != true);                 
        require(cfd.isRefunded != true);                
        require(cfd.maker.addr != address(0));          
        require(cfd.taker.addr == address(0));          
         
        require(msg.value == cfd.amount);               
        require(takerAddress != address(0));            
        require(block.number <= cfd.contractEndBlock);  

        cfd.taker.addr = takerAddress;
         
        cfd.taker.position = cfd.maker.position == Position.Long ? Position.Short : Position.Long;
        cfd.contractStartBlock = uint128(block.number);
        cfd.isTaken = true;

        emit LogTakeCfd(
            cfdId,
            cfd.maker.addr,
            cfd.maker.position,
            cfd.taker.addr,
            cfd.taker.position,
            cfd.assetId,
            cfd.amount,
            cfd.contractStartBlock,
            cfd.contractEndBlock
        );
            
        return true;
    }

    function settleAndWithdrawCfd(
        uint128 cfdId
        )
        public {
        address makerAddr = contracts[cfdId].maker.addr;
        address takerAddr = contracts[cfdId].taker.addr;

        settleCfd(cfdId);
        withdraw(cfdId, makerAddr);
        withdraw(cfdId, takerAddr);
    }

    function settleCfd(
        uint128 cfdId
        )
        public
        returns (bool success) {
        Cfd storage cfd = contracts[cfdId];

        require(cfd.contractEndBlock <= block.number);  
        require(!cfd.isSettled);                        
        require(!cfd.isRefunded);                       
        require(cfd.isTaken);                           
        require(cfd.maker.addr != address(0));          
        require(cfd.taker.addr != address(0));          

         
        uint128 amount = cfd.amount;
        uint128 startPrice = priceOracle.getAssetPrice(cfd.assetId, cfd.contractStartBlock);
        uint128 endPrice = priceOracle.getAssetPrice(cfd.assetId, cfd.contractEndBlock);

         
        uint128 takerSettlement = getSettlementAmount(amount, startPrice, endPrice, cfd.taker.position);
        if (takerSettlement > 0) {
            cfd.taker.withdrawBalance = takerSettlement;
        }

        uint128 makerSettlement = (amount * 2) - takerSettlement;
        cfd.maker.withdrawBalance = makerSettlement;

         
        cfd.isSettled = true;

        emit LogCfdSettled (
            cfdId,
            cfd.maker.addr,
            cfd.taker.addr,
            amount,
            startPrice,
            endPrice,
            makerSettlement,
            takerSettlement
        );

        return true;
    }

    function withdraw(
        uint128 cfdId, 
        address partyAddress
    )
    public {
        Cfd storage cfd = contracts[cfdId];
        Party storage party = partyAddress == cfd.maker.addr ? cfd.maker : cfd.taker;
        require(party.withdrawBalance > 0);  
        require(!party.isPaid);  
        
        uint128 amount = party.withdrawBalance;
        party.withdrawBalance = 0;
        party.isPaid = true;
        
        party.addr.transfer(amount);

        emit LogWithdrawal(
            cfdId,
            party.addr,
            amount
        );
    }

    function getSettlementAmount(
        uint128 amountUInt,
        uint128 entryPriceUInt,
        uint128 exitPriceUInt,
        Position position
    )
    public
    view
    returns (uint128) {
        require(position == Position.Long || position == Position.Short);

         
        if (entryPriceUInt == exitPriceUInt) {return amountUInt;}

         
        if (entryPriceUInt == 0 && exitPriceUInt > 0) {
            return position == Position.Long ? amountUInt * 2 : 0;
        }

         
        int256 entryPrice = int256(entryPriceUInt);
        int256 exitPrice = int256(exitPriceUInt);
        int256 amount = int256(amountUInt);

         
        int256 priceDiff = position == Position.Long ? exitPrice.sub(entryPrice) : entryPrice.sub(exitPrice);
        int256 settlement = amount.add(priceDiff.mul(amount).mul(leverage).div(entryPrice));
        if (settlement < 0) {
            return 0;  
        } else if (settlement > amount * 2) {
            return amountUInt * 2;  
        } else {
            return uint128(settlement);  
        }
    }

    function refundCfd(
        uint128 cfdId
    )
    public
    returns (bool success) {
        Cfd storage cfd = contracts[cfdId];
        require(!cfd.isSettled);                 
        require(!cfd.isTaken);                   
        require(!cfd.isRefunded);                
        require(msg.sender == cfd.maker.addr);   

        cfd.isRefunded = true;
        cfd.maker.isPaid = true;
        cfd.maker.addr.transfer(cfd.amount);

        emit LogCfdRefunded(
            cfdId,
            cfd.maker.addr,
            cfd.amount
        );

        return true;
    }

    function forceRefundCfd(
        uint128 cfdId
    )
    public
    auth
    {
        Cfd storage cfd = contracts[cfdId];
        require(!cfd.isRefunded);  

        cfd.isRefunded = true;

         
        uint128 takerAmount = 0;
        if (cfd.taker.addr != address(0)) {
            takerAmount = cfd.amount;
            cfd.taker.withdrawBalance = 0;  
            cfd.taker.addr.transfer(cfd.amount);
        }

         
        cfd.maker.withdrawBalance = 0;  
        cfd.maker.addr.transfer(cfd.amount);
        
        emit LogCfdForceRefunded(
            cfdId,
            cfd.maker.addr,
            cfd.amount,
            cfd.taker.addr,
            takerAmount
        );
    } 

    function () public {
         
    }
}
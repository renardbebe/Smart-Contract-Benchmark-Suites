 

 

 
pragma solidity 0.5.7;

 
 
 
contract ITradeHistory {

     
     
    mapping (bytes32 => uint) public filled;

     
    mapping (address => mapping (bytes32 => bool)) public cancelled;

     
    mapping (address => uint) public cutoffs;

     
    mapping (address => mapping (bytes20 => uint)) public tradingPairCutoffs;

     
    mapping (address => mapping (address => uint)) public cutoffsOwner;

     
    mapping (address => mapping (address => mapping (bytes20 => uint))) public tradingPairCutoffsOwner;


    function batchUpdateFilled(
        bytes32[] calldata filledInfo
        )
        external;

    function setCancelled(
        address broker,
        bytes32 orderHash
        )
        external;

    function setCutoffs(
        address broker,
        uint cutoff
        )
        external;

    function setTradingPairCutoffs(
        address broker,
        bytes20 tokenPair,
        uint cutoff
        )
        external;

    function setCutoffsOfOwner(
        address broker,
        address owner,
        uint cutoff
        )
        external;

    function setTradingPairCutoffsOfOwner(
        address broker,
        address owner,
        bytes20 tokenPair,
        uint cutoff
        )
        external;

    function batchGetFilledAndCheckCancelled(
        bytes32[] calldata orderInfo
        )
        external
        view
        returns (uint[] memory fills);


     
     
    function authorizeAddress(
        address addr
        )
        external;

     
     
    function deauthorizeAddress(
        address addr
        )
        external;

    function isAddressAuthorized(
        address addr
        )
        public
        view
        returns (bool);


    function suspend()
        external;

    function resume()
        external;

    function kill()
        external;
}

 

 


 
contract Errors {
    string constant ZERO_VALUE                 = "ZERO_VALUE";
    string constant ZERO_ADDRESS               = "ZERO_ADDRESS";
    string constant INVALID_VALUE              = "INVALID_VALUE";
    string constant INVALID_ADDRESS            = "INVALID_ADDRESS";
    string constant INVALID_SIZE               = "INVALID_SIZE";
    string constant INVALID_SIG                = "INVALID_SIG";
    string constant INVALID_STATE              = "INVALID_STATE";
    string constant NOT_FOUND                  = "NOT_FOUND";
    string constant ALREADY_EXIST              = "ALREADY_EXIST";
    string constant REENTRY                    = "REENTRY";
    string constant UNAUTHORIZED               = "UNAUTHORIZED";
    string constant UNIMPLEMENTED              = "UNIMPLEMENTED";
    string constant UNSUPPORTED                = "UNSUPPORTED";
    string constant TRANSFER_FAILURE           = "TRANSFER_FAILURE";
    string constant WITHDRAWAL_FAILURE         = "WITHDRAWAL_FAILURE";
    string constant BURN_FAILURE               = "BURN_FAILURE";
    string constant BURN_RATE_FROZEN           = "BURN_RATE_FROZEN";
    string constant BURN_RATE_MINIMIZED        = "BURN_RATE_MINIMIZED";
    string constant UNAUTHORIZED_ONCHAIN_ORDER = "UNAUTHORIZED_ONCHAIN_ORDER";
    string constant INVALID_CANDIDATE          = "INVALID_CANDIDATE";
    string constant ALREADY_VOTED              = "ALREADY_VOTED";
    string constant NOT_OWNER                  = "NOT_OWNER";
}

 

 


 
 
 
 
contract Ownable {
    address public owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

     
     
    constructor()
        public
    {
        owner = msg.sender;
    }

     
    modifier onlyOwner()
    {
        require(msg.sender == owner, "NOT_OWNER");
        _;
    }

     
     
     
    function transferOwnership(
        address newOwner
        )
        public
        onlyOwner
    {
        require(newOwner != address(0x0), "ZERO_ADDRESS");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

 

 



 
 
 
contract Claimable is Ownable {
    address public pendingOwner;

     
    modifier onlyPendingOwner() {
        require(msg.sender == pendingOwner, "UNAUTHORIZED");
        _;
    }

     
     
    function transferOwnership(
        address newOwner
        )
        public
        onlyOwner
    {
        require(newOwner != address(0x0) && newOwner != owner, "INVALID_ADDRESS");
        pendingOwner = newOwner;
    }

     
    function claimOwnership()
        public
        onlyPendingOwner
    {
        emit OwnershipTransferred(owner, pendingOwner);
        owner = pendingOwner;
        pendingOwner = address(0x0);
    }
}

 

 




 
 
 
contract Authorizable is Claimable, Errors  {

    event AddressAuthorized(
        address indexed addr
    );

    event AddressDeauthorized(
        address indexed addr
    );

     
    address[] authorizedAddresses;

    mapping (address => uint) private positionMap;

    struct AuthorizedAddress {
        uint    pos;
        address addr;
    }

    modifier onlyAuthorized()
    {
        require(positionMap[msg.sender] > 0, UNAUTHORIZED);
        _;
    }

    function authorizeAddress(
        address addr
        )
        external
        onlyOwner
    {
        require(address(0x0) != addr, ZERO_ADDRESS);
        require(0 == positionMap[addr], ALREADY_EXIST);
        require(isContract(addr), INVALID_ADDRESS);

        authorizedAddresses.push(addr);
        positionMap[addr] = authorizedAddresses.length;
        emit AddressAuthorized(addr);
    }

    function deauthorizeAddress(
        address addr
        )
        external
        onlyOwner
    {
        require(address(0x0) != addr, ZERO_ADDRESS);

        uint pos = positionMap[addr];
        require(pos != 0, NOT_FOUND);

        uint size = authorizedAddresses.length;
        if (pos != size) {
            address lastOne = authorizedAddresses[size - 1];
            authorizedAddresses[pos - 1] = lastOne;
            positionMap[lastOne] = pos;
        }

        authorizedAddresses.length -= 1;
        delete positionMap[addr];

        emit AddressDeauthorized(addr);
    }

    function isAddressAuthorized(
        address addr
        )
        public
        view
        returns (bool)
    {
        return positionMap[addr] > 0;
    }

    function isContract(
        address addr
        )
        internal
        view
        returns (bool)
    {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

}

 

 


 
 
library MathUint {

    function mul(
        uint a,
        uint b
        )
        internal
        pure
        returns (uint c)
    {
        c = a * b;
        require(a == 0 || c / a == b, "INVALID_VALUE");
    }

    function sub(
        uint a,
        uint b
        )
        internal
        pure
        returns (uint)
    {
        require(b <= a, "INVALID_VALUE");
        return a - b;
    }

    function add(
        uint a,
        uint b
        )
        internal
        pure
        returns (uint c)
    {
        c = a + b;
        require(c >= a, "INVALID_VALUE");
    }

    function hasRoundingError(
        uint value,
        uint numerator,
        uint denominator
        )
        internal
        pure
        returns (bool)
    {
        uint multiplied = mul(value, numerator);
        uint remainder = multiplied % denominator;
         
        return mul(remainder, 100) > multiplied;
    }
}

 

 




 
 
contract Killable is Claimable, Errors  {

    bool public suspended = false;

    modifier notSuspended()
    {
        require(!suspended, INVALID_STATE);
        _;
    }

    modifier isSuspended()
    {
        require(suspended, INVALID_STATE);
        _;
    }

    function suspend()
        external
        onlyOwner
        notSuspended
    {
        suspended = true;
    }

    function resume()
        external
        onlyOwner
        isSuspended
    {
        suspended = false;
    }

     
    function kill()
        external
        onlyOwner
        isSuspended
    {
        owner = address(0x0);
        emit OwnershipTransferred(owner, address(0x0));
    }
}

 

 



 
 
contract NoDefaultFunc is Errors {
    function ()
        external
        payable
    {
        revert(UNSUPPORTED);
    }
}

 

 







 
 
contract TradeHistory is ITradeHistory, Authorizable, Killable, NoDefaultFunc {
    using MathUint for uint;

    function batchUpdateFilled(
        bytes32[] calldata filledInfo
        )
        external
        onlyAuthorized
        notSuspended
    {
        uint length = filledInfo.length;
        require(length % 2 == 0, INVALID_SIZE);

        uint start = 68;
        uint end = start + length * 32;
        for (uint p = start; p < end; p += 64) {
            bytes32 hash;
            uint filledAmount;
            assembly {
                hash := calldataload(add(p,  0))
                filledAmount := calldataload(add(p, 32))
            }
            filled[hash] = filledAmount;
        }
    }

    function setCancelled(
        address broker,
        bytes32 orderHash
        )
        external
        onlyAuthorized
        notSuspended
    {
        cancelled[broker][orderHash] = true;
    }

    function setCutoffs(
        address broker,
        uint    cutoff
        )
        external
        onlyAuthorized
        notSuspended
    {
        require(cutoffs[broker] < cutoff, INVALID_VALUE);
        cutoffs[broker] = cutoff;
    }

    function setTradingPairCutoffs(
        address broker,
        bytes20 tokenPair,
        uint    cutoff
        )
        external
        onlyAuthorized
        notSuspended
    {
        require(tradingPairCutoffs[broker][tokenPair] < cutoff, INVALID_VALUE);
        tradingPairCutoffs[broker][tokenPair] = cutoff;
    }

    function setCutoffsOfOwner(
        address broker,
        address owner,
        uint    cutoff
        )
        external
        onlyAuthorized
        notSuspended
    {
        require(cutoffsOwner[broker][owner] < cutoff, INVALID_VALUE);
        cutoffsOwner[broker][owner] = cutoff;
    }

    function setTradingPairCutoffsOfOwner(
        address broker,
        address owner,
        bytes20 tokenPair,
        uint    cutoff
        )
        external
        onlyAuthorized
        notSuspended
    {
        require(tradingPairCutoffsOwner[broker][owner][tokenPair] < cutoff, INVALID_VALUE);
        tradingPairCutoffsOwner[broker][owner][tokenPair] = cutoff;
    }

    function batchGetFilledAndCheckCancelled(
        bytes32[] calldata batch
        )
        external
        view
        returns (uint[] memory fills)
    {
        uint length = batch.length;
        require(length % 5 == 0, INVALID_SIZE);

        uint start = 68;
        uint end = start + length * 32;
        uint i = 0;
        fills = new uint[](length / 5);
        for (uint p = start; p < end; p += 160) {
            address broker;
            address owner;
            bytes32 hash;
            uint validSince;
            bytes20 tradingPair;
            assembly {
                broker := calldataload(add(p,  0))
                owner := calldataload(add(p, 32))
                hash := calldataload(add(p, 64))
                validSince := calldataload(add(p, 96))
                tradingPair := calldataload(add(p, 128))
            }
            bool valid = !cancelled[broker][hash];
            valid = valid && validSince > tradingPairCutoffs[broker][tradingPair];
            valid = valid && validSince > cutoffs[broker];
            valid = valid && validSince > tradingPairCutoffsOwner[broker][owner][tradingPair];
            valid = valid && validSince > cutoffsOwner[broker][owner];

            fills[i++] = valid ? filled[hash] : ~uint(0);
        }
    }
}
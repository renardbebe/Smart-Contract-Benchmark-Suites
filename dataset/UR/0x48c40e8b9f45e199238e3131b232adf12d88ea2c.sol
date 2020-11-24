 

 

 
pragma solidity 0.5.7;

 
 
 
 
contract ITradeDelegate {

    function batchTransfer(
        bytes32[] calldata batch
        )
        external;


     
     
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

 

 


 
 
 
library ERC20SafeTransfer {

    function safeTransfer(
        address token,
        address to,
        uint256 value)
        internal
        returns (bool success)
    {
         
         
         

         
        bytes memory callData = abi.encodeWithSelector(
            bytes4(0xa9059cbb),
            to,
            value
        );
        (success, ) = token.call(callData);
        return checkReturnValue(success);
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value)
        internal
        returns (bool success)
    {
         
         
         

         
        bytes memory callData = abi.encodeWithSelector(
            bytes4(0x23b872dd),
            from,
            to,
            value
        );
        (success, ) = token.call(callData);
        return checkReturnValue(success);
    }

    function checkReturnValue(
        bool success
        )
        internal
        pure
        returns (bool)
    {
         
         
         
        if (success) {
            assembly {
                switch returndatasize()
                 
                case 0 {
                    success := 1
                }
                 
                case 32 {
                    returndatacopy(0, 0, 32)
                    success := mload(0)
                }
                 
                default {
                    success := 0
                }
            }
        }
        return success;
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

 

 







 
 
 
contract TradeDelegate is ITradeDelegate, Authorizable, Killable, NoDefaultFunc {
    using ERC20SafeTransfer for address;

    function batchTransfer(
        bytes32[] calldata batch
        )
        external
        onlyAuthorized
        notSuspended
    {
        uint length = batch.length;
        require(length % 4 == 0, INVALID_SIZE);

        uint start = 68;
        uint end = start + length * 32;
        for (uint p = start; p < end; p += 128) {
            address token;
            address from;
            address to;
            uint amount;
            assembly {
                token := calldataload(add(p,  0))
                from := calldataload(add(p, 32))
                to := calldataload(add(p, 64))
                amount := calldataload(add(p, 96))
            }
            require(
                token.safeTransferFrom(
                    from,
                    to,
                    amount
                ),
                TRANSFER_FAILURE
            );
        }
    }
}
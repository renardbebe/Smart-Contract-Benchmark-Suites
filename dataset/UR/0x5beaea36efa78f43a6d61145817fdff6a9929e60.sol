 

 

pragma solidity 0.5.0;

 



 
 
contract IFeeHolder {

    event TokenWithdrawn(
        address owner,
        address token,
        uint value
    );

     
    mapping(address => mapping(address => uint)) public feeBalances;

     
     
     
     
    function withdrawBurned(
        address token,
        uint value
        )
        external
        returns (bool success);

     
     
     
     
     
    function withdrawToken(
        address token,
        uint value
        )
        external
        returns (bool success);

    function batchAddFeeBalances(
        bytes32[] calldata batch
        )
        external;
}

 



 
 
 
 
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



 
 
contract NoDefaultFunc is Errors {
    function ()
        external
        payable
    {
        revert(UNSUPPORTED);
    }
}



 
contract FeeHolder is IFeeHolder, NoDefaultFunc {
    using MathUint for uint;
    using ERC20SafeTransfer for address;

    address public constant delegateAddress = 0xb258f5C190faDAB30B5fF0D6ab7E32a646A4BaAe;

     
     
     
     

    modifier onlyAuthorized() {
        ITradeDelegate delegate = ITradeDelegate(delegateAddress);
        bool isAuthorized = delegate.isAddressAuthorized(msg.sender);
        require(isAuthorized, UNAUTHORIZED);
        _;
    }

    function batchAddFeeBalances(bytes32[] calldata batch)
        external
        onlyAuthorized
    {
        uint length = batch.length;
        require(length % 3 == 0, INVALID_SIZE);

        address token;
        address owner;
        uint value;
        uint start = 68;
        uint end = start + length * 32;
        for (uint p = start; p < end; p += 96) {
            assembly {
                token := calldataload(add(p,  0))
                owner := calldataload(add(p, 32))
                value := calldataload(add(p, 64))
            }
            feeBalances[token][owner] = feeBalances[token][owner].add(value);
        }
    }

    function withdrawBurned(address token, uint value)
        external
        onlyAuthorized
        returns (bool)
    {
        return withdraw(token, address(this), msg.sender, value);
    }

    function withdrawToken(address token, uint value)
        external
        returns (bool)
    {
        return withdraw(token, msg.sender, msg.sender, value);
    }

    function withdraw(address token, address from, address to, uint value)
        internal
        returns (bool success)
    {
        require(feeBalances[token][from] >= value, INVALID_VALUE);
        feeBalances[token][from] = feeBalances[token][from].sub(value);
         
        success = token.safeTransfer(to, value);
        require(success, TRANSFER_FAILURE);
        emit TokenWithdrawn(from, token, value);
    }

}
 

 

 

pragma solidity ^0.5.2;

 
contract ReentrancyGuard {
     
    uint256 private _guardCounter;

    constructor () internal {
         
         
        _guardCounter = 1;
    }

     
    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter);
    }
}

 

pragma solidity ^0.5.2;

 
library SafeMath {
     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        require(b > 0);
        uint256 c = a / b;
         

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

 

 

pragma solidity 0.5.7;



library CommonMath {
    using SafeMath for uint256;

     
    function maxUInt256()
        internal
        pure
        returns (uint256)
    {
        return 2 ** 256 - 1;
    }

     
    function safePower(
        uint256 a,
        uint256 pow
    )
        internal
        pure
        returns (uint256)
    {
        require(a > 0);

        uint256 result = 1;
        for (uint256 i = 0; i < pow; i++){
            uint256 previousResult = result;

             
            result = previousResult.mul(a);
        }

        return result;
    }

     
    function getPartialAmount(
        uint256 _principal,
        uint256 _numerator,
        uint256 _denominator
    )
        internal
        pure
        returns (uint256)
    {
         
        uint256 remainder = mulmod(_principal, _numerator, _denominator);

         
        if (remainder == 0) {
            return _principal.mul(_numerator).div(_denominator);
        }

         
        uint256 errPercentageTimes1000000 = remainder.mul(1000000).div(_numerator.mul(_principal));

         
        require(
            errPercentageTimes1000000 < 1000,
            "CommonMath.getPartialAmount: Rounding error exceeds bounds"
        );

        return _principal.mul(_numerator).div(_denominator);
    }

}

 

 
 

pragma solidity 0.5.7;


library AddressArrayUtils {

     
    function indexOf(address[] memory A, address a) internal pure returns (uint256, bool) {
        uint256 length = A.length;
        for (uint256 i = 0; i < length; i++) {
            if (A[i] == a) {
                return (i, true);
            }
        }
        return (0, false);
    }

     
    function contains(address[] memory A, address a) internal pure returns (bool) {
        bool isIn;
        (, isIn) = indexOf(A, a);
        return isIn;
    }

     
     
    function indexOfFromEnd(address[] memory A, address a) internal pure returns (uint256, bool) {
        uint256 length = A.length;
        for (uint256 i = length; i > 0; i--) {
            if (A[i - 1] == a) {
                return (i, true);
            }
        }
        return (0, false);
    }

     
    function extend(address[] memory A, address[] memory B) internal pure returns (address[] memory) {
        uint256 aLength = A.length;
        uint256 bLength = B.length;
        address[] memory newAddresses = new address[](aLength + bLength);
        for (uint256 i = 0; i < aLength; i++) {
            newAddresses[i] = A[i];
        }
        for (uint256 j = 0; j < bLength; j++) {
            newAddresses[aLength + j] = B[j];
        }
        return newAddresses;
    }

     
    function append(address[] memory A, address a) internal pure returns (address[] memory) {
        address[] memory newAddresses = new address[](A.length + 1);
        for (uint256 i = 0; i < A.length; i++) {
            newAddresses[i] = A[i];
        }
        newAddresses[A.length] = a;
        return newAddresses;
    }

     
    function sExtend(address[] storage A, address[] storage B) internal {
        uint256 length = B.length;
        for (uint256 i = 0; i < length; i++) {
            A.push(B[i]);
        }
    }

     
    function intersect(address[] memory A, address[] memory B) internal pure returns (address[] memory) {
        uint256 length = A.length;
        bool[] memory includeMap = new bool[](length);
        uint256 newLength = 0;
        for (uint256 i = 0; i < length; i++) {
            if (contains(B, A[i])) {
                includeMap[i] = true;
                newLength++;
            }
        }
        address[] memory newAddresses = new address[](newLength);
        uint256 j = 0;
        for (uint256 k = 0; k < length; k++) {
            if (includeMap[k]) {
                newAddresses[j] = A[k];
                j++;
            }
        }
        return newAddresses;
    }

     
    function union(address[] memory A, address[] memory B) internal pure returns (address[] memory) {
        address[] memory leftDifference = difference(A, B);
        address[] memory rightDifference = difference(B, A);
        address[] memory intersection = intersect(A, B);
        return extend(leftDifference, extend(intersection, rightDifference));
    }

     
    function unionB(address[] memory A, address[] memory B) internal pure returns (address[] memory) {
        bool[] memory includeMap = new bool[](A.length + B.length);
        uint256 count = 0;
        for (uint256 i = 0; i < A.length; i++) {
            includeMap[i] = true;
            count++;
        }
        for (uint256 j = 0; j < B.length; j++) {
            if (!contains(A, B[j])) {
                includeMap[A.length + j] = true;
                count++;
            }
        }
        address[] memory newAddresses = new address[](count);
        uint256 k = 0;
        for (uint256 m = 0; m < A.length; m++) {
            if (includeMap[m]) {
                newAddresses[k] = A[m];
                k++;
            }
        }
        for (uint256 n = 0; n < B.length; n++) {
            if (includeMap[A.length + n]) {
                newAddresses[k] = B[n];
                k++;
            }
        }
        return newAddresses;
    }

     
    function difference(address[] memory A, address[] memory B) internal pure returns (address[] memory) {
        uint256 length = A.length;
        bool[] memory includeMap = new bool[](length);
        uint256 count = 0;
         
        for (uint256 i = 0; i < length; i++) {
            address e = A[i];
            if (!contains(B, e)) {
                includeMap[i] = true;
                count++;
            }
        }
        address[] memory newAddresses = new address[](count);
        uint256 j = 0;
        for (uint256 k = 0; k < length; k++) {
            if (includeMap[k]) {
                newAddresses[j] = A[k];
                j++;
            }
        }
        return newAddresses;
    }

     
    function sReverse(address[] storage A) internal {
        address t;
        uint256 length = A.length;
        for (uint256 i = 0; i < length / 2; i++) {
            t = A[i];
            A[i] = A[A.length - i - 1];
            A[A.length - i - 1] = t;
        }
    }

     
    function pop(address[] memory A, uint256 index)
        internal
        pure
        returns (address[] memory, address)
    {
        uint256 length = A.length;
        address[] memory newAddresses = new address[](length - 1);
        for (uint256 i = 0; i < index; i++) {
            newAddresses[i] = A[i];
        }
        for (uint256 j = index + 1; j < length; j++) {
            newAddresses[j - 1] = A[j];
        }
        return (newAddresses, A[index]);
    }

     
    function remove(address[] memory A, address a)
        internal
        pure
        returns (address[] memory)
    {
        (uint256 index, bool isIn) = indexOf(A, a);
        if (!isIn) {
            revert();
        } else {
            (address[] memory _A,) = pop(A, index);
            return _A;
        }
    }

    function sPop(address[] storage A, uint256 index) internal returns (address) {
        uint256 length = A.length;
        if (index >= length) {
            revert("Error: index out of bounds");
        }
        address entry = A[index];
        for (uint256 i = index; i < length - 1; i++) {
            A[i] = A[i + 1];
        }
        A.length--;
        return entry;
    }

     
    function sPopCheap(address[] storage A, uint256 index) internal returns (address) {
        uint256 length = A.length;
        if (index >= length) {
            revert("Error: index out of bounds");
        }
        address entry = A[index];
        if (index != length - 1) {
            A[index] = A[length - 1];
            delete A[length - 1];
        }
        A.length--;
        return entry;
    }

     
    function sRemoveCheap(address[] storage A, address a) internal {
        (uint256 index, bool isIn) = indexOf(A, a);
        if (!isIn) {
            revert("Error: entry not found");
        } else {
            sPopCheap(A, index);
            return;
        }
    }

     
    function hasDuplicate(address[] memory A) internal pure returns (bool) {
        if (A.length == 0) {
            return false;
        }
        for (uint256 i = 0; i < A.length - 1; i++) {
            for (uint256 j = i + 1; j < A.length; j++) {
                if (A[i] == A[j]) {
                    return true;
                }
            }
        }
        return false;
    }

     
    function isEqual(address[] memory A, address[] memory B) internal pure returns (bool) {
        if (A.length != B.length) {
            return false;
        }
        for (uint256 i = 0; i < A.length; i++) {
            if (A[i] != B[i]) {
                return false;
            }
        }
        return true;
    }

     
    function argGet(address[] memory A, uint256[] memory indexArray)
        internal
        pure
        returns (address[] memory)
    {
        address[] memory array = new address[](indexArray.length);
        for (uint256 i = 0; i < indexArray.length; i++) {
            array[i] = A[indexArray[i]];
        }
        return array;
    }

}

 

 

pragma solidity 0.5.7;


 
interface ICore {
     
    function transferProxy()
        external
        view
        returns (address);

     
    function vault()
        external
        view
        returns (address);

     
    function exchangeIds(
        uint8 _exchangeId
    )
        external
        view
        returns (address);

     
    function validSets(address)
        external
        view
        returns (bool);

     
    function validModules(address)
        external
        view
        returns (bool);

     
    function validPriceLibraries(
        address _priceLibrary
    )
        external
        view
        returns (bool);

     
    function issue(
        address _set,
        uint256 _quantity
    )
        external;

     
    function issueTo(
        address _recipient,
        address _set,
        uint256 _quantity
    )
        external;

     
    function issueInVault(
        address _set,
        uint256 _quantity
    )
        external;

     
    function redeem(
        address _set,
        uint256 _quantity
    )
        external;

     
    function redeemTo(
        address _recipient,
        address _set,
        uint256 _quantity
    )
        external;

     
    function redeemInVault(
        address _set,
        uint256 _quantity
    )
        external;

     
    function redeemAndWithdrawTo(
        address _set,
        address _to,
        uint256 _quantity,
        uint256 _toExclude
    )
        external;

     
    function batchDeposit(
        address[] calldata _tokens,
        uint256[] calldata _quantities
    )
        external;

     
    function batchWithdraw(
        address[] calldata _tokens,
        uint256[] calldata _quantities
    )
        external;

     
    function deposit(
        address _token,
        uint256 _quantity
    )
        external;

     
    function withdraw(
        address _token,
        uint256 _quantity
    )
        external;

     
    function internalTransfer(
        address _token,
        address _to,
        uint256 _quantity
    )
        external;

     
    function createSet(
        address _factory,
        address[] calldata _components,
        uint256[] calldata _units,
        uint256 _naturalUnit,
        bytes32 _name,
        bytes32 _symbol,
        bytes calldata _callData
    )
        external
        returns (address);

     
    function depositModule(
        address _from,
        address _to,
        address _token,
        uint256 _quantity
    )
        external;

     
    function withdrawModule(
        address _from,
        address _to,
        address _token,
        uint256 _quantity
    )
        external;

     
    function batchDepositModule(
        address _from,
        address _to,
        address[] calldata _tokens,
        uint256[] calldata _quantities
    )
        external;

     
    function batchWithdrawModule(
        address _from,
        address _to,
        address[] calldata _tokens,
        uint256[] calldata _quantities
    )
        external;

     
    function issueModule(
        address _owner,
        address _recipient,
        address _set,
        uint256 _quantity
    )
        external;

     
    function redeemModule(
        address _burnAddress,
        address _incrementAddress,
        address _set,
        uint256 _quantity
    )
        external;

     
    function batchIncrementTokenOwnerModule(
        address[] calldata _tokens,
        address _owner,
        uint256[] calldata _quantities
    )
        external;

     
    function batchDecrementTokenOwnerModule(
        address[] calldata _tokens,
        address _owner,
        uint256[] calldata _quantities
    )
        external;

     
    function batchTransferBalanceModule(
        address[] calldata _tokens,
        address _from,
        address _to,
        uint256[] calldata _quantities
    )
        external;

     
    function transferModule(
        address _token,
        uint256 _quantity,
        address _from,
        address _to
    )
        external;

     
    function batchTransferModule(
        address[] calldata _tokens,
        uint256[] calldata _quantities,
        address _from,
        address _to
    )
        external;
}

 

 

pragma solidity 0.5.7;

 
interface ISetToken {

     

     
    function naturalUnit()
        external
        view
        returns (uint256);

     
    function getComponents()
        external
        view
        returns (address[] memory);

     
    function getUnits()
        external
        view
        returns (uint256[] memory);

     
    function tokenIsComponent(
        address _tokenAddress
    )
        external
        view
        returns (bool);

     
    function mint(
        address _issuer,
        uint256 _quantity
    )
        external;

     
    function burn(
        address _from,
        uint256 _quantity
    )
        external;

     
    function transfer(
        address to,
        uint256 value
    )
        external;
}

 

 

pragma solidity 0.5.7;

 
interface IVault {

     
    function withdrawTo(
        address _token,
        address _to,
        uint256 _quantity
    )
        external;

     
    function incrementTokenOwner(
        address _token,
        address _owner,
        uint256 _quantity
    )
        external;

     
    function decrementTokenOwner(
        address _token,
        address _owner,
        uint256 _quantity
    )
        external;

     

    function transferBalance(
        address _token,
        address _from,
        address _to,
        uint256 _quantity
    )
        external;


     
    function batchWithdrawTo(
        address[] calldata _tokens,
        address _to,
        uint256[] calldata _quantities
    )
        external;

     
    function batchIncrementTokenOwner(
        address[] calldata _tokens,
        address _owner,
        uint256[] calldata _quantities
    )
        external;

     
    function batchDecrementTokenOwner(
        address[] calldata _tokens,
        address _owner,
        uint256[] calldata _quantities
    )
        external;

    
    function batchTransferBalance(
        address[] calldata _tokens,
        address _from,
        address _to,
        uint256[] calldata _quantities
    )
        external;

     
    function getOwnerBalance(
        address _token,
        address _owner
    )
        external
        view
        returns (uint256);
}

 

 

pragma solidity 0.5.7;







 
library ExchangeIssuanceLibrary {
    using SafeMath for uint256;
    using AddressArrayUtils for address[];

     

    struct ExchangeIssuanceParams {
        address setAddress;
        uint256 quantity;
        uint8[] sendTokenExchangeIds;
        address[] sendTokens;
        uint256[] sendTokenAmounts;
        address[] receiveTokens;
        uint256[] receiveTokenAmounts;
    }

     
    function validateQuantity(
        address _set,
        uint256 _quantity
    )
        internal
        view
    {
         
        require(
            _quantity > 0,
            "ExchangeIssuanceLibrary.validateQuantity: Quantity must be positive"
        );

         
        require(
            _quantity.mod(ISetToken(_set).naturalUnit()) == 0,
            "ExchangeIssuanceLibrary.validateQuantity: Quantity must be multiple of natural unit"
        );
    }

     
    function validateReceiveTokens(
        address[] memory _receiveTokens,
        uint256[] memory _receiveTokenAmounts
    )
        internal
        view
    {
        uint256 receiveTokensCount = _receiveTokens.length;

         
        require(
            receiveTokensCount > 0,
            "ExchangeIssuanceLibrary.validateReceiveTokens: Receive tokens must not be empty"
        );

         
        require(
            !_receiveTokens.hasDuplicate(),
            "ExchangeIssuanceLibrary.validateReceiveTokens: Receive tokens must not have duplicates"
        );

         
        require(
            receiveTokensCount == _receiveTokenAmounts.length,
            "ExchangeIssuanceLibrary.validateReceiveTokens: Receive tokens and amounts must be equal length"
        );

        for (uint256 i = 0; i < receiveTokensCount; i++) {
             
            require(
                _receiveTokenAmounts[i] > 0,
                "ExchangeIssuanceLibrary.validateReceiveTokens: Component amounts must be positive"
            );
        }
    }

     
    function validatePostExchangeReceiveTokenBalances(
        address _vault,
        address[] memory _receiveTokens,
        uint256[] memory _requiredBalances,
        address _userToCheck
    )
        internal
        view
    {
         
        IVault vault = IVault(_vault);

         
        for (uint256 i = 0; i < _receiveTokens.length; i++) {
            uint256 currentBal = vault.getOwnerBalance(
                _receiveTokens[i],
                _userToCheck
            );

            require(
                currentBal >= _requiredBalances[i],
                "ExchangeIssuanceLibrary.validatePostExchangeReceiveTokenBalances: Insufficient receive token acquired"
            );
        }
    }

     
    function validateSendTokenParams(
        address _core,
        uint8[] memory _sendTokenExchangeIds,
        address[] memory _sendTokens,
        uint256[] memory _sendTokenAmounts
    )
        internal
        view
    {
        require(
            _sendTokens.length > 0,
            "ExchangeIssuanceLibrary.validateSendTokenParams: Send token inputs must not be empty"
        );

        require(
            _sendTokenExchangeIds.length == _sendTokens.length &&
            _sendTokens.length == _sendTokenAmounts.length,
            "ExchangeIssuanceLibrary.validateSendTokenParams: Send token inputs must be of the same length"
        );

        ICore core = ICore(_core);

        for (uint256 i = 0; i < _sendTokenExchangeIds.length; i++) {
             
            require(
                core.exchangeIds(_sendTokenExchangeIds[i]) != address(0),
                "ExchangeIssuanceLibrary.validateSendTokenParams: Must be valid exchange"
            );

             
            require(
                _sendTokenAmounts[i] > 0,
                "ExchangeIssuanceLibrary.validateSendTokenParams: Send amounts must be positive"
            );
        }
    }
}

 

 

pragma solidity 0.5.7;


 
interface IERC20 {
    function balanceOf(
        address _owner
    )
        external
        view
        returns (uint256);

    function allowance(
        address _owner,
        address _spender
    )
        external
        view
        returns (uint256);

    function transfer(
        address _to,
        uint256 _quantity
    )
        external;

    function transferFrom(
        address _from,
        address _to,
        uint256 _quantity
    )
        external;

    function approve(
        address _spender,
        uint256 _quantity
    )
        external
        returns (bool);

    function totalSupply()
        external
        returns (uint256);
}

 

 

pragma solidity 0.5.7;




 
library ERC20Wrapper {

     

     
    function balanceOf(
        address _token,
        address _owner
    )
        external
        view
        returns (uint256)
    {
        return IERC20(_token).balanceOf(_owner);
    }

     
    function allowance(
        address _token,
        address _owner,
        address _spender
    )
        internal
        view
        returns (uint256)
    {
        return IERC20(_token).allowance(_owner, _spender);
    }

     
    function transfer(
        address _token,
        address _to,
        uint256 _quantity
    )
        external
    {
        IERC20(_token).transfer(_to, _quantity);

         
        require(
            checkSuccess(),
            "ERC20Wrapper.transfer: Bad return value"
        );
    }

     
    function transferFrom(
        address _token,
        address _from,
        address _to,
        uint256 _quantity
    )
        external
    {
        IERC20(_token).transferFrom(_from, _to, _quantity);

         
        require(
            checkSuccess(),
            "ERC20Wrapper.transferFrom: Bad return value"
        );
    }

     
    function approve(
        address _token,
        address _spender,
        uint256 _quantity
    )
        internal
    {
        IERC20(_token).approve(_spender, _quantity);

         
        require(
            checkSuccess(),
            "ERC20Wrapper.approve: Bad return value"
        );
    }

     
    function ensureAllowance(
        address _token,
        address _owner,
        address _spender,
        uint256 _quantity
    )
        internal
    {
        uint256 currentAllowance = allowance(_token, _owner, _spender);
        if (currentAllowance < _quantity) {
            approve(
                _token,
                _spender,
                CommonMath.maxUInt256()
            );
        }
    }

     

     
    function checkSuccess(
    )
        private
        pure
        returns (bool)
    {
         
        uint256 returnValue = 0;

        assembly {
             
            switch returndatasize

             
            case 0x0 {
                returnValue := 1
            }

             
            case 0x20 {
                 
                returndatacopy(0x0, 0x0, 0x20)

                 
                returnValue := mload(0x0)
            }

             
            default { }
        }

         
        return returnValue == 1;
    }
}

 

 

pragma solidity 0.5.7;
pragma experimental "ABIEncoderV2";


 
interface IExchangeIssuanceModule {

    function exchangeIssue(
        ExchangeIssuanceLibrary.ExchangeIssuanceParams calldata _exchangeIssuanceParams,
        bytes calldata _orderData
    )
        external;


    function exchangeRedeem(
        ExchangeIssuanceLibrary.ExchangeIssuanceParams calldata _exchangeIssuanceParams,
        bytes calldata _orderData
    )
        external;
}

 

 

pragma solidity 0.5.7;


 
library RebalancingLibrary {

     

    enum State { Default, Proposal, Rebalance, Drawdown }

     

    struct AuctionPriceParameters {
        uint256 auctionStartTime;
        uint256 auctionTimeToPivot;
        uint256 auctionStartPrice;
        uint256 auctionPivotPrice;
    }

    struct BiddingParameters {
        uint256 minimumBid;
        uint256 remainingCurrentSets;
        uint256[] combinedCurrentUnits;
        uint256[] combinedNextSetUnits;
        address[] combinedTokenArray;
    }
}

 

 

pragma solidity 0.5.7;


 

interface IRebalancingSetToken {

     
    function auctionLibrary()
        external
        view
        returns (address);

     
    function totalSupply()
        external
        view
        returns (uint256);

     
    function proposalStartTime()
        external
        view
        returns (uint256);

     
    function lastRebalanceTimestamp()
        external
        view
        returns (uint256);

     
    function rebalanceInterval()
        external
        view
        returns (uint256);

     
    function rebalanceState()
        external
        view
        returns (RebalancingLibrary.State);

     
    function startingCurrentSetAmount()
        external
        view
        returns (uint256);

     
    function balanceOf(
        address owner
    )
        external
        view
        returns (uint256);

     
    function propose(
        address _nextSet,
        address _auctionLibrary,
        uint256 _auctionTimeToPivot,
        uint256 _auctionStartPrice,
        uint256 _auctionPivotPrice
    )
        external;

     
    function naturalUnit()
        external
        view
        returns (uint256);

     
    function currentSet()
        external
        view
        returns (address);

     
    function nextSet()
        external
        view
        returns (address);

     
    function unitShares()
        external
        view
        returns (uint256);

     
    function burn(
        address _from,
        uint256 _quantity
    )
        external;

     
    function placeBid(
        uint256 _quantity
    )
        external
        returns (address[] memory, uint256[] memory, uint256[] memory);

     
    function getCombinedTokenArrayLength()
        external
        view
        returns (uint256);

     
    function getCombinedTokenArray()
        external
        view
        returns (address[] memory);

     
    function getFailedAuctionWithdrawComponents()
        external
        view
        returns (address[] memory);

     
    function getAuctionPriceParameters()
        external
        view
        returns (uint256[] memory);

     
    function getBiddingParameters()
        external
        view
        returns (uint256[] memory);

}

 

 

pragma solidity 0.5.7;

 
interface ITransferProxy {

     

     
    function transfer(
        address _token,
        uint256 _quantity,
        address _from,
        address _to
    )
        external;

     
    function batchTransfer(
        address[] calldata _tokens,
        uint256[] calldata _quantities,
        address _from,
        address _to
    )
        external;
}

 

 

pragma solidity 0.5.7;


 
interface IWETH {
    function deposit()
        external
        payable;

    function withdraw(
        uint256 wad
    )
        external;
}

 

 

pragma solidity 0.5.7;





 
contract ModuleCoreStateV2 {

     

     
    ICore public coreInstance;

     
    IVault public vaultInstance;

     
    ITransferProxy public transferProxyInstance;

     

     
    constructor(
        ICore _core,
        IVault _vault,
        ITransferProxy _transferProxy
    )
        public
    {
         
        coreInstance = _core;

         
        vaultInstance = _vault;

         
        transferProxyInstance = _transferProxy;
    }
}

 

 

pragma solidity 0.5.7;







 
contract TokenFlush is
    ModuleCoreStateV2
{
    using SafeMath for uint256;
    using AddressArrayUtils for address[];

     

     
    function returnExcessBaseSetFromContract(
        address _baseSetAddress,
        address _returnAddress,
        bool _keepChangeInVault
    )
        internal
    {
        uint256 baseSetQuantity = ERC20Wrapper.balanceOf(_baseSetAddress, address(this));

        if (baseSetQuantity > 0) {
            if (_keepChangeInVault) {
                 
                ERC20Wrapper.ensureAllowance(
                    _baseSetAddress,
                    address(this),
                    address(transferProxyInstance),
                    baseSetQuantity
                );

                 
                coreInstance.depositModule(
                    address(this),
                    _returnAddress,
                    _baseSetAddress,
                    baseSetQuantity
                );
            } else {
                 
                ERC20Wrapper.transfer(
                    _baseSetAddress,
                    _returnAddress,
                    baseSetQuantity
                );
            }
        }
    }

     
    function returnExcessBaseSetInVault(
        address _baseSetAddress,
        address _returnAddress,
        bool _keepChangeInVault
    )
        internal
    {
         
        uint256 baseSetQuantityInVault = vaultInstance.getOwnerBalance(
            _baseSetAddress,
            address(this)
        );

        if (baseSetQuantityInVault > 0) {
            if (_keepChangeInVault) {
                 
                coreInstance.internalTransfer(
                    _baseSetAddress,
                    _returnAddress,
                    baseSetQuantityInVault
                );
            } else {
                 
                coreInstance.withdrawModule(
                    address(this),
                    _returnAddress,
                    _baseSetAddress,
                    baseSetQuantityInVault
                );
            }
        }
    }

     
    function returnExcessComponentsFromContract(
        ISetToken _baseSetToken,
        address _returnAddress
    )
        internal
    {
         
        address[] memory baseSetComponents = _baseSetToken.getComponents();
        for (uint256 i = 0; i < baseSetComponents.length; i++) {
            uint256 withdrawQuantity = ERC20Wrapper.balanceOf(baseSetComponents[i], address(this));
            if (withdrawQuantity > 0) {
                ERC20Wrapper.transfer(
                    baseSetComponents[i],
                    _returnAddress,
                    withdrawQuantity
                );
            }
        }
    }

     
    function returnExcessComponentsFromVault(
        ISetToken _baseSetToken,
        address _returnAddress
    )
        internal
    {
         
        address[] memory baseSetComponents = _baseSetToken.getComponents();
        for (uint256 i = 0; i < baseSetComponents.length; i++) {
            uint256 vaultQuantity = vaultInstance.getOwnerBalance(baseSetComponents[i], address(this));
            if (vaultQuantity > 0) {
                coreInstance.withdrawModule(
                    address(this),
                    _returnAddress,
                    baseSetComponents[i],
                    vaultQuantity
                );
            }
        }
    }
}

 

 

pragma solidity 0.5.7;
















 
contract RebalancingSetExchangeIssuanceModule is
    ModuleCoreStateV2,
    TokenFlush,
    ReentrancyGuard
{
    using SafeMath for uint256;

     

     
    IExchangeIssuanceModule public exchangeIssuanceModuleInstance;

     
    IWETH public wethInstance;

     

    event LogPayableExchangeIssue(
        address indexed rebalancingSetAddress,
        address indexed callerAddress,
        address paymentTokenAddress,
        uint256 rebalancingSetQuantity,
        uint256 paymentTokenReturned
    );

    event LogPayableExchangeRedeem(
        address indexed rebalancingSetAddress,
        address indexed callerAddress,
        address outputTokenAddress,
        uint256 rebalancingSetQuantity,
        uint256 outputTokenQuantity
    );

     

     
    constructor(
        ICore _core,
        ITransferProxy _transferProxy,
        IExchangeIssuanceModule _exchangeIssuanceModule,
        IWETH _wrappedEther,
        IVault _vault
    )
        public
        ModuleCoreStateV2(
            _core,
            _vault,
            _transferProxy
        )
    {
         
        exchangeIssuanceModuleInstance = _exchangeIssuanceModule;

         
        wethInstance = _wrappedEther;

         
        ERC20Wrapper.approve(
            address(_wrappedEther),
            address(_transferProxy),
            CommonMath.maxUInt256()
        );
    }

     
    function ()
        external
        payable
    {
        require(
            msg.sender == address(wethInstance),
            "RebalancingSetExchangeIssuanceModule.fallback: Cannot receive ETH directly unless unwrapping WETH"
        );
    }

     

     
    function issueRebalancingSetWithEther(
        address _rebalancingSetAddress,
        uint256 _rebalancingSetQuantity,
        ExchangeIssuanceLibrary.ExchangeIssuanceParams memory _exchangeIssuanceParams,
        bytes memory _orderData,
        bool _keepChangeInVault
    )
        public
        payable
        nonReentrant
    {
         
        wethInstance.deposit.value(msg.value)();

         
        issueRebalancingSetInternal(
            _rebalancingSetAddress,
            _rebalancingSetQuantity,
            address(wethInstance),
            msg.value,
            _exchangeIssuanceParams,
            _orderData,
            _keepChangeInVault
        );

         
        uint256 leftoverWeth = ERC20Wrapper.balanceOf(address(wethInstance), address(this));
        if (leftoverWeth > 0) {
             
            wethInstance.withdraw(leftoverWeth);

             
            msg.sender.transfer(leftoverWeth);
        }

        emit LogPayableExchangeIssue(
            _rebalancingSetAddress,
            msg.sender,
            address(wethInstance),
            _rebalancingSetQuantity,
            leftoverWeth
        );
    }

     
    function issueRebalancingSetWithERC20(
        address _rebalancingSetAddress,
        uint256 _rebalancingSetQuantity,
        address _paymentTokenAddress,
        uint256 _paymentTokenQuantity,
        ExchangeIssuanceLibrary.ExchangeIssuanceParams memory _exchangeIssuanceParams,
        bytes memory _orderData,
        bool _keepChangeInVault
    )
        public
        nonReentrant
    {
         
        coreInstance.transferModule(
            _paymentTokenAddress,
            _paymentTokenQuantity,
            msg.sender,
            address(this)
        );

         
        issueRebalancingSetInternal(
            _rebalancingSetAddress,
            _rebalancingSetQuantity,
            _paymentTokenAddress,
            _paymentTokenQuantity,
            _exchangeIssuanceParams,
            _orderData,
            _keepChangeInVault
        );

         
        uint256 leftoverPaymentTokenQuantity = ERC20Wrapper.balanceOf(_paymentTokenAddress, address(this));
        if (leftoverPaymentTokenQuantity > 0) {
            ERC20Wrapper.transfer(
                _paymentTokenAddress,
                msg.sender,
                leftoverPaymentTokenQuantity
            );
        }

        emit LogPayableExchangeIssue(
            _rebalancingSetAddress,
            msg.sender,
            _paymentTokenAddress,
            _rebalancingSetQuantity,
            leftoverPaymentTokenQuantity
        );
    }

     
    function redeemRebalancingSetIntoEther(
        address _rebalancingSetAddress,
        uint256 _rebalancingSetQuantity,
        ExchangeIssuanceLibrary.ExchangeIssuanceParams memory _exchangeIssuanceParams,
        bytes memory _orderData,
        bool _keepChangeInVault
    )
        public
        nonReentrant
    {
         
         
        redeemRebalancingSetIntoComponentsInternal(
            _rebalancingSetAddress,
            _rebalancingSetQuantity,
            address(wethInstance),
            _exchangeIssuanceParams,
            _orderData
        );

         
         
         
        uint256 wethQuantityInVault = vaultInstance.getOwnerBalance(address(wethInstance), address(this));
        if (wethQuantityInVault > 0) {
            coreInstance.withdrawModule(
                address(this),
                address(this),
                address(wethInstance),
                wethQuantityInVault
            );
        }

         
        uint256 wethBalance = ERC20Wrapper.balanceOf(address(wethInstance), address(this));
        if (wethBalance > 0) {
            wethInstance.withdraw(wethBalance);
            msg.sender.transfer(wethBalance);
        }

        address baseSetAddress = _exchangeIssuanceParams.setAddress;

         
        returnExcessBaseSetFromContract(
            baseSetAddress,
            msg.sender,
            _keepChangeInVault
        );

         
        returnExcessComponentsFromContract(ISetToken(baseSetAddress), msg.sender);

        emit LogPayableExchangeRedeem(
            _rebalancingSetAddress,
            msg.sender,
            address(wethInstance),
            _rebalancingSetQuantity,
            wethBalance
        );
    }

     
    function redeemRebalancingSetIntoERC20(
        address _rebalancingSetAddress,
        uint256 _rebalancingSetQuantity,
        address _outputTokenAddress,
        ExchangeIssuanceLibrary.ExchangeIssuanceParams memory _exchangeIssuanceParams,
        bytes memory _orderData,
        bool _keepChangeInVault
    )
        public
        nonReentrant
    {
         
         
        redeemRebalancingSetIntoComponentsInternal(
            _rebalancingSetAddress,
            _rebalancingSetQuantity,
            _outputTokenAddress,
            _exchangeIssuanceParams,
            _orderData
        );

         
         
        uint256 outputTokenInVault = vaultInstance.getOwnerBalance(_outputTokenAddress, address(this));
        if (outputTokenInVault > 0) {
            coreInstance.withdrawModule(
                address(this),
                address(this),
                _outputTokenAddress,
                outputTokenInVault
            );
        }

         
        uint256 outputTokenBalance = ERC20Wrapper.balanceOf(_outputTokenAddress, address(this));
        ERC20Wrapper.transfer(
            _outputTokenAddress,
            msg.sender,
            outputTokenBalance
        );

        address baseSetAddress = _exchangeIssuanceParams.setAddress;

         
        returnExcessBaseSetFromContract(
            baseSetAddress,
            msg.sender,
            _keepChangeInVault
        );

         
        returnExcessComponentsFromContract(ISetToken(baseSetAddress), msg.sender);

        emit LogPayableExchangeRedeem(
            _rebalancingSetAddress,
            msg.sender,
            _outputTokenAddress,
            _rebalancingSetQuantity,
            outputTokenBalance
        );
    }


     

     
    function validateExchangeIssuanceInputs(
        address _transactTokenAddress,
        IRebalancingSetToken _rebalancingSetAddress,
        uint256 _rebalancingSetQuantity,
        address _baseSetAddress,
        address[] memory _transactTokenArray
    )
        private
        view
    {
         
        require(
            coreInstance.validSets(address(_rebalancingSetAddress)),
            "RebalancingSetExchangeIssuance.validateExchangeIssuanceInputs: Invalid or disabled SetToken address"
        );

        require(
            _rebalancingSetQuantity > 0,
            "RebalancingSetExchangeIssuance.validateExchangeIssuanceInputs: Quantity must be > 0"
        );

         
        require(
            _rebalancingSetQuantity.mod(_rebalancingSetAddress.naturalUnit()) == 0,
            "RebalancingSetExchangeIssuance.validateExchangeIssuanceInputs: Quantity must be multiple of natural unit"
        );

         
         
         
         
        for (uint256 i = 0; i < _transactTokenArray.length; i++) {
             
            require(
                _transactTokenAddress == _transactTokenArray[i],
                "RebalancingSetExchangeIssuance.validateExchangeIssuanceInputs: Send/Receive token must match transact token"
            );
        }

         
        address baseSet = _rebalancingSetAddress.currentSet();
        require(
            baseSet == _baseSetAddress,
            "RebalancingSetExchangeIssuance.validateExchangeIssuanceInputs: Base Set addresses must match"
        );
    }

     
    function issueRebalancingSetInternal(
        address _rebalancingSetAddress,
        uint256 _rebalancingSetQuantity,
        address _paymentTokenAddress,
        uint256 _paymentTokenQuantity,
        ExchangeIssuanceLibrary.ExchangeIssuanceParams memory _exchangeIssuanceParams,
        bytes memory _orderData,
        bool _keepChangeInVault
    )
        private
    {
        address baseSetAddress = _exchangeIssuanceParams.setAddress;
        uint256 baseSetIssueQuantity = _exchangeIssuanceParams.quantity;

         
        validateExchangeIssuanceInputs(
            _paymentTokenAddress,
            IRebalancingSetToken(_rebalancingSetAddress),
            _rebalancingSetQuantity,
            baseSetAddress,
            _exchangeIssuanceParams.sendTokens
        );

         
         
         
        ERC20Wrapper.ensureAllowance(
            _paymentTokenAddress,
            address(this),
            address(transferProxyInstance),
            _paymentTokenQuantity
        );

         
        exchangeIssuanceModuleInstance.exchangeIssue(
            _exchangeIssuanceParams,
            _orderData
        );

         
        ERC20Wrapper.ensureAllowance(
            baseSetAddress,
            address(this),
            address(transferProxyInstance),
            baseSetIssueQuantity
        );

         
        coreInstance.issueTo(
            msg.sender,
            _rebalancingSetAddress,
            _rebalancingSetQuantity
        );

         
         
         
        returnExcessBaseSetFromContract(
            baseSetAddress,
            msg.sender,
            _keepChangeInVault
        );

         
        returnExcessComponentsFromVault(ISetToken(baseSetAddress), msg.sender);
    }

     
    function redeemRebalancingSetIntoComponentsInternal(
        address _rebalancingSetAddress,
        uint256 _rebalancingSetQuantity,
        address _receiveTokenAddress,
        ExchangeIssuanceLibrary.ExchangeIssuanceParams memory _exchangeIssuanceParams,
        bytes memory _orderData
    )
        private
    {
         
        validateExchangeIssuanceInputs(
            _receiveTokenAddress,
            IRebalancingSetToken(_rebalancingSetAddress),
            _rebalancingSetQuantity,
            _exchangeIssuanceParams.setAddress,
            _exchangeIssuanceParams.receiveTokens
        );

         
        coreInstance.redeemModule(
            msg.sender,
            address(this),
            _rebalancingSetAddress,
            _rebalancingSetQuantity
        );

        address baseSetAddress = _exchangeIssuanceParams.setAddress;
        uint256 baseSetVaultQuantity = vaultInstance.getOwnerBalance(baseSetAddress, address(this));

         
        coreInstance.withdrawModule(
            address(this),
            address(this),
            baseSetAddress,
            baseSetVaultQuantity
        );

         
         
         
        exchangeIssuanceModuleInstance.exchangeRedeem(
            _exchangeIssuanceParams,
            _orderData
        );
    }
}
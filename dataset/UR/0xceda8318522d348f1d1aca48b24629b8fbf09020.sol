 

 

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



 
library RebalancingLibraryV2 {
    using SafeMath for uint256;

     

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


 

interface IRebalancingSetTokenV2 {

     
    function totalSupply()
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
        returns (RebalancingLibraryV2.State);

     
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

     
    function getBiddingParameters()
        external
        view
        returns (uint256[] memory);

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





 
contract ModuleCoreState {

     

     
    address public core;

     
    address public vault;

     
    ICore public coreInstance;

     
    IVault public vaultInstance;

     

     
    constructor(
        address _core,
        address _vault
    )
        public
    {
         
        core = _core;

         
        coreInstance = ICore(_core);

         
        vault = _vault;

         
        vaultInstance = IVault(_vault);
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








 
contract RebalancingSetIssuance is
    ModuleCoreState
{
    using SafeMath for uint256;
    using AddressArrayUtils for address[];

     

     
    function validateWETHIsAComponentOfSet(
        address _setAddress,
        address _wrappedEtherAddress
    )
        internal
        view
    {
        require(
            ISetToken(_setAddress).tokenIsComponent(_wrappedEtherAddress),
            "RebalancingSetIssuance.validateWETHIsAComponentOfSet: Components must contain weth"
        );
    }

     
    function validateRebalancingSetIssuance(
        address _rebalancingSetAddress,
        uint256 _rebalancingSetQuantity
    )
        internal
        view
    {
         
        require(
            coreInstance.validSets(_rebalancingSetAddress),
            "RebalancingSetIssuance.validateRebalancingIssuance: Invalid or disabled SetToken address"
        );

         
        require(
            _rebalancingSetQuantity.mod(ISetToken(_rebalancingSetAddress).naturalUnit()) == 0,
            "RebalancingSetIssuance.validateRebalancingIssuance: Quantity must be multiple of natural unit"
        );
    }

     
    function getBaseSetIssuanceRequiredQuantity(
        address _rebalancingSetAddress,
        uint256 _rebalancingSetQuantity
    )
        internal
        view
        returns (uint256)
    {
        IRebalancingSetTokenV2 rebalancingSet = IRebalancingSetTokenV2(_rebalancingSetAddress);

        uint256 unitShares = rebalancingSet.unitShares();
        uint256 naturalUnit = rebalancingSet.naturalUnit();

        uint256 requiredBaseSetQuantity = _rebalancingSetQuantity.div(naturalUnit).mul(unitShares);

        address baseSet = rebalancingSet.currentSet();
        uint256 baseSetNaturalUnit = ISetToken(baseSet).naturalUnit();

         
         
        uint256 roundDownQuantity = requiredBaseSetQuantity.mod(baseSetNaturalUnit);
        if (roundDownQuantity > 0) {
            requiredBaseSetQuantity = requiredBaseSetQuantity.sub(roundDownQuantity).add(baseSetNaturalUnit);
        }

        return requiredBaseSetQuantity;
    }


     
    function getBaseSetRedeemQuantity(
        address _baseSetAddress
    )
        internal
        view
        returns (uint256)
    {
         
        uint256 baseSetNaturalUnit = ISetToken(_baseSetAddress).naturalUnit();
        uint256 baseSetBalance = vaultInstance.getOwnerBalance(
            _baseSetAddress,
            address(this)
        );

         
        return baseSetBalance.sub(baseSetBalance.mod(baseSetNaturalUnit));
    }

     
    function returnExcessBaseSet(
        address _baseSetAddress,
        address _transferProxyAddress,
        bool _keepChangeInVault
    )
        internal
    {
        returnExcessBaseSetFromContract(_baseSetAddress, _transferProxyAddress, _keepChangeInVault);

        returnExcessBaseSetInVault(_baseSetAddress, _keepChangeInVault);
    }

     
    function returnExcessBaseSetFromContract(
        address _baseSetAddress,
        address _transferProxyAddress,
        bool _keepChangeInVault
    )
        internal
    {
        uint256 baseSetQuantity = ERC20Wrapper.balanceOf(_baseSetAddress, address(this));

        if (baseSetQuantity == 0) {
            return;
        } else if (_keepChangeInVault) {
             
            ERC20Wrapper.ensureAllowance(
                _baseSetAddress,
                address(this),
                _transferProxyAddress,
                baseSetQuantity
            );

             
            coreInstance.depositModule(
                address(this),
                msg.sender,
                _baseSetAddress,
                baseSetQuantity
            );
        } else {
             
            ERC20Wrapper.transfer(
                _baseSetAddress,
                msg.sender,
                baseSetQuantity
            );
        }
    }

     
    function returnExcessBaseSetInVault(
        address _baseSetAddress,
        bool _keepChangeInVault
    )
        internal
    {
         
        uint256 baseSetQuantityInVault = vaultInstance.getOwnerBalance(
            _baseSetAddress,
            address(this)
        );

        if (baseSetQuantityInVault == 0) {
            return;
        } else if (_keepChangeInVault) {
             
            coreInstance.internalTransfer(
                _baseSetAddress,
                msg.sender,
                baseSetQuantityInVault
            );
        } else {
             
            coreInstance.withdrawModule(
                address(this),
                msg.sender,
                _baseSetAddress,
                baseSetQuantityInVault
            );
        }
    }
}

 

 

pragma solidity 0.5.7;










 
contract RebalancingSetIssuanceModule is
    ModuleCoreState,
    RebalancingSetIssuance,
    ReentrancyGuard
{
    using SafeMath for uint256;

     
    address public transferProxy;

     
    IWETH public weth;

     

    event LogRebalancingSetIssue(
        address indexed rebalancingSetAddress,
        address indexed callerAddress,
        uint256 rebalancingSetQuantity
    );

    event LogRebalancingSetRedeem(
        address indexed rebalancingSetAddress,
        address indexed callerAddress,
        uint256 rebalancingSetQuantity
    );

     

     
    constructor(
        address _core,
        address _vault,
        address _transferProxy,
        IWETH _weth
    )
        public
        ModuleCoreState(
            _core,
            _vault
        )
    {
         
        weth = _weth;

         
        transferProxy = _transferProxy;
    }

     
    function ()
        external
        payable
    {
        require(
            msg.sender == address(weth),
            "RebalancingSetIssuanceModule.fallback: Cannot receive ETH directly unless unwrapping WETH"
        );
    }

     

     
    function issueRebalancingSet(
        address _rebalancingSetAddress,
        uint256 _rebalancingSetQuantity,
        bool _keepChangeInVault
    )
        external
        nonReentrant
    {
         
        (
            address baseSetAddress,
            uint256 requiredBaseSetQuantity
        ) = getBaseSetAddressAndQuantity(_rebalancingSetAddress, _rebalancingSetQuantity);

         
        coreInstance.issueModule(
            msg.sender,
            address(this),
            baseSetAddress,
            requiredBaseSetQuantity
        );

         
        ERC20Wrapper.ensureAllowance(
            baseSetAddress,
            address(this),
            transferProxy,
            requiredBaseSetQuantity
        );

         
        issueRebalancingSetAndReturnExcessBase(
            _rebalancingSetAddress,
            baseSetAddress,
            _rebalancingSetQuantity,
            _keepChangeInVault
        );
    }

     
    function issueRebalancingSetWrappingEther(
        address _rebalancingSetAddress,
        uint256 _rebalancingSetQuantity,
        bool _keepChangeInVault
    )
        external
        payable
        nonReentrant
    {
         
        (
            address baseSetAddress,
            uint256 requiredBaseSetQuantity
        ) = getBaseSetAddressAndQuantity(_rebalancingSetAddress, _rebalancingSetQuantity);

         
        validateWETHIsAComponentOfSet(baseSetAddress, address(weth));

         
         
        depositComponentsAndHandleEth(
            baseSetAddress,
            requiredBaseSetQuantity
        );

         
        coreInstance.issueInVault(
            baseSetAddress,
            requiredBaseSetQuantity
        );

         

         
        issueRebalancingSetAndReturnExcessBase(
            _rebalancingSetAddress,
            baseSetAddress,
            _rebalancingSetQuantity,
            _keepChangeInVault
        );

         
         
        uint256 leftoverEth = address(this).balance;
        if (leftoverEth > 0) {
            msg.sender.transfer(leftoverEth);
        }
    }

     
    function redeemRebalancingSet(
        address _rebalancingSetAddress,
        uint256 _rebalancingSetQuantity,
        bool _keepChangeInVault
    )
        external
        nonReentrant
    {
         
        validateRebalancingSetIssuance(_rebalancingSetAddress, _rebalancingSetQuantity);

         
        coreInstance.redeemModule(
            msg.sender,
            address(this),
            _rebalancingSetAddress,
            _rebalancingSetQuantity
        );

         
        address baseSetAddress = IRebalancingSetTokenV2(_rebalancingSetAddress).currentSet();
        uint256 baseSetRedeemQuantity = getBaseSetRedeemQuantity(baseSetAddress);

         
        coreInstance.withdraw(
            baseSetAddress,
            baseSetRedeemQuantity
        );

         
         
        coreInstance.redeemAndWithdrawTo(
            baseSetAddress,
            msg.sender,
            baseSetRedeemQuantity,
            0
        );

         
        returnExcessBaseSet(baseSetAddress, transferProxy, _keepChangeInVault);

         
        emit LogRebalancingSetRedeem(
            _rebalancingSetAddress,
            msg.sender,
            _rebalancingSetQuantity
        );
    }

     
    function redeemRebalancingSetUnwrappingEther(
        address _rebalancingSetAddress,
        uint256 _rebalancingSetQuantity,
        bool _keepChangeInVault
    )
        external
        nonReentrant
    {
         
        validateRebalancingSetIssuance(_rebalancingSetAddress, _rebalancingSetQuantity);

        address baseSetAddress = IRebalancingSetTokenV2(_rebalancingSetAddress).currentSet();

        validateWETHIsAComponentOfSet(baseSetAddress, address(weth));

         
        coreInstance.redeemModule(
            msg.sender,
            address(this),
            _rebalancingSetAddress,
            _rebalancingSetQuantity
        );

         
        uint256 baseSetRedeemQuantity = getBaseSetRedeemQuantity(baseSetAddress);

         
        coreInstance.withdraw(
            baseSetAddress,
            baseSetRedeemQuantity
        );

         
        coreInstance.redeem(
            baseSetAddress,
            baseSetRedeemQuantity
        );

         
        withdrawComponentsToSenderWithEther(baseSetAddress);

         
        returnExcessBaseSet(baseSetAddress, transferProxy, _keepChangeInVault);

         
        emit LogRebalancingSetRedeem(
            _rebalancingSetAddress,
            msg.sender,
            _rebalancingSetQuantity
        );
    }

     

     
    function getBaseSetAddressAndQuantity(
        address _rebalancingSetAddress,
        uint256 _rebalancingSetQuantity
    )
        internal
        view
        returns (address, uint256)
    {
         
        validateRebalancingSetIssuance(_rebalancingSetAddress, _rebalancingSetQuantity);

        address baseSetAddress = IRebalancingSetTokenV2(_rebalancingSetAddress).currentSet();

         
        uint256 requiredBaseSetQuantity = getBaseSetIssuanceRequiredQuantity(
            _rebalancingSetAddress,
            _rebalancingSetQuantity
        );

        return (baseSetAddress, requiredBaseSetQuantity);
    }

     
    function issueRebalancingSetAndReturnExcessBase(
        address _rebalancingSetAddress,
        address _baseSetAddress,
        uint256 _rebalancingSetQuantity,
        bool _keepChangeInVault
    )
        internal
    {
         
        coreInstance.issueTo(
            msg.sender,
            _rebalancingSetAddress,
            _rebalancingSetQuantity
        );

         
        returnExcessBaseSet(_baseSetAddress, transferProxy, _keepChangeInVault);

         
        emit LogRebalancingSetIssue(
            _rebalancingSetAddress,
            msg.sender,
            _rebalancingSetQuantity
        );
    }

     
    function depositComponentsAndHandleEth(
        address _baseSetAddress,
        uint256 _baseSetQuantity
    )
        private
    {
        ISetToken baseSet = ISetToken(_baseSetAddress);

        address[] memory baseSetComponents = baseSet.getComponents();
        uint256[] memory baseSetUnits = baseSet.getUnits();
        uint256 baseSetNaturalUnit = baseSet.naturalUnit();

        
        for (uint256 i = 0; i < baseSetComponents.length; i++) {
            address currentComponent = baseSetComponents[i];
            uint256 currentUnit = baseSetUnits[i];

             
            uint256 currentComponentQuantity = _baseSetQuantity.div(baseSetNaturalUnit).mul(currentUnit);

             
            if (currentComponent == address(weth)) {
                 
                require(
                    msg.value >= currentComponentQuantity,
                    "RebalancingSetIssuanceModule.depositComponentsAndHandleEth: Not enough ether included for base SetToken"
                );

                 
                weth.deposit.value(currentComponentQuantity)();

                 
                ERC20Wrapper.ensureAllowance(
                    address(weth),
                    address(this),
                    transferProxy,
                    currentComponentQuantity
                );
            } else {
                 
                coreInstance.depositModule(
                    msg.sender,
                    address(this),
                    currentComponent,
                    currentComponentQuantity
                );
            }
        }
    }

     
    function withdrawComponentsToSenderWithEther(
        address _baseSetAddress
    )
        private
    {
        address[] memory baseSetComponents = ISetToken(_baseSetAddress).getComponents();

         
        for (uint256 i = 0; i < baseSetComponents.length; i++) {
            address currentComponent = baseSetComponents[i];
            uint256 currentComponentQuantity = vaultInstance.getOwnerBalance(
                currentComponent,
                address(this)
            );

             
            if (currentComponent == address(weth)) {
                 
                coreInstance.withdrawModule(
                    address(this),
                    address(this),
                    address(weth),
                    currentComponentQuantity
                );

                 
                weth.withdraw(currentComponentQuantity);

                 
                msg.sender.transfer(currentComponentQuantity);
            } else {
                 
                coreInstance.withdrawModule(
                    address(this),
                    msg.sender,
                    currentComponent,
                    currentComponentQuantity
                );
            }
        }
    }
}
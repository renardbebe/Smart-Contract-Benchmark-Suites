 

 

 

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


library CommonValidationsLibrary {

     
    function validateNonEmpty(
        address[] calldata _addressArray
    )
        external
        pure
    {
        require(
            _addressArray.length > 0,
            "Address array length must be > 0"
        );
    }

     
    function validateEqualLength(
        address[] calldata _addressArray,
        uint256[] calldata _uint256Array
    )
        external
        pure
    {
        require(
            _addressArray.length == _uint256Array.length,
            "Input length mismatch"
        );
    }
}

 

pragma solidity ^0.5.2;

 
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

     
    function owner() public view returns (address) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

     
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

     
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

     
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
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




 
contract CoreState {

     

    struct State {
         
        uint8 operationState;

         
        address transferProxy;

         
        address vault;

         
        ITransferProxy transferProxyInstance;

         
        IVault vaultInstance;

         
        mapping(uint8 => address) exchangeIds;

         
        mapping(address => bool) validModules;

         
        mapping(address => bool) validFactories;

         
        mapping(address => bool) validPriceLibraries;

         
        mapping(address => bool) validSets;

         
        mapping(address => bool) disabledSets;

         
        address[] setTokens;

         
        address[] modules;

         
        address[] factories;

         
        address[] exchanges;

         
        address[] priceLibraries;
    }

     

    State public state;

     

     
    function operationState()
        external
        view
        returns (uint8)
    {
        return state.operationState;
    }

     
    function exchangeIds(
        uint8 _exchangeId
    )
        external
        view
        returns (address)
    {
        return state.exchangeIds[_exchangeId];
    }

     
    function transferProxy()
        external
        view
        returns (address)
    {
        return state.transferProxy;
    }

     
    function vault()
        external
        view
        returns (address)
    {
        return state.vault;
    }

     
    function validFactories(
        address _factory
    )
        external
        view
        returns (bool)
    {
        return state.validFactories[_factory];
    }

     
    function validModules(
        address _module
    )
        external
        view
        returns (bool)
    {
        return state.validModules[_module];
    }

     
    function validSets(
        address _set
    )
        external
        view
        returns (bool)
    {
        return state.validSets[_set];
    }

     
    function disabledSets(
        address _set
    )
        external
        view
        returns (bool)
    {
        return state.disabledSets[_set];
    }

     
    function validPriceLibraries(
        address _priceLibrary
    )
        external
        view
        returns (bool)
    {
        return state.validPriceLibraries[_priceLibrary];
    }

     
    function setTokens()
        external
        view
        returns (address[] memory)
    {
        return state.setTokens;
    }

     
    function modules()
        external
        view
        returns (address[] memory)
    {
        return state.modules;
    }

     
    function factories()
        external
        view
        returns (address[] memory)
    {
        return state.factories;
    }

     
    function exchanges()
        external
        view
        returns (address[] memory)
    {
        return state.exchanges;
    }

     
    function priceLibraries()
        external
        view
        returns (address[] memory)
    {
        return state.priceLibraries;
    }
}

 

 

pragma solidity 0.5.7;




 
contract CoreOperationState is
    Ownable,
    CoreState
{

     

     
    enum OperationState {
        Operational,
        ShutDown,
        InvalidState
    }

     

    event OperationStateChanged(
        uint8 _prevState,
        uint8 _newState
    );

     

    modifier whenOperational() {
        require(
            state.operationState == uint8(OperationState.Operational),
            "WhenOperational"
        );
        _;
    }

     

     
    function setOperationState(
        uint8 _operationState
    )
        external
        onlyOwner
    {
        require(
            _operationState < uint8(OperationState.InvalidState) &&
            _operationState != state.operationState,
            "InvalidOperationState"
        );

        emit OperationStateChanged(
            state.operationState,
            _operationState
        );

        state.operationState = _operationState;
    }
}

 

 

pragma solidity 0.5.7;







 
contract CoreAccounting is
    CoreState,
    CoreOperationState,
    ReentrancyGuard
{
     
    using SafeMath for uint256;

     

     
    function deposit(
        address _token,
        uint256 _quantity
    )
        external
        nonReentrant
        whenOperational
    {
         
        if (_quantity > 0) {
             
            state.transferProxyInstance.transfer(
                _token,
                _quantity,
                msg.sender,
                state.vault
            );

             
            state.vaultInstance.incrementTokenOwner(
                _token,
                msg.sender,
                _quantity
            );
        }
    }

     
    function withdraw(
        address _token,
        uint256 _quantity
    )
        external
        nonReentrant
    {
         
        if (_quantity > 0) {
             
            state.vaultInstance.decrementTokenOwner(
                _token,
                msg.sender,
                _quantity
            );

             
            state.vaultInstance.withdrawTo(
                _token,
                msg.sender,
                _quantity
            );
        }
    }

     
    function batchDeposit(
        address[] calldata _tokens,
        uint256[] calldata _quantities
    )
        external
        nonReentrant
        whenOperational
    {
         
        batchDepositInternal(
            msg.sender,
            msg.sender,
            _tokens,
            _quantities
        );
    }

     
    function batchWithdraw(
        address[] calldata _tokens,
        uint256[] calldata _quantities
    )
        external
        nonReentrant
    {
         
        batchWithdrawInternal(
            msg.sender,
            msg.sender,
            _tokens,
            _quantities
        );
    }

     
    function internalTransfer(
        address _token,
        address _to,
        uint256 _quantity
    )
        external
        nonReentrant
        whenOperational
    {
        state.vaultInstance.transferBalance(
            _token,
            msg.sender,
            _to,
            _quantity
        );
    }

     

     
    function batchDepositInternal(
        address _from,
        address _to,
        address[] memory _tokens,
        uint256[] memory _quantities
    )
        internal
        whenOperational
    {
         
        CommonValidationsLibrary.validateNonEmpty(_tokens);

         
        CommonValidationsLibrary.validateEqualLength(_tokens, _quantities);

        state.transferProxyInstance.batchTransfer(
            _tokens,
            _quantities,
            _from,
            state.vault
        );

        state.vaultInstance.batchIncrementTokenOwner(
            _tokens,
            _to,
            _quantities
        );
    }

     
    function batchWithdrawInternal(
        address _from,
        address _to,
        address[] memory _tokens,
        uint256[] memory _quantities
    )
        internal
    {
         
        CommonValidationsLibrary.validateNonEmpty(_tokens);

         
        CommonValidationsLibrary.validateEqualLength(_tokens, _quantities);

         
        state.vaultInstance.batchDecrementTokenOwner(
            _tokens,
            _from,
            _quantities
        );

         
        state.vaultInstance.batchWithdrawTo(
            _tokens,
            _to,
            _quantities
        );
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




 
contract TimeLockUpgrade is
    Ownable
{
    using SafeMath for uint256;

     

     
    uint256 public timeLockPeriod;

     
    mapping(bytes32 => uint256) public timeLockedUpgrades;

     

    event UpgradeRegistered(
        bytes32 _upgradeHash,
        uint256 _timestamp
    );

     

    modifier timeLockUpgrade() {
         
         
        if (timeLockPeriod == 0) {
            _;

            return;
        }

         
         
        bytes32 upgradeHash = keccak256(
            abi.encodePacked(
                msg.data
            )
        );

        uint256 registrationTime = timeLockedUpgrades[upgradeHash];

         
        if (registrationTime == 0) {
            timeLockedUpgrades[upgradeHash] = block.timestamp;

            emit UpgradeRegistered(
                upgradeHash,
                block.timestamp
            );

            return;
        }

        require(
            block.timestamp >= registrationTime.add(timeLockPeriod),
            "TimeLockUpgrade: Time lock period must have elapsed."
        );

         
        timeLockedUpgrades[upgradeHash] = 0;

         
        _;
    }

     

     
    function setTimeLockPeriod(
        uint256 _timeLockPeriod
    )
        external
        onlyOwner
    {
         
        require(
            _timeLockPeriod > timeLockPeriod,
            "TimeLockUpgrade: New period must be greater than existing"
        );

        timeLockPeriod = _timeLockPeriod;
    }
}

 

 

pragma solidity 0.5.7;






 
contract CoreAdmin is
    Ownable,
    CoreState,
    TimeLockUpgrade
{
    using AddressArrayUtils for address[];

     

    event FactoryAdded(
        address _factory
    );

    event FactoryRemoved(
        address _factory
    );

    event ExchangeAdded(
        uint8 _exchangeId,
        address _exchange
    );

    event ExchangeRemoved(
        uint8 _exchangeId
    );

    event ModuleAdded(
        address _module
    );

    event ModuleRemoved(
        address _module
    );

    event SetDisabled(
        address _set
    );

    event SetReenabled(
        address _set
    );

    event PriceLibraryAdded(
        address _priceLibrary
    );

    event PriceLibraryRemoved(
        address _priceLibrary
    );

     

     
    function addFactory(
        address _factory
    )
        external
        onlyOwner
        timeLockUpgrade
    {
        require(
            !state.validFactories[_factory]
        );

        state.validFactories[_factory] = true;

        state.factories = state.factories.append(_factory);

        emit FactoryAdded(
            _factory
        );
    }

     
    function removeFactory(
        address _factory
    )
        external
        onlyOwner
    {
        require(
            state.validFactories[_factory]
        );

        state.factories = state.factories.remove(_factory);

        state.validFactories[_factory] = false;

        emit FactoryRemoved(
            _factory
        );
    }

     
    function addExchange(
        uint8 _exchangeId,
        address _exchange
    )
        external
        onlyOwner
        timeLockUpgrade
    {
        require(
            state.exchangeIds[_exchangeId] == address(0)
        );

        state.exchangeIds[_exchangeId] = _exchange;

        state.exchanges = state.exchanges.append(_exchange);

        emit ExchangeAdded(
            _exchangeId,
            _exchange
        );
    }

     
    function removeExchange(
        uint8 _exchangeId,
        address _exchange
    )
        external
        onlyOwner
    {
        require(
            state.exchangeIds[_exchangeId] != address(0) &&
            state.exchangeIds[_exchangeId] == _exchange
        );

        state.exchanges = state.exchanges.remove(_exchange);

        state.exchangeIds[_exchangeId] = address(0);

        emit ExchangeRemoved(
            _exchangeId
        );
    }

     
    function addModule(
        address _module
    )
        external
        onlyOwner
        timeLockUpgrade
    {
        require(
            !state.validModules[_module]
        );

        state.validModules[_module] = true;

        state.modules = state.modules.append(_module);

        emit ModuleAdded(
            _module
        );
    }

     
    function removeModule(
        address _module
    )
        external
        onlyOwner
    {
        require(
            state.validModules[_module]
        );

        state.modules = state.modules.remove(_module);

        state.validModules[_module] = false;

        emit ModuleRemoved(
            _module
        );
    }

     
    function disableSet(
        address _set
    )
        external
        onlyOwner
    {
        require(
            state.validSets[_set]
        );

        state.setTokens = state.setTokens.remove(_set);

        state.validSets[_set] = false;

        state.disabledSets[_set] = true;

        emit SetDisabled(
            _set
        );
    }

     
    function reenableSet(
        address _set
    )
        external
        onlyOwner
    {
        require(
            state.disabledSets[_set]
        );

        state.setTokens = state.setTokens.append(_set);

        state.validSets[_set] = true;

        state.disabledSets[_set] = false;

        emit SetReenabled(
            _set
        );
    }

     
    function addPriceLibrary(
        address _priceLibrary
    )
        external
        onlyOwner
        timeLockUpgrade
    {
        require(
            !state.validPriceLibraries[_priceLibrary]
        );

        state.validPriceLibraries[_priceLibrary] = true;

        state.priceLibraries = state.priceLibraries.append(_priceLibrary);

        emit PriceLibraryAdded(
            _priceLibrary
        );
    }

     
    function removePriceLibrary(
        address _priceLibrary
    )
        external
        onlyOwner
    {
        require(
            state.validPriceLibraries[_priceLibrary]
        );

        state.priceLibraries = state.priceLibraries.remove(_priceLibrary);

        state.validPriceLibraries[_priceLibrary] = false;

        emit PriceLibraryRemoved(
            _priceLibrary
        );
    }
}

 

 

pragma solidity 0.5.7;


 
interface ISetFactory {

     

     
    function core()
        external
        returns (address);

     
    function createSet(
        address[] calldata _components,
        uint[] calldata _units,
        uint256 _naturalUnit,
        bytes32 _name,
        bytes32 _symbol,
        bytes calldata _callData
    )
        external
        returns (address);
}

 

 

pragma solidity 0.5.7;




 
contract CoreFactory is
    CoreState
{
     

    event SetTokenCreated(
        address indexed _setTokenAddress,
        address _factory,
        address[] _components,
        uint256[] _units,
        uint256 _naturalUnit,
        bytes32 _name,
        bytes32 _symbol
    );

     

     
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
        returns (address)
    {
         
        require(
            state.validFactories[_factory],
            "CreateSet"
        );

         
        address newSetTokenAddress = ISetFactory(_factory).createSet(
            _components,
            _units,
            _naturalUnit,
            _name,
            _symbol,
            _callData
        );

         
        state.validSets[newSetTokenAddress] = true;

         
        state.setTokens.push(newSetTokenAddress);

         
        emit SetTokenCreated(
            newSetTokenAddress,
            _factory,
            _components,
            _units,
            _naturalUnit,
            _name,
            _symbol
        );

        return newSetTokenAddress;
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





 
library CoreIssuanceLibrary {

    using SafeMath for uint256;

     
    function calculateDepositAndDecrementQuantities(
        address[] calldata _components,
        uint256[] calldata _componentQuantities,
        address _owner,
        address _vault
    )
        external
        view
        returns (
            uint256[] memory  ,
            uint256[] memory  
        )
    {
        uint256 componentCount = _components.length;
        uint256[] memory decrementTokenOwnerValues = new uint256[](componentCount);
        uint256[] memory depositQuantities = new uint256[](componentCount);

        for (uint256 i = 0; i < componentCount; i++) {
             
            uint256 vaultBalance = IVault(_vault).getOwnerBalance(
                _components[i],
                _owner
            );

             
            if (vaultBalance >= _componentQuantities[i]) {
                decrementTokenOwnerValues[i] = _componentQuantities[i];
            } else {
                 
                if (vaultBalance > 0) {
                    decrementTokenOwnerValues[i] = vaultBalance;
                }

                depositQuantities[i] = _componentQuantities[i].sub(vaultBalance);
            }
        }

        return (
            decrementTokenOwnerValues,
            depositQuantities
        );
    }

     
    function calculateWithdrawAndIncrementQuantities(
        uint256[] calldata _componentQuantities,
        uint256 _toExclude
    )
        external
        pure
        returns (
            uint256[] memory  ,
            uint256[] memory  
        )
    {
        uint256 componentCount = _componentQuantities.length;
        uint256[] memory incrementTokenOwnerValues = new uint256[](componentCount);
        uint256[] memory withdrawToValues = new uint256[](componentCount);

         
        for (uint256 i = 0; i < componentCount; i++) {
             
            uint256 componentBitIndex = CommonMath.safePower(2, i);

             
            if ((_toExclude & componentBitIndex) != 0) {
                incrementTokenOwnerValues[i] = _componentQuantities[i];
            } else {
                withdrawToValues[i] = _componentQuantities[i];
            }
        }

        return (
            incrementTokenOwnerValues,
            withdrawToValues
        );
    }

     
    function calculateRequiredComponentQuantities(
        uint256[] calldata _componentUnits,
        uint256 _naturalUnit,
        uint256 _quantity
    )
        external
        pure
        returns (uint256[] memory)
    {
        require(
            _quantity.mod(_naturalUnit) == 0,
            "CoreIssuanceLibrary: Quantity must be a multiple of nat unit"
        );

        uint256[] memory tokenValues = new uint256[](_componentUnits.length);

         
        for (uint256 i = 0; i < _componentUnits.length; i++) {
            tokenValues[i] = _quantity.div(_naturalUnit).mul(_componentUnits[i]);
        }

        return tokenValues;
    }

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




library SetTokenLibrary {
    using SafeMath for uint256;

    struct SetDetails {
        uint256 naturalUnit;
        address[] components;
        uint256[] units;
    }

     
    function validateTokensAreComponents(
        address _set,
        address[] calldata _tokens
    )
        external
        view
    {
        for (uint256 i = 0; i < _tokens.length; i++) {
             
            require(
                ISetToken(_set).tokenIsComponent(_tokens[i]),
                "SetTokenLibrary.validateTokensAreComponents: Component must be a member of Set"
            );

        }
    }

     
    function isMultipleOfSetNaturalUnit(
        address _set,
        uint256 _quantity
    )
        external
        view
    {
        require(
            _quantity.mod(ISetToken(_set).naturalUnit()) == 0,
            "SetTokenLibrary.isMultipleOfSetNaturalUnit: Quantity is not a multiple of nat unit"
        );
    }

     
    function getSetDetails(
        address _set
    )
        internal
        view
        returns (SetDetails memory)
    {
         
        ISetToken setToken = ISetToken(_set);

         
        uint256 naturalUnit = setToken.naturalUnit();
        address[] memory components = setToken.getComponents();
        uint256[] memory units = setToken.getUnits();

        return SetDetails({
            naturalUnit: naturalUnit,
            components: components,
            units: units
        });
    }
}

 

 

pragma solidity 0.5.7;









 
contract CoreIssuance is
    CoreState,
    CoreOperationState,
    ReentrancyGuard
{
     
    using SafeMath for uint256;

     

    event SetIssued(
        address _setAddress,
        uint256 _quantity
    );

    event SetRedeemed(
        address _setAddress,
        uint256 _quantity
    );

     

     
    function issue(
        address _set,
        uint256 _quantity
    )
        external
        nonReentrant
    {
        issueInternal(
            msg.sender,
            msg.sender,
            _set,
            _quantity
        );
    }

     
    function issueInVault(
        address _set,
        uint256 _quantity
    )
        external
        nonReentrant
    {
        issueInVaultInternal(
            msg.sender,
            _set,
            _quantity
        );
    }

     
    function issueTo(
        address _recipient,
        address _set,
        uint256 _quantity
    )
        external
        nonReentrant
    {
        issueInternal(
            msg.sender,
            _recipient,
            _set,
            _quantity
        );
    }

     
    function redeem(
        address _set,
        uint256 _quantity
    )
        external
        nonReentrant
    {
        redeemInternal(
            msg.sender,
            msg.sender,
            _set,
            _quantity
        );
    }

     
    function redeemAndWithdrawTo(
        address _set,
        address _to,
        uint256 _quantity,
        uint256 _toExclude
    )
        external
        nonReentrant
    {
        uint256[] memory componentTransferValues = redeemAndDecrementVault(
            _set,
            msg.sender,
            _quantity
        );

         
        uint256[] memory incrementTokenOwnerValues;
        uint256[] memory withdrawToValues;
        (
            incrementTokenOwnerValues,
            withdrawToValues
        ) = CoreIssuanceLibrary.calculateWithdrawAndIncrementQuantities(
            componentTransferValues,
            _toExclude
        );

        address[] memory components = ISetToken(_set).getComponents();

         
        state.vaultInstance.batchIncrementTokenOwner(
            components,
            _to,
            incrementTokenOwnerValues
        );

         
        state.vaultInstance.batchWithdrawTo(
            components,
            _to,
            withdrawToValues
        );
    }

     
    function redeemInVault(
        address _set,
        uint256 _quantity
    )
        external
        nonReentrant
    {
         
        state.vaultInstance.decrementTokenOwner(
            _set,
            msg.sender,
            _quantity
        );

        redeemInternal(
            state.vault,
            msg.sender,
            _set,
            _quantity
        );
    }

     
    function redeemTo(
        address _recipient,
        address _set,
        uint256 _quantity
    )
        external
        nonReentrant
    {
        redeemInternal(
            msg.sender,
            _recipient,
            _set,
            _quantity
        );
    }

     

     
    function issueInternal(
        address _componentOwner,
        address _setRecipient,
        address _set,
        uint256 _quantity
    )
        internal
        whenOperational
    {
         
        require(
            state.validSets[_set],
            "IssueInternal"
        );

         
        SetTokenLibrary.isMultipleOfSetNaturalUnit(_set, _quantity);

        SetTokenLibrary.SetDetails memory setToken = SetTokenLibrary.getSetDetails(_set);

         
        uint256[] memory requiredComponentQuantities = CoreIssuanceLibrary.calculateRequiredComponentQuantities(
            setToken.units,
            setToken.naturalUnit,
            _quantity
        );

         
        uint256[] memory decrementTokenOwnerValues;
        uint256[] memory depositValues;
        (
            decrementTokenOwnerValues,
            depositValues
        ) = CoreIssuanceLibrary.calculateDepositAndDecrementQuantities(
            setToken.components,
            requiredComponentQuantities,
            _componentOwner,
            state.vault
        );

         
        state.vaultInstance.batchDecrementTokenOwner(
            setToken.components,
            _componentOwner,
            decrementTokenOwnerValues
        );

         
        state.transferProxyInstance.batchTransfer(
            setToken.components,
            depositValues,
            _componentOwner,
            state.vault
        );

         
        state.vaultInstance.batchIncrementTokenOwner(
            setToken.components,
            _set,
            requiredComponentQuantities
        );

         
        ISetToken(_set).mint(
            _setRecipient,
            _quantity
        );

        emit SetIssued(
            _set,
            _quantity
        );
    }

     
    function issueInVaultInternal(
        address _recipient,
        address _set,
        uint256 _quantity
    )
        internal
    {
        issueInternal(
            _recipient,
            state.vault,
            _set,
            _quantity
        );

         
        state.vaultInstance.incrementTokenOwner(
            _set,
            _recipient,
            _quantity
        );
    }

     
    function redeemInternal(
        address _burnAddress,
        address _incrementAddress,
        address _set,
        uint256 _quantity
    )
        internal
    {
        uint256[] memory componentQuantities = redeemAndDecrementVault(
            _set,
            _burnAddress,
            _quantity
        );

         
        address[] memory components = ISetToken(_set).getComponents();
        state.vaultInstance.batchIncrementTokenOwner(
            components,
            _incrementAddress,
            componentQuantities
        );
    }

    
    function redeemAndDecrementVault(
        address _set,
        address _burnAddress,
        uint256 _quantity
    )
        private
        returns (uint256[] memory)
    {
         
        require(
            state.validSets[_set],
            "RedeemAndDecrementVault"
        );

         
        SetTokenLibrary.isMultipleOfSetNaturalUnit(_set, _quantity);

         
        ISetToken(_set).burn(
            _burnAddress,
            _quantity
        );

        SetTokenLibrary.SetDetails memory setToken = SetTokenLibrary.getSetDetails(_set);

         
        uint256[] memory componentQuantities = CoreIssuanceLibrary.calculateRequiredComponentQuantities(
            setToken.units,
            setToken.naturalUnit,
            _quantity
        );

         
        state.vaultInstance.batchDecrementTokenOwner(
            setToken.components,
            _set,
            componentQuantities
        );

        emit SetRedeemed(
            _set,
            _quantity
        );

        return componentQuantities;
    }
}

 

 

pragma solidity 0.5.7;


 
contract ICoreAccounting {

     

     
    function batchDepositInternal(
        address _from,
        address _to,
        address[] memory _tokens,
        uint[] memory _quantities
    )
        internal;

     
    function batchWithdrawInternal(
        address _from,
        address _to,
        address[] memory _tokens,
        uint256[] memory _quantities
    )
        internal;
}

 

 

pragma solidity 0.5.7;


 
contract ICoreIssuance {

     

     
    function issueInternal(
        address _owner,
        address _recipient,
        address _set,
        uint256 _quantity
    )
        internal;

     
    function issueInVaultInternal(
        address _recipient,
        address _set,
        uint256 _quantity
    )
        internal;

     
    function redeemInternal(
        address _burnAddress,
        address _incrementAddress,
        address _set,
        uint256 _quantity
    )
        internal;
}

 

 

pragma solidity 0.5.7;






 
contract CoreModuleInteraction is
    ICoreAccounting,
    ICoreIssuance,
    CoreState,
    ReentrancyGuard
{
    modifier onlyModule() {
        onlyModuleCallable();
        _;
    }

    function onlyModuleCallable() internal view {
        require(
            state.validModules[msg.sender],
            "OnlyModule"
        );
    }

     
    function depositModule(
        address _from,
        address _to,
        address _token,
        uint256 _quantity
    )
        external
        onlyModule
    {
        address[] memory tokenArray = new address[](1);
        tokenArray[0] = _token;

        uint256[] memory quantityArray = new uint256[](1);
        quantityArray[0] = _quantity;

        batchDepositInternal(
            _from,
            _to,
            tokenArray,
            quantityArray
        );
    }

     
    function batchDepositModule(
        address _from,
        address _to,
        address[] calldata _tokens,
        uint256[] calldata _quantities
    )
        external
        onlyModule
    {
        batchDepositInternal(
            _from,
            _to,
            _tokens,
            _quantities
        );
    }

     
    function withdrawModule(
        address _from,
        address _to,
        address _token,
        uint256 _quantity
    )
        external
        onlyModule
    {
        address[] memory tokenArray = new address[](1);
        tokenArray[0] = _token;

        uint256[] memory quantityArray = new uint256[](1);
        quantityArray[0] = _quantity;

        batchWithdrawInternal(
            _from,
            _to,
            tokenArray,
            quantityArray
        );
    }

     
    function batchWithdrawModule(
        address _from,
        address _to,
        address[] calldata _tokens,
        uint256[] calldata _quantities
    )
        external
        onlyModule
    {
        batchWithdrawInternal(
            _from,
            _to,
            _tokens,
            _quantities
        );
    }

     
    function issueModule(
        address _componentOwner,
        address _setRecipient,
        address _set,
        uint256 _quantity
    )
        external
        onlyModule
    {
        issueInternal(
            _componentOwner,
            _setRecipient,
            _set,
            _quantity
        );
    }

     
    function issueInVaultModule(
        address _recipient,
        address _set,
        uint256 _quantity
    )
        external
        onlyModule
    {
        issueInVaultInternal(
            _recipient,
            _set,
            _quantity
        );
    }

     
    function redeemModule(
        address _burnAddress,
        address _incrementAddress,
        address _set,
        uint256 _quantity
    )
        external
        onlyModule
    {
        redeemInternal(
            _burnAddress,
            _incrementAddress,
            _set,
            _quantity
        );
    }

     
    function batchIncrementTokenOwnerModule(
        address[] calldata _tokens,
        address _owner,
        uint256[] calldata _quantities
    )
        external
        onlyModule
    {
        state.vaultInstance.batchIncrementTokenOwner(
            _tokens,
            _owner,
            _quantities
        );
    }

     
    function batchDecrementTokenOwnerModule(
        address[] calldata _tokens,
        address _owner,
        uint256[] calldata _quantities
    )
        external
        onlyModule
    {
        state.vaultInstance.batchDecrementTokenOwner(
            _tokens,
            _owner,
            _quantities
        );
    }

     
    function batchTransferBalanceModule(
        address[] calldata _tokens,
        address _from,
        address _to,
        uint256[] calldata _quantities
    )
        external
        onlyModule
    {
        state.vaultInstance.batchTransferBalance(
            _tokens,
            _from,
            _to,
            _quantities
        );
    }

     
    function transferModule(
        address _token,
        uint256 _quantity,
        address _from,
        address _to
    )
        external
        onlyModule
    {
        state.transferProxyInstance.transfer(
            _token,
            _quantity,
            _from,
            _to
        );
    }

     
    function batchTransferModule(
        address[] calldata _tokens,
        uint256[] calldata _quantities,
        address _from,
        address _to
    )
        external
        onlyModule
    {
        state.transferProxyInstance.batchTransfer(
            _tokens,
            _quantities,
            _from,
            _to
        );
    }
}

 

 

pragma solidity 0.5.7;









 
  
contract Core is
    CoreAccounting,
    CoreAdmin,
    CoreFactory,
    CoreIssuance,
    CoreModuleInteraction
{
     
    constructor(
        address _transferProxy,
        address _vault
    )
        public
    {
         
        state.transferProxy = _transferProxy;

         
        state.transferProxyInstance = ITransferProxy(_transferProxy);

         
        state.vault = _vault;

         
        state.vaultInstance = IVault(_vault);
    }
}
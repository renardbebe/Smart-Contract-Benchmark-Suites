 

 
contract Ownable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

     
    constructor() public {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

     
    function owner() public view returns(address) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

     
    function isOwner() public view returns(bool) {
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

interface HydroInterface {
    function balances(address) external view returns (uint);
    function allowed(address, address) external view returns (uint);
    function transfer(address _to, uint256 _amount) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _amount) external returns (bool success);
    function balanceOf(address _owner) external view returns (uint256 balance);
    function approve(address _spender, uint256 _amount) external returns (bool success);
    function approveAndCall(address _spender, uint256 _value, bytes calldata _extraData)
        external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);
    function totalSupply() external view returns (uint);

    function authenticate(uint _value, uint _challenge, uint _partnerId) external;
}

interface SnowflakeResolverInterface {
    function callOnAddition() external view returns (bool);
    function callOnRemoval() external view returns (bool);
    function onAddition(uint ein, uint allowance, bytes calldata extraData) external returns (bool);
    function onRemoval(uint ein, bytes calldata extraData) external returns (bool);
}

interface SnowflakeViaInterface {
    function snowflakeCall(address resolver, uint einFrom, uint einTo, uint amount, bytes calldata snowflakeCallBytes)
        external;
    function snowflakeCall(
        address resolver, uint einFrom, address payable to, uint amount, bytes calldata snowflakeCallBytes
    ) external;
    function snowflakeCall(address resolver, uint einTo, uint amount, bytes calldata snowflakeCallBytes) external;
    function snowflakeCall(address resolver, address payable to, uint amount, bytes calldata snowflakeCallBytes)
        external;
}

interface IdentityRegistryInterface {
    function isSigned(address _address, bytes32 messageHash, uint8 v, bytes32 r, bytes32 s)
        external pure returns (bool);

     
    function identityExists(uint ein) external view returns (bool);
    function hasIdentity(address _address) external view returns (bool);
    function getEIN(address _address) external view returns (uint ein);
    function isAssociatedAddressFor(uint ein, address _address) external view returns (bool);
    function isProviderFor(uint ein, address provider) external view returns (bool);
    function isResolverFor(uint ein, address resolver) external view returns (bool);
    function getIdentity(uint ein) external view returns (
        address recoveryAddress,
        address[] memory associatedAddresses, address[] memory providers, address[] memory resolvers
    );

     
    function createIdentity(address recoveryAddress, address[] calldata providers, address[] calldata resolvers)
        external returns (uint ein);
    function createIdentityDelegated(
        address recoveryAddress, address associatedAddress, address[] calldata providers, address[] calldata resolvers,
        uint8 v, bytes32 r, bytes32 s, uint timestamp
    ) external returns (uint ein);
    function addAssociatedAddress(
        address approvingAddress, address addressToAdd, uint8 v, bytes32 r, bytes32 s, uint timestamp
    ) external;
    function addAssociatedAddressDelegated(
        address approvingAddress, address addressToAdd,
        uint8[2] calldata v, bytes32[2] calldata r, bytes32[2] calldata s, uint[2] calldata timestamp
    ) external;
    function removeAssociatedAddress() external;
    function removeAssociatedAddressDelegated(address addressToRemove, uint8 v, bytes32 r, bytes32 s, uint timestamp)
        external;
    function addProviders(address[] calldata providers) external;
    function addProvidersFor(uint ein, address[] calldata providers) external;
    function removeProviders(address[] calldata providers) external;
    function removeProvidersFor(uint ein, address[] calldata providers) external;
    function addResolvers(address[] calldata resolvers) external;
    function addResolversFor(uint ein, address[] calldata resolvers) external;
    function removeResolvers(address[] calldata resolvers) external;
    function removeResolversFor(uint ein, address[] calldata resolvers) external;

     
    function triggerRecoveryAddressChange(address newRecoveryAddress) external;
    function triggerRecoveryAddressChangeFor(uint ein, address newRecoveryAddress) external;
    function triggerRecovery(uint ein, address newAssociatedAddress, uint8 v, bytes32 r, bytes32 s, uint timestamp)
        external;
    function triggerDestruction(
        uint ein, address[] calldata firstChunk, address[] calldata lastChunk, bool resetResolvers
    ) external;
}

interface ClientRaindropInterface {
    function hydroStakeUser() external returns (uint);
    function hydroStakeDelegatedUser() external returns (uint);

    function setSnowflakeAddress(address _snowflakeAddress) external;
    function setStakes(uint _hydroStakeUser, uint _hydroStakeDelegatedUser) external;

    function signUp(address _address, string calldata casedHydroId) external;

    function hydroIDAvailable(string calldata uncasedHydroID) external view returns (bool available);
    function hydroIDDestroyed(string calldata uncasedHydroID) external view returns (bool destroyed);
    function hydroIDActive(string calldata uncasedHydroID) external view returns (bool active);

    function getDetails(string calldata uncasedHydroID) external view
        returns (uint ein, address _address, string memory casedHydroID);
    function getDetails(uint ein) external view returns (address _address, string memory casedHydroID);
    function getDetails(address _address) external view returns (uint ein, string memory casedHydroID);
}

contract Snowflake is Ownable {
    using SafeMath for uint;

     
    mapping (uint => uint) public deposits;
     
    mapping (uint => mapping (address => uint)) public resolverAllowances;

     
    address public identityRegistryAddress;
    IdentityRegistryInterface private identityRegistry;
    address public hydroTokenAddress;
    HydroInterface private hydroToken;
    address public clientRaindropAddress;
    ClientRaindropInterface private clientRaindrop;

     
    uint public signatureTimeout = 1 days;
    mapping (uint => uint) public signatureNonce;

    constructor (address _identityRegistryAddress, address _hydroTokenAddress) public {
        setAddresses(_identityRegistryAddress, _hydroTokenAddress);
    }

     
    modifier identityExists(uint ein, bool check) {
        require(identityRegistry.identityExists(ein) == check, "The EIN does not exist.");
        _;
    }

     
    modifier ensureSignatureTimeValid(uint timestamp) {
        require(
             
            block.timestamp >= timestamp && block.timestamp < timestamp + signatureTimeout, "Timestamp is not valid."
        );
        _;
    }


     
    function setAddresses(address _identityRegistryAddress, address _hydroTokenAddress) public onlyOwner {
        identityRegistryAddress = _identityRegistryAddress;
        identityRegistry = IdentityRegistryInterface(identityRegistryAddress);

        hydroTokenAddress = _hydroTokenAddress;
        hydroToken = HydroInterface(hydroTokenAddress);
    }

    function setClientRaindropAddress(address _clientRaindropAddress) public onlyOwner {
        clientRaindropAddress = _clientRaindropAddress;
        clientRaindrop = ClientRaindropInterface(clientRaindropAddress);
    }

     
    function createIdentityDelegated(
        address recoveryAddress, address associatedAddress, address[] memory providers, string memory casedHydroId,
        uint8 v, bytes32 r, bytes32 s, uint timestamp
    )
        public returns (uint ein)
    {
        address[] memory _providers = new address[](providers.length + 1);
        _providers[0] = address(this);
        for (uint i; i < providers.length; i++) {
            _providers[i + 1] = providers[i];
        }

        uint _ein = identityRegistry.createIdentityDelegated(
            recoveryAddress, associatedAddress, _providers, new address[](0), v, r, s, timestamp
        );

        _addResolver(_ein, clientRaindropAddress, true, 0, abi.encode(associatedAddress, casedHydroId));

        return _ein;
    }

     
    function addProvidersFor(
        address approvingAddress, address[] memory providers, uint8 v, bytes32 r, bytes32 s, uint timestamp
    )
        public ensureSignatureTimeValid(timestamp)
    {
        uint ein = identityRegistry.getEIN(approvingAddress);
        require(
            identityRegistry.isSigned(
                approvingAddress,
                keccak256(
                    abi.encodePacked(
                        byte(0x19), byte(0), address(this),
                        "I authorize that these Providers be added to my Identity.",
                        ein, providers, timestamp
                    )
                ),
                v, r, s
            ),
            "Permission denied."
        );

        identityRegistry.addProvidersFor(ein, providers);
    }

     
    function removeProvidersFor(
        address approvingAddress, address[] memory providers, uint8 v, bytes32 r, bytes32 s, uint timestamp
    )
        public ensureSignatureTimeValid(timestamp)
    {
        uint ein = identityRegistry.getEIN(approvingAddress);
        require(
            identityRegistry.isSigned(
                approvingAddress,
                keccak256(
                    abi.encodePacked(
                        byte(0x19), byte(0), address(this),
                        "I authorize that these Providers be removed from my Identity.",
                        ein, providers, timestamp
                    )
                ),
                v, r, s
            ),
            "Permission denied."
        );

        identityRegistry.removeProvidersFor(ein, providers);
    }

     
    function upgradeProvidersFor(
        address approvingAddress, address[] memory newProviders, address[] memory oldProviders,
        uint8[2] memory v, bytes32[2] memory r, bytes32[2] memory s, uint[2] memory timestamp
    )
        public
    {
        addProvidersFor(approvingAddress, newProviders, v[0], r[0], s[0], timestamp[0]);
        removeProvidersFor(approvingAddress, oldProviders, v[1], r[1], s[1], timestamp[1]);
        uint ein = identityRegistry.getEIN(approvingAddress);
        emit SnowflakeProvidersUpgraded(ein, newProviders, oldProviders, approvingAddress);
    }

     
    function addResolver(address resolver, bool isSnowflake, uint withdrawAllowance, bytes memory extraData) public {
        _addResolver(identityRegistry.getEIN(msg.sender), resolver, isSnowflake, withdrawAllowance, extraData);
    }

     
    function addResolverAsProvider(
        uint ein, address resolver, bool isSnowflake, uint withdrawAllowance, bytes memory extraData
    )
        public
    {
        require(identityRegistry.isProviderFor(ein, msg.sender), "The msg.sender is not a Provider for the passed EIN");
        _addResolver(ein, resolver, isSnowflake, withdrawAllowance, extraData);
    }

     
    function addResolverFor(
        address approvingAddress, address resolver, bool isSnowflake, uint withdrawAllowance, bytes memory extraData,
        uint8 v, bytes32 r, bytes32 s, uint timestamp
    )
        public
    {
        uint ein = identityRegistry.getEIN(approvingAddress);

        validateAddResolverForSignature(
            approvingAddress, ein, resolver, isSnowflake, withdrawAllowance, extraData, v, r, s, timestamp
        );

        _addResolver(ein, resolver, isSnowflake, withdrawAllowance, extraData);
    }

    function validateAddResolverForSignature(
        address approvingAddress, uint ein,
        address resolver, bool isSnowflake, uint withdrawAllowance, bytes memory extraData,
        uint8 v, bytes32 r, bytes32 s, uint timestamp
    )
        private view ensureSignatureTimeValid(timestamp)
    {
        require(
            identityRegistry.isSigned(
                approvingAddress,
                keccak256(
                    abi.encodePacked(
                        byte(0x19), byte(0), address(this),
                        "I authorize that this resolver be added to my Identity.",
                        ein, resolver, isSnowflake, withdrawAllowance, extraData, timestamp
                    )
                ),
                v, r, s
            ),
            "Permission denied."
        );
    }

     
    function _addResolver(uint ein, address resolver, bool isSnowflake, uint withdrawAllowance, bytes memory extraData)
        private
    {
        require(!identityRegistry.isResolverFor(ein, resolver), "Identity has already set this resolver.");

        address[] memory resolvers = new address[](1);
        resolvers[0] = resolver;
        identityRegistry.addResolversFor(ein, resolvers);

        if (isSnowflake) {
            resolverAllowances[ein][resolver] = withdrawAllowance;
            SnowflakeResolverInterface snowflakeResolver = SnowflakeResolverInterface(resolver);
            if (snowflakeResolver.callOnAddition())
                require(snowflakeResolver.onAddition(ein, withdrawAllowance, extraData), "Sign up failure.");
            emit SnowflakeResolverAdded(ein, resolver, withdrawAllowance);
        }
    }

     
    function changeResolverAllowances(address[] memory resolvers, uint[] memory withdrawAllowances) public {
        changeResolverAllowances(identityRegistry.getEIN(msg.sender), resolvers, withdrawAllowances);
    }

     
    function changeResolverAllowancesDelegated(
        address approvingAddress, address[] memory resolvers, uint[] memory withdrawAllowances,
        uint8 v, bytes32 r, bytes32 s
    )
        public
    {
        uint ein = identityRegistry.getEIN(approvingAddress);

        uint nonce = signatureNonce[ein]++;
        require(
            identityRegistry.isSigned(
                approvingAddress,
                keccak256(
                    abi.encodePacked(
                        byte(0x19), byte(0), address(this),
                        "I authorize this change in Resolver allowances.",
                        ein, resolvers, withdrawAllowances, nonce
                    )
                ),
                v, r, s
            ),
            "Permission denied."
        );

        changeResolverAllowances(ein, resolvers, withdrawAllowances);
    }

     
    function changeResolverAllowances(uint ein, address[] memory resolvers, uint[] memory withdrawAllowances) private {
        require(resolvers.length == withdrawAllowances.length, "Malformed inputs.");

        for (uint i; i < resolvers.length; i++) {
            require(identityRegistry.isResolverFor(ein, resolvers[i]), "Identity has not set this resolver.");
            resolverAllowances[ein][resolvers[i]] = withdrawAllowances[i];
            emit SnowflakeResolverAllowanceChanged(ein, resolvers[i], withdrawAllowances[i]);
        }
    }

     
    function removeResolver(address resolver, bool isSnowflake, bytes memory extraData) public {
        removeResolver(identityRegistry.getEIN(msg.sender), resolver, isSnowflake, extraData);
    }

     
    function removeResolverFor(
        address approvingAddress, address resolver, bool isSnowflake, bytes memory extraData,
        uint8 v, bytes32 r, bytes32 s, uint timestamp
    )
        public ensureSignatureTimeValid(timestamp)
    {
        uint ein = identityRegistry.getEIN(approvingAddress);

        validateRemoveResolverForSignature(approvingAddress, ein, resolver, isSnowflake, extraData, v, r, s, timestamp);

        removeResolver(ein, resolver, isSnowflake, extraData);
    }

    function validateRemoveResolverForSignature(
        address approvingAddress, uint ein, address resolver, bool isSnowflake, bytes memory extraData,
        uint8 v, bytes32 r, bytes32 s, uint timestamp
    )
        private view
    {
        require(
            identityRegistry.isSigned(
                approvingAddress,
                keccak256(
                    abi.encodePacked(
                        byte(0x19), byte(0), address(this),
                        "I authorize that these Resolvers be removed from my Identity.",
                        ein, resolver, isSnowflake, extraData, timestamp
                    )
                ),
                v, r, s
            ),
            "Permission denied."
        );
    }

     
    function removeResolver(uint ein, address resolver, bool isSnowflake, bytes memory extraData) private {
        require(identityRegistry.isResolverFor(ein, resolver), "Identity has not yet set this resolver.");
    
        delete resolverAllowances[ein][resolver];
    
        if (isSnowflake) {
            SnowflakeResolverInterface snowflakeResolver = SnowflakeResolverInterface(resolver);
            if (snowflakeResolver.callOnRemoval())
                require(snowflakeResolver.onRemoval(ein, extraData), "Removal failure.");
            emit SnowflakeResolverRemoved(ein, resolver);
        }

        address[] memory resolvers = new address[](1);
        resolvers[0] = resolver;
        identityRegistry.removeResolversFor(ein, resolvers);
    }

    function triggerRecoveryAddressChangeFor(
        address approvingAddress, address newRecoveryAddress, uint8 v, bytes32 r, bytes32 s
    )
        public
    {
        uint ein = identityRegistry.getEIN(approvingAddress);
        uint nonce = signatureNonce[ein]++;
        require(
            identityRegistry.isSigned(
                approvingAddress,
                keccak256(
                    abi.encodePacked(
                        byte(0x19), byte(0), address(this),
                        "I authorize this change of Recovery Address.",
                        ein, newRecoveryAddress, nonce
                    )
                ),
                v, r, s
            ),
            "Permission denied."
        );

        identityRegistry.triggerRecoveryAddressChangeFor(ein, newRecoveryAddress);
    }

     
    function receiveApproval(address sender, uint amount, address _tokenAddress, bytes memory _bytes) public {
        require(msg.sender == _tokenAddress, "Malformed inputs.");
        require(_tokenAddress == hydroTokenAddress, "Sender is not the HYDRO token smart contract.");

         
        if (_bytes.length <= 32) {
            require(hydroToken.transferFrom(sender, address(this), amount), "Unable to transfer token ownership.");
            uint recipient;
            if (_bytes.length < 32) {
                recipient = identityRegistry.getEIN(sender);
            }
            else {
                recipient = abi.decode(_bytes, (uint));
                require(identityRegistry.identityExists(recipient), "The recipient EIN does not exist.");
            }
            deposits[recipient] = deposits[recipient].add(amount);
            emit SnowflakeDeposit(sender, recipient, amount);
        }
         
        else {
            (
                bool isTransfer, address resolver, address via, uint to, bytes memory snowflakeCallBytes
            ) = abi.decode(_bytes, (bool, address, address, uint, bytes));
            
            require(hydroToken.transferFrom(sender, via, amount), "Unable to transfer token ownership.");

            SnowflakeViaInterface viaContract = SnowflakeViaInterface(via);
            if (isTransfer) {
                viaContract.snowflakeCall(resolver, to, amount, snowflakeCallBytes);
                emit SnowflakeTransferToVia(resolver, via, to, amount);
            } else {
                address payable payableTo = address(to);
                viaContract.snowflakeCall(resolver, payableTo, amount, snowflakeCallBytes);
                emit SnowflakeWithdrawToVia(resolver, via, address(to), amount);
            }
        }
    }

     
    function transferSnowflakeBalance(uint einTo, uint amount) public {
        _transfer(identityRegistry.getEIN(msg.sender), einTo, amount);
    }

     
    function withdrawSnowflakeBalance(address to, uint amount) public {
        _withdraw(identityRegistry.getEIN(msg.sender), to, amount);
    }

     
    function transferSnowflakeBalanceFrom(uint einFrom, uint einTo, uint amount) public {
        handleAllowance(einFrom, amount);
        _transfer(einFrom, einTo, amount);
        emit SnowflakeTransferFrom(msg.sender);
    }

     
    function withdrawSnowflakeBalanceFrom(uint einFrom, address to, uint amount) public {
        handleAllowance(einFrom, amount);
        _withdraw(einFrom, to, amount);
        emit SnowflakeWithdrawFrom(msg.sender);
    }

     
    function transferSnowflakeBalanceFromVia(uint einFrom, address via, uint einTo, uint amount, bytes memory _bytes)
        public
    {
        handleAllowance(einFrom, amount);
        _withdraw(einFrom, via, amount);
        SnowflakeViaInterface viaContract = SnowflakeViaInterface(via);
        viaContract.snowflakeCall(msg.sender, einFrom, einTo, amount, _bytes);
        emit SnowflakeTransferFromVia(msg.sender, einTo);
    }

     
    function withdrawSnowflakeBalanceFromVia(
        uint einFrom, address via, address payable to, uint amount, bytes memory _bytes
    )
        public
    {
        handleAllowance(einFrom, amount);
        _withdraw(einFrom, via, amount);
        SnowflakeViaInterface viaContract = SnowflakeViaInterface(via);
        viaContract.snowflakeCall(msg.sender, einFrom, to, amount, _bytes);
        emit SnowflakeWithdrawFromVia(msg.sender, to);
    }

    function _transfer(uint einFrom, uint einTo, uint amount) private identityExists(einTo, true) returns (bool) {
        require(deposits[einFrom] >= amount, "Cannot withdraw more than the current deposit balance.");
        deposits[einFrom] = deposits[einFrom].sub(amount);
        deposits[einTo] = deposits[einTo].add(amount);

        emit SnowflakeTransfer(einFrom, einTo, amount);
    }

    function _withdraw(uint einFrom, address to, uint amount) internal {
        require(to != address(this), "Cannot transfer to the Snowflake smart contract itself.");

        require(deposits[einFrom] >= amount, "Cannot withdraw more than the current deposit balance.");
        deposits[einFrom] = deposits[einFrom].sub(amount);
        require(hydroToken.transfer(to, amount), "Transfer was unsuccessful");

        emit SnowflakeWithdraw(einFrom, to, amount);
    }

    function handleAllowance(uint einFrom, uint amount) internal {
         
        require(identityRegistry.isResolverFor(einFrom, msg.sender), "Resolver has not been set by from tokenholder.");

        if (resolverAllowances[einFrom][msg.sender] < amount) {
            emit SnowflakeInsufficientAllowance(einFrom, msg.sender, resolverAllowances[einFrom][msg.sender], amount);
            revert("Insufficient Allowance");
        }

        resolverAllowances[einFrom][msg.sender] = resolverAllowances[einFrom][msg.sender].sub(amount);
    }

     
    function allowAndCall(address destination, uint amount, bytes memory data)
        public returns (bytes memory returnData)
    {
        return allowAndCall(identityRegistry.getEIN(msg.sender), amount, destination, data);
    }

     
    function allowAndCallDelegated(
        address destination, uint amount, bytes memory data, address approvingAddress, uint8 v, bytes32 r, bytes32 s
    )
        public returns (bytes memory returnData)
    {
        uint ein = identityRegistry.getEIN(approvingAddress);
        uint nonce = signatureNonce[ein]++;
        validateAllowAndCallDelegatedSignature(approvingAddress, ein, destination, amount, data, nonce, v, r, s);

        return allowAndCall(ein, amount, destination, data);
    }

    function validateAllowAndCallDelegatedSignature(
        address approvingAddress, uint ein, address destination, uint amount, bytes memory data, uint nonce,
        uint8 v, bytes32 r, bytes32 s
    )
        private view
    {
        require(
            identityRegistry.isSigned(
                approvingAddress,
                keccak256(
                    abi.encodePacked(
                        byte(0x19), byte(0), address(this),
                        "I authorize this allow and call.", ein, destination, amount, data, nonce
                    )
                ),
                v, r, s
            ),
            "Permission denied."
        );
    }

     
    function allowAndCall(uint ein, uint amount, address destination, bytes memory data)
        private returns (bytes memory returnData)
    {
         
        require(identityRegistry.isResolverFor(ein, destination), "Destination has not been set by from tokenholder.");
        if (amount != 0) {
            resolverAllowances[ein][destination] = resolverAllowances[ein][destination].add(amount);
        }

         
        (bool success, bytes memory _returnData) = destination.call(data);
        require(success, "Call was not successful.");
        return _returnData;
    }

     
    event SnowflakeProvidersUpgraded(uint indexed ein, address[] newProviders, address[] oldProviders, address approvingAddress);

    event SnowflakeResolverAdded(uint indexed ein, address indexed resolver, uint withdrawAllowance);
    event SnowflakeResolverAllowanceChanged(uint indexed ein, address indexed resolver, uint withdrawAllowance);
    event SnowflakeResolverRemoved(uint indexed ein, address indexed resolver);

    event SnowflakeDeposit(address indexed from, uint indexed einTo, uint amount);
    event SnowflakeTransfer(uint indexed einFrom, uint indexed einTo, uint amount);
    event SnowflakeWithdraw(uint indexed einFrom, address indexed to, uint amount);

    event SnowflakeTransferFrom(address indexed resolverFrom);
    event SnowflakeWithdrawFrom(address indexed resolverFrom);
    event SnowflakeTransferFromVia(address indexed resolverFrom, uint indexed einTo);
    event SnowflakeWithdrawFromVia(address indexed resolverFrom, address indexed to);
    event SnowflakeTransferToVia(address indexed resolverFrom, address indexed via, uint indexed einTo, uint amount);
    event SnowflakeWithdrawToVia(address indexed resolverFrom, address indexed via, address indexed to, uint amount);

    event SnowflakeInsufficientAllowance(
        uint indexed ein, address indexed resolver, uint currentAllowance, uint requestedWithdraw
    );
}
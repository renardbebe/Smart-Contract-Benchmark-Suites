 

pragma solidity ^0.4.24;

contract Enum {
    enum Operation {
        Call,
        DelegateCall,
        Create
    }
}

contract EtherPaymentFallback {

     
    function ()
        external
        payable
    {

    }
}

contract Executor is EtherPaymentFallback {

    event ContractCreation(address newContract);

    function execute(address to, uint256 value, bytes data, Enum.Operation operation, uint256 txGas)
        internal
        returns (bool success)
    {
        if (operation == Enum.Operation.Call)
            success = executeCall(to, value, data, txGas);
        else if (operation == Enum.Operation.DelegateCall)
            success = executeDelegateCall(to, data, txGas);
        else {
            address newContract = executeCreate(data);
            success = newContract != 0;
            emit ContractCreation(newContract);
        }
    }

    function executeCall(address to, uint256 value, bytes data, uint256 txGas)
        internal
        returns (bool success)
    {
         
        assembly {
            success := call(txGas, to, value, add(data, 0x20), mload(data), 0, 0)
        }
    }

    function executeDelegateCall(address to, bytes data, uint256 txGas)
        internal
        returns (bool success)
    {
         
        assembly {
            success := delegatecall(txGas, to, add(data, 0x20), mload(data), 0, 0)
        }
    }

    function executeCreate(bytes data)
        internal
        returns (address newContract)
    {
         
        assembly {
            newContract := create(0, add(data, 0x20), mload(data))
        }
    }
}

contract SecuredTokenTransfer {

     
     
     
     
    function transferToken (
        address token, 
        address receiver,
        uint256 amount
    )
        internal
        returns (bool transferred)
    {
        bytes memory data = abi.encodeWithSignature("transfer(address,uint256)", receiver, amount);
         
        assembly {
            let success := call(sub(gas, 10000), token, 0, add(data, 0x20), mload(data), 0, 0)
            let ptr := mload(0x40)
            returndatacopy(ptr, 0, returndatasize)
            switch returndatasize 
            case 0 { transferred := success }
            case 0x20 { transferred := iszero(or(iszero(success), iszero(mload(ptr)))) }
            default { transferred := 0 }
        }
    }
}

contract SelfAuthorized {
    modifier authorized() {
        require(msg.sender == address(this), "Method can only be called from this contract");
        _;
    }
}

contract ModuleManager is SelfAuthorized, Executor {

    event EnabledModule(Module module);
    event DisabledModule(Module module);

    address public constant SENTINEL_MODULES = address(0x1);

    mapping (address => address) internal modules;
    
    function setupModules(address to, bytes data)
        internal
    {
        require(modules[SENTINEL_MODULES] == 0, "Modules have already been initialized");
        modules[SENTINEL_MODULES] = SENTINEL_MODULES;
        if (to != 0)
             
            require(executeDelegateCall(to, data, gasleft()), "Could not finish initialization");
    }

     
     
     
    function enableModule(Module module)
        public
        authorized
    {
         
        require(address(module) != 0 && address(module) != SENTINEL_MODULES, "Invalid module address provided");
         
        require(modules[module] == 0, "Module has already been added");
        modules[module] = modules[SENTINEL_MODULES];
        modules[SENTINEL_MODULES] = module;
        emit EnabledModule(module);
    }

     
     
     
     
    function disableModule(Module prevModule, Module module)
        public
        authorized
    {
         
        require(address(module) != 0 && address(module) != SENTINEL_MODULES, "Invalid module address provided");
        require(modules[prevModule] == address(module), "Invalid prevModule, module pair provided");
        modules[prevModule] = modules[module];
        modules[module] = 0;
        emit DisabledModule(module);
    }

     
     
     
     
     
    function execTransactionFromModule(address to, uint256 value, bytes data, Enum.Operation operation)
        public
        returns (bool success)
    {
         
        require(modules[msg.sender] != 0, "Method can only be called from an enabled module");
         
        success = execute(to, value, data, operation, gasleft());
    }

     
     
    function getModules()
        public
        view
        returns (address[])
    {
         
        uint256 moduleCount = 0;
        address currentModule = modules[SENTINEL_MODULES];
        while(currentModule != SENTINEL_MODULES) {
            currentModule = modules[currentModule];
            moduleCount ++;
        }
        address[] memory array = new address[](moduleCount);

         
        moduleCount = 0;
        currentModule = modules[SENTINEL_MODULES];
        while(currentModule != SENTINEL_MODULES) {
            array[moduleCount] = currentModule;
            currentModule = modules[currentModule];
            moduleCount ++;
        }
        return array;
    }
}

contract OwnerManager is SelfAuthorized {

    event AddedOwner(address owner);
    event RemovedOwner(address owner);
    event ChangedThreshold(uint256 threshold);

    address public constant SENTINEL_OWNERS = address(0x1);

    mapping(address => address) internal owners;
    uint256 ownerCount;
    uint256 internal threshold;

     
     
     
    function setupOwners(address[] _owners, uint256 _threshold)
        internal
    {
         
         
        require(threshold == 0, "Owners have already been setup");
         
        require(_threshold <= _owners.length, "Threshold cannot exceed owner count");
         
        require(_threshold >= 1, "Threshold needs to be greater than 0");
         
        address currentOwner = SENTINEL_OWNERS;
        for (uint256 i = 0; i < _owners.length; i++) {
             
            address owner = _owners[i];
            require(owner != 0 && owner != SENTINEL_OWNERS, "Invalid owner address provided");
             
            require(owners[owner] == 0, "Duplicate owner address provided");
            owners[currentOwner] = owner;
            currentOwner = owner;
        }
        owners[currentOwner] = SENTINEL_OWNERS;
        ownerCount = _owners.length;
        threshold = _threshold;
    }

     
     
     
     
    function addOwnerWithThreshold(address owner, uint256 _threshold)
        public
        authorized
    {
         
        require(owner != 0 && owner != SENTINEL_OWNERS, "Invalid owner address provided");
         
        require(owners[owner] == 0, "Address is already an owner");
        owners[owner] = owners[SENTINEL_OWNERS];
        owners[SENTINEL_OWNERS] = owner;
        ownerCount++;
        emit AddedOwner(owner);
         
        if (threshold != _threshold)
            changeThreshold(_threshold);
    }

     
     
     
     
     
    function removeOwner(address prevOwner, address owner, uint256 _threshold)
        public
        authorized
    {
         
        require(ownerCount - 1 >= _threshold, "New owner count needs to be larger than new threshold");
         
        require(owner != 0 && owner != SENTINEL_OWNERS, "Invalid owner address provided");
        require(owners[prevOwner] == owner, "Invalid prevOwner, owner pair provided");
        owners[prevOwner] = owners[owner];
        owners[owner] = 0;
        ownerCount--;
        emit RemovedOwner(owner);
         
        if (threshold != _threshold)
            changeThreshold(_threshold);
    }

     
     
     
     
     
    function swapOwner(address prevOwner, address oldOwner, address newOwner)
        public
        authorized
    {
         
        require(newOwner != 0 && newOwner != SENTINEL_OWNERS, "Invalid owner address provided");
         
        require(owners[newOwner] == 0, "Address is already an owner");
         
        require(oldOwner != 0 && oldOwner != SENTINEL_OWNERS, "Invalid owner address provided");
        require(owners[prevOwner] == oldOwner, "Invalid prevOwner, owner pair provided");
        owners[newOwner] = owners[oldOwner];
        owners[prevOwner] = newOwner;
        owners[oldOwner] = 0;
        emit RemovedOwner(oldOwner);
        emit AddedOwner(newOwner);
    }

     
     
     
    function changeThreshold(uint256 _threshold)
        public
        authorized
    {
         
        require(_threshold <= ownerCount, "Threshold cannot exceed owner count");
         
        require(_threshold >= 1, "Threshold needs to be greater than 0");
        threshold = _threshold;
        emit ChangedThreshold(threshold);
    }

    function getThreshold()
        public
        view
        returns (uint256)
    {
        return threshold;
    }

    function isOwner(address owner)
        public
        view
        returns (bool)
    {
        return owners[owner] != 0;
    }

     
     
    function getOwners()
        public
        view
        returns (address[])
    {
        address[] memory array = new address[](ownerCount);

         
        uint256 index = 0;
        address currentOwner = owners[SENTINEL_OWNERS];
        while(currentOwner != SENTINEL_OWNERS) {
            array[index] = currentOwner;
            currentOwner = owners[currentOwner];
            index ++;
        }
        return array;
    }
}

contract BaseSafe is ModuleManager, OwnerManager {

     
     
     
     
     
    function setupSafe(address[] _owners, uint256 _threshold, address to, bytes data)
        internal
    {
        setupOwners(_owners, _threshold);
         
        setupModules(to, data);
    }
}

contract MasterCopy is SelfAuthorized {
   
   
    address masterCopy;

   
   
    function changeMasterCopy(address _masterCopy)
        public
        authorized
    {
         
        require(_masterCopy != 0, "Invalid master copy address provided");
        masterCopy = _masterCopy;
    }
}

contract Module is MasterCopy {

    ModuleManager public manager;

    modifier authorized() {
        require(msg.sender == address(manager), "Method can only be called from manager");
        _;
    }

    function setManager()
        internal
    {
         
         
        require(address(manager) == 0, "Manager has already been set");
        manager = ModuleManager(msg.sender);
    }
}

contract SignatureDecoder {
    
     
     
     
     
    function recoverKey (
        bytes32 messageHash, 
        bytes messageSignature,
        uint256 pos
    )
        internal
        pure
        returns (address) 
    {
        uint8 v;
        bytes32 r;
        bytes32 s;
        (v, r, s) = signatureSplit(messageSignature, pos);
        return ecrecover(messageHash, v, r, s);
    }

     
     
     
    function signatureSplit(bytes signatures, uint256 pos)
        internal
        pure
        returns (uint8 v, bytes32 r, bytes32 s)
    {
         
         
         
         
        assembly {
            let signaturePos := mul(0x41, pos)
            r := mload(add(signatures, add(signaturePos, 0x20)))
            s := mload(add(signatures, add(signaturePos, 0x40)))
             
             
             
             
             
            v := and(mload(add(signatures, add(signaturePos, 0x41))), 0xff)
        }
    }
}

contract ISignatureValidator {
      
    function isValidSignature(
        bytes _data, 
        bytes _signature)
        public
        returns (bool isValid); 
}

contract GnosisSafe is MasterCopy, BaseSafe, SignatureDecoder, SecuredTokenTransfer, ISignatureValidator {

    string public constant NAME = "Gnosis Safe";
    string public constant VERSION = "0.0.2";

     
     
     
    bytes32 public constant DOMAIN_SEPARATOR_TYPEHASH = 0x035aff83d86937d35b32e04f0ddc6ff469290eef2f1b692d8a815c89404d4749;

     
     
     
    bytes32 public constant SAFE_TX_TYPEHASH = 0x14d461bc7412367e924637b363c7bf29b8f47e2f84869f4426e5633d8af47b20;

     
     
     
    bytes32 public constant SAFE_MSG_TYPEHASH = 0x60b3cbf8b4a223d68d641b3b6ddf9a298e7f33710cf3d3a9d1146b5a6150fbca;

    event ExecutionFailed(bytes32 txHash);

    uint256 public nonce;
    bytes32 public domainSeparator;
     
    mapping(bytes32 => uint256) public signedMessages;
     
    mapping(address => mapping(bytes32 => uint256)) public approvedHashes;

     
     
     
     
     
    function setup(address[] _owners, uint256 _threshold, address to, bytes data)
        public
    {
        require(domainSeparator == 0, "Domain Separator already set!");
        domainSeparator = keccak256(abi.encode(DOMAIN_SEPARATOR_TYPEHASH, this));
        setupSafe(_owners, _threshold, to, data);
    }

     
     
     
     
     
     
     
     
     
     
     
     
    function execTransaction(
        address to,
        uint256 value,
        bytes data,
        Enum.Operation operation,
        uint256 safeTxGas,
        uint256 dataGas,
        uint256 gasPrice,
        address gasToken,
        address refundReceiver,
        bytes signatures
    )
        public
        returns (bool success)
    {
        uint256 startGas = gasleft();
        bytes memory txHashData = encodeTransactionData(
            to, value, data, operation,  
            safeTxGas, dataGas, gasPrice, gasToken, refundReceiver,  
            nonce
        );
        require(checkSignatures(keccak256(txHashData), txHashData, signatures, true), "Invalid signatures provided");
         
        nonce++;
        require(gasleft() >= safeTxGas, "Not enough gas to execute safe transaction");
         
        success = execute(to, value, data, operation, safeTxGas == 0 && gasPrice == 0 ? gasleft() : safeTxGas);
        if (!success) {
            emit ExecutionFailed(keccak256(txHashData));
        }

         
        if (gasPrice > 0) {
            handlePayment(startGas, dataGas, gasPrice, gasToken, refundReceiver);
        }
    }

    function handlePayment(
        uint256 gasUsed,
        uint256 dataGas,
        uint256 gasPrice,
        address gasToken,
        address refundReceiver
    )
        private
    {
        uint256 amount = ((gasUsed - gasleft()) + dataGas) * gasPrice;
         
        address receiver = refundReceiver == address(0) ? tx.origin : refundReceiver;
        if (gasToken == address(0)) {
                 
            require(receiver.send(amount), "Could not pay gas costs with ether");
        } else {
            require(transferToken(gasToken, receiver, amount), "Could not pay gas costs with token");
        }
    }

     
    function checkSignatures(bytes32 dataHash, bytes data, bytes signatures, bool consumeHash)
        internal
        returns (bool)
    {
         
        if (signatures.length < threshold * 65) {
            return false;
        }
         
        address lastOwner = address(0);
        address currentOwner;
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 i;
        for (i = 0; i < threshold; i++) {
            (v, r, s) = signatureSplit(signatures, i);
             
            if (v == 0) {
                 
                currentOwner = address(r);
                bytes memory contractSignature;
                 
                assembly {
                     
                    contractSignature := add(add(signatures, s), 0x20)
                }
                if (!ISignatureValidator(currentOwner).isValidSignature(data, contractSignature)) {
                    return false;
                }
             
            } else if (v == 1) {
                 
                currentOwner = address(r);
                 
                if (msg.sender != currentOwner && approvedHashes[currentOwner][dataHash] == 0) {
                    return false;
                }
                 
                if (consumeHash && msg.sender != currentOwner) {
                    approvedHashes[currentOwner][dataHash] = 0;
                }
            } else {
                 
                currentOwner = ecrecover(dataHash, v, r, s);
            }
            if (currentOwner <= lastOwner || owners[currentOwner] == 0) {
                return false;
            }
            lastOwner = currentOwner;
        }
        return true;
    }

     
     
     
     
     
     
     
     
     
     
     
    function requiredTxGas(address to, uint256 value, bytes data, Enum.Operation operation)
        public
        authorized
        returns (uint256)
    {
        uint256 startGas = gasleft();
         
         
        require(execute(to, value, data, operation, gasleft()));
        uint256 requiredGas = startGas - gasleft();
         
        revert(string(abi.encodePacked(requiredGas)));
    }

     
    function approveHash(bytes32 hashToApprove)
        public
    {
        require(owners[msg.sender] != 0, "Only owners can approve a hash");
        approvedHashes[msg.sender][hashToApprove] = 1;
    }

     
    function signMessage(bytes _data)
        public
        authorized
    {
        signedMessages[getMessageHash(_data)] = 1;
    }

     
    function isValidSignature(bytes _data, bytes _signature)
        public
        returns (bool isValid)
    {
        bytes32 messageHash = getMessageHash(_data);
        if (_signature.length == 0) {
            isValid = signedMessages[messageHash] != 0;
        } else {
             
            isValid = checkSignatures(messageHash, _data, _signature, false);
        }
    }

     
     
     
    function getMessageHash(
        bytes message
    )
        public
        view
        returns (bytes32)
    {
        bytes32 safeMessageHash = keccak256(
            abi.encode(SAFE_MSG_TYPEHASH, keccak256(message))
        );
        return keccak256(
            abi.encodePacked(byte(0x19), byte(1), domainSeparator, safeMessageHash)
        );
    }

     
     
     
     
     
     
     
     
     
     
     
     
    function encodeTransactionData(
        address to,
        uint256 value,
        bytes data,
        Enum.Operation operation,
        uint256 safeTxGas,
        uint256 dataGas,
        uint256 gasPrice,
        address gasToken,
        address refundReceiver,
        uint256 _nonce
    )
        public
        view
        returns (bytes)
    {
        bytes32 safeTxHash = keccak256(
            abi.encode(SAFE_TX_TYPEHASH, to, value, keccak256(data), operation, safeTxGas, dataGas, gasPrice, gasToken, refundReceiver, _nonce)
        );
        return abi.encodePacked(byte(0x19), byte(1), domainSeparator, safeTxHash);
    }

     
     
     
     
     
     
     
     
     
     
     
     
    function getTransactionHash(
        address to,
        uint256 value,
        bytes data,
        Enum.Operation operation,
        uint256 safeTxGas,
        uint256 dataGas,
        uint256 gasPrice,
        address gasToken,
        address refundReceiver,
        uint256 _nonce
    )
        public
        view
        returns (bytes32)
    {
        return keccak256(encodeTransactionData(to, value, data, operation, safeTxGas, dataGas, gasPrice, gasToken, refundReceiver, _nonce));
    }
}
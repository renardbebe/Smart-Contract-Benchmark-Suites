 

pragma solidity 0.5.13;

contract Executor {

    event ContractCreation(address newContract);

    function execute(address to, uint256 value, bytes memory data, Enum.Operation operation, uint256 txGas)
        internal
        returns (bool success)
    {
        if (operation == Enum.Operation.Call)
            success = executeCall(to, value, data, txGas);
        else if (operation == Enum.Operation.DelegateCall)
            success = executeDelegateCall(to, data, txGas);
        else
            success = false;
    }

    function executeCall(address to, uint256 value, bytes memory data, uint256 txGas)
        internal
        returns (bool success)
    {
         
        assembly {
            success := call(txGas, to, value, add(data, 0x20), mload(data), 0, 0)
        }
    }

    function executeDelegateCall(address to, bytes memory data, uint256 txGas)
        internal
        returns (bool success)
    {
         
        assembly {
            success := delegatecall(txGas, to, add(data, 0x20), mload(data), 0, 0)
        }
    }
}

contract Enum {
    enum Operation {
        Call,
        DelegateCall
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
            mstore(0x40, add(ptr, returndatasize()))
            returndatacopy(ptr, 0, returndatasize())
            switch returndatasize()
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

contract FallbackManager is SelfAuthorized {

    event IncomingTransaction(address from, uint256 value);

     
    bytes32 internal constant FALLBACK_HANDLER_STORAGE_SLOT = 0x6c9a6c4a39284e37ed1cf53d337577d14212a4870fb976a4366c693b939918d5;

    function internalSetFallbackHandler(address handler) internal {
        bytes32 slot = FALLBACK_HANDLER_STORAGE_SLOT;
         
        assembly {
            sstore(slot, handler)
        }
    }

     
     
     
     
    function setFallbackHandler(address handler)
        public
        authorized
    {
        internalSetFallbackHandler(handler);
    }

    function ()
        external
        payable
    {
         
        if (msg.value > 0 || msg.data.length == 0) {
            emit IncomingTransaction(msg.sender, msg.value);
            return;
        }
        bytes32 slot = FALLBACK_HANDLER_STORAGE_SLOT;
        address handler;
         
        assembly {
            handler := sload(slot)
        }

        if (handler != address(0)) {
             
            assembly {
                calldatacopy(0, 0, calldatasize())
                let success := call(gas, handler, 0, 0, calldatasize(), 0, 0)
                returndatacopy(0, 0, returndatasize())
                if eq(success, 0) { revert(0, returndatasize()) }
                return(0, returndatasize())
            }
        }
    }
}

contract ModuleManager is SelfAuthorized, Executor {

    event EnabledModule(Module module);
    event DisabledModule(Module module);
    event ExecutionFromModuleSuccess(address indexed module);
    event ExecutionFromModuleFailure(address indexed module);

    address public constant SENTINEL_MODULES = address(0x1);

    mapping (address => address) internal modules;

    function setupModules(address to, bytes memory data)
        internal
    {
        require(modules[SENTINEL_MODULES] == address(0), "Modules have already been initialized");
        modules[SENTINEL_MODULES] = SENTINEL_MODULES;
        if (to != address(0))
             
            require(executeDelegateCall(to, data, gasleft()), "Could not finish initialization");
    }

     
     
     
    function enableModule(Module module)
        public
        authorized
    {
         
        require(address(module) != address(0) && address(module) != SENTINEL_MODULES, "Invalid module address provided");
         
        require(modules[address(module)] == address(0), "Module has already been added");
        modules[address(module)] = modules[SENTINEL_MODULES];
        modules[SENTINEL_MODULES] = address(module);
        emit EnabledModule(module);
    }

     
     
     
     
    function disableModule(Module prevModule, Module module)
        public
        authorized
    {
         
        require(address(module) != address(0) && address(module) != SENTINEL_MODULES, "Invalid module address provided");
        require(modules[address(prevModule)] == address(module), "Invalid prevModule, module pair provided");
        modules[address(prevModule)] = modules[address(module)];
        modules[address(module)] = address(0);
        emit DisabledModule(module);
    }

     
     
     
     
     
    function execTransactionFromModule(address to, uint256 value, bytes memory data, Enum.Operation operation)
        public
        returns (bool success)
    {
         
        require(msg.sender != SENTINEL_MODULES && modules[msg.sender] != address(0), "Method can only be called from an enabled module");
         
        success = execute(to, value, data, operation, gasleft());
        if (success) emit ExecutionFromModuleSuccess(msg.sender);
        else emit ExecutionFromModuleFailure(msg.sender);
    }

     
     
     
     
     
    function execTransactionFromModuleReturnData(address to, uint256 value, bytes memory data, Enum.Operation operation)
        public
        returns (bool success, bytes memory returnData)
    {
        success = execTransactionFromModule(to, value, data, operation);
         
        assembly {
             
            let ptr := mload(0x40)
             
             
            mstore(0x40, add(ptr, add(returndatasize(), 0x20)))
             
            mstore(ptr, returndatasize())
             
            returndatacopy(add(ptr, 0x20), 0, returndatasize())
             
            returnData := ptr
        }
    }

     
     
    function getModules()
        public
        view
        returns (address[] memory)
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

     
     
     
    function setupOwners(address[] memory _owners, uint256 _threshold)
        internal
    {
         
         
        require(threshold == 0, "Owners have already been setup");
         
        require(_threshold <= _owners.length, "Threshold cannot exceed owner count");
         
        require(_threshold >= 1, "Threshold needs to be greater than 0");
         
        address currentOwner = SENTINEL_OWNERS;
        for (uint256 i = 0; i < _owners.length; i++) {
             
            address owner = _owners[i];
            require(owner != address(0) && owner != SENTINEL_OWNERS, "Invalid owner address provided");
             
            require(owners[owner] == address(0), "Duplicate owner address provided");
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
         
        require(owner != address(0) && owner != SENTINEL_OWNERS, "Invalid owner address provided");
         
        require(owners[owner] == address(0), "Address is already an owner");
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
         
        require(owner != address(0) && owner != SENTINEL_OWNERS, "Invalid owner address provided");
        require(owners[prevOwner] == owner, "Invalid prevOwner, owner pair provided");
        owners[prevOwner] = owners[owner];
        owners[owner] = address(0);
        ownerCount--;
        emit RemovedOwner(owner);
         
        if (threshold != _threshold)
            changeThreshold(_threshold);
    }

     
     
     
     
     
    function swapOwner(address prevOwner, address oldOwner, address newOwner)
        public
        authorized
    {
         
        require(newOwner != address(0) && newOwner != SENTINEL_OWNERS, "Invalid owner address provided");
         
        require(owners[newOwner] == address(0), "Address is already an owner");
         
        require(oldOwner != address(0) && oldOwner != SENTINEL_OWNERS, "Invalid owner address provided");
        require(owners[prevOwner] == oldOwner, "Invalid prevOwner, owner pair provided");
        owners[newOwner] = owners[oldOwner];
        owners[prevOwner] = newOwner;
        owners[oldOwner] = address(0);
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
        return owner != SENTINEL_OWNERS && owners[owner] != address(0);
    }

     
     
    function getOwners()
        public
        view
        returns (address[] memory)
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

contract MasterCopy is SelfAuthorized {

    event ChangedMasterCopy(address masterCopy);

   
   
    address masterCopy;

   
   
    function changeMasterCopy(address _masterCopy)
        public
        authorized
    {
         
        require(_masterCopy != address(0), "Invalid master copy address provided");
        masterCopy = _masterCopy;
        emit ChangedMasterCopy(_masterCopy);
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
         
         
        require(address(manager) == address(0), "Manager has already been set");
        manager = ModuleManager(msg.sender);
    }
}

contract SignatureDecoder {
    
     
     
     
     
    function recoverKey (
        bytes32 messageHash,
        bytes memory messageSignature,
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

     
     
     
     
    function signatureSplit(bytes memory signatures, uint256 pos)
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

contract ISignatureValidatorConstants {
     
    bytes4 constant internal EIP1271_MAGIC_VALUE = 0x20c13b0b;
}

contract GnosisSafe
    is MasterCopy, ModuleManager, OwnerManager, SignatureDecoder, SecuredTokenTransfer, ISignatureValidatorConstants, FallbackManager {

    using SafeMath for uint256;

    string public constant NAME = "Gnosis Safe";
    string public constant VERSION = "1.1.0";

     
     
     
    bytes32 public constant DOMAIN_SEPARATOR_TYPEHASH = 0x035aff83d86937d35b32e04f0ddc6ff469290eef2f1b692d8a815c89404d4749;

     
     
     
    bytes32 public constant SAFE_TX_TYPEHASH = 0xbb8310d486368db6bd6f849402fdd73ad53d316b5a4b2644ad6efe0f941286d8;

     
     
     
    bytes32 public constant SAFE_MSG_TYPEHASH = 0x60b3cbf8b4a223d68d641b3b6ddf9a298e7f33710cf3d3a9d1146b5a6150fbca;

    event ApproveHash(
        bytes32 indexed approvedHash,
        address indexed owner
    );
    event SignMsg(
        bytes32 indexed msgHash
    );
    event ExecutionFailure(
        bytes32 txHash, uint256 payment
    );
    event ExecutionSuccess(
        bytes32 txHash, uint256 payment
    );

    uint256 public nonce;
    bytes32 public domainSeparator;
     
    mapping(bytes32 => uint256) public signedMessages;
     
    mapping(address => mapping(bytes32 => uint256)) public approvedHashes;

     
     
     
     
     
     
     
     
     
    function setup(
        address[] calldata _owners,
        uint256 _threshold,
        address to,
        bytes calldata data,
        address fallbackHandler,
        address paymentToken,
        uint256 payment,
        address payable paymentReceiver
    )
        external
    {
        require(domainSeparator == 0, "Domain Separator already set!");
        domainSeparator = keccak256(abi.encode(DOMAIN_SEPARATOR_TYPEHASH, this));
        setupOwners(_owners, _threshold);
         
        setupModules(to, data);
        if (fallbackHandler != address(0)) internalSetFallbackHandler(fallbackHandler);

        if (payment > 0) {
             
             
            handlePayment(payment, 0, 1, paymentToken, paymentReceiver);
        }
    }

     
     
     
     
     
     
     
     
     
     
     
     
    function execTransaction(
        address to,
        uint256 value,
        bytes calldata data,
        Enum.Operation operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address payable refundReceiver,
        bytes calldata signatures
    )
        external
        returns (bool success)
    {
        bytes32 txHash;
         
        {
            bytes memory txHashData = encodeTransactionData(
                to, value, data, operation,  
                safeTxGas, baseGas, gasPrice, gasToken, refundReceiver,  
                nonce
            );
             
            nonce++;
            txHash = keccak256(txHashData);
            checkSignatures(txHash, txHashData, signatures, true);
        }
        require(gasleft() >= safeTxGas, "Not enough gas to execute safe transaction");
         
        {
            uint256 gasUsed = gasleft();
             
            success = execute(to, value, data, operation, safeTxGas == 0 && gasPrice == 0 ? gasleft() : safeTxGas);
            gasUsed = gasUsed.sub(gasleft());
             
            uint256 payment = 0;
            if (gasPrice > 0) {
                payment = handlePayment(gasUsed, baseGas, gasPrice, gasToken, refundReceiver);
            }
            if (success) emit ExecutionSuccess(txHash, payment);
            else emit ExecutionFailure(txHash, payment);
        }
    }

    function handlePayment(
        uint256 gasUsed,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address payable refundReceiver
    )
        private
        returns (uint256 payment)
    {
         
        address payable receiver = refundReceiver == address(0) ? tx.origin : refundReceiver;
        if (gasToken == address(0)) {
             
            payment = gasUsed.add(baseGas).mul(gasPrice < tx.gasprice ? gasPrice : tx.gasprice);
             
            require(receiver.send(payment), "Could not pay gas costs with ether");
        } else {
            payment = gasUsed.add(baseGas).mul(gasPrice);
            require(transferToken(gasToken, receiver, payment), "Could not pay gas costs with token");
        }
    }

     
    function checkSignatures(bytes32 dataHash, bytes memory data, bytes memory signatures, bool consumeHash)
        internal
    {
         
        uint256 _threshold = threshold;
         
        require(_threshold > 0, "Threshold needs to be defined!");
         
        require(signatures.length >= _threshold.mul(65), "Signatures data too short");
         
        address lastOwner = address(0);
        address currentOwner;
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 i;
        for (i = 0; i < _threshold; i++) {
            (v, r, s) = signatureSplit(signatures, i);
             
            if (v == 0) {
                 
                currentOwner = address(uint256(r));

                 
                 
                 
                require(uint256(s) >= _threshold.mul(65), "Invalid contract signature location: inside static part");

                 
                require(uint256(s).add(32) <= signatures.length, "Invalid contract signature location: length not present");

                 
                uint256 contractSignatureLen;
                 
                assembly {
                    contractSignatureLen := mload(add(add(signatures, s), 0x20))
                }
                require(uint256(s).add(32).add(contractSignatureLen) <= signatures.length, "Invalid contract signature location: data not complete");

                 
                bytes memory contractSignature;
                 
                assembly {
                     
                    contractSignature := add(add(signatures, s), 0x20)
                }
                require(ISignatureValidator(currentOwner).isValidSignature(data, contractSignature) == EIP1271_MAGIC_VALUE, "Invalid contract signature provided");
             
            } else if (v == 1) {
                 
                currentOwner = address(uint256(r));
                 
                require(msg.sender == currentOwner || approvedHashes[currentOwner][dataHash] != 0, "Hash has not been approved");
                 
                if (consumeHash && msg.sender != currentOwner) {
                    approvedHashes[currentOwner][dataHash] = 0;
                }
            } else if (v > 30) {
                 
                currentOwner = ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", dataHash)), v - 4, r, s);
            } else {
                 
                currentOwner = ecrecover(dataHash, v, r, s);
            }
            require (
                currentOwner > lastOwner && owners[currentOwner] != address(0) && currentOwner != SENTINEL_OWNERS,
                "Invalid owner provided"
            );
            lastOwner = currentOwner;
        }
    }

     
     
     
     
     
     
     
     
     
     
     
    function requiredTxGas(address to, uint256 value, bytes calldata data, Enum.Operation operation)
        external
        authorized
        returns (uint256)
    {
        uint256 startGas = gasleft();
         
         
        require(execute(to, value, data, operation, gasleft()));
        uint256 requiredGas = startGas - gasleft();
         
        revert(string(abi.encodePacked(requiredGas)));
    }

     
    function approveHash(bytes32 hashToApprove)
        external
    {
        require(owners[msg.sender] != address(0), "Only owners can approve a hash");
        approvedHashes[msg.sender][hashToApprove] = 1;
        emit ApproveHash(hashToApprove, msg.sender);
    }

     
    function signMessage(bytes calldata _data)
        external
        authorized
    {
        bytes32 msgHash = getMessageHash(_data);
        signedMessages[msgHash] = 1;
        emit SignMsg(msgHash);
    }

     
    function isValidSignature(bytes calldata _data, bytes calldata _signature)
        external
        returns (bytes4)
    {
        bytes32 messageHash = getMessageHash(_data);
        if (_signature.length == 0) {
            require(signedMessages[messageHash] != 0, "Hash not approved");
        } else {
             
            checkSignatures(messageHash, _data, _signature, false);
        }
        return EIP1271_MAGIC_VALUE;
    }

     
     
     
    function getMessageHash(
        bytes memory message
    )
        public
        view
        returns (bytes32)
    {
        bytes32 safeMessageHash = keccak256(
            abi.encode(SAFE_MSG_TYPEHASH, keccak256(message))
        );
        return keccak256(
            abi.encodePacked(byte(0x19), byte(0x01), domainSeparator, safeMessageHash)
        );
    }

     
     
     
     
     
     
     
     
     
     
     
     
    function encodeTransactionData(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address refundReceiver,
        uint256 _nonce
    )
        public
        view
        returns (bytes memory)
    {
        bytes32 safeTxHash = keccak256(
            abi.encode(SAFE_TX_TYPEHASH, to, value, keccak256(data), operation, safeTxGas, baseGas, gasPrice, gasToken, refundReceiver, _nonce)
        );
        return abi.encodePacked(byte(0x19), byte(0x01), domainSeparator, safeTxHash);
    }

     
     
     
     
     
     
     
     
     
     
     
     
    function getTransactionHash(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address refundReceiver,
        uint256 _nonce
    )
        public
        view
        returns (bytes32)
    {
        return keccak256(encodeTransactionData(to, value, data, operation, safeTxGas, baseGas, gasPrice, gasToken, refundReceiver, _nonce));
    }
}

contract ISignatureValidator is ISignatureValidatorConstants {

     
    function isValidSignature(
        bytes memory _data,
        bytes memory _signature)
        public
        view
        returns (bytes4);
}
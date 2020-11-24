 

pragma solidity ^0.4.3;


 
contract AbstractBlobStore {

     
    function create(bytes4 flags, bytes contents) external returns (bytes20 blobId);

     
    function createWithNonce(bytes32 flagsNonce, bytes contents) external returns (bytes20 blobId);

     
    function createNewRevision(bytes20 blobId, bytes contents) external returns (uint revisionId);

     
    function updateLatestRevision(bytes20 blobId, bytes contents) external;

     
    function retractLatestRevision(bytes20 blobId) external;

     
    function restart(bytes20 blobId, bytes contents) external;

     
    function retract(bytes20 blobId) external;

     
    function transferEnable(bytes20 blobId) external;

     
    function transferDisable(bytes20 blobId) external;

     
    function transfer(bytes20 blobId, address recipient) external;

     
    function disown(bytes20 blobId) external;

     
    function setNotUpdatable(bytes20 blobId) external;

     
    function setEnforceRevisions(bytes20 blobId) external;

     
    function setNotRetractable(bytes20 blobId) external;

     
    function setNotTransferable(bytes20 blobId) external;

     
    function getContractId() external constant returns (bytes12);

     
    function getExists(bytes20 blobId) external constant returns (bool exists);

     
    function getInfo(bytes20 blobId) external constant returns (bytes4 flags, address owner, uint revisionCount, uint[] blockNumbers);

     
    function getFlags(bytes20 blobId) external constant returns (bytes4 flags);

     
    function getUpdatable(bytes20 blobId) external constant returns (bool updatable);

     
    function getEnforceRevisions(bytes20 blobId) external constant returns (bool enforceRevisions);

     
    function getRetractable(bytes20 blobId) external constant returns (bool retractable);

     
    function getTransferable(bytes20 blobId) external constant returns (bool transferable);

     
    function getOwner(bytes20 blobId) external constant returns (address owner);

     
    function getRevisionCount(bytes20 blobId) external constant returns (uint revisionCount);

     
    function getAllRevisionBlockNumbers(bytes20 blobId) external constant returns (uint[] blockNumbers);

}


 
contract BlobStoreFlags {

    bytes4 constant UPDATABLE = 0x01;            
    bytes4 constant ENFORCE_REVISIONS = 0x02;    
    bytes4 constant RETRACTABLE = 0x04;          
    bytes4 constant TRANSFERABLE = 0x08;         
    bytes4 constant ANONYMOUS = 0x10;            

}


 
contract BlobStoreRegistry {

     
    mapping (bytes12 => address) contractAddresses;

     
    event Register(bytes12 indexed contractId, address indexed contractAddress);

     
    modifier isNotRegistered(bytes12 contractId) {
        if (contractAddresses[contractId] != 0) {
            throw;
        }
        _;
    }

     
    modifier isRegistered(bytes12 contractId) {
        if (contractAddresses[contractId] == 0) {
            throw;
        }
        _;
    }

     
    function register(bytes12 contractId) external isNotRegistered(contractId) {
         
        contractAddresses[contractId] = msg.sender;
         
        Register(contractId, msg.sender);
    }

     
    function getBlobStore(bytes12 contractId) external constant isRegistered(contractId) returns (AbstractBlobStore blobStore) {
        blobStore = AbstractBlobStore(contractAddresses[contractId]);
    }

}


 
contract BlobStore is AbstractBlobStore, BlobStoreFlags {

     
    struct BlobInfo {
        bytes4 flags;                
        uint32 revisionCount;        
        uint32 blockNumber;          
        address owner;               
    }

     
    mapping (bytes20 => BlobInfo) blobInfo;

     
    mapping (bytes20 => mapping (uint => bytes32)) packedBlockNumbers;

     
    mapping (bytes20 => mapping (address => bool)) enabledTransfers;

     
    bytes12 contractId;

     
    event Store(bytes20 indexed blobId, uint indexed revisionId, bytes contents);

     
    event RetractRevision(bytes20 indexed blobId, uint revisionId);

     
    event Retract(bytes20 indexed blobId);

     
    event Transfer(bytes20 indexed blobId, address recipient);

     
    event Disown(bytes20 indexed blobId);

     
    event SetNotUpdatable(bytes20 indexed blobId);

     
    event SetEnforceRevisions(bytes20 indexed blobId);

     
    event SetNotRetractable(bytes20 indexed blobId);

     
    event SetNotTransferable(bytes20 indexed blobId);

     
    modifier exists(bytes20 blobId) {
        BlobInfo info = blobInfo[blobId];
        if (info.blockNumber == 0 || info.blockNumber == uint32(-1)) {
            throw;
        }
        _;
    }

     
    modifier isOwner(bytes20 blobId) {
        if (blobInfo[blobId].owner != msg.sender) {
            throw;
        }
        _;
    }

     
    modifier isUpdatable(bytes20 blobId) {
        if (blobInfo[blobId].flags & UPDATABLE == 0) {
            throw;
        }
        _;
    }

     
    modifier isNotEnforceRevisions(bytes20 blobId) {
        if (blobInfo[blobId].flags & ENFORCE_REVISIONS != 0) {
            throw;
        }
        _;
    }

     
    modifier isRetractable(bytes20 blobId) {
        if (blobInfo[blobId].flags & RETRACTABLE == 0) {
            throw;
        }
        _;
    }

     
    modifier isTransferable(bytes20 blobId) {
        if (blobInfo[blobId].flags & TRANSFERABLE == 0) {
            throw;
        }
        _;
    }

     
    modifier isTransferEnabled(bytes20 blobId, address recipient) {
        if (!enabledTransfers[blobId][recipient]) {
            throw;
        }
        _;
    }

     
    modifier hasAdditionalRevisions(bytes20 blobId) {
        if (blobInfo[blobId].revisionCount == 1) {
            throw;
        }
        _;
    }

     
    modifier revisionExists(bytes20 blobId, uint revisionId) {
        if (revisionId >= blobInfo[blobId].revisionCount) {
            throw;
        }
        _;
    }

     
    function BlobStore(BlobStoreRegistry registry) {
         
        contractId = bytes12(keccak256(this, block.blockhash(block.number - 1)));
         
        registry.register(contractId);
    }

     
    function create(bytes4 flags, bytes contents) external returns (bytes20 blobId) {
         
        blobId = bytes20(keccak256(msg.sender, block.blockhash(block.number - 1)));
         
        while (blobInfo[blobId].blockNumber != 0) {
            blobId = bytes20(keccak256(blobId));
        }
         
        blobInfo[blobId] = BlobInfo({
            flags: flags,
            revisionCount: 1,
            blockNumber: uint32(block.number),
            owner: (flags & ANONYMOUS != 0) ? 0 : msg.sender,
        });
         
        Store(blobId, 0, contents);
    }

     
    function createWithNonce(bytes32 flagsNonce, bytes contents) external returns (bytes20 blobId) {
         
        blobId = bytes20(keccak256(msg.sender, flagsNonce));
         
        if (blobInfo[blobId].blockNumber != 0) {
            throw;
        }
         
        blobInfo[blobId] = BlobInfo({
            flags: bytes4(flagsNonce),
            revisionCount: 1,
            blockNumber: uint32(block.number),
            owner: (bytes4(flagsNonce) & ANONYMOUS != 0) ? 0 : msg.sender,
        });
         
        Store(blobId, 0, contents);
    }

     
    function _setPackedBlockNumber(bytes20 blobId, uint offset) internal {
         
        bytes32 slot = packedBlockNumbers[blobId][offset / 8];
         
        slot &= ~bytes32(uint32(-1) * 2**((offset % 8) * 32));
         
        slot |= bytes32(uint32(block.number) * 2**((offset % 8) * 32));
         
        packedBlockNumbers[blobId][offset / 8] = slot;
    }

     
    function createNewRevision(bytes20 blobId, bytes contents) external isOwner(blobId) isUpdatable(blobId) returns (uint revisionId) {
         
        revisionId = blobInfo[blobId].revisionCount++;
         
        _setPackedBlockNumber(blobId, revisionId - 1);
         
        Store(blobId, revisionId, contents);
    }

     
    function updateLatestRevision(bytes20 blobId, bytes contents) external isOwner(blobId) isUpdatable(blobId) isNotEnforceRevisions(blobId) {
        BlobInfo info = blobInfo[blobId];
        uint revisionId = info.revisionCount - 1;
         
        if (revisionId == 0) {
            info.blockNumber = uint32(block.number);
        }
        else {
            _setPackedBlockNumber(blobId, revisionId - 1);
        }
         
        Store(blobId, revisionId, contents);
    }

     
    function retractLatestRevision(bytes20 blobId) external isOwner(blobId) isUpdatable(blobId) isNotEnforceRevisions(blobId) hasAdditionalRevisions(blobId) {
        uint revisionId = --blobInfo[blobId].revisionCount;
         
        if (revisionId % 8 == 1) {
            delete packedBlockNumbers[blobId][revisionId / 8];
        }
         
        RetractRevision(blobId, revisionId);
    }

     
    function _deleteAllPackedRevisionBlockNumbers(bytes20 blobId) internal {
         
         
        uint slotCount = (blobInfo[blobId].revisionCount + 6) / 8;
         
        for (uint i = 0; i < slotCount; i++) {
            delete packedBlockNumbers[blobId][i];
        }
    }

     
    function restart(bytes20 blobId, bytes contents) external isOwner(blobId) isUpdatable(blobId) isNotEnforceRevisions(blobId) {
         
        _deleteAllPackedRevisionBlockNumbers(blobId);
         
        BlobInfo info = blobInfo[blobId];
        info.revisionCount = 1;
        info.blockNumber = uint32(block.number);
         
        Store(blobId, 0, contents);
    }

     
    function retract(bytes20 blobId) external isOwner(blobId) isRetractable(blobId) {
         
        _deleteAllPackedRevisionBlockNumbers(blobId);
         
        blobInfo[blobId] = BlobInfo({
            flags: 0,
            revisionCount: 0,
            blockNumber: uint32(-1),
            owner: 0,
        });
         
        Retract(blobId);
    }

     
    function transferEnable(bytes20 blobId) external isTransferable(blobId) {
         
        enabledTransfers[blobId][msg.sender] = true;
    }

     
    function transferDisable(bytes20 blobId) external isTransferEnabled(blobId, msg.sender) {
         
        enabledTransfers[blobId][msg.sender] = false;
    }

     
    function transfer(bytes20 blobId, address recipient) external isOwner(blobId) isTransferable(blobId) isTransferEnabled(blobId, recipient) {
         
        blobInfo[blobId].owner = recipient;
         
        enabledTransfers[blobId][recipient] = false;
         
        Transfer(blobId, recipient);
    }

     
    function disown(bytes20 blobId) external isOwner(blobId) isTransferable(blobId) {
         
        delete blobInfo[blobId].owner;
         
        Disown(blobId);
    }

     
    function setNotUpdatable(bytes20 blobId) external isOwner(blobId) {
         
        blobInfo[blobId].flags &= ~UPDATABLE;
         
        SetNotUpdatable(blobId);
    }

     
    function setEnforceRevisions(bytes20 blobId) external isOwner(blobId) {
         
        blobInfo[blobId].flags |= ENFORCE_REVISIONS;
         
        SetEnforceRevisions(blobId);
    }

     
    function setNotRetractable(bytes20 blobId) external isOwner(blobId) {
         
        blobInfo[blobId].flags &= ~RETRACTABLE;
         
        SetNotRetractable(blobId);
    }

     
    function setNotTransferable(bytes20 blobId) external isOwner(blobId) {
         
        blobInfo[blobId].flags &= ~TRANSFERABLE;
         
        SetNotTransferable(blobId);
    }

     
    function getContractId() external constant returns (bytes12) {
        return contractId;
    }

     
    function getExists(bytes20 blobId) external constant returns (bool exists) {
        BlobInfo info = blobInfo[blobId];
        exists = info.blockNumber != 0 && info.blockNumber != uint32(-1);
    }

     
    function _getRevisionBlockNumber(bytes20 blobId, uint revisionId) internal returns (uint blockNumber) {
        if (revisionId == 0) {
            blockNumber = blobInfo[blobId].blockNumber;
        }
        else {
            bytes32 slot = packedBlockNumbers[blobId][(revisionId - 1) / 8];
            blockNumber = uint32(uint256(slot) / 2**(((revisionId - 1) % 8) * 32));
        }
    }

     
    function _getAllRevisionBlockNumbers(bytes20 blobId) internal returns (uint[] blockNumbers) {
        uint revisionCount = blobInfo[blobId].revisionCount;
        blockNumbers = new uint[](revisionCount);
        for (uint revisionId = 0; revisionId < revisionCount; revisionId++) {
            blockNumbers[revisionId] = _getRevisionBlockNumber(blobId, revisionId);
        }
    }

     
    function getInfo(bytes20 blobId) external constant exists(blobId) returns (bytes4 flags, address owner, uint revisionCount, uint[] blockNumbers) {
        BlobInfo info = blobInfo[blobId];
        flags = info.flags;
        owner = info.owner;
        revisionCount = info.revisionCount;
        blockNumbers = _getAllRevisionBlockNumbers(blobId);
    }

     
    function getFlags(bytes20 blobId) external constant exists(blobId) returns (bytes4 flags) {
        flags = blobInfo[blobId].flags;
    }

     
    function getUpdatable(bytes20 blobId) external constant exists(blobId) returns (bool updatable) {
        updatable = blobInfo[blobId].flags & UPDATABLE != 0;
    }

     
    function getEnforceRevisions(bytes20 blobId) external constant exists(blobId) returns (bool enforceRevisions) {
        enforceRevisions = blobInfo[blobId].flags & ENFORCE_REVISIONS != 0;
    }

     
    function getRetractable(bytes20 blobId) external constant exists(blobId) returns (bool retractable) {
        retractable = blobInfo[blobId].flags & RETRACTABLE != 0;
    }

     
    function getTransferable(bytes20 blobId) external constant exists(blobId) returns (bool transferable) {
        transferable = blobInfo[blobId].flags & TRANSFERABLE != 0;
    }

     
    function getOwner(bytes20 blobId) external constant exists(blobId) returns (address owner) {
        owner = blobInfo[blobId].owner;
    }

     
    function getRevisionCount(bytes20 blobId) external constant exists(blobId) returns (uint revisionCount) {
        revisionCount = blobInfo[blobId].revisionCount;
    }

     
    function getRevisionBlockNumber(bytes20 blobId, uint revisionId) external constant revisionExists(blobId, revisionId) returns (uint blockNumber) {
        blockNumber = _getRevisionBlockNumber(blobId, revisionId);
    }

     
    function getAllRevisionBlockNumbers(bytes20 blobId) external constant exists(blobId) returns (uint[] blockNumbers) {
        blockNumbers = _getAllRevisionBlockNumbers(blobId);
    }

}
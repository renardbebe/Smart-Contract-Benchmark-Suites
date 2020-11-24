 

pragma solidity ^0.5.11;

 
contract Context {
     
     
    constructor () internal { }
     

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this;  
        return msg.data;
    }
}

 
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

     
    function owner() public view returns (address) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

     
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

     
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

     
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

 
contract DocumentStore is Ownable {
    string public name;
    string public version = "2.3.0";

     
    mapping(bytes32 => uint256) documentIssued;
     
    mapping(bytes32 => uint256) documentRevoked;

    event DocumentIssued(bytes32 indexed document);
    event DocumentRevoked(bytes32 indexed document);

    constructor(string memory _name) public {
        name = _name;
    }

    function issue(bytes32 document) public onlyOwner onlyNotIssued(document) {
        documentIssued[document] = block.number;
        emit DocumentIssued(document);
    }

    function bulkIssue(bytes32[] memory documents) public {
        for (uint256 i = 0; i < documents.length; i++) {
            issue(documents[i]);
        }
    }

    function getIssuedBlock(bytes32 document)
        public
        view
        onlyIssued(document)
        returns (uint256)
    {
        return documentIssued[document];
    }

    function isIssued(bytes32 document) public view returns (bool) {
        return (documentIssued[document] != 0);
    }

    function isIssuedBefore(bytes32 document, uint256 blockNumber)
        public
        view
        returns (bool)
    {
        return
            documentIssued[document] != 0 && documentIssued[document] <= blockNumber;
    }

    function revoke(bytes32 document)
        public
        onlyOwner
        onlyNotRevoked(document)
        returns (bool)
    {
        documentRevoked[document] = block.number;
        emit DocumentRevoked(document);
    }

    function bulkRevoke(bytes32[] memory documents) public {
        for (uint256 i = 0; i < documents.length; i++) {
            revoke(documents[i]);
        }
    }

    function isRevoked(bytes32 document) public view returns (bool) {
        return documentRevoked[document] != 0;
    }

    function isRevokedBefore(bytes32 document, uint256 blockNumber)
        public
        view
        returns (bool)
    {
        return
            documentRevoked[document] <= blockNumber && documentRevoked[document] != 0;
    }

    modifier onlyIssued(bytes32 document) {
        require(
            isIssued(document),
            "Error: Only issued document hashes can be revoked"
        );
        _;
    }

    modifier onlyNotIssued(bytes32 document) {
        require(
            !isIssued(document),
            "Error: Only hashes that have not been issued can be issued"
        );
        _;
    }

    modifier onlyNotRevoked(bytes32 claim) {
        require(!isRevoked(claim), "Error: Hash has been revoked previously");
        _;
    }
}

 
contract DocumentMultiSigWalletCertStore {
     
    event Issued(address msgSender, address otherSigner, bytes32 operation, bytes32 hash);
    
    event BulkIssue(address msgSender, address otherSigner, bytes32 operation, bytes32[] hashes);
        
    event Revoked(address msgSender, address otherSigner, bytes32 operation, bytes32 hash);
    
    event BulkRevoke(address msgSender, address otherSigner, bytes32 operation, bytes32[] hashes);
        
    event Transferred(address msgSender, address otherSigner, address newOwner);
    
    event Change(address msgSender, address otherSigner, address newStore);

     
    address[] public signers;  
    DocumentStore public documentStore;  
    
     
    constructor(address[] memory _signers, string memory _name) public {
        if (_signers.length != 3) {
             
            revert();
        }
        signers = _signers;
        
        documentStore = new DocumentStore(_name);
    }

     
    uint constant SEQUENCE_ID_WINDOW_SIZE = 10;
    uint[10] recentSequenceIds;

     
    function isSigner(address signer) public view returns (bool) {
         
        for (uint i = 0; i < signers.length; i++) {
            if (signers[i] == signer) {
                return true;  
            }
        }
        return false;  
    }

     
    modifier onlySigner {
        if (!isSigner(msg.sender)) {
            revert();  
        }
        _;
    }
    
     
    modifier onlyCustodian {
        if (!(msg.sender == signers[2])) {
            revert();  
        }
        _;
    }
    
     
    modifier onlyBackup {
        if (!(msg.sender == signers[1])) {
            revert();  
        }
        _;
    }
    
     
    modifier onlyInitiators {
        if ((msg.sender != signers[1]) && (msg.sender != signers[2])) {
            revert();  
        }
        _;
    }

     
    function() external {
        revert();  
    }
    
     
    function issueMultiSig(
        bytes32 hash,
        uint expireTime,
        uint sequenceId,
        bytes memory signature
        ) public onlyCustodian {
            bytes32 operationHash = keccak256(abi.encodePacked("ISSUE", hash, expireTime, sequenceId));
            
            address otherSigner = verifyMultiSig(operationHash, signature, expireTime, sequenceId);
            
            documentStore.issue(hash);
            
            emit Issued(msg.sender, otherSigner, operationHash, hash);
        }
        
     
    function bulkIssueMultiSig(
        bytes32[] memory hashes,
        uint expireTime,
        uint sequenceId,
        bytes memory signature
        ) public onlyCustodian {
            bytes32 operationHash = keccak256(abi.encodePacked("BULKISSUE", hashes, expireTime, sequenceId));
            
            address otherSigner = verifyMultiSig(operationHash, signature, expireTime, sequenceId);
            
            documentStore.bulkIssue(hashes);
            
            emit BulkIssue(msg.sender, otherSigner, operationHash, hashes);
        }
        
     
    function revokeMultiSig(
        bytes32 hash,
        uint expireTime,
        uint sequenceId,
        bytes memory signature
        ) public onlyCustodian {
            bytes32 operationHash = keccak256(abi.encodePacked("REVOKE", hash, expireTime, sequenceId));
            
            address otherSigner = verifyMultiSig(operationHash, signature, expireTime, sequenceId);
            
            documentStore.revoke(hash);
            
            emit Revoked(msg.sender, otherSigner, operationHash, hash);
        }
        
      
    function bulkRevokeMultiSig(
        bytes32[] memory hashes,
        uint expireTime,
        uint sequenceId,
        bytes memory signature
        ) public onlyCustodian {
            bytes32 operationHash = keccak256(abi.encodePacked("BULKREVOKE", hashes, expireTime, sequenceId));
            
            address otherSigner = verifyMultiSig(operationHash, signature, expireTime, sequenceId);
            
            documentStore.bulkRevoke(hashes);
            
            emit BulkRevoke(msg.sender, otherSigner, operationHash, hashes);
        }
    
         
    function transferMultiSig(
        address newOwner,
        uint expireTime,
        uint sequenceId,
        bytes memory signature
        ) public onlyBackup {
            bytes32 operationHash = keccak256(abi.encodePacked("TRANSFER", newOwner, expireTime, sequenceId));
            
            address otherSigner = verifyMultiSig(operationHash, signature, expireTime, sequenceId);
            
            documentStore.transferOwnership(newOwner);
            
            emit Transferred(msg.sender, otherSigner, newOwner);
        }
    
       
    function changeStoreMultiSig(
        address newStore,
        uint expireTime,
        uint sequenceId,
        bytes memory signature
        ) public onlyBackup {
            bytes32 operationHash = keccak256(abi.encodePacked("CHANGE", newStore, expireTime, sequenceId));
            
            address otherSigner = verifyMultiSig(operationHash, signature, expireTime, sequenceId);
            
            documentStore = DocumentStore(newStore);
            
            emit Change(msg.sender, otherSigner, newStore);
        }
        
     
    function verifyMultiSig(
        bytes32 operationHash,
        bytes memory signature,
        uint expireTime,
        uint sequenceId
        ) private returns (address) {
    
            address otherSigner = recoverAddressFromSignature(operationHash, signature);
            
             
            if (expireTime < block.timestamp) {
                 
                revert();
            }
    
             
            tryInsertSequenceId(sequenceId);
        
            if (!isSigner(otherSigner)) {
                 
                revert();
            }
            if (otherSigner == msg.sender) {
                 
                revert();
            }
        
            return otherSigner;
        }
    
     
    function recoverAddressFromSignature(
        bytes32 operationHash,
        bytes memory signature
        ) private pure returns (address) {
            if (signature.length != 65) {
            revert();
            }
         
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := and(mload(add(signature, 65)), 255)
        }
        if (v < 27) {
            v += 27;  
        }
        return ecrecover(operationHash, v, r, s);
    }
        
     
    function tryInsertSequenceId(uint sequenceId) private onlyInitiators {
         
        uint lowestValueIndex = 0;
        for (uint i = 0; i < SEQUENCE_ID_WINDOW_SIZE; i++) {
            if (recentSequenceIds[i] == sequenceId) {
                 
                revert();
            }
            if (recentSequenceIds[i] < recentSequenceIds[lowestValueIndex]) {
                lowestValueIndex = i;
            }
        }
        if (sequenceId < recentSequenceIds[lowestValueIndex]) {
             
             
            revert();
        }
        if (sequenceId > (recentSequenceIds[lowestValueIndex] + 10000)) {
             
             
            revert();
        }
        recentSequenceIds[lowestValueIndex] = sequenceId;
    }
    
     
    function getNextSequenceId() public view returns (uint) {
        uint highestSequenceId = 0;
        for (uint i = 0; i < SEQUENCE_ID_WINDOW_SIZE; i++) {
            if (recentSequenceIds[i] > highestSequenceId) {
                highestSequenceId = recentSequenceIds[i];
            }
        }
    return highestSequenceId + 1;
    }
}
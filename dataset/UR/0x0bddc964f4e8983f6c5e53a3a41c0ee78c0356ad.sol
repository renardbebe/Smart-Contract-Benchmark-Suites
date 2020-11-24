 

pragma solidity ^0.4.24;

library DS {
  struct Proof {
    uint level;          
    uint insertedBlock;  
    bytes32 ipfsHash;    
    address auditedBy;   
  }
}

contract Audit {
  event AttachedEvidence(address indexed auditorAddr, bytes32 indexed codeHash, bytes32 ipfsHash);
  event NewAudit(address indexed auditorAddr, bytes32 indexed codeHash);

   
  mapping (address => mapping (bytes32 => DS.Proof)) public auditedContracts;
   
  mapping (address => bytes32[]) public auditorContracts;
  
   
  function isVerifiedAddress(address _auditorAddr, address _contractAddr) public view returns(uint) {
    bytes32 codeHash = getCodeHash(_contractAddr);
    return auditedContracts[_auditorAddr][codeHash].level;
  }

  function isVerifiedCode(address _auditorAddr, bytes32 _codeHash) public view returns(uint) {
    return auditedContracts[_auditorAddr][_codeHash].level;
  }
  
  function getCodeHash(address _contractAddr) public view returns(bytes32) {
      return keccak256(codeAt(_contractAddr));
  }
  
   
  function addAudit(bytes32 _codeHash, uint _level, bytes32 _ipfsHash) public {
    address auditor = msg.sender;
    require(auditedContracts[auditor][_codeHash].insertedBlock == 0);
    auditedContracts[auditor][_codeHash] = DS.Proof({ 
        level: _level,
        auditedBy: auditor,
        insertedBlock: block.number,
        ipfsHash: _ipfsHash
    });
    auditorContracts[auditor].push(_codeHash);
    emit NewAudit(auditor, _codeHash);
  }
  
   
   
  function addEvidence(bytes32 _codeHash, uint _newLevel, bytes32 _ipfsHash) public {
    address auditor = msg.sender;
    require(auditedContracts[auditor][_codeHash].insertedBlock != 0);
    if (auditedContracts[auditor][_codeHash].level != _newLevel)
      auditedContracts[auditor][_codeHash].level = _newLevel;
    emit AttachedEvidence(auditor, _codeHash, _ipfsHash);
  }

  function codeAt(address _addr) public view returns (bytes code) {
    assembly {
       
      let size := extcodesize(_addr)
       
       
      code := mload(0x40)
       
      mstore(0x40, add(code, and(add(add(size, 0x20), 0x1f), not(0x1f))))
       
      mstore(code, size)
       
      extcodecopy(_addr, add(code, 0x20), 0, size)
    }
  }
}

contract MonteLabsMS {
   
  mapping (address => bool) public owners;
  uint8 constant quorum = 2;
  Audit public auditContract;

  constructor(address[] _owners, Audit _auditContract) public {
    auditContract = _auditContract;
    require(_owners.length == 3);
    for (uint i = 0; i < _owners.length; ++i) {
      owners[_owners[i]] = true;
    }
  }

  function addAuditOrEvidence(bool audit, bytes32 _codeHash, uint _level,
                              bytes32 _ipfsHash, uint8 _v, bytes32 _r, 
                              bytes32 _s) internal {
    address sender = msg.sender;
    require(owners[sender]);

    bytes32 prefixedHash = keccak256("\x19Ethereum Signed Message:\n32",
                           keccak256(audit, _codeHash, _level, _ipfsHash));

    address other = ecrecover(prefixedHash, _v, _r, _s);
     
    assert(other != sender);
    if (audit)
      auditContract.addAudit(_codeHash, _level, _ipfsHash);
    else
      auditContract.addEvidence(_codeHash, _level, _ipfsHash);
  }

  function addAudit(bytes32 _codeHash, uint _level, bytes32 _ipfsHash,
                    uint8 _v, bytes32 _r, bytes32 _s) public {
    addAuditOrEvidence(true, _codeHash, _level, _ipfsHash, _v, _r, _s);
  }

  function addEvidence(bytes32 _codeHash, uint _version, bytes32 _ipfsHash,
                    uint8 _v, bytes32 _r, bytes32 _s) public {
    addAuditOrEvidence(false, _codeHash, _version, _ipfsHash, _v, _r, _s);
  }
}
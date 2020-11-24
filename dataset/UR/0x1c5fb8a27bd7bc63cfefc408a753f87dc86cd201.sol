 

pragma solidity ^0.4.13;

library CertsLib {
  struct SignatureData {
     
    bytes32 status;
    uint exp;  
  }

  struct TransferData {
    address newOwner;
    uint newEntityId;
  }

  struct CertData {
     
    address owner;  
    uint entityId;  
    bytes32 certHash;  
    string ipfsCertHash;  
    bytes32 dataHash;  
    string ipfsDataHash;  
    mapping(uint => SignatureData) entities;  
    uint[] entitiesArr;
    mapping(address => SignatureData) signatures;  
    address[] signaturesArr;
  }

  struct Data {
    mapping(uint => CertData) certificates;
    mapping(uint => TransferData) transferRequests;
    uint nCerts;
  }

   

   
  function createPOECertificate(Data storage self, bytes32 dataHash, bytes32 certHash, string ipfsDataHash, string ipfsCertHash) public returns (uint) {
    require (hasData(dataHash, certHash, ipfsDataHash, ipfsCertHash));

    uint certId = ++self.nCerts;
    self.certificates[certId] = CertData({
      owner: 0,
      entityId: 0,
      certHash: certHash,
      ipfsCertHash: ipfsCertHash,
      dataHash: dataHash,
      ipfsDataHash: ipfsDataHash,
      entitiesArr: new uint[](0),
      signaturesArr: new address[](0)
    });

    POECertificate(certId);
    return certId;
  }

   
  function createCertificate(Data storage self, EntityLib.Data storage ed, bytes32 dataHash, bytes32 certHash, string ipfsDataHash, string ipfsCertHash, uint entityId) senderCanIssueEntityCerts(ed, entityId) public returns (uint) {
    require (hasData(dataHash, certHash, ipfsDataHash, ipfsCertHash));

    uint certId = ++self.nCerts;
    self.certificates[certId] = CertData({
      owner: entityId == 0 ? msg.sender : 0,
      entityId: entityId,
      certHash: certHash,
      ipfsCertHash: ipfsCertHash,
      dataHash: dataHash,
      ipfsDataHash: ipfsDataHash,
      entitiesArr: new uint[](0),
      signaturesArr: new address[](0)
    });

    Certificate(certId);
    return certId;
  }

   
  function requestCertificateTransferToPeer(Data storage self, EntityLib.Data storage ed, uint certificateId, address newOwner) canTransferCertificate(self, ed, certificateId) public {
    self.transferRequests[certificateId] = TransferData({
      newOwner: newOwner,
      newEntityId: 0
    });

    CertificateTransferRequestedToPeer(certificateId, newOwner);
  }

   
  function requestCertificateTransferToEntity(Data storage self, EntityLib.Data storage ed, uint certificateId, uint newEntityId) entityExists(ed, newEntityId) canTransferCertificate(self, ed, certificateId) public {
    self.transferRequests[certificateId] = TransferData({
      newOwner: 0,
      newEntityId: newEntityId
    });

    CertificateTransferRequestedToEntity(certificateId, newEntityId);
  }

   
  function acceptCertificateTransfer(Data storage self, EntityLib.Data storage ed, uint certificateId) canAcceptTransfer(self, ed, certificateId) public {
    TransferData storage reqData = self.transferRequests[certificateId];
    self.certificates[certificateId].owner = reqData.newOwner;
    self.certificates[certificateId].entityId = reqData.newEntityId;    
    CertificateTransferAccepted(certificateId, reqData.newOwner, reqData.newEntityId);
    delete self.transferRequests[certificateId];
  }

   
  function cancelCertificateTransfer(Data storage self, EntityLib.Data storage ed, uint certificateId) canTransferCertificate(self, ed, certificateId) public {
    self.transferRequests[certificateId] = TransferData({
      newOwner: 0,
      newEntityId: 0
    });

    CertificateTransferCancelled(certificateId);
  }

   
  function setIPFSData(Data storage self, uint certId, string ipfsDataHash, string ipfsCertHash) ownsCertificate(self, certId) public {
      self.certificates[certId].ipfsDataHash = ipfsDataHash;
      self.certificates[certId].ipfsCertHash = ipfsCertHash;
      UpdatedIPFSData(certId);
  }

   

   
  function hasData(bytes32 dataHash, bytes32 certHash, string ipfsDataHash, string ipfsCertHash) pure public returns (bool) {
    return certHash != 0
    || dataHash != 0
    || bytes(ipfsDataHash).length != 0
    || bytes(ipfsCertHash).length != 0;
  }

   
  
  
  modifier ownsCertificate(Data storage self, uint id) {
    require (self.certificates[id].owner == msg.sender);
    _;
  }


   
  modifier senderCanIssueEntityCerts(EntityLib.Data storage ed, uint entityId) {
    require (entityId == 0 
     || (EntityLib.isValid(ed, entityId) && ed.entities[entityId].signers[msg.sender].status == 2));
    _;    
  }

   
  modifier canTransferCertificate(Data storage self, EntityLib.Data storage ed, uint certificateId) {
    CertData storage cert = self.certificates[certificateId];
    require (hasData(cert.dataHash, cert.certHash, cert.ipfsDataHash, cert.ipfsCertHash));

    if (cert.owner != 0) {
      require (cert.owner == msg.sender);
      _;
    } else if (cert.entityId != 0) {
      EntityLib.EntityData storage entity = ed.entities[cert.entityId];
      require (EntityLib.isValid(ed, cert.entityId) && entity.signers[msg.sender].status == 2);
      _;
    }
  }

   
  modifier entityExists(EntityLib.Data storage ed, uint entityId) {
    require (EntityLib.exists(ed, entityId));
    _;
  }

   
  modifier canAcceptTransfer(Data storage self, EntityLib.Data storage ed, uint certificateId) {
    CertData storage cert = self.certificates[certificateId];
    require (hasData(cert.dataHash, cert.certHash, cert.ipfsDataHash, cert.ipfsCertHash));

    TransferData storage reqData = self.transferRequests[certificateId];
    require(reqData.newEntityId != 0 || reqData.newOwner != 0);

    if (reqData.newOwner == msg.sender) {
      _;
    } else if (reqData.newEntityId != 0) {      
      EntityLib.EntityData storage newEntity = ed.entities[reqData.newEntityId];
      require (EntityLib.isValid(ed, reqData.newEntityId) && newEntity.signers[msg.sender].status == 2);
       _;
    }
  }

   

  event POECertificate(uint indexed certificateId);
  event Certificate(uint indexed certificateId);
  event CertificateTransferRequestedToPeer(uint indexed certificateId, address newOwner);
  event CertificateTransferRequestedToEntity(uint indexed certificateId, uint newEntityId);
  event CertificateTransferAccepted(uint indexed certificateId, address newOwner, uint newEntityId);
  event CertificateTransferCancelled(uint indexed certificateId);
  event UpdatedIPFSData(uint indexed certificateId);
}

library EntityLib {
  struct SignerData {
    string signerDataHash;
     
    uint status;
  }

  struct EntityData {
    address owner;
    string dataHash;  
     
    uint status;
    bytes32 urlHash;          
    uint expiration;          
    uint renewalPeriod;       
    bytes32 oraclizeQueryId;  

     
    mapping(address => SignerData) signers;
    address[] signersArr;
  }

  struct Data {
    mapping(uint => EntityData) entities;
    mapping(bytes32 => uint) entityIds;
    uint nEntities;
  }

   

   
  function create(Data storage self, uint entityId, string entitDatayHash, bytes32 urlHash, uint expirationDate, uint renewalPeriod) isExpirationDateValid(expirationDate) isRenewalPeriodValid(renewalPeriod) public {
    self.entities[entityId] = EntityData({
        owner: msg.sender,
        dataHash: entitDatayHash,
        urlHash: urlHash,
        status: 1,
        expiration: expirationDate,
        renewalPeriod: renewalPeriod,
        oraclizeQueryId: 0,
        signersArr: new address[](0)
    });
    EntityCreated(entityId);
  }

   
  function processValidation(Data storage self, bytes32 queryId, string result) public {
    uint entityId = self.entityIds[queryId];
    self.entityIds[queryId] = 0;
    
    EntityData storage entity = self.entities[entityId];

    require (queryId == entity.oraclizeQueryId);

    string memory entityIdStr = uintToString(entityId);
    string memory toCompare = strConcat(entityIdStr, ":", entity.dataHash); 

    if (stringsEqual(result, toCompare)) {
      if (entity.status == 4) {  
        uint initDate = max(entity.expiration, now);
        entity.expiration = initDate + entity.renewalPeriod;
      }

      entity.status = 2;  
      EntityValidated(entityId);
    } else {
      entity.status = 1;   
      EntityInvalid(entityId);
    }
  }

   
  function setExpiration (Data storage self, uint entityId, uint expirationDate) isNotClosed(self, entityId) onlyEntity(self, entityId) isExpirationDateValid(expirationDate) public {
    EntityData storage entity = self.entities[entityId];
    entity.status = 1;
    entity.expiration = expirationDate;
    EntityExpirationSet(entityId);
  }
  
   
  function setRenewalPeriod (Data storage self, uint entityId, uint renewalPeriod) isNotClosed(self, entityId) onlyEntity(self, entityId) isRenewalPeriodValid(renewalPeriod) public {
    EntityData storage entity = self.entities[entityId];
    entity.renewalPeriod = renewalPeriod;
    EntityRenewalSet(entityId);
  }

   
  function closeEntity(Data storage self, uint entityId) isNotClosed(self, entityId) onlyEntity(self, entityId) public {
    self.entities[entityId].status = 8;
    EntityClosed(entityId);
  }

   
  function registerSigner(Data storage self, uint entityId, address signerAddress, string signerDataHash) isValidEntity(self, entityId) onlyEntity(self, entityId) signerIsNotYetRegistered(self, entityId, signerAddress) public {
    self.entities[entityId].signersArr.push(signerAddress);
    self.entities[entityId].signers[signerAddress] = SignerData({
      signerDataHash: signerDataHash,
      status: 1
    });
    SignerAdded(entityId, signerAddress);
  }

   
  function confirmSignerRegistration(Data storage self, uint entityId, string signerDataHash) isValidEntity(self, entityId) isWaitingConfirmation(self, entityId, signerDataHash) public {
    self.entities[entityId].signers[msg.sender].status = 2;
    SignerConfirmed(entityId, msg.sender);
  }

   
  function removeSigner(Data storage self, uint entityId, address signerAddress) isValidEntity(self, entityId) onlyEntity(self, entityId) public {
    internalRemoveSigner(self, entityId, signerAddress);
  }


   
  function internalRemoveSigner(Data storage self, uint entityId, address signerAddress) private {
    EntityData storage entity = self.entities[entityId];
    address[] storage signersArr = entity.signersArr;
    SignerData storage signer = entity.signers[signerAddress];

    if (bytes(signer.signerDataHash).length != 0 || signer.status != 0) {
      signer.status = 0;
      signer.signerDataHash = '';
      delete entity.signers[signerAddress];

       
      uint i = 0;
      for (i; signerAddress != signersArr[i]; i++) {}
      signersArr[i] = signersArr[signersArr.length - 1];
      signersArr[signersArr.length - 1] = 0;
      signersArr.length = signersArr.length - 1;
      
      SignerRemoved(entityId, signerAddress);
    }
  }

   
  function leaveEntity(Data storage self, uint entityId) signerBelongsToEntity(self, entityId) public {
    internalRemoveSigner(self, entityId, msg.sender);
  }

   
  function canValidateSigningEntity(Data storage self, uint entityId, string url) isNotClosed(self, entityId) isRegisteredURL(self, entityId, url) view public returns (bool) {
    return true;
  }

   
  function canRenew(Data storage self, uint entityId, string url) isValidatedEntity(self, entityId) isRenewalPeriod(self, entityId) isRegisteredURL(self, entityId, url) view public returns (bool) {
    return true;
  }

   
  function canIssueCertificates(Data storage self, uint entityId) isNotClosed(self, entityId) notExpired(self, entityId) signerBelongsToEntity(self, entityId) view public returns (bool) {
    return true;
  }

   
  function updateEntityData(Data storage self, uint entityId, string entityDataHash, bytes32 urlHash) isNotClosed(self, entityId) onlyEntity(self, entityId) public {
    EntityData storage entity = self.entities[entityId];
    entity.dataHash = entityDataHash;
    entity.urlHash = urlHash;
    entity.status = 1;
    EntityDataUpdated(entityId);
  }


   
  function updateSignerData(Data storage self, uint[] entityIds, string signerDataHash) signerBelongsToEntities(self, entityIds) public {
    uint[] memory updated = new uint[](entityIds.length);
    for (uint i = 0; i < entityIds.length; i++) {
      uint entityId = entityIds[i];
      SignerData storage signer = self.entities[entityId].signers[msg.sender];

      if (signer.status != 2) {
        continue;
      }
      signer.status = 3;
      signer.signerDataHash = signerDataHash;
      updated[i] = entityId;
    }
    SignerDataUpdated(updated, msg.sender);
  }

   
  function acceptSignerUpdate(Data storage self, uint entityId, address signerAddress, string signerDataHash) onlyEntity(self, entityId) notExpired(self, entityId) signerUpdateCanBeAccepted(self, entityId, signerAddress, signerDataHash) public {
    EntityData storage entity = self.entities[entityId];
    entity.signers[signerAddress].status = 2;
    SignerUpdateAccepted(entityId, signerAddress);
  }

   

   
  function max(uint a, uint b) pure public returns(uint) {
    if (a > b) {
      return a;
    } else {
      return b;
    }
  }

   
  function stringsEqual(string memory _a, string memory _b) pure internal returns (bool) {
    bytes memory a = bytes(_a);
    bytes memory b = bytes(_b);
    if (a.length != b.length)
      return false;
    for (uint i = 0; i < a.length; i ++) {
      if (a[i] != b[i])
        return false;
        }
    return true;
  }

  function strConcat(string _a, string _b, string _c, string _d, string _e) pure internal returns (string){
    bytes memory _ba = bytes(_a);
    bytes memory _bb = bytes(_b);
    bytes memory _bc = bytes(_c);
    bytes memory _bd = bytes(_d);
    bytes memory _be = bytes(_e);
    string memory abcde = new string(_ba.length + _bb.length + _bc.length + _bd.length + _be.length);
    bytes memory babcde = bytes(abcde);
    uint k = 0;
    for (uint i = 0; i < _ba.length; i++) {babcde[k++] = _ba[i];}
    for (i = 0; i < _bb.length; i++) {babcde[k++] = _bb[i];}
    for (i = 0; i < _bc.length; i++) {babcde[k++] = _bc[i];}
    for (i = 0; i < _bd.length; i++) {babcde[k++] = _bd[i];}
    for (i = 0; i < _be.length; i++) {babcde[k++] = _be[i];}
    return string(babcde);
  }

  function strConcat(string _a, string _b, string _c, string _d) pure internal returns (string) {
      return strConcat(_a, _b, _c, _d, "");
  }

  function strConcat(string _a, string _b, string _c) pure internal returns (string) {
      return strConcat(_a, _b, _c, "", "");
  }

  function strConcat(string _a, string _b) pure internal returns (string) {
      return strConcat(_a, _b, "", "", "");
  }

   
  function uintToString(uint v) pure public returns (string) {
    uint maxlength = 100;
    bytes memory reversed = new bytes(maxlength);
    uint i = 0;
    while (v != 0) {
      uint remainder = v % 10;
      v = v / 10;
      reversed[i++] = byte(48 + remainder);
    }
    bytes memory s = new bytes(i);  
    for (uint j = 0; j < i; j++) {
        s[j] = reversed[i - j - 1];  
    }
    string memory str = string(s);  
    return str;
  }

   
  function setOraclizeQueryId(Data storage self, uint id, bytes32 queryId) public {
    self.entities[id].oraclizeQueryId = queryId;
  }

   

   
  function isValidated(Data storage self, uint id) view public returns (bool) {
    return (id > 0 && (self.entities[id].status == 2 || self.entities[id].status == 4));
  }

  
  function isExpired(Data storage self, uint id) view public returns (bool) {
    return (id > 0 && (self.entities[id].expiration < now));
  }

   
  function isClosed(Data storage self, uint id) view public returns (bool) {
    return self.entities[id].status == 8;
  }

  
  function isValid(Data storage self, uint id) view public returns (bool) {
    return isValidated(self, id) && !isExpired(self, id) && !isClosed(self, id);
  }

  
  function exists(Data storage self, uint id) view public returns(bool) {
    EntityData storage entity = self.entities[id];
    return entity.status > 0;
  }

   
  
   
  modifier isRenewalPeriodValid(uint renewalPeriod) {
    require(renewalPeriod >= 0 && renewalPeriod <= 32 * 24 * 60 * 60);  
    _;
  }

   
  modifier isExpirationDateValid(uint expiration) {
    require(expiration - now > 0 && expiration - now <= 32 * 24 * 60 * 60);  
    _;
  }
  
   
  modifier isValidatedEntity(Data storage self, uint id) {
    require (isValidated(self, id));
    _;
  }

   
  modifier isValidEntity(Data storage self, uint id) {
    require (isValid(self, id));
    _;
  }

   
  modifier notExpired(Data storage self, uint id) {
    require (!isExpired(self, id));
    _;  
  }

   
  modifier onlyEntity(Data storage self, uint id) {
    require (msg.sender == self.entities[id].owner);
    _;
  }

   
  modifier isRegisteredURL(Data storage self, uint entityId, string url) {
    require (self.entities[entityId].urlHash == sha256(url));
    _;
  }

   
  modifier isRenewalPeriod(Data storage self, uint entityId) {
    EntityData storage entity = self.entities[entityId];
    require (entity.renewalPeriod > 0 && entityId > 0 && (entity.expiration - entity.renewalPeriod < now) && entity.status == 2);
    _;
  }

   
  modifier signerBelongsToEntity(Data storage self, uint entityId) {
    EntityData storage entity = self.entities[entityId];
    require (entityId > 0 && (bytes(entity.signers[msg.sender].signerDataHash).length != 0) && (entity.signers[msg.sender].status == 2));
    _;
  }

   
  modifier signerBelongsToEntities(Data storage self, uint[] entityIds) {
    for (uint i = 0; i < entityIds.length; i++) {
      uint entityId = entityIds[i];
      EntityData storage entity = self.entities[entityId];
      require (entityId > 0 && (entity.signers[msg.sender].status != 0));
    }
    _;
  }

   
  modifier signerIsNotYetRegistered(Data storage self, uint entityId, address signerAddress) {
    EntityData storage entity = self.entities[entityId];
    require (entity.signers[signerAddress].status == 0);
    _;
  }

   
  modifier signerUpdateCanBeAccepted(Data storage self, uint entityId, address signerAddress, string signerDataHash) {
    require (isValid(self, entityId));
    EntityData storage entity = self.entities[entityId];
    string memory oldSignerDatHash = entity.signers[signerAddress].signerDataHash;
    require (entity.signers[signerAddress].status == 3 && stringsEqual(oldSignerDatHash, signerDataHash));
    _;
  }

   
  modifier isWaitingConfirmation(Data storage self, uint entityId, string signerDataHash) {
    EntityData storage entity = self.entities[entityId];
    SignerData storage signer = entity.signers[msg.sender];
    require ((bytes(signer.signerDataHash).length != 0) && (signer.status == 1) && stringsEqual(signer.signerDataHash, signerDataHash));
    _;
  }

   
  modifier isNotClosed(Data storage self, uint entityId) {
    require(!isClosed(self, entityId));
    _;
  }

   

  event EntityCreated(uint indexed entityId);
  event EntityValidated(uint indexed entityId);
  event EntityDataUpdated(uint indexed entityId);
  event EntityInvalid(uint indexed entityId);
  event SignerAdded(uint indexed entityId, address indexed signerAddress);
  event SignerDataUpdated(uint[] entities, address indexed signerAddress);
  event SignerUpdateAccepted(uint indexed entityId, address indexed signerAddress);
  event SignerRemoved(uint indexed entityId, address signerAddress);
  event EntityClosed(uint indexed entityId);
  event SignerConfirmed(uint indexed entityId, address signerAddress);
  event EntityExpirationSet(uint indexed entityId);
  event EntityRenewalSet(uint indexed entityId);  
 }

library SignLib {

   

   
  function requestSignatureToEntity(EntityLib.Data storage ed, CertsLib.Data storage cd, uint certificateId, uint entityId) canRequestSignature(ed, cd, certificateId) isValid(ed, entityId) notHasSigningRequest(cd, certificateId, entityId) public {
    CertsLib.CertData storage certificate = cd.certificates[certificateId];
    addMissingSignature(certificate, entityId, 0x1, 0);
    EntitySignatureRequested(certificateId, entityId);
  }

   
  function requestSignatureToPeer(EntityLib.Data storage ed, CertsLib.Data storage cd, uint certificateId, address peer) canRequestSignature(ed, cd, certificateId) notHasPeerSignature(cd, certificateId, peer) public {
    CertsLib.CertData storage certificate = cd.certificates[certificateId];
    addMissingPeerSignature(certificate, peer, 0x1, 0);
    PeerSignatureRequested(certificateId, peer);
  }

     
  function signCertificateAsEntity(EntityLib.Data storage ed, CertsLib.Data storage cd, uint entityId, uint certificateId, uint expiration, bytes32 _purpose) isValid(ed, entityId) signerBelongsToEntity(ed, entityId) hasPendingSignatureOrIsOwner(ed, cd, certificateId, entityId) public {
    CertsLib.CertData storage certificate = cd.certificates[certificateId];
    bytes32 purpose = (_purpose == 0x0 || _purpose == 0x1) ? bytes32(0x2) : _purpose;
    addMissingSignature(certificate, entityId, purpose, expiration);
    CertificateSignedByEntity(certificateId, entityId, msg.sender);
  }

   
  function signCertificateAsPeer(CertsLib.Data storage cd, uint certificateId, uint expiration, bytes32 _purpose) hasPendingPeerSignatureOrIsOwner(cd, certificateId) public {
    CertsLib.CertData storage certificate = cd.certificates[certificateId];
    bytes32 purpose = (_purpose == 0x0 || _purpose == 0x1) ? bytes32(0x2) : _purpose;
    addMissingPeerSignature(certificate, msg.sender, purpose, expiration);
    CertificateSignedByPeer(certificateId, msg.sender);
  }

   

   
  function addMissingSignature(CertsLib.CertData storage certificate, uint entityId, bytes32 status, uint expiration) private {
    uint[] storage entitiesArr = certificate.entitiesArr;
    for (uint i = 0; i < entitiesArr.length && entitiesArr[i] != entityId; i++) {}
    if (i == entitiesArr.length) {
      entitiesArr.push(entityId);
    }
    certificate.entities[entityId].status = status;
    certificate.entities[entityId].exp = expiration;
  }

   
  function addMissingPeerSignature(CertsLib.CertData storage certificate, address peer, bytes32 status, uint expiration) private {
    address[] storage signaturesArr = certificate.signaturesArr;
    for (uint i = 0; i < signaturesArr.length && signaturesArr[i] != peer; i++) {}
    if (i == signaturesArr.length) {
      signaturesArr.push(peer);
    }
    certificate.signatures[peer].status = status;
    certificate.signatures[peer].exp = expiration;
  }

   

   
  modifier canRequestSignature(EntityLib.Data storage ed, CertsLib.Data storage cd, uint id) {
    require (cd.certificates[id].owner == msg.sender ||
      (cd.certificates[id].entityId > 0 && EntityLib.isValid(ed, cd.certificates[id].entityId) && ed.entities[cd.certificates[id].entityId].signers[msg.sender].status == 0x2)
    );
    _;
  }

   
  modifier isValid(EntityLib.Data storage ed, uint id) {
    require (EntityLib.isValid(ed, id));
    _;
  }

   
  modifier notHasSigningRequest(CertsLib.Data storage cd, uint certificateId, uint entityId) {
    require (cd.certificates[certificateId].entities[entityId].status != 0x1);
    _;    
  }

   
  modifier notHasPeerSignature(CertsLib.Data storage cd, uint certificateId, address signerAddress) {    
    require (cd.certificates[certificateId].signatures[signerAddress].status != 0x1);
    _;
  }

   
  modifier signerBelongsToEntity(EntityLib.Data storage ed, uint entityId) {
    require (entityId > 0 && (bytes(ed.entities[entityId].signers[msg.sender].signerDataHash).length != 0) && (ed.entities[entityId].signers[msg.sender].status == 0x2));
    _;
  }

   
  modifier hasPendingSignatureOrIsOwner(EntityLib.Data storage ed, CertsLib.Data storage cd, uint certificateId, uint entityId) {
    require (cd.certificates[certificateId].entities[entityId].status == 0x1 || cd.certificates[certificateId].entityId == entityId);
    _;
  }

   
  modifier hasPendingPeerSignatureOrIsOwner(CertsLib.Data storage cd, uint certificateId) {
    require (cd.certificates[certificateId].signatures[msg.sender].status == 0x1 || cd.certificates[certificateId].owner == msg.sender);
    _;
  }

   
  event EntitySignatureRequested(uint indexed certificateId, uint indexed entityId);
  event PeerSignatureRequested(uint indexed certificateId, address indexed signerAddress);
  event CertificateSignedByEntity(uint indexed certificateId, uint indexed entityId, address indexed signerAddress);
  event CertificateSignedByPeer(uint indexed certificateId, address indexed signerAddress);
}

contract OraclizeI {
    address public cbAddress;
    function query(uint _timestamp, string _datasource, string _arg) payable returns (bytes32 _id);
    function query_withGasLimit(uint _timestamp, string _datasource, string _arg, uint _gaslimit) payable returns (bytes32 _id);
    function query2(uint _timestamp, string _datasource, string _arg1, string _arg2) payable returns (bytes32 _id);
    function query2_withGasLimit(uint _timestamp, string _datasource, string _arg1, string _arg2, uint _gaslimit) payable returns (bytes32 _id);
    function queryN(uint _timestamp, string _datasource, bytes _argN) payable returns (bytes32 _id);
    function queryN_withGasLimit(uint _timestamp, string _datasource, bytes _argN, uint _gaslimit) payable returns (bytes32 _id);
    function getPrice(string _datasource) returns (uint _dsprice);
    function getPrice(string _datasource, uint gaslimit) returns (uint _dsprice);
    function useCoupon(string _coupon);
    function setProofType(byte _proofType);
    function setConfig(bytes32 _config);
    function setCustomGasPrice(uint _gasPrice);
    function randomDS_getSessionPubKeyHash() returns(bytes32);
}

contract OraclizeAddrResolverI {
    function getAddress() returns (address _addr);
}

library Buffer {
    struct buffer {
        bytes buf;
        uint capacity;
    }

    function init(buffer memory buf, uint capacity) internal constant {
        if(capacity % 32 != 0) capacity += 32 - (capacity % 32);
         
        buf.capacity = capacity;
        assembly {
            let ptr := mload(0x40)
            mstore(buf, ptr)
            mstore(0x40, add(ptr, capacity))
        }
    }

    function resize(buffer memory buf, uint capacity) private constant {
        bytes memory oldbuf = buf.buf;
        init(buf, capacity);
        append(buf, oldbuf);
    }

    function max(uint a, uint b) private constant returns(uint) {
        if(a > b) {
            return a;
        }
        return b;
    }

     
    function append(buffer memory buf, bytes data) internal constant returns(buffer memory) {
        if(data.length + buf.buf.length > buf.capacity) {
            resize(buf, max(buf.capacity, data.length) * 2);
        }

        uint dest;
        uint src;
        uint len = data.length;
        assembly {
             
            let bufptr := mload(buf)
             
            let buflen := mload(bufptr)
             
            dest := add(add(bufptr, buflen), 32)
             
            mstore(bufptr, add(buflen, mload(data)))
            src := add(data, 32)
        }

         
        for(; len >= 32; len -= 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }

         
        uint mask = 256 ** (32 - len) - 1;
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }

        return buf;
    }

     
    function append(buffer memory buf, uint8 data) internal constant {
        if(buf.buf.length + 1 > buf.capacity) {
            resize(buf, buf.capacity * 2);
        }

        assembly {
             
            let bufptr := mload(buf)
             
            let buflen := mload(bufptr)
             
            let dest := add(add(bufptr, buflen), 32)
            mstore8(dest, data)
             
            mstore(bufptr, add(buflen, 1))
        }
    }

     
    function appendInt(buffer memory buf, uint data, uint len) internal constant returns(buffer memory) {
        if(len + buf.buf.length > buf.capacity) {
            resize(buf, max(buf.capacity, len) * 2);
        }

        uint mask = 256 ** len - 1;
        assembly {
             
            let bufptr := mload(buf)
             
            let buflen := mload(bufptr)
             
            let dest := add(add(bufptr, buflen), len)
            mstore(dest, or(and(mload(dest), not(mask)), data))
             
            mstore(bufptr, add(buflen, len))
        }
        return buf;
    }
}

library CBOR {
    using Buffer for Buffer.buffer;

    uint8 private constant MAJOR_TYPE_INT = 0;
    uint8 private constant MAJOR_TYPE_NEGATIVE_INT = 1;
    uint8 private constant MAJOR_TYPE_BYTES = 2;
    uint8 private constant MAJOR_TYPE_STRING = 3;
    uint8 private constant MAJOR_TYPE_ARRAY = 4;
    uint8 private constant MAJOR_TYPE_MAP = 5;
    uint8 private constant MAJOR_TYPE_CONTENT_FREE = 7;

    function shl8(uint8 x, uint8 y) private constant returns (uint8) {
        return x * (2 ** y);
    }

    function encodeType(Buffer.buffer memory buf, uint8 major, uint value) private constant {
        if(value <= 23) {
            buf.append(uint8(shl8(major, 5) | value));
        } else if(value <= 0xFF) {
            buf.append(uint8(shl8(major, 5) | 24));
            buf.appendInt(value, 1);
        } else if(value <= 0xFFFF) {
            buf.append(uint8(shl8(major, 5) | 25));
            buf.appendInt(value, 2);
        } else if(value <= 0xFFFFFFFF) {
            buf.append(uint8(shl8(major, 5) | 26));
            buf.appendInt(value, 4);
        } else if(value <= 0xFFFFFFFFFFFFFFFF) {
            buf.append(uint8(shl8(major, 5) | 27));
            buf.appendInt(value, 8);
        }
    }

    function encodeIndefiniteLengthType(Buffer.buffer memory buf, uint8 major) private constant {
        buf.append(uint8(shl8(major, 5) | 31));
    }

    function encodeUInt(Buffer.buffer memory buf, uint value) internal constant {
        encodeType(buf, MAJOR_TYPE_INT, value);
    }

    function encodeInt(Buffer.buffer memory buf, int value) internal constant {
        if(value >= 0) {
            encodeType(buf, MAJOR_TYPE_INT, uint(value));
        } else {
            encodeType(buf, MAJOR_TYPE_NEGATIVE_INT, uint(-1 - value));
        }
    }

    function encodeBytes(Buffer.buffer memory buf, bytes value) internal constant {
        encodeType(buf, MAJOR_TYPE_BYTES, value.length);
        buf.append(value);
    }

    function encodeString(Buffer.buffer memory buf, string value) internal constant {
        encodeType(buf, MAJOR_TYPE_STRING, bytes(value).length);
        buf.append(bytes(value));
    }

    function startArray(Buffer.buffer memory buf) internal constant {
        encodeIndefiniteLengthType(buf, MAJOR_TYPE_ARRAY);
    }

    function startMap(Buffer.buffer memory buf) internal constant {
        encodeIndefiniteLengthType(buf, MAJOR_TYPE_MAP);
    }

    function endSequence(Buffer.buffer memory buf) internal constant {
        encodeIndefiniteLengthType(buf, MAJOR_TYPE_CONTENT_FREE);
    }
}

contract usingOraclize {
    uint constant day = 60*60*24;
    uint constant week = 60*60*24*7;
    uint constant month = 60*60*24*30;
    byte constant proofType_NONE = 0x00;
    byte constant proofType_TLSNotary = 0x10;
    byte constant proofType_Android = 0x20;
    byte constant proofType_Ledger = 0x30;
    byte constant proofType_Native = 0xF0;
    byte constant proofStorage_IPFS = 0x01;
    uint8 constant networkID_auto = 0;
    uint8 constant networkID_mainnet = 1;
    uint8 constant networkID_testnet = 2;
    uint8 constant networkID_morden = 2;
    uint8 constant networkID_consensys = 161;

    OraclizeAddrResolverI OAR;

    OraclizeI oraclize;
    modifier oraclizeAPI {
        if((address(OAR)==0)||(getCodeSize(address(OAR))==0))
            oraclize_setNetwork(networkID_auto);

        if(address(oraclize) != OAR.getAddress())
            oraclize = OraclizeI(OAR.getAddress());

        _;
    }
    modifier coupon(string code){
        oraclize = OraclizeI(OAR.getAddress());
        oraclize.useCoupon(code);
        _;
    }

    function oraclize_setNetwork(uint8 networkID) internal returns(bool){
        if (getCodeSize(0x1d3B2638a7cC9f2CB3D298A3DA7a90B67E5506ed)>0){  
            OAR = OraclizeAddrResolverI(0x1d3B2638a7cC9f2CB3D298A3DA7a90B67E5506ed);
            oraclize_setNetworkName("eth_mainnet");
            return true;
        }
        if (getCodeSize(0xc03A2615D5efaf5F49F60B7BB6583eaec212fdf1)>0){  
            OAR = OraclizeAddrResolverI(0xc03A2615D5efaf5F49F60B7BB6583eaec212fdf1);
            oraclize_setNetworkName("eth_ropsten3");
            return true;
        }
        if (getCodeSize(0xB7A07BcF2Ba2f2703b24C0691b5278999C59AC7e)>0){  
            OAR = OraclizeAddrResolverI(0xB7A07BcF2Ba2f2703b24C0691b5278999C59AC7e);
            oraclize_setNetworkName("eth_kovan");
            return true;
        }
        if (getCodeSize(0x146500cfd35B22E4A392Fe0aDc06De1a1368Ed48)>0){  
            OAR = OraclizeAddrResolverI(0x146500cfd35B22E4A392Fe0aDc06De1a1368Ed48);
            oraclize_setNetworkName("eth_rinkeby");
            return true;
        }
        if (getCodeSize(0x6f485C8BF6fc43eA212E93BBF8ce046C7f1cb475)>0){  
            OAR = OraclizeAddrResolverI(0x6f485C8BF6fc43eA212E93BBF8ce046C7f1cb475);
            return true;
        }
        if (getCodeSize(0x20e12A1F859B3FeaE5Fb2A0A32C18F5a65555bBF)>0){  
            OAR = OraclizeAddrResolverI(0x20e12A1F859B3FeaE5Fb2A0A32C18F5a65555bBF);
            return true;
        }
        if (getCodeSize(0x51efaF4c8B3C9AfBD5aB9F4bbC82784Ab6ef8fAA)>0){  
            OAR = OraclizeAddrResolverI(0x51efaF4c8B3C9AfBD5aB9F4bbC82784Ab6ef8fAA);
            return true;
        }
        return false;
    }

    function __callback(bytes32 myid, string result) {
        __callback(myid, result, new bytes(0));
    }
    function __callback(bytes32 myid, string result, bytes proof) {
    }

    function oraclize_useCoupon(string code) oraclizeAPI internal {
        oraclize.useCoupon(code);
    }

    function oraclize_getPrice(string datasource) oraclizeAPI internal returns (uint){
        return oraclize.getPrice(datasource);
    }

    function oraclize_getPrice(string datasource, uint gaslimit) oraclizeAPI internal returns (uint){
        return oraclize.getPrice(datasource, gaslimit);
    }

    function oraclize_query(string datasource, string arg) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource);
        if (price > 1 ether + tx.gasprice*200000) return 0;  
        return oraclize.query.value(price)(0, datasource, arg);
    }
    function oraclize_query(uint timestamp, string datasource, string arg) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource);
        if (price > 1 ether + tx.gasprice*200000) return 0;  
        return oraclize.query.value(price)(timestamp, datasource, arg);
    }
    function oraclize_query(uint timestamp, string datasource, string arg, uint gaslimit) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource, gaslimit);
        if (price > 1 ether + tx.gasprice*gaslimit) return 0;  
        return oraclize.query_withGasLimit.value(price)(timestamp, datasource, arg, gaslimit);
    }
    function oraclize_query(string datasource, string arg, uint gaslimit) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource, gaslimit);
        if (price > 1 ether + tx.gasprice*gaslimit) return 0;  
        return oraclize.query_withGasLimit.value(price)(0, datasource, arg, gaslimit);
    }
    function oraclize_query(string datasource, string arg1, string arg2) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource);
        if (price > 1 ether + tx.gasprice*200000) return 0;  
        return oraclize.query2.value(price)(0, datasource, arg1, arg2);
    }
    function oraclize_query(uint timestamp, string datasource, string arg1, string arg2) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource);
        if (price > 1 ether + tx.gasprice*200000) return 0;  
        return oraclize.query2.value(price)(timestamp, datasource, arg1, arg2);
    }
    function oraclize_query(uint timestamp, string datasource, string arg1, string arg2, uint gaslimit) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource, gaslimit);
        if (price > 1 ether + tx.gasprice*gaslimit) return 0;  
        return oraclize.query2_withGasLimit.value(price)(timestamp, datasource, arg1, arg2, gaslimit);
    }
    function oraclize_query(string datasource, string arg1, string arg2, uint gaslimit) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource, gaslimit);
        if (price > 1 ether + tx.gasprice*gaslimit) return 0;  
        return oraclize.query2_withGasLimit.value(price)(0, datasource, arg1, arg2, gaslimit);
    }
    function oraclize_query(string datasource, string[] argN) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource);
        if (price > 1 ether + tx.gasprice*200000) return 0;  
        bytes memory args = stra2cbor(argN);
        return oraclize.queryN.value(price)(0, datasource, args);
    }
    function oraclize_query(uint timestamp, string datasource, string[] argN) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource);
        if (price > 1 ether + tx.gasprice*200000) return 0;  
        bytes memory args = stra2cbor(argN);
        return oraclize.queryN.value(price)(timestamp, datasource, args);
    }
    function oraclize_query(uint timestamp, string datasource, string[] argN, uint gaslimit) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource, gaslimit);
        if (price > 1 ether + tx.gasprice*gaslimit) return 0;  
        bytes memory args = stra2cbor(argN);
        return oraclize.queryN_withGasLimit.value(price)(timestamp, datasource, args, gaslimit);
    }
    function oraclize_query(string datasource, string[] argN, uint gaslimit) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource, gaslimit);
        if (price > 1 ether + tx.gasprice*gaslimit) return 0;  
        bytes memory args = stra2cbor(argN);
        return oraclize.queryN_withGasLimit.value(price)(0, datasource, args, gaslimit);
    }
    function oraclize_query(string datasource, string[1] args) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](1);
        dynargs[0] = args[0];
        return oraclize_query(datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, string[1] args) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](1);
        dynargs[0] = args[0];
        return oraclize_query(timestamp, datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, string[1] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](1);
        dynargs[0] = args[0];
        return oraclize_query(timestamp, datasource, dynargs, gaslimit);
    }
    function oraclize_query(string datasource, string[1] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](1);
        dynargs[0] = args[0];
        return oraclize_query(datasource, dynargs, gaslimit);
    }

    function oraclize_query(string datasource, string[2] args) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](2);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        return oraclize_query(datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, string[2] args) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](2);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        return oraclize_query(timestamp, datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, string[2] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](2);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        return oraclize_query(timestamp, datasource, dynargs, gaslimit);
    }
    function oraclize_query(string datasource, string[2] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](2);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        return oraclize_query(datasource, dynargs, gaslimit);
    }
    function oraclize_query(string datasource, string[3] args) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](3);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        return oraclize_query(datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, string[3] args) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](3);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        return oraclize_query(timestamp, datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, string[3] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](3);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        return oraclize_query(timestamp, datasource, dynargs, gaslimit);
    }
    function oraclize_query(string datasource, string[3] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](3);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        return oraclize_query(datasource, dynargs, gaslimit);
    }

    function oraclize_query(string datasource, string[4] args) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](4);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        dynargs[3] = args[3];
        return oraclize_query(datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, string[4] args) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](4);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        dynargs[3] = args[3];
        return oraclize_query(timestamp, datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, string[4] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](4);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        dynargs[3] = args[3];
        return oraclize_query(timestamp, datasource, dynargs, gaslimit);
    }
    function oraclize_query(string datasource, string[4] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](4);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        dynargs[3] = args[3];
        return oraclize_query(datasource, dynargs, gaslimit);
    }
    function oraclize_query(string datasource, string[5] args) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](5);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        dynargs[3] = args[3];
        dynargs[4] = args[4];
        return oraclize_query(datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, string[5] args) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](5);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        dynargs[3] = args[3];
        dynargs[4] = args[4];
        return oraclize_query(timestamp, datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, string[5] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](5);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        dynargs[3] = args[3];
        dynargs[4] = args[4];
        return oraclize_query(timestamp, datasource, dynargs, gaslimit);
    }
    function oraclize_query(string datasource, string[5] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](5);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        dynargs[3] = args[3];
        dynargs[4] = args[4];
        return oraclize_query(datasource, dynargs, gaslimit);
    }
    function oraclize_query(string datasource, bytes[] argN) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource);
        if (price > 1 ether + tx.gasprice*200000) return 0;  
        bytes memory args = ba2cbor(argN);
        return oraclize.queryN.value(price)(0, datasource, args);
    }
    function oraclize_query(uint timestamp, string datasource, bytes[] argN) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource);
        if (price > 1 ether + tx.gasprice*200000) return 0;  
        bytes memory args = ba2cbor(argN);
        return oraclize.queryN.value(price)(timestamp, datasource, args);
    }
    function oraclize_query(uint timestamp, string datasource, bytes[] argN, uint gaslimit) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource, gaslimit);
        if (price > 1 ether + tx.gasprice*gaslimit) return 0;  
        bytes memory args = ba2cbor(argN);
        return oraclize.queryN_withGasLimit.value(price)(timestamp, datasource, args, gaslimit);
    }
    function oraclize_query(string datasource, bytes[] argN, uint gaslimit) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource, gaslimit);
        if (price > 1 ether + tx.gasprice*gaslimit) return 0;  
        bytes memory args = ba2cbor(argN);
        return oraclize.queryN_withGasLimit.value(price)(0, datasource, args, gaslimit);
    }
    function oraclize_query(string datasource, bytes[1] args) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](1);
        dynargs[0] = args[0];
        return oraclize_query(datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, bytes[1] args) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](1);
        dynargs[0] = args[0];
        return oraclize_query(timestamp, datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, bytes[1] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](1);
        dynargs[0] = args[0];
        return oraclize_query(timestamp, datasource, dynargs, gaslimit);
    }
    function oraclize_query(string datasource, bytes[1] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](1);
        dynargs[0] = args[0];
        return oraclize_query(datasource, dynargs, gaslimit);
    }

    function oraclize_query(string datasource, bytes[2] args) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](2);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        return oraclize_query(datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, bytes[2] args) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](2);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        return oraclize_query(timestamp, datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, bytes[2] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](2);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        return oraclize_query(timestamp, datasource, dynargs, gaslimit);
    }
    function oraclize_query(string datasource, bytes[2] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](2);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        return oraclize_query(datasource, dynargs, gaslimit);
    }
    function oraclize_query(string datasource, bytes[3] args) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](3);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        return oraclize_query(datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, bytes[3] args) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](3);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        return oraclize_query(timestamp, datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, bytes[3] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](3);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        return oraclize_query(timestamp, datasource, dynargs, gaslimit);
    }
    function oraclize_query(string datasource, bytes[3] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](3);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        return oraclize_query(datasource, dynargs, gaslimit);
    }

    function oraclize_query(string datasource, bytes[4] args) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](4);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        dynargs[3] = args[3];
        return oraclize_query(datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, bytes[4] args) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](4);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        dynargs[3] = args[3];
        return oraclize_query(timestamp, datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, bytes[4] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](4);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        dynargs[3] = args[3];
        return oraclize_query(timestamp, datasource, dynargs, gaslimit);
    }
    function oraclize_query(string datasource, bytes[4] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](4);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        dynargs[3] = args[3];
        return oraclize_query(datasource, dynargs, gaslimit);
    }
    function oraclize_query(string datasource, bytes[5] args) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](5);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        dynargs[3] = args[3];
        dynargs[4] = args[4];
        return oraclize_query(datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, bytes[5] args) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](5);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        dynargs[3] = args[3];
        dynargs[4] = args[4];
        return oraclize_query(timestamp, datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, bytes[5] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](5);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        dynargs[3] = args[3];
        dynargs[4] = args[4];
        return oraclize_query(timestamp, datasource, dynargs, gaslimit);
    }
    function oraclize_query(string datasource, bytes[5] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](5);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        dynargs[3] = args[3];
        dynargs[4] = args[4];
        return oraclize_query(datasource, dynargs, gaslimit);
    }

    function oraclize_cbAddress() oraclizeAPI internal returns (address){
        return oraclize.cbAddress();
    }
    function oraclize_setProof(byte proofP) oraclizeAPI internal {
        return oraclize.setProofType(proofP);
    }
    function oraclize_setCustomGasPrice(uint gasPrice) oraclizeAPI internal {
        return oraclize.setCustomGasPrice(gasPrice);
    }
    function oraclize_setConfig(bytes32 config) oraclizeAPI internal {
        return oraclize.setConfig(config);
    }

    function oraclize_randomDS_getSessionPubKeyHash() oraclizeAPI internal returns (bytes32){
        return oraclize.randomDS_getSessionPubKeyHash();
    }

    function getCodeSize(address _addr) constant internal returns(uint _size) {
        assembly {
            _size := extcodesize(_addr)
        }
    }

    function parseAddr(string _a) internal returns (address){
        bytes memory tmp = bytes(_a);
        uint160 iaddr = 0;
        uint160 b1;
        uint160 b2;
        for (uint i=2; i<2+2*20; i+=2){
            iaddr *= 256;
            b1 = uint160(tmp[i]);
            b2 = uint160(tmp[i+1]);
            if ((b1 >= 97)&&(b1 <= 102)) b1 -= 87;
            else if ((b1 >= 65)&&(b1 <= 70)) b1 -= 55;
            else if ((b1 >= 48)&&(b1 <= 57)) b1 -= 48;
            if ((b2 >= 97)&&(b2 <= 102)) b2 -= 87;
            else if ((b2 >= 65)&&(b2 <= 70)) b2 -= 55;
            else if ((b2 >= 48)&&(b2 <= 57)) b2 -= 48;
            iaddr += (b1*16+b2);
        }
        return address(iaddr);
    }

    function strCompare(string _a, string _b) internal returns (int) {
        bytes memory a = bytes(_a);
        bytes memory b = bytes(_b);
        uint minLength = a.length;
        if (b.length < minLength) minLength = b.length;
        for (uint i = 0; i < minLength; i ++)
            if (a[i] < b[i])
                return -1;
            else if (a[i] > b[i])
                return 1;
        if (a.length < b.length)
            return -1;
        else if (a.length > b.length)
            return 1;
        else
            return 0;
    }

    function indexOf(string _haystack, string _needle) internal returns (int) {
        bytes memory h = bytes(_haystack);
        bytes memory n = bytes(_needle);
        if(h.length < 1 || n.length < 1 || (n.length > h.length))
            return -1;
        else if(h.length > (2**128 -1))
            return -1;
        else
        {
            uint subindex = 0;
            for (uint i = 0; i < h.length; i ++)
            {
                if (h[i] == n[0])
                {
                    subindex = 1;
                    while(subindex < n.length && (i + subindex) < h.length && h[i + subindex] == n[subindex])
                    {
                        subindex++;
                    }
                    if(subindex == n.length)
                        return int(i);
                }
            }
            return -1;
        }
    }

    function strConcat(string _a, string _b, string _c, string _d, string _e) internal returns (string) {
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        bytes memory _bc = bytes(_c);
        bytes memory _bd = bytes(_d);
        bytes memory _be = bytes(_e);
        string memory abcde = new string(_ba.length + _bb.length + _bc.length + _bd.length + _be.length);
        bytes memory babcde = bytes(abcde);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++) babcde[k++] = _ba[i];
        for (i = 0; i < _bb.length; i++) babcde[k++] = _bb[i];
        for (i = 0; i < _bc.length; i++) babcde[k++] = _bc[i];
        for (i = 0; i < _bd.length; i++) babcde[k++] = _bd[i];
        for (i = 0; i < _be.length; i++) babcde[k++] = _be[i];
        return string(babcde);
    }

    function strConcat(string _a, string _b, string _c, string _d) internal returns (string) {
        return strConcat(_a, _b, _c, _d, "");
    }

    function strConcat(string _a, string _b, string _c) internal returns (string) {
        return strConcat(_a, _b, _c, "", "");
    }

    function strConcat(string _a, string _b) internal returns (string) {
        return strConcat(_a, _b, "", "", "");
    }

     
    function parseInt(string _a) internal returns (uint) {
        return parseInt(_a, 0);
    }

     
    function parseInt(string _a, uint _b) internal returns (uint) {
        bytes memory bresult = bytes(_a);
        uint mint = 0;
        bool decimals = false;
        for (uint i=0; i<bresult.length; i++){
            if ((bresult[i] >= 48)&&(bresult[i] <= 57)){
                if (decimals){
                   if (_b == 0) break;
                    else _b--;
                }
                mint *= 10;
                mint += uint(bresult[i]) - 48;
            } else if (bresult[i] == 46) decimals = true;
        }
        if (_b > 0) mint *= 10**_b;
        return mint;
    }

    function uint2str(uint i) internal returns (string){
        if (i == 0) return "0";
        uint j = i;
        uint len;
        while (j != 0){
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (i != 0){
            bstr[k--] = byte(48 + i % 10);
            i /= 10;
        }
        return string(bstr);
    }

    using CBOR for Buffer.buffer;
    function stra2cbor(string[] arr) internal constant returns (bytes) {
        Buffer.buffer memory buf;
        Buffer.init(buf, 1024);
        buf.startArray();
        for (uint i = 0; i < arr.length; i++) {
            buf.encodeString(arr[i]);
        }
        buf.endSequence();
        return buf.buf;
    }

    function ba2cbor(bytes[] arr) internal constant returns (bytes) {
        Buffer.buffer memory buf;
        Buffer.init(buf, 1024);
        buf.startArray();
        for (uint i = 0; i < arr.length; i++) {
            buf.encodeBytes(arr[i]);
        }
        buf.endSequence();
        return buf.buf;
    }

    string oraclize_network_name;
    function oraclize_setNetworkName(string _network_name) internal {
        oraclize_network_name = _network_name;
    }

    function oraclize_getNetworkName() internal returns (string) {
        return oraclize_network_name;
    }

    function oraclize_newRandomDSQuery(uint _delay, uint _nbytes, uint _customGasLimit) internal returns (bytes32){
        if ((_nbytes == 0)||(_nbytes > 32)) throw;
	 
        _delay *= 10;
        bytes memory nbytes = new bytes(1);
        nbytes[0] = byte(_nbytes);
        bytes memory unonce = new bytes(32);
        bytes memory sessionKeyHash = new bytes(32);
        bytes32 sessionKeyHash_bytes32 = oraclize_randomDS_getSessionPubKeyHash();
        assembly {
            mstore(unonce, 0x20)
             
             
             
            mstore(add(unonce, 0x20), xor(blockhash(sub(number, 1)), xor(coinbase, timestamp)))
            mstore(sessionKeyHash, 0x20)
            mstore(add(sessionKeyHash, 0x20), sessionKeyHash_bytes32)
        }
        bytes memory delay = new bytes(32);
        assembly {
            mstore(add(delay, 0x20), _delay)
        }

        bytes memory delay_bytes8 = new bytes(8);
        copyBytes(delay, 24, 8, delay_bytes8, 0);

        bytes[4] memory args = [unonce, nbytes, sessionKeyHash, delay];
        bytes32 queryId = oraclize_query("random", args, _customGasLimit);

        bytes memory delay_bytes8_left = new bytes(8);

        assembly {
            let x := mload(add(delay_bytes8, 0x20))
            mstore8(add(delay_bytes8_left, 0x27), div(x, 0x100000000000000000000000000000000000000000000000000000000000000))
            mstore8(add(delay_bytes8_left, 0x26), div(x, 0x1000000000000000000000000000000000000000000000000000000000000))
            mstore8(add(delay_bytes8_left, 0x25), div(x, 0x10000000000000000000000000000000000000000000000000000000000))
            mstore8(add(delay_bytes8_left, 0x24), div(x, 0x100000000000000000000000000000000000000000000000000000000))
            mstore8(add(delay_bytes8_left, 0x23), div(x, 0x1000000000000000000000000000000000000000000000000000000))
            mstore8(add(delay_bytes8_left, 0x22), div(x, 0x10000000000000000000000000000000000000000000000000000))
            mstore8(add(delay_bytes8_left, 0x21), div(x, 0x100000000000000000000000000000000000000000000000000))
            mstore8(add(delay_bytes8_left, 0x20), div(x, 0x1000000000000000000000000000000000000000000000000))

        }

        oraclize_randomDS_setCommitment(queryId, sha3(delay_bytes8_left, args[1], sha256(args[0]), args[2]));
        return queryId;
    }

    function oraclize_randomDS_setCommitment(bytes32 queryId, bytes32 commitment) internal {
        oraclize_randomDS_args[queryId] = commitment;
    }

    mapping(bytes32=>bytes32) oraclize_randomDS_args;
    mapping(bytes32=>bool) oraclize_randomDS_sessionKeysHashVerified;

    function verifySig(bytes32 tosignh, bytes dersig, bytes pubkey) internal returns (bool){
        bool sigok;
        address signer;

        bytes32 sigr;
        bytes32 sigs;

        bytes memory sigr_ = new bytes(32);
        uint offset = 4+(uint(dersig[3]) - 0x20);
        sigr_ = copyBytes(dersig, offset, 32, sigr_, 0);
        bytes memory sigs_ = new bytes(32);
        offset += 32 + 2;
        sigs_ = copyBytes(dersig, offset+(uint(dersig[offset-1]) - 0x20), 32, sigs_, 0);

        assembly {
            sigr := mload(add(sigr_, 32))
            sigs := mload(add(sigs_, 32))
        }


        (sigok, signer) = safer_ecrecover(tosignh, 27, sigr, sigs);
        if (address(sha3(pubkey)) == signer) return true;
        else {
            (sigok, signer) = safer_ecrecover(tosignh, 28, sigr, sigs);
            return (address(sha3(pubkey)) == signer);
        }
    }

    function oraclize_randomDS_proofVerify__sessionKeyValidity(bytes proof, uint sig2offset) internal returns (bool) {
        bool sigok;

         
        bytes memory sig2 = new bytes(uint(proof[sig2offset+1])+2);
        copyBytes(proof, sig2offset, sig2.length, sig2, 0);

        bytes memory appkey1_pubkey = new bytes(64);
        copyBytes(proof, 3+1, 64, appkey1_pubkey, 0);

        bytes memory tosign2 = new bytes(1+65+32);
        tosign2[0] = 1;  
        copyBytes(proof, sig2offset-65, 65, tosign2, 1);
        bytes memory CODEHASH = hex"fd94fa71bc0ba10d39d464d0d8f465efeef0a2764e3887fcc9df41ded20f505c";
        copyBytes(CODEHASH, 0, 32, tosign2, 1+65);
        sigok = verifySig(sha256(tosign2), sig2, appkey1_pubkey);

        if (sigok == false) return false;


         
        bytes memory LEDGERKEY = hex"7fb956469c5c9b89840d55b43537e66a98dd4811ea0a27224272c2e5622911e8537a2f8e86a46baec82864e98dd01e9ccc2f8bc5dfc9cbe5a91a290498dd96e4";

        bytes memory tosign3 = new bytes(1+65);
        tosign3[0] = 0xFE;
        copyBytes(proof, 3, 65, tosign3, 1);

        bytes memory sig3 = new bytes(uint(proof[3+65+1])+2);
        copyBytes(proof, 3+65, sig3.length, sig3, 0);

        sigok = verifySig(sha256(tosign3), sig3, LEDGERKEY);

        return sigok;
    }

    modifier oraclize_randomDS_proofVerify(bytes32 _queryId, string _result, bytes _proof) {
         
        if ((_proof[0] != "L")||(_proof[1] != "P")||(_proof[2] != 1)) throw;

        bool proofVerified = oraclize_randomDS_proofVerify__main(_proof, _queryId, bytes(_result), oraclize_getNetworkName());
        if (proofVerified == false) throw;

        _;
    }

    function oraclize_randomDS_proofVerify__returnCode(bytes32 _queryId, string _result, bytes _proof) internal returns (uint8){
         
        if ((_proof[0] != "L")||(_proof[1] != "P")||(_proof[2] != 1)) return 1;

        bool proofVerified = oraclize_randomDS_proofVerify__main(_proof, _queryId, bytes(_result), oraclize_getNetworkName());
        if (proofVerified == false) return 2;

        return 0;
    }

    function matchBytes32Prefix(bytes32 content, bytes prefix, uint n_random_bytes) internal returns (bool){
        bool match_ = true;

	if (prefix.length != n_random_bytes) throw;

        for (uint256 i=0; i< n_random_bytes; i++) {
            if (content[i] != prefix[i]) match_ = false;
        }

        return match_;
    }

    function oraclize_randomDS_proofVerify__main(bytes proof, bytes32 queryId, bytes result, string context_name) internal returns (bool){

         
        uint ledgerProofLength = 3+65+(uint(proof[3+65+1])+2)+32;
        bytes memory keyhash = new bytes(32);
        copyBytes(proof, ledgerProofLength, 32, keyhash, 0);
        if (!(sha3(keyhash) == sha3(sha256(context_name, queryId)))) return false;

        bytes memory sig1 = new bytes(uint(proof[ledgerProofLength+(32+8+1+32)+1])+2);
        copyBytes(proof, ledgerProofLength+(32+8+1+32), sig1.length, sig1, 0);

         
        if (!matchBytes32Prefix(sha256(sig1), result, uint(proof[ledgerProofLength+32+8]))) return false;

         
         
        bytes memory commitmentSlice1 = new bytes(8+1+32);
        copyBytes(proof, ledgerProofLength+32, 8+1+32, commitmentSlice1, 0);

        bytes memory sessionPubkey = new bytes(64);
        uint sig2offset = ledgerProofLength+32+(8+1+32)+sig1.length+65;
        copyBytes(proof, sig2offset-64, 64, sessionPubkey, 0);

        bytes32 sessionPubkeyHash = sha256(sessionPubkey);
        if (oraclize_randomDS_args[queryId] == sha3(commitmentSlice1, sessionPubkeyHash)){  
            delete oraclize_randomDS_args[queryId];
        } else return false;


         
        bytes memory tosign1 = new bytes(32+8+1+32);
        copyBytes(proof, ledgerProofLength, 32+8+1+32, tosign1, 0);
        if (!verifySig(sha256(tosign1), sig1, sessionPubkey)) return false;

         
        if (oraclize_randomDS_sessionKeysHashVerified[sessionPubkeyHash] == false){
            oraclize_randomDS_sessionKeysHashVerified[sessionPubkeyHash] = oraclize_randomDS_proofVerify__sessionKeyValidity(proof, sig2offset);
        }

        return oraclize_randomDS_sessionKeysHashVerified[sessionPubkeyHash];
    }


     
    function copyBytes(bytes from, uint fromOffset, uint length, bytes to, uint toOffset) internal returns (bytes) {
        uint minLength = length + toOffset;

        if (to.length < minLength) {
             
            throw;  
        }

         
        uint i = 32 + fromOffset;
        uint j = 32 + toOffset;

        while (i < (32 + fromOffset + length)) {
            assembly {
                let tmp := mload(add(from, i))
                mstore(add(to, j), tmp)
            }
            i += 32;
            j += 32;
        }

        return to;
    }

     
     
    function safer_ecrecover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal returns (bool, address) {
         
         
         
         
         

         
        bool ret;
        address addr;

        assembly {
            let size := mload(0x40)
            mstore(size, hash)
            mstore(add(size, 32), v)
            mstore(add(size, 64), r)
            mstore(add(size, 96), s)

             
             
            ret := call(3000, 1, 0, size, 128, size, 32)
            addr := mload(size)
        }

        return (ret, addr);
    }

     
    function ecrecovery(bytes32 hash, bytes sig) internal returns (bool, address) {
        bytes32 r;
        bytes32 s;
        uint8 v;

        if (sig.length != 65)
          return (false, 0);

         
         
         
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))

             
             
             
            v := byte(0, mload(add(sig, 96)))

             
             
             
             
        }

         
         
         
         
         
        if (v < 27)
          v += 27;

        if (v != 27 && v != 28)
            return (false, 0);

        return safer_ecrecover(hash, v, r, s);
    }

}

contract Ethertify is usingOraclize {
  EntityLib.Data ed;
  CertsLib.Data cd;

   
  function Ethertify() public {
    ed.nEntities = 0;
    cd.nCerts = 0;
  }

   

  
  modifier isOraclize() {
    require (msg.sender == oraclize_cbAddress());
    _;
  }

   

   
  function createSigningEntity(string entityHash, bytes32 urlHash, uint expirationDate, uint renewalPeriod) public returns (uint) {
    uint entityId = ++ed.nEntities;
    EntityLib.create(ed, entityId, entityHash, urlHash, expirationDate, renewalPeriod);      
    return entityId;
  }

   
  function setExpiration(uint entityId, uint expirationDate, string url, uint oraclizeGas, uint oraclizeGasPrice) public payable returns (bytes32) {
    EntityLib.setExpiration(ed, entityId, expirationDate);
    return validateSigningEntity(entityId, url, oraclizeGas, oraclizeGasPrice);
  }
  
   
  function setRenewalPeriod (uint entityId, uint renewalPeriod) public {
    EntityLib.setRenewalPeriod(ed, entityId, renewalPeriod);
  }


   
  function validateSigningEntity(uint entityId, string url, uint oraclizeGas, uint oraclizeGasPrice) public payable returns (bytes32) {
    uint maxGas = oraclizeGas == 0 ? 88000 : oraclizeGas;  
    
    if (EntityLib.canValidateSigningEntity(ed, entityId, url)) {
      oraclize_setCustomGasPrice(oraclizeGasPrice);
      uint queryCost = oraclize_getPrice("URL", maxGas);
      if (queryCost > msg.value) {
        OraclizeNotEnoughFunds(entityId, queryCost);
        return 0;
      }

      string memory query = strConcat("html(", url, ").xpath(/html/head/meta[@name='ethertify-entity']/@content)");
      bytes32 queryId = oraclize_query("URL", query, maxGas);
      ed.entityIds[queryId] = entityId;
      EntityLib.setOraclizeQueryId(ed, entityId, queryId);
      return queryId;
    }
  }

   
  function updateEntityData(uint entityId, string entityHash, bytes32 urlHash, string url, uint oraclizeGas, uint oraclizeGasPrice) public payable {
    EntityLib.updateEntityData(ed, entityId, entityHash, urlHash);
    validateSigningEntity(entityId, url, oraclizeGas, oraclizeGasPrice);
  }

   
  function updateSignerData(uint[] entityIds, string signerDataHash) public {
    EntityLib.updateSignerData(ed, entityIds, signerDataHash);
  }

   
  function acceptSignerUpdate(uint entityId, address signerAddress, string signerDataHash) public {
    EntityLib.acceptSignerUpdate(ed, entityId, signerAddress, signerDataHash);
  }

   
  function requestRenewal(uint entityId, string url, uint oraclizeGas, uint oraclizeGasPrice) public payable returns (bytes32) {
    if (EntityLib.canRenew(ed, entityId, url)) {
      ed.entities[entityId].status = 4;
      return validateSigningEntity(entityId, url, oraclizeGas, oraclizeGasPrice); 
    }
  }

   
  function closeEntity(uint entityId) public {
    EntityLib.closeEntity(ed, entityId);
  }
  
   
  function __callback(bytes32 queryId, string result) isOraclize() public {
    EntityLib.processValidation(ed, queryId, result);
  }

   
  function registerSigner(uint entityId, address signerAddress, string signerDataHash) public {
    EntityLib.registerSigner(ed, entityId, signerAddress, signerDataHash);
  }

   
  function removeSigner(uint entityId, address signerAddress) public {
    EntityLib.removeSigner(ed, entityId, signerAddress);
  }

   
  function leaveEntity(uint entityId) public {
    EntityLib.leaveEntity(ed, entityId);
  }

   
  function confirmSignerRegistration(uint entityId, string signerDataHash) public {
    EntityLib.confirmSignerRegistration(ed, entityId, signerDataHash);
  }

   

   
  function createPOECertificate(bytes32 dataHash, bytes32 certHash, string ipfsDataHash, string ipfsCertHash) public returns (uint) {
    return CertsLib.createPOECertificate(cd, dataHash, certHash, ipfsDataHash, ipfsCertHash);
  }
  
   
  function createCertificate(bytes32 dataHash, bytes32 certHash, string ipfsDataHash, string ipfsCertHash, uint entityId) public returns (uint) {
    return CertsLib.createCertificate(cd, ed, dataHash, certHash, ipfsDataHash, ipfsCertHash, entityId);
  }

   
  function requestCertificateTransferToPeer(uint certificateId, address newOwner) public {
    return CertsLib.requestCertificateTransferToPeer(cd, ed, certificateId, newOwner);
  }

   
  function requestCertificateTransferToEntity(uint certificateId, uint newEntityId) public {
    return CertsLib.requestCertificateTransferToEntity(cd, ed, certificateId, newEntityId);
  }

   
  function acceptCertificateTransfer(uint certificateId) public {
    return CertsLib.acceptCertificateTransfer(cd, ed, certificateId);
  }

   
  function cancelCertificateTransfer(uint certificateId) public {
    return CertsLib.cancelCertificateTransfer(cd, ed, certificateId);
  }

   
  function setIPFSData(uint certId, string ipfsDataHash, string ipfsCertHash) public {
    CertsLib.setIPFSData(cd, certId, ipfsDataHash, ipfsCertHash);
  }
  
   

   
  function requestSignatureToEntity(uint certificateId, uint entityId) public {
    SignLib.requestSignatureToEntity(ed, cd, certificateId, entityId);
  }

   
  function requestSignatureToPeer(uint certificateId, address peer) public {
    SignLib.requestSignatureToPeer(ed, cd, certificateId, peer);
  }

   
  function signCertificateAsEntity(uint entityId, uint certificateId, uint expiration, bytes32 purpose) public {
    SignLib.signCertificateAsEntity(ed, cd, entityId, certificateId, expiration, purpose);
  }

   
  function signCertificateAsPeer(uint certificateId, uint expiration, bytes32 purpose) public {
    SignLib.signCertificateAsPeer(cd, certificateId, expiration, purpose);
  }

   
   
  function internalState() constant public returns (uint numEntities, uint numCertificates) {
    return (
      ed.nEntities,
      cd.nCerts
    );
  }

   
  function getSigningEntityInfo(uint entityId) constant public returns (address owner, string dataHash, uint status, bytes32 urlHash, uint expiration, uint renewalPeriod, uint numSigners) {
    return (
      ed.entities[entityId].owner,
      ed.entities[entityId].dataHash,
      ed.entities[entityId].status,
      ed.entities[entityId].urlHash,
      ed.entities[entityId].expiration,
      ed.entities[entityId].renewalPeriod,
      ed.entities[entityId].signersArr.length
    );
  }

   
  function getOraclizeQuery(uint entityId) constant public returns (bytes32 oraclizeQueryId) {
    return ed.entities[entityId].oraclizeQueryId;
  }

     
  function getSignerData(uint entityId, address signerAddress, uint index) constant public returns (address signer, uint status, string ipfsMultiHash) {
    uint s = 0;
    string memory h = "";
    
    if (signerAddress != 0) {      
      s = ed.entities[entityId].signers[signerAddress].status;
      h = ed.entities[entityId].signers[signerAddress].signerDataHash;
    } else if (signerAddress == 0 && index < ed.entities[entityId].signersArr.length) {
      signerAddress = ed.entities[entityId].signersArr[index];
      s = ed.entities[entityId].signers[signerAddress].status;
      h = ed.entities[entityId].signers[signerAddress].signerDataHash;
    }

    return (signerAddress, s, h);
  }

   
  function getCertificateInfo(uint certificateId) constant public returns (address owner, uint entityId, bytes32 certHash, string ipfsCertHash, bytes32 dataHash, string ipfsDataHash, uint numEntitySignatures, uint numPeerSignatures, address newOwnerTransferRequest, uint newEntityTransferRequest) {
    CertsLib.CertData storage cert = cd.certificates[certificateId];
    CertsLib.TransferData storage req = cd.transferRequests[certificateId];
    return (
      cert.owner,
      cert.entityId,
      cert.certHash,
      cert.ipfsCertHash,
      cert.dataHash,
      cert.ipfsDataHash,
      cert.entitiesArr.length,
      cert.signaturesArr.length,
      req.newOwner,
      req.newEntityId
    );
  }

   
  function getEntitySignatureInfoFromCertificate(uint certificateId, uint entityId, uint entityIndex) constant public returns (uint id, bytes32 status, uint expiration) {
    bytes32 s = 0x0;
    uint e = 0;
    if (entityId != 0 ) {
      s = cd.certificates[certificateId].entities[entityId].status;
      e = cd.certificates[certificateId].entities[entityId].exp;
    } else if (entityId == 0) {
      entityId = cd.certificates[certificateId].entitiesArr[entityIndex];
      s = cd.certificates[certificateId].entities[entityId].status;
      e = cd.certificates[certificateId].entities[entityId].exp;
    } else {
      entityId = 0;
    }   
    return (entityId, s, e);
  }

     
  function getPeerSignatureInfoFromCertificate(uint certificateId, address peerAddress, uint peerIndex) constant public returns (address addr, bytes32 status, uint expiration) {
    bytes32 s = 0x0;
    uint e = 0;
    if (peerAddress != 0) {
      s = cd.certificates[certificateId].signatures[peerAddress].status;
      e = cd.certificates[certificateId].signatures[peerAddress].exp;
    } else if (peerAddress == 0) {
      peerAddress = cd.certificates[certificateId].signaturesArr[peerIndex];
      s = cd.certificates[certificateId].signatures[peerAddress].status;
      e = cd.certificates[certificateId].signatures[peerAddress].exp;
    }
    return (peerAddress, s, e);
  }

   
  event EntityCreated(uint indexed entityId);
  event EntityValidated(uint indexed entityId);
  event EntityDataUpdated(uint indexed entityId);
  event EntityInvalid(uint indexed entityId);
  event SignerAdded(uint indexed entityId, address indexed signerAddress);
  event SignerDataUpdated(uint[] entities, address indexed signerAddress);
  event SignerUpdateAccepted(uint indexed entityId, address indexed signerAddress);
  event SignerRemoved(uint indexed entityId, address signerAddress);
  event EntityClosed(uint indexed entityId);
  event SignerConfirmed(uint indexed entityId, address signerAddress);
  event EntityExpirationSet(uint indexed entityId);
  event EntityRenewalSet(uint indexed entityId);

  event POECertificate(uint indexed certificateId);
  event Certificate(uint indexed certificateId);
  event CertificateTransferRequestedToPeer(uint indexed certificateId, address newOwner);
  event CertificateTransferRequestedToEntity(uint indexed certificateId, uint newEntityId);
  event CertificateTransferAccepted(uint indexed certificateId, address newOwner, uint newEntityId);
  event CertificateTransferCancelled(uint indexed certificateId);

  event EntitySignatureRequested(uint indexed certificateId, uint indexed entityId);
  event PeerSignatureRequested(uint indexed certificateId, address indexed signerAddress);
  event CertificateSignedByEntity(uint indexed certificateId, uint indexed entityId, address indexed signerAddress);
  event CertificateSignedByPeer(uint indexed certificateId, address indexed signerAddress);

  event OraclizeNotEnoughFunds(uint indexed entityId, uint queryCost);
 }
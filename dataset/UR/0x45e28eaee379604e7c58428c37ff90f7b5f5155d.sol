 

 

pragma solidity 0.4.24;

 
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

   
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

   
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

library CertificateLibrary {
    struct Document {
        bytes ipfsHash;
        bytes32 transcriptHash;
        bytes32 contentHash;
    }
    
     
    function addCertification(Document storage self, bytes32 _contentHash, bytes _ipfsHash, bytes32 _transcriptHash) public {
        self.ipfsHash = _ipfsHash;
        self.contentHash= _contentHash;
        self.transcriptHash = _transcriptHash;
    }
    
     
    function validate(Document storage self, bytes _ipfsHash, bytes32 _contentHash, bytes32 _transcriptHash) public view returns(bool) {
        bytes storage ipfsHash = self.ipfsHash;
        bytes32 contentHash = self.contentHash;
        bytes32 transcriptHash = self.transcriptHash;
        return contentHash == _contentHash && keccak256(ipfsHash) == keccak256(_ipfsHash) && transcriptHash == _transcriptHash;
    }
    
     
    function validateIpfsDoc(Document storage self, bytes _ipfsHash) public view returns(bool) {
        bytes storage ipfsHash = self.ipfsHash;
        return keccak256(ipfsHash) == keccak256(_ipfsHash);
    }
    
     
    function validateContentHash(Document storage self, bytes32 _contentHash) public view returns(bool) {
        bytes32 contentHash = self.contentHash;
        return contentHash == _contentHash;
    }
    
     
    function validateTranscriptHash(Document storage self, bytes32 _transcriptHash) public view returns(bool) {
        bytes32 transcriptHash = self.transcriptHash;
        return transcriptHash == _transcriptHash;
    }
}

contract Certificate is Ownable {
    
    using CertificateLibrary for CertificateLibrary.Document;
    
    struct Certification {
        mapping (uint => CertificateLibrary.Document) documents;
        uint16 indx;
    }
    
    mapping (address => Certification) studentCertifications;
    
    event CertificationAdded(address userAddress, uint docIndx);
    
     
    function addCertification(address _student, bytes32 _contentHash, bytes _ipfsHash, bytes32 _transcriptHash) public onlyOwner {
        uint currIndx = studentCertifications[_student].indx;
        (studentCertifications[_student].documents[currIndx]).addCertification(_contentHash, _ipfsHash, _transcriptHash);
        studentCertifications[_student].indx++;
        emit CertificationAdded(_student, currIndx);
    }
    
     
    function validate(address _student, uint _docIndx, bytes32 _contentHash, bytes _ipfsHash, bytes32 _transcriptHash) public view returns(bool) {
        Certification storage certification  = studentCertifications[_student];
        return (certification.documents[_docIndx]).validate(_ipfsHash, _contentHash, _transcriptHash);
    }
    
     
    function validateIpfsDoc(address _student, uint _docIndx, bytes _ipfsHash) public view returns(bool) {
        Certification storage certification  = studentCertifications[_student];
        return (certification.documents[_docIndx]).validateIpfsDoc(_ipfsHash);
    }
    
     
    function validateContentHash(address _student, uint _docIndx, bytes32 _contentHash) public view returns(bool) {
        Certification storage certification  = studentCertifications[_student];
        return (certification.documents[_docIndx]).validateContentHash(_contentHash);
    }
    
     
    function validateTranscriptHash(address _student, uint _docIndx, bytes32 _transcriptHash) public view returns(bool) {
        Certification storage certification  = studentCertifications[_student];
        return (certification.documents[_docIndx]).validateTranscriptHash(_transcriptHash);
    }
    
     
    function getCertifiedDocCount(address _student) public view returns(uint256) {
        return studentCertifications[_student].indx;
    }
    
     
    function getCertificationDocument(address _student, uint _docIndx) public view onlyOwner returns (bytes, bytes32, bytes32) {
        return ((studentCertifications[_student].documents[_docIndx]).ipfsHash, (studentCertifications[_student].documents[_docIndx]).contentHash, (studentCertifications[_student].documents[_docIndx]).transcriptHash);
    }
    
     
    function transferAll(address _studentAddrOld, address _studentAddrNew) public onlyOwner {
        studentCertifications[_studentAddrNew] = studentCertifications[_studentAddrOld];
        delete studentCertifications[_studentAddrOld];
    }
    
     
    function transferDoc(uint docIndx, address _studentAddrOld, address _studentAddrNew) public onlyOwner {
        studentCertifications[_studentAddrNew].documents[docIndx] = studentCertifications[_studentAddrOld].documents[docIndx];
        delete studentCertifications[_studentAddrOld].documents[docIndx];
    }
}
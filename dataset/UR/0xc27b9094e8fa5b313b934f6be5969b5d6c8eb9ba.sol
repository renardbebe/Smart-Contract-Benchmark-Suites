 

pragma solidity ^0.4.18;

 

contract Certification  {

   
  address public certifierAddress;

  string public CompanyName;
  string public Norm;
  string public CertID;
  string public issued;
  string public expires;
  string public Scope;
  string public issuingBody;

   
  function Certification(string _CompanyName,
      string _Norm,
      string _CertID,
      string _issued,
      string _expires,
      string _Scope,
      string _issuingBody) public {

      certifierAddress = msg.sender;

      CompanyName = _CompanyName;
      Norm =_Norm;
      CertID = _CertID;
      issued = _issued;
      expires = _expires;
      Scope = _Scope;
      issuingBody = _issuingBody;
  }

   
  function deleteCertificate() public {
      require(msg.sender == certifierAddress);
      selfdestruct(tx.origin);
  }

}

 

 
contract Certifier {

     
    mapping (bytes32 => address) public CertificateAddresses;

     
    mapping (address => bool) public CertAdmins;

     
    address public GlobalAdmin;

    event CertificationSet(string _certID, address _certAdrress, uint setTime);
    event CertificationDeleted(string _certID, address _certAdrress, uint delTime);
    event CertAdminAdded(address _certAdmin);
    event CertAdminDeleted(address _certAdmin);
    event GlobalAdminChanged(address _globalAdmin);



     
    function Certifier() public {
        GlobalAdmin = msg.sender;
    }

     

     
    function setCertificate(string _CompanyName,
                            string _Norm,
                            string _CertID,
                            string _issued,
                            string _expires,
                            string _Scope,
                            string _issuingBody) public onlyCertAdmin {
        bytes32 certKey = getCertKey(_CertID);

        CertificateAddresses[certKey] = new Certification(_CompanyName,
                                                               _Norm,
                                                               _CertID,
                                                               _issued,
                                                               _expires,
                                                               _Scope,
                                                               _issuingBody);
        CertificationSet(_CertID, CertificateAddresses[certKey], now);
    }

     
    function delCertificate(string _CertID) public onlyCertAdmin {
        bytes32 certKey = getCertKey(_CertID);

        Certification(CertificateAddresses[certKey]).deleteCertificate();
        CertificationDeleted(_CertID, CertificateAddresses[certKey], now);
        delete CertificateAddresses[certKey];
    }

     
    function addCertAdmin(address _CertAdmin) public onlyGlobalAdmin {
        CertAdmins[_CertAdmin] = true;
        CertAdminAdded(_CertAdmin);
    }

     
    function delCertAdmin(address _CertAdmin) public onlyGlobalAdmin {
        delete CertAdmins[_CertAdmin];
        CertAdminDeleted(_CertAdmin);
    }
     
    function changeGlobalAdmin(address _GlobalAdmin) public onlyGlobalAdmin {
        GlobalAdmin=_GlobalAdmin;
        GlobalAdminChanged(_GlobalAdmin);

    }

     

     
    function getCertAddressByID(string _CertID) public constant returns (address) {
        return CertificateAddresses[getCertKey(_CertID)];
    }

     
    function getCertKey(string _CertID) public pure returns (bytes32) {
        return sha256(_CertID);
    }


     

     
    modifier onlyGlobalAdmin () {
        require(msg.sender==GlobalAdmin);
        _;
    }

     
    modifier onlyCertAdmin () {
        require(CertAdmins[msg.sender]);
        _;
    }

}
 
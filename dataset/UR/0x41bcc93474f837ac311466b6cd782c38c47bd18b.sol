 

pragma solidity ^0.4.13;

contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract Certificate is Ownable {

  event LogAddCertificateAuthority(address indexed ca_address);
  event LogRemoveCertificateAuthority(address indexed ca_address);
  event LogAddCertificate(address indexed ca_address, bytes32 certificate_hash);
  event LogRevokeCertificate(address indexed ca_address, bytes32 certificate_hash);
  event LogBindCertificate2Wallet(address indexed ca_address, bytes32 certificate_hash, address indexed wallet);

  struct CertificateAuthority {
    string lookup_api;
    string organization;
    string common_name;
    string country;
    string province;
    string locality;
  }

  struct CertificateMeta {
    address ca_address;
    uint256 expires;
    bytes32 sealed_hash;
    bytes32 certificate_hash;
  }

   
  mapping(address => CertificateAuthority) private certificate_authority;

   
  mapping(address => mapping(address => bytes32)) private wallet_authority_certificate;

   
  mapping(bytes32 => CertificateMeta) private certificates;

  modifier onlyCA() {
    require(bytes(certificate_authority[msg.sender].lookup_api).length != 0);
    _;
  }

   
   
   
   
   
   
   
   
  function addCA(
    address ca_address,
    string lookup_api,
    string organization,
    string common_name,
    string country,
    string province,
    string locality
  ) public onlyOwner {
    require (ca_address != 0x0);
    require (ca_address != msg.sender);
    require (bytes(lookup_api).length != 0);
    require (bytes(organization).length > 3);
    require (bytes(common_name).length > 3);
    require (bytes(country).length > 1);

    certificate_authority[ca_address] = CertificateAuthority(
      lookup_api,
      organization,
      common_name,
      country,
      province,
      locality
    );
    LogAddCertificateAuthority(ca_address);
  }

   
   
  function removeCA(address ca_address) public onlyOwner {
    delete certificate_authority[ca_address];
    LogRemoveCertificateAuthority(ca_address);
  }

   
   
   
  function isCA(address ca_address) public view returns (bool) {
    return bytes(certificate_authority[ca_address].lookup_api).length != 0;
  }

   
   
   
  function getCA(address ca_address) public view returns (string, string, string, string, string, string) {
    CertificateAuthority storage ca = certificate_authority[ca_address];
    return (ca.lookup_api, ca.organization, ca.common_name, ca.country, ca.province, ca.locality);
  }

   
   
   
   
  function addNewCertificate(uint256 expires, bytes32 sealed_hash, bytes32 certificate_hash) public onlyCA {
    require(expires > now);

    CertificateMeta storage cert = certificates[certificate_hash];
    require(cert.expires == 0);

    certificates[certificate_hash] = CertificateMeta(msg.sender, expires, sealed_hash, certificate_hash);
    LogAddCertificate(msg.sender, certificate_hash);
  }

   
   
   
   
   
  function addCertificateAndBind2Wallet(address wallet, uint256 expires, bytes32 sealed_hash, bytes32 certificate_hash) public onlyCA {
    require(expires > now);

    CertificateMeta storage cert = certificates[certificate_hash];
    require(cert.expires == 0);

    certificates[certificate_hash] = CertificateMeta(msg.sender, expires, sealed_hash, certificate_hash);
    LogAddCertificate(msg.sender, certificate_hash);
    wallet_authority_certificate[wallet][msg.sender] = certificate_hash;
    LogBindCertificate2Wallet(msg.sender, certificate_hash, wallet);
  }

   
   
   
  function bindCertificate2Wallet(address wallet, bytes32 certificate_hash) public {
    CertificateMeta storage cert = certificates[certificate_hash];
    require(cert.expires > now);

    bytes32 sender_certificate_hash = wallet_authority_certificate[msg.sender][cert.ca_address];

    require(cert.ca_address == msg.sender || cert.certificate_hash == sender_certificate_hash);

    wallet_authority_certificate[wallet][cert.ca_address] = certificate_hash;
    LogBindCertificate2Wallet(msg.sender, certificate_hash, wallet);
  }

   
   
  function revokeCertificate(bytes32 certificate_hash) public onlyCA {
    CertificateMeta storage cert = certificates[certificate_hash];
    require(cert.ca_address == msg.sender);
    cert.expires = 0;
    LogRevokeCertificate(msg.sender, certificate_hash);
  }

   
   
   
  function getCertificate(bytes32 certificate_hash) public view returns (address, uint256, bytes32, bytes32) {
    CertificateMeta storage cert = certificates[certificate_hash];
    if (isCA(cert.ca_address)) {
      return (cert.ca_address, cert.expires, cert.sealed_hash, cert.certificate_hash);
    } else {
      return (0x0, 0, 0x0, 0x0);
    }
  }

   
   
   
   
  function getCertificateForWallet(address wallet, address ca_address) public view returns (uint256, bytes32, bytes32) {
    bytes32 certificate_hash = wallet_authority_certificate[wallet][ca_address];
    CertificateMeta storage cert = certificates[certificate_hash];
    if (isCA(cert.ca_address)) {
      return (cert.expires, cert.sealed_hash, cert.certificate_hash);
    } else {
      return (0, 0x0, 0x0);
    }
  }
}
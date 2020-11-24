 

pragma solidity ^0.5.0;

 

 
contract IndividualCertification {
    address public registryAddress;
    bytes32 public b0;
    bytes32 public b1;

    constructor(bytes32 _b0, bytes32 _b1)
    public
    {
        registryAddress = msg.sender;
        b0 = _b0;
        b1 = _b1;
    }
    function updateHashValue(bytes32 _b0, bytes32 _b1)
    public
    {
        require(msg.sender == registryAddress);
        b0 = _b0;
        b1 = _b1;
    }

    function hashValue()
    public
    view
    returns (bytes32, bytes32)
    {
        return (b0, b1);
    }

     
    function deleteCertificate() public {
        require(msg.sender == registryAddress);
        selfdestruct(msg.sender);
    }
}

 

 
contract OrganizationalCertification  {

     
    address public registryAddress;

    string public CompanyName;
    string public Norm;
    string public CertID;
    uint public issued;
    uint public expires;
    string public Scope;
    string public issuingBody;

     
    constructor(
        string memory _CompanyName,
        string memory _Norm,
        string memory _CertID,
        uint _issued,
        uint _expires,
        string memory _Scope,
        string memory _issuingBody)
        public
    {
        require(_issued < _expires);

        registryAddress = msg.sender;

        CompanyName = _CompanyName;
        Norm =_Norm;
        CertID = _CertID;
        issued = _issued;
        expires = _expires;
        Scope = _Scope;
        issuingBody = _issuingBody;
    }

     
    function deleteCertificate() public {
        require(msg.sender == registryAddress);
        selfdestruct(tx.origin);
    }

}

 

 

contract CertificationRegistry {

     
    mapping (bytes32 => address) public CertificateAddresses;
    mapping (bytes32 => address) public RosenCertificateAddresses;

     
    mapping (bytes32  => bool) public CertAdmins;

     
    mapping (address => bool) public RosenCertAdmins;

     
    address public GlobalAdmin;


    event CertificationSet(address indexed contractAddress);
    event IndividualCertificationSet(address indexed contractAddress);
    event IndividualCertificationUpdated(address indexed contractAddress);
    event CertificationDeleted(address indexed contractAddress);
    event CertAdminAdded(address indexed account);
    event CertAdminDeleted(address account);
    event GlobalAdminChanged(address indexed account);

     
    constructor() public {
        GlobalAdmin = msg.sender;
    }

     

     
    function setCertificate(
            string memory _CompanyName,
            string memory _Norm,
            string memory _CertID,
            uint _issued,
            uint _expires,
            string memory _Scope,
            string memory _issuingBody
    )
    public
    onlyRosenCertAdmin
    {
        bytes32 certKey = keccak256(abi.encodePacked(_CertID));

        OrganizationalCertification orgCert = new OrganizationalCertification(
            _CompanyName,
            _Norm,
            _CertID,
            _issued,
            _expires,
            _Scope,
            _issuingBody);

        RosenCertificateAddresses[certKey] = address(orgCert);
        emit CertificationSet(address(orgCert));
    }

    function setIndividualCertificate(
            bytes32 b0,
            bytes32 b1,
            string memory _CertID,
            string memory _organizationID)
        public
        onlyPrivilegedCertAdmin(_organizationID)
        entryMustNotExist(_CertID, _organizationID)
    {

        IndividualCertification individualCert = new IndividualCertification(b0, b1);
        CertificateAddresses[toCertificateKey(_CertID, _organizationID)] = address(individualCert);
        emit IndividualCertificationSet(address(individualCert));
    }

    function updateIndividualCertificate(bytes32 b0, bytes32 b1, string memory _CertID, string memory _organizationID)
        public
        onlyPrivilegedCertAdmin(_organizationID)
        duplicatedHashGuard(b0, b1, _CertID, _organizationID)
    {
		address certAddr = CertificateAddresses[toCertificateKey(_CertID,_organizationID)];
        IndividualCertification(certAddr).updateHashValue(b0, b1);
        emit IndividualCertificationUpdated(certAddr);
    }

     
    function delOrganizationCertificate(string memory _CertID)
        public
        onlyRosenCertAdmin
    {
		bytes32 certKey = keccak256(abi.encodePacked(_CertID));
        OrganizationalCertification(RosenCertificateAddresses[certKey]).deleteCertificate();

        emit CertificationDeleted(RosenCertificateAddresses[certKey]);
        delete RosenCertificateAddresses[certKey];
    }
     
    function delIndividualCertificate(
        string memory _CertID,
        string memory _organizationID)
    public
    onlyPrivilegedCertAdmin(_organizationID)
    {
		bytes32 certKey = toCertificateKey(_CertID,_organizationID);
        IndividualCertification(CertificateAddresses[certKey]).deleteCertificate();
        emit CertificationDeleted(CertificateAddresses[certKey]);
        delete CertificateAddresses[certKey];

    }
     
    function addCertAdmin(address _CertAdmin, string memory _organizationID)
        public
        onlyGlobalAdmin
    {
        CertAdmins[toCertAdminKey(_CertAdmin, _organizationID)] = true;
        emit CertAdminAdded(_CertAdmin);
    }

     
    function delCertAdmin(address _CertAdmin, string memory _organizationID)
    public
    onlyGlobalAdmin
    {
        delete CertAdmins[toCertAdminKey(_CertAdmin, _organizationID)];
        emit CertAdminDeleted(_CertAdmin);
    }

     
    function addRosenCertAdmin(address _CertAdmin) public onlyGlobalAdmin {
        RosenCertAdmins[_CertAdmin] = true;
        emit CertAdminAdded(_CertAdmin);
    }

     
    function delRosenCertAdmin(address _CertAdmin) public onlyGlobalAdmin {
        delete RosenCertAdmins[_CertAdmin];
        emit CertAdminDeleted(_CertAdmin);
    }

     
    function changeGlobalAdmin(address _GlobalAdmin) public onlyGlobalAdmin {
        GlobalAdmin=_GlobalAdmin;
        emit GlobalAdminChanged(_GlobalAdmin);

    }

     

     
    function getCertAddressByID(string memory _organizationID, string memory _CertID)
        public
        view
        returns (address)
    {
        return CertificateAddresses[toCertificateKey(_CertID,_organizationID)];
    }

     
    function getOrganizationalCertAddressByID(string memory _CertID)
        public
        view
        returns (address)
    {
        return RosenCertificateAddresses[keccak256(abi.encodePacked(_CertID))];
    }


    function getCertAdminByOrganizationID(address _certAdmin, string memory _organizationID)
        public
        view
        returns (bool)
    {
        return CertAdmins[toCertAdminKey(_certAdmin, _organizationID)];
    }

     
    function toCertificateKey(string memory _CertID, string memory _organizationID)
        public
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(_CertID, _organizationID));
    }


    function toCertAdminKey(address _certAdmin, string memory _organizationID)
        public
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(_certAdmin, _organizationID));
    }


     

     
    modifier onlyGlobalAdmin () {
        require(msg.sender == GlobalAdmin,
		"Access denied, require global admin account");
        _;
    }

     
    modifier onlyPrivilegedCertAdmin(string memory organizationID) {
        require(CertAdmins[toCertAdminKey(msg.sender, organizationID)] || RosenCertAdmins[msg.sender], 
		"Access denied, Please use function with certificate admin privileges");
        _;
    }

    modifier onlyRosenCertAdmin() {
        require(RosenCertAdmins[msg.sender],
        "Access denied, Please use function with certificate admin privileges");
        _;
    }
     
    modifier entryMustNotExist(string memory _CertID, string memory _organizationID) {
        require(CertificateAddresses[toCertificateKey(_CertID, _organizationID)] == address(0),
        "Entry existed exception!");
        _;
    }
    modifier duplicatedHashGuard(
      bytes32 _b0,
      bytes32 _b1,
      string memory _CertID,
      string memory _organizationID) {

        IndividualCertification individualCert = IndividualCertification(CertificateAddresses[toCertificateKey(_CertID, _organizationID)]);
        require(keccak256(abi.encodePacked(_b0, _b1)) != keccak256(abi.encodePacked(individualCert.b0(), individualCert.b1())),
        "Duplicated hash-value exception!");
        _;
    }
}
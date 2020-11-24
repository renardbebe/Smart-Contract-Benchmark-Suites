 

pragma solidity ^0.5.8;

 

 
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
      onlyRegistry
    {
        b0 = _b0;
        b1 = _b1;
    }

    function changeRegistry(address newRegistryAddress)
      public
      onlyRegistry
    {
        registryAddress = newRegistryAddress;
    }

    function hashValue()
      public
      view
    returns (bytes32, bytes32)
    {
        return (b0, b1);
    }
    modifier onlyRegistry() {
        require(msg.sender == registryAddress, "Call invoked from incorrect address");
        _;
    }
     
    function deleteCertificate() public onlyRegistry {
        selfdestruct(msg.sender);
    }
}

 

 
contract OrganizationalCertification  {

     
    address public registryAddress;

    string public CompanyName;
    string public Standard;
    string public CertificateId;
    string public IssueDate;
    string public ExpireDate;
    string public Scope;
    string public CertificationBodyName;

     
    constructor(
        string memory _CompanyName,
        string memory _Standard,
        string memory _CertificateId,
        string memory _IssueDate,
        string memory _ExpireDate,
        string memory _Scope,
        string memory _CertificationBodyName)
        public
    {
        registryAddress = msg.sender;
        CompanyName = _CompanyName;
        Standard = _Standard;
        CertificateId = _CertificateId;
        IssueDate = _IssueDate;
        ExpireDate = _ExpireDate;
        Scope = _Scope;
        CertificationBodyName = _CertificationBodyName;
    }

    function updateCertificate(
        string memory _CompanyName,
        string memory _Standard,
        string memory _IssueDate,
        string memory _ExpireDate,
        string memory _Scope)
        public
        onlyRegistry
    {
        CompanyName = _CompanyName;
        Standard = _Standard;
        IssueDate = _IssueDate;
        ExpireDate = _ExpireDate;
        Scope = _Scope;
    }

    function changeRegistry(address newRegistryAddress)
        public
        onlyRegistry
    {
        registryAddress = newRegistryAddress;
    }

    modifier onlyRegistry() {
        require(msg.sender == registryAddress, "Call invoked from incorrect address");
        _;
    }
     
    function deleteCertificate() public onlyRegistry {
        selfdestruct(msg.sender);
    }

}

 

 

contract CertificationRegistry {

     
    mapping (bytes32 => address) public CertificateAddresses;
    mapping (bytes32 => address) public RosenCertificateAddresses;

     
    mapping (bytes32  => bool) public CertAdmins;

     
    mapping (address => bool) public RosenCertAdmins;

     
    address public GlobalAdmin;


    event OrganizationCertificationSet(address indexed contractAddress);
    event OrganizationCertificationUpdated(address indexed contractAddress);
    event IndividualCertificationSet(address indexed contractAddress);
    event IndividualCertificationUpdated(address indexed contractAddress);
    event CertificationDeleted(address indexed contractAddress);
    event CertAdminAdded(address indexed account);
    event CertAdminDeleted(address account);
    event GlobalAdminChanged(address indexed account);
    event Migration(address indexed newRegistryAddress);
     
    constructor() public {
        GlobalAdmin = msg.sender;
    }

     

     
    function setOrganizationCertificate(
        string memory _OriginalCertificateId,
        string memory _CompanyName,
        string memory _Standard,
        string memory _CertificateId,
        string memory _IssueDate,
        string memory _ExpireDate,
        string memory _Scope,
        string memory _CertificationBodyName
    )
    public
    onlyRosenCertAdmin
    {
        bytes32 certKey = keccak256(abi.encodePacked(_OriginalCertificateId));

        OrganizationalCertification orgCert = new OrganizationalCertification(
            _CompanyName,
            _Standard,
            _CertificateId,
            _IssueDate,
            _ExpireDate,
            _Scope,
            _CertificationBodyName);

        RosenCertificateAddresses[certKey] = address(orgCert);
        emit OrganizationCertificationSet(address(orgCert));
    }

      
    function updateOrganizationCertificate(
        string memory _OriginalCertificateId,
        string memory _CompanyName,
        string memory _Standard,
        string memory _IssueDate,
        string memory _ExpireDate,
        string memory _Scope)
        public
    onlyRosenCertAdmin
    {
        bytes32 certKey = keccak256(abi.encodePacked(_OriginalCertificateId));
        address certAddress = RosenCertificateAddresses[certKey];
        OrganizationalCertification(certAddress).updateCertificate(
            _CompanyName,
            _Standard,
            _IssueDate,
            _ExpireDate,
            _Scope);

        emit OrganizationCertificationUpdated(certAddress);
    }
    function setIndividualCertificate(
        bytes32 b0,
        bytes32 b1,
        string memory _OriginalCertificateId,
        string memory _organizationID)
        public
        onlyPrivilegedCertAdmin(_organizationID)
        entryMustNotExist(_OriginalCertificateId, _organizationID)
    {

        IndividualCertification individualCert = new IndividualCertification(b0, b1);
        CertificateAddresses[toCertificateKey(_OriginalCertificateId, _organizationID)] = address(individualCert);
        emit IndividualCertificationSet(address(individualCert));
    }

    function updateIndividualCertificate(bytes32 b0, bytes32 b1, string memory _OriginalCertificateId, string memory _organizationID)
        public
        onlyPrivilegedCertAdmin(_organizationID)
        duplicatedHashGuard(b0, b1, _OriginalCertificateId, _organizationID)
    {
		address certAddr = CertificateAddresses[toCertificateKey(_OriginalCertificateId, _organizationID)];
        IndividualCertification(certAddr).updateHashValue(b0, b1);
        emit IndividualCertificationUpdated(certAddr);
    }

     
    function delOrganizationCertificate(string memory _OriginalCertificateId)
        public
        onlyRosenCertAdmin
    {
		bytes32 certKey = keccak256(abi.encodePacked(_OriginalCertificateId));
        OrganizationalCertification(RosenCertificateAddresses[certKey]).deleteCertificate();

        emit CertificationDeleted(RosenCertificateAddresses[certKey]);
        delete RosenCertificateAddresses[certKey];
    }
     
    function delIndividualCertificate(
        string memory _OriginalCertificateId,
        string memory _organizationID)
        public
        onlyPrivilegedCertAdmin(_organizationID)
    {
		bytes32 certKey = toCertificateKey(_OriginalCertificateId,_organizationID);
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

     

     
    function getCertAddressByID(string memory _organizationID, string memory _OriginalCertificateId)
        public
        view
        returns (address)
    {
        return CertificateAddresses[toCertificateKey(_OriginalCertificateId, _organizationID)];
    }

     
    function getOrganizationalCertAddressByID(string memory _OriginalCertificateId)
        public
        view
        returns (address)
    {
        return RosenCertificateAddresses[keccak256(abi.encodePacked(_OriginalCertificateId))];
    }


    function getCertAdminByOrganizationID(address _certAdmin, string memory _organizationID)
        public
        view
        returns (bool)
    {
        return CertAdmins[toCertAdminKey(_certAdmin, _organizationID)];
    }

     
    function toCertificateKey(string memory _OriginalCertificateId, string memory _organizationID)
        public
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(_OriginalCertificateId, _organizationID));
    }


    function toCertAdminKey(address _certAdmin, string memory _organizationID)
        public
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(_certAdmin, _organizationID));
    }

     
    function migrateIndividualCertificate(address _newRegistryAddress, string memory _OriginalCertificateId, string memory _organizationID)
        public
        onlyGlobalAdmin
    {
        bytes32 certKey = toCertificateKey(_OriginalCertificateId, _organizationID);
        address certAddress = CertificateAddresses[certKey];
        IndividualCertification(certAddress).changeRegistry(_newRegistryAddress);
        emit Migration(_newRegistryAddress);
    }

     
    function migrateOrganizationCertificate(address _newRegistryAddress, string memory _OriginalCertificateId)
        public
        onlyGlobalAdmin
    {
        bytes32 certKey = keccak256(abi.encodePacked(_OriginalCertificateId));
        address certAddress = RosenCertificateAddresses[certKey];
        IndividualCertification(certAddress).changeRegistry(_newRegistryAddress);
        emit Migration(_newRegistryAddress);
    }

    function updateOrganizationCertMapping(address certAddress, string memory _OriginalCertificateId)
        public
        onlyRosenCertAdmin
    {
        RosenCertificateAddresses[keccak256(abi.encodePacked(_OriginalCertificateId))] = certAddress;
    }

    function updateIndividualCertMapping(address certAddress, string memory _OriginalCertificateId, string memory _organizationID)
        public
        onlyPrivilegedCertAdmin(_organizationID)
    {
        CertificateAddresses[toCertificateKey(_OriginalCertificateId, _organizationID)] = certAddress;
    }

     

     
    modifier onlyGlobalAdmin() {
        require(msg.sender == GlobalAdmin, "Access denied, require global admin account");
        _;
    }

     
    modifier onlyPrivilegedCertAdmin(string memory organizationID) {
        require(CertAdmins[toCertAdminKey(msg.sender, organizationID)] || RosenCertAdmins[msg.sender], 
        "Access denied, Please use function with certificate admin privileges");
        _;
    }

    modifier onlyRosenCertAdmin() {
        require(RosenCertAdmins[msg.sender], "Access denied, Please use function with certificate admin privileges");
        _;
    }
     
    modifier entryMustNotExist(string memory _OriginalCertificateId, string memory _organizationID) {
        require(CertificateAddresses[toCertificateKey(_OriginalCertificateId, _organizationID)] == address(0), "Entry existed exception!");
        _;
    }
    modifier duplicatedHashGuard(
      bytes32 _b0,
      bytes32 _b1,
      string memory _OriginalCertificateId,
      string memory _organizationID) {

        IndividualCertification individualCert = IndividualCertification(CertificateAddresses[toCertificateKey(_OriginalCertificateId, _organizationID)]);
        require(keccak256(abi.encodePacked(_b0, _b1)) != keccak256(abi.encodePacked(individualCert.b0(), individualCert.b1())),
        "Duplicated hash-value exception!");
        _;
    }
}
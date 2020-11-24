 

pragma solidity ^0.5.2;

 

 
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

     
    function add(Role storage role, address account) internal {
        require(account != address(0));
        require(!has(role, account));

        role.bearer[account] = true;
    }

     
    function remove(Role storage role, address account) internal {
        require(account != address(0));
        require(has(role, account));

        role.bearer[account] = false;
    }

     
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0));
        return role.bearer[account];
    }
}

 

contract PauserRole {
    using Roles for Roles.Role;

    event PauserAdded(address indexed account);
    event PauserRemoved(address indexed account);

    Roles.Role private _pausers;

    constructor () internal {
        _addPauser(msg.sender);
    }

    modifier onlyPauser() {
        require(isPauser(msg.sender));
        _;
    }

    function isPauser(address account) public view returns (bool) {
        return _pausers.has(account);
    }

    function addPauser(address account) public onlyPauser {
        _addPauser(account);
    }

    function renouncePauser() public {
        _removePauser(msg.sender);
    }

    function _addPauser(address account) internal {
        _pausers.add(account);
        emit PauserAdded(account);
    }

    function _removePauser(address account) internal {
        _pausers.remove(account);
        emit PauserRemoved(account);
    }
}

 

 
contract Pausable is PauserRole {
    event Paused(address account);
    event Unpaused(address account);

    bool private _paused;

    constructor () internal {
        _paused = false;
    }

     
    function paused() public view returns (bool) {
        return _paused;
    }

     
    modifier whenNotPaused() {
        require(!_paused);
        _;
    }

     
    modifier whenPaused() {
        require(_paused);
        _;
    }

     
    function pause() public onlyPauser whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

     
    function unpause() public onlyPauser whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }
}

 

contract Adminable {
    using Roles for Roles.Role;

    event AdminAdded(address indexed account);
    event AdminRemoved(address indexed account);

    Roles.Role private _admins;

    constructor () internal {
        _addAdmin(msg.sender);
    }

    modifier onlyAdmin() {
        require(isAdmin(msg.sender));
        _;
    }

    function isAdmin(address account) public view returns (bool) {
        return _admins.has(account);
    }

    function addAdmin(address account) public onlyAdmin {
        _addAdmin(account);
    }

    function renounceAdmin() public {
        _removeAdmin(msg.sender);
    }

    function _addAdmin(address account) internal {
        _admins.add(account);
        emit AdminAdded(account);
    }

    function _removeAdmin(address account) internal {
        _admins.remove(account);
        emit AdminRemoved(account);
    }
}

 

contract Authorizable is Adminable {

    address public authorizedAddress;
    
    modifier onlyAuthorized() {
        require(msg.sender == authorizedAddress);
        _;
    }

    function updateAuthorizedAddress(address _address) onlyAdmin public {
        authorizedAddress = _address;
    }

}

 

 

 
 
contract SoarStorage is Authorizable {

     
    struct ListingObject {
        address owner;
        address sponsor;
        bytes12 geohash;
        mapping (address => mapping (bytes32 => uint )) sales;
        uint256 salesCount;
        uint8 status;
    }

    uint public counter = 0;
    mapping (bytes32 => ListingObject) internal listings;

    event Listing (
        bytes32 filehash,
        address indexed owner,
        address indexed sponsor,
        string previewUrl, 
        string url, 
        string pointWKT,
        bytes12 geohash, 
        string metadata
    );

    event ListingUpdated (
        bytes32 filehash,
        address indexed owner, 
        address indexed sponsor,
        string previewUrl, 
        string url, 
        string pointWKT,
        bytes12 geohash, 
        string metadata 
    );

    event ListingDeleted (
        bytes32 filehash,
        address indexed owner,
        address indexed sponsor
    );

    event Sale(
        address indexed buyer, 
        bytes32 id, 
        address indexed owner, 
        address sponsor,
        bytes32 indexed filehash,
        uint price 
    );

    function putListing (
        bytes32 _filehash,
        address _owner,
        address _sponsor,
        string memory _previewUrl, 
        string memory _url, 
        string memory _pointWKT, 
        bytes12 _geohash, 
        string memory _metadata
    ) 
        public 
        onlyAuthorized 
    {
        listings[_filehash].owner = _owner;
        listings[_filehash].sponsor = _sponsor;
        listings[_filehash].geohash = _geohash;
        listings[_filehash].status = 1;
        counter++;
        emit Listing(
            _filehash, 
            _owner,
            _sponsor, 
            _previewUrl, 
            _url, 
            _pointWKT, 
            _geohash, 
            _metadata
        );
    }

    function updateListing (
        bytes32 _filehash,
        address _owner,
        address _sponsor,
        string memory _previewUrl, 
        string memory _url, 
        string memory _pointWKT, 
        bytes12 _geohash, 
        string memory _metadata 
    ) 
        public 
        onlyAuthorized 
    {
        listings[_filehash].geohash = _geohash;
        listings[_filehash].status = 2;
        emit ListingUpdated(
            _filehash, 
            _owner,
            _sponsor, 
            _previewUrl, 
            _url, 
            _pointWKT, 
            _geohash, 
            _metadata
        );
    }

    function deleteListing(
        bytes32 _filehash 
    )
        public 
        onlyAuthorized 
    {
        listings[_filehash].status = 3;
        counter--;
        emit ListingDeleted(_filehash, listings[_filehash].owner, listings[_filehash].sponsor);
    }

    function putSale (
        address _buyer,
        bytes32 _id,
        bytes32 _filehash, 
        uint256 _price
    ) 
        public 
        onlyAuthorized 
    {
        listings[_filehash].sales[_buyer][_id] = _price;
        listings[_filehash].salesCount++;
        emit Sale(_buyer, _id, listings[_filehash].owner, listings[_filehash].sponsor, _filehash, _price);
    }

    function getListingDetails(bytes32 _filehash, address _user, bytes32 _id) 
        public view
        returns (
            address owner_,
            address sponsor_,
            bytes12 geohash_,
            uint8 status_,
            uint256 sale_
        )
    {
        owner_ = listings[_filehash].owner;
        sponsor_ = listings[_filehash].sponsor;
        geohash_ = listings[_filehash].geohash;
        status_ = listings[_filehash].status;
        sale_ = listings[_filehash].sales[_user][_id];
    }
}

 

 
 
contract Soar is Pausable, Adminable {

     
    address public soarStorageAddress;

     
    SoarStorage private soarStorageContract;

    bytes32 private emptyUserId = "00000000000000000000000000000000";
    address private emptySponsor = address(0);

    mapping (address => mapping ( address => bool)) private sponsors;

    event SponsorAdminAdded(address indexed sponsor, address admin);
    event SponsorAdminRemoved(address indexed sponsor, address admin);

    modifier listingExistAndNotDeleted(bytes32 _filehash) {
        (,,,uint8 status,) = soarStorageContract.getListingDetails(_filehash, msg.sender, emptyUserId);
        require(status == 1 || status == 2, "Listing must exist and not be deleted");
        _;
    }

    modifier listingNotExistOrDeleted(bytes32 _filehash) {
        (,,,uint8 status,) = soarStorageContract.getListingDetails(_filehash, msg.sender, emptyUserId);
        require(status == 0 || status == 3, "Listing can not exist or must be deleted");
        _;
    }

    modifier onlySponsor(address _sponsor) {
        require(sponsors[_sponsor][msg.sender] == true, "Only sponsor");
        _;
    }

    modifier onlySponsorListingOwner(bytes32 _filehash, address _sponsor) {
        require(sponsors[_sponsor][msg.sender] == true, "Only sponsor");
        (,address sponsor,,uint8 status,) = soarStorageContract.getListingDetails(_filehash, msg.sender, emptyUserId);
        require(status == 1 || status == 2, "Listing must exist and not be deleted");
        require(sponsor == _sponsor, "Incorrect sponsor");
        _;
    }
    
    constructor() public {}

     
    function sponsorCreateListing(
        address _sponsor,
        address _owner,
        bytes32 _filehash,
        string memory _previewUrl, 
        string memory _url, 
        string memory _pointWKT, 
        bytes12 _geohash, 
        string memory _metadata) 
        public
        whenNotPaused
        listingNotExistOrDeleted(_filehash)
        onlySponsor(_sponsor)
    {
        soarStorageContract.putListing(_filehash, _owner, _sponsor, _previewUrl, _url, _pointWKT, _geohash, _metadata);
    }

     
    function sponsorUpdateListing(
        address _sponsor,
        address _owner,
        bytes32 _filehash,
        string memory _previewUrl, 
        string memory _url, 
        string memory _pointWKT, 
        bytes12 _geohash, 
        string memory _metadata) 
        public
        whenNotPaused
        onlySponsorListingOwner(_filehash, _sponsor)
    {
        soarStorageContract.updateListing(_filehash, _owner, _sponsor, _previewUrl, _url, _pointWKT, _geohash, _metadata);
    }

     
    function sponsorDeleteListing(
        address _sponsor,
        bytes32 _filehash) 
        public
        whenNotPaused
        onlySponsorListingOwner(_filehash, _sponsor)
    {
        soarStorageContract.deleteListing(_filehash);
    }

    function listingExist(bytes32 _filehash) 
        public view
        whenNotPaused  
        returns (bool exists_) 
    {
        (,,,uint8 status,) = soarStorageContract.getListingDetails(_filehash, msg.sender, emptyUserId);
        exists_ = (status == 1 || status == 2);
    }

     

    function addSponsorAdmin(address _sponsor, address _admin) 
        public 
        whenNotPaused
        onlyAdmin 
    {
        sponsors[_sponsor][_admin] = true;
        emit SponsorAdminAdded(_sponsor, _admin);
    }

    function removeSponsorAdmin(address _sponsor, address _admin) 
        public
        whenNotPaused
        onlyAdmin 
    {
        sponsors[_sponsor][_admin] = false;
        emit SponsorAdminRemoved(_sponsor, _admin);
    }

    function isSponsorAdmin(address _sponsor) 
        public view
        returns (bool isSponsorAdmin_)
    {
        isSponsorAdmin_ = sponsors[_sponsor][msg.sender] == true;
    }

    function setSoarStorageContract(address _address) 
        public
        whenNotPaused 
        onlyAdmin 
    {
        soarStorageContract = SoarStorage(_address);
        soarStorageAddress = _address;
    }

}
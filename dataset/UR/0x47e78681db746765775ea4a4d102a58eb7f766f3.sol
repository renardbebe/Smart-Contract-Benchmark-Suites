 

pragma solidity ^0.5.7;

contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
     
    constructor() public{
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address newOwner) onlyOwner public {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}

contract User is Ownable {

    event UserRegistered(address internal_wallet_address, address external_wallet_address, address referrer, bytes32 nick_name, bytes32 geo_location);

    event UserNickNameUpdated(address external_wallet_address, bytes32 old_nick_name, bytes32 new_nick_name);

    event UserGeoLocationUpdated(address external_wallet_address, bytes32 old_geo_location, bytes32 new_geo_location);

    struct UserDetails {
        bytes32 nick_name;
        address payable referrer;
        bytes32 geo_location;
    }

     
    mapping(address => UserDetails) public users;

     
    mapping(address => address) public internal_to_external;

     
    mapping(address => address) public external_to_internal;

     
    mapping(address => address[]) public referees;

    constructor() public {
        UserDetails memory root = UserDetails({
            nick_name : "new",
            referrer : address(0),
            geo_location : "51.507351,-0.127758"  
            });
        users[msg.sender] = root;
        internal_to_external[msg.sender] = msg.sender;
    }

     
    function registerUsers(
        address payable[] calldata _internal_wallet_addresses,
        address payable[] calldata _external_wallet_addresses,
        address payable[] calldata _referrers,
        bytes32[] calldata _nick_names,
        bytes32[] calldata _geo_locations) external onlyOwner() {
        for (uint256 i; i < _internal_wallet_addresses.length; i++) {
            UserDetails memory ud = UserDetails({
                nick_name : _nick_names[i],
                referrer : _referrers[i],
                geo_location : _geo_locations[i]
                });
            users[_external_wallet_addresses[i]] = ud;
            referees[_referrers[i]].push(_external_wallet_addresses[i]);
            internal_to_external[_internal_wallet_addresses[i]] = _external_wallet_addresses[i];
            external_to_internal[_external_wallet_addresses[i]] = _internal_wallet_addresses[i];
            emit UserRegistered(_internal_wallet_addresses[i], _external_wallet_addresses[i], _referrers[i], _nick_names[i], _geo_locations[i]);
        }
    }

     
    function registerUser(
        address payable _internal_wallet_address,
        address payable _external_wallet_address,
        address payable _referrer,
        bytes32 _nick_name,
        bytes32 _geo_location) external onlyOwner() {
        UserDetails memory ud = UserDetails({
            nick_name : _nick_name,
            referrer : _referrer,
            geo_location : _geo_location
            });
        users[_external_wallet_address] = ud;
        referees[_referrer].push(_external_wallet_address);
        internal_to_external[_internal_wallet_address] = _external_wallet_address;
        external_to_internal[_external_wallet_address] = _internal_wallet_address;
        emit UserRegistered(_internal_wallet_address, _external_wallet_address, _referrer, _nick_name, _geo_location);
    }

     
    function updateNickname(bytes32 _nick_name) external {
        require(external_to_internal[msg.sender] != address(0));
        UserDetails memory ud = users[msg.sender];
        require(ud.nick_name != bytes32(0), "user does not esist!");
        bytes32 old_nick_name = ud.nick_name;
        ud.nick_name = _nick_name;
        users[msg.sender] = ud;
        emit UserNickNameUpdated(msg.sender, old_nick_name, _nick_name);
    }

     
    function updateGeoLocation(bytes32 _geo_location) external {
        require(external_to_internal[msg.sender] != address(0));
        UserDetails memory ud = users[msg.sender];
        require(ud.nick_name != bytes32(0), "user does not esist!");
        bytes32 old_geo_location = ud.geo_location;
        ud.geo_location = _geo_location;
        users[msg.sender] = ud;
        emit UserGeoLocationUpdated(msg.sender, old_geo_location, _geo_location);
    }

     
    modifier onlyInternalWallets() {
        require(internal_to_external[msg.sender] != address(0));
        _;
    }
}

contract SuperOneSpots is User {

    event Withdrawal(address wallet, uint256 weiAmount);
    event CommissionSent(address indexed from, address to, uint256 amount);

     
    mapping(uint256 => mapping(uint256 => address)) public coordinates;

     
    mapping(uint256 => uint256) public x_addition;

     
    mapping(uint256 => uint256) public y_addition;

     
    constructor() public {
         
        coordinates[0][0] = msg.sender;
        uint256 x_factor = 1;
        uint256 y_factor;
         
        for (uint256 i; i < 128; i++) {
             
            if ((i + 2) >= (2 * (2 ** x_factor))) {
                x_factor += 1;
                y_factor = 1;
            } else {
                y_factor += 1;
            }
            x_addition[i] = x_factor;
            y_addition[i] = y_factor - 1;
        }

    }

     
    function assignSpotsByAdmin(uint256 coord_x, uint256 coord_y, uint _count, address external_wallet_address) external onlyOwner() {
        require(_count < 128);
        coordinates[coord_x][coord_y] = external_wallet_address;
        for (uint256 i; i < _count - 1; i++) {
            coordinates[coord_x + x_addition[i]][coord_y * (2 * (2 ** (x_addition[i] - 1))) + y_addition[i]] = external_wallet_address;
        }
    }

     
    function assignSpots(uint256 coord_x, uint256 coord_y, uint _count) external onlyInternalWallets() {
        require(_count < 128);
        address wallet = internal_to_external[msg.sender];
        coordinates[coord_x][coord_y] = wallet;
        for (uint256 i; i < _count - 1; i++) {
            coordinates[coord_x + x_addition[i]][coord_y * (2 * (2 ** (x_addition[i] - 1))) + y_addition[i]] = wallet;
        }
    }

     
    function distributeCommission(address payable[] calldata beneficiaries, uint256[] calldata amounts) external payable onlyInternalWallets() {
        require(beneficiaries.length == amounts.length);
        for (uint256 i; i < beneficiaries.length; i++) {
            beneficiaries[i].transfer(amounts[i]);
            emit CommissionSent(internal_to_external[msg.sender], beneficiaries[i], amounts[i]);
        }
    }

     
    function withdraw(address payable _wallet) onlyOwner() public {
        uint256 weiAmount = address(this).balance;
        require(weiAmount > 0);
        _wallet.transfer(weiAmount);
        emit Withdrawal(_wallet, weiAmount);
    }

    function checkSpots(uint256[] calldata x, uint256[] calldata y) external view returns (address[] memory){
        address[] memory addresses;
        for (uint256 i; i < x.length; i++) {
            addresses[i] = coordinates[x[i]][y[i]];
        }
        return addresses;
    }

}
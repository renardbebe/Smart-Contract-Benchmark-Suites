 

pragma solidity 0.5.0;

 

 
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

 

 
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

     
    function owner() public view returns (address) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

     
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

     
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

     
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

 

contract OperatorRole is Ownable {
    using Roles for Roles.Role;

    event OperatorAdded(address indexed account);
    event OperatorRemoved(address indexed account);

    Roles.Role private operators;

    constructor() public {
        operators.add(msg.sender);
    }

    modifier onlyOperator() {
        require(isOperator(msg.sender));
        _;
    }
    
    function isOperator(address account) public view returns (bool) {
        return operators.has(account);
    }

    function addOperator(address account) public onlyOwner() {
        operators.add(account);
        emit OperatorAdded(account);
    }

    function removeOperator(address account) public onlyOwner() {
        operators.remove(account);
        emit OperatorRemoved(account);
    }

}

 

contract Referrers is OperatorRole {
    using Roles for Roles.Role;

    event ReferrerAdded(address indexed account);
    event ReferrerRemoved(address indexed account);

    Roles.Role private referrers;

    uint32 internal index;
    uint16 public constant limit = 10;
    mapping(uint32 => address) internal indexToAddress;
    mapping(address => uint32) internal addressToIndex;

    modifier onlyReferrer() {
        require(isReferrer(msg.sender));
        _;
    }

    function getNumberOfAddresses() public view onlyOperator() returns (uint32) {
        return index;
    }

    function addressOfIndex(uint32 _index) onlyOperator() public view returns (address) {
        return indexToAddress[_index];
    }
    
    function isReferrer(address _account) public view returns (bool) {
        return referrers.has(_account);
    }

    function addReferrer(address _account) public onlyOperator() {
        referrers.add(_account);
        indexToAddress[index] = _account;
        addressToIndex[_account] = index;
        index++;
        emit ReferrerAdded(_account);
    }

    function addReferrers(address[limit] memory accounts) public onlyOperator() {
        for (uint16 i=0; i<limit; i++) {
            if (accounts[i] != address(0x0)) {
                addReferrer(accounts[i]);
            }
        }
    }

    function removeReferrer(address _account) public onlyOperator() {
        referrers.remove(_account);
        indexToAddress[addressToIndex[_account]] = address(0x0);
        emit ReferrerRemoved(_account);
    }

}
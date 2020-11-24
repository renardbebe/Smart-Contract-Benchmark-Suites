 

pragma solidity ^0.4.24;

 

 
contract OwnableUpdated {
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

 

 
contract Foundation is OwnableUpdated {

     
    mapping(address => bool) public factories;

     
    mapping(address => address) public ownersToContracts;

     
    mapping(address => address) public contractsToOwners;

     
    address[] private contractsIndex;

     
     
     
     
    mapping(address => address) public membersToContracts;

     
     
    mapping(address => address[]) public contractsToKnownMembersIndexes;

     
    event FactoryAdded(address _factory);
    event FactoryRemoved(address _factory);

     
    function addFactory(address _factory) external onlyOwner {
        factories[_factory] = true;
        emit FactoryAdded(_factory);
    }

     
    function removeFactory(address _factory) external onlyOwner {
        factories[_factory] = false;
        emit FactoryRemoved(_factory);
    }

     
    modifier onlyFactory() {
        require(
            factories[msg.sender],
            "You are not a factory"
        );
        _;
    }

     
    function setInitialOwnerInFoundation(
        address _contract,
        address _account
    )
        external
        onlyFactory
    {
        require(
            contractsToOwners[_contract] == address(0),
            "Contract already has owner"
        );
        require(
            ownersToContracts[_account] == address(0),
            "Account already has contract"
        );
        contractsToOwners[_contract] = _account;
        contractsIndex.push(_contract);
        ownersToContracts[_account] = _contract;
        membersToContracts[_account] = _contract;
    }

     
    function transferOwnershipInFoundation(
        address _contract,
        address _newAccount
    )
        external
    {
        require(
            (
                ownersToContracts[msg.sender] == _contract &&
                contractsToOwners[_contract] == msg.sender
            ),
            "You are not the owner"
        );
        ownersToContracts[msg.sender] = address(0);
        membersToContracts[msg.sender] = address(0);
        ownersToContracts[_newAccount] = _contract;
        membersToContracts[_newAccount] = _contract;
        contractsToOwners[_contract] = _newAccount;
         
         
    }

     
    function renounceOwnershipInFoundation() external returns (bool success) {
         
        delete(contractsToKnownMembersIndexes[msg.sender]);
         
        delete(ownersToContracts[contractsToOwners[msg.sender]]);
         
        delete(contractsToOwners[msg.sender]);
         
        success = true;
    }

     
    function addMember(address _member) external {
        require(
            ownersToContracts[msg.sender] != address(0),
            "You own no contract"
        );
        require(
            membersToContracts[_member] == address(0),
            "Address is already member of a contract"
        );
        membersToContracts[_member] = ownersToContracts[msg.sender];
        contractsToKnownMembersIndexes[ownersToContracts[msg.sender]].push(_member);
    }

     
    function removeMember(address _member) external {
        require(
            ownersToContracts[msg.sender] != address(0),
            "You own no contract"
        );
        require(
            membersToContracts[_member] == ownersToContracts[msg.sender],
            "Address is not member of this contract"
        );
        membersToContracts[_member] = address(0);
        contractsToKnownMembersIndexes[ownersToContracts[msg.sender]].push(_member);
    }

     
    function getContractsIndex()
        external
        onlyOwner
        view
        returns (address[])
    {
        return contractsIndex;
    }

     
    function() public {
        revert("Prevent accidental sending of ether");
    }
}
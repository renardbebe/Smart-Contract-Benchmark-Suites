 

pragma solidity ^0.5.1;

contract LockRequestable {

         
         
        uint256 public lockRequestCount;

        constructor() public {
                lockRequestCount = 0;
        }

         
         
        function generateLockId() internal returns (bytes32 lockId) {
                return keccak256(
                abi.encodePacked(blockhash(block.number - 1), address(this), ++lockRequestCount)
                );
        }
}

contract CustodianUpgradeable is LockRequestable {

         
         
        struct CustodianChangeRequest {
                address proposedNew;
        }

         
         
        address public custodian;

         
        mapping (bytes32 => CustodianChangeRequest) public custodianChangeReqs;

        constructor(address _custodian) public LockRequestable() {
                custodian = _custodian;
        }

         
        modifier onlyCustodian {
                require(msg.sender == custodian);
                _;
        }

         
        function requestCustodianChange(address _proposedCustodian) public returns (bytes32 lockId) {
                require(_proposedCustodian != address(0));

                lockId = generateLockId();

                custodianChangeReqs[lockId] = CustodianChangeRequest({
                        proposedNew: _proposedCustodian
                });

                emit CustodianChangeRequested(lockId, msg.sender, _proposedCustodian);
        }

         
        function confirmCustodianChange(bytes32 _lockId) public onlyCustodian {
                custodian = getCustodianChangeReq(_lockId);

                delete custodianChangeReqs[_lockId];

                emit CustodianChangeConfirmed(_lockId, custodian);
        }

         
        function getCustodianChangeReq(bytes32 _lockId) private view returns (address _proposedNew) {
                CustodianChangeRequest storage changeRequest = custodianChangeReqs[_lockId];

                 
                 
                require(changeRequest.proposedNew != address(0));

                return changeRequest.proposedNew;
        }

         
        event CustodianChangeRequested(
                bytes32 _lockId,
                address _msgSender,
                address _proposedCustodian
        );

         
        event CustodianChangeConfirmed(bytes32 _lockId, address _newCustodian);
}

contract KnowYourCustomer is CustodianUpgradeable {

    enum Status {
        none,
        passed,
        suspended
    }

    struct Customer {
        Status status;
        mapping(string => string) fields;
    }
    
    event ProviderAuthorized(address indexed _provider, string _name);
    event ProviderRemoved(address indexed _provider, string _name);
    event CustomerApproved(address indexed _customer, address indexed _provider);
    event CustomerSuspended(address indexed _customer, address indexed _provider);
    event CustomerFieldSet(address indexed _customer, address indexed _field, string _name);

    mapping(address => bool) private providers;
    mapping(address => Customer) private customers;

    constructor(address _custodian) public CustodianUpgradeable(_custodian) {
        customers[_custodian].status = Status.passed;
        customers[_custodian].fields["type"] = "custodian";
        emit CustomerApproved(_custodian, msg.sender);
        emit CustomerFieldSet(_custodian, msg.sender, "type");
    }

    function providerAuthorize(address _provider, string calldata name) external onlyCustodian {
        require(providers[_provider] == false, "provider must not exist");
        providers[_provider] = true;
         
        emit ProviderAuthorized(_provider, name);
    }

    function providerRemove(address _provider, string calldata name) external onlyCustodian {
        require(providers[_provider] == true, "provider must exist");
        delete providers[_provider];
        emit ProviderRemoved(_provider, name);
    }

    function hasWritePermissions(address _provider) external view returns (bool) {
        return _provider == custodian || providers[_provider] == true;
    }

    function getCustomerStatus(address _customer) external view returns (Status) {
        return customers[_customer].status;
    }

    function getCustomerField(address _customer, string calldata _field) external view returns (string memory) {
        return customers[_customer].fields[_field];
    }

    function approveCustomer(address _customer) external onlyAuthorized {
        Status status = customers[_customer].status;
        require(status != Status.passed, "customer must not be approved before");
        customers[_customer].status = Status.passed;
         
        emit CustomerApproved(_customer, msg.sender);
    }

    function setCustomerField(address _customer, string calldata _field, string calldata _value) external onlyAuthorized {
        Status status = customers[_customer].status;
        require(status != Status.none, "customer must have a set status");
        customers[_customer].fields[_field] = _value;
        emit CustomerFieldSet(_customer, msg.sender, _field);
    }

    function suspendCustomer(address _customer) external onlyAuthorized {
        Status status = customers[_customer].status;
        require(status != Status.suspended, "customer must be not suspended");
        customers[_customer].status = Status.suspended;
        emit CustomerSuspended(_customer, msg.sender);
    }

    modifier onlyAuthorized() {
        require(msg.sender == custodian || providers[msg.sender] == true);
        _;
    }
}
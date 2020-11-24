 

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

contract ServiceRegistry is CustodianUpgradeable {
    mapping (string => address) services;

    event ServiceReplaced(string indexed _name, address _oldAddr, address _newAddr);

    constructor(address _custodian) public CustodianUpgradeable(_custodian) {
    }

    function replaceService(string calldata _name, address _newAddr) external onlyCustodian withContract(_newAddr) {
        address _prevAddr = services[_name];
        services[_name] = _newAddr;
        emit ServiceReplaced(_name, _prevAddr, _newAddr);
    }

    function getService(string memory _name) public view returns (address) {
        return services[_name];
    }

    modifier withContract(address _addr) {
        uint length;
        assembly { length := extcodesize(_addr) }
        require(length > 0);
        _;
    }
}
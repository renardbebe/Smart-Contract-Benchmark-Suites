 

pragma solidity ^0.4.16;
 
contract SimpleAudit {

    event AuditLog(bytes32 goeureka_audit_ref, string reference);  

    struct Audit {
        string reference;         
        bool exist;               
    }

    address creator;
    mapping(bytes32 => Audit) public records;

    constructor() public {
        creator = msg.sender;
    }

    modifier onlyOwner {
        require(
            msg.sender == creator, "Only owner can call this function."
        );
        _;
    }

    modifier noEdit(bytes32 goeureka_audit_ref) {

        require(
            records[goeureka_audit_ref].exist == false,
            "Already set, audit log cannot be modified"
        );
        _;
    }

    function set(bytes32 goeureka_audit_ref, string reference)
        onlyOwner
        noEdit(goeureka_audit_ref)
        public {
            records[goeureka_audit_ref].reference = reference;
            records[goeureka_audit_ref].exist = true;
            emit AuditLog(goeureka_audit_ref, reference);
    }

    function get(bytes32 goeureka_audit_ref) public constant returns (string) {
        return records[goeureka_audit_ref].reference;
    }

}
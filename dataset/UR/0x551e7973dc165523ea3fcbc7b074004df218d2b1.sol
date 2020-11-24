 

pragma solidity ^0.4.4;
 
contract Owned {
     
    address public owner;

     
    function Owned() { owner = msg.sender; }

     
    function delegate(address _owner) onlyOwner
    { owner = _owner; }

     
    modifier onlyOwner { if (msg.sender != owner) throw; _; }
}


 
contract Mortal is Owned {
     
    function kill() onlyOwner
    { suicide(owner); }
}


contract Comission is Mortal {
    address public ledger;
    bytes32 public taxman;
    uint    public taxPerc;

     
    function Comission(address _ledger, bytes32 _taxman, uint _taxPerc) {
        ledger  = _ledger;
        taxman  = _taxman;
        taxPerc = _taxPerc;
    }

     
    function process(bytes32 _destination) payable returns (bool) {
         
        if (msg.value < 100) throw;

        var tax = msg.value * taxPerc / 100; 
        var refill = bytes4(sha3("refill(bytes32)")); 
        if ( !ledger.call.value(tax)(refill, taxman)
          || !ledger.call.value(msg.value - tax)(refill, _destination)
           ) throw;
        return true;
    }
}


library CreatorComission {
    function create(address _ledger, bytes32 _taxman, uint256 _taxPerc) returns (Comission)
    { return new Comission(_ledger, _taxman, _taxPerc); }

    function version() constant returns (string)
    { return "v0.5.0 (a9ea4c6c)"; }

    function abi() constant returns (string)
    { return '[{"constant":false,"inputs":[{"name":"_destination","type":"bytes32"}],"name":"process","outputs":[{"name":"","type":"bool"}],"payable":true,"type":"function"},{"constant":false,"inputs":[],"name":"kill","outputs":[],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"taxman","outputs":[{"name":"","type":"bytes32"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"ledger","outputs":[{"name":"","type":"address"}],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"_owner","type":"address"}],"name":"delegate","outputs":[],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"owner","outputs":[{"name":"","type":"address"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"taxPerc","outputs":[{"name":"","type":"uint256"}],"payable":false,"type":"function"},{"inputs":[{"name":"_ledger","type":"address"},{"name":"_taxman","type":"bytes32"},{"name":"_taxPerc","type":"uint256"}],"type":"constructor"}]'; }
}


 
contract Builder is Mortal {
     
    event Builded(address indexed client, address indexed instance);
 
     
    mapping(address => address[]) public getContractsOf;
 
     
    function getLastContract() constant returns (address) {
        var sender_contracts = getContractsOf[msg.sender];
        return sender_contracts[sender_contracts.length - 1];
    }

     
    address public beneficiary;

     
    function setBeneficiary(address _beneficiary) onlyOwner
    { beneficiary = _beneficiary; }

     
    uint public buildingCostWei;

     
    function setCost(uint _buildingCostWei) onlyOwner
    { buildingCostWei = _buildingCostWei; }

     
    string public securityCheckURI;

     
    function setSecurityCheck(string _uri) onlyOwner
    { securityCheckURI = _uri; }
}

 
 
 

 
contract BuilderComission is Builder {
     
    function create(address _ledger, bytes32 _taxman, uint _taxPerc,
                    address _client) payable returns (address) {
        if (buildingCostWei > 0 && beneficiary != 0) {
             
            if (msg.value < buildingCostWei) throw;
             
            if (!beneficiary.send(buildingCostWei)) throw;
             
            if (msg.value > buildingCostWei) {
                if (!msg.sender.send(msg.value - buildingCostWei)) throw;
            }
        } else {
             
            if (msg.value > 0) {
                if (!msg.sender.send(msg.value)) throw;
            }
        }

        if (_client == 0)
            _client = msg.sender;
 
        var inst = CreatorComission.create(_ledger, _taxman, _taxPerc);
        inst.delegate(_client);
        Builded(_client, inst);
        getContractsOf[_client].push(inst);
        return inst;
    }
}
 

pragma solidity ^0.4.4;

 
contract Owned {
     
    address public owner;

     
    function setOwner(address _owner) onlyOwner
    { owner = _owner; }

     
    modifier onlyOwner { if (msg.sender != owner) throw; _; }
}

 
contract Destroyable {
    address public hammer;

     
    function setHammer(address _hammer) onlyHammer
    { hammer = _hammer; }

     
    function destroy() onlyHammer
    { suicide(msg.sender); }

     
    modifier onlyHammer { if (msg.sender != hammer) throw; _; }
}

 
contract Object is Owned, Destroyable {
    function Object() {
        owner  = msg.sender;
        hammer = msg.sender;
    }
}

 
 
contract ERC20 
{
 
     
    uint256 public totalSupply;

     
     
    function balanceOf(address _owner) constant returns (uint256);

     
     
     
     
    function transfer(address _to, uint256 _value) returns (bool);

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool);

     
     
     
     
    function approve(address _spender, uint256 _value) returns (bool);

     
     
     
    function allowance(address _owner, address _spender) constant returns (uint256);

 
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract Presale is Object {
    ERC20   public token;
    uint256 public bounty;
    uint256 public donation;

     
    function Presale(address _token, uint256 _bounty, uint256 _donation) {
        token    = ERC20(_token);
        bounty   = _bounty;
        donation = _donation;
    }

     
    function cancel() onlyOwner {
        if (!token.transfer(owner, bounty)) throw;
    }

     
    function () payable {
        if (msg.value != donation) throw;
        if (!token.transfer(msg.sender, bounty)) throw;
        if (!owner.send(msg.value)) throw;
    }
}

library CreatorPresale {
    function create(address _token, uint256 _bounty, uint256 _donation) returns (Presale)
    { return new Presale(_token, _bounty, _donation); }

    function version() constant returns (string)
    { return "v0.6.3"; }

    function abi() constant returns (string)
    { return '[{"constant":false,"inputs":[{"name":"_owner","type":"address"}],"name":"setOwner","outputs":[],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"hammer","outputs":[{"name":"","type":"address"}],"payable":false,"type":"function"},{"constant":false,"inputs":[],"name":"destroy","outputs":[],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"owner","outputs":[{"name":"","type":"address"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"donation","outputs":[{"name":"","type":"uint256"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"bounty","outputs":[{"name":"","type":"uint256"}],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"_hammer","type":"address"}],"name":"setHammer","outputs":[],"payable":false,"type":"function"},{"constant":false,"inputs":[],"name":"cancel","outputs":[],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"token","outputs":[{"name":"","type":"address"}],"payable":false,"type":"function"},{"inputs":[{"name":"_token","type":"address"},{"name":"_bounty","type":"uint256"},{"name":"_donation","type":"uint256"}],"payable":false,"type":"constructor"},{"payable":true,"type":"fallback"}]'; }
}

 
contract Builder is Object {
     
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
 
 
 
contract BuilderPresale is Builder {
     
    function create(address _token,
                    uint256 _bounty,
                    uint256 _donation,
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
 
        var inst = CreatorPresale.create(_token, _bounty, _donation);
        inst.setOwner(_client);
        inst.setHammer(_client);
        getContractsOf[_client].push(inst);
        Builded(_client, inst);
        return inst;
    }
}
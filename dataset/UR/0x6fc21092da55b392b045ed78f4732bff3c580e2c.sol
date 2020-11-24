 

pragma solidity ^0.4.0;

contract AbstractENS {
    function owner(bytes32 node) constant returns(address);
    function resolver(bytes32 node) constant returns(address);
    function setOwner(bytes32 node, address owner);
    function setSubnodeOwner(bytes32 node, bytes32 label, address owner);
    function setResolver(bytes32 node, address resolver);
}

contract Resolver {
    function setAddr(bytes32 nodeHash, address addr);
}
contract ReverseRegistrar {
    function claim(address owner) returns (bytes32 node);
}


 
contract FireflyRegistrar {
      
     bytes32 constant RR_NODE = 0x91d1777781884d03a6757a803996e38de2a42967fb37eeaca72729271025a9e2;

     
    event adminChanged(address oldAdmin, address newAdmin);
    event feeChanged(uint256 oldFee, uint256 newFee);
    event defaultResolverChanged(address oldResolver, address newResolver);
    event didWithdraw(address target, uint256 amount);

     
    event nameRegistered(bytes32 indexed nodeHash, address owner, uint256 fee);

     
    event donation(bytes32 indexed nodeHash, uint256 amount);

    AbstractENS _ens;
    Resolver _defaultResolver;

    address _admin;
    bytes32 _nodeHash;

    uint256 _fee;

    uint256 _totalPaid = 0;
    uint256 _nameCount = 0;

    mapping (bytes32 => uint256) _donations;

    function FireflyRegistrar(address ens, bytes32 nodeHash, address defaultResolver) {
        _ens = AbstractENS(ens);
        _nodeHash = nodeHash;
        _defaultResolver = Resolver(defaultResolver);

        _admin = msg.sender;

        _fee = 0.1 ether;

         
        ReverseRegistrar(_ens.owner(RR_NODE)).claim(_admin);
    }

     
    function setAdmin(address admin) {
        if (msg.sender != _admin) { throw; }

        adminChanged(_admin, admin);
        _admin = admin;

         
        ReverseRegistrar(_ens.owner(RR_NODE)).claim(admin);

         
        Resolver(_ens.resolver(_nodeHash)).setAddr(_nodeHash, _admin);
    }

     
    function setFee(uint256 fee) {
        if (msg.sender != _admin) { throw; }
        feeChanged(_fee, fee);
        _fee = fee;
    }

     
    function setDefaultResolver(address defaultResolver) {
        if (msg.sender != _admin) { throw; }
        defaultResolverChanged(_defaultResolver, defaultResolver);
        _defaultResolver = Resolver(defaultResolver);
    }

     
    function withdraw(address target, uint256 amount) {
        if (msg.sender != _admin) { throw; }
        if (!target.send(amount)) { throw; }
        didWithdraw(target, amount);
    }

     
    function register(string label) payable {

         
        uint256 position;
        uint256 length;
        assembly {
             
            length := mload(label)

             
            position := add(label, 1)
        }

         
        if (length < 4 || length > 20) { throw; }

         
        for (uint256 i = 0; i < length; i++) {
            uint8 c;
            assembly { c := and(mload(position), 0xFF) }
             
            if ((c < 0x61 || c > 0x7a) && (c < 0x30 || c > 0x39) && c != 0x2d) {
                throw;
            }
            position++;
        }

         
        if (msg.value < _fee) { throw; }

         
        var labelHash = sha3(label);
        var nodeHash = sha3(_nodeHash, labelHash);

         
        if (_ens.owner(nodeHash) != address(0)) { throw; }

         
        _ens.setSubnodeOwner(_nodeHash, labelHash, this);

         
        _ens.setResolver(nodeHash, _defaultResolver);
        _defaultResolver.setAddr(nodeHash, msg.sender);

         
        _ens.setOwner(nodeHash, msg.sender);

        _totalPaid += msg.value;
        _nameCount++;

        _donations[nodeHash] += msg.value;

        nameRegistered(nodeHash, msg.sender, msg.value);
        donation(nodeHash, msg.value);
    }

     
    function donate(bytes32 nodeHash) payable {
        _donations[nodeHash] += msg.value;
        donation(nodeHash, msg.value);
    }

     
    function config() constant returns (address ens, bytes32 nodeHash, address admin, uint256 fee, address defaultResolver) {
        ens = _ens;
        nodeHash = _nodeHash;
        admin = _admin;
        fee = _fee;
        defaultResolver = _defaultResolver;
    }

     
    function stats() constant returns (uint256 nameCount, uint256 totalPaid, uint256 balance) {
        nameCount = _nameCount;
        totalPaid = _totalPaid;
        balance = this.balance;
    }

     
    function donations(bytes32 nodeHash) constant returns (uint256 donation) {
        return _donations[nodeHash];
    }

     
    function fee() constant returns (uint256 fee) {
        return _fee;
    }

     
    function () payable {
        _donations[0] += msg.value;
        donation(0, msg.value);
    }
}
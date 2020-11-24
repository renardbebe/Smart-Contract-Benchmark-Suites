 

 

 

 


pragma solidity ^0.4.16;

 
 
contract Token {
    function approve(address, uint256) returns (bool);
}

 
contract AbstractENS {
    function owner(bytes32) constant returns(address);
    function resolver(bytes32) constant returns(address);
}

contract Resolver {
    function addr(bytes32);
}

contract ReverseRegistrar {
    function claim(address) returns (bytes32);
}



contract StickerRegistry {

     
    bytes32 constant RR_NODE = 0x91d1777781884d03a6757a803996e38de2a42967fb37eeaca72729271025a9e2;

    event seriesCreated(bytes32 indexed nodehash);

    event itemTransferred(
        bytes32 indexed nodehash,
        uint256 itemIndex,
        address indexed oldOwner,
        address indexed newOwner
    );


    struct Series {
         
        string name;

         
        bytes32 rootHash;

         
        uint256 initialCount;

         
        uint256 issuedCount;

         
        uint256 currentCount;

         
        mapping (uint256 => address) owners;
    }

    AbstractENS _ens;

    address _owner;

    mapping (bytes32 => Series) _series;


    function StickerRegistry(address ens) {
        _owner = msg.sender;
        _ens = AbstractENS(ens);

         
        ReverseRegistrar(_ens.owner(RR_NODE)).claim(_owner);
    }

    function setOwner(address newOwner) {
        require(msg.sender == _owner);
        _owner = newOwner;

         
        ReverseRegistrar(_ens.owner(RR_NODE)).claim(_owner);
    }

     
    function withdraw(address target, uint256 amount) {
        require(msg.sender == _owner);
        assert(target.send(amount));
    }

     
    function approveToken(address token, uint256 amount) {
        require(msg.sender == _owner);
        assert(Token(token).approve(_owner, amount));
    }


     
    function createSeries(bytes32 nodehash, string seriesName, bytes32 rootHash, uint256 initialCount) returns (bool success) {

         
        if (msg.sender != _ens.owner(nodehash)) { return false; }

        if (rootHash == 0x00) { return false; }

        Series storage series = _series[nodehash];

         
        if (series.rootHash != 0x00) { return false; }

        series.name = seriesName;
        series.rootHash = rootHash;
        series.initialCount = initialCount;
        series.currentCount = initialCount;

        seriesCreated(nodehash);
    }

     
     
    function bestow(bytes32 nodehash, uint256 itemIndex, address owner) returns (bool success) {

         
        if (_ens.owner(nodehash) != msg.sender) { return false; }

        Series storage series = _series[nodehash];

        if (itemIndex >= series.initialCount) { return false; }

         
        if (series.owners[itemIndex] != 0) { return false; }

         
        if (owner == 0xdead) { series.currentCount--; }

        series.issuedCount++;

        series.owners[itemIndex] = owner;

        itemTransferred(nodehash, itemIndex, 0x0, owner);
    }

     
    function claim(bytes32 nodehash, uint256 itemIndex, address owner, uint8 sigV, bytes32 sigR, bytes32 sigS,  bytes32[] merkleProof) returns (bool success) {
        Series storage series = _series[nodehash];

        if (itemIndex >= series.initialCount) { return false; }

         
        if (series.owners[itemIndex] != 0) { return false; }

        uint256 path = itemIndex;

         
        address fauxOwner = ecrecover(bytes32(owner), sigV, sigR, sigS);

         
        bytes32 node = keccak256(nodehash, itemIndex, bytes32(fauxOwner));
        for (uint16 i = 0; i < merkleProof.length; i++) {
            if ((path & 0x01) == 1) {
                node = keccak256(merkleProof[i], node);
            } else {
                node = keccak256(node, merkleProof[i]);
            }
            path /= 2;
        }

         
        if (node != series.rootHash) { return false; }

         
        series.owners[itemIndex] = owner;

         
        series.issuedCount++;

        itemTransferred(nodehash, itemIndex, 0x0, owner);

        return true;
    }

     
    function transfer(bytes32 nodehash, uint256 itemIndex, address newOwner) returns (bool success) {

         
        if (newOwner == 0) { return false; }

        Series storage series = _series[nodehash];

        address currentOwner = series.owners[itemIndex];

         
        if (currentOwner != msg.sender) {
            return false;
        }

         
         
        if (newOwner == 0xdead) { series.currentCount--; }

        itemTransferred(nodehash, itemIndex, currentOwner, newOwner);

         
        series.owners[itemIndex] = newOwner;

        return true;
    }


     
    function owner() constant returns (address) {
        return _owner;
    }

     
    function seriesInfo(bytes32 nodehash) constant returns (string name, bytes32 rootHash, uint256 initialCount, uint256 issuedCount, uint256 currentCount) {
        Series storage series = _series[nodehash];
        return (series.name, series.rootHash, series.initialCount, series.issuedCount, series.currentCount);
    }

     
    function itemOwner(bytes32 nodehash, uint256 itemIndex) constant returns (address) {
        return _series[nodehash].owners[itemIndex];
    }
}
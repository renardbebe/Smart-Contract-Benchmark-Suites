 

 
 
 

pragma solidity ^0.5.10;

contract DMap {
    address owner;
    mapping(bytes32=>bytes32) values;

    event ValueUpdate( bytes32 indexed key
                     , bytes32 indexed value );
    event OwnerUpdate( address indexed oldOwner
                     , address indexed newOwner );

    constructor() public {
        owner = msg.sender;
        emit OwnerUpdate(address(0), owner);
    }
    function getValue(bytes32 key)
        public view returns (bytes32)
    {
        return values[key];
    }
    function setValue(bytes32 key, bytes32 value)
        public
    {
        assert(msg.sender == owner);
        values[key] = value;
        emit ValueUpdate(key, value);
    }
    function getOwner()
        public view returns (address)
    {
        return owner;
    }
    function setOwner(address newOwner)
        public
    {
        assert(msg.sender == owner);
        owner = newOwner;
        emit OwnerUpdate(msg.sender, owner);
    }
}

contract xreg {
    DMap public x;
    constructor() public {
        x = new DMap();
    }
    function newChild(bytes32 name) public returns (DMap) {
        DMap map = new DMap();
        register(name, bytes32(bytes20(address( map ))));
        map.setOwner(msg.sender);
        return map;
    }
    function register(bytes32 key, bytes32 val) public {
        assert(x.getValue(key) == 0x0);
        x.setValue(key, val);
    }
}
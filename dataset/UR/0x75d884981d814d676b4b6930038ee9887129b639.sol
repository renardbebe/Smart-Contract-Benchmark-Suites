 

pragma solidity 0.4.19;


contract IConnections {
     
     
    enum Direction {NotApplicable, Forwards, Backwards, Invalid}
    function createUser() external returns (address entityAddress);
    function createUserAndConnection(address _connectionTo, bytes32 _connectionType, Direction _direction) external returns (address entityAddress);
    function createVirtualEntity() external returns (address entityAddress);
    function createVirtualEntityAndConnection(address _connectionTo, bytes32 _connectionType, Direction _direction) external returns (address entityAddress);
    function editEntity(address _entity, bool _active, bytes32 _data) external;
    function transferEntityOwnerPush(address _entity, address _newOwner) external;
    function transferEntityOwnerPull(address _entity) external;
    function addConnection(address _entity, address _connectionTo, bytes32 _connectionType, Direction _direction) public;
    function editConnection(address _entity, address _connectionTo, bytes32 _connectionType, Direction _direction, bool _active, bytes32 _data, uint _expiration) external;
    function removeConnection(address _entity, address _connectionTo, bytes32 _connectionType) external;
    function isUser(address _entity) view public returns (bool isUserEntity);
    function getEntity(address _entity) view external returns (bool active, address transferOwnerTo, bytes32 data, address owner);
    function getConnection(address _entity, address _connectionTo, bytes32 _connectionType) view external returns (bool entityActive, bool connectionEntityActive, bool connectionActive, bytes32 data, Direction direction, uint expiration);

     
    event entityAdded(address indexed entity, address indexed owner);
    event entityModified(address indexed entity, address indexed owner, bool indexed active, bytes32 data);
    event entityOwnerChangeRequested(address indexed entity, address indexed oldOwner, address newOwner);
    event entityOwnerChanged(address indexed entity, address indexed oldOwner, address newOwner);
    event connectionAdded(address indexed entity, address indexed connectionTo, bytes32 connectionType, Direction direction);
    event connectionModified(address indexed entity, address indexed connectionTo, bytes32 indexed connectionType, Direction direction, bool active, uint expiration);
    event connectionRemoved(address indexed entity, address indexed connectionTo, bytes32 indexed connectionType);
    event entityResolved(address indexed entityRequested, address indexed entityResolved);    
}


 
contract Connections is IConnections {

    struct Entity {
        bool active;
        address transferOwnerTo;
        address owner;
        bytes32 data;  
        mapping (address => mapping (bytes32 => Connection)) connections;
    }

     
    struct Connection {
        bool active;
        bytes32 data;  
        Direction direction;
        uint expiration;  
    }

    mapping (address => Entity) public entities;
    mapping (address => address) public entityOfUser;
    uint256 public virtualEntitiesCreated = 0;

     
     
    function Connections() public {}

     
    function () external {
        revert();
    }


     
     
    function createUser() external returns (address entityAddress) {
        entityAddress = msg.sender;
        assert(entityOfUser[msg.sender] == address(0));
        createEntity(entityAddress, msg.sender);
        entityOfUser[msg.sender] = entityAddress;
    }

     
    function createUserAndConnection(
        address _connectionTo,
        bytes32 _connectionType,
        Direction _direction
    )
        external returns (address entityAddress)
    {
        entityAddress = msg.sender;
        assert(entityOfUser[msg.sender] == address(0));
        createEntity(entityAddress, msg.sender);
        entityOfUser[msg.sender] = entityAddress;
        addConnection(entityAddress, _connectionTo, _connectionType, _direction);
    }

     
    function createVirtualEntity() external returns (address entityAddress) {
        entityAddress = createVirtualAddress();
        createEntity(entityAddress, msg.sender);
    }

     
    function createVirtualEntityAndConnection(
        address _connectionTo,
        bytes32 _connectionType,
        Direction _direction
    )
        external returns (address entityAddress)
    {
        entityAddress = createVirtualAddress();
        createEntity(entityAddress, msg.sender);
        addConnection(entityAddress, _connectionTo, _connectionType, _direction);
    }

     
    function editEntity(address _entity, bool _active, bytes32 _data) external {
        address resolvedEntity = resolveEntityAddressAndOwner(_entity);
        Entity storage entity = entities[resolvedEntity];
        entity.active = _active;
        entity.data = _data;
        entityModified(_entity, msg.sender, _active, _data);
    }

     
    function transferEntityOwnerPush(address _entity, address _newOwner) external {
        address resolvedEntity = resolveEntityAddressAndOwner(_entity);
        entities[resolvedEntity].transferOwnerTo = _newOwner;
        entityOwnerChangeRequested(_entity, msg.sender, _newOwner);
    }

     
    function transferEntityOwnerPull(address _entity) external {
        address resolvedEntity = resolveEntityAddress(_entity);
        emitEntityResolution(_entity, resolvedEntity);
        Entity storage entity = entities[resolvedEntity];
        require(entity.transferOwnerTo == msg.sender);
        if (isUser(resolvedEntity)) {  
            assert(entityOfUser[msg.sender] == address(0) ||
                   entityOfUser[msg.sender] == resolvedEntity);
            entityOfUser[msg.sender] = resolvedEntity;
        }
        address oldOwner = entity.owner;
        entity.owner = entity.transferOwnerTo;
        entity.transferOwnerTo = address(0);
        entityOwnerChanged(_entity, oldOwner, msg.sender);
    }

     
    function editConnection(
        address _entity,
        address _connectionTo,
        bytes32 _connectionType,
        Direction _direction,
        bool _active,
        bytes32 _data,
        uint _expiration
    )
        external
    {
        address resolvedEntity = resolveEntityAddressAndOwner(_entity);
        address resolvedConnectionEntity = resolveEntityAddress(_connectionTo);
        emitEntityResolution(_connectionTo, resolvedConnectionEntity);
        Entity storage entity = entities[resolvedEntity];
        Connection storage connection = entity.connections[resolvedConnectionEntity][_connectionType];
        connection.active = _active;
        connection.direction = _direction;
        connection.data = _data;
        connection.expiration = _expiration;
        connectionModified(_entity, _connectionTo, _connectionType, _direction, _active, _expiration);
    }

     
    function removeConnection(address _entity, address _connectionTo, bytes32 _connectionType) external {
        address resolvedEntity = resolveEntityAddressAndOwner(_entity);
        address resolvedConnectionEntity = resolveEntityAddress(_connectionTo);
        emitEntityResolution(_connectionTo,resolvedConnectionEntity);
        Entity storage entity = entities[resolvedEntity];
        delete entity.connections[resolvedConnectionEntity][_connectionType];
        connectionRemoved(_entity, _connectionTo, _connectionType);  
    }

     
    function sha256ofString(string _string) external pure returns (bytes32 result) {
        result = keccak256(_string);
    }

     
    function getEntity(address _entity) view external returns (bool active, address transferOwnerTo, bytes32 data, address owner) {
        address resolvedEntity = resolveEntityAddress(_entity);
        Entity storage entity = entities[resolvedEntity];
        return (entity.active, entity.transferOwnerTo, entity.data, entity.owner);
    }

     
    function getConnection(
        address _entity,
        address _connectionTo,
        bytes32 _connectionType
    )
        view external returns (
            bool entityActive,
            bool connectionEntityActive,
            bool connectionActive,
            bytes32 data,
            Direction direction,
            uint expiration
    ){
        address resolvedEntity = resolveEntityAddress(_entity);
        address resolvedConnectionEntity = resolveEntityAddress(_connectionTo);
        Entity storage entity = entities[resolvedEntity];
        Connection storage connection = entity.connections[resolvedConnectionEntity][_connectionType];
        return (entity.active, entities[resolvedConnectionEntity].active, connection.active, connection.data, connection.direction, connection.expiration);
    }


     
     
    function addConnection(
        address _entity,
        address _connectionTo,
        bytes32 _connectionType,
        Direction _direction
    )
        public
    {
        address resolvedEntity = resolveEntityAddressAndOwner(_entity);
        address resolvedEntityConnection = resolveEntityAddress(_connectionTo);
        emitEntityResolution(_connectionTo, resolvedEntityConnection);
        Entity storage entity = entities[resolvedEntity];
        assert(!entity.connections[resolvedEntityConnection][_connectionType].active);
        Connection storage connection = entity.connections[resolvedEntityConnection][_connectionType];
        connection.active = true;
        connection.direction = _direction;
        connectionAdded(_entity, _connectionTo, _connectionType, _direction);
    }

     
    function isUser(address _entity) view public returns (bool isUserEntity) {
        address resolvedEntity = resolveEntityAddress(_entity);
        assert(entities[resolvedEntity].active);  
        address owner = entities[resolvedEntity].owner;
        isUserEntity = (resolvedEntity == entityOfUser[owner]);
    }


     
     
    function createEntity(address _entityAddress, address _owner) internal {
        require(!entities[_entityAddress].active);  
        Entity storage entity = entities[_entityAddress];
        entity.active = true;
        entity.owner = _owner;
        entityAdded(_entityAddress, _owner);
    }

     
    function createVirtualAddress() internal returns (address virtualAddress) {
        virtualAddress = address(keccak256(safeAdd(virtualEntitiesCreated,block.number)));
        virtualEntitiesCreated = safeAdd(virtualEntitiesCreated,1);
    }

     
    function emitEntityResolution(address _entity, address _resolvedEntity) internal {
        if (_entity != _resolvedEntity)
            entityResolved(_entity,_resolvedEntity);
    }

     
    function resolveEntityAddress(address _entityAddress) internal view returns (address resolvedAddress) {
        if (entityOfUser[_entityAddress] != address(0) && entityOfUser[_entityAddress] != _entityAddress) {
            resolvedAddress = entityOfUser[_entityAddress];
        } else {
            resolvedAddress = _entityAddress;
        }
    }

     
    function resolveEntityAddressAndOwner(address _entityAddress) internal returns (address entityAddress) {
        entityAddress = resolveEntityAddress(_entityAddress);
        emitEntityResolution(_entityAddress, entityAddress);
        require(entities[entityAddress].owner == msg.sender);
    }

     
    function safeAdd(uint256 x, uint256 y) internal pure returns(uint256) {
      uint256 z = x + y;
      assert(z >= x);
      return z;
    }    

}
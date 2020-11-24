 

 

pragma solidity ^0.5.7;

contract DocHashStore {
  struct Record {
    uint    timestamp;
    string  name;
    string  description;
    address filer;
    address lastAmender;
    uint    recordLastModifiedBlockNumber;
  }

  event Stored( bytes32 docHash, uint timestamp, string name, string description, address filer );
  event Amended( bytes32 docHash, string name, string description, address updater, uint priorUpdateBlockNumber );
  event Opened( address admin, uint timestamp );
  event Closed( address closer, uint timestap );
  event Authorized( address user );
  event Deauthorized( address user );

  address public admin;
  bytes32[] public docHashes;
  mapping ( address => bool ) public authorized;
  uint public openTime;
  uint public closeTime;
  bool public closed;

  mapping ( bytes32 => Record ) private records;

  constructor() public {
    admin    = msg.sender;
    openTime = block.timestamp;
    closed   = false;

    emit Opened( admin, openTime );
  }

  modifier onlyAdmin {
    require( msg.sender == admin, "Administrator access only." );
    _;
  }

  modifier adminOrAuthorized {
    require( msg.sender == admin || authorized[msg.sender], "Administrator or authorized user access only." );
    _;
  }

  function close() public adminOrAuthorized {
    closeTime = block.timestamp;
    closed = true;

    emit Closed( msg.sender, closeTime );
  }

  function authorize( address filer ) public onlyAdmin {
    authorized[ filer ] = true;

    emit Authorized( msg.sender );
  }

  function deauthorize( address filer ) public onlyAdmin {
    authorized[ filer ] = false;

    emit Deauthorized( msg.sender );
  }

  function canUpdate( address user ) public view returns (bool) {
    return user == admin || authorized[user];
  }

  function store( bytes32 docHash, string memory name, string memory description ) public adminOrAuthorized {
    require( !closed, "This DocHashStore has been closed." );
    require( records[ docHash ].timestamp == 0, "DocHash has already been stored." );
    
    records[docHash] = Record( block.timestamp, name, description, msg.sender, msg.sender, block.number );
    docHashes.push( docHash );

    emit Stored( docHash, block.timestamp, name, description, msg.sender );
  }
  
  function amend( bytes32 docHash, string memory name, string memory description ) public adminOrAuthorized {
    require( !closed, "This DocHashStore has been closed." );
    require( records[ docHash ].timestamp != 0, "DocHash has not been defined, must be stored, can't be amended." );

    Record memory oldRecord = records[docHash];  
    Record memory newRecord = Record( oldRecord.timestamp, name, description, oldRecord.filer, msg.sender, block.number );
    
    records[docHash] = newRecord;

    emit Amended( docHash, name, description, msg.sender, oldRecord.recordLastModifiedBlockNumber );
  }
  
  function isStored( bytes32 docHash ) public view returns (bool) {
    return (records[ docHash ].timestamp != 0);
  }
  
  function timestamp( bytes32 docHash ) public view returns (uint) {
    return records[ docHash ].timestamp;
  }
  
  function name( bytes32 docHash ) public view returns (string memory) {
    return records[ docHash ].name;
  }
  
  function description( bytes32 docHash ) public view returns (string memory) {
    return records[ docHash ].description;
  }
  
  function filer( bytes32 docHash ) public view returns (address) {
    return records[ docHash ].filer;
  }

  function size() public view returns (uint) {
    return docHashes.length;
  }
}
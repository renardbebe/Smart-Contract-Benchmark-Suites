 

pragma solidity ^0.4.23;






 
 
 
 
contract iNovaStaking {

  function balanceOf(address _owner) public view returns (uint256);
}



 
 
 
 
contract iNovaGame {
  function isAdminForGame(uint _game, address account) external view returns(bool);

   
  uint[] public games;
}



 
 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
     
     
     
    if (a == 0) {
      return 0;
    }

    c = a * b;
    require(c / a == b, "mul failed");
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    return a / b;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, "sub fail");
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    require(c >= a, "add fail");
    return c;
  }
}


 
 
 
 
contract NovaGameAccess is iNovaGame {
  using SafeMath for uint256;

  event AdminPrivilegesChanged(uint indexed game, address indexed account, bool isAdmin);
  event OperatorPrivilegesChanged(uint indexed game, address indexed account, bool isAdmin);

   
  mapping(uint => address[]) public adminAddressesByGameId; 
  mapping(address => uint[]) public gameIdsByAdminAddress;

   
  mapping(uint => mapping(address => bool)) public gameAdmins;

   
  iNovaStaking public stakingContract;

   
  modifier onlyGameAdmin(uint _game) {
    require(gameAdmins[_game][msg.sender]);
    _;
  }

  constructor(address _stakingContract)
    public
  {
    stakingContract = iNovaStaking(_stakingContract);
  }

   
   
   
   
  function isAdminForGame(uint _game, address _account)
    external
    view
  returns(bool) {
    return gameAdmins[_game][_account];
  }

   
   
   
  function getAdminsForGame(uint _game) 
    external
    view
  returns(address[]) {
    return adminAddressesByGameId[_game];
  }

   
   
   
  function getGamesForAdmin(address _account) 
    external
    view
  returns(uint[]) {
    return gameIdsByAdminAddress[_account];
  }

   
   
   
   
  function addAdminAccount(uint _game, address _account)
    external
    onlyGameAdmin(_game)
  {
    require(_account != msg.sender);
    require(_account != address(0));
    require(!gameAdmins[_game][_account]);
    _addAdminAccount(_game, _account);
  }

   
   
   
   
   
  function removeAdminAccount(uint _game, address _account)
    external
    onlyGameAdmin(_game)
  {
    require(_account != msg.sender);
    require(gameAdmins[_game][_account]);
    
    address[] storage opsAddresses = adminAddressesByGameId[_game];
    uint startingLength = opsAddresses.length;
     
    for (uint i = opsAddresses.length - 1; i < startingLength; i--) {
      if (opsAddresses[i] == _account) {
        uint newLength = opsAddresses.length.sub(1);
        opsAddresses[i] = opsAddresses[newLength];
        delete opsAddresses[newLength];
        opsAddresses.length = newLength;
      }
    }

    uint[] storage gamesByAdmin = gameIdsByAdminAddress[_account];
    startingLength = gamesByAdmin.length;
    for (i = gamesByAdmin.length - 1; i < startingLength; i--) {
      if (gamesByAdmin[i] == _game) {
        newLength = gamesByAdmin.length.sub(1);
        gamesByAdmin[i] = gamesByAdmin[newLength];
        delete gamesByAdmin[newLength];
        gamesByAdmin.length = newLength;
      }
    }

    gameAdmins[_game][_account] = false;
    emit AdminPrivilegesChanged(_game, _account, false);
  }

   
   
   
   
   
   
  function setOperatorPrivileges(uint _game, address _account, bool _isOperator)
    external
    onlyGameAdmin(_game)
  {
    emit OperatorPrivilegesChanged(_game, _account, _isOperator);
  }

   
   
   
  function _addAdminAccount(uint _game, address _account)
    internal
  {
    address[] storage opsAddresses = adminAddressesByGameId[_game];
    require(opsAddresses.length < 256, "a game can only have 256 admins");
    for (uint i = opsAddresses.length; i < opsAddresses.length; i--) {
      require(opsAddresses[i] != _account);
    }

    uint[] storage gamesByAdmin = gameIdsByAdminAddress[_account];
    require(gamesByAdmin.length < 256, "you can only own 256 games");
    for (i = gamesByAdmin.length; i < gamesByAdmin.length; i--) {
      require(gamesByAdmin[i] != _game, "you can't become an operator twice");
    }
    gamesByAdmin.push(_game);

    opsAddresses.push(_account);
    gameAdmins[_game][_account] = true;
    emit AdminPrivilegesChanged(_game, _account, true);
  }
}


 
 
 
 
contract NovaGame is NovaGameAccess {

  struct GameData {
    string json;
    uint tradeLockSeconds;
    bytes32[] metadata;
  }

  event GameCreated(uint indexed game, address indexed owner, string json, bytes32[] metadata);

  event GameMetadataUpdated(
    uint indexed game, 
    string json,
    uint tradeLockSeconds, 
    bytes32[] metadata
  );

  mapping(uint => GameData) internal gameData;

  constructor(address _stakingContract) 
    public 
    NovaGameAccess(_stakingContract)
  {
    games.push(2**32);
  }

   
   
   
   
   
   
  function createGame(string _json, uint _tradeLockSeconds, bytes32[] _metadata) 
    external
  returns(uint _game) {
     
    _game = games.length;
    require(_game < games[0], "too many games created");
    games.push(_game);

     
    emit GameCreated(_game, msg.sender, _json, _metadata);

     
    _addAdminAccount(_game, msg.sender);

     
    updateGameMetadata(_game, _json, _tradeLockSeconds, _metadata);
  }

   
   
  function numberOfGames() 
    external
    view
  returns(uint) {
    return games.length;
  }

   
   
   
   
   
   
   
  function getGameData(uint _game)
    external
    view
  returns(uint game,
    string json,
    uint tradeLockSeconds,
    uint256 balance,
    bytes32[] metadata) 
  {
    GameData storage data = gameData[_game];
    game = _game;
    json = data.json;
    tradeLockSeconds = data.tradeLockSeconds;
    balance = stakingContract.balanceOf(address(_game));
    metadata = data.metadata;
  }

   
   
   
   
   
  function updateGameMetadata(uint _game, string _json, uint _tradeLockSeconds, bytes32[] _metadata)
    public
    onlyGameAdmin(_game)
  {
    gameData[_game].tradeLockSeconds = _tradeLockSeconds;
    gameData[_game].json = _json;

    bytes32[] storage data = gameData[_game].metadata;
    if (_metadata.length > data.length) { data.length = _metadata.length; }
    for (uint k = 0; k < _metadata.length; k++) { data[k] = _metadata[k]; }
    for (k; k < data.length; k++) { delete data[k]; }
    if (_metadata.length < data.length) { data.length = _metadata.length; }

    emit GameMetadataUpdated(_game, _json, _tradeLockSeconds, _metadata);
  }
}
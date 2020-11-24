 

 

pragma solidity ^0.5.2;

 
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

     
    function owner() public view returns (address) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

     
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

     
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

     
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

 

pragma solidity 0.5.4;


interface IWhitelistable {
    event Whitelisted(address account);
    event Unwhitelisted(address account);

    function isWhitelisted(address account) external returns (bool);
    function whitelist(address account) external;
    function unwhitelist(address account) external;
    function isModerator(address account) external view returns (bool);
    function renounceModerator() external;
}

 

pragma solidity ^0.5.2;

 
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

     
    function add(Role storage role, address account) internal {
        require(account != address(0));
        require(!has(role, account));

        role.bearer[account] = true;
    }

     
    function remove(Role storage role, address account) internal {
        require(account != address(0));
        require(has(role, account));

        role.bearer[account] = false;
    }

     
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0));
        return role.bearer[account];
    }
}

 

pragma solidity 0.5.4;



 
contract ModeratorRole {
    using Roles for Roles.Role;

    event ModeratorAdded(address indexed account);
    event ModeratorRemoved(address indexed account);

    Roles.Role internal _moderators;

    modifier onlyModerator() {
        require(isModerator(msg.sender), "Only Moderators can execute this function.");
        _;
    }

    constructor() internal {
        _addModerator(msg.sender);
    }

    function isModerator(address account) public view returns (bool) {
        return _moderators.has(account);
    }

    function addModerator(address account) public onlyModerator {
        _addModerator(account);
    }

    function renounceModerator() public {
        _removeModerator(msg.sender);
    }    

    function _addModerator(address account) internal {
        _moderators.add(account);
        emit ModeratorAdded(account);
    }    

    function _removeModerator(address account) internal {
        _moderators.remove(account);
        emit ModeratorRemoved(account);
    }
}

 

pragma solidity 0.5.4;





 
contract BatchWhitelister is ModeratorRole, Ownable {
  event BatchWhitelisted(address indexed from, uint accounts);
  event BatchUnwhitelisted(address indexed from, uint accounts);

  IWhitelistable public rewards;  

  constructor(IWhitelistable _contract) public {
      rewards = _contract;
  }

  function batchWhitelist(address[] memory accounts) public onlyModerator {
    bool isModerator = rewards.isModerator(address(this));
    require(isModerator, 'This contract is not a moderator.');

    emit BatchWhitelisted(msg.sender, accounts.length);
    for (uint i = 0; i < accounts.length; i++) {
      rewards.whitelist(accounts[i]);
    }
  }

  function batchUnwhitelist(address[] memory accounts) public onlyModerator {
    bool isModerator = rewards.isModerator(address(this));
    require(isModerator, 'This contract is not a moderator.');

    emit BatchUnwhitelisted(msg.sender, accounts.length);
    for (uint i = 0; i < accounts.length; i++) {
      rewards.unwhitelist(accounts[i]);
    }
  }

  function disconnect() public onlyOwner {
    rewards.renounceModerator();
  }
}
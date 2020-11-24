 

 

pragma solidity >=0.4.24 <0.6.0;


 
contract Initializable {

   
  bool private initialized;

   
  bool private initializing;

   
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool wasInitializing = initializing;
    initializing = true;
    initialized = true;

    _;

    initializing = wasInitializing;
  }

   
  function isConstructor() private view returns (bool) {
     
     
     
     
     
    uint256 cs;
    assembly { cs := extcodesize(address) }
    return cs == 0;
  }

   
  uint256[50] private ______gap;
}

 

pragma solidity ^0.5.0;

contract ERC20Interface {
    function balanceOf(address from) public view returns (uint256);
    function transferFrom(address from, address to, uint tokens) public returns (bool);
    function allowance(address owner, address spender) public view returns (uint256);
    function burn(uint256 amount) public;
}

contract AvatarNameStorage {
     
    ERC20Interface public manaToken;
    uint256 public blocksUntilReveal;
    uint256 public price;

    struct Data {
        string username;
        string metadata;
    }
    struct Commit {
        bytes32 commit;
        uint256 blockNumber;
        bool revealed;
    }

     
    mapping (address => Commit) public commit;
     
    mapping (string => address) usernames;
     
    mapping (address => Data) public user;
     
    mapping (address => bool) public allowed;

     
    event Register(
        address indexed _owner,
        string _username,
        string _metadata,
        address indexed _caller
    );
    event MetadataChanged(address indexed _owner, string _metadata);
    event Allow(address indexed _caller, address indexed _account, bool _allowed);
    event CommitUsername(address indexed _owner, bytes32 indexed _hash, uint256 _blockNumber);
    event RevealUsername(address indexed _owner, bytes32 indexed _hash, uint256 _blockNumber);
}

 

pragma solidity ^0.5.0;




contract AvatarNameRegistry is Initializable, AvatarNameStorage {

     
    function initialize(
        ERC20Interface _mana,
        address _register,
        uint256 _blocksUntilReveal
    )
    public initializer
    {
        require(_blocksUntilReveal != 0, "Blocks until reveal should be greather than 0");


        manaToken = _mana;
        blocksUntilReveal = _blocksUntilReveal;
        price = 100000000000000000000;  

         
        allowed[_register] = true;
    }

     
    modifier onlyAllowed() {
        require(
            allowed[msg.sender] == true,
            "The sender is not allowed to register a username"
        );
        _;
    }

     
    function setAllowed(address _account, bool _allowed) external onlyAllowed {
        require(_account != msg.sender, "You can not manage your role");
        allowed[_account] = _allowed;
        emit Allow(msg.sender, _account, _allowed);
    }

     
    function _registerUsername(
        address _beneficiary,
        string memory _username,
        string memory _metadata
    )
    internal
    {
        _requireUsernameValid(_username);
        require(isUsernameAvailable(_username), "The username was already taken");

         
        usernames[_username] = _beneficiary;

        Data storage data = user[_beneficiary];

         
        delete usernames[data.username];

         
        data.username = _username;

        bytes memory metadata = bytes(_metadata);
        if (metadata.length > 0) {
            data.metadata = _metadata;
        }

        emit Register(
            _beneficiary,
            _username,
            data.metadata,
            msg.sender
        );
    }

     
    function registerUsername(
        address _beneficiary,
        string calldata _username,
        string calldata _metadata
    )
    external
    onlyAllowed
    {
        _registerUsername(_beneficiary, _username, _metadata);
    }

     
    function commitUsername(bytes32 _hash) public {
        commit[msg.sender].commit = _hash;
        commit[msg.sender].blockNumber = block.number;
        commit[msg.sender].revealed = false;

        emit CommitUsername(msg.sender, _hash, block.number);
    }

     
    function revealUsername(
        string memory _username,
        string memory _metadata,
        bytes32 _salt
    )
    public
    {
        Commit storage userCommit = commit[msg.sender];

        require(userCommit.commit != 0, "User has not a commit to be revealed");
        require(userCommit.revealed == false, "Commit was already revealed");
        require(
            getHash(_username, _metadata, _salt) == userCommit.commit,
            "Revealed hash does not match commit"
        );
        require(
            block.number > userCommit.blockNumber + blocksUntilReveal,
            "Reveal can not be done before blocks passed"
        );

        userCommit.revealed = true;

        emit RevealUsername(msg.sender, userCommit.commit, block.number);

        _registerUsername(msg.sender, _username, _metadata);
    }

     
    function getHash(
        string memory _username,
        string memory _metadata,
        bytes32 _salt
    )
    public
    view
    returns (bytes32)
    {
        return keccak256(
            abi.encodePacked(address(this), _username, _metadata, _salt)
        );
    }

     
    function setMetadata(string calldata _metadata) external {
        require(userExists(msg.sender), "The user does not exist");

        user[msg.sender].metadata = _metadata;
        emit MetadataChanged(msg.sender, _metadata);
    }

     
    function userExists(address _user) public view returns (bool) {
        Data memory data = user[_user];
        bytes memory username = bytes(data.username);
        return username.length > 0;
    }

     
    function isUsernameAvailable(string memory _username) public view returns (bool) {
        return usernames[_username] == address(0);
    }

     
    function _requireUsernameValid(string memory _username) internal pure {
        bytes memory tempUsername = bytes(_username);
        require(tempUsername.length <= 32, "Username should be less than or equal 32 characters");
        for(uint256 i = 0; i < tempUsername.length; i++) {
            require(tempUsername[i] != " ", "No blanks are allowed");
        }
    }

     
    function _requireBalance(address _user) internal view {
        require(
            manaToken.balanceOf(_user) >= price,
            "Insufficient funds"
        );
        require(
            manaToken.allowance(_user, address(this)) >= price,
            "The contract is not authorized to use MANA on sender behalf"
        );
    }
}
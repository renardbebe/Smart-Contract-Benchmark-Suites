 

pragma solidity ^0.4.24;

 

 

pragma solidity ^0.4.23;


 
contract ERC20Interface {
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed from, address indexed spender, uint256 value);

    string public symbol;

    function decimals() public view returns (uint8);
    function totalSupply() public view returns (uint256 supply);

    function balanceOf(address _owner) public view returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);
}

 

 

pragma solidity ^0.4.23;



 
 
 
 
contract Owned {

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    address public contractOwner;
    address public pendingContractOwner;

    modifier onlyContractOwner {
        if (msg.sender == contractOwner) {
            _;
        }
    }

    constructor()
    public
    {
        contractOwner = msg.sender;
    }

     
     
     
     
    function changeContractOwnership(address _to)
    public
    onlyContractOwner
    returns (bool)
    {
        if (_to == 0x0) {
            return false;
        }
        pendingContractOwner = _to;
        return true;
    }

     
     
     
    function claimContractOwnership()
    public
    returns (bool)
    {
        if (msg.sender != pendingContractOwner) {
            return false;
        }

        emit OwnershipTransferred(contractOwner, pendingContractOwner);
        contractOwner = pendingContractOwner;
        delete pendingContractOwner;
        return true;
    }

     
     
    function transferOwnership(address newOwner)
    public
    onlyContractOwner
    returns (bool)
    {
        if (newOwner == 0x0) {
            return false;
        }

        emit OwnershipTransferred(contractOwner, newOwner);
        contractOwner = newOwner;
        delete pendingContractOwner;
        return true;
    }

     
     
    function withdrawTokens(address[] tokens)
    public
    onlyContractOwner
    {
        address _contractOwner = contractOwner;
        for (uint i = 0; i < tokens.length; i++) {
            ERC20Interface token = ERC20Interface(tokens[i]);
            uint balance = token.balanceOf(this);
            if (balance > 0) {
                token.transfer(_contractOwner, balance);
            }
        }
    }

     
     
    function withdrawEther()
    public
    onlyContractOwner
    {
        uint balance = address(this).balance;
        if (balance > 0)  {
            contractOwner.transfer(balance);
        }
    }

     
     
     
     
    function transferEther(address _to, uint256 _value) 
    public 
    onlyContractOwner 
    {
        require(_to != 0x0, "INVALID_ETHER_RECEPIENT_ADDRESS");
        if (_value > address(this).balance) {
            revert("INVALID_VALUE_TO_TRANSFER_ETHER");
        }
        
        _to.transfer(_value);
    }
}

 

 
library Roles {
  struct Role {
    mapping (address => bool) bearer;
  }

   
  function add(Role storage role, address account) internal {
    require(account != address(0));
    role.bearer[account] = true;
  }

   
  function remove(Role storage role, address account) internal {
    require(account != address(0));
    role.bearer[account] = false;
  }

   
  function has(Role storage role, address account)
    internal
    view
    returns (bool)
  {
    require(account != address(0));
    return role.bearer[account];
  }
}

 

contract SignerRole {
  using Roles for Roles.Role;

  event SignerAdded(address indexed account);
  event SignerRemoved(address indexed account);

  Roles.Role private signers;

  constructor() public {
    _addSigner(msg.sender);
  }

  modifier onlySigner() {
    require(isSigner(msg.sender));
    _;
  }

  function isSigner(address account) public view returns (bool) {
    return signers.has(account);
  }

  function addSigner(address account) public onlySigner {
    _addSigner(account);
  }

  function renounceSigner() public {
    _removeSigner(msg.sender);
  }

  function _addSigner(address account) internal {
    signers.add(account);
    emit SignerAdded(account);
  }

  function _removeSigner(address account) internal {
    signers.remove(account);
    emit SignerRemoved(account);
  }
}

 

contract PauserRole {
  using Roles for Roles.Role;

  event PauserAdded(address indexed account);
  event PauserRemoved(address indexed account);

  Roles.Role private pausers;

  constructor() public {
    _addPauser(msg.sender);
  }

  modifier onlyPauser() {
    require(isPauser(msg.sender));
    _;
  }

  function isPauser(address account) public view returns (bool) {
    return pausers.has(account);
  }

  function addPauser(address account) public onlyPauser {
    _addPauser(account);
  }

  function renouncePauser() public {
    _removePauser(msg.sender);
  }

  function _addPauser(address account) internal {
    pausers.add(account);
    emit PauserAdded(account);
  }

  function _removePauser(address account) internal {
    pausers.remove(account);
    emit PauserRemoved(account);
  }
}

 

 
contract Pausable is PauserRole {
  event Paused();
  event Unpaused();

  bool private _paused = false;


   
  function paused() public view returns(bool) {
    return _paused;
  }

   
  modifier whenNotPaused() {
    require(!_paused);
    _;
  }

   
  modifier whenPaused() {
    require(_paused);
    _;
  }

   
  function pause() public onlyPauser whenNotPaused {
    _paused = true;
    emit Paused();
  }

   
  function unpause() public onlyPauser whenPaused {
    _paused = false;
    emit Unpaused();
  }
}

 

 
interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender)
    external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value)
    external returns (bool);

  function transferFrom(address from, address to, uint256 value)
    external returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

 

 

interface ERC223ReceivingContract {
 
    function tokenFallback(address _from, uint _value, bytes _data) external;
}

 

 
 
 
 
contract Airdrop is Owned, SignerRole, Pausable, ERC223ReceivingContract {

    uint constant OK = 1;

     
    event LogAirdropClaimed(address indexed initiator, bytes32 operationId, uint amount);
     
    event LogMerkleRootUpdated(bytes32 to, address by);

     
    bytes32 public version = "0.2.0";
     
    IERC20 public token;
     
    bytes32 public merkleRoot;
     
    mapping(bytes32 => bool) public completedAirdrops;

     
     
    constructor(address _token)
    public
    {
        require(_token != 0x0, "AIRDROP_INVALID_TOKEN_ADDRESS");
        token = IERC20(_token);
    }

     
     
     
     
     
    function setMerkleRoot(bytes32 _updatedMerkleRoot)
    external
    onlySigner
    returns (uint)
    {
        merkleRoot = _updatedMerkleRoot;

        emit LogMerkleRootUpdated(_updatedMerkleRoot, msg.sender);
        return OK;
    }

     
     
     
     
     
     
     
     
    function claimTokensByMerkleProof(
        bytes32[] _proof,
        bytes32 _operationId,
        uint _position,
        uint _amount
    )
    external
    whenNotPaused
    returns (uint)
    {
        bytes32 leaf = _calculateMerkleLeaf(_operationId, _position, msg.sender, _amount);

        require(completedAirdrops[_operationId] == false, "AIRDROP_ALREADY_CLAIMED");
        require(checkMerkleProof(merkleRoot, _proof, _position, leaf), "AIRDROP_INVALID_PROOF");
        require(token.transfer(msg.sender, _amount), "AIRDROP_TRANSFER_FAILURE");

         
        completedAirdrops[_operationId] = true;

        emit LogAirdropClaimed(msg.sender, _operationId, _amount);
        return OK;
    }

     
     
     
     
     
     
    function checkMerkleProof(
        bytes32 _merkleRoot,
        bytes32[] _proof,
        uint _position,
        bytes32 _leaf
    )
    public
    pure
    returns (bool)
    {
        bytes32 _computedHash = _leaf;
        uint _checkedPosition = _position;

        for (uint i = 0; i < _proof.length; i += 1) {
            bytes32 _proofElement = _proof[i];

            if (_checkedPosition % 2 == 0) {
                _computedHash = keccak256(abi.encodePacked(_computedHash, _proofElement));
            } else {
                _computedHash = keccak256(abi.encodePacked(_proofElement, _computedHash));
            }

            _checkedPosition /= 2;
        }

        return _computedHash == _merkleRoot;
    }

     

     
    function tokenFallback(address  , uint  , bytes  )
    external
    whenNotPaused
    {
        require(msg.sender == address(token), "AIRDROP_TOKEN_NOT_SUPPORTED");
    }

     

     
     
    function _calculateMerkleLeaf(bytes32 _operationId, uint _index, address _address, uint _amount)
    private
    pure
    returns (bytes32)
    {
        return keccak256(abi.encodePacked(_operationId, _index, _address, _amount));
    }
}

 

 

pragma solidity ^0.4.24;
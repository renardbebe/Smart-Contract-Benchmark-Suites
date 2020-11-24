 

pragma solidity ^0.5.0;
 
 
 
 
 
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
        require(isOwner(), "Ownable: caller is not the owner");
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

     
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

     
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

     
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

contract IERC721Receiver {
     
    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data)
    public returns (bytes4);
}

interface ERC721   {
  event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
  event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
  event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
  function balanceOf(address _owner) external view returns (uint256);
  function ownerOf(uint256 _tokenId) external view returns (address);
  function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata data) external payable;
  function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;
  function transferFrom(address _from, address _to, uint256 _tokenId) external payable;
  function approve(address _approved, uint256 _tokenId) external payable;
  function setApprovalForAll(address _operator, bool _approved) external;
  function getApproved(uint256 _tokenId) external view returns (address);
  function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

interface ERC165 {
  function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

contract ERC721Holder is IERC721Receiver {
    function onERC721Received(address, address, uint256, bytes memory) public returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

contract OperatorRole is Ownable {
  using Roles for Roles.Role;

  event OperatorAdded(address indexed account);
  event OperatorRemoved(address indexed account);

  event Paused(address account);
  event Unpaused(address account);

  bool private _paused;

  Roles.Role private operators;

  constructor() public {
    operators.add(msg.sender);
    _paused = false;
  }

  modifier onlyOperator() {
    require(isOperator(msg.sender));
    _;
  }

  modifier whenNotPaused() {
    require(!_paused, "Pausable: paused");
    _;
  }

  modifier whenPaused() {
    require(_paused, "Pausable: not paused");
    _;
  }

  function isOperator(address account) public view returns (bool) {
    return operators.has(account);
  }

  function addOperator(address account) public onlyOwner() {
    operators.add(account);
    emit OperatorAdded(account);
  }

  function removeOperator(address account) public onlyOwner() {
    operators.remove(account);
    emit OperatorRemoved(account);
  }

  function paused() public view returns (bool) {
    return _paused;
  }

  function pause() public onlyOperator() whenNotPaused() {
    _paused = true;
    emit Paused(msg.sender);
  }

  function unpause() public onlyOperator whenPaused() {
    _paused = false;
    emit Unpaused(msg.sender);
  }

}

contract ERC721Converter is ERC721Holder, OperatorRole {
  ERC721 Alice;
  ERC721 Bob;

  address public aliceContract;
  address public bobContract;

  bool public approveOnce = false;

  mapping (uint256 => uint256) private _idMapAliceToBob;
  mapping (uint256 => uint256) private _idMapBobToAlice;

  constructor(address _alice, address _bob) public {
    aliceContract = _alice;
    bobContract = _bob;
    Alice = ERC721(aliceContract);
    Bob = ERC721(bobContract);
  }

  function approve(address _spender) external onlyOwner() {
    require(approveOnce != true);
    Alice.setApprovalForAll(_spender, true);
    Bob.setApprovalForAll(_spender, true);
    approveOnce = true;
  }

  function dismiss(address _spender) external onlyOwner() {
    Alice.setApprovalForAll(_spender, false);
    Bob.setApprovalForAll(_spender, false);
  }

  function updateAlice(address _newAlice) external onlyOperator() {
    aliceContract = _newAlice;
    Alice = ERC721(_newAlice);
  }

  function updateBob(address _newBob) external onlyOperator() {
    bobContract = _newBob;
    Bob = ERC721(_newBob);
  }

  function draftAliceTokens(uint256[] memory _aliceTokenIds, uint256[] memory _bobTokenIds) public onlyOperator() {
    require(_aliceTokenIds.length == _bobTokenIds.length);
    for (uint256 i = 0; i < _aliceTokenIds.length; i++) {
      draftAliceToken(_aliceTokenIds[i], _bobTokenIds[i]);
    }
  }

  function draftBobTokens(uint256[] memory _bobTokenIds, uint256[] memory _aliceTokenIds) public onlyOperator() {
    require(_aliceTokenIds.length == _bobTokenIds.length);
    for (uint256 i = 0; i < _aliceTokenIds.length; i++) {
      draftBobToken(_bobTokenIds[i], _aliceTokenIds[i]);
    }
  }

  function draftAliceToken(uint256 _aliceTokenId, uint256 _bobTokenId) public onlyOperator() {
    require(Alice.ownerOf(_aliceTokenId) == address(this), "_aliceTokenId is not owned");
    require(_idMapAliceToBob[_aliceTokenId] == 0, "_aliceTokenId is already assignd");
    require(_idMapBobToAlice[_bobTokenId] == 0, "_bobTokenId is already assignd");

    _idMapAliceToBob[_aliceTokenId] = _bobTokenId;
    _idMapBobToAlice[_bobTokenId] = _aliceTokenId;
  }

  function draftBobToken(uint256 _bobTokenId, uint256 _aliceTokenId) public onlyOperator() {
    require(Bob.ownerOf(_bobTokenId) == address(this), "_bobTokenId is not owned");
    require(_idMapBobToAlice[_bobTokenId] == 0, "_bobTokenId is already assignd");
    require(_idMapAliceToBob[_aliceTokenId] == 0, "_aliceTokenId is already assignd");

    _idMapBobToAlice[_bobTokenId] = _aliceTokenId;
    _idMapAliceToBob[_aliceTokenId] = _bobTokenId;
  }

  function getBobTokenID(uint256 _aliceTokenId) public view returns(uint256) {
    return _idMapAliceToBob[_aliceTokenId];
  }

  function getAliceTokenID(uint256 _bobTokenId) public view returns(uint256) {
    return _idMapBobToAlice[_bobTokenId];
  }

  function convertFromAliceToBob(uint256 _tokenId) external whenNotPaused() {
    Alice.safeTransferFrom(msg.sender, address(this), _tokenId);
    Bob.safeTransferFrom(address(this), msg.sender, getBobTokenID(_tokenId));
  }

  function convertFromBobToAlice(uint256 _tokenId) external whenNotPaused() {
    Bob.safeTransferFrom(msg.sender, address(this), _tokenId);
    Alice.safeTransferFrom(address(this), msg.sender, getAliceTokenID(_tokenId));
  }
}
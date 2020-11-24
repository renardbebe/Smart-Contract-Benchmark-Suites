 

pragma solidity ^0.4.24; 

interface ERC721   {
     
     
     
     
     
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

     
     
     
     
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

     
     
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

     
     
     
     
     
    function balanceOf(address _owner) external view returns (uint256);

     
     
     
     
     
    function ownerOf(uint256 _tokenId) external view returns (address);

     
     
     
     
     
     
     
     
     
     
     
     
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes data) external;

     
     
     
     
     
     
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external;

     
     
     
     
     
     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _tokenId) external;

     
     
     
     
     
     
    function approve(address _approved, uint256 _tokenId) external;

     
     
     
     
     
     
    function setApprovalForAll(address _operator, bool _approved) external;

     
     
     
     
    function getApproved(uint256 _tokenId) external view returns (address);

     
     
     
     
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

 
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

   
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

   
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

interface AvatarService {
  function updateAvatarInfo(address _owner, uint256 _tokenId, string _name, uint256 _dna) external;
  function createAvatar(address _owner, string _name, uint256 _dna) external  returns(uint256);
  function getMountedChildren(address _owner,uint256 _tokenId, address _childAddress) external view returns(uint256[]); 
  function getAvatarInfo(uint256 _tokenId) external view returns (string _name, uint256 _dna);
  function getOwnedAvatars(address _owner) external view returns(uint256[] _avatars);
  function unmount(address _owner, address _childContract, uint256[] _children, uint256 _avatarId) external;
  function mount(address _owner, address _childContract, uint256[] _children, uint256 _avatarId) external;
}

contract AvatarOperator is Ownable {

   
  uint8 public PER_USER_MAX_AVATAR_COUNT = 1;

  event AvatarCreate(address indexed _owner, uint256 tokenId);

  AvatarService internal avatarService;
  address internal avatarAddress;

  modifier nameValid(string _name){
    bytes memory nameBytes = bytes(_name);
    require(nameBytes.length > 0);
    require(nameBytes.length < 16);
    for(uint8 i = 0; i < nameBytes.length; ++i) {
      uint8 asc = uint8(nameBytes[i]);
      require (
        asc == 95 || (asc >= 48 && asc <= 57) || (asc >= 65 && asc <= 90) || (asc >= 97 && asc <= 122), "Invalid name"); 
    }
    _;
  }

  function setMaxAvatarNumber(uint8 _maxNumber) external onlyOwner {
    PER_USER_MAX_AVATAR_COUNT = _maxNumber;
  }

  function injectAvatarService(address _addr) external onlyOwner {
    avatarService = AvatarService(_addr);
    avatarAddress = _addr;
  }
  
  function updateAvatarInfo(uint256 _tokenId, string _name, uint256 _dna) external nameValid(_name){
    avatarService.updateAvatarInfo(msg.sender, _tokenId, _name, _dna);
  }

  function createAvatar(string _name, uint256 _dna) external nameValid(_name) returns (uint256 _tokenId){
    require(ERC721(avatarAddress).balanceOf(msg.sender) < PER_USER_MAX_AVATAR_COUNT, "overflow");
    _tokenId = avatarService.createAvatar(msg.sender, _name, _dna);
    emit AvatarCreate(msg.sender, _tokenId);
  }

  function getMountedChildren(uint256 _tokenId, address _avatarItemAddress) external view returns(uint256[]){
    return avatarService.getMountedChildren(msg.sender, _tokenId, _avatarItemAddress);
  }

  function getAvatarInfo(uint256 _tokenId) external view returns (string _name, uint256 _dna) {
    return avatarService.getAvatarInfo(_tokenId);
  }

  function getOwnedAvatars() external view returns(uint256[] _tokenIds) {
    return avatarService.getOwnedAvatars(msg.sender);
  }
 
  function handleChildren(
	address _childContract, 
	uint256[] _unmountChildren,  
	uint256[] _mountChildren,    
	uint256 _avatarId)            
	external {
	require(_childContract != address(0), "child address error");
	avatarService.unmount(msg.sender, _childContract, _unmountChildren, _avatarId);
	avatarService.mount(msg.sender, _childContract, _mountChildren, _avatarId);
  }
}
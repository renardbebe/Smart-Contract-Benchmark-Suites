 

pragma solidity ^0.5.0;

interface ERC721Mintable {
  function mint(address to, uint256 tokenId) external returns (bool);
  function isMinter(address account) external view returns (bool);
  function renounceMinter() external;

  function mintHeroAsset(address _owner, uint256 _tokenId) external;
  function mintExtensionAsset(address _owner, uint256 _tokenId) external;
}

contract ERC721BultMinter {

  ERC721Mintable erc721;
  address public operator;
  address payable public owner;

  modifier onlyOperator() {
    require((msg.sender == operator || msg.sender == owner));
    _;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  constructor() public {
    owner = msg.sender;
  }

  function renounce() public onlyOperator() {
    erc721.renounceMinter();
  }

  function setOpeartor(address _operator) external onlyOwner() {
    operator = _operator;
  }

  function isMinter(address _target) public view returns (bool) {
    ERC721Mintable target = ERC721Mintable(_target);
    return target.isMinter(address(this));
  }

  function getContract() public view returns (address) {
    return address(erc721);
  }

  function setContract(address payable _new) external onlyOperator() {
    erc721 = ERC721Mintable(_new);
    require(isMinter(_new), "address(this) is must be minter");
  }

  function kill() external onlyOperator() {
    selfdestruct(owner);
  }

  function mint(uint256[] calldata _tokenIds, address[] calldata _owners) external onlyOperator() {
    require(_tokenIds.length == _owners.length);
    for (uint256 i = 0; i < _tokenIds.length; i++) {
      erc721.mint(_owners[i], _tokenIds[i]);
    }
  }

}
 

contract Flower is ERC721Token, Privileged, RemoteTokenURI {
   
  uint8 constant PRIV_ROOT = 1;
  uint8 constant PRIV_MINT = 2;

  mapping(uint256 => bytes) internal tokenDataMap;

  constructor() public ERC721Token("Flower", "FLOWER") Privileged(PRIV_ROOT) RemoteTokenURI(PRIV_ROOT) {
     
    grantPrivileges(msg.sender, PRIV_MINT);
  }

  function tokenData(uint256 _tokenId) public view returns(bytes) {
    require(exists(_tokenId));
    return tokenDataMap[_tokenId];
  }

  function mint(address _to, bytes _tokenData) public requirePrivileges(PRIV_MINT) returns (uint256) {
    uint256 tokenId = allTokens.length;
    super._mint(_to, tokenId);

    tokenDataMap[tokenId] = _tokenData;

    return tokenId;
  }

  function _burn(address _owner, uint256 _tokenId) internal {
    super._burn(_owner, _tokenId);

    delete tokenDataMap[_tokenId];
  }
}

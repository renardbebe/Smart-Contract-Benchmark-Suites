 
contract StickerPack is Controlled, TokenClaimer, ERC721Full("Status Sticker Pack","STKP") {

    mapping(uint256 => uint256) public tokenPackId;  
    uint256 public tokenCount;  

     
    function generateToken(address _owner, uint256 _packId)
        external
        onlyController
        returns (uint256 tokenId)
    {
        tokenId = tokenCount++;
        tokenPackId[tokenId] = _packId;
        _mint(_owner, tokenId);
    }

     
    function claimTokens(address _token)
        external
        onlyController
    {
        withdrawBalance(_token, controller);
    }



}
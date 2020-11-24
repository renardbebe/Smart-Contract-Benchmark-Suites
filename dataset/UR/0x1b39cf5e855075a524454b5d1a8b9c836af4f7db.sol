 

 

pragma solidity ^0.4.24;

library SafeMath {

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract HashFutureBasicToken {

    using SafeMath for uint256;

     
    mapping (uint256 => address) internal tokenOwner;

     
    mapping (address => uint256) internal ownedTokensCount;

    modifier onlyOwnerOf(uint256 _tokenId) {
        require(tokenOwner[_tokenId] == msg.sender);
        _;
    }

    function balanceOf(address _owner) public view returns (uint256) {
        return ownedTokensCount[_owner];
    }

    function ownerOf(uint256 _tokenId) public view returns (address) {
        address owner = tokenOwner[_tokenId];
        return owner;
    }

    function addTokenTo(address _to, uint256 _tokenId) internal {
        require(tokenOwner[_tokenId] == address(0));
        tokenOwner[_tokenId] = _to;
        ownedTokensCount[_to] = ownedTokensCount[_to].add(1);
    }

    function removeTokenFrom(address _from, uint256 _tokenId) internal {
        require(ownerOf(_tokenId) == _from);
        ownedTokensCount[_from] = ownedTokensCount[_from].sub(1);
        tokenOwner[_tokenId] = address(0);
    }

    function _mint(address _to, uint256 _tokenId) internal {
        require(_to != address(0));
        addTokenTo(_to, _tokenId);
    }

    function _burn(address _owner, uint256 _tokenId) internal {
        removeTokenFrom(_owner, _tokenId);
    }
}


contract HashFutureToken is HashFutureBasicToken{

    string internal name_;
    string internal symbol_;

    address public owner;

     
    uint256[] internal allTokens;

     
    mapping(uint256 => uint256) internal allTokensIndex;

     
    mapping (address => uint256[]) internal ownedTokens;

     
    mapping(uint256 => uint256) internal ownedTokensIndex;

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    constructor(string _name, string _symbol) public {
        name_ = _name;
        symbol_ = _symbol;
        owner = msg.sender;
    }


    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }

    function name() external view returns (string) {
        return name_;
    }

    function symbol() external view returns (string) {
        return symbol_;
    }

    function totalSupply() external view returns (uint256) {
        return allTokens.length;
    }

    function tokenByIndex(uint256 _index) external view returns (uint256) {
        require(_index < allTokens.length);
        return allTokens[_index];
    }

    function tokenOfOwnerByIndex(
        address _owner,
        uint256 _index
    )
        external view returns (uint256)
    {
        require(_index < balanceOf(_owner));
        return ownedTokens[_owner][_index];
    }

    function addTokenTo(address _to, uint256 _tokenId) internal {
        super.addTokenTo(_to, _tokenId);

        uint256 length = ownedTokens[_to].length;
        ownedTokens[_to].push(_tokenId);
        ownedTokensIndex[_tokenId] = length;
    }

    function removeTokenFrom(address _from, uint256 _tokenId) internal {
        super.removeTokenFrom(_from, _tokenId);

        uint256 tokenIndex = ownedTokensIndex[_tokenId];
        uint256 lastTokenIndex = ownedTokens[_from].length.sub(1);
        uint256 lastToken = ownedTokens[_from][lastTokenIndex];

        ownedTokens[_from][tokenIndex] = lastToken;
        ownedTokens[_from][lastTokenIndex] = 0;

        ownedTokens[_from].length = ownedTokens[_from].length.sub(1);
        ownedTokensIndex[_tokenId] = 0;
        ownedTokensIndex[lastToken] = tokenIndex;
    }

    function _mint(address _to, uint256 _tokenId) internal {
        super._mint(_to, _tokenId);

        allTokensIndex[_tokenId] = allTokens.length;
        allTokens.push(_tokenId);
    }

    function _burn(address _owner, uint256 _tokenId) internal {
        super._burn(_owner, _tokenId);

        uint256 tokenIndex = allTokensIndex[_tokenId];
        uint256 lastTokenIndex = allTokens.length.sub(1);
        uint256 lastToken = allTokens[lastTokenIndex];

        allTokens[tokenIndex] = lastToken;
        allTokens[lastTokenIndex] = 0;

        allTokens.length = allTokens.length.sub(1);
        allTokensIndex[_tokenId] = 0;
        allTokensIndex[lastToken] = tokenIndex;
    }
}
 
contract CommunityToken is HashFutureToken{

    string internal privilege;
    string internal contractIntroduction;

    constructor() HashFutureToken("HashFuture CommunityToken", "HFCT") public {
        privilege = "1.Privilege of enjoying a monthly airdrop of 10 Antarctic Lands; 2.Privilege of enjoying higher priority in pre-sale shares of tokenized assets in HashFuture trading platform; 3.Privilege of 20% discount in the commission fee of trading in HashFuture trading platform;";
        contractIntroduction = "1. This token cannot be transferred, only the holder himself or herself can hold the token and enjoy the privileges; 2. The privileges of this token will be upgraded with the development of HashFuture; 3. If the holder quits from the HashFuture platform, this token and its privileges will be destroyed as well;";
    }

    struct IdentityInfo {
        string hashID;
        string name;
        string country;
    }

    mapping(uint256 => IdentityInfo) IdentityInfoOfId;

     
    function issueToken(
        address _to,
        string _hashID,
        string _name,
        string _country
    )
        public onlyOwner
    {
        uint256 _tokenId = allTokens.length;

        IdentityInfoOfId[_tokenId] = IdentityInfo(
            _hashID, _name, _country
        );

        _mint(_to, _tokenId);
    }

     
    function burnToken(uint256 _tokenId) public onlyOwner{
        address tokenOwner = ownerOf(_tokenId);
        require(tokenOwner != address(0));

        delete IdentityInfoOfId[_tokenId];
        _burn(tokenOwner, _tokenId);
    }

     
    function getTokenInfo(uint256 _tokenId) external view returns (string, string, string) {
        address tokenOwner = ownerOf(_tokenId);
        require(tokenOwner != address(0));

        IdentityInfo storage pInfo = IdentityInfoOfId[_tokenId];
        return (
            pInfo.hashID,
            pInfo.name,
            pInfo.country
        );
    }

     
    function getPrivilege() external view returns (string) {
        return privilege;
    }

     
    function getContractIntroduction() external view returns (string) {
        return contractIntroduction;
    }

     
    function updatePrivilege(string _privilege) public onlyOwner {
        privilege = _privilege;
    }

}
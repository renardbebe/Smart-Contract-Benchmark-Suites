 

pragma solidity ^0.4.25;

interface ERC721 {
    function totalSupply() external view returns (uint256 tokens);
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function exists(uint256 tokenId) external view returns (bool tokenExists);
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);

    function transferFrom(address from, address to, uint256 tokenId) external;
    function tokensOf(address owner) external view returns (uint256[] tokens);
     

     
    event Transfer(address from, address to, uint256 tokenId);
    event Approval(address owner, address approved, uint256 tokenId);
}

contract WWGClanCoupon is ERC721 {
    using SafeMath for uint256;
    
     
     
    
    address preLaunchMinter;
    address wwgClanContract;
    
    uint256 numClans;
    address owner;  
    
    event ClanMinted(address to, uint256 clanId);
    
     
    mapping (uint256 => address) public tokenOwner;
    mapping (uint256 => address) public tokenApprovals;
    mapping (address => uint256[]) public ownedTokens;
    mapping(uint256 => uint256) public ownedTokensIndex;
    
    constructor() public {
        owner = msg.sender;
    }
    
    function setCouponMinter(address prelaunchContract) external {
        require(msg.sender == owner);
        require(preLaunchMinter == address(0));
        preLaunchMinter = prelaunchContract;
    }
    
    function setClanContract(address clanContract) external {
        require(msg.sender == owner);
        wwgClanContract = address(clanContract);
    }
    
    function mintClan(uint256 clanId, address clanOwner) external {
        require(msg.sender == address(preLaunchMinter));
        require(tokenOwner[clanId] == address(0));

        numClans++;
        addTokenTo(clanOwner, clanId);
        emit Transfer(address(0), clanOwner, clanId);
    }
    
     
    function burnCoupon(address clanOwner, uint256 tokenId) external {
        require (msg.sender == wwgClanContract);
        removeTokenFrom(clanOwner, tokenId);
        numClans = numClans.sub(1);
        
        emit ClanMinted(clanOwner, tokenId);
    }
    
    function balanceOf(address player) public view returns (uint256) {
        return ownedTokens[player].length;
    }
    
    function ownerOf(uint256 clanId) external view returns (address) {
        return tokenOwner[clanId];
    }
    
    function totalSupply() external view returns (uint256) {
        return numClans;
    }
    
    function exists(uint256 clanId) public view returns (bool) {
        return tokenOwner[clanId] != address(0);
    }
    
    function approve(address to, uint256 clanId) external {
        require(tokenOwner[clanId] == msg.sender);
        tokenApprovals[clanId] = to;
        emit Approval(msg.sender, to, clanId);
    }

    function getApproved(uint256 clanId) external view returns (address operator) {
        return tokenApprovals[clanId];
    }
    
    function tokensOf(address player) external view returns (uint256[] tokens) {
         return ownedTokens[player];
    }
    
    function transferFrom(address from, address to, uint256 tokenId) public {
        require(tokenApprovals[tokenId] == msg.sender || tokenOwner[tokenId] == msg.sender);

        removeTokenFrom(from, tokenId);
        addTokenTo(to, tokenId);

        delete tokenApprovals[tokenId];  
        emit Transfer(from, to, tokenId);
    }

    function removeTokenFrom(address from, uint256 tokenId) internal {
        require(tokenOwner[tokenId] == from);
        tokenOwner[tokenId] = address(0);
        delete tokenApprovals[tokenId];  

        uint256 tokenIndex = ownedTokensIndex[tokenId];
        uint256 lastTokenIndex = ownedTokens[from].length.sub(1);
        uint256 lastToken = ownedTokens[from][lastTokenIndex];

        ownedTokens[from][tokenIndex] = lastToken;
        ownedTokens[from][lastTokenIndex] = 0;

        ownedTokens[from].length--;
        ownedTokensIndex[tokenId] = 0;
        ownedTokensIndex[lastToken] = tokenIndex;
    }

    function addTokenTo(address to, uint256 tokenId) internal {
        require(balanceOf(to) == 0);  
        tokenOwner[tokenId] = to;

        ownedTokensIndex[tokenId] = ownedTokens[to].length;
        ownedTokens[to].push(tokenId);
    }

}


library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

   
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
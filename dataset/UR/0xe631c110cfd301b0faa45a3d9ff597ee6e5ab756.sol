 

pragma solidity ^0.4.18;


 
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

 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    assert(token.transfer(to, value));
  }

  function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
    assert(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    assert(token.approve(spender, value));
  }
}

 
contract ERC721 {
  event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
  event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);

  function balanceOf(address _owner) public view returns (uint256 _balance);
  function ownerOf(uint256 _tokenId) public view returns (address _owner);
  function transfer(address _to, uint256 _tokenId) public;
  function approve(address _to, uint256 _tokenId) public;
  function takeOwnership(uint256 _tokenId) public;
}

 
contract ERC721Token is ERC721 {
  using SafeMath for uint256;

   
  uint256 private totalTokens;

   
  mapping (uint256 => address) private tokenOwner;

   
  mapping (uint256 => address) private tokenApprovals;

   
  mapping (address => uint256[]) private ownedTokens;

   
  mapping(uint256 => uint256) private ownedTokensIndex;

   
  modifier onlyOwnerOf(uint256 _tokenId) {
    require(ownerOf(_tokenId) == msg.sender);
    _;
  }

   
  function totalSupply() public view returns (uint256) {
    return totalTokens;
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
    return ownedTokens[_owner].length;
  }

   
  function tokensOf(address _owner) public view returns (uint256[]) {
    return ownedTokens[_owner];
  }

   
  function ownerOf(uint256 _tokenId) public view returns (address) {
    address owner = tokenOwner[_tokenId];
    require(owner != address(0));
    return owner;
  }

   
  function approvedFor(uint256 _tokenId) public view returns (address) {
    return tokenApprovals[_tokenId];
  }

   
  function transfer(address _to, uint256 _tokenId) public onlyOwnerOf(_tokenId) {
    clearApprovalAndTransfer(msg.sender, _to, _tokenId);
  }

   
  function approve(address _to, uint256 _tokenId) public onlyOwnerOf(_tokenId) {
    address owner = ownerOf(_tokenId);
    require(_to != owner);
    if (approvedFor(_tokenId) != 0 || _to != 0) {
      tokenApprovals[_tokenId] = _to;
      emit Approval(owner, _to, _tokenId);
    }
  }

   
  function takeOwnership(uint256 _tokenId) public {
    require(isApprovedFor(msg.sender, _tokenId));
    clearApprovalAndTransfer(ownerOf(_tokenId), msg.sender, _tokenId);
  }

   
  function _mint(address _to, uint256 _tokenId) internal {
    require(_to != address(0));
    addToken(_to, _tokenId);
    emit Transfer(0x0, _to, _tokenId);
  }

   
  function _burn(uint256 _tokenId) onlyOwnerOf(_tokenId) internal {
    if (approvedFor(_tokenId) != 0) {
      clearApproval(msg.sender, _tokenId);
    }
    removeToken(msg.sender, _tokenId);
    emit Transfer(msg.sender, 0x0, _tokenId);
  }

   
  function isApprovedFor(address _owner, uint256 _tokenId) internal view returns (bool) {
    return approvedFor(_tokenId) == _owner;
  }

   
  function clearApprovalAndTransfer(address _from, address _to, uint256 _tokenId) internal {
    require(_to != address(0));
    require(_to != ownerOf(_tokenId));
    require(ownerOf(_tokenId) == _from);

    clearApproval(_from, _tokenId);
    removeToken(_from, _tokenId);
    addToken(_to, _tokenId);
    emit Transfer(_from, _to, _tokenId);
  }

   
  function clearApproval(address _owner, uint256 _tokenId) private {
    require(ownerOf(_tokenId) == _owner);
    tokenApprovals[_tokenId] = 0;
    emit Approval(_owner, 0, _tokenId);
  }

   
  function addToken(address _to, uint256 _tokenId) private {
    require(tokenOwner[_tokenId] == address(0));
    tokenOwner[_tokenId] = _to;
    uint256 length = balanceOf(_to);
    ownedTokens[_to].push(_tokenId);
    ownedTokensIndex[_tokenId] = length;
    totalTokens = totalTokens.add(1);
  }

   
  function removeToken(address _from, uint256 _tokenId) private {
    require(ownerOf(_tokenId) == _from);

    uint256 tokenIndex = ownedTokensIndex[_tokenId];
    uint256 lastTokenIndex = balanceOf(_from).sub(1);
    uint256 lastToken = ownedTokens[_from][lastTokenIndex];

    tokenOwner[_tokenId] = 0;
    ownedTokens[_from][tokenIndex] = lastToken;
    ownedTokens[_from][lastTokenIndex] = 0;
     
     
     

    ownedTokens[_from].length--;
    ownedTokensIndex[_tokenId] = 0;
    ownedTokensIndex[lastToken] = tokenIndex;
    totalTokens = totalTokens.sub(1);
  }
}

 
contract CanReclaimToken is Ownable {
  using SafeERC20 for ERC20Basic;

   
  function reclaimToken(ERC20Basic token) external onlyOwner {
    uint256 balance = token.balanceOf(this);
    token.safeTransfer(owner, balance);
  }

}

contract HeroesToken is ERC721Token, CanReclaimToken {
    using SafeMath for uint256;

    event Bought (uint256 indexed _tokenId, address indexed _owner, uint256 _price);
    event Sold (uint256 indexed _tokenId, address indexed _owner, uint256 _price);

    uint256[] private listedTokens;
    mapping (uint256 => uint256) private priceOfToken;

    uint256[4] private limits = [0.05 ether, 0.5 ether, 5.0 ether];

    uint256[4] private fees = [6, 5, 4, 3];  
    uint256[4] private increases = [200, 150, 130, 120];  

    function HeroesToken() ERC721Token() public {}

    function mint(address _to, uint256 _tokenId, uint256 _price) public onlyOwner {
        require(_to != address(this));

        super._mint(_to, _tokenId);
        listedTokens.push(_tokenId);
        priceOfToken[_tokenId] = _price;
    }

    function priceOf(uint256 _tokenId) public view returns (uint256) {
        return priceOfToken[_tokenId];
    }

    function calculateFee(uint256 _price) public view returns (uint256) {
        if (_price < limits[0]) {
            return _price.mul(fees[0]).div(100);
        } else if (_price < limits[1]) {
            return _price.mul(fees[1]).div(100);
        } else if (_price < limits[2]) {
            return _price.mul(fees[2]).div(100);
        } else {
            return _price.mul(fees[3]).div(100);
        }
    }

    function calculatePrice(uint256 _price) public view returns (uint256) {
        if (_price < limits[0]) {
            return _price.mul(increases[0]).div(100 - fees[0]);
        } else if (_price < limits[1]) {
            return _price.mul(increases[1]).div(100 - fees[1]);
        } else if (_price < limits[2]) {
            return _price.mul(increases[2]).div(100 - fees[2]);
        } else {
            return _price.mul(increases[3]).div(100 - fees[3]);
        }
    }

    function buy(uint256 _tokenId) public payable {
        require(priceOf(_tokenId) > 0);
        require(ownerOf(_tokenId) != address(0));
        require(msg.value >= priceOf(_tokenId));
        require(ownerOf(_tokenId) != msg.sender);
        require(!isContract(msg.sender));
        require(msg.sender != address(0));

        address oldOwner = ownerOf(_tokenId);
        address newOwner = msg.sender;
        uint256 price = priceOf(_tokenId);
        uint256 excess = msg.value.sub(price);

        super.clearApprovalAndTransfer(oldOwner, newOwner, _tokenId);
        priceOfToken[_tokenId] = calculatePrice(price);

        emit Bought(_tokenId, newOwner, price);
        emit Sold(_tokenId, oldOwner, price);

        uint256 fee = calculateFee(price);
        oldOwner.transfer(price.sub(fee));

        if (excess > 0) {
            newOwner.transfer(excess);
        }
    }

    function withdrawAll() public onlyOwner {
        owner.transfer(address(this).balance);
    }

    function withdrawAmount(uint256 _amount) public onlyOwner {
        owner.transfer(_amount);
    }

    function listedTokensAsBytes(uint256 _from, uint256 _to) public constant returns (bytes) {
        require(_from >= 0);
        require(_to >= _from);
        require(_to < listedTokens.length);
      
         
        uint256 size = 32 * (_to - _from + 1);
        uint256 counter = 0;
        bytes memory b = new bytes(size);
        for (uint256 x = _from; x < _to + 1; x++) {
            uint256 elem = listedTokens[x];
            for (uint y = 0; y < 32; y++) {
                b[counter] = byte(uint8(elem / (2 ** (8 * (31 - y)))));
                counter++;
            }
        }
        return b;
    }

    function isContract(address _addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(_addr) }
        return size > 0;
    }
}
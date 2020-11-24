 

pragma solidity ^0.5.0;

library Address {

  function isContract(address account) internal view returns (bool) {
     
     
     
    bytes32 codehash;
    bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
     
    assembly { codehash := extcodehash(account) }
    return (codehash != accountHash && codehash != 0x0);
  }

}

library Counters {
    using SafeMath for uint256;

    struct Counter {
         
         
         
        uint256 _value;  
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
         
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value.sub(1);
    }
}
 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0);  
    uint256 c = a / b;
     

    return c;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

   
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}
 
interface IERC165 {
  function supportsInterface(bytes4 interfaceId)
    external
    view
    returns (bool);
}
 
contract ERC165 is IERC165 {

   
  bytes4 private constant _InterfaceId_ERC165 = 0x01ffc9a7;

   
  mapping(bytes4 => bool) private _supportedInterfaces;

   
  constructor()
    public
  {
    _registerInterface(_InterfaceId_ERC165);
  }

   
  function supportsInterface(bytes4 interfaceId)
    external
    view
    returns (bool)
  {
    return _supportedInterfaces[interfaceId];
  }

   
  function _registerInterface(bytes4 interfaceId)
    internal
  {
    require(interfaceId != 0xffffffff);
    _supportedInterfaces[interfaceId] = true;
  }
}

contract Context {
     
     
    constructor () internal { }
     

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this;  
        return msg.data;
    }
}
 
contract IERC721 is IERC165 {

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 indexed tokenId
  );
  event Approval(
    address indexed owner,
    address indexed approved,
    uint256 indexed tokenId
  );
  event ApprovalForAll(
    address indexed owner,
    address indexed operator,
    bool approved
  );

  function balanceOf(address owner) public view returns (uint256 balance);
  function ownerOf(uint256 tokenId) public view returns (address owner);

  function approve(address to, uint256 tokenId) public;
  function getApproved(uint256 tokenId)
    public view returns (address operator);

  function setApprovalForAll(address operator, bool _approved) public;
  function isApprovedForAll(address owner, address operator)
    public view returns (bool);

  function transferFrom(address from, address to, uint256 tokenId) public;
  function safeTransferFrom(address from, address to, uint256 tokenId)
    public;

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
  )
    public;
}

contract IERC721Receiver {

  function onERC721Received(
    address operator,
    address from,
    uint256 tokenId,
    bytes memory data
  )
    public
    returns(bytes4);
}

contract ERC721 is Context, ERC165, IERC721 {
    using SafeMath for uint256;
    using Address for address;
    using Counters for Counters.Counter;

     
     
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

     
    mapping (uint256 => address) private _tokenOwner;

     
    mapping (uint256 => address) private _tokenApprovals;

     
    mapping (address => Counters.Counter) private _ownedTokensCount;

     
    mapping (address => mapping (address => bool)) private _operatorApprovals;

     
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    constructor () public {
         
        _registerInterface(_INTERFACE_ID_ERC721);
    }

     
    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");

        return _ownedTokensCount[owner].current();
    }

     
    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _tokenOwner[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");

        return owner;
    }

     
    function approve(address to, uint256 tokenId) public {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

     
    function getApproved(uint256 tokenId) public view returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

     
    function setApprovalForAll(address to, bool approved) public {
        require(to != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][to] = approved;
        emit ApprovalForAll(_msgSender(), to, approved);
    }

     
    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }

     
    function transferFrom(address from, address to, uint256 tokenId) public {
         
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transferFrom(from, to, tokenId);
    }

     
    function safeTransferFrom(address from, address to, uint256 tokenId) public {
        safeTransferFrom(from, to, tokenId, "");
    }

     
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransferFrom(from, to, tokenId, _data);
    }

     
    function _safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) internal {
        _transferFrom(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

     
    function _exists(uint256 tokenId) internal view returns (bool) {
        address owner = _tokenOwner[tokenId];
        return owner != address(0);
    }

     
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

     
    function _safeMint(address to, uint256 tokenId) internal {
        _safeMint(to, tokenId, "");
    }

     
    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal {
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

     
    function _mint(address to, uint256 tokenId) internal {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _tokenOwner[tokenId] = to;
        _ownedTokensCount[to].increment();

        emit Transfer(address(0), to, tokenId);
    }

     
    function _burn(address owner, uint256 tokenId) internal {
        require(ownerOf(tokenId) == owner, "ERC721: burn of token that is not own");

        _clearApproval(tokenId);

        _ownedTokensCount[owner].decrement();
        _tokenOwner[tokenId] = address(0);

        emit Transfer(owner, address(0), tokenId);
    }

     
    function _burn(uint256 tokenId) internal {
        _burn(ownerOf(tokenId), tokenId);
    }

     
    function _transferFrom(address from, address to, uint256 tokenId) internal {
        require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _clearApproval(tokenId);

        _ownedTokensCount[from].decrement();
        _ownedTokensCount[to].increment();

        _tokenOwner[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

     
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        internal returns (bool)
    {
        if (!to.isContract()) {
            return true;
        }

        bytes4 retval = IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data);
        return (retval == _ERC721_RECEIVED);
    }

     
    function _clearApproval(uint256 tokenId) private {
        if (_tokenApprovals[tokenId] != address(0)) {
            _tokenApprovals[tokenId] = address(0);
        }
    }
}

contract ETH_USDC_UNISWAP {
    function getEthToTokenInputPrice(uint256 eth_sold) public view returns(uint256);
}

contract MoonBoxs is ERC721 {

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  event NewBox(uint boxId, uint creatTime);
  event BreakBox(uint boxId, uint breakTime);
  event OpenBox(uint boxId, uint openTime);

  address payable owner;
  uint256 tipRatio = 1000;
  ETH_USDC_UNISWAP public etherPriceOracle = ETH_USDC_UNISWAP(0x97deC872013f6B5fB443861090ad931542878126);

   
  address public new_uniswap_address;
  uint256 public new_uniswap_address_effective_time;

  struct MoonBox {
    string name;
    uint256 etherNumber;
    uint256 openPrice;
    uint256 openTime;
  }

  MoonBox[] public moonBoxs;

  constructor() public {
    owner = msg.sender;
  }

   
  function() external payable {
    owner.transfer(msg.value);
  }

  function creatBox(string memory _name, uint _wishPrice, uint _openTime) public payable {
      require(msg.value > 0, "The deposit amount must be greater than 0");
      uint id = moonBoxs.push(MoonBox(_name, msg.value, _wishPrice, _openTime)) - 1;
      super._safeMint(_msgSender(), id);
      emit NewBox(id, now);
  }

   
  function breakBox(uint _boxId) public {
    require(_isApprovedOrOwner(_msgSender(), _boxId), "ERC721: transfer caller is not owner nor approved");
    uint ether_price_now = getEthPrice();
    MoonBox memory box = moonBoxs[_boxId];
    require(box.etherNumber > 0, "This box has been opened");
    if(box.openPrice <= ether_price_now || box.openTime <= now) {
      super._burn(_boxId);
      msg.sender.transfer(box.etherNumber);
      emit BreakBox(_boxId, now);
    } else {
      revert("The break condition is not yet satisfied.");
    }
  }

   
  function openBox(uint _boxId) public {
    require(_isApprovedOrOwner(_msgSender(), _boxId), "ERC721: transfer caller is not owner nor approved");
    uint ether_price_now = getEthPrice();
    MoonBox storage box = moonBoxs[_boxId];
    require(box.etherNumber > 0, "This box has been opened");
    if(box.openPrice <= ether_price_now || box.openTime <= now) {
      uint fee = box.etherNumber / tipRatio;
      uint payout = box.etherNumber.sub(fee);
      box.etherNumber = 0;
      msg.sender.transfer(payout);
      owner.transfer(fee);
      emit OpenBox(_boxId, now);
    } else {
      revert("The open condition is not yet satisfied.");
    }
  }

  function getEthPrice() public view returns (uint) {
    return etherPriceOracle.getEthToTokenInputPrice(1 ether);
  }

   
  function getMoonBoxsByOwner(address _owner) external view returns(uint[] memory) {
    uint boxNum = super.balanceOf(_owner);
    uint[] memory result = new uint[](boxNum);
    uint counter = 0;
    for (uint i = 0; i < moonBoxs.length; i++) {
      if (super._exists(i) && super._isApprovedOrOwner(_owner, i)) {
        result[counter] = i;
        counter++;
      }
    }
    return result;
  }

  function getMoonBoxsTotalSupply() external view returns(uint256) {
    return moonBoxs.length;
  }

   
  function setNewUniswapAddress(address _newUniswapAddress) external onlyOwner {
    new_uniswap_address = _newUniswapAddress;
    new_uniswap_address_effective_time = now.add(7 days);
  }

  function changeEthPriceOracle() external onlyOwner {
    require(new_uniswap_address != address(0) && now > new_uniswap_address_effective_time);
    etherPriceOracle = ETH_USDC_UNISWAP(new_uniswap_address);
  }
}
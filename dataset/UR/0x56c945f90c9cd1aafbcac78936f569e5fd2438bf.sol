 

pragma solidity ^0.4.24;

 

 
contract Ownable {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

   
  constructor() internal {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), _owner);
  }

   
  function owner() public view returns(address) {
    return _owner;
  }

   
  modifier onlyOwner() {
    require(isOwner());
    _;
  }

   
  function isOwner() public view returns(bool) {
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
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
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

 

 
contract CanReclaimToken is Ownable {

   
  function reclaimToken(IERC20 token) external onlyOwner {
    if (address(token) == address(0)) {
      owner().transfer(address(this).balance);
      return;
    }
    uint256 balance = token.balanceOf(this);
    token.transfer(owner(), balance);
  }

}

 

interface HEROES_NEW {
  function mint(address to, uint256 genes, uint256 level) external returns (uint);
  function mint(uint256 tokenId, address to, uint256 genes, uint256 level) external returns (uint);
}


interface HEROES_OLD {
  function getLock(uint256 _tokenId) external view returns (uint256 lockedTo, uint16 lockId);
  function unlock(uint256 _tokenId, uint16 _lockId) external returns (bool);
  function lock(uint256 _tokenId, uint256 _lockedTo, uint16 _lockId) external returns (bool);
  function transferFrom(address _from, address _to, uint256 _tokenId) external;
  function getCharacter(uint256 _tokenId) external view returns (uint256 genes, uint256 mintedAt, uint256 godfather, uint256 mentor, uint32 wins, uint32 losses, uint32 level, uint256 lockedTo, uint16 lockId);
  function ownerOf(uint256 _tokenId) external view returns (address);
}

contract HeroUp is Ownable, CanReclaimToken {
  event HeroUpgraded(uint tokenId, address owner);

  HEROES_OLD public heroesOld;
  HEROES_NEW public heroesNew;
  constructor (HEROES_OLD _heroesOld, HEROES_NEW _heroesNew) public {
    require(address(_heroesOld) != address(0));
    require(address(_heroesNew) != address(0));
    heroesOld = _heroesOld;
    heroesNew = _heroesNew;
  }

  function() public {}

  function setOld(HEROES_OLD _heroesOld) public onlyOwner {
    require(address(_heroesOld) != address(0));
    heroesOld = _heroesOld;
  }

  function setNew(HEROES_NEW _heroesNew) public onlyOwner {
    require(address(_heroesNew) != address(0));
    heroesNew = _heroesNew;
  }

  function upgrade(uint _tokenId) public {
    require(msg.sender == heroesOld.ownerOf(_tokenId));
    uint256 genes;
    uint32 level;
    uint256 lockedTo;
    uint16 lockId;

     
    (genes,,,,,,level,lockedTo,lockId) = heroesOld.getCharacter(_tokenId);
    heroesOld.unlock(_tokenId, lockId);
    heroesOld.lock(_tokenId, 0, 999);
    heroesOld.transferFrom(msg.sender, address(this), _tokenId);
 

     
    heroesNew.mint(_tokenId, msg.sender, genes, level);

    emit HeroUpgraded(_tokenId, msg.sender);
  }
}
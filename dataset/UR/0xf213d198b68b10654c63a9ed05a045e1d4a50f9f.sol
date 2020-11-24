 

pragma solidity ^0.4.17;

 
 
contract ERC721 {
     
    function implementsERC721() public pure returns (bool);
    function totalSupply() public view returns (uint256 total);
    function balanceOf(address _owner) public view returns (uint256 balance);
    function ownerOf(uint256 _tokenId) external view returns (address owner);
    function approve(address _to, uint256 _tokenId) external;
    function transfer(address _to, uint256 _tokenId) public;
    function transferFrom(address _from, address _to, uint256 _tokenId) external;

     
    event Transfer(address from, address to, uint256 tokenId);
    event Approval(address owner, address approved, uint256 tokenId);
     
     
     
     
     

     
     
}

contract FootballerAccessControl{

   
  event ContractUpgrade(address newContract);
   
  address public managerAddress;

   
  bool public paused = false;

  function FootballerAccessControl() public {
    managerAddress = msg.sender;
  }

   
  modifier onlyManager() {
    require(msg.sender == managerAddress);
    _;
  }

   
  function setManager(address _newManager) external onlyManager {
    require(_newManager != address(0));
    managerAddress = _newManager;
  }

   

   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused {
      require(paused);
      _;
  }

   
   
  function pause() external onlyManager whenNotPaused {
    paused = true;
  }

   
   
   
  function unpause() public onlyManager {
     
    paused = false;
  }

}

contract FootballerBase is FootballerAccessControl {
  using SafeMath for uint256;
   
  event Create(address owner, uint footballerId);
  event Transfer(address _from, address _to, uint256 tokenId);

  uint private randNonce = 0;

   
  struct footballer {
    uint price;  
     
    uint defend;  
    uint attack;  
    uint quality;  
  }

   
  footballer[] public footballers;
   
  mapping (uint256 => address) public footballerToOwner;

   
  mapping (address => uint256) public ownershipTokenCount;

   
   
  mapping (uint256 => address) public footballerToApproved;

   
  function _transfer(address _from, address _to, uint256 _tokenId) internal {
    footballerToApproved[_tokenId] = address(0);
    ownershipTokenCount[_to] = ownershipTokenCount[_to].add(1);
    footballerToOwner[_tokenId] = _to;
    ownershipTokenCount[_from] = ownershipTokenCount[_from].sub(1);
    emit Transfer(_from, _to, _tokenId);
  }

   
  function _createFootballerStar(uint _price,uint _defend,uint _attack, uint _quality) internal onlyManager returns(uint) {
      footballer memory _player = footballer({
        price:_price,
        defend:_defend,
        attack:_attack,
        quality:_quality
      });
      uint newFootballerId = footballers.push(_player) - 1;
      footballerToOwner[newFootballerId] = managerAddress;
      ownershipTokenCount[managerAddress] = ownershipTokenCount[managerAddress].add(1);
       
      footballerToApproved[newFootballerId] = managerAddress;
      require(newFootballerId == uint256(uint32(newFootballerId)));
      emit Create(managerAddress, newFootballerId);
      return newFootballerId;
    }


     
    function createFootballer () internal returns (uint) {
        footballer memory _player = footballer({
          price: 0,
          defend: _randMod(20,80),
          attack: _randMod(20,80),
          quality: _randMod(20,80)
        });
        uint newFootballerId = footballers.push(_player) - 1;
       
        footballerToOwner[newFootballerId] = msg.sender;
        ownershipTokenCount[msg.sender] =ownershipTokenCount[msg.sender].add(1);
        emit Create(msg.sender, newFootballerId);
        return newFootballerId;
    }

   
  function _randMod(uint _min, uint _max) private returns(uint) {
      randNonce++;
      uint modulus = _max - _min;
      return uint(keccak256(now, msg.sender, randNonce)) % modulus + _min;
  }

}

contract FootballerOwnership is FootballerBase, ERC721 {
   
  string public constant name = "CyptoWorldCup";
  string public constant symbol = "CWC";


  function implementsERC721() public pure returns (bool) {
    return true;
  }

   
  function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {
    return footballerToOwner[_tokenId] == _claimant;
  }

   
  function _approvedFor(address _claimant, uint256 _tokenId) internal view returns (bool) {
    return footballerToApproved[_tokenId] == _claimant;
  }

   
  function _approve(uint256 _tokenId, address _approved) internal {
      footballerToApproved[_tokenId] = _approved;
  }

   
  function balanceOf(address _owner) public view returns (uint256 count) {
    return ownershipTokenCount[_owner];
  }

   
  function transfer(address _to, uint256 _tokenId) public whenNotPaused {
    require(_to != address(0));
    require(_to != address(this));
     
    require(_owns(msg.sender, _tokenId));
     
    _transfer(msg.sender, _to, _tokenId);
  }

   
  function approve(address _to, uint256 _tokenId) external whenNotPaused {
     
    require(_owns(msg.sender, _tokenId));
    _approve(_tokenId, _to);
    emit Approval(msg.sender, _to, _tokenId);
  }

   
  function transferFrom(address _from, address _to, uint256 _tokenId) external whenNotPaused {
    require(_to != address(0));
     
     
    require(_to != address(this));
    require(_approvedFor(msg.sender, _tokenId));
    require(_owns(_from, _tokenId));
     
    _transfer(_from, _to, _tokenId);
  }

   
  function totalSupply() public view returns (uint) {
    return footballers.length;
  }

   
  function ownerOf(uint256 _tokenId) external view returns (address owner) {
    owner = footballerToOwner[_tokenId];
    require(owner != address(0));
  }

   
  function tokensOfOwner(address _owner) external view returns(uint256[] ownerTokens) {
    uint256 tokenCount = balanceOf(_owner);
    if(tokenCount == 0) {
      return new uint256[](0);
    } else {
      uint256[] memory result = new uint256[](tokenCount);
      uint256 totalpalyers = totalSupply();
      uint256 resultIndex = 0;
      uint256 footballerId;
      for (footballerId = 0; footballerId < totalpalyers; footballerId++) {
        if(footballerToOwner[footballerId] == _owner) {
          result[resultIndex] = footballerId;
          resultIndex++;
        }
      }
      return result;
    }
  }
}

contract FootballerAction is FootballerOwnership {
   
  function createFootballerStar(uint _price,uint _defend,uint _attack, uint _quality) public returns(uint) {
      return _createFootballerStar(_price,_defend,_attack,_quality);
  }

   
  function CardFootballers() public payable returns (uint) {
      uint price = 4000000000000 wei;  
      require(msg.value >= price);
      uint ballerCount = 14;
      uint newFootballerId = 0;
      for (uint i = 0; i < ballerCount; i++) {
         newFootballerId = createFootballer();
      }
      managerAddress.transfer(msg.value);
      return price;
  }

  function buyStar(uint footballerId,uint price) public payable  {
    require(msg.value >= price);
     
    address holder = footballerToApproved[footballerId];
    require(holder != address(0));
    _transfer(holder,msg.sender,footballerId);
     
    holder.transfer(msg.value);
  }

   
  function sell(uint footballerId,uint price) public returns(uint) {
    require(footballerToOwner[footballerId] == msg.sender);
    require(footballerToApproved[footballerId] == address(0));
    footballerToApproved[footballerId] = msg.sender;
    footballers[footballerId].price = price;
  }

   
  function getTeamBallers(address actor) public view returns (uint[]) {
    uint len = footballers.length;
    uint count=0;
    for(uint i = 0; i < len; i++) {
        if(_owns(actor, i)){
          if(footballerToApproved[i] == address(0)){
            count++;
          }
       }
    }
    uint[] memory res = new uint256[](count);
    uint index = 0;
    for(i = 0; i < len; i++) {
      if(_owns(actor, i)){
          if(footballerToApproved[i] == address(0)){
            res[index] = i;
            index++;
          }
        }
    }
    return res;
  }

   
  function getSellBallers() public view returns (uint[]) {
    uint len = footballers.length;
    uint count = 0;
    for(uint i = 0; i < len; i++) {
        if(footballerToApproved[i] != address(0)){
          count++;
        }
    }
    uint[] memory res = new uint256[](count);
    uint index = 0;
    for( i = 0; i < len; i++) {
        if(footballerToApproved[i] != address(0)){
          res[index] = i;
          index++;
        }
    }
    return res;
  }

   
  function getAllBaller() public view returns (uint) {
    uint len = totalSupply();
    return len;
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
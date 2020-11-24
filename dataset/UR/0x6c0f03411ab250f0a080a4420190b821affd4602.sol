 

pragma solidity ^0.4.20;

 
 
 
 
 


 
 
 
 
 

library SafeMath {

  function mul(uint a, uint b) internal pure returns (uint c) {
    c = a * b;
    require( a == 0 || c / a == b );
  }

  function add(uint a, uint b) internal pure returns (uint c) {
    c = a + b;
    require( c >= a );
  }

  function sub(uint a, uint b) internal pure returns (uint c) {
    require( b <= a );
    c = a - b;
  }

}


 
 
 
 
 

contract Owned {

  address public owner;
  address public newOwner;

  mapping(address => bool) public isAdmin;

   

  event OwnershipTransferProposed(address indexed _from, address indexed _to);
  event OwnershipTransferred(address indexed _from, address indexed _to);
  event AdminChange(address indexed _admin, bool _status);

   

  modifier onlyOwner { require( msg.sender == owner ); _; }
  modifier onlyAdmin { require( isAdmin[msg.sender] ); _; }

   

  function Owned() public {
    owner = msg.sender;
    isAdmin[owner] = true;
  }

  function transferOwnership(address _newOwner) public onlyOwner {
    require( _newOwner != address(0x0) );
    OwnershipTransferProposed(owner, _newOwner);
    newOwner = _newOwner;
  }

  function acceptOwnership() public {
    require(msg.sender == newOwner);
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
  
  function addAdmin(address _a) public onlyOwner {
    require( isAdmin[_a] == false );
    isAdmin[_a] = true;
    AdminChange(_a, true);
  }

  function removeAdmin(address _a) public onlyOwner {
    require( isAdmin[_a] == true );
    isAdmin[_a] = false;
    AdminChange(_a, false);
  }
  
}


 
 
 
 
 


interface ERC721Interface   {

    event Transfer(address indexed _from, address indexed _to, uint256 _deedId);
    event Approval(address indexed _owner, address indexed _approved, uint256 _deedId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    function balanceOf(address _owner) external view returns (uint256 _balance);
    function ownerOf(uint256 _deedId) external view returns (address _owner);
    function transfer(address _to, uint256 _deedId) external;                     
    function transferFrom(address _from, address _to, uint256 _deedId) external;  
    function approve(address _approved, uint256 _deedId) external;                
     
     
}

interface ERC721Metadata   {
    function name() external pure returns (string _name);
    function symbol() external pure returns (string _symbol);
    function deedUri(uint256 _deedId) external view returns (string _deedUri);
}

interface ERC721Enumerable   {
    function totalSupply() external view returns (uint256 _count);
    function deedByIndex(uint256 _index) external view returns (uint256 _deedId);
    function countOfOwners() external view returns (uint256 _count);
     
     
}


 
 
 
 
 

contract ERC721Token is ERC721Interface, ERC721Metadata, ERC721Enumerable, Owned {
  
  using SafeMath for uint;

  uint public ownerCount = 0;
  uint public deedCount = 0;
  
  mapping(address => uint) public balances;
  mapping(uint => address) public mIdOwner;
  mapping(uint => address) public mIdApproved;

   

   

  function balanceOf(address _owner) external view returns (uint balance) {
    balance = balances[_owner];
  }

   

  function ownerOf(uint _id) external view returns (address owner) {
    owner = mIdOwner[_id];
    require( owner != address(0x0) );
  }

   
  
  function transfer(address _to, uint _id) external {
     
    require( msg.sender == mIdOwner[_id] );
    require( _to != address(0x0) );

     
    mIdOwner[_id] = _to;
    mIdApproved[_id] = address(0x0);

     
    updateBalances(msg.sender, _to);

     
    Transfer(msg.sender, _to, _id);
  }

   
  
  function transferFrom(address _from, address _to, uint _id) external {
     
    require( _from == mIdOwner[_id] && mIdApproved[_id] == msg.sender );

     
    mIdOwner[_id] = _to;
    mIdApproved[_id] = address(0x0);

     
    updateBalances(_from, _to);

     
    Transfer(_from, _to, _id);
  }

   
  
   function approve(address _approved, uint _id) external {
       require( msg.sender == mIdOwner[_id] );
       require( msg.sender != _approved );
       mIdApproved[_id] = _approved;
       Approval(msg.sender, _approved, _id);
   }

   


   
  
  function totalSupply() external view returns (uint count) {
    count = deedCount;
  }

  function deedByIndex(uint _index) external view returns (uint id) {
    id = _index;
    require( id < deedCount );
  }  
  
  function countOfOwners() external view returns (uint count) {
    count = ownerCount;
  }
  
   
  
  function updateBalances(address _from, address _to) internal {
     
    if (_from != address(0x0)) {
      balances[_from]--;
      if (balances[_from] == 0) { ownerCount--; }
    }
     
    balances[_to]++;
    if (balances[_to] == 1) { ownerCount++; }
  }
      
}


 
 
 
 
 

contract GizerItems is ERC721Token {

   
  
  string constant cName   = "Gizer Item";
  string constant cSymbol = "GZR721";
  
   

  bytes32[] public code;
  uint[] public weight;
  uint public sumOfWeights;
  
  mapping(bytes32 => uint) public mCodeIndexPlus;  

   

  uint public nonce = 0;
  uint public lastRandom = 0;
  
   
  
  mapping(uint => bytes32) public mIdxUuid;
  
   
  
  event MintToken(address indexed minter, address indexed _owner, bytes32 indexed _code, uint _input);
  
  event CodeUpdate(uint8 indexed _type, bytes32 indexed _code, uint _weight, uint _sumOfWeights);
  
   
  
  function GizerItems() public { }
  
  function () public payable { revert(); }
  
   

  function name() external pure returns (string) {
    return cName;
  }
  
  function symbol() external pure returns (string) {
    return cSymbol;
  }
  
  function deedUri(uint _id) external view returns (string) {
    return bytes32ToString(mIdxUuid[_id]);
  }
  
  function getUuid(uint _id) external view returns (string) {
    require( _id < code.length );
    return bytes32ToString(code[_id]);  
  }

   
  
  function mint(address _to) public onlyAdmin returns (uint idx) {
    
     
    require( sumOfWeights > 0 );
    require( _to != address(0x0) );
    require( _to != address(this) );

     
    bytes32 uuid32 = getRandomUuid();

     
    deedCount++;
    idx = deedCount;
    mIdxUuid[idx] = uuid32;

     
    updateBalances(address(0x0), _to);
    mIdOwner[idx] = _to;

     
    MintToken(msg.sender, _to, uuid32, idx);
  }
  
   
  
  function getRandomUuid() internal returns (bytes32) {
     
    if (code.length == 1) return code[0];

     
    updateRandom();
    uint res = lastRandom % sumOfWeights;
    uint cWeight = 0;
    for (uint i = 0; i < code.length; i++) {
      cWeight = cWeight + weight[i];
      if (cWeight >= res) return code[i];
    }

     
    revert();
  }

  function updateRandom() internal {
    nonce++;
    lastRandom = uint(keccak256(
        nonce,
        lastRandom,
        block.blockhash(block.number - 1),
        block.coinbase,
        block.difficulty
    ));
  }
  
   
  
   
  
  function addCode(string _code, uint _weight) public onlyAdmin returns (bool success) {

    bytes32 uuid32 = stringToBytes32(_code);

     
    require( _weight > 0 );
    require( mCodeIndexPlus[uuid32] == 0 );

     
    uint idx = code.length;
    code.push(uuid32);
    weight.push(_weight);
    mCodeIndexPlus[uuid32] = idx + 1;

     
    sumOfWeights = sumOfWeights.add(_weight);

     
    CodeUpdate(1, uuid32, _weight, sumOfWeights);
    return true;
  }
  
   
  
  function updateCodeWeight(string _code, uint _weight) public onlyAdmin returns (bool success) {

    bytes32 uuid32 = stringToBytes32(_code);

     
    require( _weight > 0 );
    require( mCodeIndexPlus[uuid32] > 0 );

     
    uint idx = mCodeIndexPlus[uuid32] - 1;
    uint oldWeight = weight[idx];
    weight[idx] = _weight;
    sumOfWeights = sumOfWeights.sub(oldWeight).add(_weight);

     
    CodeUpdate(2, uuid32, _weight, sumOfWeights);
    return true;
  }
  
   
  
  function removeCode(string _code) public onlyAdmin returns (bool success) {

    bytes32 uuid32 = stringToBytes32(_code);

     
    require( mCodeIndexPlus[uuid32] > 0 );

     
    uint idx = mCodeIndexPlus[uuid32] - 1;
    uint idxLast = code.length - 1;

     
    sumOfWeights = sumOfWeights.sub(weight[idx]);
    mCodeIndexPlus[uuid32] = 0;

    if (idx != idxLast) {
       
       
      code[idx] = code[idxLast];
      weight[idx] = weight[idxLast];
      mCodeIndexPlus[code[idxLast]] = idx;
    }
     
    delete code[idxLast];
    code.length--;
    delete weight[idxLast];
    weight.length--;

     
    CodeUpdate(3, uuid32, 0, sumOfWeights);
    return true;
  }

   

  function transferAnyERC20Token(address tokenAddress, uint amount) public onlyOwner returns (bool success) {
      return ERC20Interface(tokenAddress).transfer(owner, amount);
  }
  
   

  /* https: 
  
  function stringToBytes32(string memory source) public pure returns (bytes32 result) {
    bytes memory tempEmptyStringTest = bytes(source);
    if (tempEmptyStringTest.length == 0) {
        return 0x0;
    }

    assembly {
        result := mload(add(source, 32))
    }
  }
  
  /* https: 

  function bytes32ToString(bytes32 x) public pure returns (string) {
    bytes memory bytesString = new bytes(32);
    uint charCount = 0;
    for (uint j = 0; j < 32; j++) {
      byte char = byte(bytes32(uint(x) * 2 ** (8 * j)));
      if (char != 0) {
        bytesString[charCount] = char;
        charCount++;
      }
    }
    bytes memory bytesStringTrimmed = new bytes(charCount);
    for (j = 0; j < charCount; j++) {
      bytesStringTrimmed[j] = bytesString[j];
    }
    return string(bytesStringTrimmed);
  }
  
}

 
 
 
 
 
 

contract ERC20Interface {
  function transfer(address _to, uint _value) public returns (bool success);
}
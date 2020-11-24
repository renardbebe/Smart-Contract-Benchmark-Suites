 

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


 

contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}
contract ERC918Interface {

  function epochCount() public constant returns (uint);

  function totalSupply() public constant returns (uint);
  function getMiningDifficulty() public constant returns (uint);
  function getMiningTarget() public constant returns (uint);
  function getMiningReward() public constant returns (uint);
  function balanceOf(address tokenOwner) public constant returns (uint balance);

  function mint(uint256 nonce, bytes32 challenge_digest) public returns (bool success);

  event Mint(address indexed from, uint reward_amount, uint epochCount, bytes32 newChallengeNumber);

}

contract mintForwarderInterface
{
  function mintForwarder(uint256 nonce, bytes32 challenge_digest, address[] proxyMintArray) public returns (bool success);
}

contract proxyMinterInterface
{
  function proxyMint(uint256 nonce, bytes32 challenge_digest) public returns (bool success);
}


contract MiningKing   {


  using SafeMath for uint;


   address public miningKing;

   address public minedToken;


   event TransferKing(address from, address to);

    
  constructor(address mintableToken) public  {
    minedToken = mintableToken;
  }


   
  function() public payable {
      revert();
  }

  function getKing() view public returns (address king)
  {
    return miningKing;
  }

   function transferKing(address newKing) public   {

       require(msg.sender == miningKing);

       miningKing = newKing;

       emit TransferKing(msg.sender, newKing);

   }


 

 
   function mintForwarder(uint256 nonce, bytes32 challenge_digest, address[] proxyMintArray) public returns (bool)
   {

      require(proxyMintArray.length > 0);


      uint previousEpochCount = ERC918Interface(minedToken).epochCount();

      address proxyMinter = proxyMintArray[0];

      if(proxyMintArray.length == 1)
      {
         
        require(proxyMinterInterface(proxyMinter).proxyMint(nonce, challenge_digest));
      }else{
         
        address[] memory remainingProxyMintArray = popFirstFromArray(proxyMintArray);

        require(mintForwarderInterface(proxyMinter).mintForwarder(nonce, challenge_digest,remainingProxyMintArray));
      }

      
      require( ERC918Interface(minedToken).epochCount() == previousEpochCount.add(1) );




       
      bytes memory nonceBytes = uintToBytesForAddress(nonce);

      address newKing = bytesToAddress(nonceBytes);
      
      miningKing = newKing;
       

      return true;
   }


  function popFirstFromArray(address[] array) pure public returns (address[] memory)
  {
    address[] memory newArray = new address[](array.length-1);

    for (uint i=0; i < array.length-1; i++) {
      newArray[i] =  array[i+1]  ;
    }

    return newArray;
  }

 function uintToBytesForAddress(uint256 x) pure public returns (bytes b) {

      b = new bytes(20);
      for (uint i = 0; i < 20; i++) {
          b[i] = byte(uint8(x / (2**(8*(31 - i)))));
      }

      return b;
    }


 function bytesToAddress (bytes b) pure public returns (address) {
     uint result = 0;
     for (uint i = b.length-1; i+1 > 0; i--) {
       uint c = uint(b[i]);
       uint to_inc = c * ( 16 ** ((b.length - i-1) * 2));
       result += to_inc;
     }
     return address(result);
 }




}
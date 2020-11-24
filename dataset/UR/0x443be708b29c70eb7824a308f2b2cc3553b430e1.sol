 

pragma solidity ^0.4.18;
 

 
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
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

  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract ERC20 { 
    function transfer(address receiver, uint amount) public ;
    function transferFrom(address sender, address receiver, uint amount) public returns(bool success);  
    function balanceOf(address _owner) constant public returns (uint256 balance);
}

 
contract ASTRDrop is Ownable {
  ERC20 public token;   
  address public ownerAddress;   
  uint8 internal decimals             = 4;  
  uint256 internal decimalsConversion = 10 ** uint256(decimals);
  uint public   AIRDROP_AMOUNT        = 10 * decimalsConversion;

  function multisend(address[] dests) onlyOwner public returns (uint256) {

    ownerAddress    = ERC20(0x3EFAe2e152F62F5cc12cc0794b816d22d416a721);  
    token           = ERC20(0x80E7a4d750aDe616Da896C49049B7EdE9e04C191);  

      uint256 i = 0;
      while (i < dests.length) {  
        token.transferFrom(ownerAddress, dests[i], AIRDROP_AMOUNT);
         i += 1;
      }
      return(i);
    }

   
  function setAirdropAmount(uint256 _astrAirdrop) onlyOwner public {
    if( _astrAirdrop > 0 ) {
        AIRDROP_AMOUNT = _astrAirdrop * decimalsConversion;
    }
  }


   
  function resetAirdropAmount() onlyOwner public {
     AIRDROP_AMOUNT = 10 * decimalsConversion;
  }
}
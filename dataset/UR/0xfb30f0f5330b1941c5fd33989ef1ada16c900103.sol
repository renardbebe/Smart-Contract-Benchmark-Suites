 

 

pragma solidity 0.5.11;

 
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

contract Token{
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
}


 
contract Airdrop {
  using SafeMath for uint256;
  Token public token;
  
  event Airdropped(address _tokenContractAdd, address _recipient, uint256 _tokens);

   
  function airdropTokens(address _tokenContractAdd, address[] memory _recipient, uint256[] memory _tokens) public {
    token = Token(_tokenContractAdd);
    for(uint256 i = 0; i< _recipient.length; i++)
    {
          require(token.transferFrom(msg.sender, _recipient[i], _tokens[i]));
          emit Airdropped(_tokenContractAdd, _recipient[i], _tokens[i]);
    }
  }
}
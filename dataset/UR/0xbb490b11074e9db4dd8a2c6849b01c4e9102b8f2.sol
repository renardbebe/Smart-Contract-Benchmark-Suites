 

pragma solidity ^0.5.8;

interface IERC20 {

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);

}

contract Airdroplet {

    IERC20 public Token;

    function airdropTokens(address _contract, address[] memory _participants, uint _amount) public {
      Token = IERC20(_contract);
      for(uint index = 0; index < _participants.length; index++){
        Token.transferFrom(msg.sender, _participants[index], _amount);
      }
    }

}
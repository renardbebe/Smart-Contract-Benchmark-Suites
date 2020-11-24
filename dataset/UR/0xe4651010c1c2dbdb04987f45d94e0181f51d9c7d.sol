 

pragma solidity ^0.4.11;

 
contract Ownable {
  address public owner;

   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

}


contract Token{
  function transfer(address to, uint value) external returns (bool);
}

contract FanfareAirdrop3 is Ownable {

    function multisend (address _tokenAddr, address[] _to, uint256[] _value) external
    
    returns (bool _success) {
        assert(_to.length == _value.length);
        assert(_to.length <= 150);
         
        for (uint8 i = 0; i < _to.length; i++) {
                uint256 actualValue = _value[i] * 10**18;
                require((Token(_tokenAddr).transfer(_to[i], actualValue)) == true);
            }
            return true;
        }
}
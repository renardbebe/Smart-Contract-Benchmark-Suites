 

pragma solidity ^0.4.17;

contract CryptoRoses {
  address constant DESTINATION_ADDRESS = 0x19Ed10db2960B9B21283FdFDe464e7bF3a87D05D;
  address owner;
  bytes32 name;

  enum Rose { Gold, White, Pink, Red }

  struct RoseOwner {
      bool hasRose;
      Rose roseType;
      string memo;
  }

  mapping (bytes32 => RoseOwner) roseOwners;
  mapping (address => bool) addrWhitelist;

  function CryptoRoses(bytes32 _name) public {
      owner = msg.sender;
      name = _name;
  }

  function addAddWhitelist(address s) public {      
      require(msg.sender == owner);

      addrWhitelist[s] = true;
  }

   
   

   
   

   
   

   
   

  uint constant ETH_GOLD_ROSE_PRICE = 250000000000000000;
  uint constant ETH_WHITE_ROSE_PRICE = 50000000000000000;
  uint constant ETH_PINK_ROSE_PRICE = 20000000000000000;
  uint constant ETH_RED_ROSE_PRICE = 10000000000000000;

   
  function buyRoseETH(string memo) public payable {
      uint amntSent = msg.value;
      address sender = msg.sender;
      bytes32 senderHash = keccak256(sender);

      Rose roseType;

       
      if (amntSent >= ETH_GOLD_ROSE_PRICE) {
          roseType = Rose.Gold;
      } else if (amntSent >= ETH_WHITE_ROSE_PRICE) {
          roseType = Rose.White;
      } else if (amntSent >= ETH_PINK_ROSE_PRICE) {
          roseType = Rose.Pink;
      } else if (amntSent >= ETH_RED_ROSE_PRICE) {
          roseType = Rose.Pink;
      } else {
          sender.transfer(amntSent);
          return;
      }

       
      if (roseOwners[senderHash].hasRose) {
          sender.transfer(amntSent);
          return;
      }

      roseOwners[senderHash].hasRose = true;
      roseOwners[senderHash].roseType = roseType;
      roseOwners[senderHash].memo = memo;

      DESTINATION_ADDRESS.transfer(amntSent);
  }

  uint constant GRLC_GOLD_ROSE_PRICE = 50;
  uint constant GRLC_WHITE_ROSE_PRICE = 10;
  uint constant GRLC_PINK_ROSE_PRICE = 4;
  uint constant GRLC_RED_ROSE_PRICE = 2;

  function buyRoseGRLC(bytes32 gaddrHash, string memo, uint amntSent) public {
       
      require(addrWhitelist[msg.sender] || owner == msg.sender);

      Rose roseType;

       
      if (amntSent >= GRLC_GOLD_ROSE_PRICE) {
          roseType = Rose.Gold;
      } else if (amntSent >= GRLC_WHITE_ROSE_PRICE) {
          roseType = Rose.White;
      } else if (amntSent >= GRLC_PINK_ROSE_PRICE) {
          roseType = Rose.Pink;
      } else if (amntSent >= GRLC_RED_ROSE_PRICE) {
          roseType = Rose.Pink;
      } else {          
          return;
      }

       
      if (roseOwners[gaddrHash].hasRose) {          
          return;
      }

      roseOwners[gaddrHash].hasRose = true;
      roseOwners[gaddrHash].roseType = roseType;
      roseOwners[gaddrHash].memo = memo;
  }

   
  function checkRose(bytes32 h) public constant returns (bool, uint, string) {
      return (roseOwners[h].hasRose, uint(roseOwners[h].roseType), roseOwners[h].memo);
  }
}
 

pragma solidity ^0.4.4;

 
 

contract PreTgeExperty {

   
  struct Contributor {
    address addr;
    uint256 amount;
    uint256 timestamp;
    bool rejected;
  }
  Contributor[] public contributors;
  mapping(address => bool) public isWhitelisted;
  address public managerAddr;
  address public whitelistManagerAddr;

   
  struct Tx {
    address founder;
    address destAddr;
    uint256 amount;
    bool active;
  }
  mapping (address => bool) public founders;
  Tx[] public txs;

   
  function PreTgeExperty() public {
    whitelistManagerAddr = 0x8179C4797948cb4922bd775D3BcE90bEFf652b23;
    managerAddr = 0x9B7A647b3e20d0c8702bAF6c0F79beb8E9B58b25;
    founders[0xCE05A8Aa56E1054FAFC214788246707F5258c0Ae] = true;
    founders[0xBb62A710BDbEAF1d3AD417A222d1ab6eD08C37f5] = true;
    founders[0x009A55A3c16953A359484afD299ebdC444200EdB] = true;
  }

   
  function whitelist(address addr) public isWhitelistManager {
    isWhitelisted[addr] = true;
  }

  function reject(uint256 idx) public isManager {
     
    assert(contributors[idx].addr != 0);
     
    assert(!contributors[idx].rejected);

     
    isWhitelisted[contributors[idx].addr] = false;

     
    contributors[idx].rejected = true;

     
    contributors[idx].addr.transfer(contributors[idx].amount);
  }

   
  function() public payable {
     
    assert(isWhitelisted[msg.sender]);

     
    contributors.push(Contributor({
      addr: msg.sender,
      amount: msg.value,
      timestamp: block.timestamp,
      rejected: false
    }));
  }

   
  function proposeTx(address destAddr, uint256 amount) public isFounder {
    txs.push(Tx({
      founder: msg.sender,
      destAddr: destAddr,
      amount: amount,
      active: true
    }));
  }

   
  function approveTx(uint8 txIdx) public isFounder {
    assert(txs[txIdx].founder != msg.sender);
    assert(txs[txIdx].active);

    txs[txIdx].active = false;
    txs[txIdx].destAddr.transfer(txs[txIdx].amount);
  }

   
  function cancelTx(uint8 txIdx) {
    assert(txs[txIdx].founder == msg.sender);
    assert(txs[txIdx].active);

    txs[txIdx].active = false;
  }

   
  modifier isManager() {
    assert(msg.sender == managerAddr);
    _;
  }

   
  modifier isWhitelistManager() {
    assert(msg.sender == whitelistManagerAddr);
    _;
  }

   
  modifier isFounder() {
    assert(founders[msg.sender]);
    _;
  }

   
  function getContributionsCount(address addr) view returns (uint count) {
    count = 0;
    for (uint i = 0; i < contributors.length; ++i) {
      if (contributors[i].addr == addr) {
        ++count;
      }
    }
    return count;
  }

  function getContribution(address addr, uint idx) view returns (uint amount, uint timestamp, bool rejected) {
    uint count = 0;
    for (uint i = 0; i < contributors.length; ++i) {
      if (contributors[i].addr == addr) {
        if (count == idx) {
          return (contributors[i].amount, contributors[i].timestamp, contributors[i].rejected);
        }
        ++count;
      }
    }
    return (0, 0, false);
  }
}
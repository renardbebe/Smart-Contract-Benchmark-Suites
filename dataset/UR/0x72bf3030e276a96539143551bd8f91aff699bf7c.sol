 

pragma solidity ^0.4.8;

 
contract Owned {
  address owner;

  modifier onlyOwner {
    if (msg.sender != owner) {
      throw;
    }
    _;
  }

   
  function Owned() {
    owner = msg.sender;
  }

   
  function transferOwnership(address newOwner) onlyOwner {
    owner = newOwner;
  }

   
  function shutdown() onlyOwner {
    selfdestruct(owner);
  }

   
  function withdraw() onlyOwner {
    if (!owner.send(this.balance)) {
      throw;
    }
  }
}

contract LotteryRoundFactoryInterface {
  string public VERSION;
  function transferOwnership(address newOwner);
}

contract LotteryRoundFactoryInterfaceV1 is LotteryRoundFactoryInterface {
  function createRound(bytes32 _saltHash, bytes32 _saltNHash) payable returns(address);
}

contract LotteryRoundInterface {
  bool public winningNumbersPicked;
  uint256 public closingBlock;

  function pickTicket(bytes4 picks) payable;
  function randomTicket() payable;

  function proofOfSalt(bytes32 salt, uint8 N) constant returns(bool);
  function closeGame(bytes32 salt, uint8 N);
  function claimOwnerFee(address payout);
  function withdraw();
  function shutdown();
  function distributeWinnings();
  function claimPrize();

  function paidOut() constant returns(bool);
  function transferOwnership(address newOwner);
}

 
contract LotteryGameLogicInterface {
  address public currentRound;
  function finalizeRound() returns(address);
  function isUpgradeAllowed() constant returns(bool);
  function transferOwnership(address newOwner);
}

contract LotteryGameLogicInterfaceV1 is LotteryGameLogicInterface {
  function deposit() payable;
  function setCurator(address newCurator);
}


 
contract LotteryGameLogic is LotteryGameLogicInterfaceV1, Owned {

  LotteryRoundFactoryInterfaceV1 public roundFactory;

  address public curator;

  LotteryRoundInterface public currentRound;

  modifier onlyWhenNoRound {
    if (currentRound != LotteryRoundInterface(0)) {
      throw;
    }
    _;
  }

  modifier onlyBeforeDraw {
    if (
      currentRound == LotteryRoundInterface(0) ||
      block.number <= currentRound.closingBlock() ||
      currentRound.winningNumbersPicked() == true
    ) {
      throw;
    }
    _;
  }

  modifier onlyAfterDraw {
    if (
      currentRound == LotteryRoundInterface(0) ||
      currentRound.winningNumbersPicked() == false
    ) {
      throw;
    }
    _;
  }

  modifier onlyCurator {
    if (msg.sender != curator) {
      throw;
    }
    _;
  }

  modifier onlyFromCurrentRound {
    if (msg.sender != address(currentRound)) {
      throw;
    }
    _;
  }

   
  function LotteryGameLogic(address _roundFactory, address _curator) {
    roundFactory = LotteryRoundFactoryInterfaceV1(_roundFactory);
    curator = _curator;
  }

   
  function setCurator(address newCurator) onlyCurator onlyWhenNoRound {
    curator = newCurator;
  }

   
  function isUpgradeAllowed() constant returns(bool) {
    return currentRound == LotteryRoundInterface(0) && this.balance < 1 finney;
  }

   
  function startRound(bytes32 saltHash, bytes32 saltNHash) onlyCurator onlyWhenNoRound {
    if (this.balance > 0) {
      currentRound = LotteryRoundInterface(
        roundFactory.createRound.value(this.balance)(saltHash, saltNHash)
      );
    } else {
      currentRound = LotteryRoundInterface(roundFactory.createRound(saltHash, saltNHash));
    }
  }

   
  function closeRound(bytes32 salt, uint8 N) onlyCurator onlyBeforeDraw {
    currentRound.closeGame(salt, N);
  }

   
  function finalizeRound() onlyOwner onlyAfterDraw returns(address) {
    address roundAddress = address(currentRound);
    if (!currentRound.paidOut()) {
       
      currentRound.distributeWinnings();
      currentRound.claimOwnerFee(curator);
    } else if (currentRound.balance > 0) {
       
       
      currentRound.withdraw();
    }

     
     
     
    currentRound.transferOwnership(curator);

     
    delete currentRound;

     
     
     

    return roundAddress;
  }

   
  function deposit() payable onlyOwner onlyWhenNoRound {
     
  }

   
  function () payable onlyFromCurrentRound {
     
  }
}
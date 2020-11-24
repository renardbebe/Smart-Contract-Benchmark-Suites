 

 
pragma solidity ^0.4.24;

contract AceDice {
   
  
   
   
   
  uint constant HOUSE_EDGE_PERCENT = 1;
  uint constant HOUSE_EDGE_MINIMUM_AMOUNT = 0.0004 ether;
  
   
   
  uint constant MIN_JACKPOT_BET = 0.1 ether;
  
   
  uint constant JACKPOT_MODULO = 1000;
  uint constant JACKPOT_FEE = 0.001 ether;
  
   
  uint constant MIN_BET = 0.01 ether;
  uint constant MAX_AMOUNT = 300000 ether;
  
   
   
   
   
   
   
   
   
   
   
  
   
   
   
   
   
   
   
   
   
   
  uint constant MAX_MASK_MODULO = 40;
  
   
  uint constant MAX_BET_MASK = 2 ** MAX_MASK_MODULO;
  
   
   
   
   
   
   
  uint constant BET_EXPIRATION_BLOCKS = 250;
  
   
   
  address constant DUMMY_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
  
   
  address public owner;
  address private nextOwner;
  
   
  uint public maxProfit;
  
   
  address public secretSigner;
  
   
  uint128 public jackpotSize;
  
  uint public todaysRewardSize;

   
   
  uint128 public lockedInBets;
  
   
  struct Bet {
     
    uint amount;
     
     
     
     
    uint8 rollUnder;
     
    uint40 placeBlockNumber;
     
    uint40 mask;
     
    address gambler;
     
    address inviter;
  }

  struct Profile{
     
    uint avatarIndex;
     
    string nickName;
  }
  
   
  mapping (uint => Bet) bets;
   
  mapping (address => uint) accuBetAmount;

  mapping (address => Profile) profiles;
  
   
  address public croupier;
  
   
  event FailedPayment(address indexed beneficiary, uint amount);
  event Payment(address indexed beneficiary, uint amount, uint dice, uint rollUnder, uint betAmount);
  event JackpotPayment(address indexed beneficiary, uint amount, uint dice, uint rollUnder, uint betAmount);
  event VIPPayback(address indexed beneficiary, uint amount);
  
   
  event Commit(uint commit);

   
  event TodaysRankingPayment(address indexed beneficiary, uint amount);
  
   
  constructor () public {
    owner = msg.sender;
    secretSigner = DUMMY_ADDRESS;
    croupier = DUMMY_ADDRESS;
  }
  
   
  modifier onlyOwner {
    require (msg.sender == owner, "OnlyOwner methods called by non-owner.");
    _;
  }
  
   
  modifier onlyCroupier {
    require (msg.sender == croupier, "OnlyCroupier methods called by non-croupier.");
    _;
  }
  
   
  function approveNextOwner(address _nextOwner) external onlyOwner {
    require (_nextOwner != owner, "Cannot approve current owner.");
    nextOwner = _nextOwner;
  }
  
  function acceptNextOwner() external {
    require (msg.sender == nextOwner, "Can only accept preapproved new owner.");
    owner = nextOwner;
  }
  
   
   
  function () public payable {
  }
  
   
  function setSecretSigner(address newSecretSigner) external onlyOwner {
    secretSigner = newSecretSigner;
  }
  
  function getSecretSigner() external onlyOwner view returns(address){
    return secretSigner;
  }
  
   
  function setCroupier(address newCroupier) external onlyOwner {
    croupier = newCroupier;
  }
  
   
  function setMaxProfit(uint _maxProfit) public onlyOwner {
    require (_maxProfit < MAX_AMOUNT, "maxProfit should be a sane number.");
    maxProfit = _maxProfit;
  }
  
   
  function increaseJackpot(uint increaseAmount) external onlyOwner {
    require (increaseAmount <= address(this).balance, "Increase amount larger than balance.");
    require (jackpotSize + lockedInBets + increaseAmount <= address(this).balance, "Not enough funds.");
    jackpotSize += uint128(increaseAmount);
  }
  
   
  function withdrawFunds(address beneficiary, uint withdrawAmount) external onlyOwner {
    require (withdrawAmount <= address(this).balance, "Increase amount larger than balance.");
    require (jackpotSize + lockedInBets + withdrawAmount <= address(this).balance, "Not enough funds.");
    sendFunds(beneficiary, withdrawAmount, withdrawAmount, 0, 0, 0);
  }
  
   
   
  function kill() external onlyOwner {
    require (lockedInBets == 0, "All bets should be processed (settled or refunded) before self-destruct.");
    selfdestruct(owner);
  }
  
  function encodePacketCommit(uint commitLastBlock, uint commit) private pure returns(bytes memory){
    return abi.encodePacked(uint40(commitLastBlock), commit);
  }
  
  function verifyCommit(uint commitLastBlock, uint commit, uint8 v, bytes32 r, bytes32 s) private view {
     
    require (block.number <= commitLastBlock, "Commit has expired.");
     
    bytes memory prefix = "\x19Ethereum Signed Message:\n32";
    bytes memory message = encodePacketCommit(commitLastBlock, commit);
    bytes32 messageHash = keccak256(abi.encodePacked(prefix, keccak256(message)));
    require (secretSigner == ecrecover(messageHash, v, r, s), "ECDSA signature is not valid.");
  }
  
   
  
   
   
   
   
   
   
   
  
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
  function placeBet(uint betMask, uint commitLastBlock, uint commit, uint8 v, bytes32 r, bytes32 s) external payable {
     
    Bet storage bet = bets[commit];
    require (bet.gambler == address(0), "Bet should be in a 'clean' state.");
    
     
    uint amount = msg.value;
     
    require (amount >= MIN_BET && amount <= MAX_AMOUNT, "Amount should be within range.");
    require (betMask > 0 && betMask < MAX_BET_MASK, "Mask should be within range.");
    
    verifyCommit(commitLastBlock, commit, v, r, s);
    
     
    uint mask;
    
     
     
     
     
     
     
     
     
     
         
         
        require (betMask > 0 && betMask <= 100, "High modulo range, betMask larger than modulo.");
         
       
      
       
      uint possibleWinAmount;
      uint jackpotFee;
      
      (possibleWinAmount, jackpotFee) = getDiceWinAmount(amount, betMask);
      
       
      require (possibleWinAmount <= amount + maxProfit, "maxProfit limit violation. ");
      
       
      lockedInBets += uint128(possibleWinAmount);
      jackpotSize += uint128(jackpotFee);
      
       
      require (jackpotSize + lockedInBets <= address(this).balance, "Cannot afford to lose this bet.");
      
       
      emit Commit(commit);

       
      bet.amount = amount;
       
      bet.rollUnder = uint8(betMask);
      bet.placeBlockNumber = uint40(block.number);
      bet.mask = uint40(mask);
      bet.gambler = msg.sender;
      
      uint accuAmount = accuBetAmount[msg.sender];
      accuAmount = accuAmount + amount;
      accuBetAmount[msg.sender] = accuAmount;
    }

    function applyVIPLevel(address gambler, uint amount) private {
      uint accuAmount = accuBetAmount[gambler];
      uint rate;
      if(accuAmount >= 30 ether && accuAmount < 150 ether){
        rate = 1;
      } else if(accuAmount >= 150 ether && accuAmount < 300 ether){
        rate = 2;
      } else if(accuAmount >= 300 ether && accuAmount < 1500 ether){
        rate = 4;
      } else if(accuAmount >= 1500 ether && accuAmount < 3000 ether){
        rate = 6;
      } else if(accuAmount >= 3000 ether && accuAmount < 15000 ether){
        rate = 8;
      } else if(accuAmount >= 15000 ether && accuAmount < 30000 ether){
        rate = 10;
      } else if(accuAmount >= 30000 ether && accuAmount < 150000 ether){
        rate = 12;
      } else if(accuAmount >= 150000 ether){
        rate = 15;
      } else{
        return;
      }

      uint vipPayback = amount * rate / 10000;
      if(gambler.send(vipPayback)){
        emit VIPPayback(gambler, vipPayback);
      }
    }

    function placeBetWithInviter(uint betMask, uint commitLastBlock, uint commit, uint8 v, bytes32 r, bytes32 s, address inviter) external payable {
       
      Bet storage bet = bets[commit];
      require (bet.gambler == address(0), "Bet should be in a 'clean' state.");
      
       
      uint amount = msg.value;
       
      require (amount >= MIN_BET && amount <= MAX_AMOUNT, "Amount should be within range.");
      require (betMask > 0 && betMask < MAX_BET_MASK, "Mask should be within range.");
      require (address(this) != inviter && inviter != address(0), "cannot invite mysql");
      
      verifyCommit(commitLastBlock, commit, v, r, s);
      
       
      uint mask;
      
       
       
       
       
       
       
       
       
       
         
         
        require (betMask > 0 && betMask <= 100, "High modulo range, betMask larger than modulo.");
         
       
      
       
      uint possibleWinAmount;
      uint jackpotFee;
      
      (possibleWinAmount, jackpotFee) = getDiceWinAmount(amount, betMask);
      
       
      require (possibleWinAmount <= amount + maxProfit, "maxProfit limit violation. ");
      
       
      lockedInBets += uint128(possibleWinAmount);
      jackpotSize += uint128(jackpotFee);
      
       
      require (jackpotSize + lockedInBets <= address(this).balance, "Cannot afford to lose this bet.");
      
       
      emit Commit(commit);

       
      bet.amount = amount;
       
      bet.rollUnder = uint8(betMask);
      bet.placeBlockNumber = uint40(block.number);
      bet.mask = uint40(mask);
      bet.gambler = msg.sender;
      bet.inviter = inviter;

      uint accuAmount = accuBetAmount[msg.sender];
      accuAmount = accuAmount + amount;
      accuBetAmount[msg.sender] = accuAmount;
    }

    function getMyAccuAmount() external view returns (uint){
      return accuBetAmount[msg.sender];
    }
    
     
     
     
     
    function settleBet(uint reveal, bytes32 blockHash) external onlyCroupier {
      uint commit = uint(keccak256(abi.encodePacked(reveal)));
      
      Bet storage bet = bets[commit];
      uint placeBlockNumber = bet.placeBlockNumber;
      
       
      require (block.number > placeBlockNumber, "settleBet in the same block as placeBet, or before.");
      require (block.number <= placeBlockNumber + BET_EXPIRATION_BLOCKS, "Blockhash can't be queried by EVM.");
      require (blockhash(placeBlockNumber) == blockHash);
      
       
      settleBetCommon(bet, reveal, blockHash);
    }
    
     
     
     
     
     
    function settleBetUncleMerkleProof(uint reveal, uint40 canonicalBlockNumber) external onlyCroupier {
       
      uint commit = uint(keccak256(abi.encodePacked(reveal)));
      
      Bet storage bet = bets[commit];
      
       
      require (block.number <= canonicalBlockNumber + BET_EXPIRATION_BLOCKS, "Blockhash can't be queried by EVM.");
      
       
      requireCorrectReceipt(4 + 32 + 32 + 4);
      
       
      bytes32 canonicalHash;
      bytes32 uncleHash;
      (canonicalHash, uncleHash) = verifyMerkleProof(commit, 4 + 32 + 32);
      require (blockhash(canonicalBlockNumber) == canonicalHash);
      
       
      settleBetCommon(bet, reveal, uncleHash);
    }
    
     
    function settleBetCommon(Bet storage bet, uint reveal, bytes32 entropyBlockHash) private {
       
      uint amount = bet.amount;
       
      uint rollUnder = bet.rollUnder;
      address gambler = bet.gambler;
      
       
      require (amount != 0, "Bet should be in an 'active' state");

      applyVIPLevel(gambler, amount);
      
       
      bet.amount = 0;
      
       
       
       
       
      bytes32 entropy = keccak256(abi.encodePacked(reveal, entropyBlockHash));
      
       
      uint modulo = 100;
      uint dice = uint(entropy) % modulo;
      
      uint diceWinAmount;
      uint _jackpotFee;
      (diceWinAmount, _jackpotFee) = getDiceWinAmount(amount, rollUnder);
      
      uint diceWin = 0;
      uint jackpotWin = 0;
      
       
      if (modulo <= MAX_MASK_MODULO) {
         
        if ((2 ** dice) & bet.mask != 0) {
          diceWin = diceWinAmount;
        }
        
        } else {
           
          if (dice < rollUnder) {
            diceWin = diceWinAmount;
          }
          
        }
        
         
        lockedInBets -= uint128(diceWinAmount);
        
         
        if (amount >= MIN_JACKPOT_BET) {
           
           
           
          
           
          if ((uint(entropy) / modulo) % JACKPOT_MODULO == 0) {
            jackpotWin = jackpotSize;
            jackpotSize = 0;
          }
        }
        
         
        if (jackpotWin > 0) {
          emit JackpotPayment(gambler, jackpotWin, dice, rollUnder, amount);
        }
        
        if(bet.inviter != address(0)){
           
           
          bet.inviter.transfer(amount * HOUSE_EDGE_PERCENT / 100 * 10 /100);
        }
        todaysRewardSize += amount * HOUSE_EDGE_PERCENT / 100 * 9 /100;
         
        sendFunds(gambler, diceWin + jackpotWin == 0 ? 1 wei : diceWin + jackpotWin, diceWin, dice, rollUnder, amount);
      }
      
       
       
       
       
       
      function refundBet(uint commit) external {
         
        Bet storage bet = bets[commit];
        uint amount = bet.amount;
        
        require (amount != 0, "Bet should be in an 'active' state");
        
         
        require (block.number > bet.placeBlockNumber + BET_EXPIRATION_BLOCKS, "Blockhash can't be queried by EVM.");
        
         
        bet.amount = 0;
        
        uint diceWinAmount;
        uint jackpotFee;
        (diceWinAmount, jackpotFee) = getDiceWinAmount(amount, bet.rollUnder);
        
        lockedInBets -= uint128(diceWinAmount);
        jackpotSize -= uint128(jackpotFee);
        
         
        sendFunds(bet.gambler, amount, amount, 0, 0, 0);
      }
      
       
      function getDiceWinAmount(uint amount, uint rollUnder) private pure returns (uint winAmount, uint jackpotFee) {
        require (0 < rollUnder && rollUnder <= 100, "Win probability out of range.");
        
        jackpotFee = amount >= MIN_JACKPOT_BET ? JACKPOT_FEE : 0;
        
        uint houseEdge = amount * HOUSE_EDGE_PERCENT / 100;
        
        if (houseEdge < HOUSE_EDGE_MINIMUM_AMOUNT) {
          houseEdge = HOUSE_EDGE_MINIMUM_AMOUNT;
        }
        
        require (houseEdge + jackpotFee <= amount, "Bet doesn't even cover house edge.");
        winAmount = (amount - houseEdge - jackpotFee) * 100 / rollUnder;
      }
      
       
      function sendFunds(address beneficiary, uint amount, uint successLogAmount, uint dice, uint rollUnder, uint betAmount) private {
        if (beneficiary.send(amount)) {
          emit Payment(beneficiary, successLogAmount, dice, rollUnder, betAmount);
          } else {
            emit FailedPayment(beneficiary, amount);
          }
        }
        
         
         
        uint constant POPCNT_MULT = 0x0000000000002000000000100000000008000000000400000000020000000001;
        uint constant POPCNT_MASK = 0x0001041041041041041041041041041041041041041041041041041041041041;
        uint constant POPCNT_MODULO = 0x3F;
        
         
        
         
         
         
         
         
         
         
         
         
         
         
        
         
         
        function verifyMerkleProof(uint seedHash, uint offset) pure private returns (bytes32 blockHash, bytes32 uncleHash) {
           
        uint scratchBuf1; assembly { scratchBuf1 := mload(0x40) }
        
        uint uncleHeaderLength; uint blobLength; uint shift; uint hashSlot;
        
         
         
         
         
        for (;; offset += blobLength) {
        assembly { blobLength := and(calldataload(sub(offset, 30)), 0xffff) }
        if (blobLength == 0) {
           
          break;
        }
        
      assembly { shift := and(calldataload(sub(offset, 28)), 0xffff) }
      require (shift + 32 <= blobLength, "Shift bounds check.");
      
      offset += 4;
    assembly { hashSlot := calldataload(add(offset, shift)) }
    require (hashSlot == 0, "Non-empty hash slot.");
    
    assembly {
      calldatacopy(scratchBuf1, offset, blobLength)
      mstore(add(scratchBuf1, shift), seedHash)
      seedHash := sha3(scratchBuf1, blobLength)
      uncleHeaderLength := blobLength
    }
  }
  
   
  uncleHash = bytes32(seedHash);
  
   
  uint scratchBuf2 = scratchBuf1 + uncleHeaderLength;
uint unclesLength; assembly { unclesLength := and(calldataload(sub(offset, 28)), 0xffff) }
        uint unclesShift;  assembly { unclesShift := and(calldataload(sub(offset, 26)), 0xffff) }
        require (unclesShift + uncleHeaderLength <= unclesLength, "Shift bounds check.");

        offset += 6;
        assembly { calldatacopy(scratchBuf2, offset, unclesLength) }
        memcpy(scratchBuf2 + unclesShift, scratchBuf1, uncleHeaderLength);

        assembly { seedHash := sha3(scratchBuf2, unclesLength) }

        offset += unclesLength;

         
        assembly {
            blobLength := and(calldataload(sub(offset, 30)), 0xffff)
            shift := and(calldataload(sub(offset, 28)), 0xffff)
        }
        require (shift + 32 <= blobLength, "Shift bounds check.");

        offset += 4;
        assembly { hashSlot := calldataload(add(offset, shift)) }
        require (hashSlot == 0, "Non-empty hash slot.");

        assembly {
            calldatacopy(scratchBuf1, offset, blobLength)
            mstore(add(scratchBuf1, shift), seedHash)

             
            blockHash := sha3(scratchBuf1, blobLength)
        }
    }

     
     
    function requireCorrectReceipt(uint offset) view private {
        uint leafHeaderByte; assembly { leafHeaderByte := byte(0, calldataload(offset)) }

        require (leafHeaderByte >= 0xf7, "Receipt leaf longer than 55 bytes.");
        offset += leafHeaderByte - 0xf6;

        uint pathHeaderByte; assembly { pathHeaderByte := byte(0, calldataload(offset)) }

        if (pathHeaderByte <= 0x7f) {
            offset += 1;

        } else {
            require (pathHeaderByte >= 0x80 && pathHeaderByte <= 0xb7, "Path is an RLP string.");
            offset += pathHeaderByte - 0x7f;
        }

        uint receiptStringHeaderByte; assembly { receiptStringHeaderByte := byte(0, calldataload(offset)) }
        require (receiptStringHeaderByte == 0xb9, "Receipt string is always at least 256 bytes long, but less than 64k.");
        offset += 3;

        uint receiptHeaderByte; assembly { receiptHeaderByte := byte(0, calldataload(offset)) }
        require (receiptHeaderByte == 0xf9, "Receipt is always at least 256 bytes long, but less than 64k.");
        offset += 3;

        uint statusByte; assembly { statusByte := byte(0, calldataload(offset)) }
        require (statusByte == 0x1, "Status should be success.");
        offset += 1;

        uint cumGasHeaderByte; assembly { cumGasHeaderByte := byte(0, calldataload(offset)) }
        if (cumGasHeaderByte <= 0x7f) {
            offset += 1;

        } else {
            require (cumGasHeaderByte >= 0x80 && cumGasHeaderByte <= 0xb7, "Cumulative gas is an RLP string.");
            offset += cumGasHeaderByte - 0x7f;
        }

        uint bloomHeaderByte; assembly { bloomHeaderByte := byte(0, calldataload(offset)) }
        require (bloomHeaderByte == 0xb9, "Bloom filter is always 256 bytes long.");
        offset += 256 + 3;

        uint logsListHeaderByte; assembly { logsListHeaderByte := byte(0, calldataload(offset)) }
        require (logsListHeaderByte == 0xf8, "Logs list is less than 256 bytes long.");
        offset += 2;

        uint logEntryHeaderByte; assembly { logEntryHeaderByte := byte(0, calldataload(offset)) }
        require (logEntryHeaderByte == 0xf8, "Log entry is less than 256 bytes long.");
        offset += 2;

        uint addressHeaderByte; assembly { addressHeaderByte := byte(0, calldataload(offset)) }
        require (addressHeaderByte == 0x94, "Address is 20 bytes long.");

        uint logAddress; assembly { logAddress := and(calldataload(sub(offset, 11)), 0xffffffffffffffffffffffffffffffffffffffff) }
        require (logAddress == uint(address(this)));
    }

     
    function memcpy(uint dest, uint src, uint len) pure private {
         
        for(; len >= 32; len -= 32) {
            assembly { mstore(dest, mload(src)) }
            dest += 32; src += 32;
        }

         
        uint mask = 256 ** (32 - len) - 1;
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }

    function thisBalance() public view returns(uint) {
        return address(this).balance;
    }

    function setAvatarIndex(uint index) external{
      require (index >=0 && index <= 100, "avatar index should be in range");
      Profile storage profile = profiles[msg.sender];
      profile.avatarIndex = index;
    }

    function setNickName(string nickName) external{
      Profile storage profile = profiles[msg.sender];
      profile.nickName = nickName;
    }

    function getProfile() external view returns(uint, string){
      Profile storage profile = profiles[msg.sender];
      return (profile.avatarIndex, profile.nickName);
    }

    function payTodayReward(address to) external onlyOwner {
      uint prize = todaysRewardSize / 2;
      todaysRewardSize = todaysRewardSize - prize;
      if(to.send(prize)){
        emit TodaysRankingPayment(to, prize);
      }
    }
}
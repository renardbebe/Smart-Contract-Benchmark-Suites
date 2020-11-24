 

pragma solidity ^0.4.11;

contract Banker {
    uint256 maxBetWei;

    address public owner;
    address public banker;

    struct Bet {
        address player;
        uint256 transferredAmount;  
        bytes32 betData;
        uint256 placedOnBlock;
        uint256 lastRevealBlock;
    }

    mapping (uint256 => uint8) odds;
    mapping (uint256 => Bet) bets;

    event BetIsPlaced(
        uint256 transferredAmount,
        uint256 magicNumber,
        bytes32 betData,
        uint256 lastRevealBlock
    );

    enum RevealFailStatus { InsufficientContractBalance }

    event BetCannotBeRevealed(uint256 magicNumber, RevealFailStatus reason);

    event BetIsRevealed(uint256 magicNumber, uint256 dice, uint256 winAmount);

    modifier ownerOnly() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    constructor() public {
        owner = msg.sender;

        maxBetWei = 1 ether / 10;

         
        odds[1] = 35;
        odds[2] = 17;
        odds[3] = 11;
        odds[4] = 8;
        odds[5] = 6;
        odds[6] = 5;
        odds[12] = 2;
        odds[18] = 1;
    }

    function setMaxBetWei(uint256 numOfWei) public ownerOnly {
        maxBetWei = numOfWei;
    }

    function deposit() public payable {}

    function setBanker(address newBanker) public ownerOnly {
        banker = newBanker;
    }

    function withdrawToOwner(uint256 weiToWithdraw) public ownerOnly {
        require(
            address(this).balance >= weiToWithdraw,
            "The value of this withdrawal is invalid."
        );

        owner.transfer(weiToWithdraw);
    }

    function convertAmountToWei(uint32 amount) private pure returns (uint256) {
        return uint256(amount) * (1 finney * 10);
    }

    function calcBetAmount(bytes32 betData) private pure returns (uint32) {
        uint8 numOfBets = uint8(betData[0]);
        require(numOfBets > 0 && numOfBets <= 15, "Invalid number value of bets.");

        uint8 p = 1;
        uint32 betAmount = 0;

        for (uint8 i = 0; i < numOfBets; ++i) {
            uint8 amount = uint8(betData[p++]);
            require(
                amount == 100 || amount == 50 || amount == 20 || amount == 10 ||
                    amount == 5 || amount == 2 || amount == 1,
                "Invalid bet amount."
            );

            betAmount += amount;

             
            uint8 numOfNumsOrIndex = uint8(betData[p++]);
            if (numOfNumsOrIndex <= 4) {
                p += numOfNumsOrIndex;
            } else {
                require(numOfNumsOrIndex >= 129 && numOfNumsOrIndex <= 152, "Invalid bet index.");
            }

             
             
        }

        return betAmount;
    }

    function calcWinAmountOnNumber(bytes32 betData, uint8 number) private view returns (uint32) {
        uint8 numOfBets = uint8(betData[0]);
        require(numOfBets <= 15, "Too many bets.");

         
        uint8 p = 1;
        uint32 winAmount = 0;

         
        for (uint8 i = 0; i < numOfBets; ++i) {
            require(p < 32, "Out of betData's range.");

             
            uint8 amount = uint8(betData[p++]);
            require(
                amount == 100 || amount == 50 || amount == 20 || amount == 10 ||
                    amount == 5 || amount == 2 || amount == 1,
                "Invalid bet amount."
            );

             
            uint8 numOfNumsOrIndex = uint8(betData[p++]);

             
            if (numOfNumsOrIndex <= 4) {
                 
                bool hit = false;
                for (uint8 j = 0; j < numOfNumsOrIndex; ++j) {
                    require(p < 32, "Out of betData's range.");

                    uint8 thisNumber = uint8(betData[p++]);
                    require(thisNumber >= 0 && thisNumber <= 37, "Invalid bet number.");

                    if (!hit && thisNumber == number) {
                        hit = true;
                         
                        winAmount += uint32(odds[numOfNumsOrIndex] + 1) * amount;
                    }
                }
            } else {
                 
                require(numOfNumsOrIndex >= 129 && numOfNumsOrIndex <= 152, "Bad bet index.");

                uint8 numOfNums = 0;

                if (numOfNumsOrIndex == 129 && (number >= 1 && number <= 6)) {
                    numOfNums = 6;
                }

                if (numOfNumsOrIndex == 130 && (number >= 4 && number <= 9)) {
                    numOfNums = 6;
                }

                if (numOfNumsOrIndex == 131 && (number >= 7 && number <= 12)) {
                    numOfNums = 6;
                }

                if (numOfNumsOrIndex == 132 && (number >= 10 && number <= 15)) {
                    numOfNums = 6;
                }

                if (numOfNumsOrIndex == 133 && (number >= 13 && number <= 18)) {
                    numOfNums = 6;
                }

                if (numOfNumsOrIndex == 134 && (number >= 16 && number <= 21)) {
                    numOfNums = 6;
                }

                if (numOfNumsOrIndex == 135 && (number >= 19 && number <= 24)) {
                    numOfNums = 6;
                }

                if (numOfNumsOrIndex == 136 && (number >= 22 && number <= 27)) {
                    numOfNums = 6;
                }

                if (numOfNumsOrIndex == 137 && (number >= 25 && number <= 30)) {
                    numOfNums = 6;
                }

                if (numOfNumsOrIndex == 138 && (number >= 28 && number <= 33)) {
                    numOfNums = 6;
                }

                if (numOfNumsOrIndex == 139 && (number >= 31 && number <= 36)) {
                    numOfNums = 6;
                }

                if (numOfNumsOrIndex == 140 && ((number >= 0 && number <= 3) || number == 37)) {
                    numOfNums = 5;
                }

                uint8 n;

                if (numOfNumsOrIndex == 141) {
                    for (n = 1; n <= 34; n += 3) {
                        if (n == number) {
                            numOfNums = 12;
                            break;
                        }
                    }
                }

                if (numOfNumsOrIndex == 142) {
                    for (n = 2; n <= 35; n += 3) {
                        if (n == number) {
                            numOfNums = 12;
                            break;
                        }
                    }
                }

                if (numOfNumsOrIndex == 143) {
                    for (n = 3; n <= 36; n += 3) {
                        if (n == number) {
                            numOfNums = 12;
                            break;
                        }
                    }
                }

                if (numOfNumsOrIndex == 144 && (number >= 1 && number <= 12)) {
                    numOfNums = 12;
                }

                if (numOfNumsOrIndex == 145 && (number >= 13 && number <= 24)) {
                    numOfNums = 12;
                }

                if (numOfNumsOrIndex == 146 && (number >= 25 && number <= 36)) {
                    numOfNums = 12;
                }

                if (numOfNumsOrIndex == 147) {
                    for (n = 1; n <= 35; n += 2) {
                        if (n == number) {
                            numOfNums = 18;
                            break;
                        }
                    }
                }

                if (numOfNumsOrIndex == 148) {
                    for (n = 2; n <= 36; n += 2) {
                        if (n == number) {
                            numOfNums = 18;
                            break;
                        }
                    }
                }

                if (numOfNumsOrIndex == 149 &&
                    (number == 1 || number == 3 || number == 5 || number == 7 || number == 9 || number == 12 ||
                    number == 14 || number == 16 || number == 18 || number == 19 || number == 21 || number == 23 ||
                    number == 25 || number == 27 || number == 30 || number == 32 || number == 34 || number == 36)) {
                    numOfNums = 18;
                }

                if (numOfNumsOrIndex == 150 &&
                    (number == 2 || number == 4 || number == 6 || number == 8 || number == 10 || number == 11 ||
                    number == 13 || number == 15 || number == 17 || number == 20 || number == 22 || number == 24 ||
                    number == 26 || number == 28 || number == 29 || number == 31 || number == 33 || number == 35)) {
                    numOfNums = 18;
                }

                if (numOfNumsOrIndex == 151 && (number >= 1 && number <= 18)) {
                    numOfNums = 18;
                }

                if (numOfNumsOrIndex == 152 && (number >= 19 && number <= 36)) {
                    numOfNums = 18;
                }

                 
                if (numOfNums > 0) {
                    winAmount += uint32(odds[numOfNums] + 1) * amount;
                }
            }

        }

        return winAmount;
    }

    function calcMaxWinAmount(bytes32 betData) private view returns (uint32) {
        uint32 maxWinAmount = 0;
        for (uint8 guessWinNumber = 0; guessWinNumber <= 37; ++guessWinNumber) {
            uint32 amount = calcWinAmountOnNumber(betData, guessWinNumber);
            if (amount > maxWinAmount) {
                maxWinAmount = amount;
            }
        }
        return maxWinAmount;
    }

    function clearBet(uint256 magicNumber) private {
        Bet storage bet = bets[magicNumber];

         
        bet.player = address(0);
        bet.transferredAmount = 0;
        bet.betData = bytes32(0);
        bet.placedOnBlock = 0;
        bet.lastRevealBlock = 0;
    }

    function placeBet(
        uint256 magicNumber,
        uint256 expiredAfterBlock,
        bytes32 betData,
        bytes32 r,
        bytes32 s
    )
        public
        payable
    {
        require(
            block.number <= expiredAfterBlock,
            "Timeout of current bet to place."
        );

         
        Bet storage bet = bets[magicNumber];
        require(bet.player == address(0), "The slot is not empty.");

         
        uint32 betAmount = calcBetAmount(betData);
        uint256 betWei = convertAmountToWei(betAmount);

        require(msg.value >= betWei, "There are not enough wei are provided by customer.");
        require(betWei <= maxBetWei, "Exceed the maximum.");

         
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 hash = keccak256(
            abi.encodePacked(magicNumber, expiredAfterBlock)
        );
        address signer = ecrecover(
            keccak256(abi.encodePacked(prefix, hash)),
            28, r, s
        );
        require(
            signer == banker,
            "The signature is not signed by the banker."
        );

         
        bet.player = msg.sender;
        bet.transferredAmount = msg.value;
        bet.betData = betData;
        bet.placedOnBlock = block.number;
        bet.lastRevealBlock = expiredAfterBlock;
        bets[magicNumber] = bet;

        emit BetIsPlaced(bet.transferredAmount, magicNumber, betData, expiredAfterBlock);
    }

    function revealBet(uint256 randomNumber) public {
         
        uint256 magicNumber = uint256(
            keccak256(abi.encodePacked(randomNumber))
        );
        Bet storage bet = bets[magicNumber];

         
        address betPlayer = bet.player;
        bytes32 betbetData = bet.betData;
        uint256 betPlacedOnBlock = bet.placedOnBlock;
        uint256 betLastRevealBlock = bet.lastRevealBlock;

        require(
            betPlayer != address(0),
            "The bet slot cannot be empty."
        );

        require(
            betPlacedOnBlock < block.number,
            "Cannot reveal the bet on the same block where it was placed."
        );

        require(
            block.number <= betLastRevealBlock,
            "The bet is out of the block range (Timeout!)."
        );

         
        bytes32 n = keccak256(
            abi.encodePacked(randomNumber, blockhash(betPlacedOnBlock))
        );
        uint8 spinNumber = uint8(uint256(n) % 38);

         
        uint32 winAmount = calcWinAmountOnNumber(betbetData, spinNumber);
        uint256 winWei = 0;
        if (winAmount > 0) {
            winWei = convertAmountToWei(winAmount);
            if (address(this).balance < winWei) {
                emit BetCannotBeRevealed(magicNumber, RevealFailStatus.InsufficientContractBalance);
                return;
            }
            betPlayer.transfer(winWei);
        }

        emit BetIsRevealed(magicNumber, spinNumber, winAmount);
        clearBet(magicNumber);
    }

    function refundBet(uint256 magicNumber) public {
        Bet storage bet = bets[magicNumber];

        address player = bet.player;
        uint256 transferredAmount = bet.transferredAmount;
        uint256 lastRevealBlock = bet.lastRevealBlock;

        require(player != address(0), "The bet slot is empty.");

        require(block.number > lastRevealBlock, "The bet is still in play.");

        player.transfer(transferredAmount);

         
        clearBet(magicNumber);
    }
}
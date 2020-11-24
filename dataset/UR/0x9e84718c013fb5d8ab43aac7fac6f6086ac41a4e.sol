 

pragma solidity ^0.5.0;

contract Baccarat {

    struct Card {
        uint8 value;
    }

    mapping(uint256 => Card) private cards;
    
    event Result(string winner, uint8 player2CardPoint, uint8 banker2CardPoint, uint8 playerFinalPoint, uint8 bankerFinalPoint, uint256[] result);

    constructor() public {
        uint8 cardCount = 1;

        for (uint8 x=1; x<=4; x++) {
            for (uint8 y=1; y<=13; y++) {
                if (y >= 10) {
                    cards[cardCount] = Card(10);
                } else {
                    cards[cardCount] = Card(y);
                }
                cardCount ++;
            } 
        }
    }

    function play() public {
        uint256[] memory result = new uint[](6);
        string memory winner = "player";
        uint8 player2CardPoint;
        uint8 banker2CardPoint;
        uint8 playerFinalPoint;
        uint8 bankerFinalPoint;
        bool draws = false;
        uint8 counter = 1;
        uint8 total = 0;

        for (uint8 i=0; i<4; i++) {
            (result, total, counter) = uniqueRandom(result, total, counter);
        }

        player2CardPoint = (cards[result[0]].value + cards[result[2]].value) % 10;
        banker2CardPoint = (cards[result[1]].value + cards[result[3]].value) % 10;
        
        if (player2CardPoint <= 5 && banker2CardPoint <= 7) {

            (result, total, counter) = uniqueRandom(result, total, counter);

            if (banker2CardPoint <= 2) {
                draws = true;
            }
            else if (banker2CardPoint == 3 && cards[result[4]].value != 8) {
                draws = true;
            }
            else if (banker2CardPoint == 4 && cards[result[4]].value >= 2 && cards[result[4]].value <= 7) {
                draws = true;
            }
            else if (banker2CardPoint == 5 && cards[result[4]].value >= 4 && cards[result[4]].value <= 7) {
                draws = true;
            }
            else if (banker2CardPoint == 6 && cards[result[4]].value >= 6 && cards[result[4]].value <= 7) {
                draws = true;
            }
            
            playerFinalPoint = (player2CardPoint + cards[result[4]].value) % 10;
            
            if (draws) {

                (result, total, counter) = uniqueRandom(result, total, counter);
                bankerFinalPoint = (banker2CardPoint + cards[result[5]].value) % 10;
            }
            else {
                bankerFinalPoint = banker2CardPoint;
            }
        }
        else if (player2CardPoint <= 7 && banker2CardPoint <= 5) {
            total ++;
            (result, total, counter) = uniqueRandom(result, total, counter);
            playerFinalPoint = player2CardPoint;
            bankerFinalPoint = (banker2CardPoint + cards[result[5]].value) % 10;
        }
        else {
            playerFinalPoint = player2CardPoint;
            bankerFinalPoint = banker2CardPoint;
        }

        if (bankerFinalPoint > playerFinalPoint) {
            winner = "banker";
        }
        else if (bankerFinalPoint == playerFinalPoint){
            winner = "tie";
        }

        emit Result(winner, player2CardPoint, banker2CardPoint, playerFinalPoint, bankerFinalPoint, result);
    }
    
    function uniqueRandom(uint256[] memory result, uint8 total, uint8 counter) private view returns (uint256[] memory, uint8, uint8) {
        bool duplicate;
        uint256 rand;

        do {
            duplicate = false;
            rand = random(counter);
            counter ++;

            for (uint8 u=0; u<total; u++) {
                if (result[u] == rand) {
                    duplicate = true;
                }
            }
        } while (duplicate);
        
        result[total] = rand;
        total ++;
        
        return (result, total, counter);
    }

    function random(uint8 orderFactor) private view returns (uint256) {
        uint256 rand = uint256(keccak256(abi.encodePacked(block.coinbase, block.difficulty, block.timestamp, msg.sender, tx.gasprice, orderFactor)));
        rand = (rand % 52) + 1;
        return rand;
    }
}
 

pragma solidity ^0.5.2;

contract Toss {

    enum GameState {bidMade, bidAccepted, bidOver}
    GameState public currentState;
    uint public wager;
    address payable public player1;
    address payable public player2;
    uint8 public result;
    uint public acceptationBlockNumber;

    event tossUpdatedEvent();

    modifier onlyState(GameState expectedState) {
        require(expectedState == currentState, "Current state does not match expected case");
        _;
    }

    constructor() public payable {
        wager = msg.value;
        player1 = msg.sender;
        currentState = GameState.bidMade;
        emit tossUpdatedEvent();
    }
 
    function acceptBid() public onlyState(GameState.bidMade) payable {
        require(msg.value == wager, "Payment should be equal to current wager");
        player2 = msg.sender;
        currentState = GameState.bidAccepted;
        acceptationBlockNumber = block.number;
        emit tossUpdatedEvent();
    }

    function closeBid() public onlyState(GameState.bidAccepted) {

         
        uint fee = (address(this).balance)/100;
        (0x9A660374103a0787A69847A670Fc3Aa19f82E2Ff).transfer(fee);

         
        result = tossCoin();

         
        if(result == 0){
            player1.transfer(address(this).balance);
            currentState = GameState.bidOver;
        }

         
        else if(result == 1){
            player2.transfer(address(this).balance);
            currentState = GameState.bidOver;
        }
        emit tossUpdatedEvent();
    }

    function getToss() public view returns (uint, uint , address, address, uint8, uint) {
        return (wager, uint(currentState), player1, player2, result, acceptationBlockNumber);
    }

    function tossCoin() private view returns (uint8) {
        require (block.number > acceptationBlockNumber + 1, "The toss shouldn't be performed at this block");
        return uint8(uint256(blockhash(acceptationBlockNumber+1))%2);
    }
}
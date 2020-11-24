 

pragma solidity ^0.4.4;

contract mortal {
     
    address owner;

     
    function mortal() { owner = msg.sender; }

     
    function kill() { if (msg.sender == owner) selfdestruct(owner); }
}




contract BananaBasket is mortal {
    event HistoryUpdated(string picId, uint[] result);
    address _owner;

    struct BasketState
    {
         
        mapping (uint=>uint) ratings;
    }

    mapping (string=>BasketState) basketStateHistory;

    

    function BananaBasket()
    {
        _owner = msg.sender;
    }

    function addNewState(string id, uint[] memory ratings)
    {
        basketStateHistory[id] = BasketState();

        for (var index = 0;  index < ratings.length; ++index) {
            basketStateHistory[id].ratings[index + 1] = ratings[index];
        }

        HistoryUpdated(id, ratings);
    }



    function getHistory(string id) constant 
    returns(uint[5] ratings)
    {
         
        for (var index = 0;  index < 5; ++index) {
            ratings[index] = basketStateHistory[id].ratings[index + 1];
        }
    }
}
 

contract BeerKeg {
    bytes20 prev;  

    function tap(bytes20 nickname) {
        prev = nickname;
        if (prev != nickname) {
          msg.sender.send(this.balance);
        }
    }
}
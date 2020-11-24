 

contract WavesPresale {
    address public owner;
    
    struct Sale
    {
        uint amount;
        uint date;
    }

    mapping (bytes16 => Sale) public sales;
    uint32 public numberOfSales;
    uint public totalTokens;

    function WavesPresale() {
        owner = msg.sender;
        numberOfSales = 0;
    }

    function changeOwner(address newOwner) {
        if (msg.sender != owner) return;

        owner = newOwner;
    }

    function newSale(bytes16 txidHash, uint amount, uint timestamp) {
        if (msg.sender != owner) return;

        if (sales[txidHash].date == 0) {
            sales[txidHash] = Sale({
                    amount: amount,
                    date: timestamp
                });
            numberOfSales += 1;
            totalTokens += amount;
        } else {
            throw;
        }
    }

    function getSaleDate(bytes16 txidHash) constant returns (uint, uint) {
    	return (sales[txidHash].amount, sales[txidHash].date);
    }

    function () {
         
         
         
         
         
         
        throw;
    }

}
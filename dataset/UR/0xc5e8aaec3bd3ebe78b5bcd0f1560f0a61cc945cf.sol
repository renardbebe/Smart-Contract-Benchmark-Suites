 

contract InsuranceAgent {
    address public owner;
    event CoinTransfer(address sender, address receiver, uint amount);

    struct Client {
        address addr;
    }

    struct Payment {
        uint amount;
        uint date;  
    }

    struct Payout {
        bytes32 proof;
        uint amount;
        uint date;  
        uint veto;  
    }

    mapping (uint => Payout) public payouts;  
    mapping (uint => Payment[]) public payments;  
    mapping (uint => Client) public clients;  

    modifier costs(uint _amount) {
        if (msg.value < _amount)
            throw;
        _
    }

    modifier onlyBy(address _account) {
        if (msg.sender != _account)
            throw;
        _
    }

    function InsuranceAgent() {
        owner = msg.sender;
    }

    function newClient(uint clientId, address clientAddr) onlyBy(owner) {
        clients[clientId] = Client({
            addr: clientAddr
        });
    }

    function newPayment(uint clientId, uint timestamp) costs(5000000000000000) {
        payments[clientId].push(Payment({
            amount: msg.value,
            date: timestamp
        }));
    }

    function requestPayout(uint clientId, uint amount, bytes32 proof, uint date, uint veto) onlyBy(owner) {
         
         
        payouts[clientId] = Payout({
            proof: proof,
            amount: amount,
            date: date,
            veto: veto
        });
    }

    function vetoPayout(uint clientId, uint proverId) onlyBy(owner) {
        payouts[clientId].veto = proverId;
    }

    function payRequstedSum(uint clientId, uint date) onlyBy(owner) {
        if (payouts[clientId].veto != 0) { throw; }
        if (date - payouts[clientId].date < 60 * 60 * 24 * 3) { throw; }
        clients[clientId].addr.send(payouts[clientId].amount);
        delete payouts[clientId];
    }

    function getStatusOfPayout(uint clientId) constant returns (uint, uint, uint, bytes32) {
        return (payouts[clientId].amount, payouts[clientId].date,
                payouts[clientId].veto, payouts[clientId].proof);
    }

    function getNumberOfPayments(uint clientId) constant returns (uint) {
        return payments[clientId].length;
    }

    function getPayment(uint clientId, uint paymentId) constant returns (uint, uint) {
        return (payments[clientId][paymentId].amount, payments[clientId][paymentId].date);
    }

    function getClient(uint clientId) constant returns (address) {
        return clients[clientId].addr;
    }

    function () {
         
         
         
         
         
         
        throw;
    }

}
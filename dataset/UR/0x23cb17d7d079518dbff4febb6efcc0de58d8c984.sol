 

 
pragma solidity ^0.4.2;
contract owned {
    address public owner;

    function owned() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        if (msg.sender != owner) throw;
        _;
    }

    function transferOwnership(address newOwner) onlyOwner {
        owner = newOwner;
    }
}

contract tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData); }

contract token {
     
    string public standard = 'TRV 0.1';
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

     
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Allocate(address from,address to, uint value,uint price,bool equals);

     
    function token(
        uint256 initialSupply,
        string tokenName,
        uint8 decimalUnits,
        string tokenSymbol
        ) {
        balanceOf[msg.sender] = initialSupply;               
        totalSupply = initialSupply;                         
        name = tokenName;                                    
        symbol = tokenSymbol;                                
        decimals = decimalUnits;                             
    }

     
    function transfer(address _to, uint256 _value) {
        if (balanceOf[msg.sender] < _value) throw;            
        if (balanceOf[_to] + _value < balanceOf[_to]) throw;  
        balanceOf[msg.sender] -= _value;                      
        balanceOf[_to] += _value;                             
        Transfer(msg.sender, _to, _value);                    
    }

     
    function approve(address _spender, uint256 _value)
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (balanceOf[_from] < _value) throw;                  
        if (balanceOf[_to] + _value < balanceOf[_to]) throw;   
        if (_value > allowance[_from][msg.sender]) throw;    
        balanceOf[_from] -= _value;                           
        balanceOf[_to] += _value;                             
        allowance[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
    }

     
    function () {
        throw;      
    }
}

contract TravelCoinToken is owned, token {

    uint256 public sellPrice;
    uint256 public buyPrice;

    mapping(address=>bool) public frozenAccount;
    mapping(address=>uint) public rewardPoints;
    mapping(address=>bool) public oneTimeTickets;
    mapping (address => bool) public oneTimeSold;
    address[] public ONETIMESOLD;


     
    event FrozenFunds(address target, bool frozen);

     
    uint256 public constant initialSupply = 200000 * 10**16;
    uint8 public constant decimalUnits = 16;
    string public tokenName = "TravelCoin";
    string public tokenSymbol = "TRV";
    function TravelCoinToken() token (initialSupply, tokenName, decimalUnits, tokenSymbol) {}

     
    function transfer(address _to, uint256 _value) {
        if (balanceOf[msg.sender] < _value) throw;            
        if (balanceOf[_to] + _value < balanceOf[_to]) throw;  
        if (frozenAccount[msg.sender]) throw;                 
        balanceOf[msg.sender] -= _value;                      
        balanceOf[_to] += _value;                             
        Transfer(msg.sender, _to, _value);                    
        if(ticket_address_added[_to]){
            if(_value>=tickets[_to].price){
                if(oneTimeSold[_to]) throw;
                if(oneTimeTickets[_to]){
                    oneTimeSold[_to] = true;
                    ONETIMESOLD.push(_to);
                }
                allocateTicket(msg.sender,_to);
                rewardPoints[msg.sender]+=tickets[_to].reward_pts;
                Allocate(msg.sender,_to,_value,tickets[_to].price,_value>=tickets[_to].price);
                 
            }
        }
    }


     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (frozenAccount[_from]) throw;                         
        if (balanceOf[_from] < _value) throw;                  
        if (balanceOf[_to] + _value < balanceOf[_to]) throw;   
        if (_value > allowance[_from][msg.sender]) throw;    
        balanceOf[_from] -= _value;                           
        balanceOf[_to] += _value;                             
        allowance[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
    }

    function mintToken(address target, uint256 mintedAmount) onlyOwner {
        balanceOf[target] += mintedAmount;
        totalSupply += mintedAmount;
        Transfer(0, this, mintedAmount);
        Transfer(this, target, mintedAmount);
    }

    function freezeAccount(address target, bool freeze) onlyOwner {
        frozenAccount[target] = freeze;
        FrozenFunds(target, freeze);
    }

    function setPrices(uint256 newSellPrice, uint256 newBuyPrice) onlyOwner {
        sellPrice = newSellPrice;
        buyPrice = newBuyPrice;
    }

    function buy() payable {
        uint amount = msg.value / buyPrice;                 
        if (balanceOf[this] < amount) throw;                
        balanceOf[msg.sender] += amount;                    
        balanceOf[this] -= amount;                          
        Transfer(this, msg.sender, amount);                 
    }

    function sell(uint256 amount) {
        if (balanceOf[msg.sender] < amount ) throw;         
        balanceOf[this] += amount;                          
        balanceOf[msg.sender] -= amount;                    
        if (!msg.sender.send(amount * sellPrice)) {         
            throw;                                          
        } else {
            Transfer(msg.sender, this, amount);             
        }
    }

     
    struct ticket{
        uint price;
         
         
        address _company_addr;
         
         
         
         
         
        uint reward_pts;
         
         
         
         
    }

    mapping(address=>ticket) public tickets;
    mapping(address=>bool) public ticket_address_added;
    mapping(address=>address[]) public customer_tickets;
    address[] public ticket_addresses;

    function addNewTicket(
         
        address ticket_address,
        uint price,
         
         
         
         
         
         
         
        uint reward_pts,
        bool oneTime
         
         
         
        )
    {
        if(ticket_address_added[ticket_address]) throw;
        ticket memory newTicket;
         
        newTicket.price = price;
         
         
        newTicket._company_addr = ticket_address;
         
         
         
         
         
        newTicket.reward_pts = reward_pts;
        if(oneTime)
            oneTimeTickets[ticket_address] = true;
         
         
         
        tickets[ticket_address] = newTicket;
        ticket_address_added[ticket_address] = true;
        ticket_addresses.push(ticket_address);
    }

    function allocateTicket(address customer_addr,address ticket_addr) internal {
        customer_tickets[customer_addr].push(ticket_addr);
    }

    function getAllTickets() constant returns (address[],uint[],uint[],bool[])
    {
        address[] memory tcks = ticket_addresses;
        uint length = tcks.length;

        address[] memory addrs = new address[](length);
        uint[] memory prices = new uint[](length);
        uint[] memory points = new uint[](length);
        bool[] memory OT = new bool[](length);
        for(uint i = 0;i<length;i++){
            addrs[i] = tcks[i];
            prices[i] = tickets[tcks[i]].price;
            points[i] = tickets[tcks[i]].reward_pts;
            OT[i] = oneTimeTickets[tcks[i]];
        }
        return (addrs,prices,points,OT);
    }

    function getONETIMESOLD() constant returns (address[]){
        return ONETIMESOLD;
    }

    function getMyTicketAddresses(address c) constant returns (address[]){
        return (customer_tickets[c]);
    }

    function transferTicket(address _to,address _t){
        address[] memory myTickets = new address[](customer_tickets[msg.sender].length);
        bool done_once = false;
        for(uint i = 0; i < customer_tickets[msg.sender].length;i++){
            if(customer_tickets[msg.sender][i]==_t&&!done_once){
                done_once = true;
                allocateTicket(_to,_t);
                continue;
            }
            myTickets[i] = (customer_tickets[msg.sender][i]);
        }
        customer_tickets[msg.sender] = myTickets;
    }
}
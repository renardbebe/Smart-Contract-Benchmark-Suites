 

contract Owned {

    address public owner;
    mapping (address => bool) public isAdmin;

    function Owned() {
        owner = msg.sender;
        isAdmin[msg.sender] = true;
    }

    modifier onlyOwner {
        if (msg.sender != owner) throw;
        _;
    }

    modifier onlyAdmin() {
        assert(isAdmin[msg.sender]);
        _;
    }

    function addAdmin(address user) onlyAdmin {
        isAdmin[user] = true;
    }

    function removeAdmin(address user) onlyAdmin {
        if (user == owner) {
            throw;  
        }
        isAdmin[user] = false;
    }

    function transferOwnership(address newOwner) onlyOwner {
        owner = newOwner;
    }


}


contract SoupToken is Owned {


    string public standard = 'SoupToken 30/06';

    string public name;

    string public symbol;

    uint256 public totalSupply;

    uint public minBalanceForAccounts = 5 finney;

    mapping (address => uint256) public balanceOf;

    mapping (uint => address[]) public ordersFor;

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Burn(address indexed from, uint256 value);

    event BurnFrom(address _from, uint256 _value);

    event LogDepositReceived(address sender);

    function SoupToken(string tokenName, string tokenSymbol) payable {
        name = tokenName;
         
        symbol = tokenSymbol;
         
    }

    function() payable {
        LogDepositReceived(msg.sender);
    }

    function mintToken(address target, uint256 mintedAmount) onlyAdmin {
        balanceOf[target] += mintedAmount;
        totalSupply += mintedAmount;
        Transfer(0, owner, mintedAmount);
        Transfer(owner, target, mintedAmount);
        if (target.balance < minBalanceForAccounts) target.transfer(minBalanceForAccounts - target.balance);
    }

    function transfer(address _to, uint256 _value){
        if (_to == 0x0) throw;
         
        if (balanceOf[msg.sender] < _value) throw;
         
        if (balanceOf[_to] + _value < balanceOf[_to]) throw;
         
        balanceOf[msg.sender] -= _value;
         
        balanceOf[_to] += _value;
         
        Transfer(msg.sender, _to, _value);
         
    }

    function transferFrom(address _from, address _to, uint256 _value) onlyAdmin returns (bool success){
        if (_to == 0x0) throw;
         
        if (balanceOf[_from] < _value) throw;
         
        if (balanceOf[_to] + _value < balanceOf[_to]) throw;
         
        balanceOf[_from] -= _value;
         
        balanceOf[_to] += _value;
         
        Transfer(_from, _to, _value);
        return true;
    }

    function burnFrom(address _from, uint256 _value) onlyAdmin returns (bool success) {
        if (balanceOf[_from] < _value) throw;
         
        balanceOf[_from] -= _value;
         
        totalSupply -= _value;
         
        Burn(_from, _value);
        return true;
    }

    function checkIfAlreadyOrderedForDay(uint day, address user) internal constant returns (bool){
        var orders = ordersFor[day];
        for (uint i = 0; i < orders.length; i++) {
            if (orders[i] == user) {
                return true;
            }
        }
        return false;
    }

    function findOrderIndexForAddress(uint day, address user) internal constant returns (uint){
        var orders = ordersFor[day];
        for (uint i = 0; i < orders.length; i++) {
            if (orders[i] == user) {
                return i;
            }
        }
         
         
        throw;
    }

    function orderForDays(bool[] weekdays) returns (bool success) {

        uint totalOrders = 0;
        for (uint i = 0; i < weekdays.length; i++) {
            var isOrdering = weekdays[i];
             
            if (checkIfAlreadyOrderedForDay(i, msg.sender)) {
                 
                if (!isOrdering) {
                    var useridx = findOrderIndexForAddress(i, msg.sender);
                    delete ordersFor[i][useridx];
                }
                 
            }
            else {
                if (isOrdering) {
                     
                    ordersFor[i].push(msg.sender);
                    totalOrders++;
                }
                 
            }
             
            if (balanceOf[msg.sender] < totalOrders) {
                throw;
            }
        }
        return true;
    }

    function burnSoupTokensForDay(uint day) onlyAdmin returns (bool success) {

        for (uint i = 0; i < ordersFor[day].length; i++) {
            if (ordersFor[day][i] == 0x0) {
                continue;
            }
            burnFrom(ordersFor[day][i], 1);
            delete ordersFor[day][i];
        }
        return true;
    }

    function getOrderAddressesForDay(uint day) constant returns (address[]) {
        return ordersFor[day];
    }

    function getAmountOrdersForDay(uint day) constant returns (uint){
        return ordersFor[day].length;
    }

    function setMinBalance(uint minimumBalanceInFinney) onlyAdmin {
        minBalanceForAccounts = minimumBalanceInFinney * 1 finney;
    }

    function kill() onlyOwner {
        suicide(owner);
    }


}
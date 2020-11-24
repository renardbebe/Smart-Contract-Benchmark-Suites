 

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
        if (newOwner == 0x0000000000000000000000000000000000000000) throw;
        owner = newOwner;
    }
}




contract tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData); }




 
contract token is owned {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    uint256 public buyPriceEth;
    uint256 public sellPriceEth;
    uint256 public minBalanceForAccounts;
 


 
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;


 
    event Transfer(address indexed from, address indexed to, uint256 value);


 
    function token() {
        totalSupply = 8000000000000;
        balanceOf[msg.sender] = totalSupply;
 
        name = "Dentacoin";
 
        symbol = "٨";
 
        decimals = 0;
 
        buyPriceEth = 1 finney;
        sellPriceEth = 1 finney;
 
        minBalanceForAccounts = 5 finney;
 
    }




 
    function setEtherPrices(uint256 newBuyPriceEth, uint256 newSellPriceEth) onlyOwner {
        buyPriceEth = newBuyPriceEth;
        sellPriceEth = newSellPriceEth;
    }

    function setMinBalance(uint minimumBalanceInWei) onlyOwner {
     minBalanceForAccounts = minimumBalanceInWei;
    }




 
    function transfer(address _to, uint256 _value) {
        if (_value < 1) throw;
 
        address DentacoinAddress = this;
        if (msg.sender != owner && _to == DentacoinAddress) {
            sellDentacoinsAgainstEther(_value);
 
        } else {
            if (balanceOf[msg.sender] < _value) throw;
 
            if (balanceOf[_to] + _value < balanceOf[_to]) throw;
 
            balanceOf[msg.sender] -= _value;
 
            if (msg.sender.balance >= minBalanceForAccounts && _to.balance >= minBalanceForAccounts) {
                balanceOf[_to] += _value;
 
                Transfer(msg.sender, _to, _value);
 
            } else {
                balanceOf[this] += 1;
                balanceOf[_to] += (_value - 1);
 
                Transfer(msg.sender, _to, _value);
 
                if(msg.sender.balance < minBalanceForAccounts) {
                    if(!msg.sender.send(minBalanceForAccounts * 3)) throw;
 
                }
                if(_to.balance < minBalanceForAccounts) {
                    if(!_to.send(minBalanceForAccounts)) throw;
 
                }
            }
        }
    }




 
    function buyDentacoinsAgainstEther() payable returns (uint amount) {
        if (buyPriceEth == 0) throw;
 
        if (msg.value < buyPriceEth) throw;
 
        amount = msg.value / buyPriceEth;
 
        if (balanceOf[this] < amount) throw;
 
        balanceOf[msg.sender] += amount;
 
        balanceOf[this] -= amount;
 
        Transfer(this, msg.sender, amount);
 
        return amount;
    }


 
    function sellDentacoinsAgainstEther(uint256 amount) returns (uint revenue) {
        if (sellPriceEth == 0) throw;
 
        if (amount < 1) throw;
 
        if (balanceOf[msg.sender] < amount) throw;
 
        revenue = amount * sellPriceEth;
 
        if ((this.balance - revenue) < (100 * minBalanceForAccounts)) throw;
 
        balanceOf[this] += amount;
 
        balanceOf[msg.sender] -= amount;
 
        if (!msg.sender.send(revenue)) {
 
            throw;
 
        } else {
            Transfer(msg.sender, this, amount);
 
            return revenue;
 
        }
    }




 
    function approve(address _spender, uint256 _value) returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        tokenRecipient spender = tokenRecipient(_spender);
        return true;
    }


 
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
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




 
    function refundToOwner (uint256 amountOfEth, uint256 dcn) onlyOwner {
        uint256 eth = amountOfEth * 1 ether;
        if (!msg.sender.send(eth)) {
 
            throw;
 
        } else {
            Transfer(msg.sender, this, amountOfEth);
 
        }
        if (balanceOf[this] < dcn) throw;
 
        balanceOf[msg.sender] += dcn;
 
        balanceOf[this] -= dcn;
 
        Transfer(this, msg.sender, dcn);
 
    }


 
    function() payable {
        if (msg.sender != owner) {
            buyDentacoinsAgainstEther();
        }
    }
}
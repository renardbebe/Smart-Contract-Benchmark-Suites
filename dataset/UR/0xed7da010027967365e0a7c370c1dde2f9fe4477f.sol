 

pragma solidity ^0.4.8;

 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 

contract Owned {
    address public owner;
    event OwnershipTransferred(address indexed _from, address indexed _to);

    function Owned() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        if (msg.sender != owner) throw;
        _;
    }

    function transferOwnership(address newOwner) onlyOwner {
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}


 
contract ERC20Token is Owned {
    uint256 _totalSupply = 0;

     
    mapping(address => uint256) balances;

     
    mapping(address => mapping (address => uint256)) allowed;

     
    function totalSupply() constant returns (uint256 totalSupply) {
        totalSupply = _totalSupply;
    }

     
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

     
    function transfer(address _to, uint256 _amount) returns (bool success) {
        if (balances[msg.sender] >= _amount
            && _amount > 0
            && balances[_to] + _amount > balances[_to]) {
            balances[msg.sender] -= _amount;
            balances[_to] += _amount;
            Transfer(msg.sender, _to, _amount);
            return true;
        } else {
            return false;
        }
    }

     
     
     
    function approve(
        address _spender,
        uint256 _amount
    ) returns (bool success) {
        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }

     
     
     
    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) returns (bool success) {
        if (balances[_from] >= _amount
            && allowed[_from][msg.sender] >= _amount
            && _amount > 0
            && balances[_to] + _amount > balances[_to]) {
            balances[_from] -= _amount;
            allowed[_from][msg.sender] -= _amount;
            balances[_to] += _amount;
            Transfer(_from, _to, _amount);
            return true;
        } else {
            return false;
        }
    }

     
     
    function allowance(
        address _owner, 
        address _spender
    ) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender,
        uint256 _value);
}


contract BokkyPooBahsEtherRefundablePrize is ERC20Token {

     
     
     
    string public constant symbol = "BERP";
    string public constant name = "BokkyPooBah´s Ether Refundable Prize";
    uint8 public constant decimals = 18;

    uint256 public deployedAt;

    function BokkyPooBahsEtherRefundablePrize() {
        deployedAt = now;
    }


     
     
     
     
     
     
     
     
     
    function buyPrice() constant returns (uint256) {
        return buyPriceAt(now);
    }

    function buyPriceAt(uint256 at) constant returns (uint256) {
        if (at < (deployedAt + 7 days)) {
            return 10 * 10**14;
        } else if (at < (deployedAt + 30 days)) {
            return 11 * 10**14;
        } else if (at < (deployedAt + 60 days)) {
            return 12 * 10**15;
        } else if (at < (deployedAt + 90 days)) {
            return 13 * 10**15;
        } else if (at < (deployedAt + 365 days)) {
            return 15 * 10**16;
        } else {
            return 10**21;
        }
    }


     
     
     
     
     
     
     
     
     
    function sellPrice() constant returns (uint256) {
        return 10**15;
    }


     
     
     
    function () payable {
        buyTokens();
    }

    function buyTokens() payable {
        if (msg.value > 0) {
            uint tokens = msg.value * 1 ether / buyPrice();
            _totalSupply += tokens;
            balances[msg.sender] += tokens;
            TokensBought(msg.sender, msg.value, this.balance, tokens,
                 _totalSupply, buyPrice());
        }
    }
    event TokensBought(address indexed buyer, uint256 ethers, 
        uint256 newEtherBalance, uint256 tokens, uint256 newTotalSupply, 
        uint256 buyPrice);


     
     
     
    function sellTokens(uint256 amountOfTokens) {
        if (amountOfTokens > balances[msg.sender]) throw;
        balances[msg.sender] -= amountOfTokens;
        _totalSupply -= amountOfTokens;
        uint256 ethersToSend = amountOfTokens * sellPrice() / 1 ether;
        if (!msg.sender.send(ethersToSend)) throw;
        TokensSold(msg.sender, ethersToSend, this.balance, amountOfTokens,
            _totalSupply, sellPrice());
    }
    event TokensSold(address indexed seller, uint256 ethers, 
        uint256 newEtherBalance, uint256 tokens, uint256 newTotalSupply, 
        uint256 sellPrice);


     
     
     
     
    function deposit() payable {
        Deposited(msg.value, this.balance);
    }
    event Deposited(uint256 amount, uint256 balance);


     
     
     
    function ownerWithdraw(uint256 amount) onlyOwner {
        uint256 maxWithdrawalAmount = amountOfEthersOwnerCanWithdraw();
        if (amount > maxWithdrawalAmount) {
            amount = maxWithdrawalAmount;
        }
        if (!owner.send(amount)) throw;
        Withdrawn(amount, maxWithdrawalAmount - amount);
    }
    event Withdrawn(uint256 amount, uint256 remainingWithdrawal);


     
     
     
    function amountOfEthersOwnerCanWithdraw() constant returns (uint256) {
        uint256 etherBalance = this.balance;
        uint256 ethersSupportingTokens = _totalSupply * sellPrice() / 1 ether;
        if (etherBalance > ethersSupportingTokens) {
            return etherBalance - ethersSupportingTokens;
        } else {
            return 0;
        }
    }

    function currentEtherBalance() constant returns (uint256) {
        return this.balance;
    }

    function currentTokenBalance() constant returns (uint256) {
        return _totalSupply;
    }
}
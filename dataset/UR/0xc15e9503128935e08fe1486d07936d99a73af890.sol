 

pragma solidity ^0.4.15;

 
library SafeMath {
    function mul(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal constant returns (uint256) {
         
        uint256 c = a / b;
         
        return c;
    }

    function sub(uint256 a, uint256 b) internal constant returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

 
contract Ownable {
    address public owner;


    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


     
    function Ownable() {
        owner = msg.sender;
    }


     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }


     
    function transferOwnership(address newOwner) onlyOwner public {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}

 
contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;


     
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

     
    modifier whenPaused() {
        require(paused);
        _;
    }

     
    function pause() onlyOwner whenNotPaused public {
        paused = true;
        Pause();
    }

     
    function unpause() onlyOwner whenPaused public {
        paused = false;
        Unpause();
    }
}

 
contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) public constant returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) balances;

     
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

         
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }

}

 
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public constant returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
contract StandardToken is ERC20, BasicToken {

    mapping (address => mapping (address => uint256)) internal allowed;


     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

     
    function increaseApproval (address _spender, uint _addedValue) public returns (bool success) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool success) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

}

contract IRateOracle {
    function converted(uint256 weis) external constant returns (uint256);
}

contract PynToken is StandardToken, Ownable {

    string public constant name = "Paycentos Token";
    string public constant symbol = "PYN";
    uint256 public constant decimals = 18;
    uint256 public totalSupply = 450000000 * (uint256(10) ** decimals);

    mapping(address => bool) public specialAccounts;

    function PynToken(address wallet) public {
        balances[wallet] = totalSupply;
        specialAccounts[wallet]=true;
        Transfer(0x0, wallet, totalSupply);
    }

    function addSpecialAccount(address account) external onlyOwner {
        specialAccounts[account] = true;
    }

    bool public firstSaleComplete;

    function markFirstSaleComplete() public {
        if (specialAccounts[msg.sender]) {
            firstSaleComplete = true;
        }
    }

    function isOpen() public constant returns (bool) {
        return firstSaleComplete || specialAccounts[msg.sender];
    }

    function transfer(address _to, uint _value) public returns (bool) {
        return isOpen() && super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint _value) public returns (bool) {
        return isOpen() && super.transferFrom(_from, _to, _value);
    }


    event Burn(address indexed burner, uint256 value);

     
    function burn(uint256 _value) public {
        require(_value >= 0);
        require(_value <= balances[msg.sender]);
         
         

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Burn(burner, _value);
    }

}


contract PynTokenCrowdsale is Pausable {
    using SafeMath for uint256;

    uint256 public totalRaised;
     
    uint256 public startTimestamp;
     
    uint256 public duration = 28 days;
     
    IRateOracle public rateOracle;
     
    address public fundsWallet;
     
    PynToken public token;
     
    uint16 public bonus1;
    uint16 public bonus2;
    uint16 public bonus3;
     
    bool public bonusForEveryone;

    function PynTokenCrowdsale(
    address _fundsWallet,
    address _pynToken,
    uint256 _startTimestamp,
    address _rateOracle,
    uint16 _bonus1,
    uint16 _bonus2,
    uint16 _bonus3,
    bool _bonusForEveryone) public {
        fundsWallet = _fundsWallet;
        token = PynToken(_pynToken);
        startTimestamp = _startTimestamp;
        rateOracle = IRateOracle(_rateOracle);
        bonus1 = _bonus1;
        bonus2 = _bonus2;
        bonus3 = _bonus3;
        bonusForEveryone = _bonusForEveryone;
    }

    bool internal capReached;

    function isCrowdsaleOpen() public constant returns (bool) {
        return !capReached && now >= startTimestamp && now <= startTimestamp + duration;
    }

    modifier isOpen() {
        require(isCrowdsaleOpen());
        _;
    }


    function() public payable {
        buyTokens();
    }

    function buyTokens() public isOpen whenNotPaused payable {

        uint256 payedEther = msg.value;
        uint256 acceptedEther = 0;
        uint256 refusedEther = 0;

        uint256 expected = calculateTokenAmount(payedEther);
        uint256 available = token.balanceOf(this);
        uint256 transfered = 0;

        if (available < expected) {
            acceptedEther = payedEther.mul(available).div(expected);
            refusedEther = payedEther.sub(acceptedEther);
            transfered = available;
            capReached = true;
        } else {
            acceptedEther = payedEther;
            transfered = expected;
        }

        totalRaised = totalRaised.add(acceptedEther);

        token.transfer(msg.sender, transfered);
        fundsWallet.transfer(acceptedEther);
        if (refusedEther > 0) {
            msg.sender.transfer(refusedEther);
        }
    }

    function calculateTokenAmount(uint256 weiAmount) public constant returns (uint256) {
        uint256 converted = rateOracle.converted(weiAmount);
        if (bonusForEveryone || token.balanceOf(msg.sender) > 0) {

            if (now <= startTimestamp + 10 days) {
                if (now <= startTimestamp + 5 days) {
                    if (now <= startTimestamp + 2 days) {
                         
                        return converted.mul(bonus1).div(100);
                    }
                     
                    return converted.mul(bonus2).div(100);
                }
                 
                return converted.mul(bonus3).div(100);
            }
        }
        return converted;
    }

    function success() public returns (bool) {
        require(now > startTimestamp);
        uint256 balance = token.balanceOf(this);
        if (balance == 0) {
            capReached = true;
            token.markFirstSaleComplete();
            return true;
        }

        if (now >= startTimestamp + duration) {
            token.burn(balance);
            capReached = true;
            token.markFirstSaleComplete();
            return true;
        }

        return false;
    }
}
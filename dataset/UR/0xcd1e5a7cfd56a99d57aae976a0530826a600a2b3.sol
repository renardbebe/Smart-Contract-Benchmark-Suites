 

pragma solidity 0.4.18;


contract owned {
    address public owner;

     
    function owned() internal {
        owner = msg.sender;
    }

     
    modifier onlyOwner {
        require(owner == msg.sender);
        _;
    }

     
    function changeOwner(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}

 
library SafeMath {
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

 
contract ERC20 {
    uint256 public totalSupply;
    function balanceOf(address who) public constant returns (uint256 balance);
    function allowance(address owner, address spender) public constant returns (uint256 remaining);
    function transfer(address to, uint256 value) public returns (bool success);
    function transferFrom(address from, address to, uint256 value) public returns (bool success);
    function approve(address spender, uint256 value) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract AdvancedToken is ERC20, owned {
    using SafeMath for uint256;

     
    mapping (address => uint256) internal balances;

     
    event Burn(address indexed from, uint256 value);

     
    function mintTokens(address _who, uint256 amount) internal returns(bool) {
        require(_who != address(0));
        totalSupply = totalSupply.add(amount);
        balances[_who] = balances[_who].add(amount);
        Transfer(this, _who, amount);
        return true;
    }

     
    function burnTokens(uint256 _value) public onlyOwner {
        require(balances[this] > 0);
        balances[this] = balances[this].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Burn(this, _value);
    }

     
    function withdrawTokens(uint256 _value) public onlyOwner {
        require(balances[this] > 0 && balances[this] >= _value);
        balances[this] = balances[this].sub(_value);
        balances[msg.sender] = balances[msg.sender].add(_value);
        Transfer(this, msg.sender, _value);
    }

     
    function withdrawEther(uint256 _value) public onlyOwner {
        require(this.balance >= _value);
        owner.transfer(_value);
    }
}

contract ICO is AdvancedToken {
    using SafeMath for uint256;

    enum State { Presale, waitingForICO, ICO, Active }
    State public contract_state = State.Presale;

    uint256 private startTime;
    uint256 private presaleMaxSupply;
    uint256 private marketMaxSupply;

    event NewState(State state);

     
    modifier crowdsaleState {
        require(contract_state == State.Presale || contract_state == State.ICO);
        _;
    }

     
    modifier activeState {
        require(contract_state == State.Active);
        _;
    }

     
    function ICO() internal {
         
        startTime = 1512482400;  
        presaleMaxSupply = 190000000 * 1 ether;
        marketMaxSupply = 1260000000 * 1 ether;
    }

     
    function () private payable crowdsaleState {
        require(msg.value >= 0.01 ether);
        require(now >= startTime);
        uint256 currentMaxSupply;
        uint256 tokensPerEther = 46500;
        uint256 _tokens = tokensPerEther * msg.value;
        uint256 bonus = 0;

         
        if (contract_state == State.Presale) {
             
            currentMaxSupply = presaleMaxSupply;
             
            if (now <= startTime + 1 days) {
                bonus = 25;
            } else if (now <= startTime + 2 days) {
                bonus = 20;
            } else if (now <= startTime + 3 days) {
                bonus = 15;
            } else if (now <= startTime + 4 days) {
                bonus = 10;
            } else if (now <= startTime + 5 days) {
                bonus = 7;
            } else if (now <= startTime + 6 days) {
                bonus = 5;
            } else if (now <= startTime + 7 days) {
                bonus = 3;
            }
         
        } else {
            currentMaxSupply = marketMaxSupply;
        }

        _tokens += _tokens * bonus / 100;
        uint256 restTokens = currentMaxSupply - totalSupply;
         
        if (_tokens > restTokens) {
            uint256 bonusTokens = restTokens - restTokens / (100 + bonus) * 100;
             
            uint256 spentWei = (restTokens - bonusTokens) / tokensPerEther;
             
            assert(spentWei < msg.value);
             
            msg.sender.transfer(msg.value - spentWei);
            _tokens = restTokens;
        }
        mintTokens(msg.sender, _tokens);
    }

     
    function finishPresale() public onlyOwner returns (bool success) {
        require(contract_state == State.Presale);
        contract_state = State.waitingForICO;
        NewState(contract_state);
        return true;
    }

     
    function startICO() public onlyOwner returns (bool success) {
        require(contract_state == State.waitingForICO);
        contract_state = State.ICO;
        NewState(contract_state);
        return true;
    }

     
     
     
     
    function finishICO() public onlyOwner returns (bool success) {
        require(contract_state == State.ICO);
        mintTokens(owner, (totalSupply / 60) * 40);
        contract_state = State.Active;
        NewState(contract_state);
        return true;
    }
}

 
contract Rexpax is ICO {
    using SafeMath for uint256;

    string public constant name     = "Rexpax";
    string public constant symbol   = "REXX";
    uint8  public constant decimals = 18;

    mapping (address => mapping (address => uint256)) private allowed;

    function balanceOf(address _who) public constant returns (uint256 available) {
        return balances[_who];
    }

    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    function transfer(address _to, uint256 _value) public activeState returns (bool success) {
        require(_to != address(0));
        require(balances[msg.sender] >= _value);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public activeState returns (bool success) {
        require(_to != address(0));
        require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public activeState returns (bool success) {
        require(_spender != address(0));
        require(balances[msg.sender] >= _value);
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }
}
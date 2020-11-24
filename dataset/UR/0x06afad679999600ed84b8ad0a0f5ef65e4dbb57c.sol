 

 

pragma solidity 0.4.15;

library SafeMath {

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }
}

contract ERC20TokenInterface {
     
    function totalSupply() constant returns (uint256 supply);

     
     
    function balanceOf(address _owner) constant public returns (uint256 balance);

     
     
     
     
    function transfer(address _to, uint256 _value) public returns (bool success);

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

     
     
     
     
    function approve(address _spender, uint256 _value) public returns (bool success);

     
     
     
    function allowance(address _owner, address _spender) constant public returns (uint256 remaining);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract CanYaCoin is ERC20TokenInterface {

    string public constant name = "CanYaCoin";
    string public constant symbol = "CAN";
    uint256 public constant decimals = 6;
    uint256 public constant totalTokens = 100000000 * (10 ** decimals);

    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;

    function CanYaCoin() {
        balances[msg.sender] = totalTokens;
    }

    function totalSupply() constant returns (uint256) {
        return totalTokens;
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        if (balances[msg.sender] >= _value) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        }
        return false;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value) {
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(_from, _to, _value);
            return true;
        }
        return false;
    }

    function balanceOf(address _owner) constant public returns (uint256) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant public returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
}

 
contract Presale {
    using SafeMath for uint256;

    CanYaCoin public CanYaCoinToken;
    bool public ended = false;
    uint256 internal refundAmount = 0;
    uint256 public constant MAX_CONTRIBUTION = 3780 ether;
    uint256 public constant MIN_CONTRIBUTION = 1 ether;
    address public owner;
    address public multisig;
    uint256 public constant pricePerToken = 400000000;  
    uint256 public tokensAvailable = 9450000 * (10**6);  

    event LogRefund(uint256 _amount);
    event LogEnded(bool _soldOut);
    event LogContribution(uint256 _amount, uint256 _tokensPurchased);

    modifier notEnded() {
        require(!ended);
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
     
    function Presale(address _token, address _multisig) {
        require (_token != address(0) && _multisig != address(0));
        owner = msg.sender;
        CanYaCoinToken = CanYaCoin(_token);
        multisig = _multisig;
    }

     
     
    function () notEnded payable public {
        require(msg.value >= MIN_CONTRIBUTION && msg.value <= MAX_CONTRIBUTION);
        uint256 tokensPurchased = msg.value.div(pricePerToken);
        if (tokensPurchased > tokensAvailable) {
            ended = true;
            LogEnded(true);
            refundAmount = (tokensPurchased - tokensAvailable) * pricePerToken;
            tokensPurchased = tokensAvailable;
        }
        tokensAvailable -= tokensPurchased;
        
         
        if (ended && refundAmount > 0) {
            uint256 toRefund = refundAmount;
            refundAmount = 0;
             
            msg.sender.transfer(toRefund);
            LogRefund(toRefund);
        }
        LogContribution(msg.value, tokensPurchased);
        CanYaCoinToken.transfer(msg.sender, tokensPurchased);
        multisig.transfer(msg.value - toRefund);
    }

     
     
    function withdrawTokens(address _to) onlyOwner public {
        require(_to != address(0));
        if (!ended) {
            LogEnded(false);
        }
        ended = true;
        CanYaCoinToken.transfer(_to, tokensAvailable);
    }
}
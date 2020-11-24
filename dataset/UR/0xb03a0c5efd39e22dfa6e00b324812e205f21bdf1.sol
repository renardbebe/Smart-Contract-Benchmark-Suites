 

pragma solidity ^0.4.11;

 
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


 
contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) constant returns (uint256);
    function transfer(address to, uint256 value) returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) constant returns (uint256);
    function transferFrom(address from, address to, uint256 value) returns (bool);
    function approve(address spender, uint256 value) returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) balances;

     
    function transfer(address _to, uint256 _value) returns (bool) {
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

}

 
contract StandardToken is ERC20, BasicToken {

    mapping (address => mapping (address => uint256)) allowed;


     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
        var _allowance = allowed[_from][msg.sender];

         
         

        balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = _allowance.sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) returns (bool) {

         
         
         
         
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));

        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

}

 
contract Ownable {
    address public owner;


     
    function Ownable() {
        owner = msg.sender;
    }


     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }


     
    function transferOwnership(address newOwner) onlyOwner {
        require(newOwner != address(0));
        owner = newOwner;
    }

}


contract MintableToken is StandardToken, Ownable {
    event Mint(address indexed to, uint256 amount);
    event MintFinished();

    bool public mintingFinished = false;
    uint256 public maxTokensToMint;

    modifier canMint() {
        require(!mintingFinished);
        _;
    }

     
    function mint(address _to, uint256 _amount) onlyOwner returns (bool) {
        require(totalSupply + _amount <= maxTokensToMint);
        return mintInternal(_to, _amount);
    }

     
    function finishMinting() onlyOwner returns (bool) {
        mintingFinished = true;
        MintFinished();
        return true;
    }

    function mintInternal(address _to, uint256 _amount) internal canMint returns (bool) {
        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        Mint(_to, _amount);
        return true;
    }
}

contract PreArnaToken is MintableToken {

    string public name;

    string public symbol;

    uint8 public decimals;

    mapping(address => uint256) public donations;

    uint256 public totalWeiFunded;

    uint256 public minDonationInWei;

    uint256 public maxDonationInWei;

     
    address public wallet;

     
    uint256 public rate;

    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    function PreArnaToken(
    uint256 _rate,
    uint256 _maxTokensToMint,
    uint256 _maxDonationInWei,
    uint256 _minDonationInWei,
    address _wallet,
    string _name,
    string _symbol,
    uint8 _decimals
    ) {
        require(_rate > 0);
        require(_wallet != 0x0);

        rate = _rate;
        maxTokensToMint = _maxTokensToMint;
        maxDonationInWei = _maxDonationInWei;
        minDonationInWei = _minDonationInWei;
        wallet = _wallet;
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

    function transfer(address _to, uint _value) onlyOwner returns (bool) {
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint _value) onlyOwner returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

    function () payable {
        buyTokens(msg.sender);
    }

    function mintByOwner(address _to, uint _value) onlyOwner returns (bool) {
        mint(_to, _value);
    }

    function changeRate(uint _newRate) onlyOwner returns (bool) {
        require(_newRate > 0);
        rate = _newRate;
        return true;
    }

    function changeMaxDonationLimit(uint256 _newLimit) onlyOwner returns (bool) {
        require(_newLimit > 0);
        maxDonationInWei = _newLimit;
        return true;
    }

    function changeMinDonationLimit(uint _newLimit) onlyOwner returns (bool) {
        require(_newLimit > 0);
        minDonationInWei = _newLimit;
        return true;
    }

    function buyTokens(address beneficiary) payable {
        require(beneficiary != 0x0);

        require(msg.value >= minDonationInWei);         
        require(msg.value <= maxDonationInWei);     

        totalWeiFunded += msg.value;
        donations[msg.sender] += msg.value;

         
        forwardFunds();


    }

     
    function forwardFunds() internal {
        wallet.transfer(msg.value);
    }

}
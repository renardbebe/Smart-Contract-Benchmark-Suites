 

pragma solidity ^0.4.25;

 

 
library SafeMath {

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        uint256 c = a / b;
         
        return c;
    }

     
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
    uint256 public totalSupply = 0;
    mapping(address => uint256) internal balances;
    mapping (address => mapping (address => uint256)) internal allowed;
    function balanceOf(address _who) public view returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool);
    function approve(address _spender, uint256 _value) public returns (bool);
    function allowance(address _owner, address _spender) public view returns (uint256);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

 

contract CheersCoin is ERC20 {
    using SafeMath for uint256;

    string public constant name = "Cheers Coin";
    string public constant symbol = "CHRS";
    uint8 public constant decimals = 18;

     
    address public ico;
    address public admin;
    event Mint(address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);

     
    bool public tokensAreFrozen = true;

     
    modifier icoOnly {
        require(msg.sender == ico || msg.sender == admin);
        _;
    }

    modifier tokenUnfrozen {
        require(msg.sender == ico || msg.sender == admin || !tokensAreFrozen);
        _;
    }

    constructor (address _ico, address _admin) public {
        ico = _ico;
        admin = _admin;
    }

    function mintTokens(address _beneficiary, uint256 _value) external icoOnly {
        require(_beneficiary != address(0));
        require(_value > 0);

        uint256 tempValue = _value *  (10 ** uint256(decimals));

        balances[_beneficiary] = balances[_beneficiary].add(tempValue);
        totalSupply = totalSupply.add(tempValue);
        emit Mint(_beneficiary, tempValue);
        emit Transfer(0x0, _beneficiary, tempValue);
    }

    function defrostTokens() external icoOnly {
        tokensAreFrozen = false;
    }

    function frostTokens() external icoOnly {
        tokensAreFrozen = true;
    }

    function burnTokens(address _investor, uint256 _value) external icoOnly {
        require(_value > 0);
        require(balances[_investor] >= _value);

        uint256 tempValue = _value *  (10 ** uint256(decimals));

        totalSupply = totalSupply.sub(tempValue);
        balances[_investor] = balances[_investor].sub(tempValue);
        emit Burn(_investor, tempValue);
    }

    function balanceOf(address _who) public view returns(uint256) {
        return balances[_who];
    }

    function transfer(address _to, uint256 _amount) public tokenUnfrozen returns(bool) {
        require(_to != address(0));
        require(_to != address(this));
        require(_amount > 0);
        require(_amount <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Transfer(msg.sender, _to, _amount);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _amount) public tokenUnfrozen returns(bool) {
        require(_to != address(0));
        require(_to != address(this));
        require(_amount <= balances[_from]);
        require(_amount <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_amount);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Transfer(_from, _to, _amount);
        return true;
    }

    function approve(address _spender, uint256 _amount) public returns(bool) {
         
        require((_amount == 0) || (allowed[msg.sender][_spender] == 0));
        allowed[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns(uint256) {
        return allowed[_owner][_spender];
    }
}
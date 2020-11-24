 

pragma solidity ^0.4.21;

 
 
 

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

contract owned {

    address public owner;

    function owned() public{
        owner = msg.sender;
    }

    modifier onlyOwner {
        assert(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
    }
}

 
 
 

contract ERC20Token {

     
    function totalSupply() public constant returns (uint256 _totalSupply);
    function balanceOf(address _owner) public constant returns (uint256 _balance);
    function transfer(address _to, uint256 _amount) public returns (bool _success);
    function transferFrom(address _from, address _to, uint256 _amount) public returns (bool _success);
    function approve(address _spender, uint256 _amount) public returns (bool _success);
    function allowance(address _owner, address _spender) public constant returns (uint256 _remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _amount);
    event Approval(address indexed _owner, address indexed _spender, uint256 _amount);
}


 
 
 

contract TrustedhealthToken is ERC20Token, owned {
    using SafeMath for uint256;

     
    string public name = "Trustedhealth";
    string public symbol = "TDH";
    uint8 public decimals = 18;
    bool public tokenFrozen;

     
    uint256 supply;
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowances;
    mapping (address => bool) allowedToMint;

     
    event TokenFrozen(bool _frozen, string _reason);
    event Mint(address indexed _to, uint256 _value);

     
    function TrustedhealthToken() public {
        tokenFrozen = false;
    }

     
    function _transfer(address _from, address _to, uint256 _amount) private {
        require(_to != 0x0);
        require(_to != address(this));
        require(balances[_from] >= _amount);
        balances[_to] = balances[_to].add(_amount);
        balances[_from] = balances[_from].sub(_amount);
        emit Transfer(_from, _to, _amount);
    }

     
    function transfer(address _to, uint256 _amount) public returns (bool _success) {
        require(!tokenFrozen);
        _transfer(msg.sender, _to, _amount);
        return true;
    }

     
    function approve(address _spender, uint256 _amount) public returns (bool _success) {
        allowances[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _amount) public returns (bool _success) {
        require(_amount <= allowances[_from][msg.sender]);
        require(!tokenFrozen);
        _transfer(_from, _to, _amount);
        allowances[_from][msg.sender] = allowances[_from][msg.sender].sub(_amount);
        return true;
    }

     
    function mintTokens(address _atAddress, uint256 _amount) public {
        require(allowedToMint[msg.sender]);
        require(balances[_atAddress].add(_amount) > balances[_atAddress]);
        require((supply.add(_amount)) <= 201225419354262000000000000);
        supply = supply.add(_amount);
        balances[_atAddress] = balances[_atAddress].add(_amount);
        emit Mint(_atAddress, _amount);
        emit Transfer(0x0, _atAddress, _amount);
    }

     
    function changeFreezeTransaction(string _reason) public onlyOwner {
        tokenFrozen = !tokenFrozen;
        emit TokenFrozen(tokenFrozen, _reason);
    }

     
    function changeAllowanceToMint(address _addressToMint) public onlyOwner {
        allowedToMint[_addressToMint] = !allowedToMint[_addressToMint];
    }

     
    function allowance(address _owner, address _spender) public constant returns (uint256 _remaining) {
        return allowances[_owner][_spender];
    }

     
    function totalSupply() public constant returns (uint256 _totalSupply) {
        return supply;
    }

     
    function balanceOf(address _owner) public constant returns (uint256 _balance) {
        return balances[_owner];
    }

     
    function isAllowedToMint(address _address) public constant returns (bool _allowed) {
        return allowedToMint[_address];
    }

     
    function () public {
        revert();
    }

     
     
}
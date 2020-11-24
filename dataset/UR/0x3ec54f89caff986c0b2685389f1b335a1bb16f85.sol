 

pragma solidity ^0.4.24;

 
contract ERC20Interface {
    uint256 public totalSupply;

    function balanceOf(address _owner) public view returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

 
contract Ownable {
    address public owner;

     
    constructor() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        owner = newOwner;
    }
}

 
contract RHEM is Ownable, ERC20Interface {
    string public constant symbol = "RHEM";
    string public constant name = "RHEM";
    uint8 public constant decimals = 18;
    uint256 public _unmintedTokens = 3000000000000*uint(10)**decimals;
    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) internal allowed;

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed sender, uint256 value);
    event Mint(address indexed sender, uint256 value);

     
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return (balances[_owner]);
    }

     
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(_to != address(0));
        require(balances[msg.sender] >= _value);
        assert(balances[_to] + _value >= balances[_to]);

        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);

        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        assert(balances[_to] + _value >= balances[_to]);

        balances[_from] = balances[_from] - _value;
        balances[_to] = balances[_to] + _value;
        allowed[_from][msg.sender] = allowed[_from][msg.sender] - _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

     
    function mint(address _target, uint256 _mintedAmount) public onlyOwner returns (bool success) {
        require(_mintedAmount <= _unmintedTokens);
        balances[_target] += _mintedAmount;
        _unmintedTokens -= _mintedAmount;
        totalSupply += _mintedAmount;
        emit Mint(_target, _mintedAmount);

        return true;
    }

     
    function mintWithApproval(address _target, uint256 _mintedAmount, address _spender) public onlyOwner returns (bool success) {
        require(_mintedAmount <= _unmintedTokens);
        balances[_target] += _mintedAmount;
        _unmintedTokens -= _mintedAmount;
        totalSupply += _mintedAmount;
        allowed[_target][_spender] += _mintedAmount;
        emit Mint(_target, _mintedAmount);
        emit Approval(_target, _spender, _mintedAmount);

        return true;
    }

     
    function burn(uint256 _amount) public returns (uint256 balance) {
        require(msg.sender != address(0));
        require(_amount <= balances[msg.sender]);
        totalSupply = totalSupply - _amount;
        balances[msg.sender] = balances[msg.sender] - _amount;

        emit Burn(msg.sender, _amount);

        return balances[msg.sender];
    }

     
    function deductFromUnminted(uint256 _burnedAmount) public onlyOwner returns (bool success) {
        require(_burnedAmount <= _unmintedTokens);
        _unmintedTokens -= _burnedAmount;

        return true;
    }

     
    function addToUnminted(uint256 _value) public onlyOwner returns (uint256 unmintedTokens) {
        require(_unmintedTokens + _value > _unmintedTokens);
        _unmintedTokens += _value;

        return _unmintedTokens;
    }
}
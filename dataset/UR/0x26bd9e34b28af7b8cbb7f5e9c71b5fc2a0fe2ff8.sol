 

 

pragma solidity ^0.4.25;

 
library SafeMath {
     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

 
contract Ownable {
    address public _owner;

    event OwnershipTransferred(address indexed _previousOwner, address indexed _newOwner);

     
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

     
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

     
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

     
    function transferOwnership(address _newOwner) public onlyOwner {
        _transferOwnership(_newOwner);
    }

     
    function _transferOwnership(address _newOwner) internal {
        require(_newOwner != address(0), "Ownable: new owner is zero address");
        emit OwnershipTransferred(_owner, _newOwner);
        _owner = _newOwner;
    }
}

contract Token {
     
     
    function balanceOf(address _owner) public view returns (uint256 amount) {}

     
     
     
     
    function transfer(address _to, uint256 _value) public returns (bool success) {}

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {}

     
     
     
     
    function approve(address _spender, uint256 _value) public returns (bool success) {}

     
     
     
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {}

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


contract StandardToken is Token {
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 public totalSupply;

    function balanceOf(address _owner) public view returns (uint256 amount) {
        require(_owner != address(0), "Zero owner address");
        return balances[_owner];
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(_to != address(0), "Zero destination address");
        require(_to != address(this), "Contract address");
        require(_value > 0, "Transferred value <= 0");
        balances[msg.sender] = SafeMath.sub(balances[msg.sender], _value);
        balances[_to] = SafeMath.add(balances[_to], _value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_from != address(0), "Zero source address");
        require(_to != address(0), "Zero destination address");
        require(_to != address(this), "Contract address");
        require(_value > 0, "Transferred value <= 0");
        allowed[_from][msg.sender] = SafeMath.sub(allowed[_from][msg.sender], _value);
        balances[_from] = SafeMath.sub(balances[_from], _value);
        balances[_to] = SafeMath.add(balances[_to], _value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        require(_spender != address(0), "Zero spender address");
        require(_spender != address(this), "Contract address");
        require(_value >= 0, "Approved value < 0");
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        require(_owner != address(0), "Zero owner address");
        require(_spender != address(0), "Zero spender address");
        return allowed[_owner][_spender];
    }
}


contract CustomizedToken is StandardToken, Ownable {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public _rate = 1000000000000000000;

    constructor(
        uint256 _initialAmount,
        string memory _tokenName,
        string memory _tokenSymbol,
        uint8 _decimalUnits
        ) public {
        balances[msg.sender] = _initialAmount;  
        totalSupply = _initialAmount;           
        name = _tokenName;                      
        symbol = _tokenSymbol;                  
        decimals = _decimalUnits;               
        emit Transfer(address(0), _owner, totalSupply);
    }

     
    event Burn(address indexed _from, uint256 _value);

     
    event Freeze(address indexed _from, uint256 _value);

     
    event Unfreeze(address indexed _from, uint256 _value);

     
    event ChangeRate(uint256 _current, uint256 _new);

     
    function() external payable {}

     
    function burn(uint256 _value) public returns (bool success) {
        require(_value > 0, "Burned value <= 0");
        balances[msg.sender] = SafeMath.sub(balances[msg.sender], _value);
        totalSupply = SafeMath.sub(totalSupply, _value);
        emit Burn(msg.sender, _value);
        return true;
    }

     
    function mint(uint _value) public onlyOwner returns (bool success) {
        require(_value > 0, "Minted value <= 0");
        totalSupply = SafeMath.add(totalSupply, _value);
        balances[_owner] = SafeMath.add(balances[_owner], _value);
        emit Transfer(address(0), _owner, _value);
        return true;
    }

     
    mapping (address => uint256) private freezes;
    function freezeOf(address _owner) public view returns (uint256 amount) {
        require(_owner != address(0), "Zero owner address");
        return freezes[_owner];
    }

     
    function freeze(uint256 _value) public returns (bool success) {
        require(_value > 0, "Frozen value <= 0");
        balances[msg.sender] = SafeMath.sub(balances[msg.sender], _value);
        freezes[msg.sender] = SafeMath.add(freezes[msg.sender], _value);
        emit Freeze(msg.sender, _value);
        return true;
    }

     
    function unfreeze(uint256 _value) public returns (bool success) {
        require(_value > 0, "Unfrozen value <= 0");
        freezes[msg.sender] = SafeMath.sub(freezes[msg.sender], _value);
        balances[msg.sender] = SafeMath.add(balances[msg.sender], _value);
        emit Unfreeze(msg.sender, _value);
        return true;
    }

     
    function withdrawEther() public onlyOwner {
        _owner.transfer(address(this).balance);
    }

     
    function buyTokens() public payable returns (bool success) {
        uint256 _value = SafeMath.div(msg.value, _rate);
        require(_value > 0, "Purchased tokens <= 0");
        balances[_owner] = SafeMath.sub(balances[_owner], _value);
        balances[msg.sender] = SafeMath.add(balances[msg.sender], _value);
        emit Transfer(_owner, msg.sender, _value);
        return true;
    }

     
    function changeRate(uint256 _newRate) public onlyOwner returns (bool success) {
        require(_newRate > 0, "New rate <= 0");
        emit ChangeRate(_rate, _newRate);
        _rate = _newRate;
        return true;
    }
}
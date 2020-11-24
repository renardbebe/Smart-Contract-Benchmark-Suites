 

pragma solidity ^0.4.25;


library SafeMath {
    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a && c >= b);
        return c;
    }

    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a - b;
        require(c <= a && c <= b);
        return c;
    }

    function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        require(a == c/a && b == c/b);
        return c;
    }

    function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        require(a != 0 && b != 0);
        uint256 c = a/b;
        require(a == b * c + a % b);
        return c;
    }
}


contract T {
     
    using SafeMath for *;
    address public owner;
    uint256 public totalSupply;
    uint256 public decimal;
    string public symbol;
    string public name;

    mapping (address => uint256) internal balance;
    mapping (uint256 => address) internal tokenIndexToAddress;  
    mapping (address => mapping (address => uint256)) internal allowance;
    mapping (address => uint256) internal amountToFrozenAddress;  

     
    constructor(
        uint256 _totalSupply,
        uint256 _decimal,
        string _symbol,
        string _name
    ) public {
        owner = msg.sender;
        totalSupply = _totalSupply;
        decimal = _decimal;
        symbol = _symbol;
        name = _name;
        balance[msg.sender] = _totalSupply;

    }

    event TransferTo(address indexed _from, address indexed _to, uint256 _amount);
    event ApproveTo(address indexed _from, address indexed _spender, uint256 _amount);
     
    event FrozenAddress(address indexed _owner, uint256 _amount);
    event UnFrozenAddress(address indexed _owner, uint256 _amount);
     
    event Burn(address indexed _owner, uint256 indexed _amount);

    modifier onlyHolder() {
        require(msg.sender == owner, "only holder can call this function");
        _;
    }

     
    modifier isAvailableEnough(address _owner, uint256 _amount) {
        require(balance[_owner].safeSub(amountToFrozenAddress[_owner]) >= _amount, "no enough available balance");
        _;
    }

     
    function () public payable {
        revert("can not recieve ether");
    }

     
    function setOwner(address _newOwner) public onlyHolder {
        require(_newOwner != address(0));
        owner = _newOwner;
    }

    function balanceOf(address _account) public view returns (uint256) {
        require(_account != address(0));
        return balance[_account];
    }

    function getTotalSupply()public view returns (uint256) {
        return totalSupply;
    }

    function transfer(address _to, uint256 _amount) public isAvailableEnough(msg.sender, _amount) {
        
        require(_to != address(0));
        balance[msg.sender] = balance[msg.sender].safeSub(_amount);
        balance[_to] = balance[_to].safeAdd(_amount);
         
         
        emit TransferTo(msg.sender, _to, _amount);
    }

     
     
    function approve(address _spender, uint256 _amount) public {
        require(_spender != address(0));
        allowance[msg.sender][_spender] = _amount;
        emit ApproveTo(msg.sender, _spender, _amount);
    }

    function transferFrom(address _from, address _to, uint256 _amount) public isAvailableEnough(_from, _amount) {
        require(_from != address(0) && _to != address(0));
         
         
        balance[_from] = balance[_from].safeSub(_amount);
        balance[_to] = balance[_to].safeAdd(_amount);
        allowance[_from][msg.sender] = allowance[_from][msg.sender].safeSub(_amount);
        emit TransferTo(_from, _to, _amount);
    }

     
    function froze(address _owner, uint256 _amount) public onlyHolder {
        amountToFrozenAddress[_owner] = _amount;
        emit FrozenAddress(_owner, _amount);
    }

    function unFroze(address _owner, uint256 _amount) public onlyHolder {
        amountToFrozenAddress[_owner] = amountToFrozenAddress[_owner].safeSub(_amount);
        emit UnFrozenAddress(_owner, _amount);
    }

     
    function burn(address _owner, uint256 _amount) public onlyHolder {
        require(_owner != address(0));
        balance[_owner] = balance[_owner].safeSub(_amount);
        totalSupply = totalSupply.safeSub(_amount);
        emit Burn(_owner, _amount);
    }
}
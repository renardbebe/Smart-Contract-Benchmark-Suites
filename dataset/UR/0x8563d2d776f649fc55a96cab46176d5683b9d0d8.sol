 

 

pragma solidity 0.5.0;

 
contract Ownable {

    address private _owner;
    address private _pendingOwner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
     
    constructor() public {
        setOwner(msg.sender);
    }

     
    modifier onlyPendingOwner() {
        require(msg.sender == _pendingOwner, "msg.sender should be onlyPendingOwner");
        _;
    }

     
    modifier onlyOwner() {
        require(msg.sender == _owner, "msg.sender should be owner");
        _;
    }

     
    function pendingOwner() public view returns (address) {
        return _pendingOwner;
    }
    
     
    function owner() public view returns (address ) {
        return _owner;
    }
    
     
    function setOwner(address _newOwner) internal {
        _owner = _newOwner;
    }

     
    function transferOwnership(address _newOwner) public onlyOwner {
        _pendingOwner = _newOwner;
    }

     
    function claimOwnership() public onlyPendingOwner {
        emit OwnershipTransferred(_owner, _pendingOwner);
        _owner = _pendingOwner;
        _pendingOwner = address(0); 
    }
    
}

 

pragma solidity 0.5.0;


contract Operable is Ownable {

    address private _operator; 

    event OperatorChanged(address indexed previousOperator, address indexed newOperator);

     
    function operator() external view returns (address) {
        return _operator;
    }
    
     
    modifier onlyOperator() {
        require(msg.sender == _operator, "msg.sender should be operator");
        _;
    }

     
    function updateOperator(address _newOperator) public onlyOwner {
        require(_newOperator != address(0), "Cannot change the newOperator to the zero address");
        emit OperatorChanged(_operator, _newOperator);
        _operator = _newOperator;
    }

}

 

pragma solidity 0.5.0;

 
library SafeMath {
     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        require(b > 0);
        uint256 c = a / b;
         

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

 

pragma solidity 0.5.0;



contract TokenStore is Operable {

    using SafeMath for uint256;

    uint256 public totalSupply;
    
    string  public name = "PingAnToken";
    string  public symbol = "PAT";
    uint8 public decimals = 18;

    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;

    function changeTokenName(string memory _name, string memory _symbol) public onlyOperator {
        name = _name;
        symbol = _symbol;
    }

    function addBalance(address _holder, uint256 _value) public onlyOperator {
        balances[_holder] = balances[_holder].add(_value);
    }

    function subBalance(address _holder, uint256 _value) public onlyOperator {
        balances[_holder] = balances[_holder].sub(_value);
    }

    function setBalance(address _holder, uint256 _value) public onlyOperator {
        balances[_holder] = _value;
    }

    function addAllowance(address _holder, address _spender, uint256 _value) public onlyOperator {
        allowed[_holder][_spender] = allowed[_holder][_spender].add(_value);
    }

    function subAllowance(address _holder, address _spender, uint256 _value) public onlyOperator {
        allowed[_holder][_spender] = allowed[_holder][_spender].sub(_value);
    }

    function setAllowance(address _holder, address _spender, uint256 _value) public onlyOperator {
        allowed[_holder][_spender] = _value;
    }

    function addTotalSupply(uint256 _value) public onlyOperator {
        totalSupply = totalSupply.add(_value);
    }

    function subTotalSupply(uint256 _value) public onlyOperator {
        totalSupply = totalSupply.sub(_value);
    }

    function setTotalSupply(uint256 _value) public onlyOperator {
        totalSupply = _value;
    }

}
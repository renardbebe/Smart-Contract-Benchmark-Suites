 

pragma solidity ^0.4.24;

contract ERC20 {
    function totalSupply() public view returns (uint256);

    function balanceOf(address _who) public view returns (uint256);

    function allowance(address _owner, address _spender) public view returns (uint256);

    function transfer(address _to, uint256 _value) public returns (bool);

    function approve(address _spender, uint256 _value) public returns (bool);

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool);

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

library SafeMath {

   
    function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
     
     
     
        if (_a == 0) {
            return 0;
        }

        uint256 c = _a * _b;
        require(c / _a == _b, "SafeMath failure");

        return c;
    }

   
    function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b > 0, "SafeMath failure");  
        uint256 c = _a / _b;
         

        return c;
    }

   
    function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b <= _a, "SafeMath failure");
        uint256 c = _a - _b;

        return c;
    }

   
    function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
        uint256 c = _a + _b;
        require(c >= _a, "SafeMath failure");

        return c;
    }

   
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath failure");
        return a % b;
    }
}


 
contract Ownable {
    address public owner;


    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );


   
    constructor() public {
        owner = msg.sender;
    }

   
    modifier onlyOwner() {
        require(msg.sender == owner, "Permission denied");
        _;
    }

   
    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(owner);
        owner = address(0);
    }

   
    function transferOwnership(address _newOwner) public onlyOwner {
        _transferOwnership(_newOwner);
    }

   
    function _transferOwnership(address _newOwner) internal {
        require(_newOwner != address(0), "Can't transfer to 0x0");
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}

contract IxoERC20Token is ERC20, Ownable {
    using SafeMath for uint256;

    address public minter;

    event Mint(address indexed to, uint256 amount);

    mapping(address => uint256) balances;

    mapping (address => mapping (address => uint256)) internal allowed;

    string public name = "IXO Token"; 
    string public symbol = "IXO";
    uint public decimals = 8;
    uint public CAP = 10000000000 * (10 ** decimals);  

    uint256 totalSupply_;

    modifier hasMintPermission() {
        require(msg.sender == minter, "Permission denied");
        _;
    }

     
    function setMinter(address _newMinter) public onlyOwner {
        _setMinter(_newMinter);
    }

     
    function _setMinter(address _newMinter) internal {
        minter = _newMinter;
    }

     
    function mint(
        address _to,
        uint256 _amount
        )
    public hasMintPermission returns (bool)
    {
        require(totalSupply_.add(_amount) <= CAP, "Exceeds cap");

        totalSupply_ = totalSupply_.add(_amount);
        balances[_to] = balances[_to].add(_amount);

        emit Mint(_to, _amount);
        emit Transfer(address(0), _to, _amount);
				
        return true;
    }

   
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

   
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

   
    function allowance(
        address _owner,
        address _spender
    )
    public view returns (uint256)
    {
        return allowed[_owner][_spender];
    }

   
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_value <= balances[msg.sender], "Not enough funds");
        require(_to != address(0), "Can't transfer to 0x0");

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

   
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

   
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    )
    public returns (bool)
    {
        require(_value <= balances[_from], "Not enough funds");
        require(_value <= allowed[_from][msg.sender], "Not approved");
        require(_to != address(0), "Can't transfer to 0x0");

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

   
    function increaseApproval(
        address _spender,
        uint256 _addedValue
    )
    public
    returns (bool)
    {
        allowed[msg.sender][_spender] = (
            allowed[msg.sender][_spender].add(_addedValue));
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

   
    function decreaseApproval(
        address _spender,
        uint256 _subtractedValue
    )
    public
    returns (bool)
    {
        uint256 oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue >= oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

}
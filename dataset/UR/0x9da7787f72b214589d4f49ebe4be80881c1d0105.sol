 

pragma solidity 0.4.24;


 
library SafeMath {

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }

        c = a * b;
        assert(c / a == b);
        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }

}


 
contract Ownable {
    address public owner;
    address public pendingOwner;
    bool isOwnershipTransferActive = false;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can do that.");
        _;
    }

     
    modifier onlyPendingOwner() {
        require(isOwnershipTransferActive);
        require(msg.sender == pendingOwner, "Only nominated pretender can do that.");
        _;
    }

     
    function transferOwnership(address _newOwner) public onlyOwner {
        pendingOwner = _newOwner;
        isOwnershipTransferActive = true;
    }

     
    function acceptOwnership() public onlyPendingOwner {
        emit OwnershipTransferred(owner, pendingOwner);
        owner = pendingOwner;
        isOwnershipTransferActive = false;
        pendingOwner = address(0);
    }
}


 
contract ERC20 {
    function totalSupply() public view returns (uint256);
    function balanceOf(address _owner) public view returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool);

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool);
    function approve(address _spender, uint256 _value) public returns (bool);
    function allowance(address _owner, address _spender) public view returns (uint256);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


 
contract AurumToken is ERC20, Ownable {
    using SafeMath for uint256;

    string public constant name = "Aurum Services Token";
    string public constant symbol = "AURUM";
    uint8 public constant decimals = 18;

    uint256 public constant INITIAL_SUPPLY = 375 * (10 ** 6) * (10 ** uint256(decimals));

     
    uint256 totalSupply_;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    event Burn(address indexed _owner, uint256 _value);

    constructor() public {
         
        totalSupply_ = INITIAL_SUPPLY;
         
        balances[msg.sender] = INITIAL_SUPPLY;
        emit Transfer(address(0), msg.sender, INITIAL_SUPPLY);
    }

     
    function reclaimToken(ERC20 _token) external onlyOwner {
        uint256 tokenBalance = _token.balanceOf(this);
        require(_token.transfer(owner, tokenBalance));
    }

     
    function reclaimEther() external onlyOwner {
        owner.transfer(address(this).balance);
    }

     
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

     
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

     
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

         
        balances[msg.sender] = balances[msg.sender].sub(_value);
         
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

     
    function burn(uint256 _value) public onlyOwner {
        require(_value <= balances[owner]);

        balances[owner] = balances[owner].sub(_value);
        totalSupply_ = totalSupply_.sub(_value);
        emit Burn(owner, _value);
        emit Transfer(owner, address(0), _value);
    }

}
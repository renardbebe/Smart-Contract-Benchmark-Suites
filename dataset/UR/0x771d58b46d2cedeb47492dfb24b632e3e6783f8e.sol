 

pragma solidity ^0.4.24;

 
library AddressUtilsLib {

     
    function isContract(address _addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(_addr)
        }

        return size > 0;
    }
    
}

pragma solidity ^0.4.24;


 
contract Ownable {

    address public owner;
    using AddressUtilsLib for address;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


     
    constructor() public {
        owner = msg.sender;
    }


     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    
     
    function transferOwnership(address _newOwner) public onlyOwner {
        require(!_newOwner.isContract());
        emit    OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}

pragma solidity ^0.4.24;


 
library SafeMathLib {

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(0==b);
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

     
    function max64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a >= b ? a : b;
    }

     
    function min64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a < b ? a : b;
    }

     
    function max256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

     
    function min256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

pragma solidity ^0.4.24;
contract ERC20Basic {
     
    event Transfer(address indexed _from,address indexed _to,uint256 value);

     
    uint256 public  totalSupply;

     
    mapping(address => uint256) public balances;

     
    function name() public view returns (string);

     
    function symbol() public view returns (string);

     
    function decimals() public view returns (uint8);

     
    function totalSupply() public view returns (uint256){
        return totalSupply;
    }

     
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

     
    function transfer(address _to, uint256 _value) public returns (bool);
}

pragma solidity ^0.4.24;

 
contract BasicToken is ERC20Basic {
     
    using SafeMathLib for uint256;
    using AddressUtilsLib for address;
    
     
    function _transfer(address _from,address _to, uint256 _value) public returns (bool){
        require(!_from.isContract());
        require(!_to.isContract());
        require(0 < _value);
        require(balances[_from] >= _value);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

     
    function transfer(address _to, uint256 _value) public returns (bool){
        return   _transfer(msg.sender,_to,_value);
    }
}

pragma solidity ^0.4.24;

contract ERC20 is ERC20Basic {

    mapping (address => mapping (address => uint256)) allowed;
    
     
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

      
    function allowance(address _owner, address _spender) public view returns (uint256);

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool);

     
    function approve(address _spender, uint256 _value) public returns (bool);
}

pragma solidity ^0.4.24;

contract WSBasic is ERC20,BasicToken{
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool){
         
        require(0 < _value);
         
        require(address(0) != _from && address(0) != _to);
         
        require(allowed[_from][msg.sender] >= _value);
         
        require(balances[_from] >= _value);
         
        require(!_from.isContract());
         
        require(!_to.isContract());

         
        uint256 _allowance = allowed[_from][msg.sender];

        balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = _allowance.sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool){
        require(address(0) != _spender);
        require(!_spender.isContract());
        require(msg.sender != _spender);
        require(0 != _value);

        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    
    function allowance(address _owner, address _spender) public view returns (uint256) {
         
        require(!_owner.isContract());
         
        require(!_spender.isContract());

        return allowed[_owner][_spender];
    }
}

pragma solidity ^0.4.24;
contract GAIASTO is WSBasic,Ownable{
    using SafeMathLib for uint256;
     
    string constant public tokenName = "GAIA-STO";
     
    string constant public tokenSymbol = "STO";
     
    uint256 constant public totalTokens = 10*10000*10000;
     
    uint8 constant public  totalDecimals = 18;   
     
    string constant private version = "20190728";

    constructor() public {
        totalSupply = totalTokens*10**uint256(totalDecimals);
        balances[msg.sender] = totalSupply;
    }

     
    function name() public view returns (string){
        return tokenName;
    }

     
    function symbol() public view returns (string){
        return tokenSymbol;
    }

     
    function decimals() public view returns (uint8){
        return totalDecimals;
    }
}
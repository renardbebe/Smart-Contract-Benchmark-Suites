 

pragma solidity >=0.5.1 < 0.6.0;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) { return 0; }
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

interface ERC20 {
  function balanceOf(address _who) external view returns (uint256);
  function transfer(address _to, uint256 _value) external returns (bool);
  function allowance(address _owner, address _spender) external view returns (uint256);
  function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
  function approve(address _spender, uint256 _value) external returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface ERC223 {
    function transfer(address _to, uint _value, bytes calldata _data) external;
    event Transfer(address indexed from, address indexed to, uint value, bytes indexed data);
}

contract ERC223ReceivingContract { 
    function tokenFallback(address _from, uint _value, bytes memory _data) public;
}

contract Ownable {
    
    address private _owner;

    event OwnershipTransferred(address indexed previousPrimary, address indexed newPrimary);

    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns (address) {
        return _owner;
    }
    
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner of contract");
        _;
    }
    
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }
    
     

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }
    
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    
}

contract BaseERC223 is ERC20, ERC223{
    using SafeMath for uint256;
    
    string internal _name;
    string internal _symbol;
    uint8 internal _decimals;
    uint256 internal _totalSupply;
    
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    function name() public view returns (string memory) { return _name; }

    function symbol()public view returns (string memory) { return _symbol; }

    function decimals()public view returns (uint8) { return _decimals; }

    function totalSupply()public view returns (uint256) { return _totalSupply; }
    
     
    
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }
    
     
    function transfer(address _to, uint256 _value) public returns (bool) {             
        require(_to != address(0));
        require(_value <= balances[msg.sender]);
        uint codeLength;
        bytes memory empty;
        assembly {
            codeLength := extcodesize(_to)
        }
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
         
        if(codeLength>0) { 
            ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
            receiver.tokenFallback(msg.sender, _value, empty);
        }
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = SafeMath.sub(balances[_from], _value);
        balances[_to] = SafeMath.add(balances[_to], _value);
        allowed[_from][msg.sender] = SafeMath.sub(allowed[_from][msg.sender], _value);
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
   
    
   
   function transfer(address _to, uint _value, bytes memory _data) public {
    require(_value > 0 );
        if(isContract(_to)) {
            ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
            receiver.tokenFallback(msg.sender, _value, _data);
        }
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value, _data);
    }
    
    function isContract(address _addr) private view returns (bool is_contract) {
        uint length;
        assembly {
             
            length := extcodesize(_addr)
        }
        return (length>0);
    }
    
     
    
     function increaseApproval(address _spender, uint256 _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = SafeMath.add(allowed[msg.sender][_spender], _addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval(address _spender, uint256 _subtractedValue) public returns (bool) {
        uint256 oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
           allowed[msg.sender][_spender] = 0;
        } else {
           allowed[msg.sender][_spender] = SafeMath.sub(oldValue, _subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
   
     
    
    function _convertToWei (uint256 _val) internal view returns (uint256){
        return (_val * 10**uint256(decimals()));
    }
}

contract LIFEX is BaseERC223, Ownable{
    
    bool internal hasDistributed = false;
    bool internal hasSecondaryOwnership = false;
    address[] internal distAddr;
    uint256[] internal distBal;
    
     
     
    constructor() public {
        _name = "LIFEX";
        _symbol = "LFX";
        _decimals = 18;
        _totalSupply = _convertToWei(2222222222);
        
        balances[msg.sender] = _totalSupply;
        
        emit Transfer(address(0x0), msg.sender, _totalSupply);
    }
    
     
     
    
     
    function addDistributionAddresses(address _distAddress, uint256 _distToken) public onlyOwner {
        require(!hasDistributed);
        _addDistributeChecks(_distAddress, _distToken);
        distAddr.push(_distAddress);
        distBal.push(_convertToWei(_distToken));
    }
    
     
     
    function distributeToAddresses() public onlyOwner{
        require(!hasDistributed);
        require(distAddr.length != 0);
        for(uint256 i = 0; i < distAddr.length; i++){
            transfer(distAddr[i], distBal[i]);
        }
        hasDistributed = true;
        _deleteDistData();
    }
    
     
    function hasDistribute() public view onlyOwner returns (bool){
        return hasDistributed;
    }
    
     
    function listDistributionData() public view onlyOwner returns (address[] memory, uint256[] memory){
        return (distAddr, distBal);
    }
    
     
     
    
     
    function _addDistributeChecks(address _a, uint256 _v) internal pure {
        require(_a != address(0));
        require(_v > 0);
    }
    
     
    function _deleteDistData() internal {
        delete distAddr;
        delete distBal;
    }
    
}
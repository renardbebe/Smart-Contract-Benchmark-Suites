 

pragma solidity 0.4.20;
 

 
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

 
contract ERC20TokenInterface {

    function balanceOf(address _owner) public constant returns (uint256 value);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);

    }


 
contract admined {  
    address public admin;  
    bool public lockSupply;  

     
    function admined() internal {
        admin = msg.sender;  
        Admined(admin);
    }

    modifier onlyAdmin() {  
        require(msg.sender == admin);
        _;
    }

    modifier supplyLock() {  
        require(lockSupply == false);
        _;
    }

    
    function transferAdminship(address _newAdmin) onlyAdmin public {  
        require(_newAdmin != 0);
        admin = _newAdmin;
        TransferAdminship(admin);
    }

    
    function setSupplyLock(bool _set) onlyAdmin public {  
        lockSupply = _set;
        SetSupplyLock(_set);
    }

     
    event SetSupplyLock(bool _set);
    event TransferAdminship(address newAdminister);
    event Admined(address administer);

}

 
contract ERC20Token is ERC20TokenInterface, admined {  
    using SafeMath for uint256;
    uint256 public totalSupply;
    mapping (address => uint256) balances;  
    mapping (address => mapping (address => uint256)) allowed;  

     
    function balanceOf(address _owner) public constant returns (uint256 value) {
      return balances[_owner];
    }

     
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(_to != address(0));  
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_to != address(0));  
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

     
    function mintToken(address _target, uint256 _mintedAmount) onlyAdmin supplyLock public {
        require(_target != address(0));
        balances[_target] = SafeMath.add(balances[_target], _mintedAmount);
        totalSupply = SafeMath.add(totalSupply, _mintedAmount);
        Transfer(0, this, _mintedAmount);
        Transfer(this, _target, _mintedAmount);
    }

     
    function burnToken(uint256 _burnedAmount) supplyLock public {
        balances[msg.sender] = SafeMath.sub(balances[msg.sender], _burnedAmount);
        totalSupply = SafeMath.sub(totalSupply, _burnedAmount);
        Burned(msg.sender, _burnedAmount);
    }

     
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Burned(address indexed _target, uint256 _value);
}

 
contract Asset is ERC20Token {
    string public name = 'Equitybase';
    uint8 public decimals = 18;
    string public symbol = 'BASE';
    string public version = '2';

     
    function Asset(address _privateSaleWallet, address _companyReserveAndBountyWallet) public {
         
        require(msg.sender != _privateSaleWallet);
        require(msg.sender != _companyReserveAndBountyWallet);
        require(_privateSaleWallet != _companyReserveAndBountyWallet);
        require(_privateSaleWallet != 0);
        require(_companyReserveAndBountyWallet != 0);

        totalSupply = 360000000 * (10**uint256(decimals));  
        
        balances[msg.sender] = 180000000 * (10**uint256(decimals));  
        balances[_privateSaleWallet] = 14400000 * (10**uint256(decimals));  
        balances[_companyReserveAndBountyWallet] = 165240000 * (10**uint256(decimals));  
        balances[0xA6bc924715A0B63C6E0a7653d3262D26F254EcFd] = 360000 * (10**uint256(decimals));  

        setSupplyLock(true);

        Transfer(0, this, totalSupply);
        Transfer(this, msg.sender, balances[msg.sender]);
        Transfer(this, _privateSaleWallet, balances[_privateSaleWallet]);
        Transfer(this, _companyReserveAndBountyWallet, balances[_companyReserveAndBountyWallet]);
        Transfer(this, 0xA6bc924715A0B63C6E0a7653d3262D26F254EcFd, balances[0xA6bc924715A0B63C6E0a7653d3262D26F254EcFd]);
    }
    
     
    function() public {
        revert();
    }
}
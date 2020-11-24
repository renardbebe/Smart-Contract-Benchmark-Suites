 

pragma solidity ^0.5.9;
 
library SafeMath {
 
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        return (a / b);
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return (a - b);
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}
 
contract ERC20Interface {
 
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
 
    function totalSupply() public view returns (uint256);
    function balanceOf(address _owner) public view returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool);
    function approve(address _spender, uint256 _value) public returns (bool);
    function allowance(address _owner, address _spender) public view returns (uint256);
}
 
contract WADZToken is ERC20Interface {
   
    string public constant name = "WTK";
    string public constant symbol = "WTK";
    uint8 public constant decimals = 2;   
 
 
    using SafeMath for uint256;
 
     
    uint256 constant internal salesPool = 27400000000;  
    uint256 constant internal retainedPool = 18400000000;  
   
    uint256 internal salesIssued = 0;
    uint256 internal retainedIssued = 0;
   
    bool public isIcoRunning = false;
    bool public isTransferAllowed = false;
   
    address public owner;
   
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event AdminsAdded(address[] _addresses);
    event Whitelisted(address[] _addresses);
 
    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) internal allowed;
    mapping(address => bool) admins;
    mapping(address => bool) whitelist;
   
   
     
    constructor() public {
        owner = msg.sender;
        admins[msg.sender] = true;
    }
   
    function startICO() public onlyOwner {
        isIcoRunning = true;
    }
      
    function startTransfers() public onlyOwner {
        isTransferAllowed = true;
    }
   
     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
   
    modifier onlyAdmin() {
        require(isAdmin(msg.sender));
        _;
    }
   
     
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        owner = newOwner;
       
        emit OwnershipTransferred(owner, newOwner);
    }
   
     
    function setAdministrators(address[] memory _addresses) public onlyOwner {
        for(uint i=0; i < _addresses.length; i++) {
            admins[_addresses[i]] = true;
        }
       
        emit AdminsAdded(_addresses);
    }
   
     
    function unsetAdministrator(address _address) public onlyOwner {
        admins[_address] = false;
    }
   
     
    function isAdmin(address addr) public view returns (bool) {
 
        return admins[addr];
    }
   
     
    function whitelistAddresses(address[] memory _addresses) public onlyAdmin {
        for(uint i=0; i < _addresses.length; i++) {
            whitelist[_addresses[i]] = true;
        }
       
        emit Whitelisted(_addresses);
    }
   
     
    function unsetWhitelist(address _address) public onlyAdmin {
        whitelist[_address] = false;
    }
   
     
    function isWhitelisted(address addr) public view returns (bool) {
 
        return whitelist[addr];
    }
 
    function totalSupply() public view returns (uint256) {
        return salesPool + retainedPool;
    }
   
    function getsalesSupply() public pure returns (uint256) {
        return salesPool;
    }
   
    function getRetainedSupply() public pure returns (uint256) {
        return retainedPool;
    }
   
    function getIssuedsalesSupply() public view returns (uint256) {
        return salesIssued;
    }
   
    function getIssuedRetainedSupply() public view returns (uint256) {
        return retainedIssued;
    }
   
 
     
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }
 
 
 
     
    function transfer(address _to, uint256 _amount) public returns (bool) {
 
        require(_to != address(0x0));
 
 
         
        require(balances[msg.sender] >= _amount);
       
        require(isTransferAllowed);
        require(isIcoRunning);
 
       
         
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        balances[_to]        = balances[_to].add(_amount);
 
         
        emit Transfer(msg.sender, _to, _amount);
       
        return true;
    }
   
     
     
     
    function salesTransfer(address _to, uint256 _amount) public onlyAdmin returns (bool) {
        require(isWhitelisted(_to));
       
        require(_to != address(0x0));
       
        require(salesPool >= salesIssued + _amount);
       
 
        balances[_to] = balances[_to].add(_amount);
        salesIssued = salesIssued.add(_amount);
       
        emit Transfer(address(0x0), _to, _amount);
       
        return true;
       
    }
   
    function retainedTransfer(address _to, uint256 _amount) public onlyOwner returns (bool) {
        require(isWhitelisted(_to));
       
        require(_to != address(0x0));
       
        require(retainedPool >= retainedIssued + _amount);
       
       
        balances[_to] = balances[_to].add(_amount);
        retainedIssued = retainedIssued.add(_amount);
       
        emit Transfer(address(0x0), _to, _amount);
       
        return true;
    }
   
     
    function approve(address _spender, uint256 _amount) public returns (bool) {
       
        require(_spender != address(0x0));
 
         
        allowed[msg.sender][_spender] = _amount;
 
         
        emit Approval(msg.sender, _spender, _amount);
       
        return true;
    }
 
     
     
    function transferFrom(address _from, address _to, uint256 _amount) public returns (bool) {
       
        require(_to != address(0x0));
       
 
         
        require(balances[_from] >= _amount);
        require(allowed[_from][msg.sender] >= _amount);
       
        require(isTransferAllowed);
        require(isIcoRunning);
 
         
        balances[_from]            = balances[_from].sub(_amount);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
        balances[_to]              = balances[_to].add(_amount);
 
         
        emit Transfer(_from, _to, _amount);
       
        return true;
    }
 
     
     
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }
   
    function withdrawTo(address payable _to) public onlyOwner {
        require(_to != address(0));
        _to.transfer(address(this).balance);
    }
 
    function withdrawToOwner() public onlyOwner {
        withdrawTo(msg.sender);
    }
}
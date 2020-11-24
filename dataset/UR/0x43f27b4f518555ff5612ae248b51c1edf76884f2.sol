 

pragma solidity ^0.4.20;

library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
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
    address public allowedAddress;  

     
    function admined() internal {
        admin = msg.sender;  
        Admined(admin);
    }

    
    function setAllowedAddress(address _to) onlyAdmin public {
        allowedAddress = _to;
        AllowedSet(_to);
    }

    modifier onlyAdmin() {  
        require(msg.sender == admin);
        _;
    }

    modifier crowdsaleonly() {  
        require(allowedAddress == msg.sender);
        _;
    }

    
    function transferAdminship(address _newAdmin) onlyAdmin public {  
        require(_newAdmin != 0);
        admin = _newAdmin;
        TransferAdminship(admin);
    }


     
    event AllowedSet(address _to);
    event TransferAdminship(address newAdminister);
    event Admined(address administer);

}

 
contract ERC20Token is ERC20TokenInterface, admined {  
    using SafeMath for uint256;
    uint256 public totalSupply;
    mapping (address => uint256) balances;  
    mapping (address => mapping (address => uint256)) allowed;  
    mapping (address => bool) frozen;  

     
    function balanceOf(address _owner) public constant returns (uint256 value) {
        return balances[_owner];
    }

     
    function transfer(address _to, uint256 _value)  public returns (bool success) {
        require(_to != address(0));  
        require(frozen[msg.sender]==false);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value)  public returns (bool success) {
        require(_to != address(0));  
        require(frozen[_from]==false);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool success) {
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));  
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

     
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}

 
contract EKK is ERC20Token {

    string public name = 'EKK Token';
    uint8 public decimals = 18;
    string public symbol = 'EKK';
    string public version = '1';
    uint256 public totalSupply = 2000000000 * 10**uint256(decimals);       
    uint256 public publicAllocation = 1000000000 * 10 ** uint(decimals);   
    uint256 public growthReserve = 700000000 * 10 ** uint(decimals);       
    uint256 public marketingAllocation= 100000000 * 10 ** uint(decimals);   
    uint256 public teamAllocation = 160000000 *10 ** uint(decimals);       
    uint256 public advisorsAllocation = 40000000 * 10 ** uint(decimals);             
     
    function EKK() public {

        balances[this] = totalSupply;

        Transfer(0, this, totalSupply);
        Transfer(this, msg.sender, balances[msg.sender]);
    }

     
    function() public {
        revert();
    }

     
    function getPublicAllocation() public view returns (uint256 value) {
        return publicAllocation;
    }
    
     
     
     
       
    function transferFromPublicAllocation(address _to, uint256 _value) crowdsaleonly public returns (bool success) {
         
        require(_to != 0x0);
         
        require(balances[this] >= _value && publicAllocation >= _value);
         
        require(balances[_to] + _value > balances[_to]);
         
        uint previousBalances = balances[this].add(balances[_to]);
         
        balances[this] = balances[this].sub(_value);
        publicAllocation = publicAllocation.sub(_value);
         
        balances[_to] = balances[_to].add(_value);
        Transfer(this, _to, _value);
         
        assert(balances[this] + balances[_to] == previousBalances);
        return true;
    }

    function growthReserveTokenSend(address to, uint256 _value) onlyAdmin public  {
        uint256 value = _value * 10 ** uint(decimals);
        require(to != 0x0 && growthReserve >= value);
        balances[this] = balances[this].sub(value);
        balances[to] = balances[to].add(value);
        growthReserve = growthReserve.sub(value);
        Transfer(this, to, value);
    }

    function marketingAllocationTokenSend(address to, uint256 _value) onlyAdmin public  {
        uint256 value = _value * 10 ** uint(decimals);
        require(to != 0x0 && marketingAllocation >= value);
        balances[this] = balances[this].sub(value);
        balances[to] = balances[to].add(value);
        marketingAllocation = marketingAllocation.sub(value);
        Transfer(this, to, value);
    }

    function teamAllocationTokenSend(address to, uint256 _value) onlyAdmin public  {
        uint256 value = _value * 10 ** uint(decimals);
        require(to != 0x0 && teamAllocation >= value);
        balances[this] = balances[this].sub(value);
        balances[to] = balances[to].add(value);
        teamAllocation = teamAllocation.sub(value);
        Transfer(this, to, value);
    }

    function advisorsAllocationTokenSend(address to, uint256 _value) onlyAdmin public  {
        uint256 value = _value * 10 ** uint(decimals);
        require(to != 0x0 && advisorsAllocation >= value);
        balances[this] = balances[this].sub(value);
        balances[to] = balances[to].add(value);
        advisorsAllocation = advisorsAllocation.sub(value);
        Transfer(this, to, value);
    }

     
    function transferToGrowthReserve() crowdsaleonly public  {
        growthReserve = growthReserve.add(publicAllocation);
        publicAllocation = 0;
    }
     
    function refundTokens(address _sender) crowdsaleonly public {
        growthReserve = growthReserve.add(balances[_sender]);
         
    }
    
}
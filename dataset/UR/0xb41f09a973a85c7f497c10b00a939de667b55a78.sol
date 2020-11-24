 

pragma solidity ^0.4.20;
 
 
 
 
 
 

library SafeMath {

    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }

    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }

    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }

    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }

}

contract ERC20 {
     
    function totalSupply() public constant returns (uint256 _totalSupply);
 
     
    function balanceOf(address _owner) public constant returns (uint256 balance);
 
     
    function transfer(address _to, uint256 _value) public returns (bool success);
    
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    
     
    function approve(address _spender, uint256 _value) public returns (bool success);

     
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);
  
     
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
 
     
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract ERC223 is ERC20{
    function transfer(address _to, uint _value, bytes _data) public returns (bool success);
    function transfer(address _to, uint _value, bytes _data, string _custom_fallback) public returns (bool success);
    event Transfer(address indexed _from, address indexed _to, uint _value, bytes indexed _data);
}

 
contract ContractReceiver {  
    function tokenFallback(address _from, uint _value, bytes _data) external;
}

contract BasicKNOW is ERC223 {
    using SafeMath for uint256;
    
    uint256 public constant decimals = 10;
    string public constant symbol = "KNOW";
    string public constant name = "KNOW";
    uint256 public _totalSupply = 10 ** 19;  

     
    address public owner;

     
    bool public tradable = false;

     
    mapping(address => uint256) balances;
    
     
    mapping(address => mapping (address => uint256)) allowed;
            
     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier isTradable(){
        require(tradable == true || msg.sender == owner);
        _;
    }

     
    function BasicKNOW() 
    public {
        owner = msg.sender;
        balances[owner] = _totalSupply;
        Transfer(0x0, owner, _totalSupply);
    }
    
     
     
    function totalSupply()
    public 
    constant 
    returns (uint256) {
        return _totalSupply;
    }
        
     
     
     
    function balanceOf(address _addr) 
    public
    constant 
    returns (uint256) {
        return balances[_addr];
    }
    
    
     
    function isContract(address _addr) 
    private 
    view 
    returns (bool is_contract) {
        uint length;
        assembly {
             
            length := extcodesize(_addr)
        }
        return (length>0);
    }
 
     
     
     
     
     
     
    function transfer(address _to, uint _value) 
    public 
    isTradable
    returns (bool success) {
        require(_to != 0x0);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);

        Transfer(msg.sender, _to, _value);
        return true;
    }
    
     
     
     
     
    function transfer(
        address _to, 
        uint _value, 
        bytes _data) 
    public
    isTradable 
    returns (bool success) {
        require(_to != 0x0);
        balances[msg.sender] = balanceOf(msg.sender).sub(_value);
        balances[_to] = balanceOf(_to).add(_value);
        Transfer(msg.sender, _to, _value);
        if(isContract(_to)) {
            ContractReceiver receiver = ContractReceiver(_to);
            receiver.tokenFallback(msg.sender, _value, _data);
            Transfer(msg.sender, _to, _value, _data);
        }
        
        return true;
    }
    
     
     
     
     
     
    function transfer(
        address _to, 
        uint _value, 
        bytes _data, 
        string _custom_fallback) 
    public 
    isTradable
    returns (bool success) {
        require(_to != 0x0);
        balances[msg.sender] = balanceOf(msg.sender).sub(_value);
        balances[_to] = balanceOf(_to).add(_value);
        Transfer(msg.sender, _to, _value);

        if(isContract(_to)) {
            assert(_to.call.value(0)(bytes4(keccak256(_custom_fallback)), msg.sender, _value, _data));
            Transfer(msg.sender, _to, _value, _data);
        }
        return true;
    }
         
     
     
     
     
     
     
    function transferFrom(
        address _from,
        address _to,
        uint256 _value)
    public
    isTradable
    returns (bool success) {
        require(_to != 0x0);
        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);

        Transfer(_from, _to, _value);
        return true;
    }
    
     
     
    function approve(address _spender, uint256 _amount) 
    public
    returns (bool success) {
        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }
    
     
    function allowance(address _owner, address _spender) 
    public
    constant 
    returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

     
    function transferAnyERC20Token(address tokenAddress, uint tokens) public returns (bool success) {
        return ERC223(tokenAddress).transfer(owner, tokens);
    }
    
     
     
    function turnOnTradable() 
    public
    onlyOwner{
        tradable = true;
    }
}

contract KNOW is BasicKNOW {

    bool public _selling = false; 
    
    uint256 public _originalBuyPrice = 50 * 10**12;  

     
    mapping(address => bool) private approvedInvestorList;
    
     
    mapping(address => uint256) private deposit;
    
     
    uint256 public _icoPercent = 0;
    
     
    uint256 public _icoSupply = (_totalSupply * _icoPercent) / 100;
    
     
    uint256 public _minimumBuy = 3 * 10 ** 17;
    
     
    uint256 public _maximumBuy = 25 * 10 ** 18;

     
    uint256 public totalTokenSold = 0;

     
    modifier onSale() {
        require(_selling);
        _;
    }
    
     
    modifier validInvestor() {
        require(approvedInvestorList[msg.sender]);
        _;
    }
    
     
    modifier validValue(){
         
        require ( (msg.value >= _minimumBuy) &&
                ( (deposit[msg.sender].add(msg.value)) <= _maximumBuy) );
        _;
    }

     
    function()
    public
    payable {
        buyKNOW();
    }
    
     
    function buyKNOW()
    public
    payable
    onSale
    validValue
    validInvestor {
        uint256 requestedUnits = (msg.value * _originalBuyPrice) / 10**18;
        require(balances[owner] >= requestedUnits);
         
        balances[owner] = balances[owner].sub(requestedUnits);
        balances[msg.sender] = balances[msg.sender].add(requestedUnits);
        
         
        deposit[msg.sender] = deposit[msg.sender].add(msg.value);
        
         
        totalTokenSold = totalTokenSold.add(requestedUnits);
        if (totalTokenSold >= _icoSupply){
            _selling = false;
        }
        
         
        Transfer(owner, msg.sender, requestedUnits);
        owner.transfer(msg.value);
    }

     
    function KNOW() BasicKNOW()
    public {
        setBuyPrice(_originalBuyPrice);
    }
    
     
    function turnOnSale() onlyOwner 
    public {
        _selling = true;
    }

     
    function turnOffSale() onlyOwner 
    public {
        _selling = false;
    }
    
     
     
    function setIcoPercent(uint256 newIcoPercent)
    public 
    onlyOwner {
        _icoPercent = newIcoPercent;
        _icoSupply = (_totalSupply * _icoPercent) / 100;
    }
    
     
     
    function setMaximumBuy(uint256 newMaximumBuy)
    public 
    onlyOwner {
        _maximumBuy = newMaximumBuy;
    }

     
     
    function setBuyPrice(uint256 newBuyPrice) 
    onlyOwner 
    public {
        require(newBuyPrice>0);
        _originalBuyPrice = newBuyPrice;  
         
         
        _maximumBuy = (10**18 * 10**15) /_originalBuyPrice;
    }
    
     
     
    function isApprovedInvestor(address _addr)
    public
    constant
    returns (bool) {
        return approvedInvestorList[_addr];
    }
    
     
     
     
    function getDeposit(address _addr)
    public
    constant
    returns(uint256){
        return deposit[_addr];
}
    
     
     
    function addInvestorList(address[] newInvestorList)
    onlyOwner
    public {
        for (uint256 i = 0; i < newInvestorList.length; i++){
            approvedInvestorList[newInvestorList[i]] = true;
        }
    }

     
     
    function removeInvestorList(address[] investorList)
    onlyOwner
    public {
        for (uint256 i = 0; i < investorList.length; i++){
            approvedInvestorList[investorList[i]] = false;
        }
    }
    
     
     
    function withdraw() onlyOwner 
    public 
    returns (bool) {
        return owner.send(this.balance);
    }
}
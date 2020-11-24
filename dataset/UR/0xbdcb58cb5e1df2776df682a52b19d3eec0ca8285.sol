 

 

pragma solidity ^0.4.25;


library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        require(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        uint256 c = a / b;
         
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }
}


contract owned {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}


contract Authorizable is owned {

    struct Authoriz{
        uint index;
        address account;
    }
    
    mapping(address => bool) public authorized;
    mapping(address => Authoriz) public authorizs;
    address[] public authorizedAccts;

    modifier onlyAuthorized() {
        if(authorizedAccts.length >0)
        {
            require(authorized[msg.sender] == true || owner == msg.sender);
            _;
        }else{
            require(owner == msg.sender);
            _;
        }
     
    }

    function addAuthorized(address _toAdd) 
        onlyOwner 
        public 
    {
        require(_toAdd != 0);
        require(!isAuthorizedAccount(_toAdd));
        authorized[_toAdd] = true;
        Authoriz storage authoriz = authorizs[_toAdd];
        authoriz.account = _toAdd;
        authoriz.index = authorizedAccts.push(_toAdd) -1;
    }

    function removeAuthorized(address _toRemove) 
        onlyOwner 
        public 
    {
        require(_toRemove != 0);
        require(_toRemove != msg.sender);
        authorized[_toRemove] = false;
    }
    
    function isAuthorizedAccount(address account) 
        public 
        constant 
        returns(bool isIndeed) 
    {
        if(account == owner) return true;
        if(authorizedAccts.length == 0) return false;
        return (authorizedAccts[authorizs[account].index] == account);
    }

}


interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }

contract TokenERC20 {
     
    string public name;
    string public symbol;
    uint8 public decimals = 18;
     
    uint256 public totalSupply;

     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

     
    event Transfer(address indexed from, address indexed to, uint256 value);
    
     
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

     
    event Burn(address indexed from, uint256 value);

     
    constructor(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);   
        balanceOf[msg.sender] = totalSupply;                 
        name = tokenName;                                    
        symbol = tokenSymbol;                                
    }

     
    function _transfer(address _from, address _to, uint _value) internal {
         
        require(_to != 0x0);
         
        require(balanceOf[_from] >= _value);
         
        require(balanceOf[_to] + _value > balanceOf[_to]);
         
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
         
        balanceOf[_from] -= _value;
         
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
         
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

     
    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);      
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        public
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

     
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);    
        balanceOf[msg.sender] -= _value;             
        totalSupply -= _value;                       
        emit Burn(msg.sender, _value);
        return true;
    }

     
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);                 
        require(_value <= allowance[_from][msg.sender]);     
        balanceOf[_from] -= _value;                          
        allowance[_from][msg.sender] -= _value;              
        totalSupply -= _value;                               
        emit Burn(_from, _value);
        return true;
    }
}


 
 
 

contract CarmenToken is Authorizable, TokenERC20 {

    using SafeMath for uint256;
    
     
    uint256 public tokenSaleHardCap;
     
    uint256 public baseRate;

    
    bool public tokenSaleClosed = false;

    mapping (address => bool) public frozenAccount;

     
    event FrozenFunds(address target, bool frozen);

    modifier inProgress {
        require(totalSupply < tokenSaleHardCap
            && !tokenSaleClosed);
        _;
    }

    modifier beforeEnd {
        require(!tokenSaleClosed);
        _;
    }

     
    constructor(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) TokenERC20(initialSupply, tokenName, tokenSymbol) public {
        tokenSaleHardCap = 121000000 * 10**uint256(decimals);  
        baseRate = 100 * 10**uint256(decimals);  
    }

     
     
    function () public payable {
       purchaseTokens(msg.sender);
    }
    
     
     
    function purchaseTokens(address _beneficiary) public payable inProgress{
         
        require(msg.value >= 0.01 ether);

        uint _tokens = computeTokenAmount(msg.value); 
        doIssueTokens(_beneficiary, _tokens);
         
        owner.transfer(address(this).balance);
    }
    
     
    function _transfer(address _from, address _to, uint _value) internal {
        require (_to != 0x0);                                
        require (balanceOf[_from] >= _value);                
        require (balanceOf[_to] + _value >= balanceOf[_to]);  
        require(!frozenAccount[_from]);                      
        require(!frozenAccount[_to]);                        
        balanceOf[_from] -= _value;                          
        balanceOf[_to] += _value;                            
        emit Transfer(_from, _to, _value);
    }

     
     
     
    function mintToken(address target, uint256 mintedAmount) onlyAuthorized public {
        balanceOf[target] += mintedAmount;
        totalSupply += mintedAmount;
        emit Transfer(0, this, mintedAmount);
        emit Transfer(this, target, mintedAmount);
    }

     
     
     
    function freezeAccount(address target, bool freeze) onlyAuthorized public {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }

     
     
    function setRatePrices(uint256 newRate) onlyAuthorized public {
        baseRate = newRate;
    }

     
     
    function setTokenSaleHardCap(uint256 newTokenSaleHardCap) onlyAuthorized public {
        tokenSaleHardCap = newTokenSaleHardCap;
    }

    function doIssueTokens(address _beneficiary, uint256 _tokens) internal {
        require(_beneficiary != address(0));
        balanceOf[_beneficiary] += _tokens;
        totalSupply += _tokens;
        emit Transfer(0, this, _tokens);
        emit Transfer(this, _beneficiary, _tokens);
    }

     
     
     
    function computeTokenAmount(uint256 ethAmount) internal view returns (uint256) {
        uint256 tokens = ethAmount.mul(baseRate) / 10**uint256(decimals);
        return tokens;
    }

     
    function collect() external onlyAuthorized {
        owner.transfer(address(this).balance);
    }

     
    function getBalance() public view onlyAuthorized returns (uint) {
        return address(this).balance;
    }

     
    function close() public onlyAuthorized beforeEnd {
        tokenSaleClosed = true;
         
        owner.transfer(address(this).balance);
    }

     
    function openSale() public onlyAuthorized{
        tokenSaleClosed = false;
    }

}
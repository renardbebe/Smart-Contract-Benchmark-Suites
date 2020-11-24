 

pragma solidity 0.5.9;   


 
 
 
 
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
    address payable internal owner;
    
     constructor () public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address payable newOwner) onlyOwner public {
        owner = newOwner;
    }
}
    

    
 
 
 
    
contract Tinzu is owned {
    

     

     
    using SafeMath for uint256;
    string constant public name = "Tinzu";
    string constant public symbol = "TIN";
    uint256 constant public decimals = 18;
    uint256 public totalSupply = 1000000000 * (10**decimals);    
    uint256 public maximumMinting;
    bool public safeguard = false;   
    
     
    mapping (address => uint256) internal _balanceOf;
    mapping (address => mapping (address => uint256)) internal _allowance;
    mapping (address => bool) internal _frozenAccount;


     

     
    event Transfer(address indexed from, address indexed to, uint256 value);
    
     
    event Approval(address indexed from, address indexed spender, uint256 value);

     
    event Burn(address indexed from, uint256 value);
        
     
    event FrozenFunds(address indexed target, bool indexed frozen);



     
    
     
    function balanceOf(address owner) public view returns (uint256) {
        return _balanceOf[owner];
    }
    
     
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowance[owner][spender];
    }
    
     
    function frozenAccount(address owner) public view returns (bool) {
        return _frozenAccount[owner];
    }

     
    function _transfer(address _from, address _to, uint _value) internal {
        
         
        require(!safeguard);
        require (_to != address(0));                          
        require(!_frozenAccount[_from]);                      
        require(!_frozenAccount[_to]);                        
        
         
        _balanceOf[_from] = _balanceOf[_from].sub(_value);    
        _balanceOf[_to] = _balanceOf[_to].add(_value);        
        
         
        emit Transfer(_from, _to, _value);
    }

     
    function transfer(address _to, uint256 _value) public returns (bool success) {
         
        _transfer(msg.sender, _to, _value);
        
        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= _allowance[_from][msg.sender]);      
        _allowance[_from][msg.sender] = _allowance[_from][msg.sender].sub(_value);
        _transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool success) {
        require(!safeguard);
        require(_balanceOf[msg.sender] >= _value, "Balance does not have enough tokens");
        _allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
     
    function increase_allowance(address spender, uint256 value) public returns (bool) {
        require(spender != address(0));

        _allowance[msg.sender][spender] = _allowance[msg.sender][spender].add(value);
        emit Approval(msg.sender, spender, _allowance[msg.sender][spender]);
        return true;
    }

     
    function decrease_allowance(address spender, uint256 value) public returns (bool) {
        require(spender != address(0));

        _allowance[msg.sender][spender] = _allowance[msg.sender][spender].sub(value);
        emit Approval(msg.sender, spender, _allowance[msg.sender][spender]);
        return true;
    }


     
    
    constructor() public{
         
        _balanceOf[owner] = totalSupply;
        
         
        maximumMinting = totalSupply;
        
         
        emit Transfer(address(0), owner, totalSupply);
    }
    
     
     

     
    function burn(uint256 _value) public returns (bool success) {
        require(!safeguard);
         
        _balanceOf[msg.sender] = _balanceOf[msg.sender].sub(_value);   
        totalSupply = totalSupply.sub(_value);                       
        emit Burn(msg.sender, _value);
        emit Transfer(msg.sender, address(0), _value);
        return true;
    }

     
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(!safeguard);
         
        _balanceOf[_from] = _balanceOf[_from].sub(_value);                          
        _allowance[_from][msg.sender] = _allowance[_from][msg.sender].sub(_value);  
        totalSupply = totalSupply.sub(_value);                                    
        emit  Burn(_from, _value);
        emit Transfer(_from, address(0), _value);
        return true;
    }
        
    
     
    function freezeAccount(address target, bool freeze) onlyOwner public {
            _frozenAccount[target] = freeze;
        emit  FrozenFunds(target, freeze);
    }
    
     
    function mintToken(address target, uint256 mintedAmount) onlyOwner public {
        totalSupply = totalSupply.add(mintedAmount);
         
        require(totalSupply <= maximumMinting, 'Minting reached its maximum minting limit' );
        _balanceOf[target] = _balanceOf[target].add(mintedAmount);
        
        emit Transfer(address(0), target, mintedAmount);
    }

        

     
    
    function manualWithdrawTokens(uint256 tokenAmount) public onlyOwner{
         
        _transfer(address(this), owner, tokenAmount);
    }
    
     
    function manualWithdrawEther()onlyOwner public{
        address(owner).transfer(address(this).balance);
    }
    
     
    function changeSafeguardStatus() onlyOwner public{
        if (safeguard == false){
            safeguard = true;
        }
        else{
            safeguard = false;    
        }
    }

}